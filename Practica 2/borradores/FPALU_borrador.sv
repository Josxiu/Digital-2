// Descripción: Módulo para la resta de dos números en punto flotante de 32 bits (IEEE 754).
module FPALU (
    input logic [31:0] A, // Entrada A
    input logic [31:0] B, // Entrada B

    output logic [31:0] S // Salida S
);

    // Señales internas para signo, exponentes y mantisas
    logic A_sign, B_sign;
    logic [7:0] A_exp, B_exp;
    logic [23:0] A_mant, B_mant; // 24 bits ya que se añade un 1 antes de la mantisa (1.M)

    // Señales para guardar el resultado
    logic S_sign;
    logic [7:0] S_exp;
    logic [23:0] S_mant; // 24 bits para la mantisa del resultado

    // señales para hacer la resta
    logic [7:0] exp_diff; // Diferencia de exponentes

    always_comb begin : FPALU_logic

        // Se extrae el signo, exponente y mantisa de A y B
        A_sign = A[31];
        B_sign = ~B[31]; // Se niega el signo de B para la resta

        A_exp = A[30:23];
        B_exp = B[30:23];

        // Si el exponente es 0, no se añade el 1 implícito 0.mantisa
        // Si el exponente es diferente de 0, se añade el 1 implícito 1.mantisa
        A_mant = (A[30:23] == 0) ? {1'b0, A[22:0]} : {1'b1, A[22:0]}; // Se añade el 1 implícito
        B_mant = (B[30:23] == 0) ? {1'b0, B[22:0]} : {1'b1, B[22:0]}; // Se añade el 1 implícito

        // Se hace la resta de los exponentes
        if (A_exp >= B_exp) begin
            exp_diff = A_exp - B_exp; // Diferencia de exponentes
            S_exp = A_exp; // El exponente del resultado es el del mayor
            S_mant = A_mant - (B_mant >> exp_diff); // Se desplaza la mantisa menor para alinear exponentes
            S_sign = A_sign; // El signo del resultado es el del mayor
        end else begin
            exp_diff = B_exp - A_exp; // Diferencia de exponentes
            S_exp = B_exp; // El exponente del resultado es el del mayor
            S_mant = B_mant - (A_mant >> exp_diff); // Se desplaza la mantisa menor para alinear exponentes
            S_sign = B_sign; // El signo del resultado es el del mayor
        end
        
    end




    
    
endmodule