
ORG 0x0000 ; Origin for the entire program

sfr lcd_data_pin = 0xA0
sfr input_port = 0x80


sfr comm = 0x4E ; New memory location for comm
sfr disp = 0x52 ; New memory location for disp
sfr disp_address = 0x54 ; New memory location for disp_address


sfr ale    =P1.0
sfr oe     =P1.3
sfr sc     =P1.1
sfr eoc    =P1.2
sfr clk    =P1.7
sfr ADD_A  =P1.4
sfr ADD_B  =P1.5
sfr ADD_C  =P1.6
sfr rs     =P3.4
sfr rw     =P3.5
sfr en     =P3.6
sfr mtr1   =P3.2
sfr mtr2   =P3.3


key       equ 0x30
value     equ 0x32
number1    equ 0x34
ascii1    equ 0x36
ascii2    equ 0x38
ascii3    equ 0x3A
flag      equ 0x3C
temp1     equ 0x3E
key1      equ 0x40
ldr1_value equ 0x42
ldr2_value equ 0x44
ldr3_value equ 0x46

timer_counter equ 0x48 ; New memory location for timer counter
delay_count equ 0x4A
;Timer0 Function
TIMER0:
    INC timer_counter  ; Increment the timer counter
    CPL clk            ; Toggle the clk signal
    RETI

;DELAY Function
DELAY:
    MOV R2, #0      ; Initialize outer loop counter

DELAY_OUTER_LOOP:
    MOV R1, #0      ; Initialize inner loop counter

DELAY_INNER_LOOP:
    NOP             ; No-operation, adjust based on your clock frequency
    NOP
    NOP
    NOP

    INC R1          ; Increment inner loop counter
    CJNE R1, #1275, DELAY_INNER_LOOP ; Continue inner loop until R1 reaches 1275

    INC R2          ; Increment outer loop counter
    CJNE R2, #delay_count, DELAY_OUTER_LOOP ; Continue outer loop until R2 reaches your desired count value

    RET

;lcd_command function
lcd_command:
    MOV A, comm         ; Load the command value into the accumulator
    MOV lcd_data_pin, A ; Store the command value in lcd_data_pin
    MOV en, #1          ; Set en to 1
    MOV rs, #0          ; Clear rs
    MOV rw, #0          ; Clear rw

    MOV delay_count, #1 ; Set delay_count to 1
    CALL delay          ; Call the delay function

    MOV en, #0           ; Clear en to complete the command
    RET


; lcd_data function
lcd_data:
    MOV A, disp         ; Load the data value into the accumulator
    MOV lcd_data_pin, A ; Store the data value in lcd_data_pin
    MOV en, #1          ; Set en to 1
    MOV rs, #1          ; Set rs to 1 (data mode)
    MOV rw, #0          ; Clear rw

    MOV delay_count, #1 ; Set delay_count to 1
    CALL delay          ; Call the delay function
	
    MOV en, #0          ; Clear en to complete the data transfer
    RET

; LCA_DATAA function in assembly
LCA_DATAA:
    MOV DPTR, #disp_address ; Load disp_address into DPTR
    MOVX A, @DPTR ; Load the first character of the string into A
    MOV R0, A ; Copy A to R0

LCA_DATAA_LOOP:
    CJNE A, #0, LCA_DATAA_CONTINUE ; Jump to LCA_DATAA_CONTINUE if A is not equal to 0 (null terminator)
    SJMP LCA_DATAA_EXIT ; Jump to LCA_DATAA_EXIT if A is equal to 0 (null terminator)

LCA_DATAA_CONTINUE:
    CALL lcd_data ; Call lcd_data function with the current character in R0
    INC DPTR ; Move to the next character in the string
    MOVX A, @DPTR ; Load the next character into A
    MOV R0, A ; Copy A to R0
    SJMP LCA_DATAA_LOOP ; Repeat the loop

LCA_DATAA_EXIT:
    RET

; lcd_ini function in assembly
lcd_ini:
    MOV A, #0x39 ; Load the command value 0x39 into the accumulator
    CALL lcd_command ; Call lcd_command function with the current value in A
    MOV A, #5 ; Load the delay count value 5 into the accumulator
    CALL delay ; Call delay function with the current value in A

    MOV A, #0x0F ; Load the command value 0x0F into the accumulator
    CALL lcd_command ; Call lcd_command function with the current value in A
    MOV A, #5 ; Load the delay count value 5 into the accumulator
    CALL delay ; Call delay function with the current value in A

    MOV A, #0x80 ; Load the command value 0x80 into the accumulator
    CALL lcd_command ; Call lcd_command function with the current value in A
    MOV A, #5 ; Load the delay count value 5 into the accumulator
    CALL delay ; Call delay function with the current value in A

    RET

