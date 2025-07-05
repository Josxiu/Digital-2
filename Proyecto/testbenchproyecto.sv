/*
 * Testbench to test the peripherals part
 */ 
module testbenchproyecto();
	logic clk;
	logic reset;
	logic [9:0] switches, leds;
	logic button; // nueva señal para el botón
	logic [7:0] display0, display1, display2; // Señales para los displays de 7 segmentos
	logic pwm_out; // nueva señal para la salida PWM
	logic [11:0] adc_value; // Señal para el ADC
	logic [7:0] disp1_sin_p; // Señal interna para monitoreo
	logic [15:0] temp_celsius; // Señal interna para la temperatura (puede ser más de 8 bits por la división)
	localparam DELAY = 10;
	
	// instantiate device to be tested
	top dut(clk, reset, switches, button, leds, display0, display1, display2, pwm_out, adc_value);

	// initialize test
	initial
	begin
		button <= 1;      // Inicializa el botón como no presionado
		reset <= 0; #DELAY; 
		reset <= 1; 

		// Inicializar el ADC
		adc_value <= 12'd819;
		#(DELAY*1000);

		// Bucle para incrementar el ADC de 10 en 10
		repeat (50)
		begin
			adc_value <= adc_value + 50;
			#(DELAY*1000);
		end

		
		
		
		switches <= 10'd0;
		#(DELAY*20000);
		$stop;
	end

	// generate clock to sequence tests
	always
	begin
		clk <= 1; #(DELAY/2); 
		clk <= 0; #(DELAY/2);
	end

	// Proceso para actualizar y mostrar la señal interna
	always @(display1) begin
		disp1_sin_p = display1 - 8'h80;
		$display("t=%0t | display1=%0d | display1-80=%0d", $time, display1, disp1_sin_p);
	end

	always @(adc_value) begin
		// temp = (adc_value + adc_value/4) / 40
		int adc_mV;
		adc_mV = adc_value + (adc_value >> 2); // Aproximación a milivoltios
		temp_celsius = adc_mV / 4;            // División entera, resultado en °C aprox

		$display("t=%0t | adc_value=%0d | temp_celsius=%0d", $time, adc_value, temp_celsius);
	end
endmodule