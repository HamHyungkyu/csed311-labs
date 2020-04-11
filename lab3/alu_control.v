`include "opcodes.v"

module alu_control(aluOp, instFuncCode, funcCode);
    input [3:0] aluOp;
    input [5:0] instFuncCode;
    output [2:0] funcCode;

    reg [2:0] _funcCode;
    
    always @(*)
        case (instFunccode)
            `INST_FUNC_ADD: _funcCode = `FUNC_ADD; // +
            `INST_FUNC_SUB: _funcCode = `FUNC_SUB; // + ! + 1
            `INST_FUNC_AND: _funcCode = `FUNC_AND; // &
            `INST_FUNC_ORR: _funcCode = `FUNC_ORR; // |
            `INST_FUNC_NOT: _funcCode = `FUNC_NOT; // !
            `INST_FUNC_TCP: _funcCode = `FUNC_TCP; // ! + 1
            `INST_FUNC_SHL: _funcCode = `FUNC_SHL; // <<
            `INST_FUNC_SHR: _funcCode = `FUNC_SHR; // >>
            `INST_FUNC_JPR: _funcCode = `FUNC_ADD; // not sure
            `INST_FUNC_JRL: _funcCode = `FUNC_ADD; // not sure
            default: _funcCode = `FUNC_ADD;
        endcase

    always @(*)
        case (aluOp)
            `ALU_OP: funcCode = _funcCode;
            `ADI_OP: funcCode = `FUNC_ADD;
            `ORI_OP: funcCode = `FUNC_ORR;
            `LHI_OP: funcCode = `FUNC_SHL;
            `LWD_OP: funcCode = `FUNC_ADD;
            `SWD_OP: funcCode = `FUNC_ADD;
            `BNE_OP: funcCode = `FUNC_ADD; // default
            `BEQ_OP: funcCode = `FUNC_ADD; // default
            `BGZ_OP: funcCode = `FUNC_ADD; // default
            `BLZ_OP: funcCode = `FUNC_ADD; // default
            `JMP_OP: funcCode = `FUNC_ADD; // default
            `JAL_OP: funcCode = `FUNC_ADD; // default
            `JPR_OP: funcCode = `FUNC_ADD; // default
            `JRL_OP: funcCode = `FUNC_ADD; // default
            default: funcCode = `FUNC_ADD;
        endcase 
endmodule

