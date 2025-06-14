/*
 * Barrel shifter: soporta LSL, LSR, ASR y ROR
 * shift_amount = Instr[11:7], shift_type = Instr[6:5]
 */
module shifter(
    input  logic [31:0] in,             // registro fuente crudo (Rm)
    input  logic [4:0]  shift_amount,   // Instr[11:7] cantidad de desplazamiento
    input  logic [1:0]  shift_type,     // Instr[6:5] tipo de desplazamiento
    output logic [31:0] out             // resultado desplazado
);
    always_comb begin
        case (shift_type)
            2'b00: out = in << shift_amount;                          // LSL
            2'b01: out = in >> shift_amount;                          // LSR
            2'b10: out = $signed(in) >>> shift_amount;               // ASR
            2'b11: out = (in >> shift_amount)                         // ROR
                        | (in << (32 - shift_amount));
            default: out = in; // No debería ocurrir, pero por seguridad, no hacer nada
        endcase
    end
endmodule