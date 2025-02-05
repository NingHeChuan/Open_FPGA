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
// 2018/4/16    NingHeChuan       1.0                     Original
//  
// *********************************************************************************
`include "Sdram_Para.v"
module Sdram_Init
#(  parameter   ADDR_WIDTH  =   12
)
(
    input                   clk,
    input                   rst_n,
    output          [11:0]  sdram_addr,
    output      reg [3:0]   sdram_cmd,
    output                  init_end

);
//-------------------------------------------------------
/*
                cs_n    ras_n   cas_n   we_n
CMD_PREGE       0       0       1       0
CMD_A_REF    0       0       0       1
CMD_NOP             0       1       1       1
CMD_MRS    0       0       0       0  

burst length = 4    addr    =   12'b0000_0110_0010
*/

localparam       DELAY_200US     =   18'd10000;

reg     [13:0]  cnt_200us;
reg     [5:0]   cnt_cmd;

//-------------------------------------------------------
//cnt_200us
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        cnt_200us <= 13'd0;
    else if(cnt_200us == DELAY_200US - 1'b1)
        cnt_200us <= cnt_200us;
    else
        cnt_200us <= cnt_200us + 1'b1;
end

//-------------------------------------------------------
//cnt_cmd
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        cnt_cmd <= 4'd0;
    else if(init_end == 1'b1)
        cnt_cmd <= cnt_cmd;
    else if(cnt_200us == DELAY_200US - 1'b1)
        cnt_cmd <= cnt_cmd + 1'b1;
    else
        cnt_cmd <= cnt_cmd;
end

//-------------------------------------------------------
//sdram_cmd ��ˢ�°˴�
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        sdram_cmd <= `CMD_NOP;
    else if(cnt_200us == DELAY_200US - 1'b1)begin
        case(cnt_cmd)
        6'd0: sdram_cmd <= `CMD_PREGE;
        6'd1: sdram_cmd <= `CMD_A_REF;
        6'd5: sdram_cmd <= `CMD_A_REF;
        6'd9: sdram_cmd <= `CMD_A_REF;
        6'd13:sdram_cmd <= `CMD_A_REF;
        6'd17:sdram_cmd <= `CMD_A_REF;
        6'd21:sdram_cmd <= `CMD_A_REF;
        6'd25:sdram_cmd <= `CMD_A_REF;
        6'd29:sdram_cmd <= `CMD_A_REF;
        6'd33:sdram_cmd <= `CMD_MRS;
        default: sdram_cmd <= `CMD_NOP;
        endcase
    end
end

//-------------------------------------------------------
assign  init_end = (cnt_cmd > 6'd34)? 1'b1: 1'b0;
assign  sdram_addr = (sdram_cmd == `CMD_MRS)? 12'b0000_0011_0010: 12'b0100_0000_0000;



endmodule
