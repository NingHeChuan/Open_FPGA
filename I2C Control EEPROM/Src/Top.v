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
// 2018/7/29    NingHeChuan       1.0                     Original
//  
// *********************************************************************************

module Top(
    input                   clk,    //50Mhz
    input                   rst_n,
    //IIC Signal
    inout                   i2c_sdat,
    output                  i2c_sclk,
    //Seg Signal
    output       [6:0]      out,
    output                  dp,
	output       [3:0]      an,      //所有的数码管的使能端
    //Other Signal
    input                   wr_en,
    input                   rd_en
); 

//
wire    [31:0]  eeprom_config_data;
wire            i2c_start;              //1 valid
wire            i2c_done;
wire    [7:0]   i2c_rd_data; 

Ctrl_I2C_Op Ctrl_I2C_Op_inst(
    .clk                    (clk               ),
    .rst_n                  (rst_n             ),
    .wr_en                  (wr_en             ),
    .rd_en                  (rd_en             ),
    .i2c_done               (i2c_done          ),
    .i2c_start              (i2c_start         ),
    .eeprom_config_data     (eeprom_config_data)
);

//-------------------------------------------------------
//I2C_Ctrl_EEPROM
I2C_Ctrl_EEPROM I2C_Ctrl_EEPROM_inst(
    .clk                    (clk               ),
    .rst_n                  (rst_n             ),
    .eeprom_config_data     (eeprom_config_data),
    .i2c_start              (i2c_start         ),          //1 valid
    .i2c_sdat               (i2c_sdat          ),
    .i2c_sclk               (i2c_sclk          ),
    .i2c_done               (i2c_done          ),
    .i2c_rd_data            (i2c_rd_data       )
);


//-------------------------------------------------------
//Seven_Seg_Display
Seven_Seg_Display Seven_Seg_Display_inst(
    .clk                (clk       ),
    .rst_n              (rst_n     ),
    .data_four          (4'b0 ),
    .data_three         (4'b0),
    .data_two           (i2c_rd_data[7:4]  ),
    .data_one           (i2c_rd_data[3:0]  ),
    .out                (out       ),
    .an                 (an        ),//所有的数码管的使能端
    .dp                 (dp        )
    );

endmodule
