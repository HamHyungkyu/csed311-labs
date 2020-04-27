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

	//
	wire [`WORD_SIZE-1] next_pc;
	wire [`WORD_SIZE-1] wb;
	wire bcond;
	wire jalr;
	wire pc_to_reg;

	assign data = i_or_d ? read_out2 : `WORD_SIZE'bz;

	//Contorl module
	control CONTROL(.instr(opcode), .clk(clk), .jal(jal), .branch(branch), .mem_read(readM), .mem_write(writeM), .alu_src(alu_src),
	 .reg_write(reg_write), .mem_to_reg(mem_to_reg), .pvs_write_en(pvs_write_en), .i_or_d(i_or_d), .ir_write(ir_write));
	
	// ALU Control Module
	// Todo : Should add PC to reg signal
	alu_control ALU_CONTROL(.aluOp(opcode), .instFuncCode(func), .funcCode(ALU_func));

	// Register File Module
	register_file REG( 
		.read1(rs),
		.read2(rt), 
		.write_reg(rd), 
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
	//pcsrc1 = jal || (branch && bcond);
	//pcsrc2 = jalr;
	//Todo : Assign wb
	assign next_pc = (jalr == 0) ? (jal || (branch && bcond)) ? pc + sign_extended_imm : pc + 1) : (C); // sign_extended_imm
	assign wb = (pc_to_reg == 1) ? (pc) : ((mem_to_reg == 1) ? data : C); // data fix
	assign address = pc;

	//Todo : num_inst, output_port, is_halted
	// num_inst += 1 when state go to IF1 on ppt.
	assign output_port = ((opcode == 15) && (func == 28)) ? read_out1 : 0; // else 0? to xx?
	assign is_halted = (opcode == 15) && (func == 29);
	// 모든 작업 완료하고 datapath.v 파일 지우기

	initial begin
		init();
	end
	
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
			init();
		end
		else begin
			//Todo:
			if(pvs_write_en) pc <= next_pc;
		end
	end

	always @(*) begin
		//bcond
		case(opcode)
			`BNE_OP: begin
				if(read_out1 != read_out2) bcond = 1;
			end
			`BEQ_OP: begin
				if(read_out1 == read_out2) bcond = 1;
			end
			`BGZ_OP: begin
				if(read_out1 > 0) bcond = 1;
			end
			`BLZ_OP: begin
				if(read_out1 <= read_out2) bcond = 1;
			end
			`JAL_OP: begin
				rd = 2;
				pc_to_reg = 1;
				pc = {4'd0, target_addr};
			end
			`JMP_OP: begin
				pc_to_reg = 1;
				pc = {4'd0, target_addr};
			end
			default: begin
				bcond = 0;
				pc_to_reg = 0;
			end
		endcase

		//jalr
		case(func)
			`INST_FUNC_JPR: begin
				jalr = 1;
			end
			`INST_FUNC_JRL: begin
				jalr = 1;
				rd = 2;
				pc_to_reg = 1;
			end
			default: jalr = 0;
		endcase
	end

	//Initialize task
	task init begin
		pc <= 0;
		address <= 0;
		num_inst <= 0;
		output_port <= 0;
		is_halted <= 0;
		bcond <= 0;
		jalr <= 0;
		pc_to_reg <= 0;
		wb <= 0;
	end
endmodule
