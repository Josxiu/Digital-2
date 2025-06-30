/*
 * Module: extend
 * Description: Sign-extend and rotate-immediate logic for ARM datapath
 */
module extend (
    input  logic [23:0] Instr,
    input  logic [1:0]  ImmSrc,
    output logic [31:0] ExtImm
);

    always_comb begin
        // Extract immediate and rotation fields
        logic [7:0]  imm8;
        logic [3:0]  rot;
        imm8 = Instr[7:0];
        rot  = Instr[11:8];

        case (ImmSrc)
            // 8-bit rotated immediate
            2'b00: begin
                logic [31:0] imm32;
                imm32 = {24'd0, imm8};
                if (rot == 0)
                    ExtImm = imm32;
                else
                    ExtImm = (imm32 >> (rot * 2)) |
                              (imm32 << (32 - (rot * 2)));
            end

            // 12-bit zero-extended immediate
            2'b01: ExtImm = {20'd0, Instr[11:0]};

            // 24-bit sign-extended branch immediate (<<2)
            2'b10: ExtImm = {{6{Instr[23]}}, Instr, 2'b00};

            default: ExtImm = 32'd0;
        endcase
    end
endmodule