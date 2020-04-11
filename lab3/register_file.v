module register_file(read1, read2, write_reg, write_data, regwrite, clk, read_out1, read_out2); 
    output [15:0] read_out1;
    output [15:0] read_out2;
    input read1;
    input read2;
    input write_reg;
    input [15:0] write_data;
    input regwrite;
    input clk;

    reg [15:0] registers [3:0];

    //Read
    assign read_out1 = registers[read1];
    assign read_out2 = registers[read2];

    //Write
    always @(negedge clk) begin
    	if(regwrite) begin
    		registers[write_reg] <= write_data;
    	end
    end
endmodule

