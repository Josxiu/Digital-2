// Este módulo decodifica un número hexadecimal de 4 bits a un formato de 7 segmentos. 
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