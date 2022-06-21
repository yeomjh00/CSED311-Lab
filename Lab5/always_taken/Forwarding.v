`include "opcodes.v"

// rd, rs1, rs2, regwrite signals
module Forwarding_unit(
    input EX_MEM_reg_write,
    input MEM_WB_reg_write,
    input [`regnum-1: 0] EX_MEM_rd,
    input [`regnum-1: 0] MEM_WB_rd,
    input [`regnum-1: 0] rs1,
    input [`regnum-1: 0] rs2,
    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
);

always@(*)begin
    if(rs1 != 0 && rs1 == EX_MEM_rd && EX_MEM_reg_write) begin
        ForwardA = 2'b10;
    end
    else if(rs1 != 0 && rs1 == MEM_WB_rd && MEM_WB_reg_write) begin
        ForwardA = 2'b01;
    end
    else
        ForwardA = 2'b00;

    if(rs2 != 0 && rs2 == EX_MEM_rd && EX_MEM_reg_write) begin
        ForwardB = 2'b10;
    end
    else if(rs2 != 0 && rs2 == MEM_WB_rd && MEM_WB_reg_write) begin
        ForwardB = 2'b01;
    end
    else
        ForwardB = 2'b00;
end
endmodule

module Internal_Forwarding_unit(
    input [`regnum -1: 0] WB_rd,
    input [`regnum -1: 0] rs1_in,
    input [`regnum -1: 0] rs2_in,
    input WB_reg_write,
    output reg internal_forwardA,
    output reg internal_forwardB);

    always@(*)begin
        if(rs1_in != 0 && rs1_in == WB_rd && WB_reg_write == 1) begin
            internal_forwardA = 1;
        end
        else
            internal_forwardA = 0;
        
        if(rs2_in != 0 && rs2_in == WB_rd && WB_reg_write == 1) begin
            internal_forwardB = 1;
        end
        else
            internal_forwardB = 0;
    end
endmodule