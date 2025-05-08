.global _start
        .equ    MAXN, 50
        .text

_start:
        /* Inicialización */
        LDR     r0, =N          // Dirección de N
        LDR     r1, [r0]        // r1 = N
        MOV     r2, #2
        CMP     r1, r2          // Validar N >= 2
        BLT     finish
        MOV     r2, #50
        CMP     r1, r2          // Validar N <= 50
        BGT     finish

        /* Punteros */
        LDR     r3, =Data       // r3 apunta a Data (entrada)
        LDR     r4, =SortedData // r4 apunta a SortedData (salida)

        /* Filtrar pares y copiarlos en SortedData */
        MOV     r5, #0          // r5 = contador de pares válidos

filter_loop:
        CMP     r1, #0          // ¿Ya revisamos todos?
        BEQ     sort_start

        LDR     r6, [r3], #4    // Cargar dato de Data y avanzar r3
        ANDS    r7, r6, #1      // Verificar si es par: dato & 1
        BNE     skip_store      // Si impar, saltar

        STR     r6, [r4], #4    // Guardar número par en SortedData
        ADD     r5, r5, #1      // Incrementar cantidad de pares

skip_store:
        SUB     r1, r1, #1      // Decrementar contador N
        B       filter_loop

sort_start:
        /* Ahora tenemos r5 elementos en SortedData
         * Vamos a ordenarlos en forma descendente (mayor a menor)
         */
        CMP     r5, #1          // Verificar si hay números pares
        BLE     finish          // Si r5 <= 1, no hay nada que ordenar

        /* Inicializar índices para Bubble Sort */
        LDR     r8, =SortedData // r8 = base de SortedData

outer_loop:
        CMP     r5, #1          // r5 indica el número de iteraciones restantes
        BLE     finish          // Si 0 o 1 elementos, ya está ordenado

        MOV     r9, #0          // j = 0

inner_loop:
        SUB     r10, r5, #1 // r10 = tamaño del array - 1
        CMP     r9, r10     // Comparar j con tamaño - 1
        BGE     outer_decrement // Si j >= tamaño - 1, salir del bucle interno

        /* Comparar SortedData[j] y SortedData[j+1] */
        LDR     r11, [r8, r9, LSL #2]      // leer SortedData[j]
        ADD     r13, r9, #1                // r13 = j+1
        LDR     r12, [r8, r13, LSL #2]     // leer SortedData[j+1]

        CMP     r11, r12        // (r11 >= r12)
        BGE     no_swap         // Si ya está en orden (descendente), no se intercambian posiciones (no swap)

        /* Intercambio de posiciones */
        STR     r12, [r8, r9, LSL #2]      // SortedData[j] = SortedData[j+1]
        STR     r11, [r8, r13, LSL #2]     // SortedData[j+1] = SortedData[j]

no_swap:
        ADD     r9, r9, #1      // j++
        B       inner_loop

outer_decrement:
        SUB     r5, r5, #1      // Reducir tamaño del array
        B       outer_loop

finish:
        b       finish          // Bucle infinito (fin del programa)

/* Sección de datos */
.data

/* Constantes y variables propias */
/* (puedes declarar aquí contadores extra si necesitas) */

/* Constantes y variables dadas por el profesor */
N:      .dc.l  12
Data:   .dc.l  1,15,-79,35,16,-564,8542,-89542,12021,54215,12,-35
SortedData: .ds.l  MAXN