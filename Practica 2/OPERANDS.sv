/* Módulo que gestiona el ingreso, almacenamiento y visualización de los
   operandos y resultados */
   
module OPERANDS (
    input logic        clk,
    input logic        reset,
    input logic [3:0]  estado,       // Estado de la FSM (A1, A2, A3, A4, B1, B2, B3, B4, SAL)
    input logic [9:0]  sw,          // Entradas desde los switches de 10 bits

    input logic [31:0] resultado,    // Resultado calculado por FPALU
    output logic [31:0]  A,           // Operando A almacenado
    output logic [31:0]  B,           // Operando B almacenado

    output logic [23:0]  visualizar // Visualización en displays de 7 segmentos

);

    // Registros internos para almacenar operandos
    logic [31:0] regA, regB;
    logic vista; // Variable que se usa para saber si se muestran los primeros 6 dígitos o los últimos 2 en los displays
    assign vista = sw[0]; // Se usa el bit 0 de los switches para determinar qué mostrar en los displays

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            regA <= 32'd0;
            regB <= 32'd0;
        end else begin
            case(estado)
                // Ingreso de A, 8 bits cada estado (SW[9:2])
                4'd0: regA[31:24] <= sw[9:2]; // A1
                4'd1: regA[23:16] <= sw[9:2]; // A2
                4'd2: regA[15:8]  <= sw[9:2]; // A3
                4'd3: regA[7:0]   <= sw[9:2]; // A4

                // Ingreso de B, 8 bits cada estado (SW[9:2])
                4'd4: regB[31:24] <= sw[9:2]; // B1
                4'd5: regB[23:16] <= sw[9:2]; // B2
                4'd6: regB[15:8]  <= sw[9:2]; // B3
                4'd7: regB[7:0]   <= sw[9:2]; // B4

                // En estado SAL no se cambian A y B
                default: ;
            endcase
        end
    end

    // Asignamos los registros a las salidas correspondientes
    assign A = regA;
    assign B = regB;
    
    
    // Lógica combinacional para determinar qué mostrar en los displays según el estado actual
    // se mira que estado estamos, si estamos ingresando A o B, o mostrando el resultado
    // Dependiendo de la variable vista se muestran los primeros 6 dígitos o los últimos 2 de cada valor que se esté mostrando
    always_comb begin
        case (estado)
            4'd0, 4'd1, 4'd2, 4'd3: begin // Ingreso de A
                if (vista) begin // Si vista es 1, se muestran los últimos 2 dígitos de A
                    visualizar = {regA[7:0], 12'd0, 4'hA}; // Se muestran los últimos 2 dígitos de A en los primeros 2 displays
                end else begin // Si vista es 0, se muestran los primeros 6 dígitos de A
                    visualizar = regA[31:8]; // Se muestran los primeros 6 dígitos de A en los primeros 6 displays
                end
            end
            4'd4, 4'd5, 4'd6, 4'd7: begin // Ingreso de B
                if (vista) begin // Si vista es 1, se muestran los últimos 2 dígitos de B
                    visualizar = {regB[7:0], 12'd0, 4'hB}; // Se muestran los últimos 2 dígitos de B en los primeros 2 displays
                end else begin // Si vista es 0, se muestran los primeros 6 dígitos de B
                    visualizar = regB[31:8]; // Se muestran los primeros 6 dígitos de B en los primeros 6 displays
                end
            end
            4'd8: begin // En estado SAL se muestra el resultado de la ALU
                if (vista) begin // Si vista es 1, se muestran los últimos 2 dígitos del resultado
                    visualizar = {resultado[7:0], 12'd0, 4'hF}; // Se muestran los últimos 2 dígitos del resultado en los primeros 2 displays
                end else begin // Si vista es 0, se muestran los primeros 6 dígitos del resultado
                    visualizar = resultado[31:8]; // Se muestran los primeros 6 dígitos del resultado en los primeros 6 displays
                end
            end
            default: visualizar = 24'd0; // En caso de estado no válido, se muestra 0

        endcase
    end


    
endmodule
