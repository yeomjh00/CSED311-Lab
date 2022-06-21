

module mux2to1 #(
    parameter data_width = 32
) (
    input  [data_width-1:0]  in0,
    input  [data_width-1:0]  in1,
    input sel,
    output [data_width-1:0]  out
);
    assign out = sel ? in1 : in0;
endmodule

module mux4to1 #(
    parameter data_width = 32
)
(
    input  [data_width-1:0]  in0,
    input  [data_width-1:0]  in1,
    input  [data_width-1:0]  in2,
    input  [data_width-1:0]  in3,
    input [1:0]sel,
    output [data_width-1:0]  out
);
    assign out = (sel == 0) ? in0 : (sel == 1) ? in1 : (sel == 2) ? in2 : in3;

endmodule


module adder #(parameter data_width=32) (
    input [data_width-1:0] in0,
    input [data_width-1:0] in1,
    output [data_width-1:0] out
);
    assign out = in0 + in1;
endmodule