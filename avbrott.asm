.data



.text

la      $t0, 0xFFFF0010  	#Set red light om main road
add   $t2,$zero, 0x02
sb      $t2, 0x0($t0)

la      $t0, 0xFFFF0011   	#Set red light om main road
add   $t1,$zero, 0x04
sb      $t1, 0x0($t0)

	li $v0, 10
	syscall