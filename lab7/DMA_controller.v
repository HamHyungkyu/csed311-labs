`define WORD_SIZE 16

module DMA_controller(clk, reset_n, command, length, bg, br, address, offset, interrupt);
    input clk;
    input reset_n;
    input command;
    input bg;
    input [`WORD_SIZE*4-1:0] length;
    inout [`WORD_SIZE-1:0]address;
	output reg [`WORD_SIZE-1:0] offset;
    output reg br;
    output reg interrupt;
    
    reg [`WORD_SIZE-1:0] input_address;
    reg [`WORD_SIZE-1:0] output_address;
    reg bg_before;
    reg command_before;

    reg [`WORD_SIZE-1:0] counter;

    assign address = bg ? output_address : `WORD_SIZE'bz;

    always@(*) begin
        if(br & bg & ~bg_before) begin // When bg raise up, change offset and address
            output_address = input_address + (counter << 2);
            offset = (counter << 2);
        end
        else if(~bg) begin
            offset = `WORD_SIZE'bz;
        end
    end
    always@(posedge clk) begin
		if(!reset_n)
			begin
                offset <= `WORD_SIZE'bz;
                br <= 0;
                interrupt <= 0;
			end
		else begin
            command_before <= command;
            bg_before <= bg;
            interrupt <= 0;
            if(command_before) begin
                counter <= (length[`WORD_SIZE-1: 0] >> 2) - 1; // number of transaction for 4 words blocks;
                input_address <= address;
                br <= 1;
            end
            else if(br & ~bg & bg_before) begin // When bg down, change counter
                if(counter > 0)
                    counter <= counter - 1;
                else 
                    begin
                        br <= 0;  
                        interrupt <= 1;
                    end
            end
		end
    end
endmodule