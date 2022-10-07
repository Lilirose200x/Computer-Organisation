.global	_start
_start:

    LDR R1, =arr @ load base address of arr[0] to r1
    MOV R2, #5 @ load number of array element
    MOV R3, #0  @ i = 0

bubble_sort:
    CMP R3,R2   @ compare r2 and r3, if i == n ?
    BGE end_program

    MOV R4, #0  @ j = 0
outter_loop:
    SUB R10, R2, R3 
    SUB R10, R10, #1 
    CMP R4, R10 @ j == (n-i-1)?
    BGE end_inner_loop

inner_loop:
    @ fetch arr[j] from memory
    LSL R5, R4, #2   
    ADD R8, R1, R5  
    LDR R5, [R8]    
    @ fetch arr[j+1] from memory
    ADD R6, R4, #1 
    LSL R6, R6, #2   
    ADD R9, R1, R6  
    LDR R6, [R9]    

    @ compare arr[j] and arr[j+1], branch if arr[j] is greater
    CMP R5, R6
    BGT swap_element
    B skip_swap

    swap_element:
    STR R5, [R9]
    STR R6, [R8]

    skip_swap:
    ADD R4, R4, #1 @ j++
    B outter_loop
    
end_inner_loop:
    ADD R3, R3, #1 @ i++
    B bubble_sort

@ end of program
end_program:
    LDR R1, =arr
    LDR R0, [R1]

    ADD R1, R1, #16
    LDR R1, [R1]

end:
    B end

.data
@ initialize arrary
arr: .word -1, 23, 0, 12, -7