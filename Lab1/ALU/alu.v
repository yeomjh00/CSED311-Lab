`include "alu_func.v"


module ALU #(parameter data_width = 16) (
	input [data_width - 1 : 0] A,
	input [data_width - 1 : 0] B,
	input [3 : 0] FuncCode,
       	output reg [data_width - 1: 0] C,
       	output reg OverflowFlag
);

// Do not use delay in your implementation.

// You can declare any variables as needed.
/*
	YOUR VARIABLE DECLARATION...
*/
	wire wire_OverflowFlag;
	wire [data_width - 1 : 0] wire_add_sub;
	wire [data_width - 1 : 0] wire_bitwise;
	wire [data_width -1 : 0] wire_shift;
	wire [data_width -1 : 0] wire_remain;
	
	ALU_add_sub #(.data_width(data_width))add_sub_inst(.A(A), .B(B), .FuncCode(FuncCode), .C(wire_add_sub), .OverflowFlag(wire_OverflowFlag));
	ALU_bitwise #(.data_width(data_width))bitwise_inst(.A(A), .B(B), .FuncCode(FuncCode), .C(wire_bitwise));
	ALU_shift #(.data_width(data_width))shift_inst(.A(A), .FuncCode(FuncCode), .C(wire_shift));
	ALU_remain #(.data_width(data_width))remain_inst(.A(A), .FuncCode(FuncCode), .C(wire_remain));



initial begin
	C = 0;
	OverflowFlag = 0;
end   	

// TODO: You should implement the functionality of ALU!
// (HINT: Use 'always @(...) begin ... end')
	always @(*) begin
		OverflowFlag = 0;
		if (FuncCode >=0 && FuncCode <2) begin
			C = wire_add_sub;
			OverflowFlag = wire_OverflowFlag;
		end

		else if(FuncCode > 2 && FuncCode <10) begin
			C = wire_bitwise;
		end

		else if(FuncCode > 9 && FuncCode <14) begin
			C = wire_shift;
		end
		
		else begin
			C = wire_remain;
		end
	end

endmodule


module ALU_add_sub #(parameter data_width = 16)(
	input [data_width-1 : 0] A,
	input [data_width-1 : 0] B,
	input [3 :0] FuncCode,
	output reg [data_width -1 : 0] C,
	output reg OverflowFlag
);
	always@(*) begin
		case(FuncCode)
			`FUNC_ADD : begin
				C = A+B;
				if (A[data_width-1] == B[data_width-1] && A[data_width-1] != C[data_width-1]) begin
					OverflowFlag = 1;
				end
				else begin
					OverflowFlag =0;
				end
			end

			`FUNC_SUB : begin
				C <= A-B;
				if ((A[data_width-1] == 0) && (B[data_width-1]==1) && (C[data_width-1] == 1)) begin
					OverflowFlag =1;
				end
				
				else if((A[data_width-1] == 1) && (B[data_width-1]==0) && (C[data_width-1] == 0)) begin
					OverflowFlag =1;
				end

				else 
					OverflowFlag = 0;			

				end
			default : OverflowFlag =0;
		endcase
	end
endmodule

module ALU_bitwise #(parameter data_width = 16)(
	input [data_width-1 : 0] A,
	input [data_width-1 : 0] B,
	input [3 :0] FuncCode,
	output reg [data_width -1 : 0] C
);
	always@(*) begin
		case(FuncCode)
			`FUNC_NOT : C = ~A;
			`FUNC_AND : C = A & B;
			`FUNC_OR : C = A | B;
			`FUNC_NAND : C = ~(A & B);
			`FUNC_NOR : C = ~(A | B);
			`FUNC_XOR : C = A^B;
			`FUNC_XNOR : C = ~(A^B);
			default : C = 0;
		endcase
	end
endmodule

module ALU_shift #(parameter data_width = 16)(
	input [data_width-1 : 0] A,
	input [3 :0] FuncCode,
	output reg [data_width -1 : 0] C
);
	always@(*) begin
		case(FuncCode)
			`FUNC_LLS : C = A << 1;
			`FUNC_LRS : C = A >> 1;
			`FUNC_ALS : C = A <<< 1;
			`FUNC_ARS : begin 
				C = A >>> 1;
				C[data_width -1] = A[data_width-1];
				end
			default : C = 0;
		endcase
	end
endmodule

module ALU_remain #(parameter data_width = 16)(
	input [data_width-1 : 0] A,
	input [3 :0] FuncCode,
	output reg [data_width -1 : 0] C
);
	always@(*) begin
		case(FuncCode)
			`FUNC_ID : C = A; 
			`FUNC_TCP : C = ~A +1;
			`FUNC_ZERO : C = 0;
			default : C = 0;
		endcase
	end

endmodule

