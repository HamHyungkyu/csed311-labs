module control(instr, jal, branch, mem_read, mem_write, alu_src, reg_write, mem_to_reg);
    input [3:0] instr;
    output reg jal;
    output reg branch;
    output reg mem_read;
    output reg mem_write;
    output reg alu_src;
    output reg reg_write;
    output reg mem_to_reg;
 
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
        jal <= 0;
        branch <= 0;
        mem_read <= 0;
        mem_write <= 0;
        alu_src <= 0;
        reg_write <= 0;
        mem_to_reg <= 0;
    end

    //Combinational logic for output
    always @(*) begin
        jal = jp;
        branch = br;
        mem_write = sw;
        alu_src = itype;
        reg_write = (jp &(instr[3] & ~instr[2] &~instr[1] & instr[0] )) | (itype & ~sw) | rtype;
        mem_to_reg = lw;
        mem_read = lw;
    end

endmodule