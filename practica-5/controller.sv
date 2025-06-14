/*
 * This module is the Control Unit of ARM single-cycle processor
 */ 
module controller(input logic clk, reset,
						input logic [31:12] Instr,
						input logic [3:0] ALUFlags,
						output logic [1:0] RegSrc,
						output logic RegWrite,
						output logic [1:0] ImmSrc,
						output logic ALUSrc,
						output logic [2:0] ALUControl,
						output logic MemWrite, MemtoReg,
						output logic PCSrc);
	logic [1:0] FlagW;
	logic PCS, RegW, MemW;
	logic NoWrite; // Se agrega NoWrite para controlar escritura en registros

	decoder dec(Instr[27:26], Instr[25:20], Instr[15:12],
					FlagW, PCS, RegW, MemW,
					MemtoReg, ALUSrc, ImmSrc, RegSrc, ALUControl, NoWrite);

	condlogic cl(clk, reset, Instr[31:28], ALUFlags,
					FlagW, PCS, RegW & ~NoWrite, MemW,
					PCSrc, RegWrite, MemWrite);
	
	// Ahora RegW depende de NoWrite, si NoWrite es 1, RegW debe ser 0
endmodule
