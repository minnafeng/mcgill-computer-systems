# Recreates the Snake video game using memory mapped I/O (MMIO)

# Constant definitions
# color definition:
.eqv BLACK	0x00000000
.eqv RED	0x00ff0000
.eqv GREEN	0x0000ff00
.eqv BLUE	0x000000ff
.eqv YELLOW	0x00ffff00
.eqv BROWN	0x00994c00
.eqv GRAY	0x00f0f0f0
.eqv WHITE	0x00ffffff

# tile definition
.eqv EMPTY	BLACK
.eqv SNAKE	WHITE
.eqv FOOD	YELLOW
.eqv RED_PILL	RED
.eqv BLUE_PILL	BLUE
.eqv WALL	BROWN

# Direction definition
.eqv DIR_RIGHT	0
.eqv DIR_DOWN	1
.eqv DIR_LEFT	2
.eqv DIR_UP  3

# game state definition
.eqv STATE_NORMAL	0
.eqv STATE_PAUSE	1
.eqv STATE_RESTART	2
.eqv STATE_EXIT		3

# some constants for buffer
.eqv WIDTH	64
.eqv HEIGHT	32
.eqv DISPLAY_BUFFER_SIZE	0x2000
.eqv SNAKE_BUFFER_SIZE		0x2000

# initial postion of the snake
.eqv INIT_HEAD_X	32
.eqv INIT_HEAD_Y	16
.eqv INIT_TAIL_X	31
.eqv INIT_TAIL_Y	16

# initial length of the snake
.eqv INIT_LENGTH	2

# maximum number of pills
.eqv MAX_NUM_PILLS	10

# TODO: add any constants here you if you need


# TODO END


.data
displayBuffer:	.space	DISPLAY_BUFFER_SIZE	# 64x32 display buffer. Each pixel takes 4 bytes.
snakeSegment:	.space	SNAKE_BUFFER_SIZE	# Array to store the offsets of the snake segments in the display buffer.
						# E.g., head_offset, 2nd_segment_offset, ..., tail_offset
						# Each offset takes 4 bytes.
snakeLength:	.word	INIT_LENGTH		# length of the snake
headX:		.word	INIT_HEAD_X		# head position x
headY:		.word	INIT_HEAD_Y		# head position y
numPills:	.word	0	# number of pills (red and blue)
direction:	.word	0	# moving direction of the snake head:
				#	0: right
				#	1: down
				#	2: left
				#	3: up
state:		.word	0	# game state:
				#	0: normal
				#	1: pause
				#	2: retstart
				#	3: exit
score:		.word	0	# score in the game. increase by 1 everying time eating a regular food
msgScore:	.asciiz "Score: "
.align 2
timeInterval:	.word   100
incSpeed:	.float 0.833333
decSpeed:	.float 1.25

# TODO: add any variables here you if you need
inputFileName:	.asciiz	"map.txt"
buffer:		.space 2080

# TODO END


.text
main:
	jal initGame
gameLoop:
	li $v0, 32
	lw $a0, timeInterval
	syscall
	
# TODO: objective 1, Handle Keyboard Input using MMIO 

	# Reading in input
	lw $s1,state 		# s1 = current state
	
  	lui $t0, 0xffff 	# $t0 = 0xffff0000
read:
	lw $t1, 0($t0) 		# $t1 = value(0xffff0000)
	andi $t1,$t1,0x0001	# Is Device ready?
	
	bnez $t1,ready		# branch if ready 
	beq $s1,STATE_PAUSE,read # If paused, keep waiting for input until ready 
	j done			# Else, do nothing if input not ready
	
ready:	
	lw $s0, 4($t0) 		# Read data from 0xffff0004
				# s0 = input
	bne $s1,STATE_PAUSE,continue # continue if not paused
	beq $s0,'p',stateResume
	
continue:
	# Check for directions
	lw $s2,direction	# s2 = current direction
	
	beq $s0,'w',dirUp
	beq $s0,'a',dirLeft
	beq $s0,'d',dirRight
	beq $s0,'s',dirDown
	
	# If not, check for states
	beq $s0,'q',stateQuit
	beq $s0,'r',stateRestart
	beq $s0,'p',statePause
	
dirUp:	
	# Do nothing if direction is the same as last 
	li $s1,DIR_UP		# s1 = new direction val
	beq $s1,$s2,done
	
	# Do nothing if direction is the reverse of last 
	li $s0,DIR_DOWN		# s0 = opposite dir
	beq $s0,$s2,done
	
	sw $s1,direction
	j done

dirLeft:	
	li $s1,DIR_LEFT
	beq $s1,$s2,done
	
	li $s0,DIR_RIGHT
	beq $s0,$s2,done
	
	sw $s1,direction
	j done
	
