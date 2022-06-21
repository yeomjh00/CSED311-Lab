
`include "vending_machine_def.v"
	

module calculate_current_state(i_input_coin,i_select_item,item_price,coin_value,current_total,
input_total, output_total, return_total,current_total_nxt,wait_time,o_return_coin,o_available_item,o_output_item);


	
	input [`kNumCoins-1:0] i_input_coin,o_return_coin;
	input [`kNumItems-1:0]	i_select_item;			
	input [31:0] item_price [`kNumItems-1:0];
	input [31:0] coin_value [`kNumCoins-1:0];
	input [`kTotalBits-1:0] current_total;
	input [31:0] wait_time;
	output reg [`kNumItems-1:0] o_available_item,o_output_item;
	output reg  [`kTotalBits-1:0] input_total, output_total, return_total,current_total_nxt;
	integer i;

	wire [`kTotalBits-1:0]wire_input_total;
	wire [`kTotalBits-1:0]wire_output_total;
	wire [`kTotalBits-1:0]wire_return_total;
	wire [`kNumItems-1:0] wire_available_item;

	
	BitChecker #(.kBitNums(`kNumCoins))Input_Checker(.Bits(i_input_coin), .Values(coin_value), .BitValue(wire_input_total));
	BitChecker #(.kBitNums(`kNumItems))Output_Checker(.Bits(o_output_item), .Values(item_price), .BitValue(wire_output_total));
	BitChecker #(.kBitNums(`kNumCoins))Return_Checker(.Bits(o_return_coin), .Values(coin_value), .BitValue(wire_return_total));
	
	check_available_item check_available_item_inst(.current_total(current_total), .item_price(item_price), .o_available_item(wire_available_item));


	// Combinational logic for the next states
	always @(*) begin
		// TODO: current_total_nxt
		// You don't have to worry about concurrent activations in each input vector (or array).
		// Calculate the next current_total state.
		// Following Codes are replaced to module "BitChecker"
/*
		input_total = `kTotalBits'd0;
		for (i=0; i<`kNumCoins; i=i+1) begin
			if (i_input_coin[i]) begin
				input_total = coin_value[i];
				i = `kNumCoins;
			end	
		end
		
		output_total = `kTotalBits'd0;
		for (i=0; i<`kNumItems; i=i+1) begin
			if(o_output_item[i]) begin
				output_total = item_price[i];
				i = `kNumItems;
			end
		end

		return_total = `kTotalBits'd0;
		for (i=0; i<`kNumCoins; i=i+1) begin
			if(o_return_coin[i]) begin
				return_total = coin_value[i];
				i=`kNumCoins;
			end
		end
*/
		current_total_nxt = current_total + wire_input_total - wire_output_total - wire_return_total;
	end

	
	
	// Combinational logic for the outputs
	always @(*) begin
		// TODO: o_available_item
		/*
		o_available_item = `kNumItems'd0;
		for (i=0;i<`kNumItems; i=i+1) begin
			if(item_price[i] <= current_total)
				o_available_item[i] = 1'b1;
		end
		*/
		o_available_item = wire_available_item;
		// TODO: o_output_item
		o_output_item = `kNumItems'd0;
		for(i=0; i<`kNumItems; i=i+1)begin
			if(i_select_item[i] && o_available_item[i])
				o_output_item[i] = 1'b1;
		end

	end
 
	


endmodule


module BitChecker #(parameter kBitNums=4)(
	Bits,
	Values,
	BitValue
);
	input [kBitNums-1: 0]Bits;
	input [31: 0]Values[kBitNums-1:0];
	output reg [`kTotalBits -1: 0]BitValue;
	integer i;

	always@(*) begin
		BitValue = `kTotalBits'd0;
		for(i=0; i<kBitNums; i=i+1) begin
			if(Bits[i]) begin
				BitValue = Values[i]; 
				i=kBitNums;
			end
		end
	end

endmodule

module check_available_item(
	current_total,
	item_price,	
	o_available_item
);
	
	input [31:0] item_price [`kNumItems-1:0];
	input [`kTotalBits-1:0] current_total;
	output reg [`kNumItems-1:0] o_available_item;
	integer i;
	
	always@(*) begin
		o_available_item = `kNumItems'd0;
		for (i=0;i<`kNumItems; i=i+1) begin
			if(item_price[i] <= current_total)
				o_available_item[i] = 1'b1;
		end
	end


endmodule

