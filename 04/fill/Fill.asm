// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel;
// the screen should remain fully black as long as the key is pressed. 
// When no key is pressed, the program clears the screen, i.e. writes
// "white" in every pixel;
// the screen should remain fully clear as long as no key is pressed.

// Put your code here.


    @currentScreenState
    M=0                     // currentScreenState = white

    @desiredScreenState
    M=0                     // desiredScreenState = white


(LOOP)
    @KBD
    D=M                     // D = Current keyboard character

    @SET_DESIRED_WHITE
    D;JEQ


(SET_DESIRED_BLACK)
    @desiredScreenState
    M=-1                    // All 1 bits

    @SET_SCREEN
    0;JMP                   // Set screen now


(SET_DESIRED_WHITE)
    @desiredScreenState
    M=0

    @SET_SCREEN
    0;JMP                   // Set screen now


(SET_SCREEN)
    @desiredScreenState
    D=M

    @currentScreenState
    D=D-M                   // desiredScreenState - currentScreenState

    @LOOP
    D;JEQ                   // Jump back to main loop if screen is already in desired state

    // Setup screen setting
    @SCREEN
    D=A                     // D = Screen address
    @8192
    D=D+A                   // Byte after last screen address byte
    @i
    M=D                     // i = Byte after last screen address byte

    @8192
    D=A
    @screenCounter
    M=D                     // screenCounter = length of screen address space

    // Record new state of screen
    @desiredScreenState
    D=M                     // D = desiredScreenState
    @currentScreenState
    M=D                     // currentScreenState = desiredScreenState

(SET_SCREEN_LOOP)
    @i
    D=M-1
    M=D                     // i = i - 1

    @screenCounter
    D=M-1
    M=D                     // screenCounter = screenCounter - 1
    
    @LOOP
    D;JLT                   // Jump back to main loop if screen has finished being filled according to desired state

    @desiredScreenState
    D=M                     // D = desiredScreenState (black or white)
    @i
    A=M                     // A = i
    M=D                     // M[i] = desiredScreenState

    @SET_SCREEN_LOOP
    0;JMP