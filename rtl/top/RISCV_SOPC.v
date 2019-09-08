//******************************************************************************
//  File    : RISCV_SOPC.v
//  Author  : Lyu Yang
//  Date    : 2019-07-12
//  Details :
//******************************************************************************
// synopsys translate_off
`timescale 1 ns / 100 ps
// synopsys translate_on
module RISCV_SOPC (
    input               clk             ,
    input               rst             ,
    output              mcb3_dram_ck    ,
    output              mcb3_dram_ck_n  ,
    inout   [15:0]      mcb3_dram_dq    ,
    output  [12:0]      mcb3_dram_a     ,
    output  [2:0]       mcb3_dram_ba    ,
    output              mcb3_dram_ras_n ,
    output              mcb3_dram_cas_n ,
    output              mcb3_dram_we_n  ,
    output              mcb3_dram_odt   ,
    output              mcb3_dram_cke   ,
    output              mcb3_dram_dm    ,
    inout               mcb3_dram_udqs  ,
    inout               mcb3_dram_udqs_n,
    output              mcb3_dram_udm   ,
    inout               mcb3_dram_dqs   ,
    inout               mcb3_dram_dqs_n ,
    inout               mcb3_rzq        ,
    inout               mcb3_zio        ,
    output              uart_txd        ,
    input               uart_rxd        ,
    output              flash_cs_n      ,
    output              flash_sclk      ,
    output              flash_mosi      ,
    input               flash_miso      ,
    output              sdio_clk        ,
    output              sdio_cmd        ,
    input               sdio_dat0       ,
    input               sdio_dat1       ,
    input               sdio_dat2       ,
    output              sdio_dat3       ,
    input   [3:0]       key             ,
    output  [3:0]       led
);

// CRG
wire                rst_sync;

// CPU Instruction
wire                iwb_ack_i;
wire                iwb_cyc_o;
wire                iwb_stb_o;
wire    [31:0]      iwb_dat_i;
wire    [31:0]      iwb_dat_o;
wire    [31:0]      iwb_adr_o;
wire    [3:0]       iwb_sel_o;
wire                iwb_we_o;
wire                iwb_err_i;
wire                iwb_rty_i;

// CPU Data
wire                dwb_ack_i;
wire                dwb_cyc_o;
wire                dwb_stb_o;
wire    [31:0]      dwb_dat_i;
wire    [31:0]      dwb_dat_o;
wire    [31:0]      dwb_adr_o;
wire                dwb_we_o;
wire    [3:0]       dwb_sel_o;
wire                dwb_err_i;
wire                dwb_rty_i;

// SOC RAM
wire                ram_ack_o;
wire                ram_cyc_i;
wire                ram_stb_i;
wire    [31:0]      ram_dat_i;
wire    [31:0]      ram_dat_o;
wire    [31:0]      ram_adr_i;
wire                ram_we_i;
wire    [3:0]       ram_sel_i;

// DDR2 SDRAM
wire                ddr_ack_o;
wire                ddr_cyc_i;
wire                ddr_stb_i;
wire    [31:0]      ddr_dat_i;
wire    [31:0]      ddr_dat_o;
wire    [31:0]      ddr_adr_i;
wire                ddr_we_i;
wire    [3:0]       ddr_sel_i;

// WB GPIO
wire                gpio_ack_o;
wire                gpio_cyc_i;
wire                gpio_stb_i;
wire    [31:0]      gpio_dat_i;
wire    [31:0]      gpio_dat_o;
wire    [31:0]      gpio_adr_i;
wire    [3:0]       gpio_sel_i;
wire                gpio_we_i;
wire                gpio_err_o;
wire                gpio_irq;

// WB UART
wire                uart_cyc_i;
wire                uart_we_i;
wire    [3:0]       uart_sel_i;
wire                uart_stb_i;
wire    [31:0]      uart_adr_i;
wire    [31:0]      uart_dat_i;
wire    [31:0]      uart_dat_o;
wire                uart_ack_o;
wire                uart_irq;

// WB SPI
wire                spi_cyc_i;
wire                spi_we_i;
wire    [3:0]       spi_sel_i;
wire                spi_stb_i;
wire    [31:0]      spi_adr_i;
wire    [31:0]      spi_dat_i;
wire    [31:0]      spi_dat_o;
wire                spi_ack_o;

wire                spi_sclk;
wire                spi_mosi;
wire                spi_miso;
wire    [15:0]      spi_csn;
wire                spi_irq;

// RST SYNC
rst_sync U_RST_SYNC (
    .clk                (clk                ),
    .arst_i             (rst                ),
    .srst_o             (rst_sync           )
);

// RISC-V
//riscv_wb_top    U_RISCV (
//    .clk_i              (clk                ),
//    .rst_i              (rst_sync           ),
//    .intr_i             (1'b0               ),
//    .iwb_cyc_o          (iwb_cyc_o          ),
//    .iwb_stb_o          (iwb_stb_o          ),
//    .iwb_adr_o          (iwb_adr_o          ),
//    .iwb_dat_i          (iwb_dat_i          ),
//    .iwb_ack_i          (iwb_ack_i          ),
//    .iwb_err_i          (1'b0               ),
//    .dwb_cyc_o          (dwb_cyc_o          ),
//    .dwb_stb_o          (dwb_stb_o          ),
//    .dwb_we_o           (dwb_we_o           ),
//    .dwb_sel_o          (dwb_sel_o          ),
//    .dwb_adr_o          (dwb_adr_o          ),
//    .dwb_dat_i          (dwb_dat_i          ),
//    .dwb_dat_o          (dwb_dat_o          ),
//    .dwb_ack_i          (dwb_ack_i          ),
//    .dwb_err_i          (1'b0               )
//);

// PicoRV32 CPU
picorv32_wb U_PICORV32 (
    .wb_clk_i           (clk                ),
    .wb_rst_i           (rst_sync           ),
    .wbm_cyc_o          (dwb_cyc_o          ),
    .wbm_stb_o          (dwb_stb_o          ),
    .wbm_we_o           (dwb_we_o           ),
    .wbm_sel_o          (dwb_sel_o          ),
    .wbm_adr_o          (dwb_adr_o          ),
    .wbm_dat_i          (dwb_dat_i          ),
    .wbm_dat_o          (dwb_dat_o          ),
    .wbm_ack_i          (dwb_ack_i          ),
    .pcpi_wr            (1'b0               ),
    .pcpi_rd            (32'h0              ),
    .pcpi_wait          (1'b0               ),
    .pcpi_ready         (1'b0               ),
    .pcpi_valid         (                   ),
    .pcpi_insn          (                   ),
    .pcpi_rs1           (                   ),
    .pcpi_rs2           (                   ),
    .irq                (32'h0              ),
    .eoi                (                   ),
    .trace_data         (                   ),
    .trace_valid        (                   ),
    .trap               (                   ),
    .mem_instr          (                   )
);

// Wishbone Conmax
wb_conmax_top U_WB_CONMAX (
    .clk_i              (clk                ),
    .rst_i              (rst_sync           ),

    // Master 0 Interface
    .m0_data_i          (32'd0              ),
    .m0_data_o          (iwb_dat_i          ),
    .m0_addr_i          (iwb_adr_o          ),
    .m0_sel_i           (4'hf               ),
    .m0_we_i            (1'b0               ),
    .m0_cyc_i           (1'b0               ),
    .m0_stb_i           (1'b0               ),
    .m0_ack_o           (iwb_ack_i          ),
    .m0_err_o           (                   ),
    .m0_rty_o           (                   ),

    // Master 1 Interface
    .m1_data_i          (dwb_dat_o          ),
    .m1_data_o          (dwb_dat_i          ),
    .m1_addr_i          (dwb_adr_o          ),
    .m1_sel_i           (dwb_sel_o          ),
    .m1_we_i            (dwb_we_o           ),
    .m1_cyc_i           (dwb_cyc_o          ),
    .m1_stb_i           (dwb_stb_o          ),
    .m1_ack_o           (dwb_ack_i          ),
    .m1_err_o           (                   ),
    .m1_rty_o           (                   ),

    // Slave 0 Interface
    .s0_data_i          (ram_dat_o          ),
    .s0_data_o          (ram_dat_i          ),
    .s0_addr_o          (ram_adr_i          ),
    .s0_sel_o           (ram_sel_i          ),
    .s0_we_o            (ram_we_i           ),
    .s0_cyc_o           (ram_cyc_i          ),
    .s0_stb_o           (ram_stb_i          ),
    .s0_ack_i           (ram_ack_o          ),
    .s0_err_i           (1'b0               ),
    .s0_rty_i           (1'b0               ),

    // Slave 1 Interface
    .s1_data_i          (ddr_dat_o          ),
    .s1_data_o          (ddr_dat_i          ),
    .s1_addr_o          (ddr_adr_i          ),
    .s1_sel_o           (ddr_sel_i          ),
    .s1_we_o            (ddr_we_i           ),
    .s1_cyc_o           (ddr_cyc_i          ),
    .s1_stb_o           (ddr_stb_i          ),
    .s1_ack_i           (ddr_ack_o          ),
    .s1_err_i           (1'b0               ),
    .s1_rty_i           (1'b0               ),

    // Slave 2 Interface
    .s2_data_i          (gpio_dat_o         ),
    .s2_data_o          (gpio_dat_i         ),
    .s2_addr_o          (gpio_adr_i         ),
    .s2_sel_o           (gpio_sel_i         ),
    .s2_we_o            (gpio_we_i          ),
    .s2_cyc_o           (gpio_cyc_i         ),
    .s2_stb_o           (gpio_stb_i         ),
    .s2_ack_i           (gpio_ack_o         ),
    .s2_err_i           (gpio_err_o         ),
    .s2_rty_i           (1'b0               ),

    // Slave 3 Interface
    .s3_data_i          (uart_dat_o         ),
    .s3_data_o          (uart_dat_i         ),
    .s3_addr_o          (uart_adr_i         ),
    .s3_sel_o           (uart_sel_i         ),
    .s3_we_o            (uart_we_i          ),
    .s3_cyc_o           (uart_cyc_i         ),
    .s3_stb_o           (uart_stb_i         ),
    .s3_ack_i           (uart_ack_o         ),
    .s3_err_i           (1'b0               ),
    .s3_rty_i           (1'b0               ),

    // Slave 4 Interface
    .s4_data_i          (spi_dat_o          ),
    .s4_data_o          (spi_dat_i          ),
    .s4_addr_o          (spi_adr_i          ),
    .s4_sel_o           (spi_sel_i          ),
    .s4_we_o            (spi_we_i           ),
    .s4_cyc_o           (spi_cyc_i          ),
    .s4_stb_o           (spi_stb_i          ),
    .s4_ack_i           (spi_ack_o          ),
    .s4_err_i           (1'b0               ),
    .s4_rty_i           (1'b0               )
);

// RAM For RISC-V CPU
wb_ram U_WB_RAM (
    .wb_clk_i           (clk                ),
    .wb_rst_i           (rst_sync           ),
    .wb_cyc_i           (ram_cyc_i          ),
    .wb_stb_i           (ram_stb_i          ),
    .wb_we_i            (ram_we_i           ),
    .wb_sel_i           (ram_sel_i          ),
    .wb_adr_i           (ram_adr_i          ),
    .wb_dat_i           (ram_dat_i          ),
    .wb_dat_o           (ram_dat_o          ),
    .wb_ack_o           (ram_ack_o          )
);

// DDR2 SDRAM
wb_xmigddr U_SPMIG_DDR (
    .wb_clk_i           (clk                    ),
    .wb_rst_i           (rst_sync               ),

    // Wishbone Interface
    .wb_cyc_i           (ddr_cyc_i              ),
    .wb_stb_i           (ddr_stb_i              ),
    .wb_we_i            (ddr_we_i               ),
    .wb_sel_i           (ddr_sel_i              ),
    .wb_adr_i           (ddr_adr_i              ),
    .wb_dat_i           (ddr_dat_i              ),
    .wb_dat_o           (ddr_dat_o              ),
    .wb_ack_o           (ddr_ack_o              ),

   // ddr2 chip signals
    .mcb3_dram_dq       (mcb3_dram_dq           ),
    .mcb3_dram_a        (mcb3_dram_a            ),
    .mcb3_dram_ba       (mcb3_dram_ba           ),
    .mcb3_dram_ras_n    (mcb3_dram_ras_n        ),
    .mcb3_dram_cas_n    (mcb3_dram_cas_n        ),
    .mcb3_dram_we_n     (mcb3_dram_we_n         ),
    .mcb3_dram_odt      (mcb3_dram_odt          ),
    .mcb3_dram_cke      (mcb3_dram_cke          ),
    .mcb3_dram_dm       (mcb3_dram_dm           ),
    .mcb3_dram_udqs     (mcb3_dram_udqs         ),
    .mcb3_dram_udqs_n   (mcb3_dram_udqs_n       ),
    .mcb3_dram_udm      (mcb3_dram_udm          ),
    .mcb3_dram_dqs      (mcb3_dram_dqs          ),
    .mcb3_dram_dqs_n    (mcb3_dram_dqs_n        ),
    .mcb3_dram_ck       (mcb3_dram_ck           ),
    .mcb3_dram_ck_n     (mcb3_dram_ck_n         ),
    .mcb3_rzq           (mcb3_rzq               ),
    .mcb3_zio           (mcb3_zio               )
);

// WB GPIO
gpio_top U_WB_GPIO (
    .wb_clk_i           (clk                    ),
    .wb_rst_i           (rst_sync               ),
    .wb_cyc_i           (gpio_cyc_i             ),
    .wb_adr_i           (gpio_adr_i             ),
    .wb_dat_i           (gpio_dat_i             ),
    .wb_sel_i           (gpio_sel_i             ),
    .wb_we_i            (gpio_we_i              ),
    .wb_stb_i           (gpio_stb_i             ),
    .wb_dat_o           (gpio_dat_o             ),
    .wb_ack_o           (gpio_ack_o             ),
    .wb_err_o           (gpio_err_o             ),
    .wb_inta_o          (gpio_irq               ),
    .ext_pad_i          (key                    ),
    .ext_pad_o          (led                    ),
    .ext_padoe_o        (                       )
);

// UART 16550 8BIT MODE
uart_top U_UART (
    .wb_clk_i           (clk                    ),
    .wb_rst_i           (rst_sync               ),
    .wb_stb_i           (uart_stb_i             ),
    .wb_cyc_i           (uart_cyc_i             ),
    .wb_ack_o           (uart_ack_o             ),
    .wb_adr_i           (uart_adr_i[31:2]       ),
    .wb_we_i            (uart_we_i              ),
    .wb_sel_i           (uart_sel_i             ),
    .wb_dat_i           (uart_dat_i             ),
    .wb_dat_o           (uart_dat_o             ),
    .int_o              (uart_irq               ),
    .stx_pad_o          (uart_txd               ),
    .srx_pad_i          (uart_rxd               ),
    .rts_pad_o          (                       ),
    .cts_pad_i          (1'b0                   ),
    .dtr_pad_o          (                       ),
    .dsr_pad_i          (1'b0                   ),
    .ri_pad_i           (1'b0                   ),
    .dcd_pad_i          (1'b0                   )
);

// SPI Master
spi_top U_SPI_MST (
    .wb_clk_i           (clk                    ),
    .wb_rst_i           (rst_sync               ),
    .wb_stb_i           (spi_stb_i              ),
    .wb_cyc_i           (spi_cyc_i              ),
    .wb_ack_o           (spi_ack_o              ),
    .wb_adr_i           (spi_adr_i[4:0]         ),
    .wb_we_i            (spi_we_i               ),
    .wb_sel_i           (spi_sel_i              ),
    .wb_dat_i           (spi_dat_i              ),
    .wb_dat_o           (spi_dat_o              ),
    .wb_int_o           (spi_irq                ),
    .ss_pad_o           (spi_csn                ),
    .sclk_pad_o         (spi_sclk               ),
    .mosi_pad_o         (spi_mosi               ),
    .miso_pad_i         (spi_miso               )
);

// SPI Flash W25Q64BV
assign flash_cs_n   = spi_csn[0];
assign flash_sclk   = spi_sclk;
assign flash_mosi   = spi_mosi;

// SDIO SPI Mode
assign sdio_dat3    = spi_csn[1];
assign sdio_clk     = spi_sclk;
assign sdio_cmd     = spi_mosi;

// SPI MISO MUX
assign spi_miso     = (~spi_csn[0]) ? flash_miso : (~spi_csn[1]) ? sdio_dat0 : 1'bz;

endmodule
