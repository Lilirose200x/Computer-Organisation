.global	_start
_start:

main:
	LDR R2,=N_th
	LDR R1, [R2]
	BL fill_fib          @call fib(N_th)
	LDR R2,=fib_N
	STR R1, [R2]    @save to fib_N
	B end

fill_fib:
	CMP R1, #1
	BLE ln_ret

	PUSH {R2-R3, lr}
	MOV R2, R1      @R2 = raw_R1

	SUB R1, R2, #1
	BL fill_fib          @fib(R - 1)
	MOV R3, R1      @R3 = tmp_sum

	SUB R1, R2, #2
	BL fill_fib          @fib(R - 2)
	ADD R3, R3, R1  @R3 += tmp_sum
	MOV R1, R3      @a1 = ret_val

	POP {R2-R3, lr}

ln_ret: 
	MOV pc, lr
	
end:
	B end

.data
N_th:  .word 8         @Nth
fib_N: .word 0         @ret_val of fib(N)

Fib8 link保存住，push 7,6
又返回去保存fib7 link, push 5,6
不断返回直到fib0，
根据1，2求出fib2,根据lr求出fib3...8