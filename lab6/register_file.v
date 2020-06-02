module register_file(read1, read2, write_reg, write_data, reg_write, read_out1, read_out2, clk); 
    output reg [15:0] read_out1;
    output reg [15:0] read_out2;
    input [1:0] read1;
    input [1:0] read2;
    input [1:0] write_reg;
    input [15:0] write_data;
    input clk;
    input reg_write;

    reg [15:0] registers [3:0];

    //Init
    initial begin
        registers[0] <= 16'h0;
        registers[1] <= 16'h0;
        registers[2] <= 16'h0;
        registers[3] <= 16'h0;
    end

    always @(*) begin
        read_out1 = registers[read1];
        read_out2 = registers[read2];
        //forward dist 3
        if(reg_write && (read1) == write_reg)
            read_out1 = write_data;
        else if(reg_write && (read2) == write_reg)
            read_out2 = write_data;
    end

    //Write
    always @(posedge clk) begin

    	if(reg_write) begin
    		registers[write_reg] <= write_data;
            $display("REg write");
            $display("%x", registers[0]);
            $display("%x", registers[1]);
            $display("%x", registers[2]);
            $display("%x", registers[3]);

    	end
    end
endmodule

