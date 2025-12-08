// © 2025 bradator1922 (Bharath). All rights reserved.
// Provided for learning and modification only.
// Reuse or submission of this architecture, or any substantially similar derivative, is strictly prohibited without written permission.

module mult_div(clk,rst,start,isMulDiv,A,B,funct3,funct7,MDResult,ready,busy,div_by_zero);

    input clk,rst,start,isMulDiv;
    input [31:0] A,B;
    input [2:0]  funct3;
    input [6:0]  funct7;
    output reg [31:0] MDResult;
    output reg ready,busy;
    output wire div_by_zero;

    // RV32M instruction decode
    wire dMUL      = (funct3 == 3'b000);
    wire dMULH     = (funct3 == 3'b001);
    wire dMULHSU   = (funct3 == 3'b010);
    wire dMULHU    = (funct3 == 3'b011);
    wire dDIV      = (funct3 == 3'b100);
    wire dDIVU     = (funct3 == 3'b101);
    wire dREM      = (funct3 == 3'b110);
    wire dREMU     = (funct3 == 3'b111);

    wire want_mul = dMUL | dMULH | dMULHSU | dMULHU;
    wire want_div = dDIV | dDIVU | dREM | dREMU;

    // FSM for coordinating MUL/DIV
      localparam S_IDLE = 2'd0,
               S_WAIT = 2'd1,
               S_DONE = 2'd2;

    reg [1:0] st, nst;


    // Registered start pulse for MUL/DIV
    reg start_mul_r, start_div_r;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            start_mul_r <= 0;
            start_div_r <= 0;
        end else begin
            start_mul_r <= (st == S_IDLE) && start && isMulDiv && want_mul;
            start_div_r <= (st == S_IDLE) && start && isMulDiv && want_div;
        end
    end

    // Operation mode registers
    reg opMUL, opMULH, opMULHSU, opMULHU;
    reg opDIV, opDIVU, opREM, opREMU;
    reg signed_a_l, signed_b_l;

    wire [63:0] prod64;
    wire mul_ready;
    wire mul_busy;

    folded_mult32 U_MUL(.clk(clk),.rst(rst),.start(start_mul_r),.A(A),.B(B),.signed_a(signed_a_l),.signed_b(signed_b_l),.P(prod64),.ready(mul_ready),.busy(mul_busy));

//divider
    wire [31:0] div_Q, div_R;
    wire div_ready;
    wire div_busy_i;
    wire div_dbz;

    radix4_div32 U_DIV(.clk(clk),.rst(rst),.start(start_div_r),.dividend(A),.divisor(B),.is_signed(opDIV | opREM),.Q(div_Q),.R(div_R),.ready(div_ready),.busy(div_busy_i),.div_by_zero(div_dbz));

    assign div_by_zero = div_dbz;

    //--------------------------------------------
    // FSM NEXT STATE
    //--------------------------------------------
    always @(*) begin
        case (st)
            S_IDLE: nst = (start && isMulDiv) ? S_WAIT : S_IDLE;

            S_WAIT: begin
                if ((want_mul && mul_ready) || (want_div && div_ready))
                    nst = S_DONE;
                else
                    nst = S_WAIT;
            end

            S_DONE: nst = S_IDLE;

            default: nst = S_IDLE;
        endcase
    end

    //--------------------------------------------
    // FSM SEQUENTIAL + OUTPUT LOGIC
    //--------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            st <= S_IDLE;
            ready <= 0;
            busy  <= 0;
            MDResult <= 0;

            opMUL <= 0; opMULH <= 0; opMULHSU <= 0; opMULHU <= 0;
            opDIV <= 0; opDIVU <= 0; opREM <= 0; opREMU <= 0;

            signed_a_l <= 0;
            signed_b_l <= 0;
        end
        else begin
            st <= nst;
            ready <= 0;

            case (st)

                //------------------------------------------------
                // IDLE STATE
                //------------------------------------------------
                S_IDLE: begin
                    busy <= 0;
                    if (start && isMulDiv) begin
                        // latch operation type
                        opMUL    <= dMUL;
                        opMULH   <= dMULH;
                        opMULHSU <= dMULHSU;
                        opMULHU  <= dMULHU;
                        opDIV    <= dDIV;
                        opDIVU   <= dDIVU;
                        opREM    <= dREM;
                        opREMU   <= dREMU;

                        signed_a_l <= (dMUL | dMULH | dMULHSU);
                        signed_b_l <= (dMUL | dMULH);

                        busy <= 1;
                    end
                    else begin
                        opMUL <= 0; opMULH <= 0; opMULHSU <= 0; opMULHU <= 0;
                        opDIV <= 0; opDIVU <= 0; opREM <= 0; opREMU <= 0;
                    end
                end

                //------------------------------------------------
                // WAIT STATE
                //------------------------------------------------
                S_WAIT: begin
                    busy <= 1;
                end

                //------------------------------------------------
                // DONE STATE
                //------------------------------------------------
                S_DONE: begin
                    busy  <= 0;
                    ready <= 1;

                    // SELECT CORRECT OUTPUT
                    if (opMUL)         MDResult <= prod64[31:0];
                    else if (opMULH)   MDResult <= prod64[63:32];
                    else if (opMULHSU) MDResult <= prod64[63:32];
                    else if (opMULHU)  MDResult <= prod64[63:32];
                    else if (opDIV | opDIVU) MDResult <= div_Q;
                    else if (opREM | opREMU) MDResult <= div_R;

                    // clear
                    opMUL <= 0; opMULH <= 0; opMULHSU <= 0; opMULHU <= 0;
                    opDIV <= 0; opDIVU <= 0; opREM <= 0; opREMU <= 0;
                    signed_a_l <= 0; signed_b_l <= 0;
                end

            endcase
        end
    end

endmodule


// FOLDED MULTIPLIER (4-cycle 16-bit partial products)
module folded_mult32(clk,rst,start,A,B,signed_a,signed_b,P,ready,busy);

    input clk,rst,start;
    input [31:0] A,B;
    input signed_a,signed_b;
    output reg [63:0] P;
    output reg ready,busy;

    localparam S_IDLE=2'd0, S_CALC=2'd1, S_DONE=2'd2;

    reg [1:0] state;
    reg [1:0] step;

    reg [63:0] acc;

    reg [15:0] a_low, a_high, b_low, b_high;

    wire a_neg = signed_a & A[31];
    wire b_neg = signed_b & B[31];

    wire [31:0] A_mag = a_neg ? (~A+1) : A;
    wire [31:0] B_mag = b_neg ? (~B+1) : B;
    wire sign_res = a_neg ^ b_neg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            ready <= 0;
            busy <= 0;
            acc <= 0;
            step <= 0;
            P <= 0;
        end
        else begin

            case (state)

                S_IDLE: begin
                    ready <= 0;
                    busy <= 0;
                    if (start) begin
                        a_low  <= A_mag[15:0];
                        a_high <= A_mag[31:16];
                        b_low  <= B_mag[15:0];
                        b_high <= B_mag[31:16];
                        acc <= 0;
                        busy <= 1;
                        step <= 0;
                        state <= S_CALC;
                    end
                end

                S_CALC: begin
                    case (step)
                        0: acc <= acc + {32'd0, a_low  * b_low};
                        1: acc <= acc + ({32'd0, a_low  * b_high} << 16);
                        2: acc <= acc + ({32'd0, a_high * b_low } << 16);
                        3: acc <= acc + ({32'd0, a_high * b_high} << 32);
                    endcase

                    step <= step + 1;

                    if (step == 3)
                        state <= S_DONE;
                end

                S_DONE: begin
                    P <= sign_res ? (~acc + 1) : acc;
                    ready <= 1;
                    busy <= 0;
                    state <= S_IDLE;
                end

            endcase
        end
    end
endmodule



// 32-bit Divider for RV32M (DIV/DIVU/REM/REMU)
module radix4_div32 (clk,rst,start,dividend,divisor,is_signed,Q,R,ready,busy,div_by_zero);

    input clk,rst,start;
    input wire [31:0] dividend,divisor;
    input is_signed;     // 1: DIV/REM, 0: DIVU/REMU
    output reg  [31:0] Q,R;
    output reg         ready,busy,div_by_zero;

    // FSM states
    localparam S_IDLE=0, S_PREP=1, S_ITER=2, S_DONE=3;
    reg [1:0] state;

    reg [5:0]  bit_cnt;
    reg [63:0] rem;
    reg [31:0] div_u;
    reg [31:0] quo_u;

    // Signed controls
    reg signA, signB, signQ, signR;
    reg [31:0] A_mag, B_mag;

    // MOVED OUTSIDE (ModelSim requires this)
    reg [63:0] rem_shift;
    reg [31:0] quo_next;

    // Signed overflow special case
    wire is_div_overflow =
        is_signed &&
        (dividend == 32'h8000_0000) &&
        (divisor  == 32'hFFFF_FFFF);

    //=====================================================
    // FSM
    //=====================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= S_IDLE;
            ready      <= 0;
            busy       <= 0;
            div_by_zero<= 0;
            Q          <= 0;
            R          <= 0;
            rem        <= 0;
            div_u      <= 0;
            quo_u      <= 0;
            bit_cnt    <= 0;
            signA      <= 0;
            signB      <= 0;
            signQ      <= 0;
            signR      <= 0;
            A_mag      <= 0;
            B_mag      <= 0;
        end else begin
            case (state)

                //=====================================================
                // IDLE
                //=====================================================
                S_IDLE: begin
                    ready       <= 0;
                    busy        <= 0;
                    div_by_zero <= 0;

                    if (start) begin

                        // Divide-by-zero
                        if (divisor == 0) begin
                            div_by_zero <= 1;
                            Q <= 32'hFFFF_FFFF;
                            R <= dividend;
                            ready <= 1;
                            state <= S_IDLE;
                        end

                        // Signed overflow
                        else if (is_div_overflow) begin
                            Q <= 32'h8000_0000;
                            R <= 0;
                            ready <= 1;
                            state <= S_IDLE;
                        end

                        else begin
                            busy <= 1;

                            if (is_signed) begin
                                signA <= dividend[31];
                                signB <= divisor[31];
                            end else begin
                                signA <= 0;
                                signB <= 0;
                            end

                            A_mag <= (is_signed && dividend[31]) ? (~dividend + 1) : dividend;
                            B_mag <= (is_signed && divisor[31])  ? (~divisor + 1)  : divisor;

                            state <= S_PREP;
                        end
                    end
                end

                //=====================================================
                // PREP
                //=====================================================
                S_PREP: begin
                    rem     <= {32'd0, A_mag};
                    div_u   <= B_mag;
                    quo_u   <= 0;
                    bit_cnt <= 32;

                    signQ   <= (is_signed) ? (signA ^ signB) : 0;
                    signR   <= (is_signed) ? signA : 0;

                    state   <= S_ITER;
                end

                //=====================================================
                // ITER (restoring division)
                //=====================================================
                S_ITER: begin
                    // shift left (bring next bit)
                    rem_shift = {rem[62:0], 1'b0};

                    if (rem_shift[63:32] >= div_u) begin
                        rem      <= {rem_shift[63:32] - div_u, rem_shift[31:0]};
                        quo_next = {quo_u[30:0], 1'b1};
                    end else begin
                        rem      <= rem_shift;
                        quo_next = {quo_u[30:0], 1'b0};
                    end

                    quo_u   <= quo_next;
                    bit_cnt <= bit_cnt - 1;

                    if (bit_cnt == 1)
                        state <= S_DONE;
                end

                //=====================================================
                // DONE
                //=====================================================
                S_DONE: begin
                    busy  <= 0;
                    ready <= 1;

                    Q <= signQ ? (~quo_u + 1) : quo_u;
                    R <= signR ? (~rem[63:32] + 1) : rem[63:32];

                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule


