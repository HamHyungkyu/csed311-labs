`include "opcodes.v"
`define WORD_SIZE 16    // data and address word size

module control(instruction, alu_src, alu_op, reg_dest, mem_write, mem_read, reg_write, mem_to_reg, is_halted, is_wwd);
    input [`WORD_SIZE-1:0] instruction;
    output reg [1:0] alu_src;
    output reg [2:0] alu_op;
    output reg [1:0] reg_dest;
    output reg mem_write;
    output reg mem_read;
    output reg reg_write;
    output reg mem_to_reg;
    output reg is_halted;
    output reg is_wwd;

    wire [3:0] opcode;
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

    initial begin
        alu_src <= 2'b0;
        alu_op <= `FUNC_ADD;
        reg_dest <= 2'b0;
        mem_write <= 0;
        mem_read <= 0;
        reg_write <= 0;
        mem_to_reg <= 0;
        is_halted <= 0;
        is_wwd <= 0;
    end

    //Combinational logic for output
    always @(*) begin
        mem_read = load;
        mem_to_reg = load;
        mem_write = store;
        is_halted = rtype && alu_instruction == `INST_FUNC_HLT;
        is_wwd = rtype && alu_instruction == `INST_FUNC_WWD;

        if(rtype && (alu_instruction == `INST_FUNC_SHL || alu_instruction == `INST_FUNC_SHR))
            alu_src = 2'b10;
        else if(opcode == `LHI_OP)
            alu_src = 2'b11;
        else if(itype)
            alu_src = 2'b01;
        else
            alu_src = 2'b00;

        reg_write = (rtype 
            && (alu_instruction != `INST_FUNC_HLT 
            && alu_instruction != `INST_FUNC_WWD 
            && alu_instruction !=`INST_FUNC_JPR)) 
            || (itype && (opcode > 3 && opcode < 8 )) || (opcode == 4'h9) ;
        
        if(opcode == 4'ha || (rtype && alu_instruction == `INST_FUNC_JRL))
            reg_dest = 2'b10;
        else if (itype)
            reg_dest = 2'b01;
        else   
            reg_dest = 2'b00;

        case (opcode)
            `ADI_OP: alu_op = `FUNC_ADD;
            `ORI_OP: alu_op = `FUNC_ORR;
            `LHI_OP: alu_op = `FUNC_SHL;
            `ALU_OP: begin
                case (alu_instruction)
                    `INST_FUNC_ADD: alu_op = `FUNC_ADD;
                    `INST_FUNC_SUB: alu_op = `FUNC_SUB;
                    `INST_FUNC_AND: alu_op = `FUNC_AND;
                    `INST_FUNC_ORR: alu_op = `FUNC_ORR;
                    `INST_FUNC_NOT: alu_op = `FUNC_NOT;
                    `INST_FUNC_TCP: alu_op = `FUNC_TCP;
                    `INST_FUNC_SHL: alu_op = `FUNC_SHL;
                    `INST_FUNC_SHR: alu_op = `FUNC_SHR;
                    default: alu_op = `FUNC_ADD;
                endcase
             end
            default: alu_op = `FUNC_ADD;
        endcase

    end

endmodule