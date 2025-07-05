.global _start

_start:

Inicialización:
    mov sp, #0xFC // Puntero del stack al final de la memoria, posición 63
    mov r12, #0 // Puntero a la dirección 0 de la memoria
    ldr r1, [r12, #0] // Carga la dirección base de periféricos (desde RAM[0]) en R1




main_loop:
    bl leer_adc // Lee el valor del ADC y lo retorna en r0
    mov r4, r0 // Mueve el valor del ADC a r4

    bl actualizar_displays // Muestra la temperatura en los displays

    bl motor_pwm // Actualiza el motor PWM con el valor del ADC

    b main_loop



fin:
    b fin


/* Función: Lee el valor del ADC y lo pasa a milivoltios con la fórmula 
mv = (ADC/4095)*5000 que equivale aproximadamente a ADC + ADC/4, ya que 5000/4095 = 1.221 y se aproxima a 1.5 = (1+1/4)
Parámetros: r1 = dirección base de periféricos
Retorna: r0 = valor del ADC convertido a mV (aproximado)
*/

leer_adc:
    add r0, r1, #0x0C // Dirección del ADC
    ldr r2, [r0, #0] // Carga el valor del ADC

    LSR r3, r2, #2 // Divide el valor del ADC entre 4
    add r2, r2, r3 // Suma el valor del ADC y ADC/4

    mov r0, r2 // Mueve el resultado a r0
    mov pc, lr


/* Función: Actualiza los displays con el valor del ADC
Parámetros: r0 = valor del ADC convertido a mV (aproximado)
            r1 = dirección base de periféricos
*/
actualizar_displays:
    LSR r0, r0, #2 // Divide el valor del ADC entre 4
    

    add r2, r1, #0x08 // Dirección del display

    

    
    mov pc, lr


motor_pwm:
    add r0, r1, #0x1C // Dirección del PWM
    mov r2, #50 // Valor del PWM

    str r2, [r0, #0] // Escribe el valor en el PWM
    mov pc, lr




