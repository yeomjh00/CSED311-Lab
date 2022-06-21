`include "Opcodes.v"
`include "Mux.v"

module ControlUnit(
    input clk,
    input reset,
    input [6:0] part_of_inst,
	input bcond,
    output reg PCWriteCond,
	output reg PCWrite,
	output reg IorD,
	output reg MemRead,
	output reg MemWrite,
	output reg MemToReg,
	output reg RegWrite,
	output reg ALUSrcA,
	output reg [1:0]ALUSrcB,
	output reg [1:0]ALUOp,
	output reg PCSource,
	output reg IRWrite,
	output is_ecall,
	output reg AWrite,
	output reg BWrite,
	output reg MDRWrite,
	output reg ALUWrite,
	output reg [1:0]AddrCtl
  );

	//wires and registers
	wire [3:0] current_state;
	wire [3:0] next_state;
	reg [3:0] state;

	//assignment
	assign current_state = state;
	assign is_ecall = (part_of_inst == `ECALL);

	MicroSequencer mseq(.part_of_inst(part_of_inst),
						.current_state(current_state),
						.AddrCtl(AddrCtl),
						.next_state(next_state));

	always@(*) begin

		PCWriteCond = 1;
		PCWrite =0;
		IorD =0;
		MemRead =0;
		MemWrite =0;
		MemToReg =0;
		RegWrite =0;
		ALUSrcA =0;
		ALUSrcB =0;
		ALUOp =0;
		PCSource =0;
		IRWrite =0;
		AWrite =0;
		BWrite =0;
		MDRWrite =0;
		ALUWrite =0;

		//IF
			if (state == 0) begin
			IorD =0;
			MemRead = 1;
			IRWrite = 1;
			AddrCtl = 2'b11;
		end

		//ID
		else if (state == 1) begin
			AWrite = 1;
			BWrite = 1;
			ALUSrcA = 0;
			ALUSrcB = 2'b01;
			ALUOp = 2'b00;
			ALUWrite = 1;
			AddrCtl = 2'b01;
		end

		else if (state == 2) begin
			ALUSrcA = 1;
			ALUSrcB = 0;
			ALUOp = 2'b01;
			ALUWrite = 1;
			AddrCtl = 2'b11;
		end

		else if (state == 3) begin
			ALUSrcA = 0;
			ALUSrcB = 2'b01;
            ALUWrite = 0;
			ALUOp = 0;
			PCSource = 0;
			PCWrite = 1;
			MemToReg = 0;
			RegWrite = 1;
			AddrCtl = 0;
		end

		// I type 1st
		else if (state == 4) begin
			ALUSrcA = 1;
			ALUSrcB = 2'b10;
			ALUOp = 2'b10;
			ALUWrite = 1;
			AddrCtl = 2'b11;
		end

		// I type 2nd
		else if (state == 5) begin
			ALUSrcA = 0;
			ALUSrcB = 2'b01;
			ALUOp = 0;
            ALUWrite = 0;
			PCSource = 0;
			PCWrite = 1;
			MemToReg = 0;
			RegWrite = 1;
			AddrCtl = 0;
		end

		// SW LW first
		else if (state == 6) begin
			ALUSrcA = 1;
			ALUSrcB = 2'b10;
			ALUOp = 0;
			ALUWrite = 1;
			AddrCtl = 2'b10;
		end

		else if (state == 7) begin
			IorD = 1;
			MemRead = 1;
			IRWrite = 0;
			MDRWrite = 1;
			AddrCtl = 2'b11;
		end

		else if (state == 8) begin
			ALUSrcA = 0;
			ALUSrcB = 2'b01;
			ALUOp = 0;
			PCSource = 0;
			PCWrite = 1;
			MemToReg = 1;
			RegWrite = 1;
			AddrCtl = 0;
		end

		else if (state == 9) begin
			ALUSrcA = 0;
			ALUSrcB = 2'b01;
			ALUOp = 0;
			MemWrite = 1;
			IorD = 1;
			PCWrite = 1;
			PCSource = 0;
			AddrCtl = 0;
		end

		// Branch PC+4
		else if (state == 10) begin
			ALUSrcA = 1;
			ALUSrcB = 2'b00;
			ALUOp = 2'b11;
            PCWriteCond =0;
			PCSource = 1;
			AddrCtl = (bcond == 1) ? 2'b11 : 2'b00;
		end

		// PC + Imm
		else if (state == 11) begin
			ALUSrcA = 0;
			ALUSrcB = 2'b10;
			ALUOp = 0;
			PCSource = 0;
			PCWrite = 1;
			AddrCtl = 0;
		end

		else if (state == 12) begin
			MemToReg = 0;
			RegWrite = 1;
			ALUSrcA = 0;
			ALUSrcB = 2'b10;
            ALUWrite = 0;
			ALUOp = 0;
			PCSource = 0;
			PCWrite = 1;
			AddrCtl = 0;
		end

		else if (state == 13) begin
			MemToReg = 0;
			RegWrite = 1;
			ALUSrcA = 1;
			ALUSrcB = 2'b10;
			ALUOp = 0;
			PCSource = 0;
			PCWrite = 1;
			AddrCtl =0;
		end

		else if (state == 14) begin
			ALUSrcA = 0;
			ALUSrcB = 2'b01;
			ALUOp = 2'b00;
			PCSource = 1;
			PCWrite = 1;
			ALUWrite = 0;
			AddrCtl = 0;
		end
	
	end

	always@(posedge clk)begin
		if(reset)
			state <= 4'd0;
		else
			state <= next_state;
	end

endmodule


module MicroSequencer(
	input [6:0] part_of_inst,
	input [3:0] current_state,
	input [1:0]AddrCtl,
	output reg [3:0] next_state
);

	//reg [3:0] state;
	always@(*) begin
		case(AddrCtl)
			`AddrCtl_Reset : next_state = 0;
			`AddrCtl_Next : next_state = current_state + 1;
			`AddrCtl_Branch1 : begin
					case(part_of_inst)
						`ARITHMETIC : next_state = 2;
						`ARITHMETIC_IMM : next_state = 4;
						`LOAD : next_state = 6;
						`STORE : next_state = 6;
						`BRANCH : next_state = 10;
						`JAL : next_state = 12;
						`JALR : next_state = 13;
						`ECALL : next_state = 14;
					endcase	
			end
			`AddrCtl_Branch2 : begin
				case(part_of_inst)
					`LOAD : next_state = 7;
					`STORE : next_state = 9;
				endcase
			end
		endcase
	end

endmodule



module ImmediateGenerator(
	part_of_inst,
	imm_gen_out
);
	input [`WordSize -1: 0] part_of_inst;
	output reg[`WordSize -1: 0] imm_gen_out;

	always@(*) begin
		case(part_of_inst [6:0])
			`ARITHMETIC : imm_gen_out = 32'd0;

			`ARITHMETIC_IMM : imm_gen_out = $signed(part_of_inst[31:20]);

			`LOAD : imm_gen_out = $signed(part_of_inst[31:20]);

			`JALR : imm_gen_out = $signed(part_of_inst[31:20]);

			`STORE : imm_gen_out = $signed({part_of_inst[31:25], part_of_inst[11:7]});

			`BRANCH : imm_gen_out = $signed({part_of_inst[31], part_of_inst[7], part_of_inst[30:25], part_of_inst[11:8], 1'b0});

			`JAL : imm_gen_out = $signed({part_of_inst[31], part_of_inst[19:12], part_of_inst[20], part_of_inst[30:21], 1'b0});
		endcase
	end

endmodule