`timescale 1ns / 100ps

`define	NumBits	16
`define	FUNC_ADD	4'b0000
`define	FUNC_SUB	4'b0001
`define FUNC_ID 	4'b0010
`define FUNC_NOT	4'b0011
`define	FUNC_AND	4'b0100
`define	FUNC_OR 	4'b0101
`define	FUNC_NAND	4'b0110
`define	FUNC_NOR	4'b0111
`define FUNC_XOR	4'b1000
`define FUNC_XNOR	4'b1001
`define	FUNC_LLS	4'b1010
`define	FUNC_LRS	4'b1011
`define	FUNC_ALS	4'b1100
`define	FUNC_ARS	4'b1101
`define	FUNC_TCP	4'b1110
`define	FUNC_ZERO	4'b1111

module ALU (A, B, FuncCode, C, OverflowFlag);
	input [`NumBits-1:0] A;
	input [`NumBits-1:0] B;
	input [3:0] FuncCode;
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
			`FUNC_ID: begin C = A; OverflowFlag = 0; end
			`FUNC_NOT: begin C = ~A; OverflowFlag = 0; end
			`FUNC_AND: begin C = A & B; OverflowFlag = 0; end
			`FUNC_OR: begin C = A | B; OverflowFlag = 0; end
			`FUNC_NAND: begin C = ~(A & B); OverflowFlag = 0; end
			`FUNC_NOR: begin C = ~(A | B); OverflowFlag = 0; end
			`FUNC_XOR: begin C = A ^ B; OverflowFlag = 0; end
			`FUNC_XNOR: begin C = A ~^ B; OverflowFlag = 0; end
			`FUNC_LLS: begin C = A << 1; OverflowFlag = 0; end
			`FUNC_LRS: begin C = A >> 1; OverflowFlag = 0; end
			`FUNC_ALS: begin C = A <<< 1; OverflowFlag = 0; end
			`FUNC_ARS: begin C = {A[`NumBits -1], A[`NumBits -1: 1]}; OverflowFlag = 0; end
			`FUNC_TCP: begin C = ~A + 1; OverflowFlag = 0; end
			`FUNC_ZERO: begin C = 0; OverflowFlag = 0; end
		endcase
	end
	// TODO: You should implement the functionality of ALU!
	// (HINT: Use 'always @(...) begin ... end')
	/*
		YOUR ALU FUNCTIONALITY IMPLEMENTATION...
	*/

endmodule

