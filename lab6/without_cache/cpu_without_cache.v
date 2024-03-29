`timescale 1ns/1ns
`include "opcodes.v"
`define WORD_SIZE 16    // data and address word size

module cpu(Clk, Reset_N, readM1, address1, data1, readM2, writeM2, address2, data2, num_inst, output_port, is_halted);
	input Clk;
	wire Clk;
	input Reset_N;
	wire Reset_N;

	output readM1;
	wire readM1;
	output [`WORD_SIZE-1:0] address1;
	wire [`WORD_SIZE-1:0] address1;
	output readM2;
	wire readM2;
	output writeM2;
	wire writeM2;
	output [`WORD_SIZE-1:0] address2;
	wire [`WORD_SIZE-1:0] address2;

	input [`WORD_SIZE-1:0] data1;
	wire [`WORD_SIZE-1:0] data1;
	inout [`WORD_SIZE-1:0] data2;
	wire [`WORD_SIZE-1:0] data2;

	output [`WORD_SIZE-1:0] num_inst;
	wire [`WORD_SIZE-1:0] num_inst;
	output [`WORD_SIZE-1:0] output_port;
	wire [`WORD_SIZE-1:0] output_port;
	output is_halted;
	wire is_halted;

	reg [`WORD_SIZE-1:0] pc, next_pc, target;
	reg is_stall, bcond;
	//ALU wries
	wire [`WORD_SIZE-1:0] A, B, C, sign_extended_imm;
	
	//Register file
	wire[1:0] rs, rt;
	wire [`WORD_SIZE-1:0] ex_mem_wb, wb;
	wire [`WORD_SIZE-1:0] read_out1, read_out2;

	//Control 
	reg flush;
	wire  mem_write, mem_read, reg_write, mem_to_reg, pc_to_reg, is_wwd, is_cur_inst_halted, jtype_jump, rtype_jump, branch;
	wire [1:0] alu_src, reg_dest;
	wire [2:0] alu_op;
	
	//Forwarding
	wire [1:0] forwardA;
	wire [1:0] forwardB;

	//BTB
	wire [`WORD_SIZE-1:0] pred_pc;
	wire pred_taken;
	reg [`WORD_SIZE-1:0] btb_target;

	reg instruction_fetech;
	//Pipeline latches
	reg [`WORD_SIZE-1:0] pc_num_inst, if_id_num_inst, id_ex_num_inst, id_ex_jump_target_addr;
	reg [`WORD_SIZE-1:0] if_id_pc, id_ex_pc;
	reg [`WORD_SIZE-1:0] if_id_pc_plus_one, id_ex_pc_plus_one, ex_mem_pc_plus_one, mem_wb_pc_plus_one;
	reg [3:0] id_ex_opcode;
	//from control
	reg [`WORD_SIZE-1:0] if_id_instruction;
	reg [1:0] id_ex_alu_src, id_ex_reg_dest;
	reg [2:0] id_ex_alu_op;
	reg id_ex_pc_to_reg, ex_mem_pc_to_reg, mem_wb_pc_to_reg;
	reg id_ex_is_halted, id_ex_is_wwd, id_ex_jtype_jump, id_ex_branch, id_ex_rtype_jump;
	reg id_ex_mem_write, id_ex_mem_read, ex_mem_mem_write, ex_mem_mem_read;
	reg id_ex_reg_write, id_ex_mem_to_reg, ex_mem_reg_write, ex_mem_mem_to_reg, mem_wb_reg_write, mem_wb_mem_to_reg;
	//from instruction
	reg [`WORD_SIZE-1:0] id_ex_sign_extended_imm;
	reg [1:0] id_ex_rd, id_ex_rt, id_ex_rs;
	reg [1:0] ex_mem_dest, mem_wb_dest;
	//from ALU
	reg [`WORD_SIZE-1:0] ex_mem_alu_result, mem_wb_alu_result;
	//from register file
	reg [`WORD_SIZE-1:0] id_ex_read_out1, id_ex_read_out2, ex_mem_read_out2;
	//from data memory
	reg [`WORD_SIZE-1:0] mem_wb_read_data;

	//
	reg [`WORD_SIZE-1:0] if_id_pred_pc, id_ex_pred_pc;

	//Assign wires
	assign address1 = pc;
	assign readM1 = instruction_fetech;
	assign data1 = `WORD_SIZE'bz;
	assign data2 = ex_mem_mem_write ? ex_mem_read_out2 : `WORD_SIZE'bz; 
	assign output_port = id_ex_is_wwd ? A : 0; 
	assign is_halted = id_ex_is_halted;
	assign num_inst = id_ex_num_inst;
	//regfile
	assign rs = if_id_instruction[11:10];
	assign rt = if_id_instruction[9:8];
	assign ex_mem_wb = ex_mem_pc_to_reg ? ex_mem_pc_plus_one : ex_mem_alu_result;
	assign wb = mem_wb_mem_to_reg ? mem_wb_read_data : 
				mem_wb_pc_to_reg ? mem_wb_pc_plus_one : 
				mem_wb_alu_result;
	//ALU 
	//Forwarding Considered
	assign sign_extended_imm = (if_id_instruction[7] == 1)? {8'hff, if_id_instruction[7:0]} : {8'h00, if_id_instruction[7:0]};
	assign A = (forwardA == 2'b00) ? ((id_ex_alu_src == 2'b11) ? id_ex_sign_extended_imm: id_ex_read_out1)
		: ((forwardA == 2'b01) ? wb 
		: ex_mem_wb); 
	assign B = (id_ex_alu_src == 2'b01) ? id_ex_sign_extended_imm 
	: (id_ex_alu_src == 2'b10) ? 1
	: (id_ex_alu_src == 2'b11) ? 8
	: ((forwardB == 2'b00) ? id_ex_read_out2 : 
	((forwardB == 2'b01) ? wb : ex_mem_wb));
	//Data memory
	assign address2 = ex_mem_alu_result;
	assign readM2 = ex_mem_mem_read;
	assign writeM2 = ex_mem_mem_write;
	
	alu ALU(.A(A), .B(B), .funcCode(id_ex_alu_op), .C(C));
	register_file REG( 
		.read1(rs),
		.read2(rt), 
		.write_reg(mem_wb_dest), 
		.write_data(wb), 
		.reg_write(mem_wb_reg_write), 
		.read_out1(read_out1), 
		.read_out2(read_out2), 
		.clk(Clk)
	);
	control CONTROL(
		.instruction(if_id_instruction), 
		.flush(flush),
		.alu_src(alu_src),
		.alu_op(alu_op), 
		.reg_dest(reg_dest), 
		.mem_write(mem_write), 
		.mem_read(mem_read), 
		.reg_write(reg_write), 
		.mem_to_reg(mem_to_reg),
		.pc_to_reg(pc_to_reg),
		.is_halted(is_cur_inst_halted),
		.is_wwd(is_wwd),
		.jtype_jump(jtype_jump),
		.rtype_jump(rtype_jump),
		.branch(branch)
	);
	forwarding_unit FORWARDING(
		.ID_EX_Rs(id_ex_rs),
		.ID_EX_Rt(id_ex_rt),
		.EX_MEM_Reg_Rd(ex_mem_dest),
		.MEM_WB_Reg_Rd(mem_wb_dest),
		.RegWrite_MEM(ex_mem_reg_write),
		.RegWrite_WB(mem_wb_reg_write),
		.ForwardA(forwardA),
		.ForwardB(forwardB)
	);
	btb BTB(
		.clk(Clk),
		.reset_n(Reset_N),
		.if_pc(pc),
		.if_btb_pc(pred_pc),
		.if_btb_taken(pred_taken),
		.id_pc(id_ex_pc),
		.branch(id_ex_branch),
		.jump(id_ex_jtype_jump || id_ex_rtype_jump),
		.bcond(bcond),
		.target(btb_target)
	);

	initial begin
		init();
	end

	always @(*) begin
		//Calculate bcond
		if(id_ex_branch) begin
			target = id_ex_pc_plus_one + id_ex_sign_extended_imm;
			case(id_ex_opcode)
			`BNE_OP: begin
				if(A != B) bcond = 1;
				else bcond = 0;
			end
			`BEQ_OP: begin
				if(A == B) bcond = 1;
				else bcond = 0;
			end
			`BGZ_OP: begin
				if(A[15] == 0 && A > 0) bcond = 1;
				else bcond = 0;
			end
			`BLZ_OP: begin
				if(A[15] == 1) bcond = 1;
				else bcond = 0;
			end
			endcase
		end

		//Stall conditons
		// 1. J type jump target miss match 
		// 2. R type jump target miss match
		// 3. Branch miss predict - 1 (Real- taken  & Predict - not taken)
		// 4. Branch miss predict - 2 (Real- not taken  & Predict -  taken)
		is_stall = (id_ex_jtype_jump && (id_ex_pred_pc != id_ex_jump_target_addr)) || 
		(id_ex_rtype_jump && (id_ex_pred_pc != A)) || 
		(id_ex_branch && bcond && (id_ex_pred_pc != target)) || 
		(id_ex_branch && ~bcond && (id_ex_pred_pc != id_ex_pc_plus_one));

		next_pc = pred_pc;

		if (id_ex_jtype_jump) begin
			btb_target = id_ex_jump_target_addr;
		end
		else if (id_ex_rtype_jump) begin
			btb_target = A;
		end
		else if (id_ex_branch && bcond) begin
			btb_target = target;
		end
	end

	always @(posedge Clk) begin
		if(!Reset_N) begin
			init();
		end
		else begin
			//Contorl handling
			//stall condition 1, 2, 3, 4, mem_read or normal progress
			if (id_ex_jtype_jump && (id_ex_pred_pc != id_ex_jump_target_addr)) begin
				pc <= id_ex_jump_target_addr;
				instruction_fetech <= 1;
			end
			else if (id_ex_rtype_jump && (id_ex_pred_pc != A)) begin
				pc <= A;
				instruction_fetech <= 1;
			end
			else if (id_ex_branch && bcond && (id_ex_pred_pc != target)) begin
				pc <= target;
				instruction_fetech <= 1;
			end
			else if (id_ex_branch && ~bcond && id_ex_pred_pc != id_ex_pc_plus_one) begin
				pc <= id_ex_pc_plus_one;
				instruction_fetech <= 1;
			end
			else if(is_cur_inst_halted) begin
				instruction_fetech <= 0;
			end
			else if (mem_read) begin
				instruction_fetech <= 1;
				pc_num_inst <= pc_num_inst;
			end
			else begin
				pc <= next_pc;
				pc_num_inst <= pc_num_inst + 1;
				instruction_fetech <= 1;
			end

			//Progress pipeline
			if_id_pc <= pc;
			if_id_pc_plus_one <= pc + 1;
			if_id_instruction <= data1;
			if_id_pred_pc <= pred_pc;

			//Flush control outputs
			if(mem_read || is_stall) begin
				flush <= 1;
				if_id_num_inst <= if_id_num_inst;
			end
			else begin
				flush <= 0;
				if_id_num_inst <= pc_num_inst;
			end
			//Ignore contorl unit outputs when it is stall condion
			if(is_stall) begin
				id_ex_pc <= id_ex_pc;
				id_ex_pc_plus_one <= id_ex_pc_plus_one;
				id_ex_pred_pc <= 0;
				id_ex_branch <= 0;
				id_ex_rtype_jump <= 0;
				id_ex_jtype_jump <= 0;
				id_ex_alu_op <= 0;
				id_ex_alu_src <= 0;
				id_ex_reg_dest <= 0;
				id_ex_mem_read <= 0;
				id_ex_mem_to_reg <= 0;
				id_ex_pc_to_reg <= 0;
				id_ex_mem_write <= 0;
				id_ex_reg_write <= 0;
				id_ex_rd <= 0;
				id_ex_rt <= 0;
				id_ex_rs <= 0;
				id_ex_read_out1 <= 0;
				id_ex_read_out2 <= 0;
				id_ex_sign_extended_imm <= 0;
				id_ex_is_halted <= 0;
				id_ex_is_wwd <= 0;
				pc_num_inst <= if_id_num_inst;
				if_id_num_inst <= id_ex_num_inst;
				id_ex_num_inst <= id_ex_num_inst;
			end
			else begin
				id_ex_pc <= if_id_pc;
				id_ex_pc_plus_one <= if_id_pc_plus_one;
				id_ex_pred_pc <= if_id_pred_pc;
				id_ex_branch <= branch;
				id_ex_rtype_jump <= rtype_jump;
				id_ex_jtype_jump <= jtype_jump;
				id_ex_opcode <= if_id_instruction[15:12];
				id_ex_jump_target_addr <= {if_id_pc_plus_one[15:12], if_id_instruction[11:0]};
				id_ex_alu_op <= alu_op;
				id_ex_alu_src <= alu_src;
				id_ex_reg_dest <= reg_dest;
				id_ex_mem_read <= mem_read;
				id_ex_mem_to_reg <= mem_to_reg;
				id_ex_pc_to_reg <= pc_to_reg;
				id_ex_mem_write <= mem_write;
				id_ex_reg_write <= reg_write;
				id_ex_rd <= if_id_instruction[7:6];
				id_ex_rt <= rt;
				id_ex_rs <= rs;
				id_ex_read_out1 <= read_out1;
				id_ex_read_out2 <= read_out2;
				id_ex_sign_extended_imm <= sign_extended_imm;
				id_ex_is_halted <= is_cur_inst_halted;
				id_ex_is_wwd <= is_wwd;
				id_ex_num_inst <= if_id_num_inst;	
			end

			ex_mem_pc_plus_one <= id_ex_pc_plus_one;
			ex_mem_alu_result <= C;
			ex_mem_read_out2 <= id_ex_read_out2;
			if(id_ex_reg_dest == 2'b00) 
				ex_mem_dest <= id_ex_rd;
			else if (id_ex_reg_dest == 2'b01)
				ex_mem_dest <= id_ex_rt;
			else 
				ex_mem_dest <= 2'b10;
			ex_mem_mem_read <= id_ex_mem_read;
			ex_mem_mem_write <= id_ex_mem_write;
			ex_mem_mem_to_reg <= id_ex_mem_to_reg;
			ex_mem_pc_to_reg <= id_ex_pc_to_reg;
			ex_mem_reg_write <= id_ex_reg_write;

			mem_wb_pc_plus_one <= ex_mem_pc_plus_one;
			mem_wb_dest <= ex_mem_dest;
			mem_wb_alu_result <= ex_mem_alu_result;
			mem_wb_read_data <= data2;
			mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
			mem_wb_pc_to_reg <= ex_mem_pc_to_reg;
			mem_wb_reg_write <= ex_mem_reg_write;
		end
	end

	//Initialize task
	task init; 
	begin
		pc <= 0;
		next_pc <= 0;
		pc_num_inst <= 0;
		instruction_fetech <= 0;
		flush <= 0;
		id_ex_mem_write <= 0;
		ex_mem_mem_write <= 0;
		id_ex_reg_write <= 0;
		ex_mem_reg_write <= 0;
		mem_wb_reg_write <= 0;
	end
	endtask

endmodule
