TITLE Proj6     (Proj6_horne.asm)

; Author: Eric Horn
; Description: The program asks the user to input ten numbers, which the program takes as character/ASCII values. 
;	Each number is converted from ASCII to decimal, then stored to an array.
;	The program then displays the elements stored within the array, the sum of the numbers, and their truncated average. 

INCLUDE Irvine32.inc

; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Description:
;	Displays a prompt and saves the ASCII input from the user to a memory location. 
;
; Preconditions: 
;	Do not use EAX, EBX, or EDX as arguments.
;
; Receives:
;	address	; string prompt
;	address	; output address
;	address	; buffer size 
;	address	; bytes read 
;
; Returns: 
;	Saves ACSII input to a memory location.
; ---------------------------------------------------------------------------------
mGetString MACRO prompt, outputAddress, bufferSize, bytesRead
	
	; Save registers.
	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDX

	; Get user input.
	MOV		EDX, prompt		
	CALL	WriteString
	MOV		EDX, outputAddress		
	MOV		ECX, bufferSize
	MOV		ECX, [ECX]
	CALL	ReadString
	MOV		EBX, bytesRead
	MOV		[EBX], EAX		; Store value of bytes read at the address of [bytesRead]

	;Restore registers.
	POP		EDX
	POP		ECX
	POP		EBX
	POP		EAX
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Description:
;	Prints a string stored at a memory location. 
;	Calls WriteString to print the string.
;
; Preconditions: 
;	Do not use EDX as an argument.
;
; Receives:
;	address	; string
;
; Returns: 
;	Prints the value at a memory location.
; ---------------------------------------------------------------------------------
mDisplayString MACRO string

	; Save registers.
	PUSH	EDX

	MOV		EDX, string
	CALL	WriteString

	; Restore registers.
	POP		EDX

ENDM

; Constants
STRINGLENGTH = 12							; # digits in an SDWORD string, including null operator and optional prefix
SIZEOFINTARRAY = 10

.data

; Prompts and statements.
intro1				BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures. ",13,10
					BYTE	"Written by: Eric Horn",13,10
					BYTE	13,10
					BYTE	"Please provide 10 signed decimal integers. ",13,10
					BYTE	"Each number needs to be small enough to fit inside a 32 bit register. ",13,10
					BYTE	"After you have finished inputting the raw numbers I will display a list of the integers,",13,10
					BYTE	"their sum, and their average value.",13,10
					BYTE	13,10,0
youEntered			BYTE	"You entered the following numbers: ",0
sumOfNum			BYTE	"The sum of these numbers is: ",0
truncatedAvg		BYTE	"The truncated average is: ",0
thanksForPlaying	BYTE	"Thanks for playing!",0
prompt1				BYTE	"Please enter an signed number: ",0
errorMsg			BYTE	"ERROR: You did not enter a signed number or your number was too big.",13,10
					BYTE	"Please try again: ",0
subtotal			BYTE	"Running subtotal: ",0
extraCredit1		BYTE	"**EC: Number each line and display a running subtotal.",13,10
					BYTE	13,10,0

; ReadVal variables
userInputString		BYTE	STRINGLENGTH DUP(0)								
userInputLength		DWORD	LENGTHOF userInputString
userInputBytesCount	DWORD	?
userInputNum		SDWORD	?

; WriteVal variables.
tempStringArray1	BYTE	STRINGLENGTH DUP(0)
tempArrayLength		DWORD	LENGTHOF tempStringArray1
tempStringArray2	BYTE	STRINGLENGTH DUP(0)

; Other variables
tenNumArray			SDWORD	SIZEOFINTARRAY DUP(0)		
tenNumArrayLength	DWORD	LENGTHOF tenNumArray

