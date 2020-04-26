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

module control(instr, clk, jal, branch, mem_read, mem_write, alu_src, reg_write, pvs_write_en);
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
        jal <= 0;
        branch <= 0;
        mem_read <= 0;
        mem_write <= 0;
        alu_src <= 0;
        reg_write <= 0;
        pvs_write_en <= 0;
        state <= `INIT;
    end

    always @(*) begin
        case(state)
        `IF1: begin
            jal = 0;
            branch = 0;
            pvs_write_en = 0;
            mem_write = 0;
            alu_src = 0;
            reg_write = 0;
            mem_read = 1;
            next_state = `IF2;   
        end 
        `IF2: begin
            mem_read = 0;
            next_state = `IF3; 
        end
        `IF3: begin
            next_state = `IF4;
        end
        `IF4: begin
            if(jp)begin
                jal = 1;
                next_state = `EX1;
            end
            else begin
                alu_src = itype;
                branch = br;
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
            if(br) begin
                next_state = `IF1;
                pvs_write_en = 1;
            end
            else if(lw | sw) begin 
                next_state = `MEM1;
            end
            else begin
                next_state = `WB;
            end
        end
        `MEM1: begin
            mem_read = lw;
            mem_write = sw;
            next_state = `MEM2;
        end
        `MEM2: begin
            mem_read = 0;
            mem_write = 0;
            next_state = `MEM3;
        end
        `MEM3: begin
            next_state = `MEM4;
        end
        `MEM4: begin
            if(lw) begin
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
            reg_write = 1;
        end
        endcase
    end

    always @(posedge clk) begin
        state <= next_state;
    end

endmodule