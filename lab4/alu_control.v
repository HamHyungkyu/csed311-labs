`include "opcodes.v"
`define WORD_SIZE 16    // data and address word size

module alu_control(aluOp, instFuncCode, alu_src, read_out1, read_out2, sign_extended_imm, A, B, funcCode, skip_write_reg);
    input [3:0] aluOp;
    input [5:0] instFuncCode;
    input alu_src;
    input [`WORD_SIZE-1:0] read_out1;
    input [`WORD_SIZE-1:0] read_out2;
    input [`WORD_SIZE-1:0] sign_extended_imm;
    output reg [`WORD_SIZE-1:0] A;
    output reg [`WORD_SIZE-1:0] B;
    output reg [2:0] funcCode;
    output reg skip_write_reg;

    initial begin 
        A <= read_out1;
        B <= read_out2;
        skip_write_reg <= 0;
    end
    always @(*) begin
        case (aluOp)
            `ALU_OP: begin
                    case (instFuncCode)
                        `INST_FUNC_ADD: begin funcCode = `FUNC_ADD; A = read_out1; B = read_out2; skip_write_reg <= 0;end
                        `INST_FUNC_SUB: begin funcCode = `FUNC_SUB; A = read_out1; B = read_out2; skip_write_reg <= 0;end
                        `INST_FUNC_AND: begin funcCode = `FUNC_AND; A = read_out1; B = read_out2; skip_write_reg <= 0;end
                        `INST_FUNC_ORR: begin funcCode = `FUNC_ORR; A = read_out1; B = read_out2; skip_write_reg <= 0;end
                        `INST_FUNC_NOT: begin funcCode = `FUNC_NOT; A = read_out1; B = read_out2; skip_write_reg <= 0;end
                        `INST_FUNC_TCP: begin funcCode = `FUNC_TCP; A = read_out1; B = read_out2; skip_write_reg <= 0;end
                        `INST_FUNC_SHL: begin funcCode = `FUNC_SHL; A = read_out1; B = 1; skip_write_reg <= 0;end
                        `INST_FUNC_SHR: begin funcCode = `FUNC_SHR; A = read_out1; B = 1; skip_write_reg <= 0;end
                        `INST_FUNC_JRL: begin funcCode = `FUNC_SHR; A = read_out1; B = 1; skip_write_reg <= 0;end
                        default: begin funcCode = `FUNC_ADD; A = read_out1; B = read_out2; skip_write_reg <= 1;end // WWD and HALT skip register write
                    endcase
                end
            `ADI_OP: begin funcCode = `FUNC_ADD; A = read_out1; B = sign_extended_imm; skip_write_reg <= 0;end
            `ORI_OP: begin funcCode = `FUNC_ORR; A = read_out1; B = sign_extended_imm; skip_write_reg <= 0;end
            `LHI_OP: begin funcCode = `FUNC_SHL; A = sign_extended_imm; B = 8; skip_write_reg <= 0;end
            `LWD_OP: begin funcCode = `FUNC_ADD; A = read_out1; B = sign_extended_imm; skip_write_reg <= 0;end
            `SWD_OP: begin funcCode = `FUNC_ADD; A = read_out1; B = sign_extended_imm; skip_write_reg <= 0;end
            `JAL_OP: begin funcCode = `FUNC_ADD; A = read_out1; B = sign_extended_imm; skip_write_reg <= 0;end     
            default: begin funcCode = `FUNC_ADD; A = read_out1; B = sign_extended_imm; skip_write_reg <= 1;end
        endcase 
    end
endmodule