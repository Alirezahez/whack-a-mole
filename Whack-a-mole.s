;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Whack a hole game
;;Auther: Chengyu Lou
;;Date : 2019-12-06 11:03
;;
;;
;;
;;
;;
; GPIO Test program - Dave Duguid, 2011 
; Modified Trevor Douglas 2014 
 
;;; Directives 
            PRESERVE8 
            THUMB        
 
        		  
;;; Equates 
 
INITIAL_MSP	EQU		0x20001000	; Initial Main Stack Pointer Value 
 
 
;PORT A GPIO - Base Addr: 0x40010800 
GPIOA_CRL	EQU		0x40010800	; (0x00) Port Configuration Register for Px7 -> Px0 
GPIOA_CRH	EQU		0x40010804	; (0x04) Port Configuration Register for Px15 -> Px8 
GPIOA_IDR	EQU		0x40010808	; (0x08) Port Input Data Register 
GPIOA_ODR	EQU		0x4001080C	; (0x0C) Port Output Data Register 
GPIOA_BSRR	EQU		0x40010810	; (0x10) Port Bit Set/Reset Register 
GPIOA_BRR	EQU		0x40010814	; (0x14) Port Bit Reset Register 
GPIOA_LCKR	EQU		0x40010818	; (0x18) Port Configuration Lock Register 
 
;PORT B GPIO - Base Addr: 0x40010C00 
GPIOB_CRL	EQU		0x40010C00	; (0x00) Port Configuration Register for Px7 -> Px0 
GPIOB_CRH	EQU		0x40010C04	; (0x04) Port Configuration Register for Px15 -> Px8 
GPIOB_IDR	EQU		0x40010C08	; (0x08) Port Input Data Register 
GPIOB_ODR	EQU		0x40010C0C	; (0x0C) Port Output Data Register 
GPIOB_BSRR	EQU		0x40010C10	; (0x10) Port Bit Set/Reset Register 
GPIOB_BRR	EQU		0x40010C14	; (0x14) Port Bit Reset Register 
GPIOB_LCKR	EQU		0x40010C18	; (0x18) Port Configuration Lock Register 
 
;The onboard LEDS are on port C bits 8 and 9 
;PORT C GPIO - Base Addr: 0x40011000 
GPIOC_CRL	EQU		0x40011000	; (0x00) Port Configuration Register for Px7 -> Px0 
GPIOC_CRH	EQU		0x40011004	; (0x04) Port Configuration Register for Px15 -> Px8 
GPIOC_IDR	EQU		0x40011008	; (0x08) Port Input Data Register 
GPIOC_ODR	EQU		0x4001100C	; (0x0C) Port Output Data Register 
GPIOC_BSRR	EQU		0x40011010	; (0x10) Port Bit Set/Reset Register 
GPIOC_BRR	EQU		0x40011014	; (0x14) Port Bit Reset Register 
GPIOC_LCKR	EQU		0x40011018	; (0x18) Port Configuration Lock Register 
 
;Registers for configuring and enabling the clocks 
;RCC Registers - Base Addr: 0x40021000 
RCC_CR		EQU		0x40021000	; Clock Control Register 
RCC_CFGR	EQU		0x40021004	; Clock Configuration Register 
RCC_CIR		EQU		0x40021008	; Clock Interrupt Register 
RCC_APB2RSTR	EQU	0x4002100C	; APB2 Peripheral Reset Register 
RCC_APB1RSTR	EQU	0x40021010	; APB1 Peripheral Reset Register 
RCC_AHBENR	EQU		0x40021014	; AHB Peripheral Clock Enable Register 
 
RCC_APB2ENR	EQU		0x40021018	; APB2 Peripheral Clock Enable Register  -- Used 
 
RCC_APB1ENR	EQU		0x4002101C	; APB1 Peripheral Clock Enable Register 
RCC_BDCR	EQU		0x40021020	; Backup Domain Control Register 
RCC_CSR		EQU		0x40021024	; Control/Status Register 
RCC_CFGR2	EQU		0x4002102C	; Clock Configuration Register 2 
 
; Times for delay routines 
         
