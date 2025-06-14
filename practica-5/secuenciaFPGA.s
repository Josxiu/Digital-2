.global _start
.equ BASE_ADDR, 0xFF200000
.equ LED_OFFSET, 0x00
.equ BUTTON_OFFSET, 0x50
.equ DELAY_VAL, 0x2FAF08

_start:
	MOV		R0, #0
	MOV		R1, #0
	MOV		R2, #0
	MOV		R3, #0
	MOV		R4, #0
	MOV		R5, #0
	MOV		R6, #0
	MOV		R7, #0
	MOV		R8, #0
	MOV		R9, #0
	MOV		R10, #0
	MOV		R11, #0
    LDR     R0, [R0]    // R0 apunta a la base de periféricos

    MOV     R1, #0b101            // R1 = patrón inicial (LED 0 encendido)
    MOV     R2, #2            // R2 = desplazamiento (dos bits a la izquierda)
    MOV     R3, #0            // R3 = dirección (0 = izquierda, 1 = derecha)
    MOV     R4, #0            // R4 = estado anterior del botón

loop:
    // Leer botón
    LDR     R5, [R0, #8] // Leer botones
    ands    R6, R5, #1                   // ¿Se presionó KEY[0]?
    BEQ     continuar                // Si no, continuar

    CMP     R4, #0                   // Detectar flanco de subida
    BNE     continuar                // Ya estaba presionado antes

    // Cambiar dirección
    EOR     R3, R3, #1               // Alternar dirección (0 <-> 1)

continuar:
    // Guardar estado del botón actual
    MOV     R4, R5

    // Escribir a los LEDs
    STR     R1, [R0, #4]

    // Delay
    LDR     R6, [R6, #4]
delay_loop:
    SUBS    R6, R6, #1
    BNE     delay_loop

    // Desplazar patrón
    CMP     R3, #0          // ¿Dirección a la izquierda?
    BEQ     shift_left

shift_right:
    LSR     R1, R1, #2      // Desplazar 2 bits a la derecha
    CMP     R1, #0
    BNE     loop
    MOV     R1, #(0b101 << 8)   // Reiniciar en LED 8 si llegó al final
    B       loop

shift_left:
    LSL     R1, R1, #2      // Desplazar 2 bits a la izquierda
    CMP     R1, #(1 << 9)
    BLO     loop
    MOV     R1, #0b101          // Reiniciar en LED 0 si llegó al final
    B       loop
