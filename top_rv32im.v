module top_rv32im(clk,rst,pc_val,instr_val,pc_write_val,ir_write_val,opcode_val,pc_plus_4_val,ALUResult_val,next_pc_val);

input clk,rst;

//test signals for fixing bug
output [31:0] pc_val;
output [31:0] instr_val;
output pc_write_val,ir_write_val;
output [6:0] opcode_val;
output [31:0] pc_plus_4_val,next_pc_val;
output [31:0] ALUResult_val;




wire [31:0] pc, next_pc, pc4, pc_base;
wire [31:0] instr_data,instr;
wire [31:0] A, B;
wire [31:0] rs1_data, rs2_data;
wire [31:0] ALUMD_Result,ALUMDout;
wire [31:0] ALUResult,MDResult;
wire [31:0] read_data,MDR;
wire [31:0] alumd_pc,alumdpc_mdr;
wire [31:0] a_mux_out,b_mux_out;
wire [31:0] imm32;
wire isMulDiv;
wire [6:0] opcode;
wire [4:0] rd,rs1,rs2;
wire [2:0] funct3;
wire [6:0] funct7;
wire Zero;
wire ready,busy,div_by_zero;
wire [31:0] pc_plus_4 = pc + 4;

// Control signals
wire pc_write, pc_base_write, pc4_write, a_write, b_write, ir_write, mdr_write, alumd_out_write;
wire reg_write;
wire [1:0] ALUOp;
wire MD_start;
wire mem_read_d;
wire mem_write;
// 00:(A), 01:0, 10:PC, 11:PC_base
wire [1:0] ALUSrcA;
// 00:(B), 01:4, 10:imm, 11:0
wire [1:0] ALUSrcB;
wire link_sel;                 // 0: PC+4 ; 1: ALUMDout
wire write_data_sel;           // 0: alumd_pc ; 1: MDR
wire is_mul_out;               // 0: ALUResult ; 1: MDResult
wire [1:0] pc_source;          // 00:alumdpc_mdr, 01:ALUResult, 10:ALUMDout, 11:masked(ALUResult)


//for testing
assign pc_val = pc;
assign instr_val = instr;
assign pc_write_val =pc_write;
assign ir_write_val = ir_write;
assign opcode_val = opcode;
assign pc_plus_4_val = pc_plus_4;
assign ALUResult_val = ALUResult;
assign next_pc_val = next_pc;




//Registers
dff pc_reg (clk,rst,pc_write,next_pc,pc);
dff instr_reg (clk,rst,ir_write,instr_data,instr);
dff pc_base_reg (clk,rst,pc_base_write,pc,pc_base);
dff pc4_reg (clk,rst,pc4_write,pc_plus_4,pc4);

dff a_reg (clk,rst,a_write,rs1_data,A);
dff b_reg (clk,rst,b_write,rs2_data,B);

dff alumd_out_reg (clk,rst,alumd_out_write,ALUMD_Result,ALUMDout);
   
dff mdr_reg (clk,rst,mdr_write,read_data,MDR);


//Control Multiplexers
mux_2_1 alu_md_mux (ALUResult,MDResult,is_mul_out,ALUMD_Result);
mux_2_1 alumd_pc_mux (ALUMDout,pc4,link_sel,alumd_pc);
mux_2_1 alumdpc_mdr_mux (alumd_pc,MDR,write_data_sel,alumdpc_mdr);

mux_4_1 a_mux (A,32'b0,pc,pc_base,ALUSrcA,a_mux_out);
mux_4_1 b_mux (B,32'd4,imm32,32'b0,ALUSrcB,b_mux_out);
mux_4_1 npc (alumdpc_mdr,pc_plus_4,ALUMDout,{ALUResult[31:1],1'b0},pc_source,next_pc);

//instruction memory
imem im (pc,instr_data);

//instrucntion decoder 
instr_decode id (instr,opcode,rd,rs1,rs2,funct3,funct7,imm32,isMulDiv);

//register file 
reg_file rf (clk,rst,rs1,rs2,rd,alumdpc_mdr,reg_write,rs1_data,rs2_data);


//dff mem_read_reg(clk, rst, mem_read_d, mem_read);   //correct if required
//data memory
dmem dm (clk,rst,mem_read_d,mem_write,funct3,ALUMDout,rs2_data,read_data);

//alu
alu al (a_mux_out,b_mux_out,funct3,funct7,ALUOp,ALUResult,Zero);

//mult/div unit
mult_div muldiv (clk,rst,MD_start,isMulDiv,A,B,funct3,funct7,MDResult,ready,busy,div_by_zero);

//control unit (FSM)
control_unit ctrl_u (
    .clk(clk),
    .rst(rst),
    .A(A),
    .B(B),

    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .isMulDiv(isMulDiv),
    .Zero(Zero),

    .ready(ready),
    .busy(busy),

    .pc_write(pc_write),
    .pc_base_write(pc_base_write),
    .pc4_write(pc4_write),
    .a_write(a_write),
    .b_write(b_write),
    .ir_write(ir_write),
    .mdr_write(mdr_write),
    .alumd_out_write(alumd_out_write),
    .reg_write(reg_write),

    .mem_read_d(mem_read_d),
    .mem_write(mem_write),

    .ALUSrcA(ALUSrcA),
    .ALUSrcB(ALUSrcB),
    .ALUOp(ALUOp),

    .MD_start(MD_start),
    .is_mul_out(is_mul_out),
    .link_sel(link_sel),
    .write_data_sel(write_data_sel),
    .pc_source(pc_source)
); 



endmodule 
