`include "opcodes.v"

`define ST 2'b11 //Strongly taken
`define WT 2'b10 //Weakly taken
`define WNT 2'b01 //Weakly Not Taken
`define SNT 2'b00 //Strongly Not Taken
`define Nbit 8
`define BTB_SIZE 256

module saturation_preidiction(clk, reset_n, pc, branch_or_jump, bcond, prediction);
	input clk;
	input reset_n;
	input [`WORD_SIZE-1:0] pc; 
	input branch_or_jump;
	input bcond;
	output reg [`WORD_SIZE-1:0] prediction;

	//Counter
	reg [1:0] state;

	//Table
	integer i;
	reg [`WORD_SIZE-1-`Nbit:0] TagTable [`BTB_SIZE-1:0];
	reg BHT;
	reg [`WORD_SIZE-1:0] BTB [`BTB_SIZE-1:0];

	//Taken 1, Not Taken 0 // change to real predict pc
	assign predict_take = 1;
	assign predict_pc = pc + 1; 

	always @(posedge clk) begin
		if(!reset_n) begin
			state <= `ST;
		end
		else begin
			if(branch_or_jump) begin
				//Taken
				if(bcond) begin 
					if(state != `ST) state <= state + 1;
				end
				//Not Taken
				else begin
					if(state != `SNT) state <= state - 1;
				end
			end
		end
	end

	always @(posedge clk) begin
		if(!reset_n) begin
			for(i = 0; i < `BTB_SIZE; i=i+1) begin
				BTB[i] <= 0;
				TagTable[i] <= 0;
			end
			BHT <= 1;
		end
		else begin
			BHT <= prediction;
		end
	end


endmodule