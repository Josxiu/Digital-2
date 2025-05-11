.global _start
        .equ    N, 4
        .text
_start:
    // Cargar el número de restas a realizar
    MOV     r0, #N          // r0 = N (número de restas)
    // se comprueba que N esté en el rango [1, 20]
    CMP     r0, #1         
    BLT     finish          // Si N < 1, termina
    CMP     r0, #20
    BGT     finish          // Si N > 20, termina


    LDR     r4, =A // Dirección de A
    LDR     r5, =B // Dirección de B
    LDR     r6, =R // Dirección de R (resultado)

    MOV     r7, #0          // contador de restas (r7 = i)

loop:       // for (i = 0; i < N; i++)
    CMP r7, #N // se verifica si ya se han realizado todas las restas
    BEQ finish // Si se han realizado todas, termina
    

    /* Leer A[i] y B[i] */
    LDR r0, [r4, r7, LSL #2] // Cargar A[i] en r0
    LDR r1, [r5, r7, LSL #2] // Cargar B[i] en r1

    // Antes de realizar la resta, se verifica si hay casos especiales como NaN o ±inf
    BL verificar_casos

    // Si la función verificar_casos retorna 0, no hay casos especiales
    // si es diferente de 0, se guarda en R[i] el valor retornado en r0
    CMP r0, #0
    BNE guardar_resultado

    /* Algoritmo para realizar R[i] = A[i] - B[i] usando procedimiento ieee754
     * El programa deberá tener al menos dos funciones que serán llamadas durante
     * la ejecución. Dichas funciones deberán emplear el Stack para mantener el valo
     * de los registros que se deberán preservar de acuerdo con la convención de regs
     */


/* Almacenar R[i] */
guardar_resultado:
    STR r0, [r6, r7, LSL #2] // Guardar resultado en R[i]
    ADD r7, r7, #1          // Incrementar contador de restas
    B loop           // Volver al inicio del bucle


/*******Función Extraer campos**********/
/*  Descripción:
    recibe como parámetro de entrada un número en formato ieee754
    y extrae el signo, exponente y mantisa

    Entradas: 
        r0 = número IEEE-754 (32 bits)
    Salidas:
        r0 = signo
        r1 = exponente
        r2 = mantisa
*/
extraer_campos:
    push {lr}
    // Guardar el valor de r0 en r3
    mov r3, r0
    // Extraer el signo bit 31
    lsr r0, r3, #31 // Desplazar a la derecha 31 bits

    // Extraer exponente bits 30:23
    lsr r1, r3, #23 // Desplazar a la derecha 23 bits
    and r1, r1, #0xFF // Se elimina el bit del signo usando una máscara

    // Extraer mantisa bits 22:0
    lsl r2, r3, #9 // Desplazar a la izquierda 9 bits para eliminar el signo y el exponente
    lsr r2, r2, #9 // Desplazar a la derecha 9 bits para volver a la posición original
    
    pop {lr}
    bx lr // Regresar de la función



/*********** FUNCIÓN verificar_casos ***********/
/*  Descripción:
    Verifica casos especiales de NaN, ±inf y ceros antes de realizar la resta de
    números en formato IEEE-754. Devuelve en r0 el valor final del resultado si se detectó
    un caso especial, si no hay ningún caso especial, devuelve 0.
    Entradas: 
        r0 = A (IEEE-754)
        r1 = B (IEEE-754)
    Salidas:
        r0 = Resultado especial (si aplica) o 0 si no hay caso especial
*/
verificar_casos:
    push {r4-r11, lr}

    // Guardar copias de A y B originales
    mov r10, r0   // copia de A
    mov r11, r1   // copia de B

    // Extraer campos de A
    BL extraer_campos
    mov r4, r0   // sA
    mov r5, r1   // eA
    mov r6, r2   // mA

    // Extraer campos de B
    mov r0, r11  // B en r0
    BL extraer_campos
    mov r7, r0   // sB
    mov r8, r1   // eB
    mov r9, r2   // mB

    // --- NaN o infinito en A ---
    cmp r5, #0xFF
    bne check_B
    cmp r6, #0      // Si el exponente es 255, y m != 0, A es NaN
    bne retornar_A    // A es NaN
    // Si mantisa es 0, A es infinito, se verifica si B también lo es
    b check_ab_inf
    

    // --- NaN o infinito en B ---
check_B:
    cmp r8, #0xFF
    bne caso_normal
    cmp r9, #0
    bne retornar_B    // B es NaN

check_ab_inf:
    // Ambos infinitos: A inf - B inf = NaN (quiet NaN)
    cmp r8, #0xFF   // si el exponende de B no es infinito devuelve A
    bne retornar_A
    cmp r9, #0      // Si la mantisa de B es diferente de 0, devuelve NaN
    bne retornar_B   // B es NaN

    // Si se llega aquí ambos son infinitos
    // se comparan signos de a y b

    cmp r4, r7  // si los signos son iguales quiere decir inf - inf = NaN
    beq retornar_NaN // if sA == sB, devolver NaN

    // si se salta beq entonces los signos son diferentes y llegamos a suma o resta de infinitos
    cmp r4, #0  // si ea es + entonces eb es -
    beq retornar_A // inf + inf = inf devuelve A
    b retornar_A // -inf - inf = -inf devuelve A

retornar_A:
    mov r0, r10
    b fin_verificar_casos
retornar_B:
    mov r0, r11
    b fin_verificar_casos
retornar_NaN:
    // Devolver qNaN
    ldr r0, =0x7FC00000
    b fin_verificar_casos

caso_normal:
    mov r0, #0

fin_verificar_casos:
    pop {r4-r11, lr}
    bx lr



        
finish:
        b       finish          // Loop infinito para bloquear ejecución

        .data
R:      .ds.l  N
A:      .dc.l  0x1E06B852, 0x671706BF, 0xFFFFFFFF, 0x7F800000
B:      .dc.l  0x1E86B852, 0xE4415050, 0xE4415050, 0xFF800000
