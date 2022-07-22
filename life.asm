# TODO: modify the info below
# Student ID: 261051043
# Name: Minna Feng
# TODO END
########### COMP 273, Winter 2022, Assignment 4, Question 2 - Game of Life ###########

.data
# You should use following two labels for opening input/output files
# DO NOT change following 2 lines for your submission!
inputFileName:	.asciiz	"life-input.txt"
outputFileName:	.asciiz "life-output.txt"
# TODO: add any variables here you if you need
buffer:		.space 10100 # max number of bytes to read
paddedBuffer:	.space 10404
finalBuffer:	.space 10100

# TODO END

.text
main:
	# read the integer n from the standard input
	jal readInt
	# now $v0 contains the number of generations n you should simulate
	
# TODO: your code in main process here

# A live cell will stay alive if it has two or three live neighbours
# A dead cell will come to life if it has exactly three live neighbours
	move $s7,$v0 # s7 = number of generations to stimulate
	
	# opening file
	li $v0,13 		# open_file syscall
	la, $a0, inputFileName
	li $a1,0 		# read flag
	li $a2,0 		# ignore mode
	syscall
	
	move $s0,$v0 		# s0 = file descriptor
	
	# reading file
	li $v0,14 		# read_file syscall
	move $a0,$s0 		# a0 = file descriptor
	la $a1,buffer
	li $a2,10100 		# wost case number of chars to read
	syscall
	
	move $s5,$v0 		# s5 = num chars read
	
	# Closing the file 
	li $v0,16       # close_file syscall
	move $a0,$s0    # file descriptor to close
	syscall         
	
	# Check if n=0
	beqz $s7,initialState # reprint initial board if n=0
	
	# get number of number of rows and cols of board
	la $a0,buffer
	move $a1,$s5 	# a1 = num chars read
	jal getDim
	
	move $s0,$v0 	# s0 = height
	move $s1,$v1 	# s1 = width
	
	# pad board with dead cells 
	la $a0,buffer
	move $a1,$s1
	move $a2,$s0
	jal addBorder
	
	# getting total number of chars in padded buffer
	add $s5,$s5,$s0
	add $s5,$s5,$s1
	add $s5,$s5,$s1
	addi $s5,$s5,4 	# s5 = num chars in padded buffer

	# STIMULATING GENERATIONS
	li $s3,0 # generation counter

genLoop:
	la $a0,paddedBuffer
	move $a1,$s5
	move $a2,$s1
	jal firstPass
	
	la $a0,paddedBuffer
	move $a1,$s5
	jal secondPass
	
	addi $s3,$s3,1 		# increment generation counter
	beq $s3,$s7,write 	# branch to write if generation counter == n
	j genLoop
	
	# WRITE TO FINAL BUFFER 
write:
	la $a0,paddedBuffer
	move $a1,$s5
	move $a2,$s1
	la $a3,finalBuffer
	jal removeBorder

 	# WRITING TO OUTPUT FILE
	
	# Open file
  	li $v0,13       
  	la $a0,outputFileName  
 	li $a1,1 		# write flag
	li $a2,0 		# ignore mode
 	syscall           
 	move $s0,$v0 		# save the file descriptor 
 	
 	# Write to file
 	li $v0,15
 	move $a0,$s0
 	la $a1,finalBuffer
 	li $a2,10100
 	syscall
 	
 	# Close file
	li $v0,16       # close_file syscall
	move $a0,$s0    # file descriptor to close
	syscall      
	j done
	
initialState:
	# Open file
  	li $v0,13       
  	la $a0,outputFileName  
 	li $a1,1 		# write flag
	li $a2,0 		# ignore mode
 	syscall           
 	move $s0,$v0 		# save the file descriptor 
 	
 	# Write to file
 	li $v0,15
 	move $a0,$s0
 	la $a1,buffer
 	li $a2,10100
 	syscall
 	
 	# Close file
	li $v0,16       # close_file syscall
	move $a0,$s0    # file descriptor to close
	syscall      
	j done
	
done:
# TODO END

	li $v0, 10	# exit the program
	syscall


# TODO: your helper functions here
getDim:
	# a0 = pointer to buffer
	# a1 = number of chars read into buffer
	# v0 = number of rows
	# v1 = number of columns
	
	move $t0,$a0
	move $t1,$a1
	li $t2,0 	# set col counter to 0
	li $t3,'\n'

