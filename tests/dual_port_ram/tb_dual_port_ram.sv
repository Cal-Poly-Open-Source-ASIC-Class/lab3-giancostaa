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

    typedef enum logic [1 : 0] 
    {
        PORT_B  = 2'h0,
        PORT_A  = 2'h1,
        PORT_AB = 2'h2
    } port_t;

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

    integer test_no;
    logic [8 : 0]  pA_addr, pB_addr;
    logic [31 : 0] pA_data, pB_data, pA_data_exp, pB_data_exp;

    task automatic pA_write();
        pA_wb_addr_i = pA_addr;
        pA_wb_sel_i  = 4'hF;
        pA_wb_we_i   = 1;
        pA_wb_data_i = pA_data;
    endtask;

    task automatic pB_write();
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

    port_t prio;

    initial begin
        // Test Goes Here
        clk_i = 0;

        @(posedge clk_i);
        rst_n_i = 0;

        @(posedge clk_i);
        rst_n_i = 1;

        pA_wb_stb_i = 1;
        pB_wb_stb_i = 1;
        
        /* ------------ TEST 1 ------------ */
        /* These tests test stalling and delegation by writing to the same memory macro.
        Though, when jumping from lo_ram to hi_ram there will be a transaction with no collision */

        test_no = 1;

        pA_data = 32'h1FF;
        pB_data = 32'h0;
        
        for (int i = 0; i < 511; i++) begin
            pA_addr = i;
            pB_addr = i + 1;

            prio = port_t'(dut.prio);
            write_mem(PORT_AB);

            if (i == 255 || i == 511) begin
                assert(dut.collision == 0) 
                    else $fatal(1, "Test %0d: Unexpected collision", test_no);
                        
            end

            if (prio == PORT_A) begin
                verify_ram(PORT_A, pA_addr, pA_data);
                
                @(posedge clk_i);
                @(negedge clk_i);
                verify_ram(PORT_B, pB_addr, pB_data);                
            end else if (prio == PORT_B) begin
                verify_ram(PORT_B, pB_addr, pB_data);

                @(posedge clk_i);
                @(negedge clk_i);
                verify_ram(PORT_A, pA_addr, pA_data);                
            end

            pA_data--;
            pB_data++;

            $display("TEST %0d PASSED", test_no);
            test_no++;
        end

        pA_wb_we_i = 0;
        pB_wb_we_i = 0;

        @(posedge clk_i);
        @(negedge clk_i);
        
        /* ------------ TEST 2 ------------ */
        /* These tests test stalling and delegation by reading from the same memory macro.
        Though, when jumping from lo_ram to hi_ram there will be a transaction with no collision */

        pA_data_exp = 32'h1FF;
        pB_data_exp = 32'h1FE;
       
        for (int i = 0; i < 510; i++) begin
            pA_addr = i;
            pB_addr = i + 1;

            prio = port_t'(dut.prio);
            read_mem(PORT_AB);

            if (i == 255 || i == 511) begin
                assert(dut.collision == 0) 
                    else $fatal(1, "Test %0d: Unexpected collision", test_no);
            end

            if (prio == PORT_A) begin
                verify_read(PORT_A, pA_data_exp);
                
                @(negedge clk_i);
                verify_read(PORT_B, pB_data_exp);                
            end else if (prio == PORT_B) begin
                verify_read(PORT_B, pB_data_exp);

                @(negedge clk_i);
                verify_read(PORT_A, pA_data_exp);                
            end

            pA_data_exp--;
            pB_data_exp--;

            $display("TEST %0d PASSED", test_no);
            test_no++;
        end
        
        $finish();
    end

    task static write_mem(input port_t port);
        if (port == PORT_AB) begin
            pA_write();
            pB_write();
        end else if (port == PORT_A) 
            pA_write();
        else
            pB_write();
        
        @(posedge clk_i);
        @(negedge clk_i);

        if (port == PORT_AB) begin
            assert(pA_wb_ack_o || pB_wb_ack_o)
                else $fatal(1, "Error: Neither Port acking on a collision");
        end else if (port == PORT_A) begin
            assert(!pB_wb_ack_o) 
                else $fatal(1, "Error: Port B should not ack on a Port A write");
        end else
            assert(!pA_wb_ack_o)
                else $fatal(1, "Error: Port A should not ack on a Port B write");

    endtask;

    task static read_mem(input port_t port);
        if (port == PORT_AB) begin
            pA_read();
            pB_read();
        end else if (port == PORT_A) 
            pA_read();
        else
            pB_read();
        
        @(posedge clk_i);
        @(negedge clk_i);

    endtask;
    

    task automatic verify_ram(input port_t port, [8 : 0]addr, [31 : 0]exp);
        logic [31 : 0] act;

        act = dut.lo_ram.RAM[addr[7 : 0]];
        if (addr > 255)
            act = dut.hi_ram.RAM[addr[7 : 0]];

        assert (act == exp) else
            $fatal(1, "Test %0d: Memory contents 0x%0h does not match expected Port %c data 0x%0h at address 0x%0h", test_no, act, port_t'(port) == PORT_A ? "A" : "B", exp, addr);
    endtask;

    task automatic verify_read(input port_t port, [31 : 0]exp);
        logic [31 : 0] act;

        act = pB_wb_data_o;
        if (port == PORT_A)
            act = pA_wb_data_o;

        assert (act == exp) else
            $fatal(1, "Test %0d: Read data 0x%0h does not match expected data 0x%0h", test_no, act, exp);

    endtask;
endmodule
