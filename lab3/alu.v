`timescale 1ns / 100ps

`include "opcodes.v"

`define	NumBits	16

module ALU (A, B, FuncCode, C, OverflowFlag);
	input [`NumBits-1:0] A;
	input [`NumBits-1:0] B;
	input [2:0] FuncCode;
	output [`NumBits-1:0] C;
	output OverflowFlag;

	reg [`NumBits-1:0] C;
	reg OverflowFlag;

	initial begin
		C = 0;
		OverflowFlag = 0;
	end   	
	
	always @(A or B or FuncCode) begin
		case(FuncCode)
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
endmodule