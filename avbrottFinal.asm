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
ten: .word 10 
seven: .word 7
three: .word 3

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
	
	la $t0, 0xFFFF0010 #Set red light for pedestrians by default
	add $t1, $zero, 0x01
	sb $t1, 0x0($t0)
	
#infinite loop, waiting for interrupts
loop: 
	nop
	b loop

	li $v0, 10 #exit
	syscall
	
.globl int_routine
int_routine:
	subu $sp, $sp, 16
	sw $at, 8($sp) #save registers used (not k0, k1)
	sw $a1, 4($sp)
	sw $v0, 0($sp)
	
	mfc0 $k1, $13 #extract EXCCODE field from Cause register
	andi $k0, $k1, EXCHMASK #extract EXCCODE (bits 2-6)
	bne $k0, $zero, restore #check EXCCODE (if nonzero leave). if k0 is 0 it means it's an user defined interrupt
	
	andi $k0, $k1, EXT_INTBUTTON
       
	lw $a1, timer #load timer variable
	addi $a1, $a1, 1 #increases timer counter by 1
	sw $a1, timer #store new value to timer
	
	#print timer value
	move $a0, $a1
	li $v0, 1
	syscall
	
	#print space
	la $a0, str
	li $v0, 4
	syscall
	
	lw $t0, ten
	blt $a1, $t0, restore #if timer less than 10, skip to restore

button:
	andi $k0, $k1, EXT_INTBUTTON #extract bit 11 (button) from Cause register
	beq $k0, $zero, restore #if no button interrupt leave
	
	lb $k0, BUTTONADDR #load button address
	andi $a1, $k0, WALK_BUTTON #check if pedestrian
	
	beq $a1, $zero, car
	
#---------pedestiran button handler------------------- 
	#prints out pedestrian
	la $a0, strP
	li $v0, 4 
	syscall
	
	#reset timer
	sw $zero, timer 
	
	b s1
	
car:
#---------car button handler------------------- 
	andi $a1, $k0, DRIV_BUTTON #check if car
	
	#prints car
	la $a0, strC
	li $v0, 4 
	syscall
	
	#resets timer
	sw $zero, timer
	b restore

#s1: blinks yellow light for 3 time units for cars
s1:
	lw $a1, timer #load timer value
	lw $t2, three
	bgt $a1, $t2, TR1
	addi $a1, $a1, 1 #increases timer counter by 1
	sw $a1, timer #stores timer value
	
	la $t0, 0xFFFF0011 #Set yellow light for cars
	add $t1, $zero, 0x02
	sb $t1, 0x0($t0)
	
	b s1
#TR1: does time reset and and sets red light for cars
TR1:
	la $t0, 0xFFFF0011
	add $t1, $zero, 0x01
	sb $t1, 0x0($t0)
	
	sw $zero, timer
	b s2
	
#s2: sets green light for pedestrians for 7 time units
s2:
	
	lw $a1, timer #load timer
	lw $t2, seven
	bgt $a1, $t2, TR2
	addi $a1, $a1, 1 #increases timer counter by 1
	sw $a1, timer #stores timer
	
	la $t0, 0xFFFF0010 #Set green light for pedestrians
	add $t1, $zero, 0x02
	sb $t1, 0x0($t0)
	
	b s2

#TR2: does time reset
TR2:
	sw $zero, timer
	b s3

#s3: blinks red light for pedestrians for 3 time units
s3:
	
	lw $a1, timer #load timer
	lw $t2, three
	bgt $a1, $t2, TR3
	addi $a1, $a1, 1 #increases timer counter by 1
	sw $a1, timer #stores timer
	
	la $t0, 0xFFFF0010 #Set red light for pedestrians
	add $t1, $zero, 0x01
	sb $t1, 0x0($t0)
	la $t0, 0xFFFF0010 #Set dark light for pedestrians
	add $t1, $zero, 0x00
	sb $t1, 0x0($t0)

	b s3
#TR3: does time reset and sets red light for pedestrians
TR3:
	la $t0, 0xFFFF0010 #Set red light
	add $t1, $zero, 0x01
	sb $t1, 0x0($t0)
	
	sw $zero, timer
	b s5

#s5: sets yellow ligt for cars for 3 time units
s5:
	lw $a1, timer #load timer
	lw $t2, three
	bgt $a1, $t2, TR5
	addi $a1, $a1, 1 #increases timer counter by 1
	sw $a1, timer #stores timer
	
	la $t0, 0xFFFF0011 #Set yellow light for cars
	add $t1, $zero, 0x02
	sb $t1, 0x0($t0)
	b s5
TR5:
	la $t0, 0xFFFF0011 #Set green light for cars
	add $t1, $zero, 0x04
	sb $t1, 0x0($t0)
	
	sw $zero, timer
	b restore

restore: #restore registers before leaving
	lw $at, 8($sp)
	lw $a1, 4($sp)
	lw $v0, 0($sp)
	addiu $sp, $sp, 16
	andi $k1, $k1, CLEAR #clear bits 10 (timer) and 11 (button) from Cause register, set to zero
	mtc0 $k1, $13 #clear Cause
	eret #return using EPC