dirRight:	
	li $s1,DIR_RIGHT
	beq $s1,$s2,done
	
	li $s0,DIR_LEFT
	beq $s0,$s2,done
	
	sw $s1,direction
	j done
	
dirDown:	
	li $s1,DIR_DOWN
	beq $s1,$s2,done
	
	li $s0,DIR_UP
	beq $s0,$s2,done
	
	sw $s1,direction
	j done

stateQuit:
	li $s1,STATE_EXIT
	sw $s1,state
	j done

stateRestart:
	li $s1,STATE_RESTART
	sw $s1,state
	j done

statePause: 
	li $s1,STATE_PAUSE
	sw $s1,state
	j done

stateResume: # resume if paused
	li $s1,STATE_NORMAL
	sw $s1,state
	j done
	
	

done:
# TODO END
	
	lw $t0, state
	beq $t0, STATE_NORMAL, main.normal
	beq $t0, STATE_PAUSE, main.pause
	beq $t0, STATE_RESTART, main.restart
	j main.exit
main.normal:
	jal updateDisplay	
	j gameLoop
main.pause:
	j gameLoop
main.restart:
	jal initGame
	j gameLoop	
main.exit:
	la $a0, msgScore
	li $v0, 4
	syscall
	lw $a0, score
	li $v0, 1
	syscall
	li $v0, 10
	syscall
	
	
# void initGame()
initGame:
	sub $sp, $sp, 4
	sw $ra, ($sp)
	
	la $a0, displayBuffer
	li $a1, DISPLAY_BUFFER_SIZE
	jal clearBuffer
	
	jal initMap
	
	# initialize variables
	li $t0, INIT_LENGTH
	sw $t0, snakeLength
	li $t0, INIT_HEAD_X
	sw $t0, headX
	li $t0, INIT_HEAD_Y
	sw $t0, headY
	li $t0, DIR_RIGHT
	sw $t0, direction
		
	li $a0, INIT_HEAD_X
	li $a1, INIT_HEAD_Y
	jal pos2offset
	li $t0, SNAKE
	sw $t0, displayBuffer($v0)	# draw head pixel
	sw $v0, snakeSegment		# head offset

	li $a0, INIT_TAIL_X
	li $a1, INIT_TAIL_Y
	jal pos2offset
	li $t0, SNAKE
	sw $t0, displayBuffer($v0)	# draw tail pixel
	sw $v0, snakeSegment+4		# tail offset
	
	sw $zero, numPills
	li $t0, STATE_NORMAL
	sw $t0, state
	sw $zero, score
	
	# set seed for corresponding pseudorandom number generator using system time
	li $v0, 30
	syscall
	move $a1, $a0
	li $a0, 0	# ID = zero
	li $v0, 40
	syscall	
	
	# spawn food
	jal spawnFood

	lw $ra, ($sp)
	add $sp, $sp, 4	
	jr $ra
	
	
# void updateDisplay()
updateDisplay:
	sub $sp, $sp, 8
	sw $ra, ($sp)
	sw $s0, 4($sp)
	
	lw $a0, headX
	lw $a1, headY
	lw $t0, direction
	beq $t0, DIR_RIGHT, updateDisplay.goRight
	beq $t0, DIR_DOWN, updateDisplay.goDown
	beq $t0, DIR_LEFT, updateDisplay.goLeft
	beq $t0, DIR_UP, updateDisplay.goUp
updateDisplay.goRight:
	add $a0, $a0, 1
	blt $a0, WIDTH, updateDisplay.headUpdateDone
	sub $a0, $a0, WIDTH	# wrap over if exceeds boundary
	j updateDisplay.headUpdateDone
updateDisplay.goDown:
	add $a1, $a1, 1
	blt $a1, HEIGHT, updateDisplay.headUpdateDone
	sub $a1, $a1, HEIGHT	# wrap over if exceeds boundary
	j updateDisplay.headUpdateDone
updateDisplay.goLeft:
	sub $a0, $a0, 1
	bge $a0, 0, updateDisplay.headUpdateDone
	add $a0, $a0, WIDTH	# wrap over if exceeds boundary
	j updateDisplay.headUpdateDone
updateDisplay.goUp:
	sub $a1, $a1, 1
	bge $a1, 0, updateDisplay.headUpdateDone
	add $a1, $a1, HEIGHT	# wrap over if exceeds boundary
	j updateDisplay.headUpdateDone
updateDisplay.headUpdateDone:
	sw $a0, headX
	sw $a1, headY
	jal pos2offset
	move $s0, $v0		# store the head offset because we need it later

	lw $t0, displayBuffer($s0) # what is in the next posion of head?
	beq $t0, EMPTY, updateDisplay.empty
	beq $t0, FOOD, updateDisplay.food
	beq $t0, RED_PILL, updateDisplay.redPill
	beq $t0, BLUE_PILL, updateDisplay.bluePill
	# else hit into bad thing
	li $t0, STATE_EXIT
	sw $t0, state
	j updateDisplay.ObjectDetectionDone
	
