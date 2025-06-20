module Debounce #(
  parameter integer WIDTH = 19  // log2(N) donde N = #ciclos para el tiempo de debounce
)(
  input  logic clk,        // 50 MHz
  input  logic rst_n,      // reset activo en bajo
  input  logic btn_in,     // señal cruda del pulsador (activa en bajo)
  output logic btn_clean   // pulso limpio, 1 ciclo alto al liberar el botón
);

  // 1) Sincronizador de 2 etapas
  logic sync0, sync1;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync0 <= 1'b1;
      sync1 <= 1'b1;
    end else begin
      sync0 <= btn_in;
      sync1 <= sync0;
    end
  end

  // 2) Debounce con contador
  logic [WIDTH-1:0] cnt;
  logic stable;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt    <= '0;
      stable <= 1'b1;
    end else if (sync1 == stable) begin
      // aún estable: reset contador
      cnt <= '0;
    end else begin
      // cambió: contar hasta umbral
      cnt <= cnt + 1;
      if (cnt == {1'b1, {(WIDTH-1){1'b0}}})
        stable <= sync1;  // una vez llega al umbral, consideramos la nueva señal estable
    end
  end

  // 3) One‑shot al detectar flanco de subida de ‘stable’
  logic last_stable;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      last_stable <= 1'b1;
      btn_clean   <= 1'b0;
    end else begin
      btn_clean   <= (~stable) & last_stable; // de 0→1 en active‑low equivale a flanco de subida
      last_stable <= stable;
    end
  end

endmodule




