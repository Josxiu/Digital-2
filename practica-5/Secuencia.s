//=============================================================================
// Práctica 5 - Secuencia de Luces (Versión para CPUlator)
//
// Este código es la versión final y funcional, adaptada para ejecutarse
// en el simulador CPUlator. Se utilizan las pseudo-instrucciones del
// ensamblador para cargar las direcciones de los periféricos y las
// constantes, en lugar de leerlas desde una RAM.
// La lógica de las secuencias es idéntica a la versión para la FPGA.
//=============================================================================

.global _start

// --- Constantes y Direcciones para CPUlator ---
.equ BASE_ADDR,     0xFF200000      // Dirección base de periféricos en CPUlator
.equ LED_OFFSET,    0x00            // Offset para los LEDs
.equ SWITCH_OFFSET, 0x40            // Offset para los switches
.equ BUTTON_OFFSET, 0x50            // Offset para los botones
.equ DELAY_VAL,     0x2FAF08      // Valor de delay ajustado para simulación visual

_start:
    // --- Inicialización ---
    // Cargar constantes usando pseudo-instrucciones de ensamblador
    LDR     R0, =BASE_ADDR      // R0 = Dirección base de periféricos
    LDR     R2, =DELAY_VAL      // R2 = Valor de delay constante

    // Inicializar variables
    MOV     R4, #0              // R4 = estado previo del botón.
    MOV     R7, #0              // R7 = índice de crecimiento (Secuencia 2)
    MOV     R8, #0              // R8 = fase (0=encender, 1=apagar) (Secuencia 2)
    MOV     R9, #0              // R9 = dirección de crecimiento (Secuencia 2)
    MOV     R1, #5              // R1 = patrón inicial para Secuencia 1 (0b101).
    MOV     R3, #0              // R3 = dirección de desplazamiento (Secuencia 1)


//=============================================================================
// Bucle Principal
//=============================================================================
loop:
    LDR     R10, [R0, #SWITCH_OFFSET] // Leer switches.
    ANDS    R10, R10, #1              // ¿SW0 es 1?
    BNE     Secuencia2                // Sí, ir a Secuencia 2.
    BEQ     Secuencia1                // No, ir a Secuencia 1.


//=============================================================================
// Secuencia 1: Desplazamiento de Patrón (Lógica Original del Usuario)
//=============================================================================
Secuencia1:
    LDR     R5, [R0, #BUTTON_OFFSET]
    CMP     R5, #1
    BNE     update_prev_btn1
    CMP     R4, #0
    BNE     update_prev_btn1
    EOR     R3, R3, #1
update_prev_btn1:
    MOV     R4, R5

    STR     R1, [R0, #LED_OFFSET]
    MOV     R6, R2
delay1:
    SUBS    R6, R6, #1
    BNE     delay1

    CMP     R3, #0
    BEQ     ShiftLeft1

ShiftRight1:
    LSR     R1, R1, #2
    CMP     R1, #0
    BNE     loop
    MOV     R1, #1280           // Reiniciar patrón a (0b101 << 8).
    B       loop

ShiftLeft1:
    LSL     R1, R1, #2
    MOV     R11, #512
    CMP     R1, R11
    BLO     loop
    MOV     R1, #5
    B       loop


//=============================================================================
// Secuencia 2: Crecimiento Simétrico (con bucles inline)
//=============================================================================
Secuencia2:
    LDR     R5, [R0, #BUTTON_OFFSET]
    CMP     R5, #1
    BNE     update_prev_btn2
    CMP     R4, #0
    BNE     update_prev_btn2
    EOR     R9, R9, #1
    MOV     R8, #0
    MOV     R7, #0
update_prev_btn2:
    MOV     R4, R5

    MOV     R1, #0
    CMP     R9, #0
    BEQ     build_outer_to_inner

build_inner_to_outer:
    MOV     R11, #16
    MOV     R12, R7
lsr_loop_1:
    CMP     R12, #0
    BEQ     lsr_done_1
    LSR     R11, R11, #1
    SUB     R12, R12, #1
    B       lsr_loop_1
lsr_done_1:
    ORR     R1, R1, R11

    MOV     R11, #32
    MOV     R12, R7
lsl_loop_1:
    CMP     R12, #0
    BEQ     lsl_done_1
    LSL     R11, R11, #1
    SUB     R12, R12, #1
    B       lsl_loop_1
lsl_done_1:
    ORR     R1, R1, R11
    B       build_done

build_outer_to_inner:
    MOV     R11, #1
    MOV     R12, R7
lsl_loop_2:
    CMP     R12, #0
    BEQ     lsl_done_2
    LSL     R11, R11, #1
    SUB     R12, R12, #1
    B       lsl_loop_2
lsl_done_2:
    ORR     R1, R1, R11

    MOV     R11, #512
    MOV     R12, R7
lsr_loop_2:
    CMP     R12, #0
    BEQ     lsr_done_2
    LSR     R11, R11, #1
    SUB     R12, R12, #1
    B       lsr_loop_2
lsr_done_2:
    ORR     R1, R1, R11

build_done:
    CMP     R8, #1
    BNE     write_leds
    MOV     R11, #1024
    SUB     R11, R11, #1
    EOR     R1, R1, R11

write_leds:
    STR     R1, [R0, #LED_OFFSET]
    MOV     R6, R2
delay2:
    SUBS    R6, R6, #1
    BNE     delay2

    ADD     R7, R7, #1
    CMP     R7, #5
    BNE     loop

    MOV     R7, #0
    EOR     R8, R8, #1
    B       loop