.code
main PROC

	; Introduction.
	mDisplayString OFFSET intro1

	; Extra credit statement.
	mDisplayString OFFSET extraCredit1

	; Prompt user for input and fill array with 10 integers.
	PUSH	OFFSET subtotal					
	PUSH    OFFSET tempArrayLength			
	PUSH	OFFSET tempStringArray2			
	PUSH	OFFSET tempStringArray1			
	PUSH	tenNumArrayLength
	PUSH	OFFSET tenNumArray
	PUSH	OFFSET errorMsg
	PUSH	OFFSET userInputNum
	PUSH	OFFSET prompt1
	PUSH	OFFSET userInputString
	PUSH	OFFSET userInputLength					
	PUSH	OFFSET userInputBytesCount
	CALL	fillArray

	; Print integers with in the array.
	PUSH	OFFSET youEntered
	PUSH	tenNumArrayLength
	PUSH	tempArrayLength
	PUSH	OFFSET tempStringArray2
	PUSH	OFFSET tempStringArray1		
	PUSH	OFFSET tenNumArray						
	CALL	printArray

	; Sum, average, and print the integers within the array.
	PUSH    OFFSET truncatedAvg
	PUSH	OFFSET sumOfNum
	PUSH	tenNumArrayLength
	PUSH	tempArrayLength
	PUSH	OFFSET tempStringArray2
	PUSH	OFFSET tempStringArray1		
	PUSH	OFFSET tenNumArray						
	CALL	sumAvgArray

	; Say goodbye.
	mDisplayString OFFSET thanksForPlaying
	CALL	CrLF

Invoke ExitProcess,0						; exit to operating system
main ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
; 
; Description:
;	Converts a string of ASCII characters to their numeric value representation. 
;	Checks for valid input (see below).
;
; Preconditions: 
;	Numerical value being converted must be < 32-bits (-2^31 to (2^31)-1)
;	Will accept (+ or -) characters as the first character.
;	All other characters must be between 0 & 9.
;
; Postconditions: 
;	All general registers modified.
;	
; Receives: 	
;	PUSH	OFFSET	; errorMsg
;	PUSH	OFFSET	; userInputNum
;	PUSH	OFFSET	; prompt1
;	PUSH	OFFSET	; userInputString
;	PUSH	OFFSET	; userInputLength
;	PUSH	OFFSET	; userInputBytesCount
;	
;
; Returns: Numerical value stored in userInputNum.
; ---------------------------------------------------------------------------------
ReadVal PROC

	; Preserve EBP, update its new location, and create local variables.
	LOCAL	signValue:DWORD, ineligiblePrefix:DWORD
	MOV		signValue, 0
	MOV		ineligiblePrefix, 0

	; Preserve registers.
	PUSHAD

; --------------------------
; Asks user for input, which is then stored in a variable.
;	Each character of the input is validated during each loop iteration.
;	Once validated, the previous total is multipied by 10. 
;	The current character is converted to decimal and added to the previous total.
;	Overflow is checked, and the loop repeats until all characters have been converted.
;	The decimal value is saved in an output variable.
; --------------------------
_getUserInput:
	; Get user input (initial prompt).
	mGetString [EBP+20], [EBP+16], [EBP+12], [EBP+8]		;  prompt1, address to store user input (string), buffer size, length (output).
	JMP		_prepLoop

_error:
	; Print error message and reset ineligiblePrefix checker.
	mGetString [EBP+28], [EBP+16], [EBP+12], [EBP+8]		;  errorMsg, address to store user input (string), buffer size, length (output).
	MOV		ineligiblePrefix, 0

_prepLoop:
	; Prep loop counter.
	CLD
	MOV		EBX, [EBP+8]					; Address of length.
	MOV		ECX, [EBX]				
	MOV		ESI, [EBP+16]					; Input value (string).
	MOV		EDI, [EBP+24]					; Address to store value (number).
	MOV		EDI, 0					

	; If user didn't enter a value, jump to _error.
	MOV		EAX, [EBX]
	CMP		EAX, 0
	JE		_error

_valLoop:
	; Loop checks every character within the given string.
	LODSB

_checkPrefix:
	; Check if first character is (+ or -).
	CMP		AL, 43
	JE		_prefixPosValue
	CMP		AL, 45
	JE		_prefixNegValue

_validateNum:
	; Check if first character is between dec values 0-9.
	CMP		AL, 48
	JL		_error
	CMP		AL, 57
	JG		_error							; Character is not a valid prefix (+ or -) or number.
	JMP		_convertToDec

_prefixPosValue:
	; First character = '+'
	CMP		ineligiblePrefix, 1				; After first character, prefix not allowed.
	JE		_error
	LOOP	_valLoop						; Move to second character.
	
_prefixNegValue:
	; First character = '-'
	CMP		ineligiblePrefix, 1				; After first character, prefix not allowed.
	JE		_error

	; Flag number as negative and move to second character.
	MOV		signValue, 1
	LOOP	_valLoop

