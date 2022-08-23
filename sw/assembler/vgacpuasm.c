/* vgacpu Assembler
 * By: John Jekel
 *
 * Takes a single input file and outputs a .bin file (ram image) for the vgacpu
*/

/* Constants And Defines */

#define NUM_INSTRUCTIONS 44
#define MAX_INST_NAME_LEN 16
#define MAIN_MEMORY_SIZE 16384

/* Includes */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdbool.h>
#include <string.h>
#include <ctype.h>

/* Types */

typedef struct inst_lookup_t {
    const char str[MAX_INST_NAME_LEN];//Lowercase of instruction
    union
    {
        uint8_t raw_instruction_byte;
        struct {
            uint8_t type : 2;//2 bits to indicate opcode type
            uint8_t opcode : 6;//Opcodes are at most 6 bits depending on type
        };
    };
} inst_lookup_t;

typedef struct inst_t {
    union
    {
        uint8_t instruction_byte;
        struct {
            uint8_t type : 2;//2 bits to indicate opcode type
            uint8_t opcode : 6;//Opcodes are at most 6 bits depending on type
            /*union {
                uint8_t opcode : 6;//Opcodes are at most 6 bits depending on type
                struct {
                    uint8_t opcode_3 : 3;
                    uint8_t operand : 3;
                };
            };*/
        };
    };
    union {
        uint8_t second_byte;
        uint8_t immediate;
        uint8_t operand_2 : 3;
    };
} inst_t;

/* Variables */

static const inst_lookup_t inst_lookup_table [NUM_INSTRUCTIONS] = {//TODO update these to match the new readme
    //Type 3
    {.str = "page",                 .opcode = 0b000000, .type = 3},
    {.str = "sjump",                .opcode = 0b000001, .type = 3},
    {.str = "slt",                  .opcode = 0b000010, .type = 3},
    {.str = "seq",                  .opcode = 0b000011, .type = 3},
    {.str = "sgt",                  .opcode = 0b000100, .type = 3},
    {.str = "fill",                 .opcode = 0b000101, .type = 3},
    {.str = "point",                .opcode = 0b000110, .type = 3},
    {.str = "line",                 .opcode = 0b000111, .type = 3},
    {.str = "wait",                 .opcode = 0b001000, .type = 3},
    {.str = "scall",                .opcode = 0b001001, .type = 3},
    {.str = "pollin",               .opcode = 0b001010, .type = 3},

    {.str = "0tox",                 .opcode = 0b100000, .type = 3},
    {.str = "xto0",                 .opcode = 0b100001, .type = 3},

    //Type 2
    {.str = "lim",                  .opcode = 0b000,    .type = 2},
    {.str = "char",                 .opcode = 0b001,    .type = 2},
    {.str = "load",                 .opcode = 0b010,    .type = 2},
    {.str = "store",                .opcode = 0b011,    .type = 2},
    {.str = "sl",                   .opcode = 0b100,    .type = 2},
    {.str = "sr",                   .opcode = 0b101,    .type = 2},

    //Type 1
    {.str = "push",                 .opcode = 0b000,    .type = 1},
    {.str = "pop",                  .opcode = 0b001,    .type = 1},
    {.str = "add",                  .opcode = 0b010,    .type = 1},
    {.str = "sub",                  .opcode = 0b011,    .type = 1},
    {.str = "and",                  .opcode = 0b100,    .type = 1},
    {.str = "or",                   .opcode = 0b101,    .type = 1},
    {.str = "xor",                  .opcode = 0b110,    .type = 1},
    {.str = "mul",                  .opcode = 0b111,    .type = 1},

    //Type 0
    {.str = "nop",                  .opcode = 0b000000, .type = 0},
    {.str = "envga",                .opcode = 0b000001, .type = 0},
    {.str = "tone",                 .opcode = 0b000010, .type = 0},
    {.str = "notone",               .opcode = 0b000011, .type = 0},
    {.str = "jump",                 .opcode = 0b000100, .type = 0},
    {.str = "jlt",                  .opcode = 0b000101, .type = 0},
    {.str = "jeq",                  .opcode = 0b000110, .type = 0},
    {.str = "jgt",                  .opcode = 0b000111, .type = 0},
    {.str = "lcall",                .opcode = 0b001000, .type = 0},
    {.str = "logo",                 .opcode = 0b001001, .type = 0},
    {.str = "pollblank",            .opcode = 0b001010, .type = 0},
    {.str = "pollrenderbusy",       .opcode = 0b001011, .type = 0},
    {.str = "ret",                  .opcode = 0b001100, .type = 0},
    {.str = "jbez",                 .opcode = 0b001101, .type = 0},
    {.str = "jbnez",                .opcode = 0b001110, .type = 0},

    {.str = "halt",                 .opcode = 0b111110, .type = 0},
    {.str = "reset",                .opcode = 0b111111, .type = 0}
};

