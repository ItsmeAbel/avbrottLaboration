.eqv EXT_INTBUTTON 0x0800 #mask for button interrupt (external), bit 11
.eqv CLEAR_BUTTON 0xFFFFF7FF #mask for clearing button interrupt, bit 11
.eqv EXCHMASK 0x007C #mask for exceptions (internal), bits 2-6
.eqv BUTTONADDR 0xFFFF0013 #I/O button address

.data
walk: .asciiz "walk button pressed"
car: .asciiz "car button presses"
ms_delay: .word 10 #1000ms which equals 1s


.ktext 0x80000180
la $k0, int_routine
jr $k0
nop

.text
.globl main
main:

mfc0 $t0, $12 #prepare status register for button interrupt
ori $t0, $t0, EXT_INTBUTTON
ori $t0, $t0, 1
mtc0 $t0, $12

lw $s3, ms_delay
loop:




la      $t0, 0xFFFF0011   	#trafic light for cars is green by default
add   $t1,$zero, 0x04
sb      $t1, 0x0($t0)


b loop
	
	li $v0, 10
	syscall
	
.globl int_routine
int_routine:
	subu $sp, $sp, 16
	sw $at, 8($sp) #save registers used (not k0, k1)
	sw $a0, 4($sp)
	sw $v0, 0($sp)
	
	addi $t0, $zero, 1
	lb $s1, BUTTONADDR
	bne $s1, $t0, button1
		la      $t0, 0xFFFF0010  	#trafic light for crossing humans
		add   $t2,$zero, 0x02
		sb      $t2, 0x0($t0)

		la      $t0, 0xFFFF0011   	#trafic light for cars
		add   $t1,$zero, 0x01
		sb      $t1, 0x0($t0)
	
		la $a0, walk #if button interrupt print text and button number
		li $v0, 4
		syscall
		lb $a0, BUTTONADDR
		li $v0, 1
		syscall
		
		
button1:

	addi $t1, $zero, 2
	lb $s2, BUTTONADDR
	bne $s2, $t1, button2
		la $a0, car #if button interrupt print text and button number
		li $v0, 4
		syscall
		lb $a0, BUTTONADDR
		li $v0, 1
		syscall
button2:

	mfc0 $k1, $13 #extract EXCCODE field from Cause register
	andi $k0, $k1, EXCHMASK #extract EXCCODE (bits 2-6)
	bne $k0, $zero, restore #check EXCCODE (if nonzero leave)
	andi $k0, $k1, EXT_INTBUTTON #extract bit 11 (button) from Cause register
	beq $k0, $zero, restore #if no button interrupt leave


restore: #restore registers before leaving
	lw $at, 8($sp)
	lw $a0, 4($sp)
	lw $v0, 0($sp)	
	addiu $sp, $sp, 16
	andi $k1, $k1, CLEAR_BUTTON #clear bit 11 (button) in Cause reg., set to 0
	mtc0 $k1, $13 #clear Cause
	eret 




