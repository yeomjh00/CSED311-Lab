`include "opcodes.v"

module PC(
	reset,
	clk,
	next_pc,
	nextPCWrite,
	current_pc
	);

	input reset;
	input clk;
	input nextPCWrite;
	input [`WordSize -1 : 0] next_pc;
	output reg [`WordSize -1 : 0] current_pc;

	always@(posedge clk)begin
		if(reset)
			current_pc <= 0 ;
		else if(nextPCWrite)
			current_pc <= next_pc;
		else
			current_pc <= current_pc;
	end
endmodule
