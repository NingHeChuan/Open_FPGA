`timescale      1ns/1ps
// *********************************************************************************
// Project Name :       
// Author       : NingHeChuan
// Email        : ninghechuan@foxmail.com
// Blogs        : http://www.cnblogs.com/ninghechuan/
// File Name    : .v
// Module Name  :
// Called By    :
// Abstract     :
//
// CopyRight(c) 2018, NingHeChuan Studio.. 
// All Rights Reserved
//
// *********************************************************************************
// Modification History:
// Date         By              Version                 Change Description
// -----------------------------------------------------------------------
// 2018/4/20    NingHeChuan       1.0                     Original
//  
// *********************************************************************************

module Uart_Byte_Rx(
	input 				clk,//50Mhz
	input 				rst_n,
	input 		[3:0]	baud_set,
	input 				rs232_rx,
	output 	reg 		uart_state,
	output	reg 		rx_done,
	output 	reg [7:0] 	data_byte
    );

reg [15:0] 	bps_DR;//2“足??那2谷?辰
reg [7:0]	bps_cnt;//﹞??米??那y,?車那???那y那?﹞⊿?赤??那y米?16㊣?
reg 		bps_clk;//﹞??米那㊣?車
reg [15:0] 	div_cnt;//﹞??米??那y
reg 		s0_rs232_rx, s1_rs232_rx;//赤?2???∩??‾㏒???3y???豕足?
reg 		tmp0_rs232_rx, tmp1_rs232_rx;//那y?Y??∩??‾
wire 		nedege;//?足2a?e那???,???米???足2a
reg [2:0] 	r_data_byte [7:0];//㊣赤那?8?????赤?a3米???∩??‾
reg [2:0] 	START_BIT, STOP_BIT;

//2“足??那2谷?辰㊣赤
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		bps_DR <= 0;	
	else begin
		case(baud_set)
		//0: bps_DR <= 324;//bps_9600x16
		0: bps_DR <= 1;//bps_9600x16 just for test
		1: bps_DR <= 162;//bps_19200x16
		2: bps_DR <= 80;//bps_38400x16
		3: bps_DR <= 53;//bps_57600x16
		4: bps_DR <= 26;//bps_115200x16
		default: bps_DR <= 324;//bps_9600x16
		endcase
	end
end	 

//﹞??米2“足??那那㊣?車
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		bps_clk <= 0;
		div_cnt <= 0;
	end
	else if(uart_state)begin
		if(div_cnt == bps_DR) begin
			bps_clk <= 1;
			div_cnt <= 0;
		end
		else begin
			bps_clk <= 0;
			div_cnt <= div_cnt + 1;
		end
	end
end

//bps_cnt
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		bps_cnt <= 0;
	else if(rx_done || (bps_cnt == 12) && (START_BIT > 2))
		bps_cnt <= 0;
	else begin
		if (bps_cnt == 159)
			bps_cnt <= 0;
		else if(bps_clk)
			bps_cnt <= bps_cnt + 1;
		else 
			bps_cnt <= bps_cnt;
	end
end

//?e那????足2a??3足㏒???那y?Y赤?2?∩|角赤,角?車???3y???豕足?米?﹞?﹞“
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		s0_rs232_rx <= 0;
		s1_rs232_rx <= 0;
	end
	else begin
		s0_rs232_rx <= rs232_rx;
		s1_rs232_rx <= s0_rs232_rx;
	end
end

//那y?Y??∩??‾
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		tmp0_rs232_rx <= 0;
		tmp1_rs232_rx <= 0;
	end
	else begin
		tmp0_rs232_rx <= s1_rs232_rx;
		tmp1_rs232_rx <= tmp0_rs232_rx;
	end
end

assign nedege = !tmp0_rs232_rx & tmp1_rs232_rx;//???米???足2a

//?芍那?D?o?rx_done
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		rx_done <= 0;
	else if(bps_cnt == 159)
		rx_done <= 1;
	else
		rx_done <= 0;
end

//那y?Y?芍豕?
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		START_BIT <= 0;//?e那???
		r_data_byte[0] <= 3'b0;
		r_data_byte[1] <= 3'b0;
		r_data_byte[2] <= 3'b0;
		r_data_byte[3] <= 3'b0;
		r_data_byte[4] <= 3'b0;
		r_data_byte[5] <= 3'b0;
		r_data_byte[6] <= 3'b0;
		r_data_byte[7] <= 3'b0;
		STOP_BIT <= 0;//?芍那???
	end
	else if(bps_clk)begin
		case(bps_cnt)
		0:begin
			START_BIT <= 0;//?e那???
			r_data_byte[0] <= 3'b0;
			r_data_byte[1] <= 3'b0;
			r_data_byte[2] <= 3'b0;
			r_data_byte[3] <= 3'b0;
			r_data_byte[4] <= 3'b0;
			r_data_byte[5] <= 3'b0;
			r_data_byte[6] <= 3'b0;	
			r_data_byte[7] <= 3'b0;
			STOP_BIT <= 0;//?芍那???
		end
		5,6,7,8,9,10:START_BIT <= START_BIT + s1_rs232_rx;
		21,22,23,24,25,26:r_data_byte[0] <= r_data_byte[0] + s1_rs232_rx;
		37,38,39,40,41,42:r_data_byte[1] <= r_data_byte[1] + s1_rs232_rx;
		53,54,55,56,57,58:r_data_byte[2] <= r_data_byte[2] + s1_rs232_rx;
		69,70,71,72,73,74:r_data_byte[3] <= r_data_byte[3] + s1_rs232_rx;
		85,86,87,88,89,90:r_data_byte[4] <= r_data_byte[4] + s1_rs232_rx;
		101,102,103,104,105,106:r_data_byte[5] <= r_data_byte[5] + s1_rs232_rx;
		117,118,119,120,121,122:r_data_byte[6] <= r_data_byte[6] + s1_rs232_rx;
		133,134,135,136,137,138:r_data_byte[7] <= r_data_byte[7] + s1_rs232_rx;
		149,150,151,152,153,154:STOP_BIT <= STOP_BIT + s1_rs232_rx;
		default:;
		endcase
	end
end

//那y?Y那?3?
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		data_byte <= 8'b0;
	end
	else if(bps_cnt == 159)begin
		data_byte[0] <= r_data_byte[0][2];
		data_byte[1] <= r_data_byte[1][2];
		data_byte[2] <= r_data_byte[2][2];
		data_byte[3] <= r_data_byte[3][2];
		data_byte[4] <= r_data_byte[4][2];
		data_byte[5] <= r_data_byte[5][2];
		data_byte[6] <= r_data_byte[6][2];
		data_byte[7] <= r_data_byte[7][2];
	end
end

//UART_state?a1那???那??|㏒?0???D
always @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		uart_state <= 1'b0;	
	else if(rx_done)
		uart_state <= 1'b0;	
	else if(nedege)
		uart_state <= 1'b1;
	else 
		uart_state <= uart_state;
end
	
endmodule 
