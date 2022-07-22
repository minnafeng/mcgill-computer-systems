# This question is an exercise of working with and manipulating strings in MIPS 
# The input string is hardcoded. The program should print the input string, 
# convert all uppercase letters to lowercase and all lowercase letters to uppercase,
# then print the output string

	.data

inputstring: 	.asciiz "I am a student at McGill University"
outputstring:	.space 100
blank: 		.asciiz "\n" 


	.text
	.globl main

main:
	# print the original string
	li  $v0, 4
	la  $a0, inputstring
	syscall

	# set pointers $t0, $t1 to first elements of both strings
	la $t0, inputstring
	la $t1, outputstring

loop:
	lb $t2, 0($t0) # load char from string
	beqz $t2, exit # exit if null char

	# if lowercase, convert to upper
	blt $t2, 'a', uppercase
	bgt $t2, 'z', uppercase
	sub $t2, $t2, 32 # lower and upper case letters in ascii table are 32 integers apart
	sb $t2, 0($t1) # store byte into outputstring

	# increment pointers
	addi $t0, $t0, 1
	addi $t1, $t1, 1

	j loop

uppercase:
	# if uppercase, convert to lower
	blt $t2, 'A', space
	bgt $t2, 'Z', space
	addi $t2, $t2, 32
	sb $t2, 0($t1) # store byte into outputstring

	# increment pointers
	addi $t0, $t0, 1
	addi $t1, $t1, 1

	j loop

space:
	# if space, store and skip
	sb $t2, 0($t1) # store byte into outputstring

	# increment pointers
	addi $t0, $t0, 1
	addi $t1, $t1, 1

	j loop

exit:
	# print blank line
	li  $v0, 4
	la  $a0, blank
	syscall

	# print the manipulated string
	li  $v0, 4
	la  $a0, outputstring
	syscall

	# terminate program
	li $v0, 10
        syscall
