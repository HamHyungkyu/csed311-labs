`timescale 1ns/1ns
`define MEMORY_SIZE 256	//	size of memory is 2^8 words (reduced size)
`define WORD_SIZE 16	//	instead of 2^16 words to reduce memory

module external_device(clk, reset_n, interrupt, offset, data);
	input clk;
	input reset_n;
	output reg interrupt;
	input [`WORD_SIZE-1:0] offset;
	inout [`WORD_SIZE*4-1:0] data;
	
	reg [`WORD_SIZE-1:0] memory [0:`MEMORY_SIZE-1];
	reg [`WORD_SIZE*4-1:0] outputData;
	reg [6:0] counter;

	assign data = offset === `WORD_SIZE'bz ? 64'bz : outputData;
	
	always@(*)begin
		outputData = {memory[offset], memory[offset + 1], memory[offset + 2],  memory[offset + 3]};
	end

	always@(posedge clk)
		if(!reset_n)
			begin
				memory[16'h0] <= 16'h1;
				memory[16'h1] <= 16'h2;
				memory[16'h2] <= 16'h3;
				memory[16'h3] <= 16'h4;
				memory[16'h4] <= 16'h5;
				memory[16'h5] <= 16'h6;
				memory[16'h6] <= 16'h7;
				memory[16'h7] <= 16'h8;
				memory[16'h8] <= 16'h9;
				memory[16'h9] <= 16'ha;
				memory[16'ha] <= 16'hb;
				memory[16'hb] <= 16'hc;
				counter <= 6'b111111;
				interrupt <= 0;
			end
		else begin
			if(counter > 1) begin
				interrupt <= 0;
				counter <= counter - 1;
			end
			else if (counter == 1)begin
				interrupt <= 1;
				counter <= counter -1;
			end
			else begin
				interrupt <= 0;
			end
		end
endmodule