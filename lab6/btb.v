`include "opcodes.v"

`define ST 2'b11 //Strongly taken
`define WT 2'b10 //Weakly taken
`define WNT 2'b01 //Weakly Not Taken
`define SNT 2'b00 //Strongly Not Taken

`define N_bit 8
`define BTB_SIZE 256

module btb(clk, reset_n, if_pc, if_btb_pc, if_btb_taken, id_pc, branch, jump, bcond, target);
	input clk;
	input reset_n;

	input [`WORD_SIZE-1:0] if_pc;
	output reg [`WORD_SIZE-1:0] if_btb_pc;
	output reg if_btb_taken;

	input [`WORD_SIZE-1:0] id_pc;
	input branch;
	input jump;
	input bcond;
	input [`WORD_SIZE-1:0] target;

	//Table
	integer i;
	reg JumpOrBranch [`BTB_SIZE-1:0]; // JUMP : 0, branch :1 
	reg [`WORD_SIZE-1-`N_bit:0] TagTable [`BTB_SIZE-1:0];
	reg [1:0] BHT;
	reg [`WORD_SIZE-1:0] BTB [`BTB_SIZE-1:0];

	//Tag, Idx on PC
	wire [`WORD_SIZE-`N_bit-1:0] if_tag = if_pc[`WORD_SIZE-1:`WORD_SIZE-`N_bit];
	wire [`N_bit-1:0] if_idx = if_pc[`N_bit-1 :0];
	wire [`WORD_SIZE-`N_bit-1:0] id_tag = id_pc[`WORD_SIZE-1:`WORD_SIZE-`N_bit];
	wire [`N_bit-1:0] id_idx = id_pc[`N_bit-1:0];

	initial begin
		if_btb_pc <= 0;
		if_btb_taken <= 0;
	end
	
	always @(*) begin
		if_btb_pc = if_pc + 1;
		if((if_tag == TagTable[if_idx]) && ~JumpOrBranch[if_idx]) begin
			if_btb_pc = BTB[if_idx];
		end
		else if ((if_tag == TagTable[if_idx]) && ( JumpOrBranch[if_idx] & BHT[1])) begin
			if_btb_pc = BTB[if_idx];
		end
		if_btb_taken = BHT[1] | ~JumpOrBranch[if_idx];
	end

	always @(posedge clk) begin
		if(!reset_n) begin
			BHT <= `SNT;
		end
		else begin
			if(branch || jump) begin
				TagTable[id_idx] <= id_tag;
				if(branch) begin
					JumpOrBranch[id_idx] <= 1;
					if(bcond) begin
						if(BHT != `ST) BHT <= BHT + 1;
					end
					else begin
						if(BHT != `SNT) BHT <= BHT - 1;
					end
				end
				else begin
					JumpOrBranch[id_idx] <= 0;
				end
				BTB[id_idx] <= target;
			end
		end
	end
endmodule