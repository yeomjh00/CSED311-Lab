`include "vending_machine_def.v"

	

module check_time_and_coin(i_input_coin,i_select_item,coin_value,clk,reset_n,
			i_trigger_return, o_output_item, wait_time,o_return_coin, current_total);
	input clk;
	input reset_n;
	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0]	i_select_item;
	input [31:0] coin_value [`kNumCoins-1:0];
	input i_trigger_return;
	input [`kTotalBits-1:0] current_total;
	input [`kNumItems-1:0] o_output_item;
	integer i;

	output reg  [`kNumCoins-1:0] o_return_coin;
	output reg [31:0] wait_time;

	

	// initiate values
	initial begin
		// TODO: initiate values
		wait_time = 'd0;
		o_return_coin = `kNumCoins'd0;
	end
	
	// update coin return time
	always @(*) begin
		// TODO: update coin return time
		// Check if select is valid
		if(i_input_coin || o_output_item || i_trigger_return)
			wait_time <= 'd0;
	end

	always @(*) begin
		// TODO: o_return_coin
		o_return_coin = `kNumCoins'b000;
		if(wait_time > `kWaitTime || i_trigger_return) begin 
			if(current_total >= coin_value[2])
				o_return_coin[2] = 1'b1;
			else if(current_total >= coin_value[1])
				o_return_coin[1] = 1'b1;
			else
				o_return_coin[0] = 1'b1;
			//else if(current_total >= coin_value[0])
				//o_return_coin[0] = 1'b1;
			//else
				//o_return_coin = `kNumCoins'b000;
		end
	end


	always @(posedge clk ) begin
		if (!reset_n) begin
		// TODO: reset all states.
			wait_time <= 'd0;
		end
		else begin
		// TODO: update all states.
			wait_time <= wait_time + 1;
		end
	end
endmodule
