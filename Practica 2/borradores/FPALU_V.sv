//----------------------------------------------------------------------------- 
// File: FPALU.sv
// Description: Módulo FPALU para resta A - B en IEEE-754 precisión simple (32 bits)
// Compatible con Verilog-2001 para ModelSim y Quartus
//----------------------------------------------------------------------------- 
module FPALU(
    input  wire [31:0] A,    // Operando A
    input  wire [31:0] B,    // Operando B
    output wire [31:0] S     // Resultado S = A - B
);

    //-------------------------------------------------------------------------
    // 1) Extracción de campos: signo, exponente y fracción
    //-------------------------------------------------------------------------
    wire        signA    = A[31];
    wire [7:0]  expA     = A[30:23];
    wire [22:0] fracA    = A[22:0];

    wire        signB    = B[31];
    wire [7:0]  expB     = B[30:23];
    wire [22:0] fracB    = B[22:0];

    //-------------------------------------------------------------------------
    // 2) Señales de casos especiales
    //-------------------------------------------------------------------------
    wire A_isNaN   = (expA == 8'hFF) && (fracA != 0);
    wire B_isNaN   = (expB == 8'hFF) && (fracB != 0);
    wire A_isInf   = (expA == 8'hFF) && (fracA == 0);
    wire B_isInf   = (expB == 8'hFF) && (fracB == 0);
    wire A_isZero  = (expA == 8'h00) && (fracA == 0);
    wire B_isZero  = (expB == 8'h00) && (fracB == 0);

    //-------------------------------------------------------------------------
    // 3) Registros internos y auxiliares
    //-------------------------------------------------------------------------
    reg  [31:0] result;
    reg  [23:0] mantA_ext, mantB_ext;
    reg  [7:0]  expMax, expRes, expDiff;
    reg  [24:0] mant_diff;
    reg  [22:0] fracRes;
    reg         signRes;
    integer     shift, i;
    reg         shift_found;

    //-------------------------------------------------------------------------
    // 4) Lógica combinacional principal
    //-------------------------------------------------------------------------
    always @* begin
        // 4.0 Valor por defecto: +0.0
        result = 32'h00000000;

        // 4.1 Propagación de NaN
        if (A_isNaN) begin
            result = A;
        end else if (B_isNaN) begin
            result = B;

        // 4.2 Ceros: A - 0 = A ; 0 - B = -B
        end else if (B_isZero) begin
            result = A;
        end else if (A_isZero) begin
            result = {~signB, expB, fracB};

        // 4.3 Infinitos
        end else if (A_isInf && B_isInf) begin
            // ∞ - ∞ = qNaN: exponente todos 1 y mantisa no cero
            result = {1'b0, 8'hFF, 1'b1, 22'b0};
        end else if (A_isInf) begin
            result = A;  // ∞ - B = ∞
        end else if (B_isInf) begin
            // A - ∞ = -∞ si B positivo, +∞ si B negativo
            result = {~signB, 8'hFF, 23'b0};

        // 4.4 Caso general: A y B normales/subnormales
        end else begin
            // 4.4.1 Insertar bit implícito en mantisas
            if (expA == 8'h00)
                mantA_ext = {1'b0, fracA};
            else
                mantA_ext = {1'b1, fracA};

            if (expB == 8'h00)
                mantB_ext = {1'b0, fracB};
            else
                mantB_ext = {1'b1, fracB};

            // 4.4.2 Igualar exponentes
            if (expA > expB) begin
                expDiff = expA - expB;
                expMax  = expA;
                mantB_ext = mantB_ext >> expDiff;
                // si B desplazada es cero, A - B = A
                if (mantB_ext == 0) begin
                    result = A;
                end
            end else if (expB > expA) begin
                expDiff = expB - expA;
                expMax  = expB;
                mantA_ext = mantA_ext >> expDiff;
                // si A desplazada es cero, A - B ≈ -B
                if (mantA_ext == 0) begin
                    result = {~signB, expB, fracB};
                end
            end else begin
                expMax = expA;
            end

            // 4.4.3 Si result sigue en default, hacer resta
            if (result == 32'h00000000) begin
                // 4.4.4 Resta de mantisas y signo resultante
                if (mantA_ext >= mantB_ext) begin
                    mant_diff = mantA_ext - mantB_ext;
                    signRes   = signA;
                end else begin
                    mant_diff = mantB_ext - mantA_ext;
                    signRes   = ~signA;
                end

                // 4.4.5 Normalización: buscar primer '1' de MSB a LSB
                shift = 0;
                shift_found = 1'b0;
                for (i = 24; i >= 0; i = i - 1) begin
                    if (!shift_found && mant_diff[i]) begin
                        shift = i - 23;
                        shift_found = 1'b1;
                    end
                end

                expRes = expMax + shift;
                if (shift >= 0)
                    fracRes = mant_diff >> shift;
                else
                    fracRes = mant_diff << (-shift);

                // 4.4.6 Overflow / Underflow
                if (expRes >= 8'hFF) begin
                    // Overflow => infinito
                    result = {signRes, 8'hFF, 23'b0};
                end else if (expRes <= 8'h00) begin
                    // Underflow => subnormal o cero
                    result = {signRes, 8'h00, fracRes >> (1 - expRes)};
                end else begin
                    // Normalizado
                    result = {signRes, expRes, fracRes};
                end
            end
        end
    end

    // 4.5 Salida final
    assign S = result;
endmodule // FPALU
