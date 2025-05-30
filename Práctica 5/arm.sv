/*
 * This module is the ARM single-cycle processor, 
 * which instantiates the Control and Datapath units
 */ 
module arm(
    input  logic        clk, reset,
    output logic [31:0] PC,
    input  logic [31:0] Instr,
    output logic        MemWrite,
    output logic [31:0] ALUResult, WriteData,
    input  logic [31:0] ReadData
);
    // interconexiones
    logic [3:0]  ALUFlags;
    logic        RegWrite, ALUSrc, MemtoReg, PCSrc;
    logic [1:0]  RegSrc, ImmSrc;
    logic [1:0]  ALUControl;
    logic        MoveOp;            // <-- señal que viene del decoder

    // Controller ahora saca MoveOp
    controller c(
        clk, reset,
        Instr[31:12], ALUFlags,
        /*outputs*/ RegSrc, RegWrite, ImmSrc,
                   ALUSrc, ALUControl,
                   MemWrite, MemtoReg, PCSrc,
                   MoveOp        // <–– conectamos aquí
    );

    // Datapath recibe MovOp
    datapath dp(
        clk, reset,
        RegSrc, RegWrite, ImmSrc,
        ALUSrc, ALUControl,
        MemtoReg, PCSrc,
        MoveOp,       // <–– y se lo pasamos al datapath
        ALUFlags, PC, Instr,
        ALUResult, WriteData, ReadData
    );
endmodule
