`include "opcodes.v"

module compute_actual_pc(
    input [`WordSize-1: 0] current_pc,
    input [`WordSize-1: 0] rs1,
    input [`WordSize-1: 0] imm_gen_out,
    input isbranch,
    input isjal,
    input isjalr,
    input alu_bcond,
    output reg [`WordSize-1: 0]target
);
    always@(*) begin
        if(isjal || (isbranch && alu_bcond)) begin
            target = current_pc + imm_gen_out;
        end

        else if(isjalr) begin
            target = (rs1 + imm_gen_out) & 32'hfffffffe;
        end

        else
            target = current_pc + 4;
    end
endmodule

module always_taken(
    input reset,
    input clk,
    input [`WordSize-1: 0] current_pc,
    input [`WordSize-1: 0] pc_of_target,
    input [`WordSize - 1: 0] actual_target,
    input is_conditional,
    output reg istaken,
    output reg [`WordSize-1: 0] pred_pc
);
    integer i;
//wires
    //for read BTBs
    wire [4:0] BTB_index;
    wire [24:0] BTB_tag;

    //for write BTBs
    wire [4:0] BTB_past_index;
    wire [24:0] BTB_past_tag;


// registers
    reg valid_bit[0:31];
    reg [24: 0] tag_bit [0:31];
    reg [`WordSize -1:0] BTB [0:31];

// assign
    //for read BTB
    assign BTB_index = current_pc[6:2];
    assign BTB_tag = current_pc[31:7];

    // for write BTB
    assign BTB_past_index = pc_of_target[6:2];
    assign BTB_past_tag = pc_of_target[31:7];

    // Read BTB asynchronously
    always@(*) begin
        if(tag_bit[BTB_index] == BTB_tag && valid_bit[BTB_index]) begin
            pred_pc = BTB[BTB_index];
            istaken = 1;
        end
        else begin
            pred_pc = current_pc + 4;
            istaken = 0;
        end
    end

    // Write BTB synchronoushly
    always@(posedge clk) begin
        if(reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                BTB[i] <= 32'b0;
                valid_bit[i] <= 0;
                tag_bit[i] <= 0;
            end
        end

        else begin
            if(is_conditional) begin
                valid_bit[BTB_past_index] <= 1;
                tag_bit[BTB_past_index] <= BTB_past_tag;
                BTB[BTB_past_index] <= actual_target;
            end
        end
    end

endmodule

module misprediction_detector_always_taken(
    input [`WordSize -1: 0] pred_pc,
    input [`WordSize -1: 0] target,
    input is_conditional,
    output reg PCSrc,
    output reg isflush
);
//if PCSrc = 0, next pc is pred_pc
//if PCSrc = 1, next pc is target
    always@(*) begin
        //isconditional is asserted if branch or jal or jalr
        if(pred_pc != target && is_conditional) begin
            PCSrc = 1;
            isflush = 1;
        end

        else begin
            PCSrc = 0;
            isflush = 0;
        end
    end
endmodule


module misprediction_detector_not_taken(
    input [`WordSize -1: 0] target,
    input actual_taken,
    output reg PCSrc,
    output reg isflush
);
//if PCSrc = 0, next pc is pred_pc
//if PCSrc = 1, next pc is target
    always@(*) begin
        if(actual_taken == 1) begin
            PCSrc = 1;
            isflush = 1;
        end

        else begin
            PCSrc = 0;
            isflush = 0;
        end
    end
endmodule
