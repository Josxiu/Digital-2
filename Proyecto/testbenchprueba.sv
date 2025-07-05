/*
 * Testbench to test the peripherals part
 */ 
module borrador_testbench_peripherals();
	logic clk;
	logic reset;
	logic [9:0] switches, leds;
	logic button; // nueva señal para el botón

	localparam DELAY = 10;
	
	// instantiate device to be tested
	top dut(clk, reset, switches, button, leds);

	// initialize test
	initial
	begin
		button <= 1;      // Inicializa el botón como no presionado
		reset <= 0; #DELAY; 
		reset <= 1; 
		
		switches <= 10'd0;
		#(DELAY*1000);
		button <= 1; // boton no presionado
		#(DELAY*100);
		button <= 0; // boton presionado
		#(DELAY*100);
		button <= 1; // boton no presionado
		#(DELAY*100);
		button <= 0; // boton presionado
		#(DELAY*100);
		button <= 1; // boton no presionado
		#(DELAY*1000);
		$stop;
	end

	// generate clock to sequence tests
	always
	begin
		clk <= 1; #(DELAY/2); 
		clk <= 0; #(DELAY/2);
	end
endmodule