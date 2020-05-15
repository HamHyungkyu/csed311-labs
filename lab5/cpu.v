`timescale 1ns/1ns
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
	reg [`WORD_SIZE-1:0] num_inst;
	output [`WORD_SIZE-1:0] output_port;
	wire [`WORD_SIZE-1:0] output_port;
	output is_halted;
	wire is_halted;

	reg [`WORD_SIZE-1:0] pc, next_pc;

	//ALU wries
	wire [`WORD_SIZE-1:0] A, B, C, sign_extended_imm;
	wire [2:0] ALU_FUNC;
	
	//Register file
	wire[1:0] rs, rt, rd;
	wire [1:0] write_reg;
	wire [`WORD_SIZE-1:0] wb;
	wire [`WORD_SIZE-1:0] read_out1, read_out2;

	//Control 
	wire  mem_write, mem_read, reg_write, mem_to_reg, is_wwd, is_cur_inst_halted;
	wire [1:0] alu_src, reg_dest;
	wire [2:0] alu_op;

	//Forwarding
	wire [1:0] forwardA;
	wire [1:0] forwardB;

	reg instruction_fetech;
	//Pipeline latches
	//from control
	reg [`WORD_SIZE-1:0] if_id_instruction;
	reg [1:0] id_ex_alu_src, id_ex_reg_dest;
	reg [2:0] id_ex_alu_op;
	reg id_ex_is_halted, id_ex_is_wwd;
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

	//Assign wires
	assign address1 = pc;
	assign readM1 = instruction_fetech;
	assign data1 = `WORD_SIZE'bz;
	assign data2 = mem_write ? ex_mem_read_out2 : `WORD_SIZE'bz; 
	assign output_port = id_ex_is_wwd ? A : 0; 
	assign is_halted = id_ex_is_halted;
	//regfile
	assign rs = if_id_instruction[11:10];
	assign rt = if_id_instruction[9:8];
	assign write_reg = mem_wb_dest;
	assign wb = mem_wb_mem_to_reg ? mem_wb_read_data : mem_wb_alu_result;
	assign rd = mem_wb_dest;
	//ALU 
	//Forwarding Considered
	assign sign_extended_imm = (if_id_instruction[7] == 1)? {8'hff, if_id_instruction[7:0]} : {8'h00, if_id_instruction[7:0]};
	assign A = (forwardA == 2'b00) ? id_ex_read_out1 
		: ((forwardA == 2'b01) ? mem_wb_alu_result 
		: ex_mem_alu_result); 
	assign B = (id_ex_alu_src == 2'b01) ? id_ex_sign_extended_imm 
	: (id_ex_alu_src == 2'b10) ? 1
	: (id_ex_alu_src == 2'b11) ? 8
	: ((forwardB == 2'b00) ? id_ex_read_out2 : 
	((forwardB == 2'b01) ? mem_wb_alu_result : ex_mem_alu_result));
	assign ALU_FUNC = alu_op; 
	//Data memory
	assign address2 = ex_mem_alu_result;
	assign readM2 = ex_mem_mem_read;
	assign writeM2 = ex_mem_mem_write;
	
	alu ALU(.A(A), .B(B), .funcCode(ALU_FUNC), .C(C));
	register_file REG( 
		.read1(rs),
		.read2(rt), 
		.write_reg(write_reg), 
		.write_data(wb), 
		.reg_write(reg_write), 
		.read_out1(read_out1), 
		.read_out2(read_out2), 
		.clk(Clk)
	);
	control CONTROL(
		.instruction(if_id_instruction), 
		.alu_src(alu_src),
		.alu_op(alu_op), 
		.reg_dest(reg_dest), 
		.mem_write(mem_write), 
		.mem_read(mem_read), 
		.reg_write(reg_write), 
		.mem_to_reg(mem_to_reg),
		.is_halted(is_cur_inst_halted),
		.is_wwd(is_wwd)
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

	initial begin
		init();
	end

	always @(*) begin
		next_pc = pc + 1;
	end

	always @(posedge Clk) begin
		if(!Reset_N) begin
			init();
		end
		else begin
			if(!is_cur_inst_halted) begin
				pc <= next_pc;
				num_inst <= num_inst + 1;
				instruction_fetech <= 1;
			end

			if_id_instruction <= data1;
			
			id_ex_alu_op <= alu_op;
			id_ex_alu_src <= alu_src;
			id_ex_reg_dest <= reg_dest;
			id_ex_mem_read <= mem_read;
			id_ex_mem_to_reg <= mem_to_reg;
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

			ex_mem_alu_result <= C;
			ex_mem_read_out2 <= id_ex_read_out2;
			if(reg_dest == 2'b00) 
				ex_mem_dest <= id_ex_rd;
			else if (reg_dest == 2'b01)
				ex_mem_dest <= id_ex_rt;
			else 
				ex_mem_dest <= 2'b10;
			ex_mem_mem_read <= id_ex_mem_read;
			ex_mem_mem_write <= id_ex_mem_write;
			ex_mem_mem_to_reg <= id_ex_mem_to_reg;
			ex_mem_reg_write <= id_ex_reg_write;

			mem_wb_dest <= ex_mem_dest;
			mem_wb_alu_result <= ex_mem_alu_result;
			mem_wb_read_data <= data2;
			mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
			mem_wb_reg_write <= ex_mem_reg_write;
		end
	end

	task init; 
	begin
		pc <= 0;
		next_pc <= 1;
		num_inst <= 0;
	end
	endtask

endmodule
