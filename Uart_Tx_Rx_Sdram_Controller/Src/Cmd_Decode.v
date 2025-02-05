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

module Cmd_Decode
#(
    parameter   REC_NUM     =   4
)
(
    input                   clk,
    input                   rst_n,
    input                   rx_done,
    input           [7:0]   uart_data,

    output     reg              wr_trig,
    output     reg              rd_trig,
    output     reg          wfifo_wr_en,
    output          [7:0]   wfifo_data
);


reg     [3:0]   rec_num;
reg     [7:0]   wr_cmd;

//-------------------------------------------------------
//rec_num
always  @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        rec_num <= 'd0;
    else if(wr_cmd == 'h55 && rec_num == 'd0 && rx_done == 1'b1)
        rec_num <= 'd0;
    else if(rec_num == REC_NUM && rx_done == 1'b1)
        rec_num <= 'd0;
    else if(rx_done == 1'b1)
        rec_num <= rec_num + 1'b1;
    else 
        rec_num <= rec_num;
end

//-------------------------------------------------------
//wr_cmd
always  @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        wr_cmd <= 'd0;
    else if(rx_done == 1'b1 && rec_num == 'd0)
        wr_cmd <= uart_data;
    else
        wr_cmd <= wr_cmd;
end
//-------------------------------------------------------
//wfifo_wr_en
always  @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        wfifo_wr_en <= 1'b0;
    else if(wr_cmd == 'h55 && rec_num > 'd0)
        wfifo_wr_en <= rx_done;
    else
        wfifo_wr_en <= 1'b0;
end
//-------------------------------------------------------
//wr_trig
always  @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        wr_trig <= 1'b0;
    else if(wr_cmd == 'h55 && rx_done == 1'b1 && rec_num == REC_NUM)
        wr_trig <= 1'b1;
    else 
        wr_trig <= 1'b0;
end
//-------------------------------------------------------
//rd_trig
always  @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        rd_trig <= 1'b0;
    else if(uart_data == 'haa && rx_done == 1'b1)
        rd_trig <= 1'b1;
    else
        rd_trig <= 1'b0;
end


assign  wfifo_data  =   (wfifo_wr_en == 1'b1)? uart_data: 'd0;
//assign  wr_trig     =   (wr_cmd == 'h55 && rec_num == 'd0)? rx_done: 1'b0;
//assign  rd_trig     =   (wr_cmd == 'haa && rec_num == 'd0)? rx_done: 1'b0;


endmodule
