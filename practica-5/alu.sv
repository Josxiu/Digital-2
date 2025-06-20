/*
 * This module is the ALU of the Datapath Unit
 */ 
module alu #(parameter N = 4) (A, B, ALUControl, Result, ALUFlags);
	input logic  [2:0] ALUControl; // Se amplió a 3 bits para agregar más instrucciones
	input logic  [N-1:0] A, B;
	output logic [N-1:0] Result;
	output logic [3:0] ALUFlags;

	logic Cout;
	// 000: ADD, 001: SUB, 010: AND, 011: ORR
	// 110: MOV, 111: XOR
	always_comb begin
		Cout = 1'b0;
		case (ALUControl)
			3'b011: begin
				Result = A | B;
			end
			3'b010: begin
				Result = A & B;
			end
			3'b110: begin // Se grega el MOV
				Result = B;
			end
			3'b111: begin // Se agrega el XOR
				Result = A ^ B;
			end
			default: begin
				{Cout, Result} = {1'b0, A} + {1'b0, (ALUControl[0] == 1'b0 ? B : ~B)} + ALUControl[0];
			end
		endcase	
	end
	
	// Negative
	assign ALUFlags[3] = Result[N-1];
	// Zero
	assign ALUFlags[2] = Result == 0 ? 1'b1 : 1'b0;
	// Carry
	assign ALUFlags[1] = (~ALUControl[1]) & Cout;
	// Overflow
	assign ALUFlags[0] = (~(ALUControl[0] ^ A[N-1] ^ B[N-1])) & (A[N-1] ^ Result[N-1]) & (~ALUControl[1]);
endmodule

