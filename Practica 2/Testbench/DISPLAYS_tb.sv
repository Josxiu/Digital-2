`timescale 1ns/1ps

module tb_DISPLAYS;

  logic [23:0] D;
  logic [7:0] display0, display1, display2, display3, display4, display5;

  // Instancia del módulo bajo prueba
  DISPLAYS dut (
    .D(D),
    .display0(display0),
    .display1(display1),
    .display2(display2),
    .display3(display3),
    .display4(display4),
    .display5(display5)
  );

  // Tarea para mostrar los valores de los displays
  task mostrar_displays;
    input string mensaje;
    begin
      $display("--- %s ---", mensaje);
      $display("D = 0x%8h", D);
      $display("Display5: %8b", display5);
      $display("Display4: %8b", display4);
      $display("Display3: %8b", display3);
      $display("Display2: %8b", display2);
      $display("Display1: %8b", display1);
      $display("Display0: %8b\n", display0);
    end
  endtask

  initial begin
    // Caso 1: mostrar primeros 24 bits (6 displays)
    D = 24'hDEADBE;
    #10;
    mostrar_displays("(primeros 6 Hex)");

    // Caso 2: mostrar los últimos 8 bits (2 displays)
    D = 24'h000000EF; // Cambiamos el valor de D para mostrar los últimos 8 bits
    #10;
    mostrar_displays("(últimos 2 Hex)");

    // otro número en hexadecimal 12345678
    // Caso 3: mostrar los primeros 6 bits (6 displays)
    D = 24'h123456;
    #10;
    mostrar_displays("primeros 6 Hex (123456)");

    // Caso 4: mostrar los últimos 8 bits (2 displays)
    D = 24'h00000078; // Cambiamos el valor de D para mostrar los últimos 8 bits
    #10;
    mostrar_displays("últimos 2 Hex (00000078)");

    $finish;
  end

endmodule