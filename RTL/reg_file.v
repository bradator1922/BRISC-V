// © 2025 bradator1922 (Bharath). All rights reserved.
// Provided for learning and modification only.
// Reuse or submission of this architecture, or any substantially similar derivative, is strictly prohibited without written permission.

module reg_file (clk,rst,rs1,rs2,rd,write_data,reg_write,rs1_data,rs2_data);

    input  clk,rst,reg_write;
    input [4:0]  rs1,rs2,rd;
    input [31:0] write_data;
    output [31:0] rs1_data,rs2_data;

     reg [31:0] regs [0:31];
    integer i;

    assign rs1_data = (rs1 == 0) ? 32'd0 : regs[rs1];
    assign rs2_data = (rs2 == 0) ? 32'd0 : regs[rs2];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;
        end else if (reg_write && (rd != 0)) begin
            regs[rd] <= write_data;
        end
    end
endmodule

