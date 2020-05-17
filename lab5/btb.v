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
	output [`WORD_SIZE-1:0] if_btb_pc;
	output if_btb_taken;
	wire [`WORD_SIZE-1:0] if_btb_pc;
	wire if_btb_taken;


	input [`WORD_SIZE-1:0] id_pc;
	input branch;
	input jump;
	input bcond;
	input [`WORD_SIZE-1:0] target;

	//Table
	integer i;
	reg [`WORD_SIZE-1-`N_bit:0] TagTable [`BTB_SIZE-1:0];
	reg [1:0] BHT;
	reg [`WORD_SIZE-1:0] BTB [`BTB_SIZE-1:0];

	//Tag, Idx on PC
	wire if_tag = if_pc[`WORD_SIZE-1:`WORD_SIZE-`N_bit];
	wire if_idx = if_pc[`N_bit:0];
	wire id_tag = id_pc[`WORD_SIZE-1:`WORD_SIZE-`N_bit];
	wire id_idx = id_pc[`N_bit:0];

	//Prediction
	assign if_btb_pc = ((if_tag == TagTable[if_idx]) && (BHT / 2)) ? BTB[if_idx] : (if_pc + 1);
	assign if_btb_taken = BHT / 2;

	always @(posedge clk) begin
		if(!reset_n) begin
			for(i = 0; i < `BTB_SIZE; i=i+1) begin
				BTB[i] <= 0;
				TagTable[i] <= 0;
			end
			BHT <= `SNT;
		end
		else begin
			if(branch || jump) begin
				TagTable[id_idx] <= id_tag;
				if(branch) begin
					if(bcond) begin
						if(BHT != `ST) BHT <= BHT + 1;
					end
					else begin
						if(BHT != `SNT) BHT <= BHT - 1;
					end
				end
				BTB[id_idx] <= target;
			end
		end
	end
endmodule