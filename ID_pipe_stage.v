`timescale 1ns / 1ps

module ID_pipe_stage(
    input  clk, reset,
    input  [9:0] pc_plus4,
    input  [31:0] instr,
    input  mem_wb_reg_write,
    input  [4:0] mem_wb_write_reg_addr,
    input  [31:0] mem_wb_write_back_data,
    input  Data_Hazard,
    input  Control_Hazard,
    output [31:0] reg1, reg2,
    output [31:0] imm_value,
    output [9:0] branch_address,
    output [9:0] jump_address,
    output branch_taken,
    output [4:0] destination_reg, 
    output mem_to_reg,
    output [1:0] alu_op,
    output mem_read,  
    output mem_write,
    output alu_src,
    output reg_write,
    output jump
    );
    
    // write your code here 
    // Remember that we test if the branch is taken or not in the decode stage. 	
    wire [6:0] ctrlOut;
    wire [6:0] muxOut;
  
    // Control
    wire regDst;
    wire branch;
    control Control(
        .reset(reset),
        .opcode(instr[31:26]), 
        .reg_dst(regDst),
        .mem_to_reg(ctrlOut[6]), 
        .alu_op(ctrlOut[5:4]),  
        .mem_read(ctrlOut[3]), 
        .mem_write(ctrlOut[2]),
        .alu_src(ctrlOut[1]), 
        .reg_write(ctrlOut[0]),
        .branch(branch),
        .jump(jump) 
    );
    
    // Control mux
    mux2 #(7) ctrlMux(   
        .a(ctrlOut),
        .b(7'b000000),
        .sel((!Data_Hazard) || Control_Hazard),
        .y(muxOut)
    );

    // Control mux output
    assign mem_to_reg = muxOut[6];
    assign alu_op = muxOut[5:4];
    assign mem_read = muxOut[3];
    assign mem_write = muxOut[2];
    assign alu_src = muxOut[1];
    assign reg_write = muxOut[0];

    // jump_address
    assign jump_address = instr[25:0] << 2;

    // branch_address
    assign branch_address = pc_plus4 + (imm_value << 2); 

    // Registers 
    register_file regFile(
        .clk(clk), .reset(reset),  
        .reg_write_en(mem_wb_reg_write),
        .reg_write_dest(mem_wb_write_reg_addr),  
        .reg_write_data(mem_wb_write_back_data),
        .reg_read_addr_1(instr[25:21]),
        .reg_read_addr_2(instr[20:16]),  
        .reg_read_data_1(reg1),  
        .reg_read_data_2(reg2) 
    );
        
    // branch_taken
    assign branch_taken = branch && (((reg1 ^ reg2) == 32'd0) ? 1'b1 : 1'b0) ? 1'b1 : 1'b0;
    
    // Sign-extend
    sign_extend signExtend(
        .sign_ex_in(instr[15:0]),
        .sign_ex_out(imm_value)
    );
    
    // destination_reg mux
    mux2 #(5) destRegMux(
        .a(instr[20:16]),
        .b(instr[15:11]),
        .sel(regDst),
        .y(destination_reg)
    );
    
endmodule