/* Macros */

#ifdef NDEBUG
#define debug_print(...) do {} while (0)
#else
#define debug_print(...) do { fputs("DEBUG: ", stderr); fprintf (stderr, __VA_ARGS__); fputc('\n', stderr); } while (0)
#endif

/* Static Function Declarations */

static bool assemble_into_memory_image(char* file_data, uint8_t* memory_image);
static bool parse_instruction_line(char* line, inst_t* instruction);
static const inst_lookup_t* get_raw_instruction(const char* line);
static size_t get_file_size(FILE* file);

/* Function Implementations */

int main(int argc, const char** argv) {

    //We start with a bunch of error checking
    if (argc < 3) {
        fputs("Error: Invalid number of arguments (expected 2)!\n", stderr);

        const char* bin_name = argc ? argv[0] : "vgacpuasm";
        fprintf(stderr, "Usage: %s INPUT.s OUTPUT.bin\n", bin_name);
        return 1;
    }
    if (!strcmp(argv[1], argv[2])){
        fputs("Error: Input and output file names cannot be the same.\n", stderr);
        return 1;
    }
    debug_print("Passed command line error handling");


    //Load the contents of the input file into a buffer
    FILE* input_file = fopen(argv[1], "r");
    if (!input_file) {
        fprintf(stderr, "Error: Failed to open %s for reading.\n", argv[1]);
        return 1;
    }
    debug_print("Input file opened");

    size_t input_file_size = get_file_size(input_file);
    char* input_file_data = (char*) malloc(sizeof(char) * input_file_size);
    if (!input_file_data) {
        fprintf(stderr, "Error: The file you supplied is too big. Please try again.\n");
        fclose(input_file);
        return 1;
    }
    if (fread(input_file_data, sizeof(char), input_file_size, input_file) < input_file_size) {
        fputs("Error: Failed to read entirety of input.\n", stderr);
        fclose(input_file);
        free(input_file_data);
        return 1;
    }
    fclose(input_file);//We're done with the file now
    debug_print("Sucesfully read input file into buffer and closed it.");

    //Cheaper to just keep this on the stack than malloc and free things :)
    //I'd do this for input_file_data too but we don't know its size at
    //compile time and even if we use alloca the file size could
    //blow past the amount of stack we have available
    uint8_t memory_image[MAIN_MEMORY_SIZE];
    //By default, fill memory with HALT instructions to make the user's debugging easier
    memset(memory_image, 0b11111100, MAIN_MEMORY_SIZE);

    //Perform the actual assembly and write to the memory_image buffer
    if (!assemble_into_memory_image(input_file_data, memory_image)) {//Parse failed
        free(input_file_data);
        return 1;
    }
    free(input_file_data);//No more need for this
    debug_print("Assembly of memory image complete, input file buffer freed.");

    //Write the memory image out as a binary file and close it
    FILE* output_file = fopen(argv[2], "wb");
    if (!output_file) {
        fprintf(stderr, "Error: Failed to open %s for writing.\n", argv[2]);
        return 1;
    }
    debug_print("Output file opened");
    if (fwrite(memory_image, sizeof(uint8_t), MAIN_MEMORY_SIZE, output_file) < MAIN_MEMORY_SIZE) {
        fputs("Error: Failed to write entirety of output.\n", stderr);
        fclose(output_file);
        return 1;
    }
    fclose(output_file);
    debug_print("Sucesfully wrote output file and closed it.");

    //We're done!
    fputs("Done!\n", stderr);
    return 0;
}

