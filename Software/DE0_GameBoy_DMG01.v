module DE0_GameBoy_DMG01
(
	 clk_50, INPUT_SWS, INPUT_BTN, VGA_BUS_R, VGA_BUS_G, VGA_BUS_B, VGA_HS, VGA_VS,
	 OEA, OEB, OEC, OED, DIRA, GB_VSync, GB_PClk, GB_Data0, GB_Data1, GB_HSync
);

input		wire				clk_50;

input		wire	[9:0]		INPUT_SWS;
input		wire	[2:0]		INPUT_BTN;

output	reg	[3:0]		VGA_BUS_R;
output	reg	[3:0]		VGA_BUS_G;
output	reg	[3:0]		VGA_BUS_B;

output	reg	[0:0]		VGA_HS;
output	reg	[0:0]		VGA_VS;

			reg	[10:0]	X_pix;
			reg	[10:0]	Y_pix;
			
			reg	[10:0]	X_pix_old;
			reg	[10:0]	Y_pix_old;
			
			reg	[0:0]		H_visible;
			reg	[0:0]		V_visible;
			
			wire	[0:0]		pixel_clk;
			reg	[9:0]		pixel_cnt;
			
			reg	[11:0]	pixel_color;
			
			reg	[11:0]	pixel_line_buf[0:159];
			
			reg	[7:0]  	disp_mem_data;
			reg	[12:0]	read_addr;
			wire	[12:0]	SS_read_addr;
			reg	[12:0]	write_addr;
			reg	[0:0]		disp_mem_wren;
			
			wire	[7:0]		disp_mem_q;
			wire	[7:0]		SS_disp_mem_q;
			
			reg	[7:0]		cnt160;
			reg	[7:0]		cnt144;
			reg	[7:0]		mem144;
			
			reg	[12:0]	cntmem;
			
			reg	[3:0]		Y_cntpix;
			reg	[3:0]		X_cntpix;
			
			reg	[0:0]		V_blank;
			reg	[0:0]		H_blank;
			
			reg	[11:0]	GB_color_00;
			reg	[11:0]	GB_color_01;
			reg	[11:0]	GB_color_10;
			reg	[11:0]	GB_color_11;
			
output	reg	[0:0]		OEA;
output	reg	[0:0]		OEB;
output	reg	[0:0]		OEC;
output	reg	[0:0]		OED;

output	reg	[0:0]		DIRA;

input		wire	[0:0]		GB_VSync;
input		wire	[0:0]		GB_PClk;
input		wire	[0:0]		GB_Data0;
input		wire	[0:0]		GB_Data1;
input		wire	[0:0]		GB_HSync;

			reg	[7:0]		GB_Vcnt;
			reg	[7:0]		GB_Hcnt;
			reg	[159:0]	GB_Hbuff0;
			reg	[159:0]	GB_Hbuff1;
			
			reg	[12:0]	wcntmem;
			reg	[7:0]		wbuffcnt;
			
initial
	begin
		disp_mem_data 	<= 0;
		read_addr		<= 0;
		write_addr		<= 0;
		disp_mem_wren	<= 0;
		
		X_pix_old		<= 0;
		Y_pix_old		<= 0;
		
		pixel_color 	<= 0;
		cnt160			<= 0;	
		cnt144			<= 0;
		mem144			<= 0;
		cntmem			<= 0;
		wcntmem			<= 0;
		Y_cntpix			<= 0;
		X_cntpix			<= 0;
		
		GB_color_00		<= 0;
		GB_color_01		<= 0;
		GB_color_10		<= 0;
		GB_color_11		<= 0;
		
		OEA				<= 0;
		OEB				<= 1;
		OEC				<= 1;
		OED				<= 1;
		
		DIRA				<= 0;
		
	end
	
always @(posedge GB_PClk)
	begin
		if(GB_VSync == 1)
			begin
				GB_Vcnt <= 0;
				GB_Hcnt <= 0;
			end
		else
			begin
				if(GB_HSync == 1)
					begin
						GB_Vcnt <= GB_Vcnt + 1'b1;
						GB_Hcnt <= 0;
					end
				else
					begin
						GB_Hbuff0[GB_Hcnt] <= !GB_Data0;
						GB_Hbuff1[GB_Hcnt] <= !GB_Data1;
						GB_Hcnt <= GB_Hcnt + 1'b1;
					end
			end
	end