getDim.loop:	# get cols: count chars up until newline
	lb $t4,0($t0)
	
	beq $t4,$t3,getDim.return
	addi $t2,$t2,1 # increment col counter
	addi $t0,$t0,1 # increment pointer
	j getDim.loop
	
getDim.return:	
	move $v1,$t2 # v1 = num of cols
	addi $t2,$t2,1 # increment col counter by 1 to account for newline
	div $v0,$t1,$t2 # v0 = num chars/num cols = num of rows
	
	jr $ra
	
addBorder:
	# SET PADDED DEAD CELLS (-1)
	# a0 = pointer to buffer
	# a1 = board width
	# a2 = board height
	
	move $t0,$a0 # t0 = pointer to buffer
	move $t1,$a1  # t1 = board width
	add $t9,$a2,1 # t9 = board height, add 1 for easier implementation later on
	la $t2,paddedBuffer # t2 = pointer to new buffer

	li $t3,' ' # t3 = unrevivable dead cell 
	li $t4,0 # t4 = counter for width 
	li $t8,0 # t8 = counter for height 
	
	addi $t1,$t1,1 # add 1 to width
	# We want to pad the top of the board with dead cells, we exclude from padding the top right corner,
	# so that we can pad it in the next loop for easier implementation
	addi $t0,$t0,-1 # back up old buffer pointer by 1
	
addBorder.loop1:
	sb $t3,0($t2)
	addi $t4,$t4,1 # increment counter
	addi $t2,$t2,1 # advance pointer 
	beq $t4,$t1,addBorder.nextLine # go to next loop when done first line
	j addBorder.loop1

addBorder.nextLine:
	li $t4,0 # reset counter to 0
	move $t1,$a1 # reset width back to normal
	# pointer is already at next cell
	sb $t3,0($t2)
	addi $t2,$t2,1 # advance pointer 
	sb $t3,0($t2)
	addi $t2,$t2,1 # advance padded buffer pointer
	addi $t0,$t0,1 # advance pointer past newline in old buffer
	addi $t8,$t8,1 # increment line counter (height)
	beq $t8,$t9,addBorder.bottom
	
	
addBorder.loop2: # retranscribe values from old to new buffer
	lb $t5,0($t0)
	sb $t5,0($t2)
	addi $t4,$t4,1 # increment counter
	addi $t2,$t2,1 # advance pointer in new buffer
	addi $t0,$t0,1 # advance pointer in old buffer
	beq $t4,$t1,addBorder.nextLine # branch after reading one line from old buffer
	j addBorder.loop2
	
addBorder.bottom:
	addi $t1,$t1,1 # add 1 to width
	
addBorder.loop3:
	sb $t3,0($t2)
	addi $t4,$t4,1 # increment width counter
	addi $t2,$t2,1 # advance pointer
	beq $t4,$t1,addBorder.return
	j addBorder.loop3
	
addBorder.return:
	jr $ra
	
firstPass:
	# marks down all cells to be killed and revived in buffer for one generation
	# a0 = pointer to buffer
	# a1 = num of chars for eof
	# a2 = width
	
	move $t0,$a0 # t0 = pointer to buffer
	move $t1,$a1 # t1 = num of chars 
	move $t4,$a2 # t4 = width
	 
	 
	li $t2,0 # t2 = char counter
	li $t3,'1' # t3 = live cell
	
firstPass.loop:
	lb $t6,0($t0)

	li $t9,' ' # t9 = unrevivable dead cell
	beq $t6,$t9,firstPass.next # branch if part of padded border
	li $t5,0 # t5 = counter of live neighbours 
	
	# check neighbours 
	# west 
	lb $t9,-1($t0)
	blt $t9,$t3,east # branch if not a live neighbour
	addi $t5,$t5,1 # increment live cell counter
	
east:
	lb $t9,1($t0)
	blt $t9,$t3,north
	addi $t5,$t5,1 
	
north:
	sub $t8,$t0,$t4 # move pointer to top of pixel
	sub $t8,$t8,2 # account for extra width caused by border
	lb $t9,0($t8)
	blt $t9,$t3,northwest
	addi $t5,$t5,1
	
