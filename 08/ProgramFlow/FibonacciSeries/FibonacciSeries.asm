@ARG
D=M
@1
A=D+A
D=M
@SP
A=M
M=D
@SP
M=M+1
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M+1
@4
M=D
@SP
M=M-1
@0
D=A
@SP
A=M
M=D
@SP
M=M+1
@THAT
D=M
A=D
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M+1
@R13
A=M
M=D
@SP
M=M-1
@1
D=A
@SP
A=M
M=D
@SP
M=M+1
@THAT
D=M
@1
A=D+A
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M+1
@R13
A=M
M=D
@SP
M=M-1
@ARG
D=M
A=D
D=M
@SP
A=M
M=D
@SP
M=M+1
@2
D=A
@SP
A=M
M=D
@SP
M=M+1
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M-1
@SP
A=M
A=M
D=A-D
@SP
A=M
M=D
@SP
M=M+1
@ARG
D=M
A=D
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M+1
@R13
A=M
M=D
@SP
M=M-1
(MAIN_LOOP_START)
@ARG
D=M
A=D
D=M
@SP
A=M
M=D
@SP
M=M+1
@SP
M=M-1
@SP
A=M
D=M
@COMPUTE_ELEMENT
D;JNE
@END_PROGRAM
0;JMP
(COMPUTE_ELEMENT)
@THAT
D=M
A=D
D=M
@SP
A=M
M=D
@SP
M=M+1
@THAT
D=M
@1
A=D+A
D=M
@SP
A=M
M=D
@SP
M=M+1
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M-1
@SP
A=M
A=M
D=D+A
@SP
A=M
M=D
@SP
M=M+1
@THAT
D=M
@2
A=D+A
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M+1
@R13
A=M
M=D
@SP
M=M-1
@4
D=M
@SP
A=M
M=D
@SP
M=M+1
@1
D=A
@SP
A=M
M=D
@SP
M=M+1
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M-1
@SP
A=M
A=M
D=D+A
@SP
A=M
M=D
@SP
M=M+1
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M+1
@4
M=D
@SP
M=M-1
@ARG
D=M
A=D
D=M
@SP
A=M
M=D
@SP
M=M+1
@1
D=A
@SP
A=M
M=D
@SP
M=M+1
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M-1
@SP
A=M
A=M
D=A-D
@SP
A=M
M=D
@SP
M=M+1
@ARG
D=M
A=D
D=A
@R13
M=D
@SP
M=M-1
@SP
A=M
D=M
@SP
M=M+1
@R13
A=M
M=D
@SP
M=M-1
@MAIN_LOOP_START
0;JMP
(END_PROGRAM)
