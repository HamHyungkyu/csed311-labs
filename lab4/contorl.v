`define IF1  4'b0000;
`define IF2  4'b0001;
`define IF3  4'b0010;
`define IF4  4'b0011;
`define ID   4'b0100;
`define EX1  4'b0101;
`define EX2  4'b0110;
`define MEM1 4'b0111;
`define MEM2 4'b1000;
`define MEM3 4'b1001;
`define MEM4 4'b1010;
`define WB   4'b1011;
`define INIT 4'b1111;

module contorl(instr, clk, jal, branch, mem_read, mem_write, alu_src, reg_write, pvs_write_en);
    input [4:0] instr;
    input clk;
    output jalr;
    output jal;
    output branch;
    output mem_read;
    output mem_write;
    output alu_src;
    output reg_write;
    output pvs_write_en;

    reg [4:0] state;
    reg [4:0] next_state;
    
    wire rtype;
    wire itype;
    wire lw;
    wire sw;
    wire br;
    wire jp;

    assign rtype = instr[0] & instr[1] & instr[2] & instr[3]; // 15
    assign itype = ~instr[3] | (~instr[0] & ~instr[1] & ~instr[2] & instr[3]); // 0~8
    assign lw = ~instr[3] &  instr[2] &  instr[1] &  instr[0]; // 7
    assign sw =  instr[3] & ~instr[0] & ~instr[1] & ~instr[2]; // 8
    assign br = ~instr[3] & ~instr[2]; //0 ~3
    assign jp =  instr[3] & ~instr[2] & (instr[1] ^ instr[0]); // 9, 10

    initial begin
        jalr <= 0;
        jal <= 0;
        branch <= 0;
        mem_read <= 0;
        mem_write <= 0;
        alu_src <= 0;
        reg_write <= 0;
        pvs_write_en <= 0;
        state <= `INIT;
    end

    always @(posedge clk) begin
        
    end

endmodule