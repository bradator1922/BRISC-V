module alu (A,B,funct3,funct7,ALUOp,ALUResult,Zero);

    input   [31:0] A,B;
    input   [2:0]  funct3;
    input   [6:0]  funct7;
    input   [1:0]  ALUOp;
    output reg  [31:0] ALUResult;
    output Zero;

    wire [31:0] sum  = A + B;
    wire [31:0] diff = A - B;

    wire [4:0] shamt = B[4:0];
    wire [31:0] sll_out = A << shamt;
    wire [31:0] srl_out = A >> shamt;
    wire [31:0] sra_out = $signed(A) >>> shamt;

    wire [31:0] slt_out  = ($signed(A) <  $signed(B)) ? 32'd1 : 32'd0;
    wire [31:0] sltu_out = (A < B) ? 32'd1 : 32'd0;

    always @(*) begin
        case (ALUOp)

            2'b00: ALUResult = sum;          // ADD (LUI, AUIPC, load/store, JALR)
            2'b01: ALUResult = diff;         // SUB (branches)

            2'b10: begin                     // R-TYPE
                case (funct3)
                    3'b000: ALUResult = funct7[5] ? diff : sum;
                    3'b111: ALUResult = A & B;
                    3'b110: ALUResult = A | B;
                    3'b100: ALUResult = A ^ B;
                    3'b001: ALUResult = sll_out;
                    3'b101: ALUResult = funct7[5] ? sra_out : srl_out;
                    3'b010: ALUResult = slt_out;
                    3'b011: ALUResult = sltu_out;
                    default: ALUResult = 32'd0;
                endcase
            end

            2'b11: begin                     // I-TYPE ALU
                case (funct3)
                    3'b000: ALUResult = sum;     // ADDI
                    3'b111: ALUResult = A & B;   // ANDI
                    3'b110: ALUResult = A | B;   // ORI
                    3'b100: ALUResult = A ^ B;   // XORI
                    3'b001: ALUResult = sll_out; // SLLI
                    3'b101: ALUResult = funct7[5] ? sra_out : srl_out; // SRAI/SRLI
                    3'b010: ALUResult = slt_out; // SLTI
                    3'b011: ALUResult = sltu_out;// SLTIU
                    default: ALUResult = 32'd0;
                endcase
            end

            default: ALUResult = 32'd0;
        endcase
    end

    assign Zero = (ALUResult == 32'd0);

endmodule

