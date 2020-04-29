`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size
`include "opcodes.v" 	   

module cpu(clk, reset_n, readM, writeM, address, data, num_inst, output_port, is_halted);
	// CPU
	input clk;
	input reset_n;
	output readM;
	output writeM;
	output [`WORD_SIZE-1:0] address;
	inout [`WORD_SIZE-1:0] data;
	output reg [`WORD_SIZE-1:0] num_inst;		// number of instruction during execution (for debuging & testing purpose)
	output [`WORD_SIZE-1:0] output_port;	// this will be used for a "WWD" instruction
	output is_halted;

	reg [`WORD_SIZE-1:0] pc, next_pc;

	//Contorl output
	wire jal, branch, mem_read, mem_write, alu_src, reg_write, mem_to_reg;
	
	//State control output
	wire pvs_write_en, i_or_d, ir_write; 

	// Register File
	reg [1:0] rs, rt, rd;
	wire [1:0] write_reg;
	wire [`WORD_SIZE-1:0] wb;
	wire [`WORD_SIZE-1:0] read_out1, read_out2;
	reg [3:0] opcode;
	reg [5:0] func;
	reg [7:0] imm;
	reg [`WORD_SIZE-1:0] sign_extended_imm;
	reg [11:0] target_addr;

	// ALU
	wire [`WORD_SIZE-1:0] A, B;
	wire [2:0] ALU_func;
	wire [`WORD_SIZE-1:0] C;
	wire skip_write_reg;
	//
	reg bcond;
	reg jalr;
	reg pc_to_reg;
	reg [`WORD_SIZE-1:0] data_cpy; // Store input from data to avid 'z'

	assign data = i_or_d ? read_out2 : `WORD_SIZE'bz;
	assign write_reg = alu_src ? rt : rd;

	//Contorl signal module
	control CONTROL(.instr(opcode), .jal(jal), .branch(branch), .mem_read(mem_read), .mem_write(mem_write), .alu_src(alu_src),
	 .reg_write(reg_write), .mem_to_reg(mem_to_reg));
	
	// State control module
	state_control STATE_CONTROL(.clk(clk), .reset_n(reset_n) ,.jal(jal), .branch(branch), .mem_read(mem_read), .mem_write(mem_write),
	 .readM(readM), .writeM(writeM) ,.pvs_write_en(pvs_write_en), .i_or_d(i_or_d), .ir_write(ir_write));
	
	// ALU Control Module
	alu_control ALU_CONTROL(.aluOp(opcode), .instFuncCode(func), .alu_src(alu_src), .read_out1(read_out1), .read_out2(read_out2), 
	.sign_extended_imm(sign_extended_imm), .A(A), .B(B), .funcCode(ALU_func), .skip_write_reg(skip_write_reg));

	// Register File Module
	register_file REG( 
		.read1(rs),
		.read2(rt), 
		.write_reg(write_reg), 
		.write_data(wb), 
		.reg_write(reg_write & ~skip_write_reg), 
		.read_out1(read_out1), 
		.read_out2(read_out2), 
		.clk(clk),
		.pvs_write_en(pvs_write_en)
	);

	// ALU Module 
	alu ALU(.A(A), .B(B), .funcCode(ALU_func), .C(C));

	//Assign wires
	assign address = ((mem_read & ~ir_write & readM) | (mem_write & ~ir_write & writeM))? C : pc; // sign_extended_imm
	assign wb = (pc_to_reg == 1) ? (pc + 1) : ((mem_to_reg == 1) ? data_cpy : C); // data fix
	assign output_port = ((opcode == 15) && (func == 28)) ? read_out1 : 0; // else 0? to xx?
	assign is_halted = (opcode == 15) && (func == 29);

	initial begin
		init();
	end
	
	always @(*) begin
		if(readM) begin
			data_cpy = data;
		end

		//Write instruction register
		if(ir_write) begin
			opcode = data_cpy[`WORD_SIZE-1:12];
			target_addr = {pc[15:12], data_cpy[11:0]};
			rs = data_cpy[11:10];
			rt = data_cpy[9:8];
			rd = data_cpy[7:6];
			func = data_cpy[5:0];
			imm = data_cpy[7:0];
			if(imm[7] == 1) sign_extended_imm = {8'hff, imm};
			else sign_extended_imm = {8'h00, imm};
			bcond = 0;
			jalr = 0;
			pc_to_reg = 0;
		end

		//Branch and jump control
		case(opcode)
			`BNE_OP: begin
				if(read_out1 != read_out2) bcond = 1;
				else bcond = 0;
			end
			`BEQ_OP: begin
				if(read_out1 == read_out2) bcond = 1;
				else bcond = 0;
			end
			`BGZ_OP: begin
				if(read_out1[15] == 0 && read_out1 > 0) bcond = 1;
				else bcond = 0;
			end
			`BLZ_OP: begin
				if(read_out1[15] == 1) bcond = 1;
				else bcond = 0;
			end
			`JAL_OP: begin
				rd = 2;
				pc_to_reg = 1;
			end
			`JMP_OP: begin
				pc_to_reg = 1;
			end
			`ALU_OP: begin
				case(func)
					`INST_FUNC_JPR: begin
						jalr = 1;
					end
					`INST_FUNC_JRL: begin
						jalr = 1;
						rd = 2;
						pc_to_reg = 1;
					end
				endcase
			end
		endcase
		next_pc = (jalr == 0) ? (jal  ? target_addr : ((branch && bcond)? pc + sign_extended_imm + 1 :pc + 1)) : read_out1;
	end

	always @(posedge clk) begin
		if(!reset_n) begin
			init();
		end
		else begin
			if(pvs_write_en) begin
				pc <= next_pc;
				num_inst <= num_inst + 1;
			end
		end
	end
	//Initialize task
	task init; 
	begin
		pc <= 0;
		num_inst <= 0;
		bcond <= 0;
		jalr <= 0;
		pc_to_reg <= 0;
		next_pc <= 0;
		opcode <= 0;
		func <= 0;
		imm <= 0;
		sign_extended_imm <= 0;
		target_addr <= 0;
	end
	endtask
endmodule
