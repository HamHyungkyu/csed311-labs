`include "opcodes.v"

module Memory(clk, reset_n, readM1, address1, data1, readM2, writeM2, address2, data2, mem_read, mem_write, i_valid, d_ready, d_valid);
	// Address format in this cache 
    // 15~3 : tag bits
    // 2  : index
    // 1~0  : block offset
	input clk;
	input reset_n;
	
	input readM1;
	input [`WORD_SIZE-1:0] address1;
	output reg [`WORD_SIZE-1:0] data1;
	
	input readM2;
	input writeM2;
	input [`WORD_SIZE-1:0] address2;
	inout data2;
	wire [`WORD_SIZE-1:0] data2;

	input mem_read;
	input mem_write;
	output reg i_valid;
	output reg d_ready;
	output reg d_valid;
	
	// I Cache
	reg [12:0] i_tag_bank_0 [1:0];
	reg i_valid_bank_0 [1:0];
	reg [15:0] i_data_bank_0 [3:0];

	reg [12:0] i_tag_bank_1 [1:0];
	reg i_valid_bank_1 [1:0];
	reg [15:0] i_data_bank_1 [3:0];

	// D Cache
	reg [12:0] d_tag_bank_0 [1:0];
	reg d_valid_bank_0 [1:0];
	reg [15:0] d_data_bank_0 [3:0];

	reg [12:0] d_tag_bank_1 [1:0];
	reg d_valid_bank_1 [1:0];
	reg [15:0] d_data_bank_1 [3:0];

	// Memory.v
	reg [`WORD_SIZE-1:0] outputData2;
	
	wire i_tag = address1[15:3];
	wire i_idx = address1[2];
	wire i_bo = address1[1:0];

	wire d_tag = address2[15:3];
	wire d_idx = address2[2];
	wire d_bo = addess2[1:0];

	wire i_hit_0 = (i_tag_bank_0[i_idx] == i_tag) && i_valid_bank_0[i_idx];
	wire i_hit_1 = (i_tag_bank_1[i_idx] == i_tag) && i_valid_bank_1[i_idx];
	wire d_hit_0 = (d_tag_bank_0[d_idx] == d_tag) && d_valid_bank_0[d_idx];
	wire d_hit_1 = (d_tag_bank_1[d_idx] == d_tag) && d_valid_bank_1[d_idx];

	assign i_hit = i_hit_0 || i_hit_1;
	assign d_hit = d_hit_0 || d_hit_1; 
	assign data2 = readM2 ? outputData2: `WORD_SIZE'bz;

	initial begin
        init_cache();
    end

	always @ (posedge clk)
		if(!reset_n) begin
			init_cache();
		end
		else begin
			if(i_hit || d_hit) begin
				if(readM1) begin
					i_data_bank = //using target_bank?
					data1 <= (writeM2 & address1==address2) ? data2 : i_data_bank;
				end
				if(readM2) begin
					d_data_bank = //
					outputData2 <= d_data_bank;
				end
			end

			//Memory.v
			/*
			if(readM1) data1 <= (writeM2 & address1==address2) ? data2:memory[address1];
			if(readM2) outputData2 <= memory[address2];
			if(writeM2) memory[address2] <= data2;
			*/													  
		end

	task init_cache;
    begin

    end
    endtask
endmodule