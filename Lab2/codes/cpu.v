// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.
`include "Memory.v"
`include "opcodes.v"
`include "RegisterFile.v"
`include "PC.v"
`include "ALUs.v"
`include "CONTROL.v"


// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation

  /***** Wire declarations *****/
	// wire for PC & Inst Memory
	wire [`WordSize -1: 0] wire_next_pc;
	wire [`WordSize -1 :0] wire_current_pc;
	wire [`WordSize -1: 0] wire_inst;

	assign pc_inst_out = wire_next_pc;

	// wire for RegisterFiles
	wire [`WordSize -1: 0] wire_rs1_dout;
	wire [`WordSize -1: 0] wire_rs2_dout;
	wire [`WordSize -1: 0] wire_rd_din;
	wire [`WordSize -1: 0] wire_semi_write_data;

	// wire for Immediate Generator
	wire [`WordSize -1: 0] wire_imm_gen_out;

	// wire for ALU and ALU Control
	wire [3:0] wire_alu_op;
	wire wire_alu_bcond;
	//wire [`WordSize -1: 0] wire_alu_in_1;
	wire [`WordSize -1: 0] wire_alu_in_2;
	wire [`WordSize -1: 0] wire_alu_result;

	// wire for Memory
	wire [`WordSize -1: 0] wire_constant_4;
	wire [`WordSize -1: 0] wire_dout;

	assign wire_constant_4 = 32'd4;

	// wire for Adder
	wire [`WordSize -1: 0] wire_add4_nxt_pc;
	wire [`WordSize -1: 0] wire_jal_nxt_pc;
	wire [`WordSize -1: 0] wire_jalr_nxt_pc; 

	assign wire_jalr_nxt_pc = (wire_alu_result & 32'hfffffffe);

	// wire for MUXs
	wire [`WordSize -1: 0] wire_semi_nxt_pc; 

	// wire for Control Unit
	wire wire_is_jal;
	wire wire_is_jalr;
	wire wire_branch;
	wire wire_mem_read;
	wire wire_mem_to_reg;
	wire wire_mem_write;
	wire wire_alu_src;
	wire wire_write_enable;
	wire wire_pc_to_reg;
	wire wire_is_ecall;

	wire wire_is_jal_addr;
	wire wire_is_jalr_addr;

	assign wire_is_jal_addr = (wire_is_jal||(wire_branch && wire_alu_bcond));
	assign wire_is_jalr_addr = (wire_is_jalr);

	//halt
	wire [`WordSize-1: 0]wire_x17;
	assign is_halted = (wire_is_ecall && (wire_x17 == 10));


  /***** Register declarations *****/


  /***** Module Instance declarations *****/
	//adders
	adder #(.data_width(`WordSize)) adder_add4_nxt_pc(.a(wire_constant_4), .b(wire_current_pc), .y(wire_add4_nxt_pc));
	adder #(.data_width(`WordSize)) adder_jal_nxt_pc(.a(wire_imm_gen_out), .b(wire_current_pc), .y(wire_jal_nxt_pc));

	//MUXs
		//MUXs for PC
	mux2to1 #(.data_width(`WordSize)) mux_semi_nxt_pc(.input0(wire_add4_nxt_pc),
							 .input1(wire_jal_nxt_pc),
							 .sel(wire_is_jal_addr),
							.y(wire_semi_nxt_pc));

	mux2to1 #(.data_width(`WordSize)) mux_nxt_pc(.input0(wire_semi_nxt_pc),
							.input1(wire_jalr_nxt_pc),
							.sel(wire_is_jalr_addr),
							.y(wire_next_pc));
		//MUX for ALU

	mux2to1 #(.data_width(`WordSize)) mux_alu_input(.input0(wire_rs2_dout),
							.input1(wire_imm_gen_out),
							.sel(wire_alu_src),
							.y(wire_alu_in_2));
		//MUXs for Write in Reg
	mux2to1 #(.data_width(`WordSize)) mux_semi_write_data(.input0(wire_alu_result),
							.input1(wire_dout),
							.sel(wire_mem_to_reg),
							.y(wire_semi_write_data));
	
	mux2to1 #(.data_width(`WordSize)) mux_write_data(.input0(wire_semi_write_data),
							.input1(wire_add4_nxt_pc),
							.sel(wire_pc_to_reg),
							.y(wire_rd_din));

		//MUX for LUI, AUIPC instruction
/*
	mux4to1 #.data_width(`WordSize)) mux_lui_auipc(.input0(wire_current_pc),
							.input1(alu_rs1_dout).
							.input2(),
							.input3(),
							.sel()
							.y());
*/

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(wire_next_pc),     // input
    .current_pc(wire_current_pc)   // output
  );
  
  // ---------- Instruction Memory from Memory.v ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(wire_current_pc),    // input
    .dout(wire_inst)     // output
  );

  // ---------- Register File from RegisterFile.v ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (wire_inst[19:15]),          // input
    .rs2 (wire_inst[24:20]),          // input
    .rd (wire_inst[11:7]),           // input
    .rd_din (wire_rd_din),       // input
    .write_enable (wire_write_enable),    // input
    .rs1_dout (wire_rs1_dout),     // output
    .rs2_dout (wire_rs2_dout),
    .x17(wire_x17)     // output
  );


  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(wire_inst[6: 0]), //input
    .is_jal(wire_is_jal),        // output
    .is_jalr(wire_is_jalr),       // output
    .branch(wire_branch),        // output
    .mem_read(wire_mem_read),      // output
    .mem_to_reg(wire_mem_to_reg),    // output
    .mem_write(wire_mem_write),     // output
    .alu_src(wire_alu_src),       // output
    .write_enable(wire_write_enable),     // output
    .pc_to_reg(wire_pc_to_reg),     // output
    .is_ecall(wire_is_ecall)       // output (ecall inst)
  );


  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(wire_inst),  // input
    .imm_gen_out(wire_imm_gen_out)    // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .part_of_inst({wire_inst[30], wire_inst[14:12], wire_inst[6:0]}),  // input
    .alu_op(wire_alu_op)         // output
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_op(wire_alu_op),      // input
    .alu_in_1(wire_rs1_dout),    // input  
    .alu_in_2(wire_alu_in_2),    // input
    .alu_result(wire_alu_result),  // output
    .alu_bcond(wire_alu_bcond)     // output
  );

  // ---------- Data Memory from Memory.v----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (wire_alu_result),       // input
    .din (wire_rs2_dout),        // input
    .mem_read (wire_mem_read),   // input
    .mem_write (wire_mem_write),  // input
    .dout (wire_dout)        // output
  );
endmodule







module mux2to1 #(parameter data_width = 32)(
	input [data_width-1:0] input0,
	input [data_width-1:0] input1,
	input sel,
	output reg [data_width-1:0] y
);
	always@(*)begin
		case (sel)
			0 : y = input0;
			1 : y = input1;
		endcase
	end
endmodule

/*
module mux4to1 #(parameter data_width = 32)(
	input [data_width-1:0] input0,
	input [data_width-1:0] input1,
	input [data_width-1:0] input2,
	input [data_width-1:0] input3,
	input [1:0] sel,
	output reg [data_width -1: 0] y
);
	always@(*) begin
		case(sel)
			0: y= input0;
			1: y = input1;
			2: y = input2;
			3: y = input3;
		endcase
	end
endmodule
*/

module adder #(parameter data_width = 32)(
	a,
	b,
	y
);
	input [data_width-1:0] a;
	input [data_width-1:0] b;
	output reg [data_width-1: 0] y;

	always@(*)begin
		y=a+b;
	end

endmodule


