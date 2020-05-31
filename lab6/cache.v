`define WORD_SIZE 16    // data and address word size

module cache (address, mem_read, mem_write, mem_fetch_input, data, read_ack, write_ack, reset_n, clk, 
is_hit, mem_fetch_output, req_mem_read, req_mem_read_address, req_mem_write, req_mem_write_address);
    // Address format in this cache 
    // 15~3 : tag bits
    // 2  : index
    // 1~0  : block offset
    input [`WORD_SIZE-1:0] address;
    input mem_read;
    input mem_write;
    input [`WORD_SIZE*4-1:0] mem_fetch_input;
    input [`WORD_SIZE-1:0] data;
    input read_ack, write_ack;
    input clk;
    input reset_n;
    output is_hit;
    reg [`WORD_SIZE-1:0] output_data;

    assign data = mem_write ? `WORD_SIZE'bz : output_data;
    output reg [`WORD_SIZE*4-1:0]mem_fetch_output;
    output reg req_mem_read;
    output reg [`WORD_SIZE-1:0] req_mem_read_address;
    output reg req_mem_write;
    output reg [`WORD_SIZE-1:0] req_mem_write_address;

    //Banks
    reg [`WORD_SIZE - 6:0] tag_bank [1:0][1:0];
    reg valid_bank [1:0][1:0];
    reg resently_used_bank [1:0][1:0];
    reg dirty_bit_bank [1:0][1:0];
    reg [`WORD_SIZE*4-1:0] data_bank [1:0][1:0];

    reg [`WORD_SIZE*4-1:0] hitted_line;
    reg target_bank;
    reg write_back;
    reg waiting;

    wire [8:0] address_tag = address[`WORD_SIZE-1: 3];
    wire address_idx = address[2];
    wire [1:0] address_block_offset = address[1:0];
    
    wire tag_comparator_0 = tag_bank[0][address_idx] == address_tag;
    wire tag_comparator_1 = tag_bank[1][address_idx] == address_tag;
    wire bank_hit_0 = tag_comparator_0 & valid_bank[0][address_idx];
    wire bank_hit_1 = tag_comparator_1 & valid_bank[1][address_idx];
    assign is_hit = bank_hit_0 | bank_hit_1;

    initial begin
        init_cache();
    end

    always @(*) begin
        if(is_hit) begin
            if(bank_hit_0)begin
                target_bank = 0;
                hitted_line = data_bank[0][address_idx];
                resently_used_bank[0][address_idx] = 1;
                resently_used_bank[1][address_idx] = 0;
            end
            else begin
                target_bank = 1;
                hitted_line = data_bank[1][address_idx];
                resently_used_bank[0][address_idx] = 0;
                resently_used_bank[1][address_idx] = 1;
            end 
            if(mem_write) begin
                dirty_bit_bank[target_bank][address_idx] = 1;
                case (address_block_offset)
                    2'b00: hitted_line = {data, hitted_line[`WORD_SIZE*3-1:0]};
                    2'b01: hitted_line = {hitted_line[`WORD_SIZE*4-1: `WORD_SIZE*3], data, hitted_line[`WORD_SIZE*2-1:0]};
                    2'b10: hitted_line = {hitted_line[`WORD_SIZE*4-1: `WORD_SIZE*2], data, hitted_line[`WORD_SIZE*1-1:0]};
                    2'b11: hitted_line = {hitted_line[`WORD_SIZE*4-1: `WORD_SIZE*1], data};
                endcase  
            end                               
        end
        else begin
            req_mem_read_address = {address[`WORD_SIZE-1:2], 2'b00};
            if(~valid_bank[0][address_idx]) begin
                target_bank = 0;
            end
            else if (~valid_bank[1][address_idx]) begin
                target_bank = 1;
            end
            else begin // Evict LRU
                target_bank = resently_used_bank[0][address_idx] ? 1 : 0;
                if(dirty_bit_bank[target_bank][address_idx]) //Write back only when it is dirty
                    write_back = 1;
                req_mem_write_address = {tag_bank[target_bank][address_idx], address_idx, 2'b00};
                tag_bank[target_bank][address_idx] = address_tag;
                valid_bank[target_bank][address_idx] = 0;
            end
        end
    end

    always @(posedge clk) begin
        if(!reset_n) begin
            init_cache();
        end
        else begin
            //Cache hit
            if(is_hit) begin
                if(mem_read) begin
                    case (address_block_offset)
                        2'b00: output_data <= hitted_line[`WORD_SIZE*4-1: `WORD_SIZE*3];
                        2'b01: output_data <= hitted_line[`WORD_SIZE*3-1: `WORD_SIZE*2];
                        2'b10: output_data <= hitted_line[`WORD_SIZE*2-1: `WORD_SIZE*1];
                        2'b11: output_data <= hitted_line[`WORD_SIZE-1: 0];
                    endcase
                end
                else if(mem_write) begin
                    data_bank[target_bank][address_idx] <= hitted_line;
                end  
            end
            else begin
                if(read_ack) begin
                    if(waiting) begin
                        valid_bank[target_bank][address_idx] <= 1;
                        dirty_bit_bank[target_bank][address_idx] <= 0;
                        data_bank[target_bank][address_idx] <= mem_fetch_input;
                        resently_used_bank[target_bank][address_idx] <= 1;
                        resently_used_bank[~target_bank][address_idx] <= 0;
                        waiting <= 0;
                    end
                    else if(~waiting & (mem_read | mem_write)) begin
                        req_mem_read <= 1;
                        if(write_back & write_ack) begin
                            req_mem_write <= 1;
                        end
                        waiting <= 1;
                    end
                end
            end
        end
    end

    task init_cache;
    begin
       valid_bank[0][0] <= 0;
       valid_bank[0][1] <= 0;
       valid_bank[1][0] <= 0;
       valid_bank[1][1] <= 0;
       waiting <= 0;
       write_back <= 0;
    end
    endtask

endmodule
