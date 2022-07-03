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
    const char instruction[MAX_INST_NAME_LEN];//Lowercase of instruction
    union
    {
        uint8_t raw_instruction_byte;
        struct {
            uint8_t opcode : 6;//Opcodes are at most 6 bits depending on type
            uint8_t type : 2;//2 bits to indicate opcode type
        };
    };
} inst_lookup_t;

typedef struct inst_t {
    union
    {
        uint8_t instruction_byte;
        struct {
            uint8_t opcode : 6;//Opcodes are at most 6 bits depending on type
            uint8_t type : 2;//2 bits to indicate opcode type
        };
    };
    uint8_t operand : 3;
    union {
        uint8_t second_byte;
        uint8_t immediate;
        uint8_t operand_2 : 3;
    };
} inst_t;

/* Variables */

static const inst_lookup_t inst_lookup_table [NUM_INSTRUCTIONS] = {
    //Type 3
    {.instruction = "page",                 .opcode = 0b000000, .type = 3},
    {.instruction = "sjump",                .opcode = 0b000001, .type = 3},
    {.instruction = "slt",                  .opcode = 0b000010, .type = 3},
    {.instruction = "seq",                  .opcode = 0b000011, .type = 3},
    {.instruction = "sgt",                  .opcode = 0b000100, .type = 3},
    {.instruction = "fill",                 .opcode = 0b000101, .type = 3},
    {.instruction = "point",                .opcode = 0b000110, .type = 3},
    {.instruction = "line",                 .opcode = 0b000111, .type = 3},
    {.instruction = "wait",                 .opcode = 0b001000, .type = 3},
    {.instruction = "scall",                .opcode = 0b001001, .type = 3},
    {.instruction = "pollin",               .opcode = 0b001010, .type = 3},

    {.instruction = "0tox",                 .opcode = 0b100000, .type = 3},
    {.instruction = "xto0",                 .opcode = 0b100001, .type = 3},

    //Type 2
    {.instruction = "lim",                  .opcode = 0b000,    .type = 2},
    {.instruction = "char",                 .opcode = 0b001,    .type = 2},
    {.instruction = "load",                 .opcode = 0b010,    .type = 2},
    {.instruction = "store",                .opcode = 0b011,    .type = 2},
    {.instruction = "sl",                   .opcode = 0b100,    .type = 2},
    {.instruction = "sr",                   .opcode = 0b101,    .type = 2},

    //Type 1
    {.instruction = "push",                 .opcode = 0b000,    .type = 1},
    {.instruction = "pop",                  .opcode = 0b001,    .type = 1},
    {.instruction = "add",                  .opcode = 0b010,    .type = 1},
    {.instruction = "sub",                  .opcode = 0b011,    .type = 1},
    {.instruction = "and",                  .opcode = 0b100,    .type = 1},
    {.instruction = "or",                   .opcode = 0b101,    .type = 1},
    {.instruction = "xor",                  .opcode = 0b110,    .type = 1},
    {.instruction = "mul",                  .opcode = 0b111,    .type = 1},

    //Type 0
    {.instruction = "nop",                  .opcode = 0b000000, .type = 0},
    {.instruction = "envga",                .opcode = 0b000001, .type = 0},
    {.instruction = "tone",                 .opcode = 0b000010, .type = 0},
    {.instruction = "notone",               .opcode = 0b000011, .type = 0},
    {.instruction = "jump",                 .opcode = 0b000100, .type = 0},
    {.instruction = "jlt",                  .opcode = 0b000101, .type = 0},
    {.instruction = "jeq",                  .opcode = 0b000110, .type = 0},
    {.instruction = "jgt",                  .opcode = 0b000111, .type = 0},
    {.instruction = "lcall",                .opcode = 0b001000, .type = 0},
    {.instruction = "logo",                 .opcode = 0b001001, .type = 0},
    {.instruction = "pollblank",            .opcode = 0b001010, .type = 0},
    {.instruction = "pollrenderbusy",       .opcode = 0b001011, .type = 0},
    {.instruction = "ret",                  .opcode = 0b001100, .type = 0},
    {.instruction = "jbez",                 .opcode = 0b001101, .type = 0},
    {.instruction = "jbnez",                .opcode = 0b001110, .type = 0},

    {.instruction = "halt",                 .opcode = 0b111110, .type = 0},
    {.instruction = "reset",                .opcode = 0b111111, .type = 0}
};

