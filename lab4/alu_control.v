`include "opcodes.v"

module alu_control(aluOp, instFuncCode, funcCode);
    input [3:0] aluOp;
    input [5:0] instFuncCode;
    output reg [2:0] funcCode;

    reg [2:0] _funcCode;

    always @(*) begin
        case (instFuncCode)
            `INST_FUNC_ADD: _funcCode = `FUNC_ADD;
            `INST_FUNC_SUB: _funcCode = `FUNC_SUB;
            `INST_FUNC_AND: _funcCode = `FUNC_AND; 
            `INST_FUNC_ORR: _funcCode = `FUNC_ORR;
            `INST_FUNC_NOT: _funcCode = `FUNC_NOT;
            `INST_FUNC_TCP: _funcCode = `FUNC_TCP; 
            `INST_FUNC_SHL: _funcCode = `FUNC_SHL;
            `INST_FUNC_SHR: _funcCode = `FUNC_SHR; 
            default: _funcCode = `FUNC_ADD;
        endcase

        case (aluOp)
            `ALU_OP: funcCode = _funcCode;
            `ADI_OP: funcCode = `FUNC_ADD;
            `ORI_OP: funcCode = `FUNC_ORR;
            `LHI_OP: funcCode = `FUNC_SHL;
            `LWD_OP: funcCode = `FUNC_ADD;
            `SWD_OP: funcCode = `FUNC_ADD;
            default: funcCode = `FUNC_ADD;
        endcase 
    end
endmodule