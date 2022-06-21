// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify modules (except InstMemory, DataMemory, and RegisterFile)
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required
`include "opcodes.v"
`include "ALUs.v"
`include "RegisterFile.v"
`include "Control.v"
`include "Memory.v"
`include "PC.v"
`include "Forwarding.v"
`include "BranchPredictor.v"


module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
  
    // wires for PC
    wire [`WordSize -1:0] next_pc;
    wire[`WordSize -1: 0] current_pc;
    wire nextPCWrite;
    wire PCSrc;
    wire actual_taken;

    // wires for predicting branch
    wire [`WordSize-1: 0]pred_pc;
    wire istaken;
    wire [`WordSize-1 :0] target;
    wire isflush;

    // wires for inst memory
    wire [`WordSize -1:0] dout;

    // wire for RegisterFile
    wire [`WordSize -1:0] inst;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] rd;
    wire [`WordSize -1:0] rd_din;
    wire [`WordSize -1:0] rs1_dout;
    wire [`WordSize -1:0] rs2_dout;

    wire [`WordSize-1:0] rs1_dout_fwd;
    wire [`WordSize-1:0] rs2_dout_fwd; 
    wire alu_bcond;



    // wire for ImmGen
    wire [`WordSize -1:0] imm_gen_out;

    // wires for ALUs
    wire [3:0] alu_op;
    wire [`WordSize -1:0] alu_in_1;
    wire [`WordSize -1:0] alu_in_2;
    wire [`WordSize -1:0] alu_in_2_imm;
    wire [`WordSize -1:0] alu_in_1_pc;
    wire [`WordSize -1:0] alu_in_2_imm_pc;
    wire [`WordSize -1:0] alu_out;

    // wires for Control Unit
    wire mem_read;
    wire mem_to_reg;
    wire reg_write;
    wire mem_write;
    wire alu_src;
    wire [1:0]ALUOp;
    wire is_ecall;
    wire ecall_hazard_detect;
    wire tmp_halt;
    wire pc_to_reg;
    wire isbranch;
    wire isjar;
    wire isjalr;

    // wires for Hazard
    wire hazard_detect;
    wire IF_ID_Write;

    // wires for fowarding
    wire internal_forwardA;
    wire internal_forwardB;

    wire [1:0]ForwardA;
    wire [1:0]ForwardB;

    // wire for Data Memory
    wire [`WordSize -1:0] dmem_dout;

    // Branch & Jump
    wire [`WordSize -1:0] branch_target;




  /***** Register declarations *****/
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  /***** IF/ID pipeline registers *****/
  reg IF_ID_istaken;
  reg [`WordSize -1: 0]IF_ID_PC;
  reg [`WordSize -1: 0]IF_ID_inst;           // will be used in ID stage




  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg [1:0]ID_EX_ALUOp;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  reg ID_EX_pc_to_reg;
  reg ID_EX_isbranch;
  reg ID_EX_isjal;
  reg ID_EX_isjalr;

  //custom register
  reg [`regnum-1:0]ID_EX_rs1;
  reg [`regnum-1 :0]ID_EX_rs2;
  reg ID_EX_halt;
  reg ID_EX_is_ecall;
  reg [`regnum -1: 0]ID_EX_rd;
  reg [`WordSize -1: 0] ID_EX_PC;
  reg ID_EX_istaken;

  // From others
  reg [`WordSize -1: 0]ID_EX_rs1_data;
  reg [`WordSize-1:0]ID_EX_rs2_data;
  reg [`WordSize -1: 0]ID_EX_imm;
  reg [3:0]ID_EX_ALU_ctrl_unit_input;
  


  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  reg EX_MEM_is_branch;     // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  // From others
  reg [`WordSize -1: 0]EX_MEM_alu_out;
  reg [`WordSize -1 : 0]EX_MEM_dmem_data;

  //custom
  reg EX_MEM_halt;
  reg [`regnum -1 : 0]EX_MEM_rd;

  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  // From others
  // src1 is ALU output
  reg [`WordSize -1: 0]MEM_WB_mem_to_reg_src_1;
  // src2 is from Data Memory
  reg [`WordSize -1 : 0]MEM_WB_mem_to_reg_src_2;

  // custom
  reg[`regnum -1: 0] MEM_WB_rd;
  reg MEM_WB_halt;


  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .nextPCWrite(nextPCWrite),
    .current_pc(current_pc)   // output
  );
  
  always_not_taken not_taken_predictor(
    .current_pc(current_pc),
    .pred_pc(pred_pc),
    .istaken(istaken)
  );



  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(dout)     // output
  );

  // -----------------------------------------------ID/IF------------------------------------------------------

  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (reset || isflush) begin
      IF_ID_inst <= 0;
      IF_ID_PC <= 0;
      IF_ID_istaken <= 0;
    end
    else if(!IF_ID_Write)begin
      IF_ID_inst <= IF_ID_inst;
      IF_ID_PC <=IF_ID_PC;
      IF_ID_istaken <= IF_ID_istaken;
    end
    else begin
      IF_ID_PC <= current_pc;
      IF_ID_inst <= dout;
      IF_ID_istaken <= istaken;
      end
    end


    assign inst = IF_ID_inst;
    assign rs1 = (is_ecall) ? 17 : inst[19:15];
    assign rs2 = inst[24:20];
    assign rd = inst[11:7];

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (rs1),          // input
    .rs2 (rs2),          // input
    .rd (MEM_WB_rd),           // input
    .rd_din (rd_din),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout)      // output
  );

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(inst[6:0]),  // input
    .hazard_detect(hazard_detect),  // input
    .mem_read(mem_read),      // output
    .mem_to_reg(mem_to_reg),    // output
    .mem_write(mem_write),     // output
    .reg_write(reg_write),     // output
    .alu_src(alu_src),       // output
    .ALUOp(ALUOp),        // output
    .pc_to_reg(pc_to_reg),     // output
    .isbranch(isbranch),      // output
    .isjal(isjal),            // output
    .isjalr(isjalr),          // output
    .is_ecall(is_ecall)       // output (ecall inst)
  );

  Ecall_Hazard_detection_unit ecall_haz_detect_unit(
    .is_ecall(is_ecall),
    .ID_EX_rd(ID_EX_rd),
    .ID_EX_reg_write(ID_EX_reg_write),
    .ID_EX_is_ecall(ID_EX_is_ecall),
    .EX_MEM_mem_read(EX_MEM_mem_read),
    .EX_MEM_rd(EX_MEM_rd),
    .ecall_hazard_detect(ecall_hazard_detect)
  );

  Hazard_detection_unit hzd_unit(
    .opcode(inst[6:0]),
    .ecall_hazard_detect(ecall_hazard_detect),
    .ID_EX_mem_read(ID_EX_mem_read),
    .ID_EX_rd(ID_EX_rd),
    .ID_rs1(rs1),
    .ID_rs2(rs2),
    .IF_ID_Write(IF_ID_Write),
    .PCWrite(nextPCWrite),
    .hazard_detect(hazard_detect)
  );

  Internal_Forwarding_unit intnl_fwd_unit(
    .WB_rd(MEM_WB_rd),
    .rs1_in(rs1),
    .rs2_in(rs2),
    .WB_reg_write(MEM_WB_reg_write),
    .internal_forwardA(internal_forwardA),
    .internal_forwardB(internal_forwardB)
  );

  assign rs1_dout_fwd = (internal_forwardA == 1) ? rd_din : (is_ecall && EX_MEM_rd == 17 && EX_MEM_reg_write) ? EX_MEM_alu_out : rs1_dout;
  assign rs2_dout_fwd = (internal_forwardB == 1) ? rd_din : rs2_dout;
  assign tmp_halt = is_ecall && (rs1_dout_fwd == 10);


  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(inst),  // input
    .imm_gen_out(imm_gen_out)    // output
  );



  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset || isflush) begin
      // control signals
      ID_EX_ALUOp <= 0;
      ID_EX_alu_src <= 0;
      ID_EX_mem_write <= 0;
      ID_EX_mem_read <= 0;
      ID_EX_mem_to_reg <= 0;
      ID_EX_reg_write <= 0;
      ID_EX_is_ecall <= 0;
      ID_EX_halt <= 0;
      ID_EX_pc_to_reg <= 0;
      ID_EX_isbranch <= 0;
      ID_EX_isjal <= 0;
      ID_EX_isjalr <= 0;

      // others
      ID_EX_rs1_data <= 0;
      ID_EX_rs2_data <= 0;
      ID_EX_imm <= 0;
      ID_EX_ALU_ctrl_unit_input <= 0;
      ID_EX_rd <= 0;
      ID_EX_rs1 <= 0;
      ID_EX_rs2 <= 0;

      //PC
      ID_EX_PC <= 0;
      ID_EX_istaken <= 0;
    end

    // normal
    else begin
      ID_EX_ALUOp <= ALUOp;
      ID_EX_alu_src <= alu_src;
      ID_EX_mem_write <= mem_write;
      ID_EX_mem_read <= mem_read;
      ID_EX_mem_to_reg <= mem_to_reg;
      ID_EX_reg_write <= reg_write;
      ID_EX_is_ecall <= is_ecall;
      ID_EX_halt <= tmp_halt;
      ID_EX_pc_to_reg <= pc_to_reg;
      ID_EX_isbranch <= isbranch;
      ID_EX_isjal <= isjal;
      ID_EX_isjalr <= isjalr;

      // others
      ID_EX_rs1_data <= rs1_dout_fwd;
      ID_EX_rs2_data <= rs2_dout_fwd;
      ID_EX_imm <= imm_gen_out;
      ID_EX_ALU_ctrl_unit_input <= {inst[30], inst[14:12]};
      ID_EX_rd <= rd;
      ID_EX_rs1 <= rs1;
      ID_EX_rs2 <= rs2;

      //PC
      ID_EX_PC <= IF_ID_PC;
      ID_EX_istaken <= IF_ID_istaken;
    end
  end

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .part_of_inst(ID_EX_ALU_ctrl_unit_input),  // input
    .ALUOp(ID_EX_ALUOp),         // output
    .alu_op(alu_op)
  );

  Forwarding_unit fwd_unit(
    .EX_MEM_reg_write(EX_MEM_reg_write),
    .MEM_WB_reg_write(MEM_WB_reg_write),
    .EX_MEM_rd(EX_MEM_rd),
    .MEM_WB_rd(MEM_WB_rd),
    .rs1(ID_EX_rs1),
    .rs2(ID_EX_rs2),
    .ForwardA(ForwardA),
    .ForwardB(ForwardB)
  );


  // ---------- ALU ----------
  assign alu_in_1 = (ForwardA == 2) ? EX_MEM_alu_out : (ForwardA == 1) ? rd_din : ID_EX_rs1_data;
  assign alu_in_2 = (ForwardB == 2) ? EX_MEM_alu_out : (ForwardB == 1) ? rd_din : ID_EX_rs2_data;
  // consider forwarding value and immediate value
  assign alu_in_2_imm = (ID_EX_alu_src == 1) ? ID_EX_imm : alu_in_2;
  assign alu_in_1_pc = (ID_EX_pc_to_reg) ? ID_EX_PC : alu_in_1;
  assign alu_in_2_imm_pc = (ID_EX_pc_to_reg) ? 4 : alu_in_2_imm;
  ALU alu (
    .alu_op(alu_op),      // input
    .alu_in_1(alu_in_1_pc),    // input  
    .alu_in_2(alu_in_2_imm_pc),    // input
    .alu_result(alu_out),  // output
    .alu_bcond(alu_bcond)     // output
  );


compute_actual_pc compute_pc(
  .current_pc(ID_EX_PC),
  .rs1(alu_in_1),
  .imm_gen_out(ID_EX_imm),
  .isbranch(ID_EX_isbranch),
  .isjal(ID_EX_isjal),
  .isjalr(ID_EX_isjalr),
  .alu_bcond(alu_bcond),
  .target(target)
);

assign actual_taken = (ID_EX_isbranch && alu_bcond) || ID_EX_isjal || ID_EX_isjalr;
misprediction_detector_not_taken mispred_detector_not_taken(
  .target(target),
  .actual_taken(actual_taken),
  .PCSrc(PCSrc),
  .isflush(isflush)
);

  assign next_pc = (PCSrc == 0) ? pred_pc : target; 


  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
      if (reset) begin
      // control signals
        EX_MEM_mem_write <= 0;
        EX_MEM_mem_read <= 0;
        EX_MEM_mem_to_reg <= 0;
        EX_MEM_reg_write <= 0;
        EX_MEM_halt <= 0;

      // others
        EX_MEM_rd <= 0;
        EX_MEM_alu_out <= 0;
        EX_MEM_dmem_data <= 0;

      end

      else begin
        // control signals
        EX_MEM_mem_write <= ID_EX_mem_write;
        EX_MEM_mem_read <= ID_EX_mem_read;
        EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;
        EX_MEM_reg_write <= ID_EX_reg_write;
        EX_MEM_halt <= ID_EX_halt;

        // others
        EX_MEM_rd <= ID_EX_rd;
        EX_MEM_alu_out <= alu_out;
        EX_MEM_dmem_data <= alu_in_2;


      end
end

  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (EX_MEM_alu_out),       // input
    .din (EX_MEM_dmem_data),        // input
    .mem_read (EX_MEM_mem_read),   // input
    .mem_write (EX_MEM_mem_write),  // input
    .dout (dmem_dout)        // output
  );

  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      //control signal
      MEM_WB_mem_to_reg <= 0;
      MEM_WB_reg_write <= 0;
      MEM_WB_halt <= 0;

      //others
      MEM_WB_rd <= 0;
      MEM_WB_mem_to_reg_src_1 <=0;
      MEM_WB_mem_to_reg_src_2 <=0;
    end
    else begin
      MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
      MEM_WB_reg_write <= EX_MEM_reg_write;
      MEM_WB_halt <= EX_MEM_halt;

      //others
      MEM_WB_rd <= EX_MEM_rd;
      MEM_WB_mem_to_reg_src_1 <= EX_MEM_alu_out;
      MEM_WB_mem_to_reg_src_2 <= dmem_dout;
    end
  end
  // mem_to_reg_src_1 : ALU result, mem_to_reg_src_2 : data memory output
  assign rd_din = (MEM_WB_mem_to_reg == 0) ? MEM_WB_mem_to_reg_src_1 : MEM_WB_mem_to_reg_src_2;
  assign is_halted = MEM_WB_halt;
  
endmodule
