// Do not submit this file.
`include "cpu.v"

module top; 
  reg reset;
  reg clk;
  wire is_halted;
  reg [31:0] total_cycle;

  CPU cpu(
    .reset(reset), 
    .clk(clk),
    .is_halted(is_halted)
  );

  // Initialize values for simulation
  initial begin
    clk = 1'b0;
    reset = 0;
    total_cycle = 32'b0;
    #1 reset = 1;         // Drive 1 to reset register values
    #6 reset = 0;
  end

  // Generate clock
  always begin
    #5 clk = ~clk;
  end

  // Calculate total cycle
  always @(posedge clk) begin
    total_cycle <= total_cycle + 1;
  end

  // After simulation finishes.
  integer i;
  always @(posedge clk) begin
    if (is_halted) begin
      $display("TOTAL CYCLE %d\n", total_cycle);
      // Print register values
      for (i = 0; i < 32; i = i + 1)
        $display("%d %x\n", i, cpu.reg_file.rf[i]);
      $finish();
    end
  end

endmodule


/* Value Checking Codes
  else begin
      $display("TOTAL CYCLE %d, inst: %h\n", total_cycle, cpu.IF_ID_inst);
      $display("rd: %h, rs1: %dth %h/%h , rs2: %dth %h/%h = %h  write? %h\n
                %h / %h, A: %b %b  B: %b %b\n
                rd_din : %h mem_to_reg/write_en : %b/%b store data: %h / hazard_detected : %b",
                  cpu.ID_EX_rd, cpu.ID_EX_rs1, cpu.rs1_dout, cpu.alu_in_1,
                  cpu.ID_EX_rs2, cpu.rs2_dout, cpu.alu_in_2_imm, cpu.alu_out, cpu.ID_EX_reg_write,
                  cpu.rs1_dout_fwd, cpu.rs2_dout_fwd,
                  cpu.internal_forwardA, cpu.ForwardA, cpu.internal_forwardB, cpu.ForwardB,
                  cpu.rd_din, cpu.MEM_WB_mem_to_reg, cpu.MEM_WB_reg_write, cpu.EX_MEM_dmem_data, cpu.hazard_detect);
        for (i = 0; i < 32; i = i + 1)
          if(cpu.reg_file.rf[i] != 0)
            $display("%d %x\n", i, cpu.reg_file.rf[i]);
      
      if(total_cycle >= 50)
        $finish();
  end
  
      else begin
    $display("TOTAL CYCLE %d, inst: %h \n", total_cycle, cpu.IF_ID_inst);
    $display("ready/valid/hit : %h / %h / %h  state: %d\n", cpu.is_ready, cpu.is_output_valid, cpu.is_hit, cpu.cache.state);
    $display("rd: %h, rs1: %dth %h/%h , rs2: %dth %h/%h = %h  write? %h\n
              %h / %h, A: %b %b  B: %b %b\n
              rd_din : %h mem_to_reg/write_en : %b/%b store data: %h / hazard_detected : %b",
                cpu.ID_EX_rd, cpu.ID_EX_rs1, cpu.rs1_dout, cpu.alu_in_1,
                cpu.ID_EX_rs2, cpu.rs2_dout, cpu.alu_in_2_imm, cpu.alu_out, cpu.ID_EX_reg_write,
                cpu.rs1_dout_fwd, cpu.rs2_dout_fwd,
                cpu.internal_forwardA, cpu.ForwardA, cpu.internal_forwardB, cpu.ForwardB,
                cpu.rd_din, cpu.MEM_WB_mem_to_reg, cpu.MEM_WB_reg_write, cpu.EX_MEM_dmem_data, cpu.hazard_detect);
      for (i = 0; i < 32; i = i + 1)
        if(cpu.reg_file.rf[i] != 0)
          $display("%d %x\n", i, cpu.reg_file.rf[i]);
  end


*/