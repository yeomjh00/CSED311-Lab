`include "opcodes.v"

module PC(
	reset,
	clk,
	next_pc,
	current_pc
	);

	input reset;
	input clk;
	input [`WordSize -1 : 0] next_pc;
	output reg [`WordSize -1 : 0] current_pc;

	always@(posedge clk)begin
		if(reset)
			current_pc <= `WordSize'd0;
		else
			current_pc <= next_pc;
	end
endmodule
