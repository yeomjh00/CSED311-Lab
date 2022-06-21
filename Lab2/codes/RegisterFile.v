// output of RF is datatype output originally. thus try with assign later.
module RegisterFile(input	reset,
                    input clk,
                    input [4:0] rs1,          // source register 1
                    input [4:0] rs2,          // source register 2
                    input [4:0] rd,           // destination register
                    input [31:0] rd_din,      // input data for rd
                    input write_enable,          // RegWrite signal
                    output reg [31:0] rs1_dout,   // output of rs 1
                    output reg [31:0] rs2_dout,  // output of rs 2
			output [31:0] x17); 
  integer i;
  // Register file
  reg [31:0] rf[0:31];
  assign x17 = rf[17];

  // TODO
  // Asynchronously read register file
	always@(*) begin
		rs1_dout = rf[rs1];
		rs2_dout = rf[rs2];
	end
  // Synchronously write data to the register file
	always@(posedge clk) begin
		if (write_enable && rd != 0)
			rf[rd] <= rd_din;
	end

  // Initialize register file (do not touch)
  always @(posedge clk) begin
    // Reset register file
    if (reset) begin
      for (i = 0; i < 32; i = i + 1)
        rf[i] = 32'b0;
      rf[2] = 32'h2ffc; // stack pointer
    end
  end
endmodule
