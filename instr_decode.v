module instr_decode (instr,opcode,rd,rs1,rs2,funct3,funct7,imm32,isMulDiv);
    input  [31:0] instr;
    output [6:0]  opcode;
    output [4:0]  rd;
    output [4:0]  rs1;
    output [4:0]  rs2;
    output [2:0]  funct3;
    output [6:0]  funct7;
    output reg [31:0] imm32;
    output reg isMulDiv;

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    always @(*) begin
        isMulDiv = 1'b0;
        imm32    = 32'd0;

        case (opcode)
            // R-type: ADD,SUB,SLT,SLL,... MUL,DIV,...
            7'b0110011: begin
                imm32 = 32'd0;
                if (funct7 == 7'b0000001)
                    isMulDiv = 1'b1;
            end

            // I-type ALU, LOAD, JALR
            // imm[31:0] = signext(instr[31:20])
            7'b0010011,
            7'b0000011,
            7'b1100111: begin
                imm32 = {{20{instr[31]}}, instr[31:20]};
            end

            // S-type stores
            // imm = signext({instr[31:25], instr[11:7]})
            7'b0100011: begin
                imm32 = {{20{instr[31]}},
                         instr[31:25],
                         instr[11:7]};
            end

            // B-type branches
            // imm[12|10:5|4:1|11|0]
            7'b1100011: begin
                imm32 = {{19{instr[31]}},
                         instr[31],
                         instr[7],
                         instr[30:25],
                         instr[11:8],
                         1'b0};
            end

            // J-type: JAL
            // imm[20|10:1|11|19:12|0]
            7'b1101111: begin
                imm32 = {{11{instr[31]}},
                         instr[31],
                         instr[19:12],
                         instr[20],
                         instr[30:21],
                         1'b0};
            end

            // U-type: LUI, AUIPC
            7'b0110111,
            7'b0010111: begin
                imm32 = {instr[31:12], 12'b0};
            end

            default: begin
                imm32    = 32'd0;
                isMulDiv = 1'b0;
            end
        endcase
    end
endmodule

