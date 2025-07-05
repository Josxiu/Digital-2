// Módulo Generador de PWM Optimizado para DE10-Lite
// Genera una señal PWM con frecuencia configurable y control directo del ancho de pulso.

module pwm #(
    // Frecuencia del reloj
    parameter integer f_clk = 50_000_000, // 50MHz
    // Frecuencia PWM deseada en Hz
    parameter integer f_pwm = 25_000      // 25kHz es un valor común y ultrasónico
) (
    input  logic        clk,              // Reloj principal de la FPGA
    input  logic        reset_n,          // Reset activo bajo
    input  logic [10:0] ancho_pulso, // ANCHO DEL PULSO (0 a TICKS_PERIODO)
    output logic        pwm_out           // Salida PWM
);

    // -----------------------------
    // Cálculo de constantes en tiempo de compilación
    // -----------------------------
    // TICKS_PERIODO = número de pulsos de clk en un periodo PWM
    localparam integer TICKS_PERIODO = f_clk / f_pwm;
    // Ancho de bits necesario para contar hasta TICKS_PERIODO
    localparam integer ANCHO_CONTADOR = $clog2(TICKS_PERIODO);

    // Registro contador de periodo PWM
    logic [ANCHO_CONTADOR-1:0] contador;

    // ---------------------------------------
    // Lógica de conteo y generación de PWM
    // ---------------------------------------
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            contador <= '0;
        end else begin
            // Incrementar o volver a cero cuando alcance fin de periodo
            if (contador >= TICKS_PERIODO - 1)
                contador <= '0;
            else
                contador <= contador + 1;
        end
    end

    // La lógica de salida ahora es combinacional y muy simple
    // Pwm es 1 si el contador es menor que el ancho de pulso deseado.
    assign pwm_out = (contador < ancho_pulso);

endmodule
