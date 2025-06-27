/*
 * This module is the Datapath Unit of the ARM single-cycle processor
 */ 
module datapath(input logic clk, reset,
					 input logic [1:0] RegSrc,
					 input logic RegWrite,
					 input logic [1:0] ImmSrc,
					 input logic ALUSrc,
					 input logic [2:0] ALUControl,
					 input logic MemtoReg,
					 input logic PCSrc,
					 input logic Link, 		// Nueva señal para agregar link
					 output logic [3:0] ALUFlags,
					 output logic [31:0] PC,
					 input logic [31:0] Instr,
					 output logic [31:0] ALUResult, WriteData,
					 input logic [31:0] ReadData);
	// Internal signals
	logic [31:0] PCNext, PCPlus4, PCPlus8;
	logic [31:0] ExtImm, SrcA, SrcB, Result;
	logic [3:0] RA1, RA2;

	// Señales Nuevas para el shifter
	logic [31:0] SrcB_raw, ShifterOut;
	logic [4:0]  shift_amount;
	logic [1:0]  shift_type;

	// Nuevas señales para la lógica de BL
    logic [3:0] In_WA3;  // Dirección final para el puerto de escritura del regfile
    logic [31:0] In_WD3; // Datos finales para el puerto de escritura del regfile

	// next PC logic
	mux2 #(32) pcmux(PCPlus4, Result, PCSrc, PCNext);
	flopr #(32) pcreg(clk, reset, PCNext, PC);
	adder #(32) pcadd1(PC, 32'b100, PCPlus4);
	adder #(32) pcadd2(PCPlus4, 32'b100, PCPlus8);

	// register file logic
	mux2 #(4) ra1mux(Instr[19:16], 4'b1111, RegSrc[0], RA1);
	mux2 #(4) ra2mux(Instr[3:0], Instr[15:12], RegSrc[1], RA2);

	// Nuevos mux para el regfile y la lógica de BL
	// Si Link=1, se escribe en R14 (4'b1110). Si no, se usa el campo Rd de la instrucción.
	mux2 #(4) wa3mux(Instr[15:12], 4'b1110, Link, In_WA3);
	mux2 #(32) wd3mux(Result, PCPlus4, Link, In_WD3); // lr(R14) recibe PC+4 si Link=1

	// Se modifica regfile para los desplazamientos, ahora la SrcB_raw recibe la salida rd2
	// ahora se conectan los multiplexores para A3 y WD3 al regfile
	regfile rf(clk, RegWrite, RA1, RA2, In_WA3, In_WD3, PCPlus8, SrcA, SrcB_raw);

	
	mux2 #(32) resmux(ALUResult, ReadData, MemtoReg, Result);
	extend ext(Instr[23:0], ImmSrc, ExtImm);

	// Campos de la instrucción para el shifter
	assign shift_amount = Instr[11:7];
	assign shift_type   = Instr[6:5];

	// Instancia del shifter
	shifter shft(SrcB_raw, shift_amount, shift_type, ShifterOut);

	

	// ALU logic
	mux2 #(32) srcbmux2(ShifterOut, ExtImm, ALUSrc, SrcB); // Ahora se usa ShifterOut en el mux
	assign WriteData = ShifterOut; // Ahora se pasa shifterOut a writeData para desplazar también cuando se usa STR
	alu #(32) alu(SrcA, SrcB, ALUControl, ALUResult, ALUFlags);
endmodule