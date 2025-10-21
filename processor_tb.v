// Testbench for the processor with automated checking (Quartus-friendly)
// Replace your existing processor_tb.v with this file.
`timescale 1ns/1ps

module processor_tb();
    // Top-level signals
    reg clock;
    reg reset;
    wire imem_clock, dmem_clock, processor_clock, regfile_clock;

    // Instance of the skeleton containing your processor
    skeleton dut(
        .clock(clock),
        .reset(reset),
        .imem_clock(imem_clock),
        .dmem_clock(dmem_clock),
        .processor_clock(processor_clock),
        .regfile_clock(regfile_clock)
    );

    // --------------------------
    // Module-scope declarations (Quartus requires these at module scope)
    // --------------------------
    // TB shadow register file and flags
    reg [31:0] tb_regs [0:31];
    reg tb_reg_written [0:31];

    // DMEM shadow
    localparam DMEM_SHADOW_SIZE = 2048;
    reg [31:0] tb_mem [0:DMEM_SHADOW_SIZE-1];
    reg tb_mem_written [0:DMEM_SHADOW_SIZE-1];

    // Expected arrays (module scope)
    reg [31:0] expected_reg [0:31];
    reg [31:0] expected_mem_arr [0:DMEM_SHADOW_SIZE-1];

    // Integers and small arrays at module scope
    integer i;
    integer idx;
    integer fails;

    // Address list used by run_checks; declared at module scope
    integer addr_list [0:7];

    // --------------------------
    // Clock generation (50 MHz -> 20 ns period)
    // --------------------------
    initial begin
        clock = 0;
        forever #10 clock = ~clock;
    end

    // --------------------------
    // Initialize TB shadows and expected placeholders
    // --------------------------
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            tb_regs[i] = 32'h00000000;
            tb_reg_written[i] = 1'b0;
            expected_reg[i] = 32'h00000000;
        end
        for (i = 0; i < DMEM_SHADOW_SIZE; i = i + 1) begin
            tb_mem[i] = 32'hDEADBEEF;
            tb_mem_written[i] = 1'b0;
            expected_mem_arr[i] = 32'h00000000;
        end

        // default address list values (will be overwritten if needed)
        addr_list[0] = 99;
        addr_list[1] = 100;
        addr_list[2] = 101;
        addr_list[3] = 102;
        addr_list[4] = 103;
        addr_list[5] = 105;
        addr_list[6] = 107;
        addr_list[7] = 111;
    end

    // --------------------------
    // Capture DUT observable writes (synchronous)
    // --------------------------
    always @(posedge clock) begin
        // Register writes
        if (dut.my_processor.ctrl_writeEnable) begin
            tb_regs[dut.my_processor.ctrl_writeReg] <= dut.my_processor.data_writeReg;
            tb_reg_written[dut.my_processor.ctrl_writeReg] <= 1'b1;
            $display("[TB][%0t] Reg write observed: r%0d <= 0x%08h",
                     $time, dut.my_processor.ctrl_writeReg, dut.my_processor.data_writeReg);
        end

        // Dmem writes
        if (dut.my_processor.wren) begin
            if (dut.my_processor.address_dmem < DMEM_SHADOW_SIZE) begin
                tb_mem[dut.my_processor.address_dmem] <= dut.my_processor.data;
                tb_mem_written[dut.my_processor.address_dmem] <= 1'b1;
            end
            $display("[TB][%0t] Dmem write observed: MEM[%0d] <= 0x%08h",
                     $time, dut.my_processor.address_dmem, dut.my_processor.data);
        end
    end

    // --------------------------
    // Test driver
    // --------------------------
    initial begin
        // reset and run
        reset = 1;
        $display("Simulation starting...");

        #50 reset = 0;
        $display("Reset released, starting program execution");

        // quick monitor
        repeat (50) begin
            #20;
            $display("Time %t: PC=%0d Instr=%h", $time, dut.my_processor.address_imem, dut.my_processor.q_imem);
            if (dut.my_processor.ctrl_writeEnable)
                $display("  Write observed: REG r%0d <= 0x%08h", dut.my_processor.ctrl_writeReg, dut.my_processor.data_writeReg);
            if (dut.my_processor.wren)
                $display("  Mem write observed: MEM[%0d] <= 0x%08h", dut.my_processor.address_dmem, dut.my_processor.data);
        end

        // allow rest of program to run
        #4000;

        // --- Set expected values for the test you ran (extreme_test.s)
        // (If you run a different test, update these expected values accordingly.)
        for (i = 0; i < 32; i = i + 1) expected_reg[i] = 32'h00000000;
        for (i = 0; i < DMEM_SHADOW_SIZE; i = i + 1) expected_mem_arr[i] = 32'h00000000;

        // Registers from the observed extreme_test.s run
        expected_reg[1]  = 32'h00000007;
        expected_reg[2]  = 32'h00000015;
        expected_reg[3]  = 32'hFFFFFFFB;
        expected_reg[4]  = 32'h00000000;
        expected_reg[5]  = 32'h00000064;
        expected_reg[6]  = 32'h00000014;
        expected_reg[7]  = 32'h00000014;
        expected_reg[8]  = 32'h00000015;
        expected_reg[9]  = 32'h0000000F;
        expected_reg[10] = 32'h00000004;
        expected_reg[11] = 32'hFFFFFFFC;
        expected_reg[12] = 32'h00000001;
        expected_reg[13] = 32'h00000010;

        // Memory expectations (word addresses)
        expected_mem_arr[99]  = 32'h00000007;
        expected_mem_arr[100] = 32'h00000007;
        expected_mem_arr[101] = 32'h00000014;
        expected_mem_arr[102] = 32'h0000000F;
        expected_mem_arr[103] = 32'h00000014;
        expected_mem_arr[105] = 32'hFFFFFFFB;
        expected_mem_arr[107] = 32'h00000015;
        expected_mem_arr[111] = 32'h000003E7;

        $display("\n--- Running automated checks ---");
        run_checks();

        $display("Simulation finished");
        $finish;
    end

    // --------------------------
    // Waveform dump
    // --------------------------
    initial begin
        $dumpfile("processor.vcd");
        $dumpvars(0, processor_tb);
    end

    // --------------------------
    // run_checks task (no declarations inside)
    // --------------------------
    task run_checks();
        begin
            fails = 0;
            $display("Checking registers 1..13 and selected memory locations...");

            // Check registers 1..13
            for (i = 1; i <= 13; i = i + 1) begin
                if (!tb_reg_written[i]) begin
                    $display("FAIL: r%0d was never observed written (observed value 0x%08h)", i, tb_regs[i]);
                    fails = fails + 1;
                end
                else if (tb_regs[i] !== expected_reg[i]) begin
                    $display("FAIL: r%0d expected 0x%08h observed 0x%08h", i, expected_reg[i], tb_regs[i]);
                    fails = fails + 1;
                end else begin
                    $display("PASS: r%0d == 0x%08h", i, tb_regs[i]);
                end
            end

            // Check the expected memory addresses
            for (idx = 0; idx < 8; idx = idx + 1) begin
                i = addr_list[idx];
                if (!tb_mem_written[i]) begin
                    $display("FAIL: MEM[%0d] was never written (observed 0x%08h)", i, tb_mem[i]);
                    fails = fails + 1;
                end
                else if (tb_mem[i] !== expected_mem_arr[i]) begin
                    $display("FAIL: MEM[%0d] expected 0x%08h observed 0x%08h", i, expected_mem_arr[i], tb_mem[i]);
                    fails = fails + 1;
                end else begin
                    $display("PASS: MEM[%0d] == 0x%08h", i, tb_mem[i]);
                end
            end

            // Summary
            if (fails == 0) $display("\nALL CHECKS PASSED!");
            else $display("\nCHECKS FAILED: %0d mismatches", fails);
        end
    endtask

endmodule
