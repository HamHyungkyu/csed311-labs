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
	wire [`WORD_SIZE-1:0] num_inst;
	output [`WORD_SIZE-1:0] output_port;
	wire [`WORD_SIZE-1:0] output_port;
	output is_halted;
	wire is_halted;

	reg [`WORD_SIZE-1:0] pc, next_pc;

	//ALU wries
	wire [`WORD_SIZE-1:0] A, B, C;
	wire [2:0] ALU_FUNC;
	
	//Register file
	wire[1:0] rs, rt, rd;
	wire [1:0] write_reg;
	wire [`WORD_SIZE-1:0] wb;
	wire [`WORD_SIZE-1:0] read_out1, read_out2;
	wire reg_write;

	//Control 
	wire alu_src, alu_op, reg_dest, mem_write, mem_read, reg_write, mem_to_reg;

	//Pipeline latches
	//from control
	reg [`WORD_SIZE-1:0] if_id_instruction;
	reg id_ex_alu_src, id_ex_reg_dest;
	reg [3:0] id_ex_alu_op;
	reg id_ex_mem_write, id_ex_mem_read, ex_mem_mem_write, ex_mem_mem_read;
	reg id_ex_reg_write, id_ex_mem_to_reg, ex_mem_reg_write, ex_mem_mem_to_reg, mem_wb_reg_write, mem_wb_mem_to_reg;
	//from instruction
	reg [1:0] id_ex_rd;
	reg [1:0] ex_mem_dest, mem_wb_dest;
	//from ALU
	reg [`WORD_SIZE-1:0] ex_mem_alu_result, mem_wb_alu_result;
	//from register file
	reg [`WORD_SIZE-1:0] ex_mem_read_out2;
	//from data memory
	reg [`WORD_SIZE-1:0] mem_wb_read_data;

	assign rs = if_id_instruction[11:10];
	assign rt = if_id_instruction[9:8];
	assign write_reg = mem_wb_dest;
	assign opcode = if_id_instruction[`WORD_SIZE-1:12];

	alu ALU(.A(A), .B(B), .funcCode(ALU_FUNC), .C(C));
	register_file REG( 
		.read1(rs),
		.read2(rt), 
		.write_reg(write_reg), 
		.write_data(wb), 
		.reg_write(reg_write), 
		.read_out1(read_out1), 
		.read_out2(read_out2), 
		.clk(clk),
	);
	
	control CONTROL();

	initial begin
		init();
	end

	always @(*) begin
		
	end

	always @(posedge Clk) begin
		if(!Reset_N) begin
			init();
		end
		else begin
			
		end
	end

	task init; 
	begin

	end
	endtask

endmodule
