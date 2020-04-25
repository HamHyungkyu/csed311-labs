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

	// datapath from Control
	input jal;
	input branch;
	input mem_read;
	input mem_write;
	input alu_src;
	input reg_write;
	input pvs_write_en;

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

	//Clock 
	always @(posedge clk) begin
		if(!reset_n) begin
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
		else begin
			readM <= 1;
			reg_write <= 0;
			writeM <= 0;
			address <= pc;
			IF <= 1;
		end
	end

	always @(posedge clk) begin
		if(IF == 1)begin
			opcode <= data[`WORD_SIZE-1:12];
			target_addr <= data[11:0];
			rs <= data[11:10];
			rt <= data[9:8];
			rd <= data[7:6];
			func <= data[5:0];
			imm <= data[7:0];
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
		if(imm[7] == 1) sign_extended_imm = {8'hff, imm};
		else sign_extended_imm = {8'h00, imm};

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

	// ALU Control Module
	alu_control ALU_CONTROL(.aluOp(opcode), .instFuncCode(func), .funcCode(ALU_func));
endmodule