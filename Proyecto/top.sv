/*
 * This module is the TOP of the ARM single-cycle processor
 */ 
module top(input logic clk, nreset,
			  input logic [9:0] switches,
			  input logic button,
			  output logic [9:0] leds,
			  output logic [7:0] display0, display1, display2, // Display de 7 segmentos
			  output logic pwm_out // Salida PWM
			  //input logic [11:0] adc_value // Señal de prueba para el ADC
			  ); 

	// Internal signals
	logic reset;
	assign reset = ~nreset;
	logic [31:0] PC, Instr, ReadData;
	logic [31:0] WriteData, DataAdr;
	logic MemWrite;
	logic [11:0] adc_value; // Señal para el ADC
	logic [10:0] pwm_duty_cycle; // Señal para controlar el ciclo de trabajo del PWM
	//logic [7:0]  Tdisplay0, Tdisplay1, Tdisplay2;

	// *** ADC converter ***
	// Instancia del módulo ADC
	
	ADC adc_inst (
		.CLOCK(clk),
		.CH0(adc_value),
		.RESET(reset)
	);
	
	// Instantiate instruction memory
	imem imem(PC, Instr);

	// Instantiate PWM generator
	pwm pwm(clk, nreset, pwm_duty_cycle, pwm_out);

	// Instantiate data memory (RAM + peripherals)
	dmem dmem(clk, MemWrite, DataAdr, WriteData, ReadData, switches, leds, ~button, adc_value, display0, display1, display2, pwm_duty_cycle);

	/*
	// Se invierten los displays para que se vean correctamente
	assign display0 = ~Tdisplay0;
	assign display1 = ~Tdisplay1;
	assign display2 = ~Tdisplay2;
	*/
	// Instantiate processor
	arm arm(clk, reset, PC, Instr, MemWrite, DataAdr, WriteData, ReadData);
endmodule