module instr_decode(opcode,rd,rs1,rs2,funct3,funct7,instr);
    output [7:0] opcode;
    output [4:0] rd,rs1,rs2;
    output [2:0] funct3;
    output [6:0] funct7;
    output [31:0] imm32;

    input [31:0] instr;

    assign opcode = instr[6:0];

    always@(*)
        begin
            case(opcode)
                //R-type
                7'b0110011: begin
                    rd = instr[11:7];
                    rs1 = instr[19:15];
                    rs2 = instr[24:20];
                    fucnt3 = instr[14:12];
                    funct7 = instr[31:25];
                    end

                //I-type
                7'b001011: begin 
                    rd = instr[11:7];
                    rs1 = instr[19:15];
                    funct3 = instr[14:12];
                    imm32 = {{20{instr[31]}},instr[31:20]};
                    end
                
                //I-type (JALR)
                7'b1100111: begin
                    rd = instr[11:7];
                    rs1 = instr[19:15];
                    funct3 = instr[14:12];
                    imm32 = {{20{instr[31]}},instr[31:20]};
                    end

                //S-type
                7'b0100011: begin
                    rs1 = instr[19:15];
                    rs2 = instr[24:20];
                    funct3 = instr[14:12];
                    imm32 = {{20{instr[31]}},{instr[31:25],instr[11:7]}};
                    end

                //B-type
                7'b1100011: begin
                    rs1 = instr[19:15];
                    rs2 = instr[24:20];
                    funct3 = instr[14:12];
                    imm32 = {{19{instr[31]}},instr[31],instr[7],instr[30:25],instr[11:8]};
                    end

                //U-type
                7'b0110111: begin
                    rd = instr[11:7];
                    imm32 = instr[31:12] << 12;
                    end
                
                //J-type
                7'b1101111: begin
                    rd = instr[11:7];
                    imm32 = {{11{instr[31]}},instr[31],instr[19:12],instr[20],instr[30:21]};
                    end
                
                //illegal instruction
                // default : begin
                //end
    
            endcase    
        end

endmodule