northwest:
	addi $t8,$t8,-1 
	lb $t9,0($t8)
	blt $t9,$t3,northeast
	addi $t5,$t5,1
	
northeast:
	addi $t8,$t8,2
	lb $t9,0($t8)
	blt $t9,$t3,south
	addi $t5,$t5,1
	
south:
	add $t8,$t0,$t4 # move pointer to bottom of pixel
	add $t8,$t8,2 # account for extra width caused by border
	lb $t9,0($t8)
	blt $t9,$t3,southwest
	addi $t5,$t5,1
	
southwest:
	addi $t8,$t8,-1 
	lb $t9,0($t8)
	blt $t9,$t3,southeast
	addi $t5,$t5,1
	
southeast:
	addi $t8,$t8,2
	lb $t9,0($t8)
	blt $t9,$t3,isLive
	addi $t5,$t5,1

isLive:
	li $t9,'0' 
	beq $t6,$t9,isDead 
	# branch if live cell has 2-3 live neighbours (can stay alive)
	li $t9,2
	beq $t5,$t9,firstPass.next
	li $t9,3
	beq $t5,$t9,firstPass.next
	# else: live cell must die
	li $t9,'k' # store 'k' to kill later
	sb $t9,0($t0)
	j firstPass.next
	
isDead:	
	li $t9,3
	bne $t5,$t9,firstPass.next # if not 3 live neighbours, can't revive
	# else" revive dead cell 
	li $t9,'#' # store '#' to revive later 
	sb $t9,0($t0)

firstPass.next:
	addi $t0,$t0,1 # advance pointer
	addi $t2,$t2,1 # increment char counter
	beq $t2,$t1,firstPass.return # branch when done reading through all chars
	j firstPass.loop
	
firstPass.return:
	jr $ra 
	
secondPass:
	# a0 = pointer to buffer
	# a1 = num of chars
	
	move $t0,$a0 # t0 = pointer to buffer
	move $t1,$a1 # t1 = num of chars
	li $t2,0 # t2 = char counter
	
	
secondPass.loop:
	lb $t9,0($t0)
	# branch if part of border or no action to be taken
	li $t8,' '
	beq $t9,$t8,secondPass.next 
	li $t8,'0'
	beq $t9,$t8,secondPass.next 
	li $t8,'1'
	beq $t9,$t8,secondPass.next 
	# else: must kill or revive cell
	li $t8,'k'
	bne $t9,$t8,revive
	# kill cell
	li $t8,'0'
	sb $t8,0($t0)
	j secondPass.next
	
revive:
	li $t8,'1'
	sb $t8,0($t0)

secondPass.next:
	addi $t0,$t0,1
	addi $t2,$t2,1
	beq $t2,$t1,secondPass.return
	j secondPass.loop
	
secondPass.return:
	jr $ra
	
removeBorder:
	# a0 = pointer to padded buffer
	# a1 = num of chars
	# a2 = width
	# a3 = pointer to final buffer 
	
	move $t0,$a0 # t0 = pointer to padded buffer
	move $t1,$a1 # t1 = num of chars
	move $t2,$a2 # t2 = width
	move $t3,$a3 # t3 = pointer to final buffer
	
	li $t4,0 # char counter
	li $t5,0 # width counter
	
removeBorder.loop:
	lb $t6,0($t0)
	# branch if part of border
	li $t7,' ' 
	beq $t6,$t7,removeBorder.next
	# else: store
	sb $t6,0($t3)
	addi $t3,$t3,1 # advance pointer in final buffer

checkWidth:
	# add newlines
	addi $t5,$t5,1 # increment width counter
	bne $t5,$t2,removeBorder.next
	li $t8,'\n'
	sb $t8,0($t3)
	li $t5,0 # set width counter back to 0
	addi $t3,$t3,1 # advance pointer in final buffer
	
removeBorder.next:
	# next cell
	addi $t0,$t0,1 # advance pointer in padded buffer
	addi $t4,$t4,1 # increment char counter
	beq $t4,$t1,removeBorder.return # branch if read through all chars in padded buffer 
	j removeBorder.loop
	
removeBorder.return:
	jr $ra

	
# TODO END

########### Helper functions for IO ###########

# read an integer
# int readInt()
readInt:
	li $v0, 5
	syscall
	jr $ra
