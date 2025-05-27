// `timescale 1ns/1ps

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

    logic prio;
    initial begin
        prio = dut.prio;
    end

    integer test;
    logic [8 : 0]  pA_addr, pB_addr;
    logic [31 : 0] pA_data, pB_data, pA_data_old, pB_data_old;

    task automatic pA_write();
        // pA_wb_stb_i  = 1;
        pA_wb_addr_i = pA_addr;
        pA_wb_sel_i  = 4'hF;
        pA_wb_we_i   = 1;
        pA_wb_data_i = pA_data;
    endtask;

    task automatic pB_write();
        // pB_wb_stb_i  = 1;
        pB_wb_addr_i = pB_addr;
        pB_wb_sel_i  = 4'hF;
        pB_wb_we_i   = 1;
        pB_wb_data_i = pB_data;
    endtask;

    task automatic pA_read();
        pA_wb_addr_i = pA_addr;
        pA_wb_we_i   = 0;
    endtask;

    task automatic pB_read();
        pB_wb_addr_i = pB_addr;
        pB_wb_we_i   = 0;
    endtask;

    initial begin
        
        
        // Test Goes Here
        clk_i = 0;

        @(posedge clk_i);
        rst_n_i = 0;

        @(posedge clk_i);
        rst_n_i = 1;

        // pA_wb_stb_i  = 0;
        // pA_wb_addr_i = 0;
        // pA_wb_sel_i  = 0;
        // pA_wb_we_i   = 0;
        // pA_wb_data_i = 0;

        // pB_wb_stb_i  = 0;
        // pB_wb_addr_i = 0;
        // pB_wb_sel_i  = 0;
        // pB_wb_we_i   = 0;
        // pB_wb_data_i = 0;

        // @(posedge clk_i);

        // /* Write to both RAMs, no collision */
        // dport_write_no_col(69, 32'hCAFEBABE, 256, 32'hEBABEFAC); 

        // /* Read from both RAMs, no collision */
        // dport_read_no_col(69, 256);

        // /* Write to single RAM, collision */
        // dport_write_col(420, "poop", 420, "butt");

        // @(posedge clk_i);
        // @(posedge clk_i);
        // @(posedge clk_i);
        // @(posedge clk_i);
        // @(posedge clk_i);
  
        /* Replicate collision waveform from assignment */


        pA_wb_stb_i = 1;
        pB_wb_stb_i = 1;

        /* Tests 1 - 8 test both ports writing to lo_ram at the same time */
        pA_addr = 9'h0;
        pB_addr = 9'h1;
        
        /* ------------ TEST 1 ------------ */
        test = 1;

        pB_data_old = 32'h0;
        pB_data = 32'h89ABCDEF;

        pA_data_old = 32'h0;
        pA_data = 32'h01234567;
        
        pA_write();
        pB_write();
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pB_addr, pB_data); // Priority = Port B

        /* ------------ TEST 2 ------------ */
        test = 2;
        pB_data_old = pB_data;
        pB_data = pA_data;

        pB_write();
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pA_addr, pA_data);    // Priority = Port A
        verify_ram(test, pB_addr, pB_data_old);

        /* ------------ TEST 3 ------------ */
        test = 3;
        pA_data_old = pA_data;
        pA_data = pB_data_old;

        pA_write();
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pA_addr, pA_data_old);
        verify_ram(test, pB_addr, pB_data);    // Priority = Port B
        
        /* ------------ TEST 4 ------------ */
        test = 4;
        pB_data_old = pB_data;
        pB_data = pA_data_old;

        pB_write();
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pA_addr, pA_data);    // Priority = Port A
        verify_ram(test, pB_addr, pB_data_old);

        /* ------------ TEST 5 ------------ */
        test = 5;
        pA_data_old = pA_data;
        pA_data = pB_data_old;

        pA_write();
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pA_addr, pA_data_old);
        verify_ram(test, pB_addr, pB_data);    // Priority = Port B

        /* ------------ TEST 6 ------------ */
        test = 6;
        pB_data_old = pB_data;
        pB_data = pA_data_old;

        pB_write();
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pA_addr, pA_data);    // Priority = Port A
        verify_ram(test, pB_addr, pB_data_old);

        /* ------------ TEST 7 ------------ */
        test = 7;
        pA_data_old = pA_data;
        pA_data = pB_data_old;

        pA_write();
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pA_addr, pA_data_old);
        verify_ram(test, pB_addr, pB_data);    // Priority = Port B

        /* ------------ TEST 8 ------------ */
        test = 8;
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pA_addr, pA_data); // Priority = Port A

        @(posedge clk_i);

        /* Tests 9 - 16 test both ports writing to hi_ram at the same time */
        pA_addr = 9'h100;   // 100
        pB_addr = 9'h1FF; // 511
        
        /* ------------ TEST 9 ------------ */
        test = 9;
        pB_data_old = 32'h0;
        pB_data = 32'h89ABCDEF;

        pA_data_old = 32'h0;
        pA_data = 32'h01234567;
        
        pA_write();
        pB_write();
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pA_addr, pA_data); // Priority = Port A

        /* ------------ TEST 10 ------------ */
        test = 10;
        
        pA_data_old = pA_data;
        pA_data = pB_data;

        pA_write();
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pA_addr, pA_data_old);    
        verify_ram(test, pB_addr, pB_data); // Priority = Port B

        /* ------------ TEST 11 ------------ */
        test = 11;
        pB_data_old = pB_data;
        pB_data = pA_data_old;

        pB_write();
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pA_addr, pA_data); // Priority = Port A
        verify_ram(test, pB_addr, pB_data_old);    
        
        /* ------------ TEST 12 ------------ */
        test = 12;
        pA_data_old = pA_data;
        pA_data = pB_data_old;

        pA_write();
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pA_addr, pA_data_old);    
        verify_ram(test, pB_addr, pB_data); // Priority = Port B

        /* ------------ TEST 13 ------------ */
        test = 13;
        pB_data_old = pB_data;
        pB_data = pA_data_old;

        pB_write();
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pA_addr, pA_data); // Priority = Port A
        verify_ram(test, pB_addr, pB_data_old);    

        /* ------------ TEST 14 ------------ */
        test = 14;
        pA_data_old = pA_data;
        pA_data = pB_data_old;

        pA_write();
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pA_addr, pA_data_old);    
        verify_ram(test, pB_addr, pB_data); // Priority = Port B

        /* ------------ TEST 15 ------------ */
        test = 15;
        pB_data_old = pB_data;
        pB_data = pA_data_old;

        pB_write();
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pA_addr, pA_data); // Priority = Port A
        verify_ram(test, pB_addr, pB_data_old);    

        /* ------------ TEST 16 ------------ */
        test = 16;
        @(posedge clk_i);
        @(negedge clk_i);
        verify_ram(test, pB_addr, pB_data_old);

        @(posedge clk_i);

        pA_wb_stb_i = 0;
        pB_wb_stb_i = 0;

        @(posedge clk_i);
        
        pA_addr = 9'h0;
        pB_addr = 9'h1;

        /* ------------ TEST 17 ------------ */
        test = 17;
        pA_read();
        pB_read();

        pA_wb_stb_i = 1;
        pB_wb_stb_i = 1;
        @(posedge clk_i);
        @(negedge clk_i);
        verify_read(test, pB_addr, pB_wb_data_o); // Priority = Port B

        @(posedge clk_i)
        @(negedge clk_i);
        verify_read(test, pA_addr, pA_wb_data_o);
        


        $finish();
    end

    task automatic verify_ram(input integer test_no, [8 : 0]addr, [31 : 0]exp);
        logic [31 : 0] act;

        act = dut.lo_ram.RAM[addr[7 : 0]];
        if (addr > 255)
            act = dut.hi_ram.RAM[addr[7 : 0]];

        assert (act == exp) else
            $fatal(1, "Test %0d: Memory contents 0x%0h does not match expected data 0x%0h at address 0x%0h", test_no, act, exp, addr);
    endtask;

    task automatic verify_read(input integer test_no, [8 : 0]addr, [31 : 0]act);
        logic [31 : 0] exp;

        exp = dut.lo_ram.RAM[addr[7 : 0]];
        if (addr > 255)
            exp = dut.hi_ram.RAM[addr[7 : 0]];

        assert (act == exp) else
            $fatal(1, "Test %0d: Read data 0x%0h does not match memory contents 0x%0h at address 0x%0h", test_no, act, exp, addr);

    endtask;
endmodule
