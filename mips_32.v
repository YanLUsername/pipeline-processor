`timescale 1ns / 1ps

module mips_32(
    input clk, reset,  
    output[31:0] result
    );
    
// define all the wires here. You need to define more wires than the ones you did in Lab2
    wire IF_Flush;
    wire en;
    wire jump;

    // Wires for instruction fetch
    wire branch_taken;
    wire [9:0] branch_address, jump_address, pc_plus4;
    wire [31:0] instr; 

    // Wires for IF/ID registers
    wire [9:0] if_id_pc_plus4;
    wire [31:0] if_id_instr;

    // Wires for instruction decode
    wire mem_wb_reg_write;
	wire [4:0] mem_wb_destination_reg;
	wire [31:0] write_back_data;
	wire [31:0] reg1, reg2;
	wire [31:0] imm_value;
	wire [4:0] destination_reg;
	wire mem_to_reg, mem_read, mem_write, alu_src, reg_write; 
	wire [1:0] alu_op;
	
	// Wires for ID/EX registers
	wire [139:0] id_ex_input, id_ex_output;
    wire [31:0] id_ex_instr, id_ex_reg1, id_ex_reg2, id_ex_imm_value;
    wire [4:0] id_ex_destination_reg;
    wire [1:0] id_ex_alu_op;
    wire id_ex_mem_to_reg, id_ex_mem_read, id_ex_mem_write, id_ex_alu_src, id_ex_reg_write;
    
    // Wires for forwarding
    wire [1:0] Forward_A, Forward_B;
	wire [31:0] alu_in2_out, alu_result;
    
    // Wires for EX/MEM registers
    wire [31:0] ex_mem_instr, ex_mem_alu_result, ex_mem_alu_in2_out;
    wire ex_mem_reg_write, ex_mem_mem_to_reg, ex_mem_mem_read;
	wire [4:0] ex_mem_destination_reg;
	wire [104:0] ex_mem_input, ex_mem_output;
    
    // Wire for data_mem
    wire [31:0] mem_read_data;
    
    // Wires for MEM/WB registers
    wire [70:0] mem_wb_input, mem_wb_output;
    wire [31:0] mem_wb_mem_read_data, mem_wb_alu_result;
    wire mem_wb_mem_to_reg;
   
// Build the pipeline as indicated in the lab manual
    
///////////////////////////// Instruction Fetch    
    // Complete your code here      
    IF_pipe_stage IF_PipeStage(
        .clk(clk), 
        .reset(reset),
        .en(en),
        .branch_address(branch_address),
        .jump_address(jump_address),
        .branch_taken(branch_taken),
        .jump(jump),
        .pc_plus4(pc_plus4),
        .instr(instr)
    );
        
///////////////////////////// IF/ID registers
    // Complete your code here
    // if_id_pc_plus4 flip flop
    pipe_reg_en #(10) IF_ID_Plus4(
        .clk(clk),
        .reset(reset),
        .en(en),
        .flush(IF_Flush),
        .d(pc_plus4),
        .q(if_id_pc_plus4)
    );
    
    // if_id_instr flip flop
    pipe_reg_en #(32) IF_ID_Instr(
        .clk(clk),
        .reset(reset),
        .en(en),
        .flush(IF_Flush),
        .d(instr),
        .q(if_id_instr)
    );

///////////////////////////// Instruction Decode 
	// Complete your code here
    ID_pipe_stage IdPipeStage(
        clk, 
        reset,
        if_id_pc_plus4,
        if_id_instr,
        mem_wb_reg_write, 
        mem_wb_destination_reg, 
        write_back_data,
        en, // from Data_Hazard
        IF_Flush,
        reg1, reg2,
        imm_value,
        branch_address,
        jump_address,
        branch_taken,
        destination_reg, 
        mem_to_reg,
        alu_op,
        mem_read,  
        mem_write,
        alu_src,
        reg_write,
        jump
    );
             
///////////////////////////// ID/EX registers 
	// Complete your code here
	pipe_reg #(140) ID_EX_Reg(
        clk,
        reset,
        id_ex_input,
        id_ex_output
    );
    
    assign id_ex_input[31:0] = if_id_instr;
    assign id_ex_input[63:32] = reg1;
    assign id_ex_input[95:64] = reg2;
    assign id_ex_input[127:96] = imm_value;
    assign id_ex_input[132:128] = destination_reg;
    assign id_ex_input[133] = mem_to_reg;
    assign id_ex_input[135:134] = alu_op;
    assign id_ex_input[136] = mem_read;
    assign id_ex_input[137] = mem_write;
    assign id_ex_input[138] = alu_src;
    assign id_ex_input[139] = reg_write;
    
    assign id_ex_instr =  id_ex_output[31:0];
    assign id_ex_reg1 = id_ex_output[63:32];
    assign id_ex_reg2 = id_ex_output[95:64];
    assign id_ex_imm_value = id_ex_output[127:96];
    assign id_ex_destination_reg = id_ex_output[132:128];
    assign id_ex_mem_to_reg = id_ex_output[133];
    assign id_ex_alu_op = id_ex_output[135:134];
    assign id_ex_mem_read = id_ex_output[136];
    assign id_ex_mem_write = id_ex_output[137];
    assign id_ex_alu_src = id_ex_output[138];
    assign id_ex_reg_write = id_ex_output[139];

///////////////////////////// Hazard_detection unit
	// Complete your code here    
    Hazard_detection hazardDetection(
        id_ex_mem_read,
        id_ex_destination_reg,
        if_id_instr[20:16],
        if_id_instr[25:21],
        branch_taken, jump,
        en, //from Data_Hazard
        IF_Flush
    );
           
///////////////////////////// Execution    
	// Complete your code here
	EX_pipe_stage EXPipeStage(
        .id_ex_instr(id_ex_instr),
        .reg1(id_ex_reg1),
        .reg2(id_ex_reg2),
        .id_ex_imm_value(id_ex_imm_value),
        .ex_mem_alu_result(ex_mem_alu_result),
        .mem_wb_write_back_result(write_back_data),
        .id_ex_alu_src(id_ex_alu_src),
        .id_ex_alu_op(id_ex_alu_op),
        .Forward_A(Forward_A),
        .Forward_B(Forward_B),
        .alu_in2_out(alu_in2_out),
        .alu_result(alu_result)
    );
        
///////////////////////////// Forwarding unit
	// Complete your code here 
    EX_Forwarding_unit EXForwardingUnit(
        .ex_mem_reg_write(ex_mem_reg_write),
        .ex_mem_write_reg_addr(ex_mem_destination_reg),
        .id_ex_instr_rs(id_ex_instr[25:21]),
        .id_ex_instr_rt(id_ex_instr[20:16]),
        .mem_wb_reg_write(mem_wb_reg_write),
        .mem_wb_write_reg_addr(mem_wb_destination_reg),
	    .Forward_A(Forward_A),
	    .Forward_B(Forward_B)
    );
     
///////////////////////////// EX/MEM registers
	// Complete your code here 
	pipe_reg #(105) EX_Mem_Reg( 
        clk,
        reset,
        ex_mem_input,
        ex_mem_output
    );
    
    assign ex_mem_input[31:0] = id_ex_instr;
    assign ex_mem_input[36:32] = id_ex_destination_reg;
    assign ex_mem_input[68:37] = alu_result;
    assign ex_mem_input[100:69] = alu_in2_out;
    assign ex_mem_input[101] = id_ex_mem_to_reg;
    assign ex_mem_input[102] = id_ex_mem_read;
    assign ex_mem_input[103] = id_ex_mem_write;
    assign ex_mem_input[104] = id_ex_reg_write;
    
    assign ex_mem_instr = ex_mem_output[31:0];
    assign ex_mem_destination_reg = ex_mem_output[36:32];
    assign ex_mem_alu_result = ex_mem_output[68:37];
    assign ex_mem_alu_in2_out = ex_mem_output[100:69];
    assign ex_mem_mem_to_reg = ex_mem_output[101];
    assign ex_mem_mem_read = ex_mem_output[102];
    assign ex_mem_mem_write = ex_mem_output[103];
    assign ex_mem_reg_write = ex_mem_output[104];
    
///////////////////////////// memory    
	// Complete your code here
    data_memory data_mem(
        .clk(clk),
        .mem_access_addr(ex_mem_alu_result),
        .mem_write_data(ex_mem_alu_in2_out),
        .mem_write_en(ex_mem_mem_write),
        .mem_read_en(ex_mem_mem_read),
        .mem_read_data(mem_read_data)
    );

///////////////////////////// MEM/WB registers  
	// Complete your code here
	pipe_reg #(71) mem_WB_Reg(
        clk,
        reset,
        mem_wb_input,
        mem_wb_output
    ); 
    
    assign mem_wb_input[31:0] = ex_mem_alu_result;
    assign mem_wb_input[63:32] = mem_read_data;
    assign mem_wb_input[64] = ex_mem_mem_to_reg;
    assign mem_wb_input[65]  = ex_mem_reg_write;
    assign mem_wb_input[70:66] = ex_mem_destination_reg;

    assign mem_wb_alu_result = mem_wb_output[31:0];
    assign mem_wb_mem_read_data = mem_wb_output[63:32];
    assign mem_wb_mem_to_reg =  mem_wb_output[64];
    assign mem_wb_reg_write = mem_wb_output[65];
    assign mem_wb_destination_reg = mem_wb_output[70:66];
    
///////////////////////////// writeback    
	// Complete your code here
    mux2 #(32) writeBack(
        .a(mem_wb_alu_result),
        .b(mem_wb_mem_read_data),
        .sel(mem_wb_mem_to_reg),
        .y(write_back_data)
    );
    
    assign result = write_back_data;
endmodule