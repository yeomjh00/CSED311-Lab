// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

`include "ALUs.v"
`include "Control.v"
`include "Memory.v"
`include "RegisterFile.v"
`include "Opcodes.v"
`include "PC.v"
`include "Mux.v"

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
  // wires for PC
  wire [`WordSize-1 : 0] next_pc;
  wire [`WordSize-1 : 0] current_pc;
  wire [`WordSize-1 : 0] memory_addr;
  wire [`WordSize-1 : 0] memory_out;

  // wires for RegisterFile
  wire [`WordSize -1:0] rs1_dout;
  wire [`WordSize -1:0] rs2_dout;
  wire[`WordSize -1:0] rd_din;

  wire[4:0] rs1;
  wire [4:0] rs2;
  wire [4:0] rd;


  // wires for ALU
  wire [`WordSize -1:0] alu_in_1;
  wire [`WordSize -1:0] alu_in_2;
  wire [`WordSize -1 :0] alu_result;
  wire [3:0] alu_op;
  wire alu_bcond;



  // wires for Control Unit
  wire PCWriteCond;
	wire PCWrite;
	wire IorD;
	wire MemRead;
	wire MemWrite;
	wire MemToReg;
	wire RegWrite;
	wire ALUSrcA;
	wire [1:0]ALUSrcB;
	wire [1:0]ALUOp;
	wire PCSource;
	wire IRWrite;
  wire is_ecall;
  wire AWrite;
  wire BWrite;
  wire MDRWrite;
  wire ALUWrite;
  wire [1:0]AddrCtl;


  // wires for Immediate Generator
  wire [`WordSize -1:0] imm_gen_out;


  // wires for Reg
  wire [`WordSize -1:0] Awire;
  wire [`WordSize -1:0] Bwire;
  wire [`WordSize -1:0] MDRwire;
  wire [`WordSize -1:0] ALUOutwire;
  wire [`WordSize -1:0] IRwire;

  /***** Register declarations *****/
  reg [31:0] IR; // instruction register
  reg [31:0] MDR; // memory data register
  reg [31:0] A; // Read 1 data register
  reg [31:0] B; // Read 2 data register
  reg [31:0] ALUOut; // ALU output register
  // Do not modify and use registers declared above.




// Wire Assignments
  assign Awire = A;
  assign Bwire = B;
  assign MDRwire = MDR;
  assign ALUOutwire = ALUOut;
  assign IRwire = IR;

  assign rs1 = is_ecall ? 17 : IR[19:15];
  assign rs2 = IR[24:20];
  assign rd = IR[11:7];
  assign nextPCWrite = (PCWrite || (!PCWriteCond && !alu_bcond));

  // terminate
  assign is_halted = is_ecall && (rs1_dout == 10);


  /***** MUX declarations *****/
      //Mux for PC
      mux2to1 mux_IorD(.in0(current_pc),
                       .in1(ALUOutwire),
                       .sel(IorD),
                       .out(memory_addr));

      mux2to1 mux_pcsrc(.in0(alu_result),
                        .in1(ALUOutwire),
                        .sel(PCSource),
                        .out(next_pc));

      //Mux for ALU
      mux2to1 mux_A(.in0(current_pc),
                    .in1(Awire),
                    .sel(ALUSrcA),
                    .out(alu_in_1));

      mux4to1 mux_B(.in0(Bwire),
                    .in1(32'd4),
                    .in2(imm_gen_out),
                    .in3(imm_gen_out),
                    .sel(ALUSrcB),
                    .out(alu_in_2));

      //Mux for Register File
      mux2to1 mux_RegWrtie(.in0(ALUOutwire),
                           .in1(MDRwire),
                           .sel(MemToReg),
                           .out(rd_din));

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .nextPCWrite(nextPCWrite), // input
    .current_pc(current_pc)   // output
  );

  // ---------- Register File ----------
  RegisterFile reg_file(
    .reset(reset),        // input
    .clk(clk),          // input
    .rs1(rs1),          // input
    .rs2(rs2),          // input
    .rd(rd),           // input
    .rd_din(rd_din),       // input
    .write_enable(RegWrite),    // input
    .rs1_dout(rs1_dout),     // output
    .rs2_dout(rs2_dout)      // output
  );

  // ---------- Memory ----------
  Memory memory(
    .reset(reset),        // input
    .clk(clk),          // input
    .addr(memory_addr),         // input
    .din(Bwire),          // input
    .mem_read(MemRead),     // input
    .mem_write(MemWrite),    // input
    .dout(memory_out)          // output
  );

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit(
    .clk(clk),
    .reset(reset),
    .part_of_inst(IR[6:0]),  // input
    .bcond(alu_bcond),        // output
    .PCWriteCond(PCWriteCond),       // output
    .PCWrite(PCWrite),       // output
    .IorD(IorD),        // output
    .MemRead(MemRead),      // output
    .MemWrite(MemWrite),    // output
    .MemToReg(MemToReg),     // output
    .RegWrite(RegWrite),       // output
    .ALUSrcA(ALUSrcA),     // output
    .ALUSrcB(ALUSrcB),     // output
    .ALUOp(ALUOp),         // output
    .PCSource(PCSource),     // output
    .IRWrite(IRWrite),       // output
    .is_ecall(is_ecall),
    .AWrite(AWrite),
    .BWrite(BWrite),
    .MDRWrite(MDRWrite),
    .ALUWrite(ALUWrite),
    .AddrCtl(AddrCtl)
  );


  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IRwire),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit(
    .part_of_inst({IRwire[30], IRwire[14:12]}),  // input
    .ALUOp(ALUOp),        // input
    .alu_op(alu_op)         // output
  );

  // ---------- ALU ----------
  ALU alu(
    .alu_op(alu_op),      // input
    .alu_in_1(alu_in_1),    // input 
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)     // output
  );


  always@(posedge clk) begin
      if(IRWrite)
        IR <= memory_out;
      if(AWrite)
        A <= rs1_dout;
      if(BWrite)
        B <= rs2_dout;
      if(ALUWrite)
        ALUOut <= alu_result;
      if(MDRWrite)
        MDR <= memory_out;
  end
endmodule
