`define WORD_SIZE 16

module DMA_controller(clk, reset_n, interrupt, length, bg, br, address, offset);
    input clk;
    input reset_n;
    input interrupt;
    input bg;
    input [`WORD_SIZE*4-1:0] length;
    inout [`WORD_SIZE-1:0]address;
	output reg [`WORD_SIZE-1:0] offset;
    output reg br;
    
    reg [`WORD_SIZE-1:0] input_address;
    reg [`WORD_SIZE-1:0] output_address;
    reg bg_before;
    reg interrupt_before;

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
			end
		else begin
            interrupt_before <= interrupt;
            bg_before <= bg;
            if(interrupt_before) begin
                counter <= (length[`WORD_SIZE-1: 0] >> 2) - 1; // number of transaction for 4 words blocks;
                input_address <= address;
                br <= 1;
            end
            else if(br & ~bg & bg_before) begin // When bg down, change counter
                if(counter > 0)
                    counter <= counter - 1;
                else 
                    br <= 0;  
            end
		end
    end
endmodule