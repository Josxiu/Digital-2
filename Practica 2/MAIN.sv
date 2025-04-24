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
	 logic [7:0]  Tdisplay0, Tdisplay1, Tdisplay2, Tdisplay3, Tdisplay4, Tdisplay5;
	 logic btn_clean;


        // Instanciamos la ALU (FPALU)
    FPALU fpal_inst (
        .A(op_A),
        .B(op_B),
        .S(resultado)
    );
	 
	   // Pulsador + debounce
	 Debounce #(.WIDTH(19)) dbu (
    .clk      (clk),
    .rst_n    (reset),   // tu reset activo en bajo
    .btn_in   (btn),     // entrada cruda desde KEY0
    .btn_clean(btn_clean)
  );

    // Instanciamos la FSM usando las señales invertidas
    FSM fsm_inst (
        .clk(clk),
        .reset(inv_reset),
        .btn(btn_clean),
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
        .display0(Tdisplay0),
        .display1(Tdisplay1),
        .display2(Tdisplay2),
        .display3(Tdisplay3),
        .display4(Tdisplay4),
        .display5(Tdisplay5)
    );
	

		assign display0 = ~Tdisplay0;
		// SW[0]==0 → invierte para ver guiones; SW[0]==1 → muestra valor normal
		assign display1 = (sw[0] == 1'b0) ? ~Tdisplay1 : Tdisplay1;
		assign display2 = (sw[0] == 1'b0) ? ~Tdisplay2 : Tdisplay2;
		assign display3 = (sw[0] == 1'b0) ? ~Tdisplay3 : Tdisplay3;
		
		assign display4 = ~Tdisplay4;
		assign display5 = ~Tdisplay5;
    
endmodule


