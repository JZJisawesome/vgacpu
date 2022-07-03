/* vgacpu Assembler
 * By: John Jekel
 *
 * Takes a single input file and outputs a .bin file (ram image) for the vgacpu
 *
*/

/* Constants And Defines */

#define NUM_INSTRUCTIONS 44
#define MAIN_MEMORY_SIZE 16384

/* Includes */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

/* Types */

typedef struct string_opcode_lookup_group {
    const char* instruction;//Lowercase of instruction
    union
    {
        uint8_t raw_instruction_byte;
        struct {
            uint8_t opcode : 6;//Opcodes are at most 6 bits depending on type
            uint8_t type : 2;//2 bits to indicate opcode type
        };
    };
} string_opcode_lookup_group;

/* Variables */

static const string_opcode_lookup_group string_opcode_lookup [NUM_INSTRUCTIONS] = {
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

/* Static Function Declarations */

static void assemble_into_memory_image(const char* file_data, uint8_t* memory_image);
static const string_opcode_lookup_group* parse_instruction_line(const char* line);
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

    //Load the contents of the input file into a buffer
    FILE* input_file = fopen(argv[1], "r");
    if (!input_file) {
        fprintf(stderr, "Error: Failed to open %s for reading.\n", argv[1]);
        return 1;
    }

    size_t input_file_size = get_file_size(input_file);
    char* input_file_data = (char*) malloc(sizeof(char) * input_file_size);
    if (!input_file_data) {
        fprintf(stderr, "Error: The file you supplied is too big. Please try again.\n");
        fclose(input_file);
        return 1;
    }
    fread(input_file_data, sizeof(char), input_file_size, input_file);
    fclose(input_file);//We're done with the file now

    //Cheaper to just keep this on the stack than malloc and free things :)
    //I'd do this for input_file_data too but we don't know its size at
    //compile time and even if we use alloca the file size could
    //blow past the amount of stack we have available
    uint8_t memory_image[MAIN_MEMORY_SIZE];

    //Perform the actual assembly and write to the memory_image buffer
    assemble_into_memory_image(input_file_data, memory_image);
    free(input_file_data);//No more need for this

    //Write the memory image out as a binary file and close it
    FILE* output_file = fopen(argv[2], "wb");
    if (!output_file) {
        fprintf(stderr, "Error: Failed to open %s for writing.\n", argv[2]);
        fclose(input_file);
        return 1;
    }
    fwrite(memory_image, sizeof(uint8_t), MAIN_MEMORY_SIZE, output_file);
    fclose(output_file);

    //We're done!
    fputs("Done!\n", stderr);
    return 0;
}

/* Static Function Implementations */

static void assemble_into_memory_image(const char* file_data, uint8_t* memory_image) {
    assert(file_data);
    assert(memory_image);
    //TODO implement
}

static const string_opcode_lookup_group* parse_instruction_line(const char* line) {
    assert(line);
    //TODO implement
}

static size_t get_file_size(FILE* file) {
    assert(file);

    //TODO implement this in a more foolproof way
    fseek(file, 0, SEEK_END);
    size_t size = ftell(file);
    rewind(file);

    return size;
}
