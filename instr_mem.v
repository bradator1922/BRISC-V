module instr_mem(instr_mem_data,clk,rst,mem_read_i,instr_mem_addr);
    output reg [31:0]instr_mem_data;
    input mem_read_i,clk,rst;
    input [31:0] instr_mem_addr;

    reg [31:0] imem [0:255];
    wire [7:0] idx = instr_mem_addr[9:2]; //ignore [1:0] bits from PC (byte address)

    always@(posedge clk or posedge rst)
        begin
            if(rst)
                instr_mem_data <= 32'h0000_0013; // ADDI x0,x0,0
            else if(mem_read_i)
                instr_mem_data <=  imem[idx];
            else
                instr_mem_data <= 32'h0000_0013;
        end
endmodule
