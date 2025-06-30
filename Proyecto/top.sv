/*
 * This module is the TOP of the ARM single-cycle processor
 */ 
module top(input logic clk, nreset,
			  input logic [9:0] switches,
			  input logic button,
			  output logic [9:0] leds,
			  output logic [7:0] display0, display1, display2); // Display de 7 segmentos

	// Internal signals
	logic reset;
	assign reset = ~nreset;
	logic [31:0] PC, Instr, ReadData;
	logic [31:0] WriteData, DataAdr;
	logic MemWrite;
	logic [11:0] adc_value; // Señal para el ADC
	logic [7:0]  Tdisplay0, Tdisplay1, Tdisplay2;

	// *** ADC converter ***
	// Instancia del módulo ADC
	/*
	ADC adc_inst (
		.CLOCK(clk),
		.CH0(adc_value),
		.RESET(reset)
	);
	*/
	// Instantiate instruction memory
	imem imem(PC, Instr);

	// Instantiate data memory (RAM + peripherals)
	dmem dmem(clk, MemWrite, DataAdr, WriteData, ReadData, switches, leds, ~button, adc_value, Tdisplay0, Tdisplay1, Tdisplay2);

	// Se invierten los displays para que se vean correctamente
	assign display0 = Tdisplay0;
	assign display1 = Tdisplay1;
	assign display2 = Tdisplay2;

	// Instantiate processor
	arm arm(clk, reset, PC, Instr, MemWrite, DataAdr, WriteData, ReadData);
endmodule