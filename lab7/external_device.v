`timescale 1ns/1ns
`define PERIOD1 100
`define MEMORY_SIZE 256	//	size of memory is 2^8 words (reduced size)
`define WORD_SIZE 16	//	instead of 2^16 words to reduce memory
			//	requirements in the Active-HDL simulator 

module external_device(clk, reset_n, interrupt, offset, data);
	input clk;
	input reset_n;
	input interrupt;
	input [`WORD_SIZE-1:0] offset;
	output [`WORD_SIZE*4-1:0] data;
	
	reg [11:0] memory [0:`MEMORY_SIZE-1];
	reg [`WORD_SIZE*4-1:0] outputData2;
	reg [6:0] counter;

	assign data2 = offset >= 0 ? outputData2 : 64'bz;
	
	always@(posedge clk)
		if(!reset_n)
			begin
				read_delay <= 2'b0;
				write_delay <= 2'b0;
				memory[16'h0] <= 16'h0;
				memory[16'h1] <= 16'h0;
				memory[16'h2] <= 16'h0;
				memory[16'h3] <= 16'h0;
				memory[16'h4] <= 16'h0;
				memory[16'h5] <= 16'h0;
				memory[16'h6] <= 16'h0;
				memory[16'h7] <= 16'h0;
				memory[16'h8] <= 16'h0;
				memory[16'h9] <= 16'h0;
				memory[16'ha] <= 16'h0;
				memory[16'hb] <= 16'h0;
				counter <= 6'b111111;
				interrupt <= 0;
			end
		else begin
			if(counter > 0) begin
				counter <= counter - 1;
			end
			else if (counter == 0)begin
				interrupt <= 1;
				counter <= counter -1;
			end
			else begin
				outputData2 <= {memory[address1_start], memory[address1_start + 1], memory[address1_start + 2],  memory[address1_start + 3]};
			end
		end
endmodule