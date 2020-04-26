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

	reg [`WORD_SIZE-1:0] pc;

	//Contorl output
	wire jal, branch, mem_read, mem_write, alu_src, reg_write, mem_to_reg, pvs_write_en, i_or_d, ir_write; 

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

	assign data = i_or_d ? read_out2 : `WORD_SIZE'bz;

	//Contorl module
	control CONTROL(.instr(opcode), .clk(clk), .jal(jal), .branch(branch), .mem_read(readM), .mem_write(writeM), .alu_src(alu_src),
	 .reg_write(reg_write), .mem_to_reg(mem_to_reg), .pvs_write_en(pvs_write_en), .i_or_d(i_or_d), .ir_write(ir_write));
	
	// ALU Control Module
	alu_control ALU_CONTROL(.aluOp(opcode), .instFuncCode(func), .funcCode(ALU_func));

	// Register File Module
	register_file REG( 
		.read1(rs),
		.read2(rt), 
		.write_reg(write_reg), 
		.write_data(wb), 
		.reg_write(reg_write), 
		.read_out1(read_out1), 
		.read_out2(read_out2), 
		.clk(clk),
		.pvs_write_en(pvs_write_en)
	);

	// ALU Module 
	alu ALU(.A(read_out1), .B(read_out2), .funcCode(ALU_func), .C(C));

	

	//Todo :PC controller & Branch condition

	
	always @(*) begin
		//Write instruction register
		if(ir_write) begin
			opcode = data[`WORD_SIZE-1:12];
			target_addr = {4'd0, data[11:0]};
			rs = data[11:10];
			rt = data[9:8];
			rd = data[7:6];
			func = data[5:0];
			imm = data[7:0];
			if(imm[7] == 1) sign_extended_imm = {8'hff, imm};
			else sign_extended_imm = {8'h00, imm};
		end
	end


	always @(posedge clk) begin
		if(!reset_n) begin
		end
		else begin
			
		end
	end

endmodule