/* Static Function Implementations */

static bool assemble_into_memory_image(char* file_data, uint8_t* memory_image) {
    assert(file_data);
    assert(memory_image);

    size_t current_line = 0;
    size_t memory_image_index = 0;

    char* line_end;
    while ((line_end = strchr(file_data, '\n'))) {
        //Cut off the line we're looking at from the rest of the file data
        *line_end = '\0';
        char* line = file_data;
        file_data = line_end + 1;
        ++current_line;

        debug_print("Line %lu: \"%s\"", current_line, line);

        //Skip past leading whitespace
        while (isspace(*line) && (*line))
            ++line;

        //Go to the next line if this one was empty
        if (!(*line)) {
            debug_print("Empty line, skipping");
            continue;
        }

        //Skip comments (note: we ONLY support comments on their own line (not after instructions))
        if (*line == '/') {
            //Note: We are not out of bounds since the prev char was not null
            if (*(line + 1) == '/') {
                debug_print("Comment, skipping");
                continue;//Skip this line (it is a comment)continue;
            }

            //TODO perhaps support multi-line comments in the future?
            /*
            if (*(line + 1) == '*') {
                debug_print("Multi-line comment, skipping starts");

                //TODO implement
                fprintf("Error: Not implemented");
                return false;
            }
            */
        }

        //TODO what about symbol support, support for assembler comands (ex. string/numerical literals, etc)
        //We will probably need an intermediate representation (array of decoded instructions) to perform
        //linking at the end

        //Parse the instruction on this line
        inst_t instruction;
        if (!parse_instruction_line(line, &instruction)) {//Parse failed
            fprintf(stderr, "Error: Syntax error on line %lu.\n", current_line);
            return false;
        }

        //Write the instruction to the memory image
        if (memory_image_index >= MAIN_MEMORY_SIZE) {//Ran out of memory on the vgacpu
            fprintf(stderr, "Error: Ran out of vgacpu memory to store code and data (line %lu).\n", current_line);
            return false;
        }

        debug_print("Writing 1st instruction byte 0x%.2x to index 0x%.4lx", instruction.instruction_byte, memory_image_index);
        memory_image[memory_image_index] = instruction.instruction_byte;
        ++memory_image_index;
        if (instruction.type >= 2) {
            debug_print("Writing 2nd instruction byte 0x%.2x to index 0x%.4lx", instruction.second_byte, memory_image_index);
            memory_image[memory_image_index] = instruction.second_byte;
            ++memory_image_index;
        }
    }

    return true;//We did it!
}

