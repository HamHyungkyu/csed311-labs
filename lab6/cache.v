`define WORD_SIZE 16    // data and address word size

module cache (address, mem_read, mem_write, mem_fetch_input, is_fetched, reset_n, clk, is_hit, hit_data, mem_fetch_output, req_mem_read, req_mem_write);
    // Address format in this cache 
    // 15~3 : tag bits
    // 2  : index
    // 1~0  : block offset
    input [`WORD_SIZE-1:0] address;
    input mem_read;
    input mem_write;
    input [`WORD_SIZE*4-1:0]mem_fetch_input;
    input clk;
    input reset_n;
    output is_hit;
    output reg [`WORD_SIZE-1:0] hit_data;
    output reg [`WORD_SIZE*4-1:0]mem_fetch_output;
    output reg req_mem_read;
    output reg req_mem_write;

    //Bank 0
    reg [`WORD_SIZE - 6:0] tag_bank_0 [1:0];
    reg valid_bank_0 [1:0];
    reg resently_used_bank_0 [1:0];
    reg [`WORD_SIZE*4-1:0] data_bank_0 [1:0];
    //Bank 1
    reg [8:0] tag_bank_1[3:0];
    reg valid_bank_1[3:0];
    reg resently_used_bank_1 [1:0];
    reg [`WORD_SIZE*4-1:0] data_bank_1[3:0];
    
    reg [`WORD_SIZE*4-1:0] hitted_line;
    reg target_bank;

    wire [8:0] address_tag = address[`WORD_SIZE-1: 3];
    wire address_idx = address[2];
    wire [1:0] address_block_offset = address[1:0];
    
    wire tag_comparator_0 = tag_bank_0[address_idx] == address_tag;
    wire tag_comparator_1 = tag_bank_0[address_idx] == address_tag;
    wire bank_hit_0 = tag_comparator_0 & valid_bank_0[address_idx];
    wire bank_hit_1 = tag_comparator_1 & valid_bank_1[address_idx];
    assign is_hit = bank_hit_0 | bank_hit_1;

    initial begin
        init_cache();
    end

    always @(*) begin
        if(is_hit) begin
            if(bank_hit_0)begin
                hitted_line = data_bank_0[address_idx];
                resently_used_bank_0[address_idx] = 1;
                resently_used_bank_1[address_idx] = 0;
            end
            else begin
                hitted_line = data_bank_1[address_idx];
                resently_used_bank_0[address_idx] = 0;
                resently_used_bank_1[address_idx] = 1;
            end     
        end
        else begin
            if(~valid_bank_0[address_idx])
                target_bank = 0;
            else if (~valid_bank_1[address_idx])
                target_bank = 1;
            else begin // Evict
                target_bank = resently_used_bank_0[address_idx] ? 1 : 0;
                //Todo eviction?
            end
        end
    end

    always @(posedge clk) begin
        if(!reset_n) begin
            init_cache();
        end
        else begin
        end
    end

    task init_cache;
    begin
       valid_bank_0[0] <= 0;
       valid_bank_0[1] <= 0;
       valid_bank_1[0] <= 0;
       valid_bank_1[1] <= 0;
    end
    endtask

endmodule