/* Macros */

#ifdef NDEBUG
#define debug_print(...) do {} while (0)
#else
#define debug_print(...) do { fputs("DEBUG: ", stderr); fprintf (stderr, __VA_ARGS__); fputc('\n', stderr); } while (0)
#endif

/* Static Function Declarations */

static bool assemble_into_memory_image(char* file_data, uint8_t* memory_image);
static bool parse_instruction_line(const char* line, inst_t* instruction);
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

    const char* line = strtok(file_data, "\n");
    size_t current_line = 1;

    size_t memory_image_index = 0;

    while (line) {
        debug_print("Line %lu: \"%s\"", current_line, line);

        //Skip past leading whitespace
        while (isspace(*line) && (*line))
            ++line;

        debug_print("Whitespace removed: \"%s\"", line);

        //Go to the next line if this one was empty
        //FIXME strtok seems to skip over this case, but we want to deal with it seperately
        if (!(*line)) {
            debug_print("Empty line, skipping");
            line = strtok(NULL, "\n");//Get the next line
            ++current_line;
            continue;
        }

        if (*line == '/') {
            if (*(line + 1) == '/') {//We are not out of bounds since the prev char was not null
                debug_print("Comment, skipping");
                line = strtok(NULL, "\n");//Get the next line
                ++current_line;
                continue;//Skip this line (it is a comment)continue;
            }
        }

        //TODO multi-line comments

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

        debug_print("Writing 1st instruction byte %x to index %lu", instruction.instruction_byte, memory_image_index);
        memory_image[memory_image_index] = instruction.instruction_byte;
        ++memory_image;
        if (instruction.type >= 2) {
            debug_print("Writing 2nd instruction byte %x to index %lu", instruction.second_byte, memory_image_index);
            *memory_image = instruction.second_byte;
            ++memory_image;
        }

        line = strtok(NULL, "\n");//Get the next line
        ++current_line;
    }
}

static bool parse_instruction_line(const char* line, inst_t* instruction) {
    assert(line);

    //Assume leading whitespace has been cut off, so we can just call this right away
    const inst_lookup_t* raw_inst = get_raw_instruction(line);
    if (!raw_inst)//Lookup failed
        return false;

    instruction->instruction_byte = raw_inst->raw_instruction_byte;

    switch (raw_inst->type) {
        case 3:
            //Need to parse the line for things to put into the second byte
            assert(false);//TODO implement
        case 2:
            //Need to parse the line for things to put into the second byte
            //as well as the operand
            assert(false);//TODO implement
        case 1:
            //Need to parse the line for the operand
            assert(false);//TODO implement
        case 0:
            return true;//Nothing else to parse!
        default:
            assert(false);//This shouldn't occur

    }
}

static const inst_lookup_t* get_raw_instruction(const char* line) {
    assert(line);

    //Assume string has no leading whitespace and is null terminated properly
    //Since the instruction lookup table isn't sorted alphabetically, really all we have is a linear search
    for (size_t i = 0; i < NUM_INSTRUCTIONS; ++i) {
        const char* comparison_str = inst_lookup_table[i].instruction;

        bool found = false;
        for (size_t j = 0; j < MAX_INST_NAME_LEN; ++j) {
            //Assume the line won't end before we recognize it either does or dosn't match
            assert(line[i]);
            assert(j < strlen(line));

            //Check if this character is the same
            if (line[i] != comparison_str[i]) {
                //If we the character mismatch was because the comparison_str ended
                //and the line string encountered white space (aka the instruction ended)
                if ((!(comparison_str[i])) && isspace(line[i])) {
                    found = true;//Then we did it! Both instructions matched!
                    break;
                } else
                    continue;//Try again
            }
        }

        if (found)
            return &inst_lookup_table[i];
    }

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