always @(posedge pixel_clk)
	begin
		if(GB_HSync == 1 && wcntmem < 160 && H_visible == 1)
			begin
				disp_mem_wren <= 1;
				wcntmem <= wcntmem + 1;
				write_addr <= wcntmem + (GB_Vcnt*40);
				wbuffcnt <= wbuffcnt + 4;
				disp_mem_data <= {GB_Hbuff0[wbuffcnt], GB_Hbuff1[wbuffcnt], GB_Hbuff0[wbuffcnt+1], GB_Hbuff1[wbuffcnt+1], GB_Hbuff0[wbuffcnt+2], GB_Hbuff1[wbuffcnt+2], GB_Hbuff0[wbuffcnt+3], GB_Hbuff1[wbuffcnt+3]};
			end
		else
			begin
				disp_mem_wren <= 0;
				wcntmem <= 0;
				wbuffcnt <= 0;
			end
	end
	
	
always @(posedge pixel_clk)
	begin
		if(Y_pix != Y_pix_old )
			begin
				Y_pix_old <= Y_pix;
				if (Y_pix < 7 || Y_pix > 1016)
					begin
						cnt144 <= 0;
						Y_cntpix <= 0;
						V_blank <= 1;
					end
				else
					begin
						if(Y_cntpix == 6)
							begin
								cnt144 <= cnt144;
								Y_cntpix <= 0;
								V_blank <= 0;
							end
						else if(Y_cntpix == 0 && Y_pix != 7)
							begin
								cnt144 <= cnt144 + 1'b1;
								Y_cntpix <= Y_cntpix + 1'b1;			
								V_blank <= 0;
							end
						else
							begin
								cnt144 <= cnt144;
								Y_cntpix <= Y_cntpix + 1'b1;
								V_blank <= 0;
							end
					end
			end
		else
			begin
				Y_pix_old <= Y_pix_old;
				Y_pix <= Y_pix;
				cnt144 <= cnt144;
				Y_cntpix <= Y_cntpix;
				V_blank <= V_blank;
			end
	end
	
always @(posedge pixel_clk)
	begin
		if(X_pix_old != X_pix)
			begin
				X_pix_old <= X_pix;
				if (X_pix < 79 || X_pix > 1200)
					begin
						X_cntpix <= 0;
						cnt160 <= 0;
						H_blank <= 1;
					end
				else
					begin
						if(X_cntpix == 6)
							begin
								cnt160 <= cnt160 + 1'b1;
								X_cntpix <= 0;
								H_blank <= 0;
							end
						else
							begin
								cnt160 <= cnt160;
								X_cntpix <= X_cntpix + 1'b1;
								H_blank <= 0;
							end
					end
			end
		else
			begin
				X_pix_old <= X_pix_old;
				X_pix <= X_pix;
				cnt160 <= cnt160;
				X_cntpix <= X_cntpix;
				H_blank <= H_blank;
			end
	end
	
