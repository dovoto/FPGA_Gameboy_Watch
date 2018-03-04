/*

Module: Memory controller

Handles bus translation for the mappers.  80% complete (supports most roms)  


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


module gb_memory_controller
//---------------------------------------
(rst, clock, addr_bus, data_in, data_out, 
we, rd, cgb, initialized,
dma_wr_addr, dma_we, dma_data, dma_happening,
gdma_wr_addr, gdma_we, gdma_data, gdma_happening,
unloaded, gb_rom,
uart_addr,uart_data_in,uart_we,uart_load);

input rst;
input clock;
input [15:0] addr_bus;
input [7:0] data_in;
output [7:0] data_out;
input we;
input rd;
input cgb;
input initialized;
output [7:0] dma_wr_addr;
output [7:0] dma_data;
output dma_we;
output dma_happening;
output [15:0] gdma_wr_addr;
output [7:0] gdma_data;
output gdma_we;
output gdma_happening;
output unloaded;
output gb_rom;
input [27:0] uart_addr;
input [7:0] uart_data_in;
input uart_we;
input uart_load;

reg [7:0] data_out;
reg [7:0] dma_wr_addr;
reg [7:0] dma_data;
reg dma_we;
reg dma_happening;
reg [15:0] gdma_wr_addr;
reg [7:0] gdma_data;
reg gdma_we;
reg gdma_happening;
reg unloaded;
reg gb_rom;
//---------------------------------------
//
//   Registers
//
//---------------------------------------
reg [7:0] rom_size;
reg [7:0] ram_size;
reg [7:0] mbc_type;

reg done_load;

reg ram_enabled;
reg [23:0] decoded_addr_bus;
reg [7:0] data_bus;



//---------------------------------------
//
//   Memory 
//
//---------------------------------------
reg [23:0] rom_addr_bus;
wire [7:0] rom_data_out;
reg rom_we;

wire [7:0] bios_data_out;
wire [7:0] jbios_data_out;

reg [12:0] wram_addr_bus;
reg [7:0] wram_data_in;
wire [7:0] wram_data_out;
reg [2:0] wram_bank_sel;
reg wram_we;

reg [15:0] cart_ram_addr_bus;
reg [7:0] cart_ram_data_in;
wire [7:0] cart_ram_data_out;
reg cart_ram_we;

reg [12:0] zpage_addr_bus;
reg [7:0] zpage_data_in;
wire [7:0] zpage_data_out;
reg zpage_we;

//=======================================================
//  Rams...lots of rams
//=======================================================

gb_zpage zpage(zpage_addr_bus,
	clock,
	zpage_data_in,
	zpage_we,
	zpage_data_out);
	
gb_work_ram wram({2'b0,wram_addr_bus} | {wram_bank_sel & {wram_addr_bus[12],wram_addr_bus[12],wram_addr_bus[12]}, 11'b0},
	clock,
	wram_data_in,
	wram_we,
	wram_data_out);
	
gb_rom rom((uart_load && (uart_addr[27:24] == 4'h0)) ? uart_addr[23:0] : rom_addr_bus,
	clock,
	(uart_load && (uart_addr[27:24] == 4'h0))  ? uart_data_in : data_in,
	(uart_load && (uart_addr[27:24] == 4'h0))  ? uart_we : rom_we,
	rom_data_out);
	
gb_bios bios((uart_load && uart_addr[27:24] == 4'h1) ? uart_addr[23:0] : rom_addr_bus[12:0],
	clock,
	(uart_load && (uart_addr[27:24] == 4'h1)) ? uart_data_in : 8'h00,
	(uart_load && (uart_addr[27:24] == 4'h1)) ? uart_we : 1'b0,
	bios_data_out);
	
jbios jbios((uart_load && (uart_addr[27:24] == 4'h2)) ? uart_addr[23:0] : rom_addr_bus[12:0],
	clock,
	(uart_load && (uart_addr[27:24] == 4'h2)) ? uart_data_in : 8'h00,
	(uart_load && (uart_addr[27:24] == 4'h2)) ? uart_we : 1'b0,
	jbios_data_out);

gb_cart_ram cart(cart_ram_addr_bus,
	clock,
	cart_ram_data_in,
	cart_ram_we,
	cart_ram_data_out);	



//---------------------------------------
//
//   MBCs
//
//---------------------------------------	
reg [15:0] mbc_addr_bus_in;

//---------------------------------------
//
//   MBC5
//
//---------------------------------------

wire [7:0] mbc5_data_out;
wire mbc5_ram_enabled;
wire [23:0] mbc5_decoded_addr;
reg mbc5_we;


gb_mbc5 mbc5(.rst(rst), 
.clock(clock), 
.addr_bus_in(mbc_addr_bus_in), 
.addr_bus_out(mbc5_decoded_addr), 
.data_in(data_in), 
.data_out(mbc5_data_out), 
.we_in(mbc5_we), 
.ram_enabled(mbc5_ram_enabled), 
.rom_size(rom_size), 
.ram_size(ram_size), 
.cgb(cgb));

//---------------------------------------
//
//   MBC2
//
//---------------------------------------

wire [7:0] mbc2_data_out;
wire mbc2_ram_enabled;
wire [23:0] mbc2_decoded_addr;
reg mbc2_we;

reg [15:0] mbc2_addr_bus_in;

gb_mbc2 mbc2(.rst(rst), 
.clock(clock), 
.addr_bus_in(mbc_addr_bus_in), 
.addr_bus_out(mbc2_decoded_addr), 
.data_in(data_in), 
.data_out(mbc2_data_out), 
.we_in(mbc2_we), 
.ram_enabled(mbc2_ram_enabled), 
.rom_size(rom_size), 
.ram_size(ram_size), 
.cgb(cgb));
	
//---------------------------------------
//
//   MBC1
//
//---------------------------------------

wire [7:0] mbc1_data_out;
wire mbc1_ram_enabled;
wire [23:0] mbc1_decoded_addr;
reg mbc1_we;

reg [15:0] mbc1_addr_bus_in;

gb_mbc1 mbc1(.rst(rst), 
.clock(clock), 
.addr_bus_in(mbc_addr_bus_in), 
.addr_bus_out(mbc1_decoded_addr), 
.data_in(data_in), 
.data_out(mbc1_data_out), 
.we_in(mbc1_we), 
.ram_enabled(mbc1_ram_enabled), 
.rom_size(rom_size), 
.ram_size(ram_size), 
.cgb(cgb));


//---------------------------------------
//
//   MBC0
//
//---------------------------------------

wire [7:0] mbc0_data_out;
wire mbc0_ram_enabled;
wire [23:0] mbc0_decoded_addr;
reg mbc0_we;



gb_mbc0 mbc0(.rst(rst), 
.clock(clock), 
.addr_bus_in(mbc_addr_bus_in), 
.addr_bus_out(mbc0_decoded_addr), 
.data_in(data_in), 
.data_out(mbc0_data_out), 
.we_in(mbc0_we), 
.ram_enabled(mbc0_ram_enabled), 
.rom_size(rom_size), 
.ram_size(ram_size), 
.cgb(cgb),
.unloaded(~done_load));
//---------------------------------------
//
//   Dma
//
//---------------------------------------
reg dma_re;
reg dma_from_rom;

reg [7:0] dma_counter;
reg [15:0] dma_rd_addr;
reg [1:0] dma_cycles;

reg [7:0] Reg_DMA_ff46;

always @(posedge clock)
begin
		if(rst) begin
			dma_counter = 8'd160;
			dma_cycles = 0;
			wram_bank_sel = 0;
		end else begin
			if(we) begin
				casex (addr_bus)
					16'b11111111xxxxxxxx: begin
							case (addr_bus[7:0])
								8'h46: begin
									Reg_DMA_ff46 = data_in;
									dma_counter = 0;
									dma_from_rom = ~data_in[7];
									dma_cycles = 0;
								end
								8'h70: wram_bank_sel = data_in[2:0];
								default: begin end
							endcase
						end 
					default: begin end
				endcase
			end
		end

		dma_happening = dma_counter != 8'd160;
	
	  	if(dma_happening) begin 
			case (dma_cycles)
				0: begin
					dma_rd_addr = {Reg_DMA_ff46, dma_counter};
					dma_re = 1'b1;
					dma_we = 1'b0;
				end
				1: begin
					dma_we = 1'b0;
					dma_re = 1'b0;					
				end
				2:	begin
					dma_wr_addr = dma_counter;
					dma_we = 1'b1;
					dma_re = 1'b0;
					dma_data = dma_from_rom ? (~Reg_DMA_ff46[7] ? rom_data_out : (ram_enabled ? cart_ram_data_out : 8'hff)) : wram_data_out;
				end 
				3: begin
					dma_we = 1'b0;
					dma_re = 1'b0;
					dma_counter = dma_counter + 1'b1;
					
				end
			endcase	
		end
		
		dma_cycles = dma_cycles +1'b1;
end

//---------------------------------------
//
//  General Dma
//
//---------------------------------------
reg gdma_re;
reg gdma_from_rom;

reg signed [11:0] gdma_counter;
reg [15:0] gdma_rd_addr;
reg [1:0] gdma_cycles;

reg [7:0] Reg_DMA_ff51;
reg [7:0] Reg_DMA_ff52;
reg [7:0] Reg_DMA_ff53;
reg [7:0] Reg_DMA_ff54;
reg [7:0] Reg_DMA_ff55;

always @(posedge clock)
begin
		if(rst) begin
			gdma_counter = 12'hfff;
			gdma_cycles = 0;
			Reg_DMA_ff51 = 8'hff;
			Reg_DMA_ff52 = 8'hff;
			Reg_DMA_ff53 = 8'hff;
			Reg_DMA_ff54 = 8'hff;
			Reg_DMA_ff55 = 8'hff;
			gdma_happening = 0;
			
		end else begin
			if(we & ~gdma_happening) begin
				casex (addr_bus)
					16'b11111111xxxxxxxx: begin
							case (addr_bus[7:0])
								8'h51: begin
									Reg_DMA_ff51 = data_in;
									gdma_from_rom = ~data_in[7];
								end
								8'h52: begin
									Reg_DMA_ff52 = data_in & 8'hf0;
								end
								8'h53: begin
									Reg_DMA_ff53 = (data_in & 8'h1f) | 8'h80;
								end
								8'h54: begin
									Reg_DMA_ff54 = data_in & 8'hf0;
								end
								8'h55: begin
									Reg_DMA_ff55 = data_in;
									gdma_cycles = 0;
									gdma_counter = {1'b0, data_in[6:0], 4'b0};
									
								end
								default: begin end
							endcase
						end 
						default: begin end
				endcase
			end
		

		
			if(gdma_happening) begin 
				case (gdma_cycles)
					0: begin
						gdma_rd_addr = {Reg_DMA_ff51, Reg_DMA_ff52};
						gdma_re = 1'b1;
						gdma_we = 1'b0;
					end
					1: begin
						gdma_we = 1'b0;
						gdma_re = 1'b0;					
					end
					2:	begin
						gdma_wr_addr = {Reg_DMA_ff53, Reg_DMA_ff54};
						gdma_we = 1'b1;
						gdma_re = 1'b0;
						casex (gdma_rd_addr)

							16'b0xxxxxxxxxxxxxxx: begin //rom / bios
								if(unloaded) begin
									gdma_data = (done_load && gdma_rd_addr[15:8] == 8'h01) ? (rom_data_out) : jbios_data_out;
								end else begin
									gdma_data = (~initialized && gdma_rd_addr[15:8] != 8'h01) ? (bios_data_out) : rom_data_out;
								end

							end
							16'b101xxxxxxxxxxxxx: begin //cart ram
									gdma_data = ram_enabled ? cart_ram_data_out : 8'hff;
							end
							16'b110xxxxxxxxxxxxx,
							16'b1110xxxxxxxxxxxx,
							16'b11110xxxxxxxxxxx,
							16'b1111x0xxxxxxxxxx,
							16'b1111xx0xxxxxxxxx,
							16'b1111xxx0xxxxxxxx: begin //wram
									gdma_data = wram_data_out;

							end

							default:	begin 
									gdma_data = 8'hff;
							end
						endcase
					end 
					3: begin
						gdma_we = 1'b0;
						gdma_re = 1'b0;
						gdma_counter = gdma_counter - 1'b1;
						{Reg_DMA_ff51, Reg_DMA_ff52} = {Reg_DMA_ff51, Reg_DMA_ff52} + 1'b1;
						{Reg_DMA_ff53, Reg_DMA_ff54} = {Reg_DMA_ff53, Reg_DMA_ff54} + 1'b1;
					end
				endcase	
				
				gdma_cycles = gdma_cycles +1'b1;
				
				
		
			end
			gdma_happening = (~gdma_counter[11]);
			
		end
end

always
begin

	cart_ram_addr_bus <= decoded_addr_bus[14:0];
	rom_addr_bus <= decoded_addr_bus;
	
	if(gdma_happening) begin
		wram_addr_bus <= (~gdma_from_rom) ? gdma_rd_addr[12:0] : addr_bus[12:0];
		mbc_addr_bus_in = gdma_rd_addr;
	end else begin
		wram_addr_bus <= (dma_happening & ~dma_from_rom) ? dma_rd_addr[12:0] : addr_bus[12:0];
		mbc_addr_bus_in = dma_happening & dma_from_rom ? dma_rd_addr : addr_bus;
	end
	
	zpage_addr_bus = addr_bus[6:0];
	
	wram_data_in <= data_in;
	cart_ram_data_in <= data_in;
	zpage_data_in = data_in;
	
	
//---------------------------------------
//
//   MBC mux
//
//---------------------------------------
	case (mbc_type)
		8'h00:  begin //MBC0
			decoded_addr_bus <= mbc0_decoded_addr;
			ram_enabled <= mbc0_ram_enabled; 
			data_bus <= mbc0_data_out;
			mbc0_we = we;
			mbc1_we = 1'b0;
			mbc2_we = 1'b0;
			mbc5_we = 1'b0;
		end
		8'h01,8'h02,8'h03:  begin //MBC1
			decoded_addr_bus <= mbc1_decoded_addr;
			ram_enabled <= mbc1_ram_enabled; 
			data_bus <= mbc1_data_out;
			mbc0_we = 1'b0;
			mbc1_we = we;
			mbc2_we = 1'b0;
			mbc5_we = 1'b0;
		end
		8'h5,8'h6:  begin //MBC2
			decoded_addr_bus <= mbc2_decoded_addr;
			ram_enabled <= mbc2_ram_enabled; 
			data_bus <= mbc2_data_out;
			mbc0_we = 1'b0;
			mbc1_we = 1'b0;
			mbc2_we = we;
			mbc5_we = 1'b0;
		end
		8'h19,8'h1a,8'h1b,8'h1c,8'h1d,8'h1e:  begin //MBC5
			decoded_addr_bus <= mbc5_decoded_addr;
			ram_enabled <= mbc5_ram_enabled; 
			data_bus <= mbc5_data_out;
			mbc0_we = 1'b0;
			mbc1_we = 1'b0;
			mbc2_we = 1'b0;
			mbc5_we = we;
		end
		default: begin
			decoded_addr_bus <= mbc1_decoded_addr;
			ram_enabled <= mbc1_ram_enabled; 
			data_bus <= mbc1_data_out;
			mbc0_we = 1'b0;
			mbc1_we = we;
			mbc2_we = 1'b0;
			mbc5_we = 1'b0;
		end	
	endcase

//---------------------------------------
//
//   Memory area decoding
//
//---------------------------------------
		casex (addr_bus)

		16'b0xxxxxxxxxxxxxxx: begin //rom / bios
			if(unloaded) begin
				data_out = (done_load && addr_bus[15:8] == 8'h01) ? (rom_data_out) : jbios_data_out;
			end else begin
				data_out = (~initialized && addr_bus[15:8] != 8'h01) ? (bios_data_out) : rom_data_out;
			end
			wram_we = 1'b0;
//			sdram_we = 1'b0;
//			sdram_rd = 1'b0;
			zpage_we = 1'b0;
			cart_ram_we = 1'b0;
			rom_we = 1'b0;
		end
		16'b101xxxxxxxxxxxxx: begin //cart ram
			data_out = ram_enabled ? cart_ram_data_out : 8'hff;
			wram_we = 1'b0;
//			sdram_we = 1'b0;
//			sdram_rd = 1'b0;
			rom_we = 1'b0;
			zpage_we = 1'b0;
			cart_ram_we = ram_enabled & we;
		end
		16'b110xxxxxxxxxxxxx,
		16'b1110xxxxxxxxxxxx,
		16'b11110xxxxxxxxxxx,
		16'b1111x0xxxxxxxxxx,
		16'b1111xx0xxxxxxxxx,
		16'b1111xxx0xxxxxxxx: begin //wram
			data_out = wram_data_out;//sdram_data_in;//
			wram_we = we;
//			sdram_we = we;
//			sdram_rd = rd;
			rom_we = 1'b0;
			cart_ram_we = 1'b0;
			zpage_we = 1'b0;

		end
		16'b111111111xxxxxxx: begin //zero page
			data_out= zpage_data_out;
			wram_we = 1'b0;
//			sdram_we = 1'b0;
//			sdram_rd = 1'b0;
			zpage_we = we;
			cart_ram_we = 1'b0;
			rom_we = 1'b0;
		end
		16'b111111110xxxxxxx: begin
			case (addr_bus[6:0])
				7'h46: begin
					data_out = Reg_DMA_ff46;
				end
				7'h70: data_out = 8'hf8 | wram_bank_sel;
				default: begin
					 data_out = 8'hff; 
				end
			endcase
			wram_we = 1'b0;
//			sdram_we = 1'b0;
//			sdram_rd = 1'b0;
			rom_we = 1'b0;
			cart_ram_we = 1'b0;	
			zpage_we = 1'b0;
		end
		default:	begin 
	      data_out = 8'hFF;
			wram_we = 1'b0;
//			sdram_we = 1'b0;
//			sdram_rd = 1'b0;
			rom_we = 1'b0;
			cart_ram_we = 1'b0;	
			zpage_we = 1'b0;

		end
	endcase
	
end
	
	always @(posedge clock)
	begin
		if(rst) begin  
			unloaded = 1;
			done_load = 0;
			mbc_type = 0;
			rom_size = 0;
			ram_size = 0;
			gb_rom = 0;
		end else if(we & unloaded & addr_bus[15:8] == 8'hFF) begin
			casex (addr_bus[7:0])
				8'h80: mbc_type = data_in;
				8'h81: rom_size = data_in;
				8'h82: ram_size = data_in;
				8'h83: done_load = 1;
				8'h86: gb_rom = ~data_in[7];
			endcase
		end else begin
			unloaded = ~(addr_bus == 0 & done_load) & unloaded;
		end
	end
endmodule


