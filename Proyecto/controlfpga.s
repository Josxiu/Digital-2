.global _start

_start:
    // Se inicializan los registros

    MOV     R12, #0             // Puntero temporal a la RAM.
    LDR     R4, [R12, #0]       // R4 <= Dirección Base de Periféricos.
    MOV     R5, #8              // R5 <= Dirección Base de la tabla de 7-seg (0x08).
    MOV     SP, #0xFC           // SP <= Puntero de Pila.

main_loop:
    // Leer Sensor y Actualizar Estado ---
    BL      _leer_y_convertir_adc // Retorna Temp*10 en R0.
    MOV     R6, R0              // Guarda el resultado en el registro de estado R6.

    // Actualizar Displays
    MOV     R0, R6              // Carga el parámetro para _actualizar_displays.
    BL      _actualizar_displays

    // Control del Motor
    MOV     R0, R6              // Carga el parámetro Temp*10 para el motor.
    MOV     R1, R4              // Carga el parámetro DirBase de periféricos.
    BL      _control_motor_pwm    // Llama a la función de control del motor.

    B       main_loop

//=============================================================================
// Subrutina: _leer_y_convertir_adc
// Propósito: Lee el sensor y calcula la Temp*10.
// Retorna: R0 = Temp*10
//=============================================================================
_leer_y_convertir_adc:
    ADD     R1, R4, #12         // R1 = Dirección del ADC (usa la base de R4).
    LDR     R2, [R1, #0]        // R2 = Valor crudo del ADC.

    // Convierte a mV y luego a Temp*10
    // mv = ADC * 5000/4095 = ADC * 1.221 mV, se aproxima 1.221mv a 1.25mv
    // Entonces ADC * 1.5mv = ADC(1+1/4)
    LSR     R3, R2, #2          // Divide el valor del ADC entre 4
    ADD     R2, R2, R3          // Suma el valor del ADC y ADC/4

    // Ya que se lee el voltaje con una ganancia de 4, se divide por ese valor para obtener el voltaje real
    LSR     R0, R2, #2          // R0 = Temp*10 = mV / 4

    MOV     PC, LR


//=============================================================================
// Subrutina: _actualizar_displays
// Propósito: Muestra un valor en los displays en formato XX.X
// Parámetros: R0 = Valor Temp*10 a mostrar.
//=============================================================================
_actualizar_displays:
    SUB     SP, SP, #24         // Espacio para 6 registros (LR, R4, R5, R7, R8, R9).
    STR     LR, [SP, #20]
    STR     R4, [SP, #16]
    STR     R5, [SP, #12]
    STR     R7, [SP, #8]
    STR     R8, [SP, #4]
    STR     R9, [SP, #0]

    

        // Límite de los displays
    // Limita el valor a mostrar al máximo de 99.9 (999).
    MOV     R2, #1024           // Carga 1024 (inmediato válido).
    SUB     R2, R2, #25         // R2 = 1024 - 25 = 999.
    CMP     R0, R2              // Compara la temperatura (en R0) con 999.
    MOVGT   R0, R2              // Si es mayor (GT), la fija en 999.
	
	// Separar las decenas del resultado anterior
    MOV     R1, R0              // Copia el parámetro de entrada (Temp*10) a R1.

    // 1. Obtener Decenas y Unidades.
    MOV     R0, R1              // Argumento para _divide
    MOV     R1, #10             // Divisor
    BL      _divide             // Divide. Retorna: R0=Cociente (25), R1=Residuo (3)
    MOV     R7, R0              // R7 = Decenas y Unidades (ej. 25)
    MOV     R9, R1              // R9 = Dígito Decimal (ej. 3)

    // 2. Separar las decenas del resultado anterior
    MOV     R0, R7              // Argumento para _divide
    MOV     R1, #10             // Divisor
    BL      _divide             // Divide. Retorna: R0=2, R1=5
    MOV     R7, R0              // R7 = Dígito de Decenas (ej. 2)
    MOV     R8, R1              // R8 = Dígito de Unidades (ej. 5)

    // 2. Mostrar en los displays
    LDR     R4, [SP, #16]       // Recuperar DirBase de periféricos a R4.
    LDR     R5, [SP, #12]       // Recuperar DirBase de la tabla a R5.

    // Display 2 (Decenas, R7)
    LSL     R1, R7, #2
    ADD     R1, R5, R1
    LDR     R2, [R1, #0]
    ADD     R3, R4, #24
    STR     R2, [R3, #0]

    // Display 1 (Unidades, R8) con punto
    LSL     R1, R8, #2
    ADD     R1, R5, R1
    LDR     R2, [R1, #0]
    ORR     R2, R2, #128
    ADD     R3, R4, #20
    STR     R2, [R3, #0]

    // Display 0 (Decimal, R9)
    LSL     R1, R9, #2
    ADD     R1, R5, R1
    LDR     R2, [R1, #0]
    ADD     R3, R4, #16
    STR     R2, [R3, #0]

    // --- RESTAURAR REGISTROS ---
    LDR     R9, [SP, #0]
    LDR     R8, [SP, #4]
    LDR     R7, [SP, #8]
    LDR     R5, [SP, #12]
    LDR     R4, [SP, #16]
    LDR     LR, [SP, #20]
    ADD     SP, SP, #24
    MOV     PC, LR


//=============================================================================
// Subrutina: _divide
// Parámetros: R0=Numerador, R1=Divisor. Retorna: R0=Cociente, R1=Residuo
//=============================================================================
_divide:
    MOV     R2, #0              // R2 = Cociente, inicializar a 0
divide_loop:
    CMP     R0, R1              // ¿Numerador >= Divisor?
    BLT     divide_done         // Si es menor, la división ha terminado.
    SUB     R0, R0, R1          // Numerador = Numerador - Divisor
    ADD     R2, R2, #1          // Cociente++
    B       divide_loop
divide_done:
    MOV     R1, R0              // Mover residuo a R1.
    MOV     R0, R2              // Mover cociente a R0.
    MOV     PC, LR              // Retornar.


//=============================================================================
// Subrutina: _control_motor_pwm
// Propósito: Ajusta la velocidad del motor según la temperatura.
// 0 si T es menor a 20, máxima si T es mayor a 40, y entre 20 y 40 es proporcional
// El ancho del pulso va de 0 a 2000
// Parámetros:
//   - R0: Valor Temp*10 (ej: 253 para 25.3°C)
//   - R1: Dirección base de los periféricos.
//=============================================================================
_control_motor_pwm: