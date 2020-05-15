`include "opcodes.v"
`define WORD_SIZE 16    // data and address word size

module control(instruction, alu_src, alu_op, reg_dest, mem_write, mem_read, reg_write, mem_to_reg);
    input [`WORD_SIZE-1:0] instruction;
    output reg alu_src;
    output reg alu_op;
    output reg reg_dest;
    output reg mem_write;
    output reg mem_read;
    output reg reg_write;
    output reg mem_to_reg;
 
    wire ; [3:0] opcode;
    wire [5:0] alu_instruction;
    wire rtype, itype, jtype, load, store, branch;
    assign opcode = instruction[15:12];
    assign alu_instruction = instruction[5:0];
    assign rtype = opcode[0] & opcode[1] & opcode[2] & opcode[3]; // 15
    assign itype = ~opcode[3] | (~opcode[0] & ~opcode[1] & ~opcode[2] & opcode[3]); // 0~8
    assign load = ~opcode[3] &  opcode[2] &  opcode[1] &  opcode[0]; // 7
    assign store =  opcode[3] & ~opcode[0] & ~opcode[1] & ~opcode[2]; // 8
    assign branch = ~opcode[3] & ~opcode[2]; //0 ~3
    assign jtype =  opcode[3] & ~opcode[2] & (opcode[1] ^ opcode[0]); // 9, 10

    //Combinational logic for output
    always @(*) begin
        mem_read = load;
        mem_to_reg = load;
        mem_write = store;
        
    end

endmodule