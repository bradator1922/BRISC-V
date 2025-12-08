// © 2025 bradator1922 (Bharath). All rights reserved.
// Provided for learning and modification only.
// Reuse or submission of this architecture, or any substantially similar derivative, is strictly prohibited without written permission.

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

