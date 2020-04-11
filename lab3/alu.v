<<<<<<< HEAD
module alu (A, B, FuncCode, C);

=======
`include "opcodes.v"

`define	NumBits	16

module alu (A, B, funcCode, C, OverflowFlag);
	input [`NumBits-1:0] A;
	input [`NumBits-1:0] B;
	input [2:0] funcCode;
	output [`NumBits-1:0] C;
	output OverflowFlag;

	reg [`NumBits-1:0] C;
	reg OverflowFlag;

	initial begin
		C = 0;
		OverflowFlag = 0;
	end   	
	
	always @(A or B or funcCode) begin
		case(funcCode)
			`FUNC_ADD: begin
					C = A + B;
					OverflowFlag = (A[`NumBits - 1] ^ C[`NumBits -1]) & (B[`NumBits -1] ^ C[`NumBits -1] ); 
				end
			`FUNC_SUB: begin 
					C = A - B; 
					OverflowFlag = (A[`NumBits - 1] ^ C[`NumBits -1]) & (~B[`NumBits -1] ^ C[`NumBits -1] ); 
				end
			`FUNC_NOT: begin C = ~A; OverflowFlag = 0; end
			`FUNC_AND: begin C = A & B; OverflowFlag = 0; end
			`FUNC_ORR: begin C = A | B; OverflowFlag = 0; end
			`FUNC_TCP: begin C = ~A + 1; OverflowFlag = 0; end
			`FUNC_SHL: begin C = A << 1; OverflowFlag = 0; end
			`FUNC_SHR: begin C = A >> 1; OverflowFlag = 0; end
		endcase
	end
>>>>>>> a9064c55eb36ea3a5361d29fa026d279c09657cf
endmodule