_convertToDec:
	; Subtract 48 from character value and multiply by 10.
	MOVZX	EBX, AL
	SUB		EBX, 48							
	MOV		EAX, 10
	MUL		EDI
	MOV		EDI, EAX						; Move quotient to EDI for further calculation.

	; If prefix negative.
	CMP		signValue, 1
	JNE		_addPositive
	SUB		EDI, EBX						; Subtract negative values from EDI.
	JMP		_checkOverflow

_addPositive:
	ADD		EDI, EBX						; Add positive values to EDI.

_checkOverflow:
	; Check to see if conversion causes overflow (value too large for 32-bit register).
	JO		_error
	MOV		ineligiblePrefix, 1				; Flag prefix value as inelgible after first element.
	LOOP	_valLoop

	; Store numerical value in output variable.
	MOV		EBX, [EBP+24]
	MOV		[EBX], EDI

_finish:
	; POP saved registers in reverse order and dereference the stack.
	POPAD
	RET		24

ReadVal ENDP

; ---------------------------------------------------------------------------------
; Name: WriteVal
; 
; Description:
;	Converts a numeric SDWORD value to a string of ASCII digits. 
;	Prints the string to console.
;
; Preconditions: 
;	Temp array 1 and temp array 2 may only contain the value zero/null.
;
; Postconditions: 
;	All general registers modified.
;	
; Receives: 	
;	PUSH	(value)	; Temp array 1 length.
;	PUSH	OFFSET	; Temp array 2 address.
;	PUSH	OFFSET	; Temp array 1 address.
;	PUSH	(value)	; Numeric value being to ACSII. 
;	
; Returns: None.
; ---------------------------------------------------------------------------------
WriteVal PROC

	; Preserve EBP, update its new location, and create local variables.
	LOCAL	signValue:DWORD, byteLength:DWORD
	MOV		signValue, 0
	MOV		byteLength, 0

	; Preserve registers.
	PUSHAD

	; Prep loop and array. 	
	STD
	MOV		EAX, [EBP+8]					; Input decimal value.
	MOV		EDI, [EBP+12]					; tempStringArray1 address.
	MOV		ECX, [EBP+20]					; Length of array value.
	DEC		ECX								; Leave first digit for possible prefix.
	ADD		EDI, ECX						; Begin at end of string. Move in reverse.	
	DEC		EDI								; Leave last digit for null operator.

	; Determine if integer is negative or positive.
	CMP		EAX, 0
	JGE		_loop1
	MOV		signValue, 1					; Track negative values.
	NEG		EAX

_loop1:
	; Divide by 10. Remainder in EDX = one's place digit of decimal value.
	MOV		EDX, 0
	MOV		EBX, 10
	DIV		EBX			
	MOV		EBX, EAX						; Save quotient for future calculation.

	; Convert digit to ASCII character.
	MOV		EAX, EDX			
	ADD		EAX, 48

	; Store digit in array (backwards).
	STOSB									; Store digit in temp array 1 (backwards).
	INC		byteLength
	MOV		EAX, EBX						; Move quotient.
	CMP		EAX, 0
	JNE		_loop1		

	; Retore negative prefix.
	CMP		signValue, 1					; Add potential negative prefix as first element of string.
	JNE		_trimString
	MOV		EAX, 45
	INC		byteLength
	STOSB

_trimString:
	; Prep temp arrays.
	CLD
	MOV		ECX, byteLength
	MOV		ESI, [EBP+12]					; tempStringArray1
	MOV		EBX, byteLength
	INC		EBX
	MOV		EDX, [EBP+20]
	SUB		EDX, EBX						; Determine location in temp array 1 of first element.
	ADD		ESI, EDX						; Move ESI to first element.
	MOV		EDI, [EBP+16]					; tempStringArray2

_loop2:
	; Load from temp array 1 and copy into temp array 2.
	LODSB
	STOSB
	LOOP	_loop2

	; Display temp array 2.
	mDisplayString [EBP+16]

	; Reset values of temp array 1.
	CLD
	MOV		EAX, 0
	MOV		ECX, [EBP+20]
	MOV		EDI, [EBP+12]
	REP		STOSB

	; Reset values of temp array 2.
	MOV		ECX, [EBP+20]
	MOV		EDI, [EBP+16]
	REP		STOSB

_end:
	; POP saved registers in reverse order and dereference the stack.
	POPAD
	RET		16

WriteVal ENDP

