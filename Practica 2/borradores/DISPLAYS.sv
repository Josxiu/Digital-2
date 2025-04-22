module deco7seg_hexa( 
input  logic [3:0] D, 
output logic [7:0] SEG); 
always_comb begin 
case(D)  
// pgfe_dcba 
4'h0: SEG = 8'b0011_1111; 
4'h1: SEG = 8'b0000_0110; 
4'h2: SEG = 8'b0101_1011; 
4'h3: SEG = 8'b0100_1111; 
4'h4: SEG = 8'b0110_0110; 
4'h5: SEG = 8'b0110_1101; 
4'h6: SEG = 8'b0111_1101; 
4'h7: SEG = 8'b0000_0111; 
4'h8: SEG = 8'b0111_1111; 
4'h9: SEG = 8'b0110_0111; 
4'hA: SEG = 8'b0111_0111; 
4'hB: SEG = 8'b0111_1100; 
4'hC: SEG = 8'b0011_1001; 
4'hD: SEG = 8'b0101_1110; 
4'hE: SEG = 8'b0111_1001; 
4'hF: SEG = 8'b0111_0001; 
endcase 
end 
endmodule

module DISPLAYS (
    input  logic [23:0] D,     // Número a mostrar
    output logic [7:0]  display0,  // Display HEX0 (más a la derecha)
    output logic [7:0]  display1,  // Display HEX1
    output logic [7:0]  display2,  // Display HEX2
    output logic [7:0]  display3,  // Display HEX3
    output logic [7:0]  display4,  // Display HEX4
    output logic [7:0]  display5   // Display HEX5 (más a la izquierda)
);

    // Componentes individuales
    logic [3:0] d1, d2, d3, d4, d5, d6;

    assign d1 = D[23:20];
    assign d2 = D[19:16];
    assign d3 = D[15:12];
    assign d4 = D[11:8];
    assign d5 = D[7:4];
    assign d6 = D[3:0];

    // Instanciación de los módulos decodificadores
    deco7seg_hexa dd1(d1, display5);
    deco7seg_hexa dd2(d2, display4);
    deco7seg_hexa dd3(d3, display3);
    deco7seg_hexa dd4(d4, display2);
    deco7seg_hexa dd5(d5, display1);
    deco7seg_hexa dd6(d6, display0);
    

endmodule

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