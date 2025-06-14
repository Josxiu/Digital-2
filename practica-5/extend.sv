/*
 * This module is the Extend block of the Datapath Unit
 */ 
module extend(input logic [23:0] Instr,
				  input logic [1:0] ImmSrc,
				  output logic [31:0] ExtImm);

	logic [7:0] Imm8;
	logic [3:0] rot;
	
	always_comb
		case(ImmSrc)
			// 8-bit unsigned immediate
			2'b00: begin
				Imm8 = Instr[7:0];
				rot = Instr[11:8];
				// Se rota a la derecha el inmediato
				if (rot == 0)
					ExtImm = {24'b0, Imm8}; // No rotación
				else
					ExtImm = ({24'b0, Imm8} >> (rot*2)) | ({24'b0, Imm8} << (32-(rot*2))); // Rotación a la derecha
			end
			// 12-bit unsigned immediate
			2'b01: ExtImm = {20'b0, Instr[11:0]};
			// 24-bit two's complement shifted branch
			2'b10: ExtImm = {{6{Instr[23]}}, Instr[23:0], 2'b00};
			default: ExtImm = 32'bx; // undefined
		endcase
endmodule
