module mux_4_1 (i0,i1,i2,i3,sel,mux_out);
input [31:0] i0,i1,i2,i3;
input [1:0]sel;
output [31:0] mux_out;

assign mux_out = sel[1] ? (sel[0] ? i3 : i2 ) : (sel[0] ? i1 : i0 );
endmodule
