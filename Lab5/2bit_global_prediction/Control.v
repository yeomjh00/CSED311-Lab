`include "Opcodes.v"
`include "Mux.v"

module ControlUnit(
    input [6:0] part_of_inst,
	input hazard_detect,
	output reg mem_read,
	output reg mem_to_reg,
	output reg mem_write,
	output reg reg_write,
	output reg alu_src,
	output reg [1:0]ALUOp,
	output reg pc_to_reg,
	output reg isbranch,
	output reg isjal,
	output reg isjalr,
	output is_ecall
  );


	//assignment
	assign is_ecall = (part_of_inst == `ECALL);

	always@(*) begin
		if(hazard_detect) begin
			mem_read = 0;
			mem_to_reg = 0;
			mem_write = 0;
			reg_write = 0;
			alu_src = 0;
			pc_to_reg = 0;
			isbranch = 0;
			isjal =0;
			isjalr =0;
			ALUOp = `ALUOP_Else;
		end
		else begin
			case(part_of_inst)
				`ARITHMETIC : begin
					mem_read = 0;
					mem_to_reg = 0;
					mem_write = 0;
					reg_write = 1;
					alu_src = 0;
					pc_to_reg = 0;
					isbranch =0;
					isjal=0;
					isjalr=0;
					ALUOp = `ALUOP_Rtype;
				end
				`ARITHMETIC_IMM : begin
					mem_read =0;
					mem_to_reg = 0;
					mem_write = 0;
					reg_write = 1;
					alu_src = 1;
					pc_to_reg = 0;
					isbranch =0;
					isjal=0;
					isjalr=0;
					ALUOp = `ALUOP_Itype;
				end
				`LOAD : begin
					mem_read = 1;
					mem_to_reg = 1;
					mem_write = 0;
					reg_write = 1;
					alu_src = 1;
					pc_to_reg = 0;
					isbranch =0;
					isjal=0;
					isjalr=0;
					ALUOp = `ALUOP_Else;
				end
				`STORE : begin
					mem_read =0;
					mem_to_reg =0;
					mem_write = 1;
					reg_write = 0;
					alu_src = 1;
					pc_to_reg = 0;
					isbranch =0;
					isjal=0;
					isjalr=0;
					ALUOp = `ALUOP_Else;
				end

				`JAL: begin
					mem_read = 0;
					mem_to_reg =0;
					mem_write =0;
					reg_write = 1;
					alu_src = 1;
					pc_to_reg = 1;
					isbranch =0;
					isjal=1;
					isjalr=0;
					ALUOp = `ALUOP_Else;
				end

				`BRANCH : begin
					mem_read = 0;
					mem_to_reg = 0;
					mem_write = 0;
					reg_write = 0;
					alu_src = 0;
					pc_to_reg = 0;
					isbranch =1;
					isjal=0;
					isjalr=0;
					ALUOp = `ALUOP_SBtype;
				end

				`JALR: begin
					mem_read = 0;
					mem_to_reg =0;
					mem_write =0;
					reg_write = 1;
					alu_src = 0;
					pc_to_reg = 1;
					isbranch =0;
					isjal=0;
					isjalr=1;
					ALUOp = `ALUOP_Else;
				end
			
				`ECALL : begin
					mem_read = 0;
					mem_to_reg = 0;
					mem_write = 0;
					reg_write = 0;
					alu_src = 0;
					pc_to_reg = 0;
					isbranch =0;
					isjal=0;
					isjalr=0;
					ALUOp = `ALUOP_Else;
				end

				default : begin
					mem_read = 0;
					mem_to_reg = 0;
					mem_write = 0;
					reg_write = 0;
					alu_src = 0;
					pc_to_reg = 0;
					isbranch =0;
					isjal=0;
					isjalr=0;
					ALUOp = `ALUOP_Else;
				end
			endcase
		end
	end

endmodule

module Hazard_detection_unit(
    input [6:0] opcode,
	input ecall_hazard_detect,
    input ID_EX_mem_read,
    input [`regnum -1: 0]ID_EX_rd,
    input [`regnum -1: 0]ID_rs1,
    input [`regnum -1: 0]ID_rs2,
    output reg IF_ID_Write,
    output reg PCWrite,
    output reg hazard_detect);

    wire use_rs1, use_rs2;

    assign use_rs1 = !(opcode == `JAL || opcode == `ECALL);
    assign use_rs2 = (opcode == `ARITHMETIC || opcode == `STORE || opcode == `BRANCH);
    

    // IF_ID_Write = 1, IF/ID Reg can be written.
    // PCWrite = 1, PC can be written.
    // hazard_detect = 1, hazard detected -> control unit generates stall.
    always@(*) begin
        //Stall Condition
        if(((ID_rs1 == ID_EX_rd && ID_rs1 != 0 && use_rs1) ||
            (ID_rs2 == ID_EX_rd && ID_rs2 != 0 && use_rs2)) &&
            ID_EX_mem_read == 1) begin
                IF_ID_Write = 0;
                PCWrite = 0;
                hazard_detect = 1;
            end

		else if(ecall_hazard_detect == 1) begin
			IF_ID_Write = 0;
			PCWrite = 0;
			hazard_detect = 1;
		end
        
        // keep going
        else begin
            IF_ID_Write = 1;
            PCWrite =1;
            hazard_detect =0;
        end
    end
endmodule

module Ecall_Hazard_detection_unit(
	input is_ecall,
	input [`regnum-1:0] ID_EX_rd,
	input ID_EX_reg_write,
	input ID_EX_is_ecall,
	input EX_MEM_mem_read,
	input [`regnum-1:0]EX_MEM_rd,
	output reg ecall_hazard_detect);

	always@(*) begin
		if(is_ecall && ID_EX_rd == 17 && ID_EX_reg_write == 1)
			ecall_hazard_detect = 1;
		if(ID_EX_is_ecall)
			ecall_hazard_detect = 0;
		if(is_ecall && EX_MEM_mem_read && EX_MEM_rd == 17 && ID_EX_is_ecall)
			ecall_hazard_detect = 1;
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