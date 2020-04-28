`include "opcodes.v"

`define	NumBits	16

module alu (A, B, funcCode, C);
	input [`NumBits-1:0] A;
	input [`NumBits-1:0] B;
	input [2:0] funcCode;
	output [`NumBits-1:0] C;

	reg [`NumBits-1:0] C;

	initial begin
		C = 0;
	end   	
	
	always @(A or B or funcCode) begin
		case(funcCode)
			`FUNC_ADD: begin C = A + B; end
			`FUNC_SUB: begin C = A - B; end
			`FUNC_NOT: begin C = ~A; end
			`FUNC_AND: begin C = A & B; end
			`FUNC_ORR: begin C = A | B; end
			`FUNC_TCP: begin C = ~A + 1; end
			`FUNC_SHL: begin C = A << B; end
			`FUNC_SHR: begin C = A >> B; end
		endcase
	end
endmodule