; BCD function in assembly
BCD:
    INC key1 ; Increment key1
    MOV key, #0 ; Clear key
    MOV flag, #0 ; Clear flag

    MOV A, input_port ; Load the value from input_port into A
    MOV number1, A ; Store the value in number1

    MOV A, number1 ; Copy number1 to A
    MOV B, #10 ; Load B with 10
    DIV AB ; Divide AB (A by B), quotient in A, remainder in B

    MOV value, B ; Store the remainder in value

    ADD A, #48 ; Convert the remainder to ASCII
    MOV ascii1, A ; Store the ASCII value in ascii1

    MOV A, number1 ; Copy number1 to A
    MOV B, #10 ; Load B with 10
    DIV AB ; Divide AB (A by B), quotient in A, remainder in B

    MOV value, B ; Store the remainder in value

    JZ NO_DIGIT2 ; Jump to NO_DIGIT2 if B (remainder) is zero
    ADD A, #48 ; Convert the remainder to ASCII
    MOV ascii2, A ; Store the ASCII value in ascii2
    SETB flag ; Set flag to 1
    SJMP SKIP_DIGIT3 ; Skip processing of the third digit

NO_DIGIT2:
    MOV ascii2, #48 ; Set ascii2 to '0'

SKIP_DIGIT3:
    MOV A, number1 ; Copy number1 to A
    MOV B, #10 ; Load B with 10
    DIV AB ; Divide AB (A by B), quotient in A, remainder in B

    MOV value, B ; Store the remainder in value
    JZ NO_DIGIT3 ; Jump to NO_DIGIT3 if B (remainder) is zero

    ADD A, #48 ; Convert the remainder to ASCII
    MOV ascii3, A ; Store the ASCII value in ascii3
    MOV key, #2 ; Set key to 2
    SJMP SKIP_CLEAR ; Skip clearing variables

NO_DIGIT3:
    MOV ascii3, #48 ; Set ascii3 to '0'

SKIP_CLEAR:
    MOV A, key1 ; Copy key1 to A
    CJNE A, #1, CHECK_KEY1_2 ; Compare A (key1) to 1, jump to CHECK_KEY1_2 if not equal
    CALL lcd_command ; Call lcd_command with the command 0xC0
    SJMP SKIP_CLEAR1; Skip clearing variables

CHECK_KEY1_2:
    MOV A, key1 ; Copy key1 to A
    CJNE A, #2, CHECK_KEY1_3 ; Compare A (key1) to 2, jump to CHECK_KEY1_3 if not equal
    CALL lcd_command ; Call lcd_command with the command 0xC5
    SJMP SKIP_CLEAR ; Skip clearing variables

CHECK_KEY1_3:
    MOV A, key1 ; Copy key1 to A
    CJNE A, #3, SKIP_CLEAR ; Compare A (key1) to 3, jump to SKIP_CLEAR if not equal
    CALL lcd_command ; Call lcd_command with the command 0xCA
    MOV key1, #0 ; Clear key1

SKIP_CLEAR1:
    MOV A, key ; Copy key to A
    CJNE A, #2, SKIP_ASCII3 ; Compare A (key) to 2, jump to SKIP_ASCII3 if not equal
    MOV A, ascii3 ; Copy ascii3 to A
    CALL lcd_data ; Call lcd_data with the current value in A

SKIP_ASCII3:
    MOV A, flag ; Copy flag to A
    CJNE A, #1, SKIP_ASCII2 ; Compare A (flag) to 1, jump to SKIP_ASCII2 if not equal
    MOV A, ascii2 ; Copy ascii2 to A
    CALL lcd_data ; Call lcd_data with the current value in A

SKIP_ASCII2:
    MOV A, ascii1 ; Copy ascii1 to A
    CALL lcd_data ; Call lcd_data with the current value in A

    RET ; Return from BCD function


CHECKING:
    MOV A, ldr1_value ; Load ldr1_value into A
    CJNE A, ldr2_value, LDR_NOT_EQUAL ; Compare A to ldr2_value, jump to LDR_NOT_EQUAL if not equal

    ; LDR1 and LDR2 are equal, stop motors
    MOV mtr1, #0 ; Stop motor 1
    MOV mtr2, #0 ; Stop motor 2
    SJMP CHECKING_END ; Jump to CHECKING_END

LDR_NOT_EQUAL:
    MOV A, ldr1_value ; Load ldr1_value into A
    SUBB A, ldr2_value ; Subtract ldr2_value from A, result in A, set carry flag (CY) if borrow

    JC LDR1_GREATER ; Jump to LDR1_GREATER if A (ldr1_value - ldr2_value) is less than 0

    ; LDR1 is greater than or equal to LDR2, move clockwise
    MOV mtr1, #1 ; Clockwise rotation for motor 1
    MOV mtr2, #0 ; Stop motor 2
    SJMP CHECKING_END ; Jump to CHECKING_END

