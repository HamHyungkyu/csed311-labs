`define IF1  4'b0000
`define IF2  4'b0001
`define IF3  4'b0010
`define IF4  4'b0011
`define ID   4'b0100
`define EX1  4'b0101
`define EX2  4'b0110
`define MEM1 4'b0111
`define MEM2 4'b1000
`define MEM3 4'b1001
`define MEM4 4'b1010
`define WB   4'b1011
`define INIT 4'b1111

module state_control(clk, reset_n, jal, branch, mem_read, mem_write, readM, writeM, pvs_write_en, i_or_d, ir_write);
    input clk, reset_n, jal, branch, mem_read, mem_write;
    output reg writeM;
    output reg readM;
    output reg pvs_write_en;
    output reg i_or_d;
    output reg ir_write;

    reg [4:0] state;
    reg [4:0] next_state;

    initial begin
        state_init();
    end

    //Operation of each state
    always @(*) begin
        case(state)
            `IF1: begin
                pvs_write_en = 0;
                readM = 1;
                writeM = 0;
                i_or_d = 0;
                ir_write = 1;
                next_state = `IF2;   
            end 
            `IF2: begin
                next_state = `IF3; 
            end
            `IF3: begin
                next_state = `IF4;
            end
            `IF4: begin
                ir_write = 0;
                readM = 0;
                if(jal)begin
                    next_state = `EX1;
                end
                else begin
                    next_state = `ID;
                end
            end
            `ID: begin
                next_state = `EX1;
            end
            `EX1: begin
     
                next_state = `EX2;
            end
            `EX2: begin
                if(branch) begin
                    next_state = `IF1;
                    pvs_write_en = 1;
                end
                else if(mem_read | mem_write) begin 
                    next_state = `MEM1;
                end
                else begin
                    next_state = `WB;
                end
            end
            `MEM1: begin
                i_or_d = mem_write;
                readM = mem_read;
                writeM = mem_write;
                next_state = `MEM2;
            end
            `MEM2: begin
        
                next_state = `MEM3;
            end
            `MEM3: begin
                next_state = `MEM4;
            end
            `MEM4: begin
                readM = 0;
                writeM = 0;
                if(mem_read) begin
                    i_or_d = 0;
                    next_state = `WB;    
                end
                else begin
                    next_state = `IF1;
                    pvs_write_en = 1;
                end
            end
            `WB: begin
                next_state = `IF1;
                pvs_write_en = 1;
            end
        endcase
    end

    always @(posedge clk) begin
        if(!reset_n) begin

        end
        else begin
            state <= next_state;
        end
    end

    task state_init;
        begin
            readM <= 0;
            writeM <= 0;
            pvs_write_en <= 1;
            i_or_d <= 0;
            ir_write <= 0;
            state <= `INIT;
            next_state <= `IF1;
        end
    endtask
endmodule