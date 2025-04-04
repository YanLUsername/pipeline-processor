`timescale 1ns / 1ps

module EX_pipe_stage(
    input [31:0] id_ex_instr,
    input [31:0] reg1, reg2,
    input [31:0] id_ex_imm_value,
    input [31:0] ex_mem_alu_result,
    input [31:0] mem_wb_write_back_result,
    input id_ex_alu_src,
    input [1:0] id_ex_alu_op,
    input [1:0] Forward_A, Forward_B,
    output [31:0] alu_in2_out,
    output [31:0] alu_result
    );
    
    // Write your code here
    wire [31:0] reg1MuxOut;
    wire [31:0] ALUMuxOut;
    
    // reg 1 mux
    mux4 #(32) reg1Mux(
        .a(reg1),
        .b(mem_wb_write_back_result),
        .c(ex_mem_alu_result),
        .d(32'b0),
        .sel(Forward_A),
        .y(reg1MuxOut)
    );
    
    // reg 2 mux
    mux4 #(32) reg2Mux(
        .a(reg2),
        .b(mem_wb_write_back_result),
        .c(ex_mem_alu_result),
        .d(32'b0),
        .sel(Forward_B),
        .y(alu_in2_out)
    );
    
    // ALU mux
    mux2 #(32) ALUmux (
        .a(alu_in2_out),
        .b(id_ex_imm_value),
        .sel(id_ex_alu_src),
        .y(ALUMuxOut)
    );
    
    wire [3:0] ALU_Control;
    wire zero;
    
    //ALUControl Module
    ALUControl ALUControl(
        .ALUOp(id_ex_alu_op), 
        .Function(id_ex_instr[5:0]),
        .ALU_Control(ALU_Control)
    );
    
    // ALU module
    ALU ALU(
        .a(reg1MuxOut),
        .b(ALUMuxOut), 
        .alu_control(ALU_Control),
        .zero(zero),
        .alu_result(alu_result)
    );
endmodule
