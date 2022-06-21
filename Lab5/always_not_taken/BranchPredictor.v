`include "opcodes.v"

module always_not_taken(
    input [`WordSize-1: 0] current_pc,
    output [`WordSize-1 :0] pred_pc,
    output istaken
);
    assign pred_pc = current_pc+4;
    assign istaken = 0;
endmodule


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

module misprediction_detector(
    input [`WordSize -1: 0] pred_pc,
    input [`WordSize -1: 0] target,
    input isconditional,
    output reg PCSrc,
    output reg isflush
);
//if PCSrc = 0, next pc is pred_pc
//if PCSrc = 1, next pc is target
    always@(*) begin
        //isconditional is asserted if branch or jal or jalr
        if(pred_pc != target && isconditional) begin
            PCSrc = 1;
            isflush = 1;
        end

        else begin
            PCSrc = 0;
            isflush = 0;
        end
    end
endmodule