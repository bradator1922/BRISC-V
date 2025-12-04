module control_unit(
    input        clk,
    input        rst,

    // datapath taps
    input  [31:0] A,
    input  [31:0] B,
    input         Zero,
    input         ready,
    input         busy,

    // decode fields
    input  [6:0]  opcode,
    input  [2:0]  funct3,
    input  [6:0]  funct7,
    input         isMulDiv,

    // control outputs
    output reg    pc_write,
    output reg    pc_base_write,
    output reg    pc4_write,
    output reg    a_write,
    output reg    b_write,
    output reg    ir_write,
    output reg    mdr_write,
    output reg    alumd_out_write,
    output reg    reg_write,

    output reg    mem_read_d,
    output reg    mem_write,

    output reg [1:0] ALUSrcA,
    output reg [1:0] ALUSrcB,
    output reg [1:0] ALUOp,

    output reg    MD_start,
    output reg    is_mul_out,
    output reg    link_sel,
    output reg    write_data_sel,
    output reg [1:0] pc_source
);

    //------------------------------------------------------
    // STATE ENCODING
    //------------------------------------------------------
    localparam
        S_FETCH1        = 6'd0,
        S_FETCH2        = 6'd1,
        S_DECODE        = 6'd2,

        S_RTYPE_EXEC    = 6'd3,
        S_RTYPE_WB      = 6'd4,

        S_ITYPE_EXEC    = 6'd5,
        S_ITYPE_WB      = 6'd6,

        S_LUI_EXEC      = 6'd7,
        S_LUI_WB        = 6'd8,

        S_AUIPC_EXEC    = 6'd9,
        S_AUIPC_WB      = 6'd10,

        S_LOAD_ADDR     = 6'd11,
        S_LOAD_READ     = 6'd12,
        S_LOAD_WB       = 6'd13,

        S_STORE_ADDR    = 6'd14,
        S_STORE_WRITE   = 6'd15,

        S_BRANCH_ADDR   = 6'd16,

        S_JAL_EXEC      = 6'd17,
        S_JAL_WB        = 6'd18,

        S_JALR_EXEC     = 6'd19,
        S_JALR_ALIGN    = 6'd20,
        S_JALR_WB       = 6'd21,

        S_MULDIV_START  = 6'd22,
        S_MULDIV_WAIT   = 6'd23,
        S_MULDIV_WB     = 6'd24;

    reg [5:0] state, next_state;

    //------------------------------------------------------
    // STATE REGISTER
    //------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= S_FETCH1;
        else
            state <= next_state;
    end

    //------------------------------------------------------
    // NEXT STATE + CONTROL LOGIC
    //------------------------------------------------------
    always @(*) begin

        //--------------------------------------------------
        // DEFAULT OUTPUTS (every cycle)
        //--------------------------------------------------
        pc_write        = 0;
        pc_base_write   = 0;
        pc4_write       = 0;
        ir_write        = 0;
        a_write         = 0;
        b_write         = 0;
        mdr_write       = 0;
        alumd_out_write = 0;
        reg_write       = 0;

        mem_read_d      = 0;
        mem_write       = 0;

        ALUSrcA         = 2'b00;
        ALUSrcB         = 2'b00;
        ALUOp           = 2'b00;

        MD_start        = 0;
        is_mul_out      = 0;

        link_sel        = 0;
        write_data_sel  = 0;
        pc_source       = 2'b01;   // default: sequential PC+4

        next_state      = state;

        //--------------------------------------------------
        // FSM
        //--------------------------------------------------
        case(state)

        //--------------------------------------------------
        // FETCH
        //--------------------------------------------------
        S_FETCH1: begin
            ALUSrcA = 2'b10;   // PC
            ALUSrcB = 2'b01;   // +4
            next_state = S_FETCH2;
        end

        S_FETCH2: begin
            pc_base_write = 1;
            pc4_write     = 1;
            ir_write      = 1;

            pc_source = 2'b01;   // PC+4
            pc_write  = 1;

            next_state = S_DECODE;
        end

        //--------------------------------------------------
        // DECODE
        //--------------------------------------------------
        S_DECODE: begin
            a_write = 1;
            b_write = 1;

            case(opcode)
                7'b0110011: next_state = S_RTYPE_EXEC;   // R
                7'b0010011: next_state = S_ITYPE_EXEC;   // I-ALU
                7'b0000011: next_state = S_LOAD_ADDR;    // LOAD
                7'b0100011: next_state = S_STORE_ADDR;   // STORE
                7'b1100011: next_state = S_BRANCH_ADDR;  // BRANCH
                7'b1101111: next_state = S_JAL_EXEC;     // JAL
                7'b1100111: next_state = S_JALR_EXEC;    // JALR
                7'b0110111: next_state = S_LUI_EXEC;     // LUI
                7'b0010111: next_state = S_AUIPC_EXEC;   // AUIPC
                default:     next_state = S_FETCH1;
            endcase
        end

        //--------------------------------------------------
        // R-TYPE
        //--------------------------------------------------
        S_RTYPE_EXEC: begin
            ALUSrcA = 2'b00;
            ALUSrcB = 2'b00;
            ALUOp   = 2'b10;

            if (isMulDiv)
                next_state = S_MULDIV_START;
            else begin
                alumd_out_write = 1;
                next_state = S_RTYPE_WB;
            end
        end

        S_RTYPE_WB: begin
            link_sel = 1'b0;        // write ALUMDout
            reg_write = 1;
            next_state = S_FETCH1;
        end

        //--------------------------------------------------
        // I-TYPE
        //--------------------------------------------------
        S_ITYPE_EXEC: begin
            ALUSrcA = 2'b00;
            ALUSrcB = 2'b10;   // imm
            ALUOp   = 2'b11;

            alumd_out_write = 1;
            next_state = S_ITYPE_WB;
        end

        S_ITYPE_WB: begin
            link_sel = 0;
            reg_write = 1;
            next_state = S_FETCH1;
        end

        //--------------------------------------------------
        // LUI
        //--------------------------------------------------
        S_LUI_EXEC: begin
            ALUSrcA = 2'b01;   // 0
            ALUSrcB = 2'b10;   // imm
            ALUOp   = 2'b00;
            alumd_out_write = 1;
            next_state = S_LUI_WB;
        end

        S_LUI_WB: begin
            link_sel = 0;
            reg_write = 1;
            next_state = S_FETCH1;
        end

        //--------------------------------------------------
        // AUIPC
        //--------------------------------------------------
        S_AUIPC_EXEC: begin
            ALUSrcA = 2'b10;  // PC
            ALUSrcB = 2'b10;  // imm
            ALUOp   = 2'b00;
            alumd_out_write = 1;
            next_state = S_AUIPC_WB;
        end

        S_AUIPC_WB: begin
            link_sel = 0;
            reg_write = 1;
            next_state = S_FETCH1;
        end

        //--------------------------------------------------
        // LOAD
        //--------------------------------------------------
        S_LOAD_ADDR: begin
            ALUSrcA = 2'b00;
            ALUSrcB = 2'b10;
            ALUOp   = 2'b00;
            alumd_out_write = 1;
            next_state = S_LOAD_READ;
        end

        S_LOAD_READ: begin
            mem_read_d = 1;
            mdr_write  = 1;
            next_state = S_LOAD_WB;
        end

        S_LOAD_WB: begin
            reg_write = 1;
            write_data_sel = 1; // MDR
            next_state = S_FETCH1;
        end

        //--------------------------------------------------
        // STORE
        //--------------------------------------------------
        S_STORE_ADDR: begin
            ALUSrcA = 2'b00;
            ALUSrcB = 2'b10;
            alumd_out_write = 1;
            next_state = S_STORE_WRITE;
        end

        S_STORE_WRITE: begin
            mem_write = 1;
            next_state = S_FETCH1;
        end

        //--------------------------------------------------
        // BRANCH
        //--------------------------------------------------
        S_BRANCH_ADDR: begin
            ALUSrcA = 2'b11;   // PC_base
            ALUSrcB = 2'b10;   // imm
            pc_source = 2'b00; // ALUResult

            case(funct3)
                3'b000: if (A==B) pc_write = 1;
                3'b001: if (A!=B) pc_write = 1;
                3'b100: if ($signed(A)<$signed(B)) pc_write = 1;
                3'b101: if ($signed(A)>=$signed(B)) pc_write = 1;
                3'b110: if (A < B) pc_write = 1;
                3'b111: if (A >= B) pc_write = 1;
            endcase

            next_state = S_FETCH1;
        end

        //--------------------------------------------------
        // JAL
        //--------------------------------------------------
        S_JAL_EXEC: begin
            ALUSrcA = 2'b11; // PC_base
            ALUSrcB = 2'b10; // imm

            pc_source = 2'b00; // ALUResult
            pc_write  = 1;

            next_state = S_JAL_WB;
        end

        S_JAL_WB: begin
            link_sel = 1;     // PC_base + 4
            reg_write = 1;
            next_state = S_FETCH1;
        end

        //--------------------------------------------------
        // JALR
        //--------------------------------------------------
        S_JALR_EXEC: begin
            ALUSrcA = 2'b00;
            ALUSrcB = 2'b10;
            next_state = S_JALR_ALIGN;
        end

        S_JALR_ALIGN: begin
            pc_source = 2'b11; // masked ALUResult
            pc_write  = 1;
            next_state = S_JALR_WB;
        end

        S_JALR_WB: begin
            link_sel = 1;
            reg_write = 1;
            next_state = S_FETCH1;
        end

        //--------------------------------------------------
        // MULDIV
        //--------------------------------------------------
        S_MULDIV_START: begin
            MD_start = 1;
            next_state = S_MULDIV_WAIT;
        end

        S_MULDIV_WAIT: begin
            if (ready)
                next_state = S_MULDIV_WB;
        end

        S_MULDIV_WB: begin
            is_mul_out = 1;
            alumd_out_write = 1;
            reg_write = 1;
            next_state = S_FETCH1;
        end

        endcase
    end
endmodule
