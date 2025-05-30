/*
 * This module is the Decoder of the Control Unit
 */ 
module decoder(input logic [1:0] Op,
					input logic [5:0] Funct,
					input logic [3:0] Rd,
					output logic [1:0] FlagW,
					output logic PCS, RegW, MemW,
					output logic MemtoReg, ALUSrc,
					output logic [1:0] ImmSrc, RegSrc,
					output logic [1:0] ALUControl,
					output logic NoWrite,
					output logic MovOp             // <--- nueva salida
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
											// B
			2'b10: 						controls = 10'b0110100010;
											// Unimplemented
			default: 					controls = 10'bx;
		endcase
		
	assign {RegSrc, ImmSrc, ALUSrc, MemtoReg, RegW, MemW, Branch, ALUOp} = controls;

	// ALU Decoder
	always_comb begin
		if (ALUOp) begin
			// detect MOV
			MovOp = (Funct[4:1] == 4'b1101);
			case (Funct[4:1])
				4'b0100: begin ALUControl = 2'b00; NoWrite = 1'b0; end // ADD
				4'b0010: begin ALUControl = 2'b01; NoWrite = 1'b0; end // SUB
				4'b0000: begin ALUControl = 2'b10; NoWrite = 1'b0; end // AND
				4'b1100: begin ALUControl = 2'b11; NoWrite = 1'b0; end // ORR
				4'b1010: begin ALUControl = 2'b01; NoWrite = 1'b1; end // CMP
				4'b1101: begin ALUControl = 2'b00; NoWrite = 1'b0; end // MOV (pero lo bypasseamos)
				default: begin ALUControl = 2'bx; NoWrite = 1'b0; end
			endcase

			FlagW[1] = Funct[0];
			FlagW[0] = Funct[0] & (ALUControl == 2'b00 || ALUControl == 2'b01);
		end
		else begin
			MovOp      = 1'b0;
			ALUControl = 2'b00;
			FlagW      = 2'b00;
			NoWrite    = 1'b0;
		end
	end
			
	// PC Logic
	assign PCS = ((Rd == 4'b1111) & RegW) | Branch;
endmodule