LDR1_GREATER:
    ; LDR2 is greater than LDR1, move anticlockwise
    MOV mtr1, #0 ; Stop motor 1
    MOV mtr2, #1 ; Anticlockwise rotation for motor 2
	SJMP CHECKING_END ; Jump to CHECKING_END

CHECKING_END:
    RET ; Return from checking function


MAIN_LOOP_ADC:
    MOV A, temp1 ; Load temp1 into A

    CJNE A, #0, TEMP1_NOT_ZERO ; Check if temp1 is not equal to 0

    ; temp1 is 0
    MOV ADD_C, #0
    MOV ADD_B, #0
    MOV ADD_A, #0
    JMP DELAY_ALE_HIGH ; Jump to DELAY_ALE_HIGH

TEMP1_NOT_ZERO:
    CJNE A, #1, TEMP1_NOT_ONE ; Check if temp1 is not equal to 1

    ; temp1 is 1
    MOV ADD_C, #0
    MOV ADD_B, #0
    MOV ADD_A, #1
    JMP DELAY_ALE_HIGH ; Jump to DELAY_ALE_HIGH

TEMP1_NOT_ONE:
    ; temp1 is 2
    MOV ADD_C, #0
    MOV ADD_B, #1
    MOV ADD_A, #0

DELAY_ALE_HIGH:
	MOV delay_count, #2
    CALL DELAY ; Call the delay function
    MOV ale, #1 ; Set ale to 1
	MOV delay_count,#2
    CALL DELAY ; Call the delay function
    MOV sc, #1 ; Set sc to 1
	MOV delay_count,#1
	CALL DELAY ; Call the delay function
    MOV ale, #0 ; Set ale to 0
	MOV delay_count,#1
	CALL DELAY ; Call the delay function
    MOV sc, #0 ; Set sc to 0

WAIT_EOC_HIGH:
    JNB eoc, WAIT_EOC_HIGH ; Wait until eoc is high

WAIT_EOC_LOW:
    JB eoc, WAIT_EOC_LOW ; Wait until eoc is low

    MOV oe, #1 ; Set oe to 1

    CJNE temp1, #0, TEMP1_NOT_ZERO_ADC ; Check if temp1 is not equal to 0

    ; temp1 is 0
    MOV ldr1_value, input_port ; Store LDR 1 value
    JMP BCD_AND_DELAY ; Jump to BCD_AND_DELAY

TEMP1_NOT_ZERO_ADC:
    CJNE temp1, #1, TEMP1_NOT_ONE_ADC ; Check if temp1 is not equal to 1

    ; temp1 is 1
    MOV ldr2_value, input_port ; Store LDR 2 value
    JMP BCD_AND_DELAY ; Jump to BCD_AND_DELAY

TEMP1_NOT_ONE_ADC:
    ; temp1 is 2
    MOV ldr3_value, input_port ; Store LDR 3 value

BCD_AND_DELAY:
    CALL BCD ; Call the BCD function
    MOV delay_count, #2 ; Set delay_count to 2
    CALL DELAY ; Call the delay function
    MOV oe, #0 ; Set oe to 0
    INC temp1 ; Increment temp1
    CJNE temp1, #3, TEMP1_NOT_THREE_ADC ; Check if temp1 is not equal to 3

    ; temp1 is 3, reset temp1 to 0
    MOV temp1, #0

TEMP1_NOT_THREE_ADC:
    CALL CHECKING ; Call the checking function
    JMP MAIN_LOOP_ADC ; Jump back to the MAIN_LOOP_ADC label, creating an infinite loop

MAIN:
    MOV eoc, #1 ; Set eoc to 1
    MOV ale, #0 ; Set ale to 0
    MOV oe, #0 ; Set oe to 0
    MOV sc, #0 ; Set sc to 0

    MOV TMOD, #0x02 ; Set TMOD to 0x02
    MOV TH0, #0xFD ; Set TH0 to 0xFD

    MOV IE, #0x82 ; Set IE to 0x82
    MOV TR0, #1 ; Set TR0 to 1

    MOV temp1, #0 ; Set temp1 to 0
    MOV key1, #0 ; Set key1 to 0

    CALL lcd_ini ; Call lcd_ini function

    MOV DPTR, #SN1_STR ; Load address of SN1 string
    CALL LCA_DATAA ; Call lcd_dataa function with SN1 string

    MOV DPTR, #SN2_STR ; Load address of SN2 string
    CALL LCA_DATAA ; Call lcd_dataa function with SN2 string

    MOV DPTR, #SN3_STR ; Load address of SN3 string
    CALL LCA_DATAA ; Call lcd_dataa function with SN3 string

    CALL MAIN_LOOP_ADC ; Call adc function

    JMP MAIN ; Jump to MAIN, creating an infinite loop

SN1_STR: DB "SN1:", 0 ; SN1 string
SN2_STR: DB "SN2:", 0 ; SN2 string
SN3_STR: DB "SN3:", 0 ; SN3 string

END MAIN ; End of the program
