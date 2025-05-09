.global _start
    .equ N, 4
    .text

_start:
    mov     r0, #N              // Número de elementos a procesar
    ldr     r1, =A              // Dirección de A
    ldr     r2, =B              // Dirección de B
    ldr     r3, =R              // Dirección de resultado R

loop:
    cmp     r0, #0              // Si N == 0, termina
    beq     finish

    // Cargar A[i] y B[i] en r4 y r5
    ldr     r4, [r1], #4        // A[i], post-incrementa r1
    ldr     r5, [r2], #4        // B[i], post-incrementa r2

    push    {r0-r5, lr}         // Preservar registros necesarios
    bl      casos_especiales // Verifica NaN, ±inf, ceros
    pop     {r0-r5, lr}         // Restaurar registros

    str     r6, [r3], #4        // Guardar resultado en R[i]
    subs    r0, r0, #1          // N--
    b       loop

finish:
    b       finish              // Bucle infinito


// Subrutina: para verificar casos especiales de NaN, ±inf y ceros

casos_especiales:
    push {r0-r3, lr}               // Guardar registros temporales y enlace

    // Extraer exponentes y fracciones de A y B
    mov   r7, #0                   
    mov   r6, #0                   

    // Extraer campos de A
    mov   r0, r4                   // r0 = A
    mov   r1, r0, lsr #23          // r1 = A >> 23 (exponente y signo)
    and   r1, r1, #0xFF            // r1 = exponente de A (bits 30:23)
    and   r2, r0, #0x7FFFFF        // r2 = fracción de A (bits 22:0)

    // Comprobar si A es NaN (exp=255, frac≠0)
    cmp   r1, #0xFF
    bne   revisar_B
    cmp   r2, #0
    bne   tratar_A_es_NaN          // A es NaN
    // Si exp=255 y frac=0, es infinito, sigue revisando B
    b     revisar_B

tratar_A_es_NaN:
    mov   r6, r4                   // r6 = A (propagar NaN)
    mov   r7, #1                   // Bandera de caso especial = 1
    b     fin_verificar_casos

revisar_B:
    mov   r0, r5                   // r0 = B
    mov   r1, r0, lsr #23
    and   r1, r1, #0xFF            // r1 = exponente de B
    and   r2, r0, #0x7FFFFF        // r2 = fracción de B

    // Comprobar si B es NaN
    cmp   r1, #0xFF
    bne   revisar_ceros_infs
    cmp   r2, #0
    bne   tratar_B_es_NaN          // B es NaN
    // Si exp=255 y frac=0, es infinito, sigue revisando ceros
    b     revisar_ceros_infs

tratar_B_es_NaN:
    mov   r6, r5                   // r6 = B (propagar NaN)
    mov   r7, #1
    b     fin_verificar_casos

revisar_ceros_infs:


fin_verificar_casos:
    pop {r0-r3, lr}
    bx lr

.data
R:      .ds.l  N
A:      .dc.l  0x1E06B852, 0x671706BF, 0xFFFFFFFF, 0x7F800000
B:      .dc.l  0x1E86B852, 0xE4415050, 0xE4415050, 0xFF800000