DELAYTIME	EQU		1600000		; (200 ms/24MHz PLL) 
DELAYONEHZ EQU 1000000 ; 1hz
PrelimWait EQU 1600000
Rand   EQU 0xAB98D379
ReactTime EQU 360000
WinningSignalTime EQU 360000
LosingSignalTime EQU 360000
; Vector Table Mapped to Address 0 at Reset 
            AREA    RESET, Data, READONLY 
            EXPORT  __Vectors 
 
__Vectors	DCD		INITIAL_MSP			; stack pointer value when stack is empty 
        	DCD		Reset_Handler		; reset vector 
			 
            AREA    MYCODE, CODE, READONLY 
			EXPORT	Reset_Handler 
			ENTRY 
 
Reset_Handler		PROC 
 
		BL GPIO_ClockInit 
		BL GPIO_init 
	 
mainLoop 
		 
		BL all_dark

		BL delay
		add r11, r11, #1
	
 		BL Wait_for_player
		
		BL check_start
		cmp r0, #1
		BEQ Normal_game_play
		
		BL delay
		cmp r11, #4
		MOVGE r11, #0
		B	mainLoop
		ENDP 
 
 
 
 
;;;;;;;;Subroutines ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC3 NOrmal_game_play
;;Require: pre-stored values in memory
;;Promise: load Random value and reacttime to registers
;;
;;
;;modifies:
;;r9
;;r10
;;
;;
;;
Normal_game_play PROC
	
	BL PrelimWait_time

	ldr r9,=Rand ; load random number to r9
	ldr r10,=ReactTime; load reacttime to r10
	B Start_Game
	BX LR
	ENDP
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC3 start game
;;Require: run normal game play function before this function
;;Promise: main game loop, get random LEDs to light up.
;;
;;
;;modifies:
;;r1
;;r10
;;r9
;;
;;Notes:
;;we use last 2 bits of r9 to decide which led to light up. 
;;r9 will shift right every loop to make last 2 bits psudo random
Start_Game PROC
	sub r10, r10, r5 ;reduce reacttime each loop
	and r1, r9, #0x0003 ; extract last two bits
	BL all_dark
	BL PrelimWait_time	;wait before enter next round, otherwise next round will read last button press. (human slower than computer
	cmp r1, #0  ;light up different LED
	BLEQ LED1
	cmp r1, #1
	BLEQ LED2
	cmp r1, #2
	BLEQ LED3
	cmp r1, #3
	BLEQ LED4
	mov r9, r9, LSR #1 ;shift right to get Random number
	B ReactTime_wait	; enter reacttime stage
	
	;B Start_Game
	
	BX LR
	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC3 ReactTime_wait
;;Require: run Start_Game function before this function
;;Promise: get user input(button press) within some time frame reacttime
;;
;;
;;modifies:
;;r0
;;r10
;;
;;
;;Notes:
;;we first set r0 to 5, so later the computer can know we click the wrong button
;;Then, get each button input, store button value to r0
;;if we clicked wrong button, the r0 will be smaller than 5, so we can enter end stage.
;;if the button clicked has same number with r1, which is our LED number. We got the right button 
;;and enter finish_round, other react time will be set to 0 and end the game
ReactTime_wait PROC
		
		MOV r0, #5
		;sw4 PC 12
		PUSH {r1, r6}
		ldr r6,=GPIOC_IDR
		ldr r1, [r6]
		and r1, #0x1000
		cmp r1, #00
		MOVEQ r0, #2
		
		ldr r6,=GPIOA_IDR
		ldr r1, [r6]
		and r1, #0x0020
		cmp r1, #0
		MOVEQ r0, #3
		
		ldr r6,=GPIOB_IDR
		ldr r1, [r6]
		and r1, #0x0200
		cmp r1, #0
		MOVEQ r0, #1
		
		ldr r6,=GPIOB_IDR
		ldr r1, [r6]
		and r1, #0x0100
		cmp r1, #0
		MOVEQ r0, #0
		
		POP {r1, r6}
		cmp r1, r0
		BEQ finish_round
		;BL PrelimWait_time
		cmp r0, #4
		MOVLE r10, #1
		subs r10, #1
		cmp r10, #0
		bne ReactTime_wait
		B End_Failure
		BX LR
		ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC3 finish_round
;;Require: run Start_Game function before this function
;;Promise: calculate reduce time for reacttime, will update later
;;count number of successful round, if its equal to 16. finish game with success
;;
;;modifies:
;;r4
;;r10
;;r5
;;
;;Notes:
;;reset reactime to original value for next round(will subtract with r5 to reduce time later)
;;count number of successful runs in r4
;;finally start game again
finish_round PROC
		ldr r10,=ReactTime
		add r4, r4, #1
		cmp r4, #16
		BEQ End_Success
		add r5, r5, #12
		B Start_Game
		BX LR
		ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC5 End_Failur
;;Require:failed the game
;;Promise: display information about failed game. then play again
;;
;;modifies:
;;r10
;;
;;Notes:
;;light up leds to surrender. wait losing_wait time then back to game
End_Failure PROC
	ldr r10,=ReactTime
	BL LED3
	BL LED4
	BL losing_Wait
	B Wait_for_player
	BX LR
	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC4 End_Success
;;Require:won the game
;;Promise: display information about won game. then play again
;;
;;modifies:
;;
;;Notes:
;;light up leds to surrender. wait winning_wait time then back to game
End_Success	PROC
	BL LED1
	BL LED2
	BL Winning_Wait
	B Wait_for_player
	BX LR
	ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC5 losing_Wait
;;Require: won the game
;;Promise: wait
;;
;;modifies:
;;
;;Notes:

losing_Wait PROC
			push{r10}
			ldr r10,=LosingSignalTime 
			b waitl
			pop{r10}
			BX LR
			ENDP
waitl
			subs r10, #1
			bne waitl
			pop{r10}
			BX LR	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC4 Winning_Wait
;;Require: won the game
;;Promise: wait
;;
;;modifies:
;;
;;Notes:
			
Winning_Wait PROC
			push{r10}
			ldr r10,=WinningSignalTime
			b waitw
			pop{r10}
			BX LR
			ENDP
waitw
			subs r10, #1
			bne waitw
			pop{r10}
			BX LR	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC2 check_button
;;Require: see the light going back and forth
;;Promise: enter game when button is pressed. wait one second
;;
;;modifies:
;;r0
;;Notes:
;; read GPIO and store to r0					
check_button	 PROC
	;sw4 PC 12
		PUSH {r1, r6}
		ldr r6,=GPIOC_IDR
		ldr r1, [r6]
		and r1, #0x1000
		cmp r1, #00
		MOVEQ r0, #2
		
		ldr r6,=GPIOA_IDR
		ldr r1, [r6]
		and r1, #0x0020
		cmp r1, #0
		MOVEQ r0, #3
		
		ldr r6,=GPIOB_IDR
		ldr r1, [r6]
		and r1, #0x0200
		cmp r1, #0
		MOVEQ r0, #1
		
		ldr r6,=GPIOB_IDR
		ldr r1, [r6]
		and r1, #0x0100
		cmp r1, #0
		MOVEQ r0, #0
		
		POP {r1, r6}
		BX LR
		ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC4 PrelimWait_time
;;Require: wait
;;Promise: wait
;;
;;modifies:
;;
;;Notes:
PrelimWait_time PROC
			push{r10}
			ldr r10,=PrelimWait
			b wait1
			pop{r10}
			BX LR
			ENDP
wait1
			subs r10, #1
			bne wait1
			pop{r10}
			BX LR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC4 Wait_for_player
;;Require: wait
;;Promise: wait
;;
;;modifies:
;;
;;Notes:
Wait_for_player PROC
	;1hz = 1 cycle/second
	PUSH {r11 ,lr}

	cmp r11, #1
	BEQ LED4
	cmp r11, #2
	BEQ LED3
	cmp r11, #3
	BEQ LED2
	cmp r11, #4
	BEQ LED1
	
	POP {r11, pc}
	
	BX LR 
	ENDP 
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC2 check_start
;;Require: see the light going back and forth
;;Promise: enter game when button is pressed. wait one second
;;
;;modifies:
;;r0
;;Notes:
;; read GPIO and store to r0	
check_start	 PROC
	;sw4 PC 12
		PUSH {r1, r6}
		ldr r6,=GPIOC_IDR
		ldr r1, [r6]
		and r1, #0x1000
		cmp r1, #00
		MOVEQ r0, #1
		
		ldr r6,=GPIOA_IDR
		ldr r1, [r6]
		and r1, #0x0020
		cmp r1, #0
		MOVEQ r0, #1
		
		ldr r6,=GPIOB_IDR
		ldr r1, [r6]
		and r1, #0x0200
		cmp r1, #0
		MOVEQ r0, #1
		
		ldr r6,=GPIOB_IDR
		ldr r1, [r6]
		and r1, #0x0100
		cmp r1, #0
		MOVEQ r0, #1
		
		POP {r1, r6}
		BX LR
		ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC LED1
;;Require: wait
;;Promise: light up LED1
;;
;;modifies:
;;
;;Notes:
			
LED1 PROC
	;led 1 pa 9
		PUSH {r0, r1, r4}
		ldr r0,=GPIOA_ODR
		ldr r1,[r0]
		mov r4,#0xfdff ; set PA 9 to 0, light up led
		and r1,r1,r4
		str r1,[r0]
		POP {r0, r1, r4}
		BX LR
		ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC LED2
;;Require: wait
;;Promise: light up LED2
;;
;;modifies:
;;
;;Notes:

LED2  PROC
	; led 2 pa 10
		PUSH {r0, r1, r4}
		ldr r0,=GPIOA_ODR
		ldr r1,[r0]
		mov r4,#0xfbff ; set PA 10 to 0, light up led
		and r1,r1,r4
		str r1,[r0]
		POP {r0, r1, r4}
		BX LR
		ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC LED3
;;Require: wait
;;Promise: light up LED3
;;
;;modifies:
;;
;;Notes:

LED3  PROC
	;led 3 pa 11
		;PUSH {lr}
		PUSH {r0, r1, r4}
		ldr r0,=GPIOA_ODR
		ldr r1,[r0]
		mov r4,#0xf7ff ; set PA 11 to 0, light up led f7ff
		and r1,r1,r4
		str r1,[r0]
		POP {r0, r1, r4}
		BX LR
		ENDP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC LED4
;;Require: wait
;;Promise: light up LED4
;;
;;modifies:
;;
;;Notes:

LED4  PROC
	;led 4 pa 12
		PUSH {r0, r1, r4}
		ldr r0,=GPIOA_ODR
		ldr r1,[r0]
		mov r4,#0xefff ; set PA 12 to 0, light up led
		and r1,r1,r4
		str r1,[r0]
		POP {r0, r1, r4}
		BX LR
		ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC4 Wait_for_player
;;Require: wait
;;Promise: wait
;;
;;modifies:
;;
;;Notes:
delay PROC
			push{r10}
			ldr r10,=DELAYONEHZ
			b wait
			pop{r10}
			BX LR
			ENDP
wait
			subs r10, #1
			bne wait
			BX LR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; UC all_dark
;;Require: wait
;;Promise: set all leds to dark
;;
;;modifies:
;;
;;Notes:
all_dark PROC
	PUSH {r0, r1}
	ldr r0,=GPIOA_ODR
	ldr r1,[r0]
	orr r1,r1,#0x00001e00
	str r1,[r0]
	POP {r0, r1}
	BX LR
	ENDP

;This routine will enable the clock for the Ports that you need	 
	ALIGN 
GPIO_ClockInit PROC 
 
	; Students to write.  Registers   .. RCC_APB2ENR 
	; ENEL 384 Pushbuttons: SW2(Red): PB8, SW3(Black): PB9, SW4(Blue): PC12 *****NEW for 2015**** SW5(Green): PA5 
	; ENEL 384 board LEDs: D1 - PA9, D2 - PA10, D3 - PA11, D4 - PA12 
	PUSH {r0, r1, r4}
	ldr r0,=RCC_APB2ENR
	ldr r1,[r0]					
	ldr r4,=0x04
	orr r1,r1,r4
	ldr r4,=0x08
	orr r1,r1,r4
	ldr r4,=0x10
	orr r1,r1,r4
	str r1,[r0]
	POP {r0, r1, r4}
	BX LR 
	ENDP 
		 
	 
	 
;This routine enables the GPIO for the LED's.  By default the I/O lines are input so we only need to configure for ouptut. 
	ALIGN 
GPIO_init  PROC 
	PUSH {r0, r1}
	; ENEL 384 board LEDs: D1 - PA9, D2 - PA10, D3 - PA11, D4 - PA12 
 	LDR R0, =GPIOA_CRH
	ldr r1,=0x44433334
	str r1,[r0]
	POP {r0, r1}
    BX LR 
	ENDP 
		 
 
 
 
 
	ALIGN 
	END 
}