<<<<<<< HEAD
module register_file(read1, read2, write_reg, reg_write, write_data, read_out1, read_out2); 
    output read_out1;
    output read_out2;
=======
module register_file(read1, read2, write_reg, write_data, regwrite, clk, read_out1, read_out2); 
    output [15:0] read_out1;
    output [15:0] read_out2;
>>>>>>> a9064c55eb36ea3a5361d29fa026d279c09657cf
    input read1;
    input read2;
    input reg_write;
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

