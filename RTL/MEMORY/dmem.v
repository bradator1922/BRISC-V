// © 2025 bradator1922 (Bharath). All rights reserved.
// Provided for learning and modification only.
// Reuse or submission of this architecture, or any substantially similar derivative, is strictly prohibited without written permission.

module dmem (clk,rst,mem_read,mem_write,funct3,addr,write_data,read_data);

    input  clk,rst,mem_read,mem_write;
    input [2:0]  funct3;
    input [31:0] addr,write_data;
    output reg  [31:0] read_data;

    // 1 KB byte-addressable memory
    reg [7:0] mem [0:1023];

    reg [7:0] b0, b1, b2, b3;
    reg [15:0] halfword;
    reg [31:0] word32;

    wire [9:0] byte_addr = addr[9:0];

    integer i;

    // RESET + STORE operations
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 1024; i = i + 1)
                mem[i] <= 8'd0;
        end else if (mem_write) begin
            case (funct3)
                3'b000: begin  // SB
                    mem[byte_addr] <= write_data[7:0];
                end

                3'b001: begin  // SH
                    mem[byte_addr]     <= write_data[7:0];
                    mem[byte_addr + 1] <= write_data[15:8];
                end

                3'b010: begin  // SW
                    mem[byte_addr]     <= write_data[7:0];
                    mem[byte_addr + 1] <= write_data[15:8];
                    mem[byte_addr + 2] <= write_data[23:16];
                    mem[byte_addr + 3] <= write_data[31:24];
                end
            endcase
        end
    end

    // LOAD operations
    always @(*) begin
        // Default values to avoid latch inferences
        b0 = 8'd0;
        b1 = 8'd0;
        b2 = 8'd0;
        b3 = 8'd0;
        halfword = 16'd0;
        word32 = 32'd0;

        if (!mem_read) begin
            read_data = 32'd0;
        end else begin
            case (funct3)
                3'b000: begin // LB
                    b0 = mem[byte_addr];
                    read_data = {{24{b0[7]}}, b0};
                end

                3'b001: begin // LH
                    b0 = mem[byte_addr];
                    b1 = mem[byte_addr + 1];
                    halfword = {b1, b0};
                    read_data = {{16{halfword[15]}}, halfword};
                end

                3'b010: begin // LW
                    b0 = mem[byte_addr];
                    b1 = mem[byte_addr + 1];
                    b2 = mem[byte_addr + 2];
                    b3 = mem[byte_addr + 3];
                    word32 = {b3, b2, b1, b0};
                    read_data = word32;
                end

                3'b100: begin // LBU
                    b0 = mem[byte_addr];
                    read_data = {24'd0, b0};
                end

                3'b101: begin // LHU
                    b0 = mem[byte_addr];
                    b1 = mem[byte_addr + 1];
                    halfword = {b1, b0};
                    read_data = {16'd0, halfword};
                end

                default: begin
                    read_data = 32'd0;
                end
            endcase
        end
    end

endmodule


