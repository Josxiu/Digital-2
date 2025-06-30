/*
 * This module is the Decoder of the Control Unit
 */ 
module decoder(
    input  logic [1:0] Op,
    input  logic [5:0] Funct,
    input  logic [3:0] Rd,
    output logic [1:0] FlagW,
    output logic       PCS, RegW, MemW,
    output logic       MemtoReg, ALUSrc,
    output logic [1:0] ImmSrc, RegSrc,
    output logic [2:0] ALUControl,
    output logic       NoWrite, // Nueva señal para agregar cmp
    output logic       Link      // Nueva señal para agregar link
);

	// Internal signals
	logic [9:0] controls;
	logic Branch, ALUOp;

	// Main Decoder
	always_comb
		casex(Op)
											// Data-processing immediate
			2'b00: 	if (Funct[5])	controls = 10'b0000101001;
											// Data-processing register
						else				controls = 10'b0000001001;
											// LDR
			2'b01: 	if (Funct[0])	controls = 10'b0001111000;
											// STR
						else				controls = 10'b1001110100;
											
			2'b10: 	if (Funct[4]) controls = 10'b0110101010; // Es BL
                                 // Para BL, activamos RegW para guardar el LR.
         
                  else          controls = 10'b0110100010; // Es una instrucción B normal
                                 // Para B, RegW está desactivado.
                  
											
			default: 					controls = 10'bx;
		endcase
		
	assign {RegSrc, ImmSrc, ALUSrc, MemtoReg, RegW, MemW, Branch, ALUOp} = controls;
   assign Link = Branch && Funct[4]; // Se agrega Link para Branch con LR
	// ALU Decoder
	always_comb begin
      // CMP no escribe en el banco de registros
      NoWrite = ALUOp && (Funct[4:1] == 4'b1010);

      if (ALUOp) begin
         case (Funct[4:1])
            4'b0100: ALUControl = 3'b000; // ADD
            4'b0010: ALUControl = 3'b001; // SUB
            4'b0000: ALUControl = 3'b010; // AND
            4'b1100: ALUControl = 3'b011; // ORR
            4'b1010: ALUControl = 3'b001; // CMP (resta, no escribe)
            4'b1101: ALUControl = 3'b110; // MOV
            4'b0001: ALUControl = 3'b111; // XOR
            default: ALUControl = 3'bxxx;
         endcase

         // Actualización de flags sólo si S==1 y operación aritmética
         FlagW[1] = Funct[0];
         FlagW[0] = Funct[0] && (ALUControl == 3'b000 || ALUControl == 3'b001);
      end
      else begin
         ALUControl = 3'b000;    // default para no-DP
         FlagW      = 2'b00;     // no actualiza flags
         NoWrite    = 1'b0;      // CMP sólo en DP
      end
   end

	// PC Logic
	assign PCS = ((Rd == 4'b1111) && RegW) || Branch;

endmodule
