//
// hps_ext for Minimig
//
// Copyright (c) 2020 Alexey Melnikov
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
///////////////////////////////////////////////////////////////////////

module hps_ext
(
	input             clk_sys,
	inout      [35:0] EXT_BUS,

	output            io_strobe,
	output            io_fpga,
	output            io_uio,
	output     [15:0] io_din,
	input      [15:0] fpga_dout,

	output reg  [2:0] mouse_buttons,
	output reg        kbd_mouse_level,
	output reg  [1:0] kbd_mouse_type,
	output reg  [7:0] kbd_mouse_data,

	input      [11:0] scr_hbl_l,
	input      [11:0] scr_hbl_r,
	input      [11:0] scr_hsize,
	input      [11:0] scr_vbl_t,
	input      [11:0] scr_vbl_b,
	input      [11:0] scr_vsize,
	input       [6:0] scr_flg,
	input       [1:0] scr_res,

	output reg [11:0] shbl_l,
	output reg [11:0] shbl_r,
	output reg [11:0] svbl_t,
	output reg [11:0] svbl_b,
	output reg        sset
);

assign EXT_BUS[15:0] = io_fpga ? fpga_dout : io_dout;
assign io_din = EXT_BUS[31:16];
assign EXT_BUS[32] = dout_en | io_fpga;
assign io_strobe = EXT_BUS[33];
assign io_uio = EXT_BUS[34];
assign io_fpga = EXT_BUS[35];

localparam EXT_CMD_MIN = UIO_GET_VMODE;
localparam EXT_CMD_MAX = UIO_SET_VPOS;

localparam UIO_MOUSE     = 'h04;
localparam UIO_KEYBOARD  = 'h05;
localparam UIO_KBD_OSD   = 'h06;
localparam UIO_GET_VMODE = 'h2C;
localparam UIO_SET_VPOS  = 'h2D;

reg [15:0] io_dout;
reg        dout_en;
reg  [4:0] byte_cnt;

always@(posedge clk_sys) begin
	reg [15:0] cmd;

	sset <= 0;

	if(~io_uio) begin
		dout_en <= 0;
		io_dout <= 0;
		byte_cnt <= 0;
		if(cmd == 'h2D) sset <= 1;
	end
	else if(io_strobe) begin

		io_dout <= 0;
		if(~&byte_cnt) byte_cnt <= byte_cnt + 1'd1;

		if(byte_cnt == 0) begin
			cmd <= io_din;
			dout_en <= (io_din >= EXT_CMD_MIN && io_din <= EXT_CMD_MAX);
		end else begin
			case(cmd)
			
				UIO_MOUSE:
					case(byte_cnt)
						1: begin
								kbd_mouse_data <= io_din[7:0];
								kbd_mouse_type <= 0;
								kbd_mouse_level <= ~kbd_mouse_level;
							end
						2: begin
								// second byte contains movement data
								kbd_mouse_data <= io_din[7:0];
								kbd_mouse_type <= 1;
								kbd_mouse_level <= ~kbd_mouse_level; 
							end
						3: begin
								// third byte contains the buttons
								mouse_buttons <= io_din[2:0];
							end
					endcase

				UIO_KEYBOARD:
					if(byte_cnt == 1) begin
						kbd_mouse_data <= io_din[7:0];
						kbd_mouse_type <= 2;
						kbd_mouse_level <= ~kbd_mouse_level;
					end

				UIO_KBD_OSD:
					if(byte_cnt == 1) begin
						kbd_mouse_data <= io_din[7:0];
						kbd_mouse_type <= 3;
						kbd_mouse_level <= ~kbd_mouse_level;
					end

				UIO_GET_VMODE:
					case(byte_cnt)
						1: io_dout <= {1'b1, scr_flg, 6'd0, scr_res};
						2: io_dout <= scr_hsize;
						3: io_dout <= scr_vsize;
						4: io_dout <= scr_hbl_l;
						5: io_dout <= scr_hbl_r;
						6: io_dout <= scr_vbl_t;
						7: io_dout <= scr_vbl_b;
					endcase

				UIO_SET_VPOS:
					case(byte_cnt)
						1: shbl_l <= io_din[11:0];
						2: shbl_r <= io_din[11:0];
						3: svbl_t <= io_din[11:0];
						4: svbl_b <= io_din[11:0];
					endcase
			endcase
		end
	end
end

endmodule
