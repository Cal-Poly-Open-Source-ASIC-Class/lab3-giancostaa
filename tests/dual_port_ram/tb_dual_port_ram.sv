`timescale 1ns/1ps

module tb_dual_port_ram;

    logic clk_i;
    logic rst_n_i;

    /* Port A Wishbone Signals */
    logic          pA_wb_stb_i;
    logic [8 : 0]  pA_wb_addr_i;
    logic [3 : 0]  pA_wb_sel_i;
    logic          pA_wb_we_i;
    logic [31 : 0] pA_wb_data_i;

    logic          pA_wb_stall_o;
    logic          pA_wb_ack_o;
    logic [31 : 0] pA_wb_data_o;
    
    /* Port B Wishbone Signals */
    logic          pB_wb_stb_i;
    logic [8 : 0]  pB_wb_addr_i;
    logic [3 : 0]  pB_wb_sel_i;
    logic          pB_wb_we_i;
    logic [31 : 0] pB_wb_data_i;

    logic          pB_wb_stall_o;
    logic          pB_wb_ack_o;
    logic [31 : 0] pB_wb_data_o;

    dual_port_ram dut(
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),

        .pA_wb_stb_i  (pA_wb_stb_i),
        .pA_wb_addr_i (pA_wb_addr_i),
        .pA_wb_sel_i  (pA_wb_sel_i),
        .pA_wb_we_i   (pA_wb_we_i),
        .pA_wb_data_i (pA_wb_data_i),
        .pA_wb_stall_o(pA_wb_stall_o),
        .pA_wb_ack_o  (pA_wb_ack_o),
        .pA_wb_data_o (pA_wb_data_o),

        .pB_wb_stb_i  (pB_wb_stb_i),
        .pB_wb_addr_i (pB_wb_addr_i),
        .pB_wb_sel_i  (pB_wb_sel_i),
        .pB_wb_we_i   (pB_wb_we_i),
        .pB_wb_data_i (pB_wb_data_i),
        .pB_wb_stall_o(pB_wb_stall_o),
        .pB_wb_ack_o  (pB_wb_ack_o),
        .pB_wb_data_o (pB_wb_data_o)
    );


    // Sample to drive clock
    localparam CLK_PERIOD = 20;
    always begin
        #(CLK_PERIOD/2) 
        clk_i<=~clk_i;
    end

    // Necessary to create Waveform
    initial begin
        // Name as needed
        $dumpfile("tb_dual_port_ram.vcd");
        $dumpvars(0);
    end

    task automatic pA_write(input [8 : 0] pA_addr, [31 : 0]pA_data);
        // pA_wb_stb_i  = 1;
        pA_wb_addr_i = pA_addr;
        pA_wb_sel_i  = 4'hF;
        pA_wb_we_i   = 1;
        pA_wb_data_i = pA_data;
    endtask;

    task automatic pB_write(input [8 : 0] pB_addr, [31 : 0]pB_data);
        // pB_wb_stb_i  = 1;
        pB_wb_addr_i = pB_addr;
        pB_wb_sel_i  = 4'hF;
        pB_wb_we_i   = 1;
        pB_wb_data_i = pB_data;
    endtask;

    task automatic pA_read(input [8 : 0] pA_addr);
        // pA_wb_stb_i  = 1;
        pA_wb_addr_i = pA_addr;
        pA_wb_we_i   = 0;
    endtask;

    task automatic pB_read(input [8 : 0] pB_addr);
        // pB_wb_stb_i  = 1;
        pB_wb_addr_i = pB_addr;
        pB_wb_we_i   = 0;
    endtask;


    task automatic dport_write_no_col(input logic [8 : 0] pA_addr, logic [31 : 0] pA_data, logic [8 : 0] pB_addr, logic [31 : 0] pB_data);
        logic [31 : 0] pA_RAM_data, pB_RAM_data;
        pA_wb_stb_i  = 1;
        pA_wb_addr_i = pA_addr;
        pA_wb_sel_i  = 4'hF;
        pA_wb_we_i   = 1;
        pA_wb_data_i = pA_data;

        pB_wb_stb_i  = 1;
        pB_wb_addr_i = pB_addr;
        pB_wb_sel_i  = 4'hF;
        pB_wb_we_i   = 1;
        pB_wb_data_i = pB_data;

        @(posedge clk_i);

        assert(dut.collision == 0) else
            $fatal(1, "Unexpected write collision");
            
        pA_wb_stb_i = 0;
        pB_wb_stb_i = 0;

        @(posedge clk_i);

        if (pA_addr < 256) 
            pA_RAM_data = dut.lo_ram.RAM[pA_addr[7 : 0]];
        else
            pA_RAM_data = dut.hi_ram.RAM[pA_addr[7 : 0]];

        assert (pA_data == pA_RAM_data) else
            $fatal(1, "RAM data %0h does not match requested write %0h at address %0d", pA_data, pA_RAM_data, pA_addr);

        
        if (pB_addr < 256) 
            pB_RAM_data = dut.lo_ram.RAM[pB_addr[7 : 0]];
        else
            pB_RAM_data = dut.hi_ram.RAM[pB_addr[7 : 0]];

        assert (pB_data == pB_RAM_data) else
            $fatal(1, "RAM data %0d does not match equested write %0h at address %0d", pB_data, pB_RAM_data, pB_addr);
    
    endtask;

    task automatic dport_write_col(input logic [8 : 0] pA_addr, logic [31 : 0] pA_data, logic [8 : 0] pB_addr, logic [31 : 0] pB_data);
        logic [31 : 0] pA_RAM_data, pB_RAM_data;
        pA_wb_stb_i  = 1;
        pA_wb_addr_i = pA_addr;
        pA_wb_sel_i  = 4'hF;
        pA_wb_we_i   = 1;
        pA_wb_data_i = pA_data;

        pB_wb_stb_i  = 1;
        pB_wb_addr_i = pB_addr;
        pB_wb_sel_i  = 4'hF;
        pB_wb_we_i   = 1;
        pB_wb_data_i = pB_data;

        @(posedge clk_i);

        assert(dut.collision == 1) else
            $fatal(1, "Expected write collision");
            
        pA_wb_stb_i = 0;
        pB_wb_stb_i = 0;

        @(posedge clk_i);

        if (pA_addr < 256) 
            pA_RAM_data = dut.lo_ram.RAM[pA_addr[7 : 0]];
        else
            pA_RAM_data = dut.hi_ram.RAM[pA_addr[7 : 0]];

        // assert (pA_data == pA_RAM_data) else
        //     $fatal(1, "RAM data %0h does not match requested write %0h at address %0d", pA_data, pA_RAM_data, pA_addr);

        
        if (pB_addr < 256) 
            pB_RAM_data = dut.lo_ram.RAM[pB_addr[7 : 0]];
        else
            pB_RAM_data = dut.hi_ram.RAM[pB_addr[7 : 0]];

        // assert (pB_data == pB_RAM_data) else
        //     $fatal(1, "RAM data %0d does not match equested write %0h at address %0d", pB_data, pB_RAM_data, pB_addr);
    
    endtask;

    task automatic dport_read_no_col(input logic [8 : 0] pA_addr, [8 : 0] pB_addr);
        logic [31 : 0] pA_RAM_data, pB_RAM_data;

        pA_wb_stb_i  = 1;
        pA_wb_addr_i = pA_addr;
        pA_wb_we_i   = 0;

        pB_wb_stb_i  = 1;
        pB_wb_addr_i = pB_addr;
        pB_wb_we_i   = 0;

        @(posedge clk_i);

        assert(dut.collision == 0) else
            $fatal(1, "Unexpected read collision");

        pA_wb_stb_i = 0;
        pB_wb_stb_i = 0;

        @(posedge clk_i);

        if (pA_addr < 256) 
            pA_RAM_data = dut.lo_ram.RAM[pA_addr[7 : 0]];
        else
            pA_RAM_data = dut.hi_ram.RAM[pA_addr[7 : 0]];

        assert (pA_wb_data_o == pA_RAM_data) else
            $fatal(1, "pA output %0d does not match RAM data %0h at address %0d", pA_wb_data_o, pA_RAM_data, pA_addr);

        
        if (pB_addr < 256) 
            pB_RAM_data = dut.lo_ram.RAM[pB_addr[7 : 0]];
        else
            pB_RAM_data = dut.hi_ram.RAM[pB_addr[7 : 0]];

        assert (pB_wb_data_o == pB_RAM_data) else
            $fatal(1, "pB output %0d does not match RAM data %0h at address %0d", pB_wb_data_o, pB_RAM_data, pB_addr);


    endtask;

    task automatic dport_read_col(input logic [8 : 0] pA_addr, [8 : 0] pB_addr);
        logic [31 : 0] pA_RAM_data, pB_RAM_data;

        pA_wb_stb_i  = 1;
        pA_wb_addr_i = pA_addr;
        pA_wb_we_i   = 0;

        pB_wb_stb_i  = 1;
        pB_wb_addr_i = pB_addr;
        pB_wb_we_i   = 0;

        @(posedge clk_i);

        assert(dut.collision == 1) else
            $fatal(1, "Expected read collision");

        pA_wb_stb_i = 0;
        pB_wb_stb_i = 0;

        @(posedge clk_i);

        if (pA_addr < 256) 
            pA_RAM_data = dut.lo_ram.RAM[pA_addr[7 : 0]];
        else
            pA_RAM_data = dut.hi_ram.RAM[pA_addr[7 : 0]];

        // assert (pA_wb_data_o == pA_RAM_data) else
        //     $fatal(1, "pA output %0d does not match RAM data %0h at address %0d", pA_wb_data_o, pA_RAM_data, pA_addr);

        
        if (pB_addr < 256) 
            pB_RAM_data = dut.lo_ram.RAM[pB_addr[7 : 0]];
        else
            pB_RAM_data = dut.hi_ram.RAM[pB_addr[7 : 0]];

        // assert (pB_wb_data_o == pB_RAM_data) else
        //     $fatal(1, "pB output %0d does not match RAM data %0h at address %0d", pB_wb_data_o, pB_RAM_data, pB_addr);


    endtask;

    task automatic pA_start();
        
    endtask;

    logic prio;
    initial begin
        prio = dut.prio;
    end

    initial begin
        // Test Goes Here
        clk_i = 0;

        @(posedge clk_i);
        rst_n_i = 0;

        @(posedge clk_i);
        rst_n_i = 1;

        pA_wb_stb_i  = 0;
        pA_wb_addr_i = 0;
        pA_wb_sel_i  = 0;
        pA_wb_we_i   = 0;
        pA_wb_data_i = 0;

        pB_wb_stb_i  = 0;
        pB_wb_addr_i = 0;
        pB_wb_sel_i  = 0;
        pB_wb_we_i   = 0;
        pB_wb_data_i = 0;

        @(posedge clk_i);

        /* Write to both RAMs, no collision */
        dport_write_no_col(69, 32'hCAFEBABE, 256, 32'hEBABEFAC); 

        /* Read from both RAMs, no collision */
        dport_read_no_col(69, 256);

        /* Write to single RAM, collision */
        dport_write_col(420, "poop", 420, "butt");

        @(posedge clk_i);
        @(posedge clk_i);
        @(posedge clk_i);
        @(posedge clk_i);
        @(posedge clk_i);
  
        /* Replicate collision waveform from assignment */
        pA_wb_stb_i = 1;
        pB_wb_stb_i = 1;
        pA_write(9'h0, 32'h01234567);
        pB_write(9'h8, 32'h89ABCDEF);
        @(posedge clk_i);
        pB_write(9'hC, 32'h89ABCDEF);
        @(posedge clk_i);
        pA_write(9'h4, 32'h01234567);
        @(posedge clk_i);
        pB_write(9'h10, 32'h89ABCDEF);
        @(posedge clk_i);
        pA_write(9'h8, 32'h01234567);
        @(posedge clk_i);
        pB_write(9'h14, 32'h89ABCDEF);
        @(posedge clk_i);
        pA_write(9'hc, 32'h01234567);
    
        @(posedge clk_i);
        $finish();
    end

endmodule
