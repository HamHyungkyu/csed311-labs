module register_file(read1, read2, write_reg, write_data, reg_write, read_out1, read_out2, clk); 
    output [15:0] read_out1;
    output [15:0] read_out2;
    input [1:0] read1;
    input [1:0] read2;
    input [1:0] write_reg;
    input [15:0] write_data;
    input reg_write;
	input clk;

    reg [15:0] registers [3:0];
    //Read
    assign read_out1 = registers[read1];
    assign read_out2 = registers[read2];
    
    initial begin
        registers[0] <= 16'h0;
        registers[1] <= 16'h0;
        registers[2] <= 16'h0;
        registers[3] <= 16'h0;
    end

    //Write
    always @(posedge clk) begin
    	if(reg_write) begin
    		registers[write_reg] <= write_data;
    	end
    end
endmodule

