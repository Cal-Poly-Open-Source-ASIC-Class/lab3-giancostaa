`include "DFFRAM256x32.v"

module dual_port_ram (

    input logic clk_i,
    input logic rst_n_i,

    /* Port A Wishbone Signals */
    input  logic          pA_wb_stb_i,
    input  logic [8 : 0] pA_wb_addr_i,
    input  logic [3 : 0]  pA_wb_sel_i,
    input  logic          pA_wb_we_i,
    input  logic [31 : 0] pA_wb_data_i,

    output logic          pA_wb_stall_o,
    output logic          pA_wb_ack_o,
    output logic [31 : 0] pA_wb_data_o,
    
    /* Port B Wishbone Signals */
    input  logic          pB_wb_stb_i,
    input  logic [8 : 0] pB_wb_addr_i,
    input  logic [3 : 0]  pB_wb_sel_i,
    input  logic          pB_wb_we_i,
    input  logic [31 : 0] pB_wb_data_i,

    output logic          pB_wb_stall_o,
    output logic          pB_wb_ack_o,
    output logic [31 : 0] pB_wb_data_o

);
    
    /* DFF RAM Signals */

    logic [10 : 0] lo_A0 , hi_A0;
    logic [31 : 0] lo_Di0, hi_Di0;
    logic          lo_EN0, hi_EN0;
    logic [3 : 0]  lo_WE0, hi_WE0;  

    DFFRAM256x32 hi_ram (
        .CLK(clk_i),
        .WE0(hi_WE0),
        .EN0(pA_en),
        .Di0(hi_Di0),
        .Do0(pA_wb_data_o),
        .A0(hi_A0)
    );

    DFFRAM256x32 lo_ram (
        .CLK(clk_i),
        .WE0(lo_WE0),
        .EN0(pB_en),
        .Di0(lo_Di0),
        .Do0(pB_wb_data_o),
        .A0(lo_A0)
    );

    /* Arbitration */

    typedef enum logic
    {
        LO_RAM = 1'b0,
        HI_RAM = 1'b1
    } ram_t;

    typedef enum logic 
    {
        PORT_A = 1'b0,
        PORT_B = 1'b1
    } port_t;

    typedef enum
    {
        INIT,
        ACK,
        STALL
    } state_t;


    logic collision;
    port_t prio, next_prio;
    
    ram_t pA_ram, pB_ram;

    /* Collision detection */

    always_comb begin
        pA_ram = LO_RAM;
        pB_ram = LO_RAM;

        if (pA_wb_addr_i > 255) 
            pA_ram = HI_RAM;

        if (pB_wb_addr_i > 255)
            pB_ram = HI_RAM;
    end

    assign collision = pA_ram == pB_ram; 

    always_ff @ (posedge clk_i) begin
        if (rst_n_i == 0)
            prio <= PORT_A;
        else if (collision)
            prio <= next_prio;
    end

    always_comb begin
        pA_wb_stall_o = 1;
        pB_wb_stall_o = 1;
        next_prio = PORT_B;

        if (collision) begin
            if (prio == PORT_A) begin
                pB_wb_stall_o = 1;
                next_prio = PORT_B;
            end else if (prio == PORT_B) begin
                pA_wb_stall_o = 1;
                next_prio = PORT_A;
            end
        end

    end

    /* Write Enable logic */
    logic [3 : 0] pA_WE0, pB_WE0;

    assign pA_WE0 = pA_wb_sel_i & {4{pA_wb_we_i}};
    assign pB_WE0 = pB_wb_sel_i & {4{pB_wb_we_i}};

    /* Arbitration */

    logic pA_lo_arbiter, pB_lo_arbiter, pA_hi_arbiter, pB_hi_arbiter;

    assign pA_lo_arbiter = ((collision && prio)  || (!collision)) && (pA_ram == LO_RAM);
    assign pB_lo_arbiter = ((collision && !prio) || (!collision)) && (pB_ram == LO_RAM);
    
    assign pA_hi_arbiter = ((collision && prio)  || (!collision)) && (pA_ram == HI_RAM);
    assign pB_hi_arbiter = ((collision && !prio) || (!collision)) && (pB_ram == HI_RAM);

    always_comb begin

        if (pA_lo_arbiter && pB_lo_arbiter) begin
            $display("I shouldn't be here...");
        end else if (pA_hi_arbiter && pB_hi_arbiter) begin
            $display("I shouldn't be here either...");
        end


        /* Lo RAM Input Arbitration */ 
        if (pA_lo_arbiter && !pB_lo_arbiter) begin
            lo_A0  = pA_wb_addr_i;
            lo_Di0 = pA_wb_data_i;
            lo_EN0 = pA_wb_stb_i;
            lo_WE0 = pA_WE0;
        end else if (!pA_lo_arbiter && pB_lo_arbiter) begin
            lo_A0  = pB_wb_addr_i;
            lo_Di0 = pB_wb_data_i;
            lo_EN0 = pB_wb_stb_i;
            lo_WE0 = pB_WE0;
        end else begin
            lo_A0 = {32'hDEADBEEF}[10 : 0];
            lo_Di0 = 32'hDEADBEEF;
            lo_EN0 = 0;
            lo_WE0 = 0;
        end

         /* Hi RAM Input Arbitration */ 
        if (pA_hi_arbiter && !pB_hi_arbiter) begin
            hi_A0  = pA_wb_addr_i;
            hi_Di0 = pA_wb_data_i;
            hi_EN0 = pA_wb_stb_i;
            hi_WE0 = pA_WE0;
        end else if (!pA_hi_arbiter && pB_hi_arbiter) begin
            hi_A0  = pB_wb_addr_i;
            hi_Di0 = pB_wb_data_i;
            hi_EN0 = pB_wb_stb_i;
            hi_WE0 = pB_WE0;
        end else begin
            hi_A0 = {32'hDEADBEEF}[10 : 0];
            hi_Di0 = 32'hDEADBEEF;
            hi_EN0 = 0;
            hi_WE0 = 0;
        end


    end

  

endmodule

