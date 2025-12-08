module mux_2_1(i0,i1,sel,mux_out);
input [31:0] i0,i1;
input sel;
output [31:0] mux_out;

assign mux_out = sel ? i1 : i0;
endmodule


