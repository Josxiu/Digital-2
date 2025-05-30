/*
 * This module is the Datapath Unit of the ARM single-cycle processor
 */ 
module datapath(
    input  logic        clk, reset,
    input  logic [1:0]  RegSrc,
    input  logic        RegWrite,
    input  logic [1:0]  ImmSrc,
    input  logic        ALUSrc,
    input  logic [1:0]  ALUControl,
    input  logic        MemtoReg,
    input  logic        PCSrc,
    input  logic        MovOp,           // <--- nuevo control
    output logic [3:0]  ALUFlags,
    output logic [31:0] PC,
    input  logic [31:0] Instr,
    output logic [31:0] ALUResult, WriteData,
    input  logic [31:0] ReadData
);
	// Internal signals
	logic [31:0] PCNext, PCPlus4, PCPlus8;
	logic [31:0] ExtImm, SrcA, SrcB, Result;
	logic [3:0] RA1, RA2;


    // Nuevas señales para el shifter
    logic [31:0] SrcB_raw;        // Valor crudo del registro fuente 2
    logic [31:0] ShifterOut;      // Salida del shifter
    logic [4:0]  shift_amount;    // Cantidad de desplazamiento
    logic [1:0]  shift_type;      // Tipo de desplazamiento



	
	// next PC logic
	mux2 #(32) pcmux(PCPlus4, Result, PCSrc, PCNext);
	flopr #(32) pcreg(clk, reset, PCNext, PC);
	adder #(32) pcadd1(PC, 32'b100, PCPlus4);
	adder #(32) pcadd2(PCPlus4, 32'b100, PCPlus8);

	// register file logic
	mux2 #(4) ra1mux(Instr[19:16], 4'b1111, RegSrc[0], RA1);
	mux2 #(4) ra2mux(Instr[3:0], Instr[15:12], RegSrc[1], RA2);
	// Se cambia la conexión: la salida rd2 de regfile ahora va a SrcB_raw
    regfile rf(clk, RegWrite, RA1, RA2, Instr[15:12], Result, PCPlus8, SrcA, SrcB_raw);
    extend ext(Instr[23:0], ImmSrc, ExtImm);


    // SHIFTER LOGIC (nuevo bloque)
    // Extrae los campos de la instrucción para el shifter
    assign shift_amount = Instr[11:7]; // Cantidad de desplazamiento
    assign shift_type   = Instr[6:5]; // Tipo de desplazamiento (LSL, LSR, ASR, ROR)
    // Instancia del shifter
    shifter shft(SrcB_raw, shift_amount, shift_type, ShifterOut);



	// ALU logic
    // Se cambia la entrada del mux2, ahora se pasa ShifterOut en lugar de writeData
	mux2 #(32) srcbmux (ShifterOut, ExtImm, ALUSrc, SrcB);
	alu  #(32) alu_i   (SrcA, SrcB, ALUControl, ALUResult, ALUFlags);

    // WriteData para stores: ahora es la salida del shifter
    assign WriteData = ShifterOut;

    // bypass MOV: si MovOp=1, saltamos ALU y pasamos SrcB
    logic [31:0] ALUOutMux;
    assign ALUOutMux = MovOp ? SrcB : ALUResult;

    // write-back multiplexer
    mux2 #(32) resmux (ALUOutMux, ReadData, MemtoReg, Result);
endmodule