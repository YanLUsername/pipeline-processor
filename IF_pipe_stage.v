`timescale 1ns / 1ps

module IF_pipe_stage(
    input clk, reset,
    input en,
    input [9:0] branch_address,
    input [9:0] jump_address,
    input branch_taken,
    input jump,
    output [9:0] pc_plus4,
    output [31:0] instr
    );
    
// write your code here
    reg [9:0] PC;
    wire [9:0] nextPC;
    wire [9:0] pcIncremented;
    wire [9:0] branchMuxOut;

    // Increment PC
    assign pcIncremented = PC + 10'd4;
    // First MUX
    assign branchMuxOut = (branch_taken) ? branch_address : pcIncremented;
    // Second MUX
    assign nextPC = (jump) ? jump_address : branchMuxOut;

    // PC update
    always @(posedge clk or posedge reset) begin
        if (reset) 
            PC <= 10'b0;  // Reset PC
        else if (en)
            PC <= nextPC; // Update PC
    end

    // Assign PC+4 to output
    assign pc_plus4 = pcIncremented;
    
    // Instantiate instruction memory
    instruction_mem inst_memory (
        .read_addr(PC), 
        .data(instr)
    );
endmodule
