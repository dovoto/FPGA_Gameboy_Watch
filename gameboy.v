
/*

Module: Top level gameboy implementation

Contrary to good design and practice there is some logic and fucntionality 
in this top level module that should be moved.



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

assign rst = KEY[0];  //no deticated reset signal for de10

//=======================================================
//  Clock generation
//=======================================================

wire cpu_clock;

gb_clocks clocks(
		.refclk(CLOCK_50),   
		.rst(rst),      
		.outclk_0(cpu_clock) //4mhz ish clock	
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
HexController hex0 ( .led_segments({HEX2}), .data(snes_buttons[7:4]));
HexController hex1 ( .led_segments({HEX3}), .data(snes_buttons[3:0]));





//=======================================================
//  Just playing around with buttons and switches
//=======================================================

HexController hex2 ( .led_segments({HEX0}), .data(counter[3:0]));
HexController hex3 ( .led_segments({HEX1}), .data(counter[7:4]));
HexController hex4 ( .led_segments({HEX4}), .data({SW[7:4]}));
HexController hex5 ( .led_segments({HEX5}), .data({SW[3:0]}));

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
