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

    task automatic pA_wb_read_word(input logic [8 : 0]addr);
        pA_wb_stb_i  = 1;
        pA_wb_addr_i = addr;
        pA_wb_sel_i  = 0;
        pA_wb_we_i   = 0;
        
        @(posedge clk_i);

        pA_wb_stb_i  = 0;

        @(posedge clk_i);

    endtask;

    task automatic pA_wb_write_word(input logic [8 : 0]addr, [31 : 0]data);
        pA_wb_stb_i  = 1;
        pA_wb_addr_i = addr;
        pA_wb_sel_i  = 4'hF;
        pA_wb_we_i   = 1;
        pA_wb_data_i = data;
        
        @(posedge clk_i);

        pA_wb_stb_i = 0;

        @(posedge clk_i);

    endtask;

    task automatic pB_wb_read_word(input logic [8 : 0]addr);
        pB_wb_stb_i  = 1;
        pB_wb_addr_i = addr;
        pB_wb_sel_i  = 0;
        pB_wb_we_i   = 0;
        
        @(posedge clk_i);

        pB_wb_stb_i  = 0;

        @(posedge clk_i);

    endtask;

    task automatic pB_wb_write_word(input logic [8 : 0]addr, [31 : 0]data);
        pB_wb_stb_i  = 1;
        pB_wb_addr_i = addr;
        pB_wb_sel_i  = 4'hF;
        pB_wb_we_i   = 1;
        pB_wb_data_i = data;
        
        @(posedge clk_i);

        pB_wb_stb_i = 0;

        @(posedge clk_i);

    endtask;

    task automatic dport_write_no_col(input logic [8 : 0] pA_addr, logic [31 : 0] pA_data, logic [8 : 0] pB_addr, logic [31 : 0] pB_data);
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
    
    endtask;

    task automatic dport_read_no_col(input logic [8 : 0] pA_addr, [8 : 0] pB_addr);
        logic [31 : 0] RAM_data;

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

        // if (pA_addr < 256) 
        //     RAM_data = dut.lo_ram.RAM[pA_addr[7 : 0]];
        // else
        //     RAM_data = dut.hi_ram.RAM[pA_addr[7 : 0]];

        // assert (pA_wb_data_o == RAM_data) else
        //     $fatal(1, "pA output %0d does not match RAM data %0h at address %0d", pA_wb_data_o, RAM_data, pA_addr);

        @(posedge clk_i);

    endtask;


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

        @(posedge clk_i);

        /* Read from both RAMs, no collision */
        dport_read_no_col(69, 256);

        /* Read from */

        @(posedge clk_i);
        @(posedge clk_i);
        @(posedge clk_i);
        @(posedge clk_i);
        
    
        $finish();
    end

endmodule
