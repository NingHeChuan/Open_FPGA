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
// 2018/4/17    NingHeChuan       1.0                     Original
//  
// *********************************************************************************

`include "Sdram_Para.v"

module Sdram_Read
#(  parameter   DATA_WIDTH  =   16,
    parameter   ADDR_WIDTH  =   12,
    parameter   ROW_DEPTH   =   2,
    parameter   COL_DEPTH   =   256,
    parameter   BURST_LENGTH =   4,       //burst length
    parameter   ACT_DEPTH    =  1,
    parameter   BREAK_PRE   =   1
)
(
    input                       clk,
    input                       rst_n,
    input                       rd_trig,
    input                       rd_en,
    input                       ref_rq,
    output          reg [3:0]   rd_cmd,
    output          reg [ADDR_WIDTH - 1:0]  rd_addr,
    output                      rd_rq,
    output          reg         rd_end_flag,
    output              [1:0]   rd_bank_addr,
    input               [DATA_WIDTH - 1:0]  rd_data,
    //rfifo signal
    output                      rfifo_wr_en,
    output              [7:0]   rfifo_wr_data
);

//-------------------------------------------------------
reg     [1:0]   break_cnt;

reg     [3:0]   act_cnt;
reg             act_end;

wire            rfifo_wr_flag;

reg             rd_end;
reg             rd_flag;
reg     [5:0]   col_cnt;
reg     [1:0]   burst_cnt;
reg     [1:0]   burst_cnt_t;

reg            row_end;
wire     [7:0]  col_addr;
reg     [ADDR_WIDTH - 1:0]  row_addr;

//state machine
reg     [4:0]   pre_state;
reg     [4:0]   next_state;

//-------------------------------------------------------
//step 1
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        pre_state <= `S_IDLE;
    else 
        pre_state <= next_state;
end