updateDisplay.empty:	# nothing
	li $t0, SNAKE
	sw $t0, displayBuffer($s0)	# draw head pixel
	
	# erase old tail in display (set color to black)
	lw $t0, snakeLength
	sub $t0, $t0, 1
	sll $t0, $t0, 2
	lw $t1, snakeSegment($t0)	# load the tail offset
	li $t2, EMPTY
	sw $t2, displayBuffer($t1)
	
	j updateDisplay.ObjectDetectionDone
	
updateDisplay.food:	#regular food
	li $t0, SNAKE
	sw $t0, displayBuffer($s0)	# draw head pixel
	lw $t0, snakeLength
	add $t0, $t0, 1
	sw $t0, snakeLength	# increase snake length
	
	jal spawnFood
	lw $t0, score
	add $t0, $t0, 1
	sw $t0, score
	
	j updateDisplay.ObjectDetectionDone
	
updateDisplay.redPill:
	li $t0, SNAKE
	sw $t0, displayBuffer($s0)	# draw head pixel
	
	# erase old tail in display (set color to black)
	lw $t0, snakeLength
	sub $t0, $t0, 1
	sll $t0, $t0, 2
	lw $t1, snakeSegment($t0)	# load the tail offset
	li $t2, EMPTY
	sw $t2, displayBuffer($t1)
	
	lw $t0, numPills
	sub $t0, $t0, 1
	sw $t0, numPills
	
	# increase game speed
	lw $t0, timeInterval
	mtc1 $t0, $f0
	cvt.s.w $f0, $f0
	l.s $f1, incSpeed
	mul.s $f0, $f0, $f1
	cvt.w.s $f0, $f0
	mfc1 $t0, $f0
	sw $t0, timeInterval
	
	j updateDisplay.ObjectDetectionDone
	
updateDisplay.bluePill:
	li $t0, SNAKE
	sw $t0, displayBuffer($s0)	# draw head pixel
	
	# erase old tail in display (set color to black)
	lw $t0, snakeLength
	sub $t0, $t0, 1
	sll $t0, $t0, 2
	lw $t1, snakeSegment($t0)	# load the tail offset
	li $t2, EMPTY
	sw $t2, displayBuffer($t1)
	
	lw $t0, numPills
	sub $t0, $t0, 1
	sw $t0, numPills
	
	# decrease game speed
	lw $t0, timeInterval
	mtc1 $t0, $f0
	cvt.s.w $f0, $f0
	l.s $f1, decSpeed
	mul.s $f0, $f0, $f1
	cvt.w.s $f0, $f0
	mfc1 $t0, $f0
	sw $t0, timeInterval
	
	j updateDisplay.ObjectDetectionDone

updateDisplay.ObjectDetectionDone:
	
	
	# update snake segments
	# for i = length-1 to 1
	#	snakeSegment[i] = snakeSegment[i-1]
	# snakeSegment[0] = new head position (stored in $s0)
	lw $t0, snakeLength	# index i
updateDisplay.snakeUpdateLoop:
	sub $t0, $t0, 1
	blt $t0, 1, updateDisplay.snakeUpdateLoopDone
	sll $t1, $t0, 2		# convert index to offset
	sub $t2, $t1, 4		# offset of previous segment
	lw $t4, snakeSegment($t2)
	sw $t4, snakeSegment($t1) # snakeSegment[i] = snakeSegment[i-1]
	j updateDisplay.snakeUpdateLoop
updateDisplay.snakeUpdateLoopDone:
	sw $s0, snakeSegment	# update head offset in snakeSegment
	
	lw $ra, ($sp)
	lw $s0, 4($sp)
	add $sp, $sp, 8
	jr $ra
	

# int pos2offset(int x, int y)
# offset = (y * WIDTH + x) * 4
# Note that each pixel takes 4 bytes!
pos2offset:
	mul $v0, $a1, WIDTH
	add $v0, $v0, $a0
	sll $v0, $v0, 2
	jr $ra


# void spawnFood()
spawnFood:
	sub $sp, $sp, 4
	sw $ra, ($sp)
	
	# spawn regular food (yellow)
spawnFood.regular:
	li $a0, WIDTH	# range: 0 <= x < WIDTH
	jal randInt
	move $t0, $v0,	# position x
	li $a0, HEIGHT	# range: 0 <= y < HEIGHT
	jal randInt
	move $t1, $v0,	# position y
	move $a0, $t0
	move $a1, $t1
	jal pos2offset
	lw $t0, displayBuffer($v0)		# get "thing" on (x, y)
	bne $t0, EMPTY, spawnFood.regular	# find another place if it is not empty
	li $t0 FOOD
	sw $t0, displayBuffer($v0)	# put the food
	
