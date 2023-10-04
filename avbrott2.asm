.eqv EXT_INTTIME 0x0400 #mask for timer interrupt (external), bit 10
.eqv EXT_INTBUTTON 0x0800 #mask for button interrupt (external), bit 11
.eqv CLEAR 0xFFFFF3FF #mask for clearing time and button interrupts, bits 10-11
.eqv EXCHMASK 0x007C #mask for exceptions (internal), bits 2-6
.eqv ENABLE_TIMER_ADR 0xFFFF0012 #I/O enabling timer
.eqv BUTTONADDR 0xFFFF0013 #I/O button address
.eqv WALK_BUTTON 0x01 #mask for pedestrian button
.eqv DRIV_BUTTON 0x02 #mask for car button
.eqv ENABLE_TIMER 0x01 #mask for enabling timer

.data
timer: .word 0
str: .asciiz " "
strC: .asciiz " Car\n"
strP: .asciiz " Pedestrian\n"
ten: .word 100
#activates and specifies method used for interrupt. In Mips interrupts are stored at the adress 0x80000180
.ktext 0x80000180
la $k0, int_routine
jr $k0
nop
.text
.globl main
main:
	mfc0 $t0, $12 #prepare status register for timer and button interrupt
	ori $t0, $t0, EXT_INTTIME

	ori $t0, $t0, EXT_INTBUTTON
	ori $t0, $t0, 1
	mtc0 $t0, $12
	li $t0, ENABLE_TIMER #enable the timer (t0 > 0)
	sb $t0, ENABLE_TIMER_ADR
	
	
	la $t0, 0xFFFF0011 #Set green light for cars by default
	add $t1, $zero, 0x04
	sb $t1, 0x0($t0)
loop: #infinite loop, waiting for interrupts

	nop
	b loop
	li $v0, 10 #exit
	syscall
.globl int_routine
int_routine:
	subu $sp, $sp, 16
	sw $at, 8($sp) #save registers used (not k0, k1)
	sw $a0, 4($sp)
	sw $v0, 0($sp)
	
	mfc0 $k1, $13 #extract EXCCODE field from Cause register
	andi $k0, $k1, EXCHMASK #extract EXCCODE (bits 2-6)
	bne $k0, $zero, restore #check EXCCODE (if nonzero leave). if k0 is 0 it means it's an user defined interrupt
	andi $k0, $k1, EXT_INTTIME #extract bit 10 (timer) from Cause register
	
	

	lw $a0, timer #if timer interrupt update and print timer
	
	addi $a0, $a0, 1 #increases timer counter by 1
	
	
	sw $a0, timer #prints out timer
	li $v0, 1
	syscall
	
	la $a0, str #prints out space
	li $v0, 4
	syscall
	
	lw $a2, ten
	blt $a0, $a2, ifend
	beq $k0, $zero, button #if no timer interrupt check button
timeInt1:
 
button:
	andi $k0, $k1, EXT_INTBUTTON #extract bit 11 (button) from Cause register
	beq $k0, $zero, restore #if no button interrupt leave
	lb $k0, BUTTONADDR #if button interrupt print text and set timer = 0
	andi $a0, $k0, WALK_BUTTON #check if pedestrian
	
	
	beq $a0, $zero, car 
#---------pedestiran button handler------------------- 
	la $a0, strP
	
	la $t0, 0xFFFF0011 #Set red light for cars by default
	add $t1, $zero, 0x01
	sb $t1, 0x0($t0)

	la $t0, 0xFFFF0010 #Set green light for pedestrians
	add $t1, $zero, 0x02
	sb $t1, 0x0($t0)
	
	b ifend
car:
#---------car button handler------------------- 
	andi $a0, $k0, DRIV_BUTTON #check if car

	
	beq $a0, $zero, restore
	la $a0, strC
	
ifend:
	li $v0, 4 #prints out either pedestiran or car
	syscall
	sw $zero, timer #set timer = 0
	
restore: #restore registers before leaving
	lw $at, 8($sp)
	lw $a0, 4($sp)
	lw $v0, 0($sp)
	addiu $sp, $sp, 16
	andi $k1, $k1, CLEAR #clear bits 10 (timer) and 11 (button) from Cause register, set to zero
	mtc0 $k1, $13 #clear Cause
	eret #return using EPC
