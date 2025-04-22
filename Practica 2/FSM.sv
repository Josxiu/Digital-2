module FSM (
    input logic clk,
    input logic reset,
    input logic btn,
    output logic [3:0] estado);
    
    // Definición de los 9 estados
    typedef enum logic [3:0] {
        A1 = 4'd0, A2 = 4'd1, A3 = 4'd2, A4 = 4'd3, // Ingreso de A
        B1 = 4'd4, B2 = 4'd5, B3 = 4'd6, B4 = 4'd7, // Ingreso de B
        SAL = 4'd8 // resultado
    } state;

    // State register
    state currentState, nextState;

    // State transition logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            currentState <= A1; // Estado inicial
        end else begin
            currentState <= nextState;
        end
    end

    // State output logic
    always_comb
        case (currentState)
            A1: if(btn) nextState = A2; else nextState = A1;
            A2: if(btn) nextState = A3; else nextState = A2;
            A3: if(btn) nextState = A4; else nextState = A3;
            A4: if(btn) nextState = B1; else nextState = A4;
            B1: if(btn) nextState = B2; else nextState = B1;
            B2: if(btn) nextState = B3; else nextState = B2;
            B3: if(btn) nextState = B4; else nextState = B3;
            B4: if(btn) nextState = SAL; else nextState = B4;
            SAL: if(btn) nextState = A1; else nextState = SAL;
            default: nextState = A1;
        endcase

    // Output logic
    assign estado = currentState;

endmodule