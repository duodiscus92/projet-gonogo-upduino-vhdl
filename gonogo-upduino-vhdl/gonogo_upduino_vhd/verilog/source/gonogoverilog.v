module blinky (
	input clk,			// 12 MHz clock
	input sw_reset,			// reset switch
	input sel_go,			// selection second/minutes for go
	input sel_nogo,			// selection second/minutes for nogo
	input [NBITS-1:0] sw_go,	// switches for go duration
	input [NBITS-1:0] sw_nogo,	// switches for nogo duration
	input sw_led_enable,		// if == 0 led don't blink so reduce consumption
	//output wire led_blue,		   led seconds 
	//output wire led_green,	   led minute
	output wire led_red,		// led gonogo
	output wire gonogo,		// pin gonogo
	output wire second,		// pin seconds
	output wire minute);		// pin minutes 


parameter NBITS = 12;	

/////////////////////////////////
// Reset and led enable
/////////////////////////////////
reg rst, led_enable;
always @(*) begin
  if(sw_reset) rst <= 1'd0; else rst <= 1'd1;
  //if(sw_led_enable) led_enable <= 1'b0; else led_enable <= 1'b1; 
end

/////////////////////////////////
// Tick counter
/////////////////////////////////
// review tick counter design if leaving this range
// initial assert (CLOCK_MHZ > 64 && CLOCK_MHZ < 250);
parameter CLOCK_MHZ = 12;
reg [4:0] tick_cntr;
reg tick_cntr_max;

always @(posedge clk) begin
	if (rst) begin
		tick_cntr <= 0;
		tick_cntr_max <= 0;
	end
	else begin
		if (tick_cntr_max) tick_cntr <= 1'b0;
		else tick_cntr <= tick_cntr + 1'b1;
		tick_cntr_max <= (tick_cntr == (CLOCK_MHZ - 2'd2));
	end
end

/////////////////////////////////
// Count off 1000 us to form 1 ms
/////////////////////////////////
reg [9:0] usecond_cntr;
reg usecond_cntr_max;

always @(posedge clk) begin
	if (rst) begin
		usecond_cntr <= 0;
		usecond_cntr_max <= 0;
	end
	else if (tick_cntr_max) begin
		if (usecond_cntr_max) usecond_cntr <= 1'b0;
		else usecond_cntr <= usecond_cntr + 1'b1;
		usecond_cntr_max <= (usecond_cntr == 10'd998);
	end
end

assign msecond = usecond_cntr[9];

/////////////////////////////////
// Count off 1000 ms to form 1 s
/////////////////////////////////
reg [9:0] msecond_cntr;
reg msecond_cntr_max;

always @(posedge clk) begin
	if (rst) begin
		msecond_cntr <= 0;
		msecond_cntr_max <= 0;
	end
	else if (usecond_cntr_max & tick_cntr_max) begin
		if (msecond_cntr_max) msecond_cntr <= 1'b0;
		else msecond_cntr <= msecond_cntr + 1'b1;
		msecond_cntr_max <= (msecond_cntr == 10'd998);
	end
end

//assign led_blue = msecond_cntr[9];
assign second = msecond_cntr[9];

/////////////////////////////////
// Count off 60s to form 1 m
/////////////////////////////////
reg [5:0] second_cntr;
reg second_cntr_max;

always @(posedge clk) begin
	if (rst) begin
		second_cntr <= 0;
		second_cntr_max <= 0;
	end
	else if (msecond_cntr_max & usecond_cntr_max & tick_cntr_max) begin
		if (second_cntr_max) second_cntr <= 1'b0;
		else second_cntr <= second_cntr + 1'b1;
		second_cntr_max <= (second_cntr == 6'd58);
	end
end

assign minute = second_cntr[5];
//assign led_green = second_cntr[5];

/////////////////////////////////
// Mux to select seconds or minutes clk
/////////////////////////////////
reg clk_go, clk_nogo;
always @(*) begin
if(sel_nogo) clk_nogo <= second & msecond_cntr_max; else clk_nogo <= minute & second_cntr_max & msecond_cntr_max;
end
always @(*) begin
if(sel_go) clk_go <= second & msecond_cntr_max; else clk_go <= minute & second_cntr_max & msecond_cntr_max;
end

/////////////////////////////////
// GO and NOGO counter
/////////////////////////////////
parameter GO = 1'b1, NOGO = 1'b0;
reg [NBITS-1:0] cntr_go; 
reg [NBITS-1:0] cntr_nogo;
reg toggle_gonogo;

always @(posedge clk) begin
	if (rst) begin
		cntr_go = 0;
		cntr_nogo = 0;
		toggle_gonogo = GO;
	end

	if((toggle_gonogo == GO) & clk_go /*& second_cntr_max & msecond_cntr_max*/ & usecond_cntr_max & tick_cntr_max) begin
	   cntr_go = cntr_go + 1'b1;
		if (cntr_go == sw_go) begin
		   toggle_gonogo = NOGO;
		   cntr_go = 0;
		end
	end

   else if (/*(toggle_gonogo == NOGO) &*/ clk_nogo /*& second_cntr_max & msecond_cntr_max*/ & usecond_cntr_max & tick_cntr_max) begin
	   cntr_nogo = cntr_nogo + 1'b1;
		if (cntr_nogo == sw_nogo) begin
		   toggle_gonogo = GO;
		   cntr_nogo = 0;
		end
	end
end

assign led_red = toggle_gonogo & sw_led_enable;
assign gonogo = toggle_gonogo;
/*
assign swgo3 = sw_go[3];
assign swgo2 = sw_go[2];
assign swgo1 = sw_go[1];
assign swgo0 = sw_go[0];
assign swnogo3 = sw_nogo[3];
assign swnogo2 = sw_nogo[2];
assign swnogo1 = sw_nogo[1];
assign swnogo0 = sw_nogo[0];
*/
endmodule
