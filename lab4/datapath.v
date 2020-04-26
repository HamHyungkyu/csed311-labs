`include "opcodes.v" 

module datapath(clk, reset_n, readM, writeM, address, data, num_inst, output_port, is_halted,
				jal, branch, mem_read, mem_write, alu_src, reg_write, pvs_write_en);
	
	// datapath from CPU
	input clk;
	input reset_n;
	input readM;
	input writeM;
	output address;
	inout data;
	output reg [`WORD_SIZE-1:0] num_inst;
	output reg [`WORD_SIZE-1:0] output_port;
	output reg is_halted;



	// Register File
	reg [1:0] rs, rt, rd;
	reg [1:0] write_reg;
	reg [`WORD_SIZE-1:0] wb;
	reg reg_write;
	wire [`WORD_SIZE-1:0] read_out1, read_out2

	// ALU
	reg [`WORD_SIZE-1:0] A, B;
	reg [2:0] ALU_func;
	wire [`WORD_SIZE-1:0] C;

	assign data = (opcode == `SWD_OP && IF != 1) ? read_out2 : `WORD_SIZE'bz;

	//initailization 
	initial begin
		readM <= 0;
		writeM <= 0;
		address <= 0;
		pc <= 0;
		IF <= 0;
		ALU_func <= 0;
		A <= 0;
		B <= 0;
		reg_write = 0;
		opcode <= 0;
	end



	always @(posedge clk) begin
		if(IF == 1)begin

			readM <= 0;
			IF <= 0;			
		end
		else if(opcode == `LWD_OP) begin
			write_reg <= rt;
			wb <= data;
			readM <= 0;
			reg_write <= 1;
		end
	end

	always @(*) begin
	

		if(pc_to_reg) wb = pc + 1;
		else begin
			if(mem_to_reg) begin
				//
			end
			else wb = C;
		end

		if(alu_src) begin
			read_out2 = sign_extended_imm;
		end


	end

endmodule