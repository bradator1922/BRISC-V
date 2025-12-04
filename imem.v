module imem (addr,instr_data);
input [31:0] addr;
output [31:0] instr_data;

    reg [31:0] imem [0:255];      // 1 KB = 256 words
    wire [7:0] idx = addr[9:2];   // word index

    assign instr_data = imem[idx];

endmodule
