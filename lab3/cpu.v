`include "opcodes.v" 	   

module cpu (readM, writeM, address, data, ackOutput, inputReady, reset_n, clk);
	output readM;									
	output writeM;								
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
	reg IF;

	reg [2:0] ALU_func;
	reg [`WORD_SIZE-1:0] A, B;
	wire [`WORD_SIZE-1:0]C;

	reg [1:0] write_reg;
	reg reg_write;
	reg [`WORD_SIZE-1:0] wb;
	wire [`WORD_SIZE-1:0] read_out1, read_out2;
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
	
	//Use register file module
	register_file REGFILE (
		.read1(rs), 
		.read2(rt), 
		.write_reg(write_reg), 
		.reg_write(reg_write), 
		.write_data(wb), 
		.read_out1(read_out1),
		.read_out2(read_out2));
	//Use ALU module
	alu ALU (.A(A), .B(B), .funcCode(ALU_func), .C(C));
	
	//Instruction fetch OR LOAD
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
			readM <= 0;
			reg_write <= 1;
		end
	end

	//Writeback 
	always @(negedge inputReady) begin
		case(opcode)
			`ALU_OP: begin
				if(func == `INST_FUNC_JRL) begin
					wb <= pc;
					pc <= read_out1;
				end
				else begin
					wb <= C;
				end
				reg_write <= 1;
			end
			`ADI_OP: begin
				wb <= C;
				reg_write <= 1;
			end
			`ORI_OP: begin
				wb <= C;
				reg_write <= 1;
			end
			`LHI_OP: begin
				wb = imm << 8;
				reg_write <= 1;
			end
			`SWD_OP: begin
				writeM <= 1;
			end
		endcase
	end

	//OFF writeM
	always @(posedge ackOutput) begin
		writeM <= 0;
	end

	//Type control after instruction fetch
	always @(negedge IF) begin
		if( opcode == 4'd15) begin 
			control_R_type();
		end
		else if ( opcode == 4'd9 || opcode == 4'd10) begin
			control_J_type();
		end
		else begin 
			control_I_type();
		end 
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


	task control_R_type;
		begin
			A = read_out1;
			B = read_out2;
			write_reg = rd;
			pc = pc + 1;
			case(func)
				`INST_FUNC_ADD: begin ALU_func = `FUNC_ADD; end
				`INST_FUNC_SUB:begin ALU_func = `FUNC_SUB; end
				`INST_FUNC_AND:begin ALU_func = `FUNC_AND; end
				`INST_FUNC_ORR: begin ALU_func = `FUNC_ORR; end
				`INST_FUNC_NOT: begin ALU_func = `FUNC_NOT; end
				`INST_FUNC_TCP: begin ALU_func = `FUNC_TCP; end
				`INST_FUNC_SHL: begin ALU_func = `FUNC_SHL; end
				`INST_FUNC_SHR: begin ALU_func = `FUNC_SHR; end
				`INST_FUNC_JPR: begin 
					pc = read_out1;
				end
				`INST_FUNC_JRL: begin
					write_reg = 2;
				end
			endcase
		end
	endtask

	task control_J_type;
		begin
			if(opcode == `JAL_OP) begin
				write_reg = 2;
				wb = pc;
			end
			pc = {4'd0, target_addr};
		end
	endtask

	task control_I_type;
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
					write_reg = rt;
				end
				`LHI_OP: begin
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