static bool parse_instruction_line(char* line, inst_t* instruction) {
    assert(line);
    assert(instruction);

    //Assume leading whitespace has been cut off
    //Cut off the instruction itself from the rest of the line and parse it
    char* inst_str_end = strpbrk(line, "\n\t ");
    if (inst_str_end)
        *inst_str_end = '\0';
    debug_print("Parsing instruction name \"%s\"", line);
    const inst_lookup_t* raw_inst = get_raw_instruction(line);
    if (!raw_inst) {//Lookup failed
        debug_print("Instruction name lookup failed");
        return false;
    }

    //Change line to point to the rest of the line now
    if (inst_str_end) {
        line = inst_str_end + 1;

        //Skip past leading whitespace
        while (isspace(*line) && (*line))
            ++line;

        if (*line)
            debug_print("Remainder of line contains: \"%s\"", line);
        else {
            line = NULL;
            debug_print("Line is now empty");
        }
    } else {
        line = NULL;
        debug_print("Line is now empty");
    }

    instruction->instruction_byte = raw_inst->raw_instruction_byte;

    switch (raw_inst->type) {
        case 3: {//inst IMM
            //Need to parse the line for things to put into the second byte
            debug_print("Instruction is type 3, parsing immediate");

            if (!line) {
                debug_print("Unexpected end of line");
                return false;
            }

            //TODO ensure no garbage afterwards/before and that atoi parse was sucessful; also support bin and hex input
            instruction->second_byte = strtol(line, NULL, 0);
            debug_print("Immediate is 0x%.2x", instruction->second_byte);

            return true;
        } case 2: {//inst rX, IMM
            //Need to parse the line for things to put into the second byte
            //as well as the operand
            debug_print("Instruction is type 2, parsing operand and immediate");

            if (!line) {
                debug_print("Unexpected end of line");
                return false;
            }

            if ((*line) != 'r') {
                debug_print("Register name not prefixed with r");
                return false;
            }
            ++line;

            char* end_of_operand;
            uint8_t operand = strtol(line, &end_of_operand, 10);//TODO ensure no garbage afterwards/before and that atoi parse was sucessful
            line = end_of_operand;//More the line past the parsed operand
            debug_print("Operand is r%u", operand);

            //Overwrite upper 3 bits of instruction byte with the operand
            //Assume upper 3 bits are 0 (opcodes should only go up to 0b111
            //in type 2 so this assumption should be safe)
            instruction->instruction_byte |= operand << 5;

            //Skip past leading whitespace
            while (isspace(*line) && (*line))
                ++line;

            if ((*line) != ',') {
                debug_print("Register name not followed by comma");
                return false;
            }
            ++line;

            //TODO ensure no garbage afterwards/before and that atoi parse was sucessful; also support bin and hex input
            instruction->second_byte = strtol(line, NULL, 0);
            debug_print("Immediate is 0x%.2x", instruction->second_byte);

            return true;
        } case 1: {//inst rX
            //Need to parse the line for the operand
            debug_print("Instruction is type 1, parsing operand");

            if (!line) {
                debug_print("Unexpected end of line");
                return false;
            }

            if ((*line) != 'r') {
                debug_print("Register name not prefixed with r");
                return false;
            }
            ++line;

            uint8_t operand = atoi(line);//TODO ensure no garbage afterwards/before and that atoi parse was sucessful
            debug_print("Operand is r%u", operand);

            //Overwrite upper 3 bits of instruction byte with the operand
            //Assume upper 3 bits are 0 (opcodes should only go up to 0b111
            //in type 1 so this assumption should be safe)
            instruction->instruction_byte |= operand << 5;

            return true;
        } case 0: {//inst
            debug_print("Instruction is type 0, no additional steps");
            if (line) {
                debug_print("User left unexpected characters after the instruction");
                return false;
            }
            return true;//Nothing else to parse!
        } default: {
            debug_print("Instruction is invalid type, this shouldn't occur");
            assert(false);//This shouldn't occur
        }
    }
}

static const inst_lookup_t* get_raw_instruction(const char* inst_str) {
    assert(inst_str);

    //Assume string has no leading whitespace and is null terminated properly
    //Since the instruction lookup table isn't sorted alphabetically, really all we have is a linear search
    for (size_t i = 0; i < NUM_INSTRUCTIONS; ++i)
        if (!strcmp(inst_lookup_table[i].str, inst_str))
            return &inst_lookup_table[i];

    return NULL;//If we couldn't find the instruction
}

static size_t get_file_size(FILE* file) {
    assert(file);

    //TODO implement this in a more foolproof way
    fseek(file, 0, SEEK_END);
    size_t size = ftell(file);
    rewind(file);

    return size;
}
