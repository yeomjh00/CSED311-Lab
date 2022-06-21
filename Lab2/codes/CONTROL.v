`include "opcodes.v"

module ControlUnit(
	input [6:0]part_of_inst,
	output reg is_jal,
	output reg is_jalr,
	output reg branch,
	output reg mem_read,
	output reg mem_to_reg,
	output reg mem_write,
	output reg alu_src,
	output reg write_enable,
	output reg pc_to_reg,
	output reg is_ecall
  );
	always@(part_of_inst) begin
		write_enable = (part_of_inst != `STORE &&
			part_of_inst != `BRANCH && part_of_inst != `ECALL);

		alu_src = (part_of_inst != `ARITHMETIC && 
			part_of_inst != `BRANCH);

		mem_read = (part_of_inst == `LOAD);
		mem_write = (part_of_inst == `STORE);
		mem_to_reg = (part_of_inst == `LOAD);
		pc_to_reg = (part_of_inst == `JAL ||
			part_of_inst == `JALR);

		is_jal = (part_of_inst == `JAL);
		is_jalr =(part_of_inst == `JALR);
		branch = (part_of_inst == `BRANCH);
		
		is_ecall = (part_of_inst == `ECALL);
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