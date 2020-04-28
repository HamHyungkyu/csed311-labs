`include "opcodes.v"
`define WORD_SIZE 16    // data and address word size

module alu_control(aluOp, instFuncCode, alu_src, read_out1, read_out2, sign_extended_imm, A, B, funcCode);
    input [3:0] aluOp;
    input [5:0] instFuncCode;
    input alu_src;
    input [`WORD_SIZE-1:0] read_out1;
    input [`WORD_SIZE-1:0] read_out2;
    input [`WORD_SIZE-1:0] sign_extended_imm;
    output reg [`WORD_SIZE-1:0] A;
    output reg [`WORD_SIZE-1:0] B;
    output reg [2:0] funcCode;

    initial begin 
        A <= read_out1;
        B <= read_out2;
    end
    always @(*) begin
        case (aluOp)
            `ALU_OP: begin
                    case (instFuncCode)
                        `INST_FUNC_ADD: begin funcCode = `FUNC_ADD; A = read_out1; B = read_out2; end
                        `INST_FUNC_SUB: begin funcCode = `FUNC_SUB; A = read_out1; B = read_out2; end
                        `INST_FUNC_AND: begin funcCode = `FUNC_AND; A = read_out1; B = read_out2; end
                        `INST_FUNC_ORR: begin funcCode = `FUNC_ORR; A = read_out1; B = read_out2; end
                        `INST_FUNC_NOT: begin funcCode = `FUNC_NOT; A = read_out1; B = read_out2; end
                        `INST_FUNC_TCP: begin funcCode = `FUNC_TCP; A = read_out1; B = read_out2; end
                        `INST_FUNC_SHL: begin funcCode = `FUNC_SHL; A = read_out1; B = 1; end
                        `INST_FUNC_SHR: begin funcCode = `FUNC_SHR; A = read_out1; B = 1; end
                        default: funcCode = `FUNC_ADD;
                    endcase
                end
            `ADI_OP: begin funcCode = `FUNC_ADD; A = read_out1; B = sign_extended_imm; end
            `ORI_OP: begin funcCode = `FUNC_ORR; A = read_out1; B = sign_extended_imm; end
            `LHI_OP: begin funcCode = `FUNC_SHL; A = sign_extended_imm; B = 8; end
            `LWD_OP: begin funcCode = `FUNC_ADD; A = read_out1; B = sign_extended_imm; end
            `SWD_OP: begin funcCode = `FUNC_ADD; A = read_out1; B = sign_extended_imm; end
            default: begin funcCode = `FUNC_ADD; A = read_out1; B = sign_extended_imm; end
        endcase 
    end
endmodule