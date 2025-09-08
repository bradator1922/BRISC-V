module reg_file(rs1_data_out,rs2_data_out,clk,reg_write,write_data,rs1_addr,rs2_addr,rd_addr);
    output [31:0] rs1_data_out,rs2_data_out ;
    input clk,reg_write;
    input [4:0] rd_addr,rs1_addr,rs2_addr;
    input [31:0] write_data;

    reg [31:0] reg_file_mem [31:0];

    assign rs1_data_out = (rs1_addr == 5'd0) ? 32'd0 : reg_file_mem[rs1_addr];
    assign rs2_data_out = (rs2_addr == 5'd0) ? 32'd0 : reg_file_mem[rs2_addr];

    always@(posedge clk)
        if(reg_write && rd_addr != 5'd0)
            begin 
                reg_file_mem[rd_addr] <= write_data;
            end

endmodule