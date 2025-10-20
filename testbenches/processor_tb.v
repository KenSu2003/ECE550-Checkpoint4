// Testbench for the processor
`timescale 1ns/1ps

module processor_tb();
    // Declare signals
    reg clock;
    reg reset;
    wire imem_clock, dmem_clock, processor_clock, regfile_clock;
    
    // Instantiate the skeleton
    skeleton dut(
        .clock(clock),
        .reset(reset),
        .imem_clock(imem_clock),
        .dmem_clock(dmem_clock),
        .processor_clock(processor_clock),
        .regfile_clock(regfile_clock)
    );
    
    // Clock generation
    initial begin
        clock = 0;
        forever #10 clock = ~clock; // 50MHz clock (20ns period)
    end
    
    // Test sequence
    initial begin
        // Initialize signals
        reset = 1;
        $display("Simulation starting...");
        
        // Apply reset for a few clock cycles
        #50 reset = 0;
        $display("Reset released, starting program execution");
        
        // Monitor execution cycle by cycle for first 20 instructions
        repeat(20) begin
            #20; // Wait for a clock cycle
            $display("Time %t: PC=%d, Instr = %h", $time, dut.address_imem, dut.q_imem);
            if (dut.ctrl_writeEnable)
                $display("  Reg write: $%d = %d", dut.ctrl_writeReg, dut.data_writeReg);
            if (dut.wren)
                $display("  Mem write: MEM[%d] = %d", dut.address_dmem, dut.data);
        end
        
        // Run simulation for the rest of the program
        #200;
        
        // Print final execution state
        $display("\nFinal state:");
        $display("IMEM Address = %d", dut.address_imem);
        $display("Last instruction = %h", dut.q_imem);
        
        // Note: Cannot directly access internal register and memory values
        // Instead, we'll watch execution through observable signals
        $display("Using observable processor ports to verify operation");
        
        // Check some ALU operations by monitoring ctrl_writeEnable and data_writeReg
        $display("Last register write: write_enable=%b, reg=%d, value=%d",
                 dut.ctrl_writeEnable, dut.ctrl_writeReg, dut.data_writeReg);
        
        $display("Simulation finished");
        $finish;
    end
    
    // Generate VCD file for waveform viewing
    initial begin
        $dumpfile("processor.vcd");
        $dumpvars(0, processor_tb);
    end
endmodule
