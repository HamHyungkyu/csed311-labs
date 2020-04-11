`include "opcodes.v" 	   

module cpu (readM, writeM, address, data, ackOutput, inputReady, reset_n, clk);
	output reg readM;									
	output reg writeM;								
	output reg [`WORD_SIZE-1:0] address;	
	inout [`WORD_SIZE-1:0] data;		
	input ackOutput;								
	input inputReady;								
	input reset_n;									
	input clk;			
	
	reg [`WORD_SIZE-1:0] pc;
	reg [3:0] opcode;
	reg [1:0] rs, rt, rd;
	reg [5:0] func;
	reg [7:0] imm;
	reg [`WORD_SIZE-1:0] sign_extended_imm;
	reg [11:0] target_addr;
	reg [1:0] instr_type;
	reg IF;

	reg [2:0] ALU_func;
	reg [1:0] A, B;
	wire C;

	reg [1:0] write_reg;
	reg reg_write;
	reg [`WORD_SIZE-1:0] wb;
	wire [`WORD_SIZE-1:0] read_out1, read_out2;
	parameter R = 2'b00, I = 2'b01, J=2'b10;
  	assign data = (opcode == `SWD_OP) ? read_out2 : `WORD_SIZE'bz;

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
	end
	
	register_file REGFILE (
		.read1(rs), 
		.read2(rt), 
		.write_reg(write_reg), 
		.reg_write(reg_write), 
		.write_data(wb), 
		.read_out1(read_out1),
		 .read_out2(read_out2));
	alu ALU (.A(A), .B(B), .FuncCode(ALU_func), .C(C));
	
	//IF
	always @(posedge inputReady) begin
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
		end
	end

	//Type define
	always @(*) begin
		if( opcode == 4'd15) begin
			instr_type = R;
			controll_R_type();
		end
		else if ( opcode == 4'd9 || opcode == 4'd10) begin
			instr_type = J; 
			controll_J_type();
		end
		else begin 
			instr_type = I;
			controll_I_type();
		end 
	end

	always @(posedge clk) begin
		if(!reset_n) begin
			readM <= 0;
			writeM <= 0;
			address <= 0;
			pc <= 0;
			ALU_func <= 0;
		end
		else begin
			readM <= 1;
			reg_write <= 0;
			writeM <= 0;
			address <= pc;
		end
	end

	always @(negedge clk) begin
		if(instr_type == R && func != `INST_FUNC_JPR || opcode == `JAL_OP) begin
			reg_write <= 1;
		end
		else if(opcode == `SWD_OP) begin
			writeM <= 1;
		end
	end

	task controll_R_type;
		begin
			A = read_out1;
			B = read_out1;
			write_reg = rd;

			pc = pc + 1;
			case(func)
				`INST_FUNC_ADD: begin ALU_func = `FUNC_ADD; wb = C; end
				`INST_FUNC_SUB:begin ALU_func = `FUNC_SUB; wb = C; end
				`INST_FUNC_AND:begin ALU_func = `FUNC_AND; wb = C; end
				`INST_FUNC_ORR: begin ALU_func = `FUNC_ORR; wb = C; end
				`INST_FUNC_NOT: begin ALU_func = `FUNC_NOT; wb = C; end
				`INST_FUNC_TCP: begin ALU_func = `FUNC_TCP; wb = C; end
				`INST_FUNC_SHL: begin ALU_func = `FUNC_SHL; wb = C; end
				`INST_FUNC_SHR: begin ALU_func = `FUNC_SHR; wb = C; end
				`INST_FUNC_JPR: begin 
					pc = read_out1;
				end
				`INST_FUNC_JRL: begin
					write_reg = 2;
					wb = pc;
					pc = read_out1;
				end
			endcase
		end
	endtask

	task controll_J_type;
		begin
			if(opcode == `JAL_OP) begin
				write_reg = 2;
				wb = pc;
			end
			pc = {4'd0, target_addr};
		end
	endtask

	task controll_I_type;
		begin
			pc = pc + 1;
			if(imm[7] == 1) sign_extended_imm = {8'hff, imm};
			else sign_extended_imm = {8'h00, imm};
			case(opcode) 
				`ADI_OP: begin
					ALU_func = `FUNC_ADD;
					A = read_out1;
					B = sign_extended_imm;
					wb = C;
					write_reg = rt;
				end
				`ORI_OP: begin
					ALU_func = `FUNC_ORR;
					A = read_out1;
					B = sign_extended_imm;
					wb = C;
					write_reg = rt;
				end
				`LHI_OP: begin
					wb = imm << 8;
					write_reg = rt;
				end
				`BNE_OP: begin
					if(read_out1 != read_out2) pc = pc + sign_extended_imm;
				end
				`BEQ_OP: begin
					if(read_out1 == read_out2) pc = pc + sign_extended_imm;
				end
				`BGZ_OP: begin
					if(read_out1 > 0) pc = pc + sign_extended_imm;
				end
				`BLZ_OP: begin
					if(read_out1 <= read_out2) pc = pc + sign_extended_imm;
				end
				`LWD_OP: begin
					address = read_out1 + sign_extended_imm;
					readM = 1;
				end
				`SWD_OP: begin
					address = read_out1 + sign_extended_imm;
				end
			endcase
		end
	endtask

endmodule							  																		  