# TODO: objective 2, Spawn Pills
# see spawnFood.regular for example

spawnFood.red:
	li $a0,5 	# equal probability of picking numbers from 0-4
	jal randInt
	move $t0,$v0 	# t0 = random int
	bnez $t0,spawnFood.blue # don't spawn if not 0
	
	lw $t2,numPills # t2 = num of pills 
	beq $t2,MAX_NUM_PILLS,spawnFood.return # branch if pills are already at max
	
spawnFood.red.getPos:	
	# else, get position for new pill to add
	li $a0,WIDTH
	jal randInt
	move $t0,$a0 # t0 = position x
	li $a0,HEIGHT
	jal randInt
	move $t1,$a0 # t1 = position y
	# get offset
	move $a0,$t0
	move $a1,$t1
	jal pos2offset
	lw $t0,displayBuffer($v0) # get "thing" on (x,y)
	bne $t0,EMPTY,spawnFood.red.getPos # find another position if given position occupied
	li $t0,RED_PILL
	sw $t0,displayBuffer($v0) # add pill
	
	# increment number of pills
	addi $t2,$t2,1
	sw $t2,numPills

spawnFood.blue:
	li $a0,100 	# equal probability of picking numbers from 0-4
	jal randInt
	move $t0,$v0 	# t0 = random int
	bge $t0,15,spawnFood.return # don't spawn if not 0
	
	lw $t2,numPills # t2 = num of pills 
	beq $t2,MAX_NUM_PILLS,spawnFood.return # branch if pills are already at max
	
spawnFood.blue.getPos:	
	# else, get position for new pill to add
	li $a0,WIDTH
	jal randInt
	move $t0,$a0 # t0 = position x
	li $a0,HEIGHT
	jal randInt
	move $t1,$a0 # t1 = position y
	# get offset
	move $a0,$t0
	move $a1,$t1
	jal pos2offset
	lw $t0,displayBuffer($v0) # get "thing" on (x,y)
	bne $t0,EMPTY,spawnFood.blue.getPos # find another position if given position occupied
	li $t0,BLUE_PILL
	sw $t0,displayBuffer($v0) # add pill
	
	# increment number of pills
	addi $t2,$t2,1
	sw $t2,numPills

spawnFood.return:
# TODO END
	
	lw $ra, ($sp)
	add $sp, $sp, 4
	jr $ra


# void clearBuffer(char* buffer, int size)
clearBuffer:
	li $t0, 0
clearBuffer.loop:
	bge $t0, $a1, clearBuffer.return
	add $t1, $a0, $t0
	sb $zero, ($t1)
	add $t0, $t0, 1
	j clearBuffer.loop
clearBuffer.return:
	jr $ra


# int randInt(int max)
# generate an random integer n where 0 <= n < max
randInt:
	move $a1, $a0
	li $a0, 0
	li $v0, 42
	syscall
	move $v0, $a0
	jr $ra
	
# void initMap()
initMap:
# TODO: objective 3, Add Walls
# load the map file you create and add wall to displayBuffer

	# opening file
	li $v0,13 		# open_file syscall
	la $a0,inputFileName
	li $a1,0 		# read flag
	li $a2,0 		# ignore mode
	syscall
	
	move $t0,$v0 		# s0 = file descriptor
	
	# reading file
	li $v0,14 		# read_file syscall
	move $a0,$t0 		# a0 = file descriptor
	la $a1,buffer
	li $a2,2080 		# number of chars to read
	syscall
	
	# Closing the file 
	li $v0,16       # close_file syscall
	move $a0,$t0    # file descriptor to close
	syscall         

	la $t0,buffer # t0 = pointer to buffer
	li $t1,0 # counter for num chars
	li $t2,0 # counter for offset
	
initMap.loop:
	lb $t3,0($t0)
	beq $t3,48,initMap.next
	beq $t3,'\n',initMap.newline
	
	li $t4,WALL
	sw $t4,displayBuffer($t2) # store wall 
	
initMap.next:
	addi $t0,$t0,1 # advance pointer
	addi $t1,$t1,1 # increment char counter
	beq $t1,2080,initMap.return
	addi $t2,$t2,4 # increment offset
	j initMap.loop
	
initMap.newline:
	addi $t0,$t0,1 # advance pointer
	addi $t1,$t1,1 # increment char counter
	li $t3,2080
	beq $t1,$t3,initMap.return
	j initMap.loop

initMap.return:
# TODO END
	jr $ra



# TODO END
