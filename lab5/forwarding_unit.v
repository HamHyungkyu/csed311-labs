`include "opcodes.v"

module forwarding_unit(ID_EX_Rs, ID_EX_Rt, EX_MEM_Reg_Rd, MEM_WB_Reg_Rd, RegWrite_MEM, RegWrite_WB, ForwardA, ForwardB);
	input [1:0] ID_EX_Rs;
	input [1:0] ID_EX_Rt;
	input [1:0] EX_MEM_Reg_Rd;
	input [1:0] MEM_WB_Reg_Rd;
	input RegWrite_MEM;
	input RegWrite_WB;
	output reg [1:0] ForwardA;
	output reg [1:0] ForwardB;

	//Do for Rs, Rt
	//MEM first, WB second.

	always @(*) begin
		//Rs
		if (ID_EX_Rs && (ID_EX_Rs == EX_MEM_Reg_Rd) && RegWrite_MEM) begin
			ForwardA = 2'b10;
		end
		else if (ID_EX_Rs && (ID_EX_Rs == MEM_WB_Reg_Rd) && RegWrite_WB) begin
			ForwardA = 2'b01;
		end
		else
			ForwardA = 2'b00;

		//Rt
		if (ID_EX_Rt && (ID_EX_Rt == EX_MEM_Reg_Rd) && RegWrite_MEM) begin
			ForwardB = 2'b10;
		end
		else if (ID_EX_Rt && (ID_EX_Rt == MEM_WB_Reg_Rd) && RegWrite_WB) begin
			ForwardB = 2'b01;
		end
		else
			ForwardB = 2'b00;
	end
endmodule