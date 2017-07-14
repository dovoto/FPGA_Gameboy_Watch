
/*

Module: Top level gameboy implementation

Contrary to good design and practice there is some logic and fucntionality 
in this top level module that should be moved.


GPIO pinout for DE10 Standard:

       FPGA

34 32 30 28 26 3.3v 24 22 20 18 16 14 12 10 5.5v 08 06 04 02 00
35 33 31 29 27 GND  25 23 21 19 17 15 13 11 GND  09 07 05 03 01 


       HSMC Connector


Author: Jason Rogers
Contact: jasonrogers@alumni.stanford.edu


LICENSE

Copyright (c) 2017 Jason Rogers

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

Attribution is given to the author(s) of the software where such attribution is 
convenient.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/


module gameboy(

	//////////// CLOCK //////////
//	input 		          		CLOCK2_50,
//	input 		          		CLOCK3_50,
//	input 		          		CLOCK4_50,
	input 		          		CLOCK_50,
//
//	//////////// KEY //////////
	input 		     [3:0]		KEY,
//
//	//////////// SW //////////
	input 		     [9:0]		SW,
//
//	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// Seg7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	output		     [6:0]		HEX4,
	output		     [6:0]		HEX5,

//	//////////// SDRAM //////////
//	output		    [12:0]		DRAM_ADDR,
//	output		     [1:0]		DRAM_BA,
//	output		          		DRAM_CAS_N,
//	output		          		DRAM_CKE,
//	output		          		DRAM_CLK,
//	output		          		DRAM_CS_N,
//	inout 		    [15:0]		DRAM_DQ,
//	output		          		DRAM_LDQM,
//	output		          		DRAM_RAS_N,
//	output		          		DRAM_UDQM,
//	output		          		DRAM_WE_N,
//
//	//////////// VGA //////////
//	output		          		VGA_BLANK_N,
//	output		     [7:0]		VGA_B,
//	output		          		VGA_CLK,
//	output		     [7:0]		VGA_G,
//	output		          		VGA_HS,
//	output		     [7:0]		VGA_R,
//	output		          		VGA_SYNC_N,
//	output		          		VGA_VS,
//
//	//////////// Audio //////////
//	input 		          		AUD_ADCDAT,
//	inout 		          		AUD_ADCLRCK,
//	inout 		          		AUD_BCLK,
//	output		          		AUD_DACDAT,
//	inout 		          		AUD_DACLRCK,
//	output		          		AUD_XCK,
//
//	//////////// I2C for Audio and Video-In //////////
//	output		          		FPGA_I2C_SCLK,
//	inout 		          		FPGA_I2C_SDAT,
//
//	//////////// GPIO, GPIO connect to GPIO Default //////////
	inout 		    [35:0]		GPIO
);


wire rst;

assign rst = ~KEY[0];  //no deticated reset signal for de10

//=======================================================
//  Clock generation
//=======================================================

wire cpu_clock;

gb_clocks clocks(
		.refclk(CLOCK_50),   
		.rst(rst),      
		.outclk_0(cpu_clock), //4mhz ish clock	
		.outclk_1(uart_clock) 
	);


//=======================================================
//  Snes controller module decleration
//=======================================================

wire [15:0] 		snes_buttons;

snes_controller snes_ctl_1(
   .clock(cpu_clock),              
	.rst(rst),            
	.snes_buttons(snes_buttons),   
	.snes_data (GPIO[0]),
   .snes_latch (GPIO[1]),
	.snes_clock (GPIO[2])
	
	);

//debug output for snes controller buttons
HexController hex0 ( .led_segments({HEX0}), .data(~snes_buttons[11:8]));
HexController hex1 ( .led_segments({HEX1}), .data(~snes_buttons[7:4]));
HexController hex2 ( .led_segments({HEX2}), .data(~snes_buttons[3:0]));


//=======================================================
// Gameboy CPU instantiation
//=======================================================
wire [15:0] cpu_addr_bus;
wire [7:0] cpu_data_bus_out;
wire [7:0] cpu_data_bus_in;
wire cpu_we;
wire cpu_re;
wire [15:0] cpu_pc;

reg [7:0] irq;
wire button_pressed = 0;
wire cgb = 0;
wire initialized;
wire speed_double;

gb_cpu cpu(
.rst(rst),
.clock(cpu_clock), 
.addr_bus_out(cpu_addr_bus), 
.data_bus_in(cpu_data_bus_in), 
.data_bus_out(cpu_data_bus_out), 
.we(cpu_we), 
.re(cpu_re), 
.PC(cpu_pc), 
.irq(irq), 
.cgb(cgb),
.initialized(initialized),
.gdma_happening(gdma_happening),
.speed_double(speed_double));


//=======================================================
// Gameboy memory controller instantiation
//=======================================================

wire [7:0] mem_controller_data_out;
wire [7:0] dma_wr_addr;
wire [7:0] dma_data;
wire dma_we;
wire dma_happening;

wire [15:0] gdma_wr_addr;
wire [7:0] gdma_data;
wire gdma_we;
wire gdma_happening;

wire unloaded;
wire gb_rom;

gb_memory_controller mem_control(
.rst(rst), 
.clock(memory_clock), 
.addr_bus(cpu_addr_bus), 
.data_in(cpu_data_bus_out), 
.data_out(mem_controller_data_out), 
.we(cpu_we),
.rd(cpu_re), 
.cgb(cgb), 
.initialized(initialized),
.dma_wr_addr(dma_wr_addr),
.dma_we(dma_we),
.dma_happening(dma_happening),
.dma_data(dma_data),
.gdma_wr_addr(gdma_wr_addr),
.gdma_we(gdma_we),
.gdma_happening(gdma_happening),
.gdma_data(gdma_data),
.unloaded(unloaded),
.gb_rom(gb_rom),
.uart_addr(uart_load_addr),
.uart_data_in(uart_data_rcv),
.uart_we(uart_load_we),
.uart_load(uart_loading));


//=======================================================
// UART for rom loading and IO
//=======================================================

wire uart_clk;
wire uart_data_rdy;
wire [7:0] uart_data_rcv;
wire uart_rst_req;
wire [27:0] uart_load_addr;
wire uart_load_we;
wire uart_loading;
wire uart_tx;
wire uart_rx;

assign GPIO[3] = uart_tx;
assign uart_rx = GPIO[4];

uart load_uart(
.rst(rst),
.clk(uart_clk), 
.data_clk(cpu_clock), 
.send(cpu_we && cpu_addr_bus == 16'hFF01),
.data_send(cpu_data_bus_out), 
.data_rcv(uart_data_rcv), 
.rdy(uart_data_rdy),
.ack(cpu_we && cpu_addr_bus == 16'hFF08), 
.tx(uart_tx), 
.rx(uart_rx),
.rst_req(uart_rst_req),
.load_addr(uart_load_addr),
.load_we(uart_load_we),
.loading(uart_loading));
















//=======================================================
//  Just playing around with buttons and switches
//=======================================================

HexController hex3 ( .led_segments({HEX3}), .data(counter[3:0]));
HexController hex4 ( .led_segments({HEX4}), .data(counter[7:4]));
HexController hex5 ( .led_segments({HEX5}), .data({SW[7:4]}));

reg [7:0] counter;
reg up_state;
reg down_state;

assign LEDR = SW;

always @(posedge CLOCK_50)
begin
	
	case (up_state)
		0: 
			begin
				counter = counter + (KEY[0] ? 1'b1 : 1'b0);
				up_state = KEY[0];
			end
		1:
			begin
				up_state = KEY[0];
			end
	endcase
	
	case (down_state)
		0: 
			begin
				counter = counter - (KEY[1] ? 1'b1 : 1'b0);
				down_state = KEY[1];
			end
		1:
			begin
				down_state = KEY[1];
			end
	endcase
end

endmodule
