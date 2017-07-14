
/*

Module: HEX LED controller for Terasic DE10 - Standard LEDs

Converts 4 bit data into 7 bit line driver signals.  Based on pin assignments
generated by Terasic board tool.  These pin assignments do not align with pinout
in the initial version of the DE10 - Standard user guide.


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






module HexController(

	output  [6:0] led_segments,  //hook up to LED lines 
	input   [3:0] data   
	
	);
	
	always
	begin
	
			case (data)
				4'h0: led_segments = 7'b1000000;
				4'h1: led_segments = 7'b1111001;
				4'h2: led_segments = 7'b0100100;
				4'h3: led_segments = 7'b0110000;
				4'h4: led_segments = 7'b0011001;
				4'h5: led_segments = 7'b0010010;
				4'h6: led_segments = 7'b0000010;
				4'h7: led_segments = 7'b1111000;
				4'h8: led_segments = 7'b0000000;
				4'h9: led_segments = 7'b0011000;
				4'ha: led_segments = 7'b0001000;
				4'hb: led_segments = 7'b0000011;
				4'hc: led_segments = 7'b1000110;
				4'hd: led_segments = 7'b0100001;
				4'he: led_segments = 7'b0000110;
				4'hf: led_segments = 7'b0001110;	
			endcase
			
	end
	
endmodule 