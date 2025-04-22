//----------------------------------------------------------------------------- 
// File: FPALU.sv
// Descripción: Módulo FPALU para realizar la operación S = A - B
//              en formato IEEE-754 de precisión simple (32 bits).
//              Implementación combinacional en SystemVerilog.
//----------------------------------------------------------------------------- 
module FPALU(
    input  logic [31:0] A,    // Operando A en formato IEEE-754 32 bits
    input  logic [31:0] B,    // Operando B en formato IEEE-754 32 bits
    output logic [31:0] S     // Resultado S = A - B (IEEE-754 32 bits)
);

    //-----------------------------------------------------------------------
    // 1) Extracción de campos de la representación IEEE-754
    //-----------------------------------------------------------------------
    logic        signA, signB;
    logic [7:0]  expA, expB;
    logic [22:0] fracA, fracB;
    assign signA = A[31];   assign expA = A[30:23];   assign fracA = A[22:0];
    assign signB = B[31];   assign expB = B[30:23];   assign fracB = B[22:0];

    //-----------------------------------------------------------------------
    // 2) Identificación de casos especiales (NaN, infinito, cero)
    //-----------------------------------------------------------------------
    logic A_isNaN, B_isNaN;
    logic A_isInf, B_isInf;
    logic A_isZero, B_isZero;
    assign A_isNaN  = (expA == 8'hFF) && (fracA != 0);
    assign B_isNaN  = (expB == 8'hFF) && (fracB != 0);
    assign A_isInf  = (expA == 8'hFF) && (fracA == 0);
    assign B_isInf  = (expB == 8'hFF) && (fracB == 0);
    assign A_isZero = (expA == 8'h00) && (fracA == 0);
    assign B_isZero = (expB == 8'h00) && (fracB == 0);

    //-----------------------------------------------------------------------
    // 3) Declaración de variables internas para la operación y normalización
    //-----------------------------------------------------------------------
    logic [23:0] mantA_ext, mantB_ext;   // Mantisas con bit implícito
    logic [7:0]  expMax, expRes;         // Exponente mayor y exponente final
    logic [24:0] mant_diff;              // Resultado intermedio (suma/resta)
    logic [22:0] fracRes;                // Fracción final antes de empaquetar
    logic        signRes;                // Signo del resultado
    logic [31:0] result;                 // Resultado interno completo
    int          shift;                  // Contador para normalización

    //-----------------------------------------------------------------------
    // 4) Lógica combinacional para cálculo de S = A - B
    //-----------------------------------------------------------------------
    always_comb begin
        // 4.0 Inicializaciones: evitan inferencia de latches
        result    = 32'h00000000;                           // default +0
        // Insertar bit implícito: 1 para normal, 0 para denormal
        mantA_ext = (expA == 8'h00) ? {1'b0, fracA} : {1'b1, fracA};
        mantB_ext = (expB == 8'h00) ? {1'b0, fracB} : {1'b1, fracB};
        expMax    = (expA > expB) ? expA : expB;            // mayor exponente
        expRes    = expMax;                                 // inicializar expRes
        mant_diff = '0;
        fracRes   = '0;
        signRes   = 1'b0;
        shift     = 0;

        // 4.1 Casos especiales: prioridad a NaN
        if (A_isNaN) begin
            result = A;   // Propagar NaN de A
        end else if (B_isNaN) begin
            result = B;   // Propagar NaN de B

        // 4.2 Cero: A - 0 = A ; 0 - B = -B
        end else if (B_isZero) begin
            result = A;
        end else if (A_isZero) begin
            result = {~signB, expB, fracB};

        // 4.3 Infinitos: ∞ - ∞ = NaN, ∞ - B = ∞, A - ∞ = ±∞
        end else if (A_isInf && B_isInf) begin
            result = {1'b0, 8'hFF, 1'b1, 22'b0}; // qNaN
        end else if (A_isInf) begin
            result = A;
        end else if (B_isInf) begin
            result = {~signB, 8'hFF, 23'b0};

        // 4.4 Caso general: números normales/subnormales
        end else begin
            // 4.4.1 Alinear exponentes desplazando mantisa del exponente menor
            if (expA > expB) begin
                mantB_ext >>= (expA - expB);
            end else if (expB > expA) begin
                mantA_ext >>= (expB - expA);
            end

            // 4.4.2 Realizar suma o resta según signos (A - B = A + (-B))
            if (signA != signB) begin
                // Caso suma de mantisas
                mant_diff = mantA_ext + mantB_ext;
                signRes   = signA;
                // Ajuste inmediato si hay carry en bit 24
                if (mant_diff[24]) begin
                    mant_diff >>= 1;
                    expRes++;
                end
            end else begin
                // Caso resta de mantisas
                if (mantA_ext >= mantB_ext) begin
                    mant_diff = mantA_ext - mantB_ext;
                    signRes   = signA;
                end else begin
                    mant_diff = mantB_ext - mantA_ext;
                    signRes   = ~signA;
                end
            end

            // 4.4.3 Normalización: desplazar hasta que MSB de mant_diff sea 1
            for (shift = 0; shift < 25 && !mant_diff[23]; shift++) begin
                mant_diff <<= 1;
                expRes--;
            end
            fracRes = mant_diff[22:0];

            // 4.4.4 Manejo de overflow/underflow
            if (expRes >= 8'hFF) begin
                // Overflow → infinito con signo correspondiente
                result = {signRes, 8'hFF, 23'b0};
            end else if (expRes <= 8'h00) begin
                // Underflow → subnormal o cero
                result = {signRes, 8'h00, mant_diff[23:1] >> (1 - expRes)};
            end else begin
                // Número normalizado
                result = {signRes, expRes, fracRes};
            end
        end

        // 4.5 Asignación de la salida final
        S = result;
    end
endmodule