; ---------------------------------------------------------------------------------
; Name: fillArray
; 
; Description:
;	Calls ReadVal to prompt the user to enter an integer value, which is stored as a string.
;	ReadVal converts the string to a decimal value.
;	fillArray stores the decimal value in an array. The array's length is variable.
;	fillArray calls writeVal to display the running subtotal value. 
;	The loop is repeated SIZEOFINTARRAY times.
;
; Preconditions: 
;	Temp array 1 and temp array 2 may only contain the value zero/null.
;
; Postconditions: 
;	All general registers modified.
;	
; Receives: 	
;	PUSH	OFFSET subtotal					; For the writeVal subprocedure 
;	PUSH    OFFSET tempArrayLength			; For the writeVal subprocedure
;	PUSH	OFFSET tempStringArray2			; For the writeVal subprocedure
;	PUSH	OFFSET tempStringArray1			; For the writeVal subprocedure
;	PUSH	(value) tenNumArrayLength
;	PUSH	OFFSET tenNumArray
;	PUSH	OFFSET errorMsg					; For the readVal subprocedure
;	PUSH	OFFSET userInputNum				; For the readVal subprocedure
;	PUSH	OFFSET prompt1					; For the readVal subprocedure
;	PUSH	OFFSET userInputString			; For the readVal subprocedure
;	PUSH	OFFSET userInputLength			; For the readVal subprocedure		
;	PUSH	OFFSET userInputBytesCount		; For the readVal subprocedure
;	
; Returns: An array filled with SDWORDs, size determined by SIZEOFINTARRAY.
; ---------------------------------------------------------------------------------
fillArray PROC

	; Preserve EBP, update its new location, and create local variables.
	LOCAL	localSubtotal:SDWORD
	MOV		localSubtotal, 0

	; Preserve registers.
	PUSHAD

	; Prep loop counter
	CLD
	MOV		ECX, [EBP+36]					; Size of array being filled.
	MOV		EDI, [EBP+32]					; Array being filled.
	MOV		EBX, 1							; Track line number

_loop:
	; EC1: Number each line of user input (must use WriteVal)
	MOV		EAX, [EBP+48]
	PUSH	[EAX]							; Temp array 1 length.
	PUSH	[EBP+44]						; Temp array 2 address.
	PUSH	[EBP+40]						; Temp array 1 address.
	PUSH	EBX								; Value being converted.
	CALL	WriteVal
	MOV		AL, ":"
	CALL	WriteChar
	MOV		AL, " "
	CALL	WriteChar

	; Get user input for array element.
	PUSH	[EBP+28]						; errorMsg
	PUSH	[EBP+24]						; userInputNum
	PUSH	[EBP+20]						; prompt1
	PUSH	[EBP+16]						; userInputString
	PUSH	[EBP+12]						; userInputLength
	PUSH	[EBP+8]							; userInputBytesCount
	CALL	ReadVal

	; Store numerical value in array.
	INC		EBX								; Track line number.
	MOV		EAX, [EBP+24]					; userInputNum
	MOV		EAX, [EAX]		
	STOSD

	; Display subtotal.
	ADD		EAX, localSubtotal
	MOV		localSubtotal, EAX
	mDisplayString [EBP+52]
	MOV		EAX, [EBP+48]
	PUSH	[EAX]							; Temp array 1 length.
	PUSH	[EBP+44]						; Temp array 2 address.
	PUSH	[EBP+40]						; Temp array 1 address.
	PUSH	localSubtotal					; Value being converted.
	CALL	WriteVal
	CALL	CrLF
	CALL    CrLF
							
	LOOP	_loop

	; POP saved registers in reverse order and dereference the stack.
	POPAD
	RET		48

fillArray ENDP

