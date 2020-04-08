`include "opcodes.v" 	   

module cpu (readM, writeM, address, data, ackOutput, inputReady, reset_n, clk);
	output readM;									
	output writeM;								
	output [`WORD_SIZE-1:0] address;	
	inout [`WORD_SIZE-1:0] data;		
	input ackOutput;								
	input inputReady;								
	input reset_n;									
	input clk;			
	
	reg [`WORD_SIZE-1:0] pc;
	reg [3:0] opcode;
	reg [1:0] rs, rt, sd;
	reg [5:0] func;
	reg [7:0] imm;
	reg [11:0] target_addr;
	reg [1:0] instr_type;

	parameter R = 2'b00, I = 2'b01, J=2'

	//initailization 
	initial begin
		readM <= 0;
		writeM <= 0;
		address <= 0;
		pc <= 0;
	end

	//IF
	always @(posedge inputReady) begin
		opcode <= data[`WORD_SIZE-1:12];
		target_addr <= data[11:0];
		rs <= data[11:10];
		rt <= dat[9:8];
		rd <= data[7:6];
		func <= data[5:0];
		imm <= data[7:0];
	end

	//Type define
	always(*) begin
		if( opcode == 4'd15) instr_type = R;
		else if ( opcode == 4'd9 || opcode == 4'10) instr_type = J;
		else instr_type = I;
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
			address <= pc;
		end
	end

	always @(negedge clk) begin
		
	end

endmodule							  																		  