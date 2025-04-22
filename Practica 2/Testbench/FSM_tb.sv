`timescale 1ns/1ps

module FSM_tb;
    // Señales
    logic clk;
    logic reset;
    logic btn;
    logic [3:0] estado;

    // Instancia del DUT
    FSM dut (
        .clk(clk),
        .reset(reset),
        .btn(btn),
        .estado(estado)
    );

    // Generación de reloj 10 ns periodo
    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        btn   = 0;
        #10 reset = 0;  // liberar reset

        // Recorrer todos los estados con pulsos de btn
        repeat (9) begin
            #10 btn = 1;
            #10 btn = 0;
        end

        #10 $finish;
    end

    // Dump de señales
    initial begin
        $dumpfile("FSM_tb.vcd");
        $dumpvars(0, FSM_tb);
    end

    // Monitoreo en consola
    initial begin
        $display("Time\tEstado");
        $monitor("%0t\t%0d", $time, estado);
    end

endmodule