always @(posedge pixel_clk)
	begin
		if(!H_visible)
			begin
				if(X_pix == 0)
					begin
						mem144 <= cnt144;
					end
				if(cntmem < 43)
					begin
						read_addr <= cntmem + (mem144*40);
						cntmem <= cntmem + 1;	

						if(disp_mem_q[7:6] == 2'b00)
							begin
								pixel_line_buf[((cntmem-3)*4)]	<= GB_color_00;
							end
						else if(disp_mem_q[7:6] == 2'b01)
							begin
								pixel_line_buf[((cntmem-3)*4)]	<= GB_color_01;
							end
						else if(disp_mem_q[7:6] == 2'b10)
							begin
								pixel_line_buf[((cntmem-3)*4)]	<= GB_color_10;
							end
						else
							begin
								pixel_line_buf[((cntmem-3)*4)]	<= GB_color_11;
							end
							
						if(disp_mem_q[5:4] == 2'b00)
							begin
								pixel_line_buf[((cntmem-3)*4)+1]	<= GB_color_00;
							end
						else if(disp_mem_q[5:4] == 2'b01)
							begin
								pixel_line_buf[((cntmem-3)*4)+1]	<= GB_color_01;
							end
						else if(disp_mem_q[5:4] == 2'b10)
							begin
								pixel_line_buf[((cntmem-3)*4)+1]	<= GB_color_10;
							end
						else
							begin
								pixel_line_buf[((cntmem-3)*4)+1]	<= GB_color_11;
							end
							
						if(disp_mem_q[3:2] == 2'b00)
							begin
								pixel_line_buf[((cntmem-3)*4)+2]	<= GB_color_00;
							end
						else if(disp_mem_q[3:2] == 2'b01)
							begin
								pixel_line_buf[((cntmem-3)*4)+2]	<= GB_color_01;
							end
						else if(disp_mem_q[3:2] == 2'b10)
							begin
								pixel_line_buf[((cntmem-3)*4)+2]	<= GB_color_10;
							end
						else
							begin
								pixel_line_buf[((cntmem-3)*4)+2]	<= GB_color_11;
							end
							
						if(disp_mem_q[1:0] == 2'b00)
							begin
								pixel_line_buf[((cntmem-3)*4)+3]	<= GB_color_00;
							end
						else if(disp_mem_q[1:0] == 2'b01)
							begin
								pixel_line_buf[((cntmem-3)*4)+3]	<= GB_color_01;
							end
						else if(disp_mem_q[1:0] == 2'b10)
							begin
								pixel_line_buf[((cntmem-3)*4)+3]	<= GB_color_10;
							end
						else
							begin
								pixel_line_buf[((cntmem-3)*4)+3]	<= GB_color_11;
							end
					end
			end
		else
			begin
				cntmem <= 0;

				read_addr <= ((cnt144+1)*40);	
			end
	end

always @(posedge pixel_clk)
	begin
		if(Y_pix == 0 && INPUT_SWS[1] == 0)
			begin
				pixel_color <= 12'b1111_1111_1111;
			end
		else if(Y_pix == 6 && INPUT_SWS[1] == 0)
			begin
				pixel_color <= 12'b1111_1111_1111;
			end
		else if (Y_pix == 1016 && INPUT_SWS[1] == 0)
			begin
				pixel_color <= 12'b1111_1111_1111;
			end
		else if (Y_pix == 1023 && INPUT_SWS[1] == 0)
			begin
				pixel_color <= 12'b1111_1111_1111;
			end
		else if (X_pix == 0 && INPUT_SWS[1] == 0)
			begin
				pixel_color <= 12'b1111_1111_1111;
			end
		else if (X_pix == 79 && INPUT_SWS[1] == 0)
			begin
				pixel_color <= 12'b1111_1111_1111;
			end
		else if (X_pix == 1199 && INPUT_SWS[1] == 0)
			begin
				pixel_color <= 12'b1111_1111_1111;
			end
		else if (X_pix == 1279 && INPUT_SWS[1] == 0)
			begin
				pixel_color <= 12'b1111_1111_1111;
			end
		else if (V_blank == 1 || H_blank == 1)
			begin
				pixel_color <= 12'b0000_0000_0000;
			end
		else
			begin
				pixel_color <= pixel_line_buf[cnt160];
			end
	end
	
	
always @(posedge pixel_clk)
	begin
		if(INPUT_SWS[0] == 0 && !V_visible && !H_visible)
			begin
				GB_color_00		<= 12'b0001_0001_0001;
				GB_color_01		<= 12'b0011_0011_0011;
				GB_color_10		<= 12'b0111_0111_0111;
				GB_color_11		<= 12'b1111_1111_1111;
			end
		else if(INPUT_SWS[0] == 1 && !V_visible && !H_visible)
			begin
				GB_color_00		<= 12'b0001_0100_0011;
				GB_color_01		<= 12'b0001_0111_0101;
				GB_color_10		<= 12'b0001_1010_1001;
				GB_color_11		<= 12'b0010_1111_1110;		
			end
		else
			begin
				GB_color_00		<= GB_color_00;
				GB_color_01		<= GB_color_01;
				GB_color_10		<= GB_color_10;
				GB_color_11		<= GB_color_11;			
			end
	end
					
			
		DE0_VGA VGA_Driver
		(
			.clk_50(clk_50),
			.pixel_color(pixel_color),
			.VGA_BUS_R(VGA_BUS_R), 
			.VGA_BUS_G(VGA_BUS_G), 
			.VGA_BUS_B(VGA_BUS_B), 
			.VGA_HS(VGA_HS), 
			.VGA_VS(VGA_VS), 
			.X_pix(X_pix), 
			.Y_pix(Y_pix), 
			.H_visible(H_visible),
			.V_visible(V_visible), 
			.pixel_clk(pixel_clk),
			.pixel_cnt(pixel_cnt)
		);
		
		DISP_RAM RAM_Driver
		(
			.clock(pixel_clk),
			.data(disp_mem_data),
			.rdaddress(read_addr),
			.wraddress(write_addr),
			.wren(disp_mem_wren),
			.q(disp_mem_q)
		);
		
		ScreenShot_RAM ScreenShot_RAM_Driver
		(
			.clock(pixel_clk),
			.data(disp_mem_data),
			.rdaddress(SS_read_addr),
			.wraddress(write_addr),
			.wren(disp_mem_wren),
			.q(SS_disp_mem_q)
		);
		
endmodule