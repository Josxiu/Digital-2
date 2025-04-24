/* Modúlo principal que integra cada modulo para realizar la resta de A y B en ieee 754
   y mostrar el resultado en un display de 7 segmentos.
   modulos usados DISPLAYS, OPERANDS, FSM y FPALU.
    */
module MAIN (
    input logic        clk,
    input logic        reset,
    input logic        btn,     // Botón para avanzar la FSM
    input logic [9:0]  sw,      // Switches de entrada
    output logic [7:0]  display0, display1, display2, display3, display4, display5 // Los 6 displays de 7 segmentos
    
);

    // Invertir reset y btn para que sean activos en 1
    logic inv_reset, inv_btn;
    logic [23:0] info_displays; // Información a mostrar en los displays
    assign inv_reset = ~reset;
    assign inv_btn   = ~btn;

    // Señales internas para conectar los módulos
    logic [3:0]  estado;        // Estado actual de la FSM
    logic [31:0] op_A, op_B;     // Operandos capturados
    logic [31:0] resultado;      // Resultado calculado por la ALU



        // Instanciamos la ALU (FPALU)
    FPALU fpal_inst (
        .A(op_A),
        .B(op_B),
        .S(resultado)
    );

    // Instanciamos la FSM usando las señales invertidas
    FSM fsm_inst (
        .clk(clk),
        .reset(inv_reset),
        .btn(inv_btn),
        .estado(estado)
    );

    // Instanciamos el módulo OPERANDS
    OPERANDS operands_inst (
        .clk(clk),
        .reset(inv_reset),
        .estado(estado),      // Estado para saber en qué etapa estamos
        .sw(sw),            // Lectura de switches
        .resultado(resultado),  // Se muestra en LEDs en el estado de resultado
        .A(op_A),           // Salida operando A
        .B(op_B),           // Salida operando B
        .visualizar(info_displays) // Salida para los displays
    );

    // Instanciamos el módulo de displays
    DISPLAYS displays_inst (
        .D(info_displays),
        .display0(display0),
        .display1(display1),
        .display2(display2),
        .display3(display3),
        .display4(display4),
        .display5(display5)
    );


    
endmodule


`timescale 1ns/1ps

module tb_MAIN;

  // Parámetro para el período de reloj
  localparam integer PER = 20; // ns → 50 MHz

  // Señales simuladas
  logic clk;
  logic reset;         // activo en bajo
  logic btn;           // activo en bajo
  logic [9:0] sw;
  logic [7:0] display0, display1, display2, display3, display4, display5;

  // Instancia del DUT
  MAIN dut (
    .clk      (clk),
    .reset    (reset),
    .btn      (btn),
    .sw       (sw),
    .display0 (display0),
    .display1 (display1),
    .display2 (display2),
    .display3 (display3),
    .display4 (display4),
    .display5 (display5)
  );

  // 1) Generación de reloj: toggle cada PER/2
  initial begin
    clk = 0;
    forever #(PER/2) clk = ~clk;
  end

  // 2) Secuencia de estímulos con delays
  initial begin
    // Estado inicial
    sw    = 10'b0;
    clk   = 0;
    btn   = 1;   // reposo (activo-bajo)
    reset = 1;   // reposo

    // Pequeña espera para estabilizar
    # (PER * 2);

    // 2.1 Reset activo-bajo un ciclo
    reset = 0;
    #PER;
    reset = 1;
    #PER;

    // --------------------------------------------------
    // 3) Ingreso de A (A1 → A4)
    // --------------------------------------------------

    // A1 = 0xAA
    sw[9:2] = 8'hAA;  
    #PER;        // dejar que sw se asiente
    btn = 0;     // presiona
    #PER;
    btn = 1;     // suelta
    #PER;

    // A2 = 0xBB
    sw[9:2] = 8'hBB;
    #PER;
    btn = 0; #PER; btn = 1; #PER;

    // A3 = 0xCC
    sw[9:2] = 8'hCC;
    #PER;
    btn = 0; #PER; btn = 1; #PER;

    // A4 = 0xDD
    sw[9:2] = 8'hDD;
    #PER;
    btn = 0; #PER; btn = 1; #PER;

    // --------------------------------------------------
    // 4) Ingreso de B (B1 → B4)
    // --------------------------------------------------

    // B1 = 0x11
    sw[9:2] = 8'h11;
    #PER;
    btn = 0; #PER; btn = 1; #PER;

    // B2 = 0x22
    sw[9:2] = 8'h22;
    #PER;
    btn = 0; #PER; btn = 1; #PER;

    // B3 = 0x33
    sw[9:2] = 8'h33;
    #PER;
    btn = 0; #PER; btn = 1; #PER;

    // B4 = 0x44
    sw[9:2] = 8'h44;
    #PER;
    btn = 0; #PER; btn = 1; #PER;

    // --------------------------------------------------
    // 5) Estado SAL: mostrar parte alta y baja
    // --------------------------------------------------

    // Parte alta (SW[0]=0)
    sw[0] = 1'b0;
    # (PER * 4);  // esperar unos ciclos

    // Parte baja (SW[0]=1)
    sw[0] = 1'b1;
    # (PER * 4);

    // --------------------------------------------------
    // 6) Informe final y fin de simulación
    // --------------------------------------------------

    $display("Displays (HEX5..HEX0) final:");
    $display(" %h %h %h %h %h %h", 
      display5, display4, display3, display2, display1, display0);
    $finish;
  end

endmodule