//-------------------------------------------------------
//step 2
always @(*)begin
    if(rst_n == 1'b0)
        next_state = `S_IDLE;
    else begin
        case(pre_state)
        `S_IDLE:begin
            if(rd_trig == 1'b1)
                next_state = `S_RREQ;
            else 
                next_state = `S_IDLE;
        end
        `S_RREQ:begin
            if(rd_en == 1'b1)
                next_state = `S_ACTROW;
            else 
                next_state = `S_RREQ;
        end
        `S_ACTROW:begin
            //if(act_end == 1'b1)
                next_state = `S_READ;
           // else 
                //next_state = S_ACTROW;
        end
        `S_READ:begin
            if(rd_end == 1'b1)
                next_state = `S_PREGE;
            else if(ref_rq == 1'b1 && burst_cnt == BURST_LENGTH - 1'b1 && rd_flag == 1'b1)
                next_state <= `S_PREGE;
            else if(row_end == 1'b1)
                next_state <= `S_PREGE;
            else
                next_state = `S_READ;
        end
        `S_PREGE:begin
            if(break_cnt == BREAK_PRE - 1'b1 && ref_rq == 1'b1 && rd_flag == 1'b1)
                next_state = `S_RREQ;
            else if(rd_flag == 1'b1 && rd_end == 1'b0 && ref_rq == 1'b0 && break_cnt == BREAK_PRE - 1'b1)
                next_state = `S_ACTROW;
            else if(break_cnt == BREAK_PRE - 1'b1)
                next_state = `S_IDLE;
        end
        default:
            next_state = `S_IDLE;
        endcase
    end
end

//-------------------------------------------------------
//rd_cmd
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        rd_cmd <= `CMD_NOP;
    else begin
        case(next_state)
        `S_IDLE: rd_cmd <= `CMD_NOP;
        `S_ACTROW:rd_cmd <= `CMD_ACT;
        `S_READ: begin
            if(burst_cnt == 'd0)
                rd_cmd <= `CMD_READ;
            else 
               rd_cmd <= `CMD_NOP;
       end
        `S_PREGE:begin
            if(break_cnt == 'd0)
                rd_cmd <= `CMD_PREGE;
            else 
                rd_cmd <= `CMD_NOP;
        end
        default: rd_cmd <= `CMD_NOP;
        endcase
    end
end
//-------------------------------------------------------
//rd_addr
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        rd_addr <= 12'd0;
    else begin
        case(next_state)
        `S_ACTROW: begin
                if(act_cnt == 'd0)
                    rd_addr <= row_addr;
                else
                    rd_addr <= 12'b0000_0000_0000;
            end
        `S_READ: rd_addr <= {3'b000, col_addr};
        `S_PREGE: rd_addr <= 12'b0100_0000_0000;
        default: rd_addr <= 12'b0000_0000_0000;
        endcase
    end
end
//-------------------rd_rq------------------------------------
//break_cnt 
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		break_cnt <= 'd0;
	else if(next_state == `S_PREGE)
		break_cnt <= break_cnt + 1'b1;
	else 
		break_cnt <= 'd0;
end

//-------------------------------------------------------
//rd_rq
/*always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        rd_rq <= 1'b0;
    else if(pre_state == `S_RREQ)
        rd_rq <= 1'b1;
    else
        rd_rq <= 1'b0;
end*/
assign  rd_rq = (pre_state == `S_RREQ)? 1'b1: 1'b0;

//-------------------------------------------------------
//act_cnt
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        act_cnt <= 4'd0;
    else if(next_state == `S_ACTROW)
        act_cnt <= act_cnt + 1'b1;
    else
        act_cnt <= 4'd0;
end
//-------------------------------------------------------
//act_end
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        act_end <= 1'b0;
    else if(act_cnt == 3'd1)
        act_end <= 1'b1;
    else 
        act_end <= 1'b0;
end

//-------------------------------------------------------
//rd_flag
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        rd_flag <= 1'b0;
    else if(rd_en == 1'b1)
        rd_flag <= 1'b1;
    else if(col_addr == COL_DEPTH - 1'b1 && row_addr == ROW_DEPTH - 1'b1)
        rd_flag <= 1'b0;
end

//-------------------------------------------------------
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        burst_cnt <= 2'd0;
    else if(burst_cnt == BURST_LENGTH - 1'b1)
        burst_cnt <= 2'd0;
    else if(next_state == `S_READ)
        burst_cnt <= burst_cnt + 1'b1;
    else
        burst_cnt <= burst_cnt;
end

//-------------------------------------------------------
//col_cnt
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        col_cnt <= 6'd0;
    else if(col_addr == COL_DEPTH - 1'b1)
        col_cnt <= 6'd0;
    else if(burst_cnt == BURST_LENGTH - 1'b1)
        col_cnt <= col_cnt + 1'b1;
    else
        col_cnt <= col_cnt;
end

assign  col_addr = {col_cnt, burst_cnt};
//assign  row_end =   (col_addr == COL_DEPTH - 1)? 1'b1: 1'b0;

always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        row_end <= 1'b0;
    else if(col_addr == COL_DEPTH - 1)
        row_end <= 1'b1;
    else 
        row_end <= 1'b0;
end
//-------------------------------------------------------
//row_addr
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        row_addr <= 12'd0;
    else if(row_end == 1'b1)
        row_addr <= row_addr + 1'b1;
    else 
        row_addr <= row_addr;
end

//-------------------------------------------------------
//rd_end
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        rd_end <= 1'b0;
    else if(ref_rq == 1'b1 && burst_cnt == BURST_LENGTH - 1'b1)
        rd_end <= 1'b1;
    else if(col_addr == COL_DEPTH - 1'b1 && row_addr == ROW_DEPTH - 1'b1)
        rd_end <= 1'b1;
    else
        rd_end <= 1'b0;
end

//-------------------------------------------------------
//rd_end delay 2clk
reg     rd_end_flag_r;
always  @(posedge clk)begin
    if(rst_n == 1'b0)begin
        rd_end_flag_r <= 1'b0;
        rd_end_flag <= 1'b0;
    end
    else begin
        rd_end_flag_r <= rd_end;
        rd_end_flag <= rd_end_flag_r;
    end
end

//----------------------------------------------------
//burst_cnt delay 1clk
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        burst_cnt_t <= 1'b0;
    else
        burst_cnt_t <= burst_cnt;
end

//-------------------------------------------------------
reg     [3:0]   rfifo_wr_en_r;
always @(posedge clk or negedge rst_n)begin
    if(rst_n == 1'b0)
        rfifo_wr_en_r <= 'b0;
    else
        rfifo_wr_en_r <= {rfifo_wr_en_r[2:0],rfifo_wr_flag};
end

//-------------------------------------------------------
assign  rfifo_wr_data   =   rd_data[7:0];
assign  rfifo_wr_flag   =   (pre_state == `S_READ)? 1'b1: 1'b0;
assign  rfifo_wr_en     =  rfifo_wr_en_r[3];
assign  rd_bank_addr = 2'b00;

endmodule
