`include "opcodes.v"

module ALUControlUnit(
	part_of_inst,
	ALUOp,
	alu_op
  );
	// [30, 14-12] in instruction code
	// [3] is funct7's second bit
	// [2 : 0] is funct3
	input [3 : 0] part_of_inst;
	input [1 : 0] ALUOp;
	output reg [3:0]alu_op;

	always@(*) begin
		case(ALUOp)
		// 00 is for Adding
		// 01 is for R type
		// 10 is for I type
		// 11 is for SB type
			`ALUOP_Else : begin
				alu_op = `ALU_ADD;
			end

			`ALUOP_Rtype : begin
				case (part_of_inst[2:0])
					`FUNCT3_AND : alu_op = `ALU_AND;
					`FUNCT3_OR : alu_op = `ALU_OR;
					`FUNCT3_XOR : alu_op = `ALU_XOR;
					`FUNCT3_ADD : alu_op = (part_of_inst[3] == 0)? `ALU_ADD : `ALU_SUB;
					`FUNCT3_SLL : alu_op = `ALU_SLL;
					`FUNCT3_SRL : alu_op = `ALU_SRL;
				endcase
			end

			`ALUOP_Itype : begin
				case(part_of_inst[2:0])
					`FUNCT3_ADD : alu_op = `ALU_ADD;
					`FUNCT3_AND : alu_op = `ALU_AND;
					`FUNCT3_OR : alu_op = `ALU_OR;
					`FUNCT3_XOR : alu_op = `ALU_XOR;
					`FUNCT3_SLL : alu_op = `ALU_SLLI;
					`FUNCT3_SRL : alu_op = `ALU_SRLI;
				endcase
			end

			`ALUOP_SBtype : begin
				case(part_of_inst[2:0])
					`FUNCT3_BEQ : alu_op = `ALU_BEQ;
					`FUNCT3_BNE : alu_op = `ALU_BNE;
					`FUNCT3_BLT : alu_op = `ALU_BLT;
					`FUNCT3_BGE : alu_op = `ALU_BGE;
				endcase
			end
		endcase
	end
endmodule



module ALU(
	alu_op,
	alu_in_1,
	alu_in_2,
	alu_result,
	alu_zero
  );
	input [3:0]alu_op;
	input [`WordSize -1: 0]alu_in_1;
	input [`WordSize -1: 0]alu_in_2;
	output reg [`WordSize -1: 0]alu_result;
	output reg alu_zero;

	always@(*) begin
		case (alu_op)
			`ALU_AND : alu_result = (alu_in_1 & alu_in_2);
			`ALU_OR : alu_result = (alu_in_1 | alu_in_2);
			`ALU_ADD : alu_result = (alu_in_1 + alu_in_2);
			`ALU_SUB : alu_result = (alu_in_1 - alu_in_2);
			`ALU_SLL : alu_result = (alu_in_1 << alu_in_2);
			`ALU_SRL : alu_result = (alu_in_1 >> alu_in_2);
			`ALU_SLLI : alu_result = (alu_in_1 << alu_in_2[4:0]);
			`ALU_SRLI : alu_result = (alu_in_1 >> alu_in_2[4:0]);
			`ALU_XOR : alu_result = (alu_in_1 ^ alu_in_2);
			`ALU_BEQ : begin 
				alu_result = alu_in_1 - alu_in_2;
				if(alu_result == 0 )
					alu_zero = 1;
				else
					alu_zero = 0;
				end
			`ALU_BNE : begin
				alu_result = alu_in_1 - alu_in_2;
				if(alu_result != 0)
					alu_zero = 1;
				else
					alu_zero = 0;
				end

			`ALU_BLT : begin
				alu_result = alu_in_1 - alu_in_2;
				if($signed(alu_result) < 0)
					alu_zero = 1;
				else
					alu_zero = 0;
				end
			`ALU_BGE : begin 
				alu_result = alu_in_1 - alu_in_2;
				if($signed(alu_result) >= 0)
					alu_zero = 1;
				else
					alu_zero = 0;
				end
		endcase
	end

endmodule 
