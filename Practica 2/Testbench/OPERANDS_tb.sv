`timescale 1ns/1ps

module tb_OPERANDS;

  logic clk;
  logic reset;
  logic [3:0] estado;
  logic [9:0] sw;
  logic [31:0] resultado;
  logic [31:0] A, B;
  logic [23:0] visualizar;

  // DUT (Device Under Test)
  OPERANDS dut (
    .clk(clk),
    .reset(reset),
    .estado(estado),
    .sw(sw),
    .resultado(resultado),
    .A(A),
    .B(B),
    .visualizar(visualizar)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns clock period
  end

  // Task para simular ingreso de 8 bits usando switches y estado
  task ingresar_operando(input [3:0] estado_local, input [7:0] data);
    begin
      @(posedge clk);
      estado = estado_local;
      sw[9:2] = data;
      sw[0] = 0; // mostrar parte alta
      @(posedge clk);
    end
  endtask

  initial begin
    // Inicialización
    reset = 1;
    estado = 0;
    sw = 10'd0;
    resultado = 32'hCAFEBABE;
    @(posedge clk);
    reset = 0;

    // Ingreso de A (A1 - A4)
    ingresar_operando(4'd0, 8'hAA); // A1 -> [31:24]
    ingresar_operando(4'd1, 8'hBB); // A2 -> [23:16]
    ingresar_operando(4'd2, 8'hCC); // A3 -> [15:8]
    ingresar_operando(4'd3, 8'hDD); // A4 -> [7:0]

    // Ingreso de B (B1 - B4)
    ingresar_operando(4'd4, 8'h11); // B1 -> [31:24]
    ingresar_operando(4'd5, 8'h22); // B2 -> [23:16]
    ingresar_operando(4'd6, 8'h33); // B3 -> [15:8]
    ingresar_operando(4'd7, 8'h44); // B4 -> [7:0]

    // Mostrar resultado (parte alta)
    @(posedge clk);
    estado = 4'd8;  // SAL
    sw[0] = 0;      // mostrar parte alta
    @(posedge clk);

    // Mostrar resultado (parte baja)
    sw[0] = 1;
    @(posedge clk);

    // Mostrar parte baja de A
    estado = 4'd3; // A4 (aún en estado A)
    sw[0] = 1;
    @(posedge clk);

    // Mostrar parte baja de B
    estado = 4'd7; // B4 (aún en estado B)
    sw[0] = 1;
    @(posedge clk);

    // Finalizar simulación
    $display("\nA = %h", A);
    $display("B = %h", B);
    $display("Resultado = %h", resultado);
    $display("Visualizar = %h", visualizar);
    $finish;
  end

endmodule