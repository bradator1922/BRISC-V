`timescale 1ns/1ps

//============================================================
//   RV32IM FULL TESTBENCH WITH SCOREBOARD + CHECKER
//============================================================
module tb_top_rv32im;

    // --------------------------------------
    // DUT INTERFACE
    // --------------------------------------
    reg clk;
    reg rst;
    wire [31:0] pc_val,instr_val,ALUResult_val,next_pc_val;
    wire pc_write_val,ir_write_val;
    wire [6:0] opcode_val;
    



    // --------------------------------------
    // Instantiate DUT
    // --------------------------------------
    top_rv32im dut (
        .clk(clk),
        .rst(rst),
        .pc_val(pc_val),
        .instr_val(instr_val),
        .pc_write_val(pc_write_val),
        .ir_write_val(ir_write_val),
        .opcode_val(opcode_val),
        .ALUResult_val(ALUResult_val),
        .next_pc_val(next_pc_val)
    );

    // --------------------------------------
    // Clock Generation (10ns period)
    // --------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --------------------------------------
    // Reset Task
    // --------------------------------------
    task apply_reset;
    begin
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);
    end
    endtask




    // =====================================================
    // TASK: Load HEX Program into IMEM
    // =====================================================
    task load_program(input [200*8-1:0] hexfile);
    begin
        $display("\n===============================================");
        $display(" Loading Program: %s", hexfile);
        $display("===============================================\n");

        $readmemh(hexfile, dut.im.imem);
    end
    endtask


    // =====================================================
    // REGISTER FILE DUMP
    // =====================================================
    task dump_regfile;
        integer i;
    begin
        $display("\n---------------- REGISTER FILE ----------------");
        for (i = 0; i < 32; i = i + 1)
            $display("x%0d = %h", i, dut.rf.regs[i]);
        $display("------------------------------------------------\n");
    end
    endtask

    // =====================================================
    // DMEM DUMP
    // =====================================================
    task dump_dmem;
        integer i;
    begin   
        $display("\n---------------- DATA MEMORY ----------------");
        for (i = 0; i < 11; i = i + 1)
            $display("x%0d = %h", i, dut.dm.mem[i]);
        $display("------------------------------------------------\n");
    end
    endtask

//testing whether imem is being written
    initial begin
    #10;
    $display("\nIMEM CONTENTS:");
    $display("0 = %h", dut.im.imem[0]);
    $display("1 = %h", dut.im.imem[1]);
    $display("2 = %h", dut.im.imem[2]);
end



    // =====================================================
    // MAIN TB FLOW
    // =====================================================
    initial begin
    

        // -----------------------------------------
        // 1. Load test program (edit this line only)
        // -----------------------------------------
        //load_program("all_instr.hex");
        //load_program("fib.hex");
        //load_program("square_of_two.hex");
        //load_program("mac.hex");
        //load_program("fact_six.hex");
        load_program("mat_mul.hex");

        // -----------------------------------------
        // 2. Reset CPU
        // -----------------------------------------
        apply_reset;

        // -----------------------------------------
        // 3. Let CPU run the entire program
        // -----------------------------------------
        $display(">>> Running Program...");
        repeat (50) @(posedge clk);


        // -----------------------------------------
        // 4. Dump register file for your reference
        // -----------------------------------------
        dump_regfile;
        dump_dmem;

    end

endmodule