; ---------------------------------------------------------------------------------
; Name: printArray
; 
; Description:
;	Prints the values within an array. 
;	Calls the WriteVal procedure to print each decimal value
;
; Preconditions: 
;	Temp array 1 and temp array 2 may only contain the value zero/null.
;
; Postconditions: 
;	All general registers modified.
;	
; Receives: 	
;	PUSH	OFFSET youEntered
;	PUSH	(value) tenNumArrayLength
;	PUSH	(value) tempArrayLength			; for WriteVal subprocedure
;	PUSH	OFFSET tempStringArray2			; for WriteVal subprocedure
;	PUSH	OFFSET tempStringArray1			; for WriteVal subprocedure
;	PUSH	OFFSET tenNumArray	
;	
; Returns: 
;	Prints: "You entered the following numbers:"
;	Prints:	A comma-separated list of array values.
; ---------------------------------------------------------------------------------
printArray PROC

	; Preserve EBP, update its new location, and create LOCAL.
	LOCAL	signValue:DWORD
	MOV		signValue, 0

	; Preserve registers.
	PUSHAD

	; Print: "You entered the following numbers:"
	mDisplayString [EBP+28]
	CALL	CrLF
	
	; Prep loop.
	CLD
	MOV		ESI, [EBP+8]					; Dec Array address.
	MOV		ECX, [EBP+24]					; Length of 10 array.

_loop:
	; Print value of array element.
	LODSD
	MOV		EBX, EAX
	PUSH	[EBP+20]						; Temp array 1 length.
	PUSH	[EBP+16]						; Temp array 2 address.
	PUSH	[EBP+12]						; Temp array 1 address.
	PUSH	EBX
	CALL	WriteVal

	; Add commas for formatting.
	CMP		ECX, 1							; If last element, skip comma.
	JE		_end
	MOV		EAX, 0
	MOV		al, ","
	CALL	WriteChar
	MOV		al, " "
	CALL    WriteChar
	LOOP	_loop

_end:
	CALL CRLF

	; POP saved registers in reverse order and dereference the stack.
	POPAD
	RET		24


printArray ENDP

; ---------------------------------------------------------------------------------
; Name: sumAvgArray
; 
; Description:
;	Sums the values of SDWORDs located within an array.
;	Calculates the truncated average of the SDWORDs located within an array.
;	WriteVal is called to print the sum and average values.
;
; Preconditions: 
;	Temp array 1 and temp array 2 may only contain the value zero/null.
;	Values must be < 32-bit.
;	Sum of values must not exceed 32-bit.
;
; Postconditions: 
;	All general registers modified.
;	
; Receives: 	
;	PUSH    OFFSET truncatedAvg
;	PUSH	OFFSET sumOfNum
;	PUSH	(value) tenNumArrayLength
;	PUSH	(value) tempArrayLength			; For WriteVal subprocedure
;	PUSH	OFFSET tempStringArray2			; For WriteVal subprocedure
;	PUSH	OFFSET tempStringArray1			; For WriteVal subprocedure
;	PUSH	OFFSET tenNumArray				
;	
; Returns: 
;	Prints: "The sum of these numbers is: "
;	Prints: "The truncated average is: "
; ---------------------------------------------------------------------------------
sumAvgArray PROC

	; Preserve EBP, update its new location, and create LOCAL.
	LOCAL	localSum:SDWORD, localAvg:SDWORD
	MOV		localSum, 0
	MOV		localAvg, 0

	; Preserve registers.
	PUSHAD

	; Print: "The sum of the array is:"
	mDisplayString [EBP+28]
	
	; Prep loop.
	CLD
	MOV		ESI, [EBP+8]					; Dec Array address.
	MOV		ECX, [EBP+24]					; Length of 10 array.
	MOV		EBX, 0

_loop1:
	; Sum the values of the array.
	LODSD
	ADD		EBX, EAX						; Add values to EBX.
	MOV		localSum, EBX					
	LOOP	_loop1

	; Print value of sum.
	PUSH	[EBP+20]						; Temp array 1 length.
	PUSH	[EBP+16]						; Temp array 2 address.
	PUSH	[EBP+12]						; Temp array 1 address.
	PUSH	localSum
	CALL	WriteVal
	CALL	CrLF

	; Print: "The avg of the array is:"
	mDisplayString [EBP+32]

	; Calulate truncated average (drop factional portion).
	MOV		EDX, 0
	MOV		EAX, localSum
	CDQ										; Sign-extend EAX for signed division.
	MOV		ECX, [EBP+24]			
	IDIV	ECX
	MOV		localAvg, EAX					; Store average value.

	; Print average value.
	PUSH	[EBP+20]						; Temp array 1 length.
	PUSH	[EBP+16]						; Temp array 2 address.
	PUSH	[EBP+12]						; Temp array 1 address.
	PUSH	localAvg
	CALL	WriteVal
	CALL	CrLF
	CALL	CrLF

_end:
	; POP saved registers in reverse order and dereference the stack.
	POPAD
	RET		28

sumAvgArray ENDP

END main
