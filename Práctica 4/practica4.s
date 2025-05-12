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
    BL verificar_casos // r0 = verificar_casos(r0, r1)
    CMP r0, #0 // si r0 == 0, no hay casos especiales y se procede a la resta
    BNE guardar_resultado // si r0 != 0, se omite la resta


    BL realizar_resta // r0 = realizar_resta(r0, r1)


/* Almacenar R[i] */
guardar_resultado:
    STR r0, [r6, r7, LSL #2] // Guardar resultado en R[i]
    ADD r7, r7, #1          // Incrementar contador de restas
    B loop           // Volver al inicio del bucle






// ************* FUNCIONES ***************



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
    cmp r4, #0  // si expA es positivo entonces expB es negativo
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



/*********** FUNCIÓN alinear_exponentes ***********/
/*
    Descripción:
        Alinea las mantisas de dos números IEEE-754 simple precisión
        para suma/resta, agregando el bit implícito si corresponde y
        desplazando la mantisa del número con menor exponente.

    Entradas:
        r0 = expA   (exponente de A)
        r1 = mantA  (mantisa de A, sin bit implícito)
        r2 = expB   (exponente de B)
        r3 = mantB  (mantisa de B, sin bit implícito)
    Salidas:
        r0 = exponente máximo (el que queda después de alinear)
        r1 = mantA alineada (con bit implícito si corresponde)
        r2 = mantB alineada (con bit implícito si corresponde)
*/
alinear_exponentes:
    push {r4-r8, lr}

    // Copiar argumentos a registros de trabajo
    mov r4, r0    // r4 = expA
    mov r5, r2    // r5 = expB
    mov r7, r1    // r7 = mantA
    mov r8, r3    // r8 = mantB

    // --- Agregar bit implícito si el número es normalizado ---
    cmp r4, #0            // ¿expA == 0? 
    beq sin_implicito_A   // Si expA = 0, no agregar bit implícito
    orr r7, r7, #(1 << 23) // Si expA > 0, agregar bit implícito a mantA

sin_implicito_A:
    cmp r5, #0            // ¿expB == 0?
    beq sin_implicito_B   // Si expB = 0, no agregar bit implícito
    orr r8, r8, #(1 << 23) // Si expB > 0, agregar bit implícito a mantB

sin_implicito_B:
    // --- Comparar exponentes ---
    cmp r4, r5
    bgt expA_mayor        // Si expA > expB, desplazar mantB
    blt expB_mayor        // Si expB > expA, desplazar mantA

    // expA == expB: no se desplaza ninguna mantisa
    mov r0, r4            // r0 = exponente máximo
    mov r1, r7            // r1 = mantA alineada
    mov r2, r8            // r2 = mantB alineada
    b exp_alineados

// --- expA > expB: desplazar mantB a la derecha ---
expA_mayor:
    sub r6, r4, r5        // r6 = expA - expB (cuántos bits desplazar)
    cmp r6, #24           // Si la diferencia es >= 24, mantB se hace cero
    bge mantB_a_cero
    lsr r8, r8, r6        // Desplazar mantB a la derecha r6 bits
    mov r0, r4            // r0 = exponente máximo
    mov r1, r7            // r1 = mantA alineada
    mov r2, r8            // r2 = mantB alineada
    b exp_alineados

mantB_a_cero:
    mov r8, #0            // mantB = 0 (desplazamiento total)
    mov r0, r4
    mov r1, r7
    mov r2, r8
    b exp_alineados

// --- expB > expA: desplazar mantA a la derecha ---
expB_mayor:
    sub r6, r5, r4        // r6 = expB - expA
    cmp r6, #24
    bge mantA_a_cero
    lsr r7, r7, r6        // Desplazar mantA a la derecha r6 bits
    mov r0, r5            // r0 = exponente máximo
    mov r1, r7            // r1 = mantA alineada
    mov r2, r8            // r2 = mantB alineada
    b exp_alineados

mantA_a_cero:
    mov r7, #0            // mantA = 0 (desplazamiento total)
    mov r0, r5
    mov r1, r7
    mov r2, r8
    b exp_alineados

// --- Return ---
exp_alineados:
    pop {r4-r8, lr}
    bx lr






/*************Función realizar_resta*************/
/* Descripción:
    Realiza la resta de dos números en formato IEEE-754.
    Entradas: 
        r0 = A (IEEE-754)
        r1 = B (IEEE-754)
    Salidas:
        r0 = Resultado de la resta (IEEE-754)
 */

realizar_resta:
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

    // Se preparan los parámetros para pasarlos a la función alinear_exponentes
    mov r0, r5 // r0 = expA
    mov r1, r6 // r1 = mantA
    mov r2, r8 // r2 = expB
    mov r3, r9 // r3 = mantB

    // Se llama a la función alinear_exponentes
    BL alinear_exponentes
    // Se tiene ahora que r0 = expMax, r1 = mantA alineada, r2 = mantB alineada

    







        
finish:
        b       finish          // Loop infinito para terminar el programa

        .data
R:      .ds.l  N
A:      .dc.l  0x1E06B852, 0x671706BF, 0xFFFFFFFF, 0x7F800000
B:      .dc.l  0x1E86B852, 0xE4415050, 0xE4415050, 0xFF800000
