.global _start
		_start:

        MOV     R0, #0xF0       
        MOV     R1, #0x01       
		
        MOV     R2, R0, LSL #4
		
		MOV		R9, R2, LSR #1


        MOV     R3, R0, LSR #1

        MOV     R4, R0, ASR #1

        MOV     R5, R0, ROR #2
		
		Mov 	R6, R2, LSR #4
		
		lsl		R0, #22
		
		add r7, r0, r2, lsr #2
		orr r8, r7, r2, ror #9
		mov r10, #0
		mov r11, #11
		lsl r11, #11
		orr r10, r11

        // Detener ejecución (bucle infinito)
end:    B       end