// © 2025 bradator1922 (Bharath). All rights reserved.
// Provided for learning and modification only.
// Reuse or submission of this architecture, or any substantially similar derivative, is strictly prohibited without written permission.

module imem (addr,instr_data);
input [31:0] addr;
output [31:0] instr_data;

    reg [31:0] imem [0:255];      // 1 KB = 256 words
    wire [7:0] idx = addr[9:2];   // word index

    assign instr_data = imem[idx];

endmodule

