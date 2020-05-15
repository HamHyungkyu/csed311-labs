`define ST 2'b11 //Strongly taken
`define WT 2'b10 //Weakly taken
`define WNT 2'b01 //Weakly Not Taken
`define SNT 2'b00 //Strongly Not Taken

module saturation_counter(clk, reset_n, branch_or_jump, bcond, prediction);
	input clk;
	input reset_n;
	input branch_or_jump;
	input bcond;
	output reg [1:0] prediction;

	reg [1:0] state;

	//Taken 1, Not Taken 0
	assign prediction = state / 2; 

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
endmodule