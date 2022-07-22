# This question is an exercise of working loops and user inputs
# Prompt user for an integer input and print whether it is a power of 2 or not. 

	.data
prompt:		.asciiz "\nEnter an Integer:\t"
powerOf2:	.asciiz "The integer you entered is a power of 2."
notPowerOf2: 	.asciiz "The integer you entered is not a power of 2."

	.text
	.globl main

main: 
	# prompt user for input
	li $v0, 4		
	la $a0, prompt
	syscall	
		
	# read integer 
	li $v0,5		
	syscall
	

	# check if input == 0
	beq $v0, $0, no		

	add $t0, $zero, $v0 # copy $v0 input to $t0
	sub $t1, $t0, 1	# store input-1 into $t1
	
	# all powers of 2 are of the binary form 100....0
	# so, subtracting 1 from that number will result into another binary digit of the form 011...1 
	# the two will have no bits in common so "and" will return 0 for a power of 2
	and $t2, $t0, $t1
	bne $t2, $0, no
	
	# print msg for power of 2
	li  $v0, 4		
	la  $a0, powerOf2
	syscall
	j exit
	
no: 	
	# print msg for not power of 2
	li  $v0, 4		
	la  $a0, notPowerOf2
	syscall
	j exit 

exit: 
	# terminate program
	li $v0, 10		
       	syscall
	
