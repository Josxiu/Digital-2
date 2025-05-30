// Program to be deployed into the FPGA DE10-Lite
.global _start
_start:
	// Loads 0xC000_0000 into R1. Data memory returns 0xC000_0000 value
	// when address zero is read using LDR (dmem_to_test_peripherals.dat).
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
	LDR		R1, [R0, #0]	// Loads 0xC000_0000 into R1
Counter:	
	// Counts up to the value provided by the switches (0xC000_0000)
	// and writes it into the leds (0xC000_0004)
	SUB		R2, R15, R15
Loop:
	LDR		R3, [R1]		// Read the switches
	CMP		R2, R3		// R4 as a temporal register
	BLS		WriteToLeds
	SUB		R2, R15, R15	// Reset the value
WriteToLeds:	
	STR		R2, [R1, #4]	// Write counter into LEDs
	// Loads delay value into R3. Data memory returns delay value
	// when address four is read using LDR (dmem_to_test_peripherals.dat).
	LDR		R3, [R0, #4]	// Loads delay value into R3
Delay:
	SUB		R3, R3, #1
	CMP		r3, #0
	BNE		Delay
	ADD		R2, R2, #1		// Increment counter
	B		Loop
End:	
	B		End				// It should never happen
