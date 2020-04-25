`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

module cpu(clk, reset_n, readM, writeM, address, data, num_inst, output_port, is_halted);
	// CPU
	input clk;
	input reset_n;
	output readM;
	output writeM;
	output [`WORD_SIZE-1:0] address;
	inout [`WORD_SIZE-1:0] data;
	output [`WORD_SIZE-1:0] num_inst;		// number of instruction during execution (for debuging & testing purpose)
	output [`WORD_SIZE-1:0] output_port;	// this will be used for a "WWD" instruction
	output is_halted;

	contorl CONTORL(.instr, .clk(clk), .jal(), .branch(), .mem_read(), .mem_write(), .alu_src(),
	 .reg_write(), .pvs_write_en());
	datapath DATAPATH(.clk(), .reset_n(), .readM(), .writeM(), .address(), .data(), .num_inst(), .output_port(), .is_halted(),
					  .jal(), .branch(), .mem_read(), .mem_write(), .alu_src(), .reg_write(), .pvs_write_en());

endmodule
