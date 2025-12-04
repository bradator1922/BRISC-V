module dff(clk,rst,enable,d,q);
input [31:0] d;
input clk,rst,enable;
output reg [31:0] q;
always@(posedge clk or posedge rst)
    begin
    if(rst) 
        q<=32'b0;
    else if(enable)
        q<=d;   
    end
endmodule 
