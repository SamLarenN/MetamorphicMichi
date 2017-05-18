;***************************************************;
;*               Author: SamLaren                  *;
;***************************************************;

format PE CONSOLE 4.0
entry main

include 'INCLUDE/win32a.inc'
include 'fasmlde32.asm'


_Code_Section			equ [AddressToFree]
_EOF				equ EndOfCode - MainCode

NumberOfLabels			equ 0x1000
NumberOfInstructions		equ 0x1004
AddressOfLastInstruction	equ 0x1008
AddressOfLastReasmInstruction	equ 0x100C
ReasmSize			equ 0x1010
NumberOfFutureLabels		equ 0x1014
RegisterScrambleKey		equ 0x1018
JumpsTable			equ 0x101C
FramesTable			equ 0x1020
PermutationResult		equ 0x1024
NumberOfFrames			equ 0x1028
AddressOfLastFrame		equ 0x103C
PositionOfFirstInstruction	equ 0x1040
FrameCounter			equ 0x1044

Shrink8bit1			equ 0x1048
Shrink8bit2			equ 0x104C
Shrink8bit3			equ 0x1050

AsmBranchCount			equ 0x1054


_Disassemble_Section		equ 0x2000
_Label_Section			equ 0x10000
_Future_Label_Section		equ 0x11500
_Reasm_Section			equ 0x13000
_Buffer_Section 		equ 0x20000
_Buffer2_Section		equ 0x25000
_Disasm2_Section		equ 0x30000


section '.code' readable executable
main1:


	cinvoke printf, hex, eax
	invoke	Sleep, -1


main:
	invoke VirtualAlloc, 0, 0x34000, 0x1000, 0x4
	mov [AddressToFree], eax
	mov ebp, eax
	mov esi, MainCode
	mov edi, eax
	mov ecx, EndOfCode
	sub ecx, MainCode
	rep movsb

	rdtsc
	mov	[RndSeed1], eax      ; Get Rand Seed 1
	rdtsc
	mov	[RndSeed2], eax      ; Get Rand Seed 2

	call disassembler
	call Shrinker
	call Permutator
	;call RegisterScrambler
	call ReAssembler

	;jmp noloop

	mov eax, [AddressToFree]
	add eax, AddressOfLastReasmInstruction
	mov ecx, [eax]

	sub ecx, [AddressToFree]
	sub ecx, _Reasm_Section
	mov eax, [AddressToFree]
	add eax, _Reasm_Section
	xor ebx, ebx


loop1:
	cmp ebx, ecx
	je noloop
	movzx edx, byte[eax+ebx]
	pushad
	cinvoke printf, hex, edx
	popad
	inc ebx
	jmp loop1

noloop:
	;mov	 ebx, ebp
	;add	 ebx, _Reasm_Section
	;invoke  CreateFile, procName, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	;invoke  WriteFile, eax, ebx, [ebp+ReasmSize], 0, 0

	mov	eax, [ebp+ReasmSize]
	cinvoke printf, hex, eax
	mov	eax, [AddressToFree]
	add	eax, _Reasm_Section
	call	eax
	cinvoke printf, hex, eax
	invoke VirtualFree, [AddressToFree], 0, 0x4000
	invoke Sleep, -1


MainCode:		     ; FIXA SHRINKERN

	push	ebx
	pop	edi
	ret

EndOfCode:






;***************************************************************************************************
;			  DISASSEMBLER
;
;
;***************************************************************************************************



disassembler:

	mov esi, _Code_Section

	mov edi, ebp
	add edi, _Disassemble_Section


@Parse:

	push esi
	call mlde32
	cmp eax, -1
	je _@done
	push eax

	mov eax, [esi]
	and eax, 0xFF

	cmp eax, 0x3
	jbe @@OP_ADD

	cmp eax, 0x5
	jbe @@OP_EAX_IMM

	cmp eax, 0xB
	jbe @@OP_OR

	cmp eax, 0xD
	jbe @@OP_EAX_IMM

	cmp eax, 0x0F
	je @@Opcode0F

	cmp eax, 0x23
	jbe @@OP_AND

	cmp eax, 0x25
	jbe @@OP_EAX_IMM

	cmp eax, 0x2B
	jbe @@OP_SUB

	cmp eax, 0x2D
	jbe @@OP_EAX_IMM

	cmp eax, 0x33
	jbe @@OP_XOR

	cmp eax, 0x35
	jbe @@OP_EAX_IMM

	cmp eax, 0x3B
	jbe @@OP_CMP

	cmp eax, 0x3D
	jbe @@OP_EAX_IMM

	cmp eax, 0x4F
	jbe @@OP_INCDEC

	cmp eax, 0x5F
	jbe @@OP_PUSHPOP_REG

	cmp eax, 0x68
	je  @@OP_PUSH_BIG_IMM

	cmp eax, 0x6A
	je  @@OP_PUSH_IMM

	cmp eax, 0x7F
	jbe @@Jcc

	cmp eax, 0x83
	jbe @@OP_REG_IMM

	cmp eax, 0x85
	jbe @@OP_TEST

	cmp eax, 0x8F
	je  @@OPCODE0x8F

	cmp eax, 0x8B
	jbe @@OP_MOV

	cmp eax, 0x90
	je  @@NOP

	cmp eax, 0xA1
	jbe @@MOV_EAX_MEM

	cmp eax, 0xA3
	jbe @@MOV_MEM_EAX

	cmp eax, 0xA9
	jbe @@OP_EAX_IMM

	cmp eax, 0xBF
	jbe @@OP_MOV_REG_IMM

	cmp eax, 0xC3
	je @@OP_RET

	cmp eax, 0xC7
	jbe @@OP_MOV_MEM_IMM

	cmp eax, 0xE8
	je @@CALL

	cmp eax, 0xEB
	je @OP_JMP_SHRT

	cmp eax, 0xF7
	jbe @@OP_TEST_IMM

	cmp eax, 0xFF
	je @@OPCODE0xFF





	pop eax
	add esi, eax
	jmp @Parse



_@done:
	;*********** Mark pseudo instr with label marks (check from label buffer) *****************
	mov eax, [AddressToFree]
	add eax, _Label_Section
	mov edx, [eax]

	mov eax, [AddressToFree]		       ; and save it as the address of last instr
	add eax, AddressOfLastInstruction
	mov [eax], edi				       ; save it here


	mov eax, [AddressToFree]
	add eax, NumberOfInstructions
	mov ecx, [eax]				       ; Load ecx with number of instructions

	xor ebx, ebx

	sub edi, 18				       ; Align last instruction to the last instruction.
						       ; So it does not point to a null instuction.

;;;; This is a loop within a loop. First loop retrieves a address of an instr in the code section
;;;; from the address in struct (+14). Then compares it with all the stored labels..
;;;; If they match, it marks it at LM (+9).

Continue_Mark:			 ;FIRST LOOP
	cmp ecx, 0			       ; check if all instructions have been parsed
	je End_Label_Marking			; if so jmp to the end
	mov eax, [edi+14]			; load eax with a address from the code section

	push ecx				; save the instr counter for after the second loop

;;;; Initialize the second loop by loading ecx with number of labels
;;;; and edx with the address of the first label from the label section

	mov ecx, [AddressToFree]
	add ecx, NumberOfLabels
	mov ecx, [ecx]
	mov edx, [AddressToFree]
	add edx, _Label_Section

Parse_Labels:			 ; SECOND LOOP
	cmp ecx, 0			       ; check if all labels have been tested
	je Done_Parsing 			; if yes, jmp to end of label loop
	mov ebx, [edx]				; load ebx with first label

	cmp ebx, eax				; check if address and label match
	je Mark_Instruction			; if yes, jump to mark instruction

	dec ecx 				; decrement number of labels
	add edx, 4				; go to next label in label section
	jmp Parse_Labels			; LOOP


Mark_Instruction:

	mov edx, [AddressToFree]
	add edx, NumberOfLabels
	mov edx, [edx]
	sub edx, ecx				; number of labels - ecx (label counter) = position
	inc edx 				; increment edx to prevent 0 as label dst.

	mov [edi+9], edx			; set LM with a number to which jmp jumps to this instr


Done_Parsing:		       ; If done parsing second loop, continue with the first.
	pop ecx

	dec ecx 				; decrement number of instructions
	sub edi, 18				; and continue to get new instr addresses backwards.
	jmp Continue_Mark			; LOOP


End_Label_Marking:

	ret					; End disassembly







@@OP_PUSH_IMM:
	mov eax, 0x68
	mov [edi], eax
	mov eax, [esi+1]
	and eax, 0xFF
	mov [edi+1], eax
	jmp @@NextInstr


@@OP_PUSH_BIG_IMM:
	mov [edi], eax
	mov eax, [esi+1]
	mov [edi+1], eax
	jmp @@NextInstr


@@OP_PUSHPOP_REG:
	mov edx, eax
	and eax, 7
	sub edx, eax
	mov [edi], edx
	mov [edi+1], eax
	jmp @@NextInstr


@@OPCODE0x8F:
	mov edx, 0x8
	mov [edi], edx
	mov eax, [esi+1]
	and eax, 0xFF
	cmp eax, 0x05
	je @@GenPushMem
	cmp eax, 0x40
	jae @@Gen_PushPtrRegOffset

	cmp eax, 0x00
	jae @@Gen_PushPtrReg


@@GenPopMem:
	mov edx, 0x8
	mov [edi], edx
	jmp @@GenPushMem


@@OPCODE0xFF:
	mov eax, [esi+1]
	and eax, 0xFF
	cmp eax, 0x35
	je @@GenPushMem

	cmp eax, 0x25
	je  @@Gen_JMPMem

	cmp eax, 0x70
	jae @@Gen_PushPtrRegOffset

	cmp eax, 0x30
	jae @@Gen_PushPtrReg

	mov eax, 0xEA
	mov [edi], eax
	mov eax, [esi+2]
	mov [edi+10], eax
	jmp @@NextInstr

@@Gen_JMPMem:
	mov eax, 0xEB
	mov [edi], eax
	mov eax, [esi+2]
	mov [edi+10], eax
	jmp @@NextInstr

@@GenPushMem:
	mov eax, 0x51
	add [edi], eax
	mov eax, [esi+2]
	mov [edi+1], eax
	jmp @@NextInstr

@@Gen_PushPtrRegOffset:
	mov edx, [esp]
	cmp edx, 3
	ja @Big_PtrOffset
	mov edx, [esi+2]
	and edx, 0xFF
	mov [edi+10], edx
	jmp @@Gen_PushPtrReg

@Big_PtrOffset:
	mov edx, [esi+2]
	mov [edi+10], edx
	jmp @@Gen_PushPtrReg

@@Gen_PushPtrReg:
	and eax, 7
	mov edx, 0x52
	add [edi], edx
	mov [edi+1], eax
	cmp eax, 4
	je PtrReg_ESP
	jmp @@NextInstr



@@OP_RET:
	mov eax, 0xFE
	mov [edi], eax
CheckFutLabels:
	call CheckFutureLabelTabel
	test eax, eax
	jz @Done_Disasm

	mov edx, [ebp+NumberOfFutureLabels]
	dec edx
	mov [ebp+NumberOfFutureLabels], edx	       ; decrement NumberOfFutureLabels

	mov ebx, eax
	push eax				       ; Check if the address already has ben disassemd.
	call CheckIfAddressIsDisassembled
	test eax, eax				       ; If it has ben disasd, get new EIP.
	jnz CheckFutLabels

	;;; MANUALLY GO TO NEXT INSTR.
	mov edx, [ebp+NumberOfInstructions]
	inc edx
	mov [ebp+NumberOfInstructions], edx	       ; increment NumberOfInstr

	mov [edi+14], esi
	add edi, 18
	add esp, 4		; Clear stack of instr size.
	mov esi, ebx
	jmp @Parse


@Done_Disasm:
	mov edx, [ebp+NumberOfInstructions]
	inc edx
	mov [ebp+NumberOfInstructions], edx	       ; increment NumberOfInstr

	mov [edi+14], esi
	add edi, 18
	add esp, 4
	jmp _@done



@@NOP:
	mov eax, 0xFF
	mov [edi], eax
	jmp @@NextInstr


@@Opcode0F:
	mov eax, [esi+1]
	and eax, 0xFF
	cmp eax, 0x80
	jb @@NextInstr
	cmp eax, 0x8F
	jbe @@Jcc32
	jmp @@NextInstr


;;; Conditional 32-bit jump (Jx, JNx)
@@Jcc32:
	mov eax, [esi+2]  ; Get the destiny address in EAX
	add eax, esi
	add eax, 6
	jmp @@ContinueWithBranchInstr

;;; CALL
@@CALL:
	mov eax, [esi+1]  ; Get the destiny address in EAX
	add eax, esi
	add eax, 5
	jmp @@ContinueWithBranchInstr


@@Jcc:
	mov eax, [esi+1] ; Get the destiny address in EAX
	and eax, 0FFh
	cmp eax, 7Fh
	jbe @@Jcc_01
	add eax, 0FFFFFF00h
@@Jcc_01:
	add eax, esi
	add eax, 2

@@ContinueWithBranchInstr:
	push ecx		  ; SAVE ECX
	mov ecx, eax		  ; Put the destiny addr. in ECX
	push ecx
	call CheckIfAddressIsDisassembled
	test eax, eax
	jz @NotDisasmYet
	jmp @Disassemed

@RET_CHECKING:

	mov eax, [esi]
	and eax, 0FFh	 ; Get the opcode
	cmp eax, 0Fh	 ; 0F? (i.e. long Jcc)
	je  @@Jcc_Jcc32
	jmp @@Done_Jcc

@@Jcc_Jcc32:
	mov eax, [esi+1] ; Get the conditional jump
	and eax, 0FFh
	sub eax, 10h	 ; Transform it to pseudoopcode


@@Done_Jcc:
	mov edx, [edi]	 ; Set the pseudoopcode in EAX
	and edx, 0FFFFFF00h
	and eax, 0FFh
	add eax, edx
	mov [edi], eax
	;mov [edi+10], ecx	 ; mov storage, jcc/call destination

	inc ebx 		    ; Increment position the label has been added to, to avoid position 0.
	mov [edi+10], ebx
	pop ecx 		   ; RESTORE ECX
	jmp @@NextInstr

@NotDisasmYet:
	push ecx
	call InsertFutureLabel

@Disassemed:
	push ecx
	call InsertLabel  ;*********** Insert label in label buffer *****************
	jmp @RET_CHECKING




;;; JMP
@OP_JMP_SHRT:

	mov ebx, [esi+1] ; Get the displacement
	and ebx, 0FFh
	cmp ebx, 7Fh
	jbe @@JMP8_01
	add ebx, 0FFFFFF00h
@@JMP8_01:
	add ebx, 2	 ; Add the length of the instruction to
	add ebx, esi	 ; the read EIP
	jmp @LoopTrace


@@OP_INCDEC:				 ; add reg, 1 or sub reg, 1
	and eax, 8
	shr eax, 3
	push ecx			 ; SAVE Counter (ECX)
	mov ecx, 0x28
	mul ecx
	pop ecx 			 ; RESTORE Counter (ECX)
	mov [edi], eax
	mov eax, [esi]
	and eax, 0xFF
	and eax, 7
	mov [edi+1], eax
	mov eax, 1
	mov [edi+5], eax
	jmp @@NextInstr


@@MOV_MEM_EAX:
	mov edx, 0x43
	mov [edi], edx
	cmp eax, 0xA2
	je @@MOV_MEM8_AL
@Done_Mem8_Al:
	mov eax, [esi+1]
	mov [edi+1], eax
	jmp @@NextInstr

@@MOV_MEM8_AL:
	mov edx, 0x80
	add [edi], edx
	jmp @Done_Mem8_Al


@@MOV_EAX_MEM:
	mov edx, 0x42
	mov [edi], edx
	cmp eax, 0xA0
	je @@MOV_AL_MEM8
@Done_Al_Mem8:
	mov eax, [esi+1]
	mov [edi+5], eax
	jmp @@NextInstr

@@MOV_AL_MEM8:
	mov edx, 0x80
	add [edi], edx
	jmp @Done_Al_Mem8


@@OP_MOV_MEM_IMM:
	mov eax, 0x44		  ; pseudo mov = 0x40	+ 4 for mem,imm
	mov [edi], eax
	mov eax, [esi]
	and eax, 0xFF
	cmp eax, 0xC6
	je @OP_MOV_MEM8_IMM
 
	mov eax, [esi+2]
	mov [edi+1], eax
	mov eax, [esi+6]
	mov [edi+5], eax
	jmp @@NextInstr
 
@OP_MOV_MEM8_IMM:
	mov eax, 0x80
	add [edi], eax
	mov eax, [esi+2]
	mov [edi+1], eax
	mov eax, [esi+6]
	and eax, 0xFF
	mov [edi+5], eax
	jmp @@NextInstr


@@OP_MOV_REG_IMM:
	mov eax, 0x40		  ; pseudo mov = 0x40
	mov [edi], eax
	mov eax, [esi]
	and eax, 0xFF
	push esi
	cmp eax, 0xB4
	jb @GEN_REG8_IMM	  ; check if 8bit
	pop esi
	and eax, 7
	mov [edi+1], eax
	mov eax, [esi+1]
	mov [edi+5], eax
	jmp @@NextInstr
 
@GEN_REG8_IMM:
	mov eax, 0x80
	add [edi], eax
	mov eax, [esi]
	and eax, 0xFF
	and eax, 7
	mov [edi+1], eax
	mov eax, [esi+1]
	and eax, 0xFF
	mov [edi+5], eax
	pop esi
	jmp @@NextInstr



@@OP_TEST_IMM:
	mov eax, 0x48		  ; pseudo test = 0x48
	mov [edi], eax
	mov eax, [esi+1]
	and eax, 0xFF
	cmp eax, 0x05
	je @@OP_TEST_MEM_IMM	  ; test if it is mem
 
	mov eax, [esi]
	and eax, 0xFF
	push esi
	inc esi
	cmp eax, 0xF6
	je @GEN_REG8_IMM

	pop esi
	mov eax, [esi+1]
	and eax, 0xFF
	and eax, 7
	mov [edi+1], eax
	mov eax, [esi+2]
	mov [edi+5], eax
	jmp @@NextInstr


@@OP_TEST_MEM_IMM:
	mov eax, 0x4
	add [edi], eax
	mov eax, [esi]
	and eax, 0xFF
	cmp eax, 0xF6
	je @@OP_TEST_MEM8_IMM

	mov eax, [esi+2]
	mov [edi+1], eax
	mov eax, [esi+6]
	mov [edi+5], eax
	jmp @@NextInstr
 
@@OP_TEST_MEM8_IMM:
	mov eax, 0x80
	add [edi], eax
	mov eax, [esi+2]
	mov [edi+1], eax
	mov eax, [esi+6]
	and eax, 0xFF
	mov [edi+5], eax
	jmp @@NextInstr




@@OP_REG_IMM:
 
	mov eax, [esi+1]
	and eax, 0xFF
	cmp eax, 0xC0
	jb @@Gen_Mem_Imm	; if second byte < 0xC0 it includes mem instead of reg
 
	mov eax, [esi]
	and eax, 0xFF
	cmp eax, 0x81
	je @@GEN_BIG_IMM	; if first byte = 0x81 it is 4 byte imm else it is 1 byte imm
	cmp eax, 0x80
	je @@Gen_Reg8_Imm	; if first byte = 0x80 it is 8bit args
 
	mov eax, [esi+1]
	and eax, 0xFF
	and eax, 7
	mov edx, eax		; save reg for later storage in edi
	mov eax, [esi+1]
	and eax, 0xFF
	sub eax, 0xC0
	sub eax, edx
	mov [edi], eax
	mov [edi+1], edx
	mov eax, [esi+2]
	and eax, 0xFF
	mov [edi+5], eax
	jmp @@NextInstr
 
@@GEN_BIG_IMM:
	mov eax, [esi+1]
	and eax, 0xFF
	and eax, 7
	mov edx, eax		; save reg for later storage in edi
	mov eax, [esi+1]
	and eax, 0xFF
	sub eax, 0xC0
	sub eax, edx
	mov [edi], eax
	mov [edi+1], edx
	mov eax, [esi+2]
	mov [edi+5], eax
	jmp @@NextInstr
 
@@Gen_Reg8_Imm:
	mov eax, 0x80		; reg8,imm
	mov [edi], eax
	mov eax, [esi+1]
	and eax, 0xFF
	and eax, 7
	mov edx, eax		; save reg for later storage in edi
	mov eax, [esi+1]
	and eax, 0xFF
	sub eax, 0xC0
	sub eax, edx
	add [edi], eax
	mov [edi+1], edx
	mov eax, [esi+2]
	and eax, 0xFF
	mov [edi+5], eax
	jmp @@NextInstr
 
@@Gen_Mem_Imm:
	mov eax, 0x4
	mov [edi], eax
	mov eax, [esi]
	and eax, 0xFF
	cmp eax, 0x80
	je @@Gen_Mem8_Imm	   ; check if it is 8 bit args
 
@Done_Mem8:
	mov eax, [esi+1]
	and eax, 0xFF
	sub eax, 0x5
	add [edi], eax
	mov eax, [esi]
	and eax, 0xFF
	cmp eax, 0x81
	je @@Gen_Mem_Big_Imm	    ; check if it is big imm (same as reg, imm)
 
	mov eax, [esi+2]
	mov [edi+1], eax
	mov eax, [esi+6]
	and eax, 0xFF
	mov [edi+5], eax
	jmp @@NextInstr
 
@@Gen_Mem8_Imm:
	mov eax, 0x80
	add [edi], eax
	jmp @Done_Mem8
 
 
@@Gen_Mem_Big_Imm:
	mov eax, [esi+2]
	mov [edi+1], eax
	mov eax, [esi+6]
	mov [edi+5], eax
	jmp @@NextInstr



@@OP_EAX_IMM:
	mov eax, [esi]
	and eax, 0xFF
	cmp eax, 0xA9
	je OP_TEST_EAX
	cmp eax, 0xA8
	je OP_TEST_Al
	mov edx, [esi]
	and edx, 0xFF
	and edx, 5
	push eax	; save eax
	cmp edx, 4
	je @Reg8
	pop eax 	; restore eax
	sub eax, edx		  ; first byte - 5(32bit) || 4(8bit) = pseudo instr
	add [edi], eax
DONE_TEST:
	mov eax, [esi+1]
	mov [edi+5], eax
	jmp @@NextInstr
 
OP_TEST_EAX:
	mov eax, 0x48
	mov [edi], eax
	jmp DONE_TEST
OP_TEST_Al:
	mov eax, 0xC8
	mov [edi], eax
	jmp DONE_TEST_REG8
 
@Reg8:
	mov eax, 0x80		; Add 0x80 for 8bit reg
	add [edi], eax
	pop eax 		; restore eax
	sub eax, edx		  ; first byte - 5(32bit) || 4(8bit) = pseudo instr
	add [edi], eax
DONE_TEST_REG8:
	mov eax, [esi+1]
	and eax, 0xFF
	mov [edi+5], eax
	jmp @@NextInstr



@@OP_ADD:
	mov eax, 0x0
	mov [edi], eax
	mov eax, [esi]
	and eax, 0xFF
	cmp eax, 0x2
	je @Gen_Reg8_PtrReg8	  ; check if reg8,byte[reg]
	cmp eax, 0x1
	ja @Gen_Reg_PtrReg
 
	cmp eax, 0x0
	je @Gen_Reg8_Reg8	; check if it is Reg8,Reg8
 
	mov eax, [esi+1]	  ; load second byte in eax
	and eax, 0xFF
	cmp eax, 0xC0		 ; check if it is PtrReg,Reg
	jb @Gen_PtrReg_Reg	 ; else jmp to reg, reg
	jmp @Gen_Reg_Reg

@@OP_OR:
	mov eax, 0x8
	mov [edi], eax
	mov eax, [esi]
	and eax, 0xFF
	cmp eax, 0xA
	je @Gen_Reg8_PtrReg8
	cmp eax, 0x9
	ja @Gen_Reg_PtrReg
 
	cmp eax, 0x8
	je @Gen_Reg8_Reg8	 ; check if it is Reg8,Reg8
 
	mov eax, [esi+1]	  ; load second byte in eax
	and eax, 0xFF
	cmp eax, 0xC0		 ; check if it is PtrReg,Reg
	jb @Gen_PtrReg_Reg	 ; else jmp to reg, reg
	jmp @Gen_Reg_Reg

@@OP_AND:
	mov eax, 0x20
	mov [edi], eax
	mov eax, [esi]
	and eax, 0xFF
	cmp eax, 0x22
	je @Gen_Reg8_PtrReg8
	cmp eax, 0x21
	ja @Gen_Reg_PtrReg
 
	cmp eax, 0x20
	je @Gen_Reg8_Reg8	 ; check if it is Reg8,Reg8
 
	mov eax, [esi+1]	  ; load second byte in eax
	and eax, 0xFF
	cmp eax, 0xC0		 ; check if it is PtrReg,Reg
	jb @Gen_PtrReg_Reg	 ; else jmp to reg, reg
	jmp @Gen_Reg_Reg

@@OP_SUB:
	mov eax, 0x28
	mov [edi], eax
	mov eax, [esi]
	and eax, 0xFF
	cmp eax, 0x2A
	je @Gen_Reg8_PtrReg8
	cmp eax, 0x29
	ja @Gen_Reg_PtrReg
 
	cmp eax, 0x28
	je @Gen_Reg8_Reg8	 ; check if it is Reg8,Reg8
 
	mov eax, [esi+1]	  ; load second byte in eax
	and eax, 0xFF
	cmp eax, 0xC0		 ; check if it is PtrReg,Reg
	jb @Gen_PtrReg_Reg	 ; else jmp to reg, reg
	jmp @Gen_Reg_Reg

@@OP_XOR:
	mov eax, 0x30
	mov [edi], eax
	mov eax, [esi]
	and eax, 0xFF
	cmp eax, 0x32
	je @Gen_Reg8_PtrReg8
	cmp eax, 0x31
	ja @Gen_Reg_PtrReg
 
	cmp eax, 0x30
	je @Gen_Reg8_Reg8	 ; check if it is Reg8,Reg8
 
	mov eax, [esi+1]	  ; load second byte in eax
	and eax, 0xFF
	cmp eax, 0xC0		 ; check if it is PtrReg,Reg
	jb @Gen_PtrReg_Reg	 ; else jmp to reg, reg
	jmp @Gen_Reg_Reg

@@OP_CMP:
	mov eax, 0x38
	mov [edi], eax
	mov eax, [esi]
	and eax, 0xFF
	cmp eax, 0x3A
	je @Gen_Reg8_PtrReg8
	cmp eax, 0x39
	ja @Gen_Reg_PtrReg
 
	cmp eax, 0x38
	je @Gen_Reg8_Reg8	  ; check if it is Reg8,Reg8
 
	mov eax, [esi+1]	  ; load second byte in eax
	and eax, 0xFF
	cmp eax, 0xC0		 ; check if it is PtrReg,Reg
	jb @Gen_PtrReg_Reg	 ; else jmp to reg, reg
	jmp @Gen_Reg_Reg

@@OP_MOV:
	mov eax, 0x40
	mov [edi], eax
	mov eax, [esi]
	and eax, 0xFF
	cmp eax, 0x8A
	je @Gen_Reg8_PtrReg8
	cmp eax, 0x89
	ja @Gen_Reg_PtrReg
 
	cmp eax, 0x88		  ; check if it is Reg8,Reg8
	je @Gen_Reg8_Reg8
 
	mov eax, [esi+1]	  ; load second byte in eax
	and eax, 0xFF
	cmp eax, 0xC0		 ; check if it is PtrReg,Reg
	jb @Gen_PtrReg_Reg	 ; else jmp to reg, reg
	jmp @Gen_Reg_Reg

@@OP_TEST:
	mov eax, 0x48
	mov [edi], eax
	mov eax, [esi]
	and eax, 0xFF
	cmp eax, 0x84		 ; check if it is Reg8,Reg8
	je @Gen_Reg8_Reg8
 
	mov eax, [esi+1]	  ; load second byte in eax
	and eax, 0xFF
	cmp eax, 0xC0		 ; check if it is PtrReg,Reg
	jb @Gen_PtrReg_Reg	 ; else jmp to reg, reg
	jmp @Gen_Reg_Reg


@Gen_Reg8_PtrReg8:
	mov eax, 0x80
	add [edi], eax
	jmp @Gen_Reg_PtrReg
 
 
@Gen_PtrReg8_Reg8:
	mov eax, 0x80
	add [edi], eax
	jmp @Gen_PtrReg_Reg



@Gen_Inverse_RegReg:
	cmp eax, 0xC0
	jb @Ret_Reg_PtrReg

	mov eax, 0x1
	add [edi], eax
	mov eax, [esi+1]
	and eax, 0xFF
	and eax, 0x38
	shr eax, 3
	mov [edi+1], eax
	mov eax, [esi+1]
	and eax, 0xFF
	and eax, 7
	mov [edi+5], eax
	jmp @@NextInstr




@Gen_Reg_PtrReg:
	mov eax, [esi+1]
	cmp eax, 0xFF
	jbe @Gen_Inverse_RegReg

@Ret_Reg_PtrReg:
	mov eax, 0x5
	add [edi], eax		   ; +05 for Reg,[Reg]
	mov eax, [esi+2]
	and eax, 0xFF
	cmp eax, 0x24
	je PtrReg_ESP_src

	mov eax, [esp]
	cmp eax, 2
	jbe @NotOffset1 	    ; else, fall through and do (mov reg, [reg2+offset])

	mov eax, [esi+1]
	and eax, 0xFF
	cmp eax, 0x3D
	jbe @@Gen_Reg_Mem	    ; check if it contains mem

	mov eax, [esi+1]
	and eax, 0xFF
	mov edx, eax
	and eax, 7
	mov [edi+5], eax	   ; store first reg
	mov eax, edx
	and eax, 0x38
	shr eax, 3
	mov [edi+1], eax	   ; store second reg
	mov eax, [esp]
	cmp eax, 0x6
	je @@Big_Offset1	    ; check if offset is 4 bit

	mov eax, [esi+2]
	and eax, 0xFF
	mov [edi+10], eax	   ; store offset
	jmp @@NextInstr

@@Big_Offset1:
	mov eax, [esi+2]
	mov [edi+10], eax	   ; store 4bit offset
	jmp @@NextInstr


@NotOffset1:
	mov eax, [esp]
	cmp eax, 0x6
	je  @@Gen_Reg_Mem	   ; check if it contains mem

	mov eax, [esi+1]	   ; store disassembled first PtrReg
	and eax, 0xFF
	and eax, 7		   ; by AND first byte, 7
	mov [edi+5], eax	   ; Store it at dst
	mov eax, [esi+1]	   ; same with second reg
	and eax, 0xFF
	shr eax, 3
	mov [edi+1], eax	  ; store second register
	jmp @@NextInstr

PtrReg_ESP_src:
	mov eax, 0x4
	mov [edi+5], eax	  ; PtrReg is ESP
	mov eax, [esi+1]	  ; Store ESP as first reg
	and eax, 0xFF
	shr eax, 3		  ; Bit manipulation
	and eax, 0xF
	and eax, 7
	mov [edi+1], eax	  ; Store second reg
	mov eax, [esp]
	cmp eax, 4		  ; Check if PtrReg have an offset
	jb @@NextInstr
	cmp byte[esp], 7	  ; check if it is a 4 bit offset
	je @@Big_Offset_ESP_src
 
	mov eax, [esi+3]
	and eax, 0xFF
	mov [edi+10], eax
	jmp @@NextInstr
 
@@Big_Offset_ESP_src:
	mov eax, [esi+3]
	mov [edi+10], eax
	jmp @@NextInstr


@Gen_Reg8_Reg8:
	mov eax, [esi+1]
	and eax, 0xFF
	cmp eax, 0xC0
	jb @Gen_PtrReg8_Reg8	     ; check if it is byte[reg],reg8
	mov eax, 0x80
	add [edi], eax


@Gen_Reg_Reg:
	mov eax, 0x1
	add [edi], eax		   ; +01 for Reg,Reg
	mov eax, [esi+1]
	and eax, 0xFF
	and eax, 7		   ; take first reg
	mov [edi+1], eax	   ; and store it at disassembled instr
	mov eax, [esi+1]
	and eax, 0xFF
	and eax, 0x38		   ; take second reg
	shr eax, 3		   ; and store
	mov [edi+5], eax	   ; it at disassembled instr
	jmp @@NextInstr

@Gen_PtrReg_Reg:
	mov eax, 0x6
	add [edi], eax		   ; +06 for [Reg],Reg
	mov eax, [esi+2]
	and eax, 0xFF
	cmp eax, 0x24
	je PtrReg_ESP

	mov eax, [esp]
	cmp eax, 2
	jbe @NotOffset		   ; else, fall through and do (mov [reg+offset], reg2)

	mov eax, [esi+1]
	and eax, 0xFF
	cmp eax, 0x3D
	jbe @@Gen_Mem_Reg	    ; check if it contains mem

	mov eax, [esi+1]
	and eax, 0xFF
	mov edx, eax
	and eax, 7
	mov [edi+1], eax	   ; store first reg
	mov eax, edx
	and eax, 0x38
	shr eax, 3
	mov [edi+5], eax	   ; store second reg
	mov eax, [esp]
	cmp eax, 0x6
	je @@Big_Offset 	    ; check if offset is 4 bit

	mov eax, [esi+2]
	and eax, 0xFF
	mov [edi+10], eax	   ; store offset
	jmp @@NextInstr


@@Big_Offset:
	mov eax, [esi+2]
	mov [edi+10], eax	   ; store 4 bit offset
	jmp @@NextInstr


@NotOffset:

	mov eax, [esp]
	cmp eax, 0x6
	je  @@Gen_Mem_Reg	   ; check if it contains mem

	mov eax, [esi+1]	   ; store disassembled first PtrReg
	and eax, 0xFF
	and eax, 7		   ; by AND first byte, 7
	mov [edi+1], eax	   ; Store it at dst
	mov eax, [esi+1]	   ; same with second reg
	and eax, 0xFF
	shr eax, 3
	mov [edi+5], eax	  ; store second register
	jmp @@NextInstr

PtrReg_ESP:
	mov eax, 0x4
	mov [edi+1], eax	  ; PtrReg is ESP
	mov eax, [esi+1]	  ; Store ESP as first reg
	and eax, 0xFF
	shr eax, 3		  ; Bit manipulation
	and eax, 0xF
	and eax, 7
	mov [edi+5], eax	  ; Store second reg
	mov eax, [esp]
	cmp eax, 4		  ; Check if PtrReg have an offset
	jb @@NextInstr
	cmp byte[esp], 7	  ; check if it is a 4 bit offset
	je @@Big_Offset_ESP
 
	mov eax, [esi+3]
	and eax, 0xFF
	mov [edi+10], eax
	jmp @@NextInstr
 
@@Big_Offset_ESP:
	mov eax, [esi+3]
	mov [edi+10], eax
	jmp @@NextInstr


@@Gen_Reg_Mem:
	mov eax, 0x5
	sub [edi], eax		   ; remove already stored reg,[reg]  (0x5)
	mov eax, 0x2
	add [edi], eax
	mov eax, [esi+1]
	and eax, 0xFF
	sub eax, 5
	shr eax, 3
	mov [edi+1], eax
	mov eax, [esi+2]
	mov [edi+5], eax
	jmp @@NextInstr

@@Gen_Mem_Reg:
	mov eax, 0x6
	sub [edi], eax		   ; remove already stored [reg],reg (0x6)
	mov eax, 0x3
	add [edi], eax
	mov eax, [esi+2]
	mov [edi+1], eax
	mov eax, [esi+1]
	and eax, 0xFF
	sub eax, 5
	shr eax, 3
	mov [edi+5], eax
	jmp @@NextInstr




@@NextInstr:
	mov edx, [ebp+NumberOfInstructions]
	inc edx
	mov [ebp+NumberOfInstructions], edx	       ; increment NumberOfInstr

	mov [edi+14], esi
	add edi, 18
	pop eax

	add esi, eax
	jmp @Parse


;;;; This function is for checking if a label is part of a loop.
;;;; This check is for normal jmps since they are the only ones that make loops.
;;;; If the label is part of a disassembled instruction, it is a loop.
;;;; If the label is not a disassembled instruction it is not a loop and
;;;; esi can change to that address to eliminate jmp instr.

@LoopTrace:	    ; EBX = address to check

	push eax		 ; SAVE REGS
	push ecx
	push edx

;;;; INITIALIZE LOOP

	mov ecx, edi			 ; Load ecx with the last disassembled instruction (NOTE:
	mov eax, ebp			 ; the code is not fully disassembled).
	add eax, _Disassemble_Section	 ; Load eax with address to the first disassembled instr

@@1:
	cmp eax, ecx			 ; check if all the disassembled instructions
	jae @NoLoop			 ; have been parsed, if yes. the label have not been
					 ; disassembled and the jmp is not a loop.
	mov edx, [eax+14]		 ; load edx with address section of instruction.
	cmp edx, ebx			 ; check the address with the label address.
	je @LoopFound			 ; If they match, it is a loop.

	add eax, 18			 ; Get next disassembled instruction
	jmp @@1 			 ; LOOP IT


;;;; IF LOOP HAS BEEN FOUND
@LoopFound:
	mov byte[eax+9], 1		 ; Mark the LM at the instruction. We can do this
					 ; since the instruction has already been disassembled
	pop edx 			 ; RESTORE REGS
	pop ecx
	pop eax

	push ebx			 ; Arg1 = ebx
	call InsertLabel		 ; Insert label in label section
	inc ebx 			 ; increment position in label tabel where it jmps  ( if it is 0 it cant be acessed)

	mov eax, 0xE9
	mov [edi], eax
	mov [edi+10], ebx		 ; Store which label it jmps to as a position in label tabel
	xor ebx, ebx

	jmp CheckFutLabels		  ; Get new EIP from future label list.


;;;; IF LOOP HAS NOT BEEN FOUND
@NoLoop:

	pop edx 			 ; RESTORE REGS
	pop ecx
	pop eax
	add esp, 4	  ; clear stack of old instr length to get new one

	mov eax, 0xFF			 ; Pseudo OP for NOP.
	mov [edi], eax			 ; Insert NOP incase this jmp points to itself.
	mov [edi+14], esi
	add edi, 18

	mov edx, [ebp+NumberOfInstructions]
	inc edx
	mov [ebp+NumberOfInstructions], edx	       ; increment NumberOfInstr

	mov esi, ebx			 ; change esi to the destination address of jmp (label that have
					 ; been checked).
	xor ebx, ebx
	jmp @Parse			 ; Continue disassembly with next instruction (JMP ELIMINATED).



;;;; This function insert labels at label section at next position.
;;;; RETURNS POSITION IN LABEL TABEL WHERE THE LABEL HAVE BEEN ADDED (EBX).
InsertLabel:
labelAddr	equ [ebp+0x8]		 ; arg = label address in code section.
	push ebp
	mov ebp, esp			 ; ENTER

	xor ebx, ebx			 ; zero ebx (position counter)
	push eax			 ; SAVE REGS
	push ecx
	push edx

;;;; INITIALIZE LOOP

	mov eax, [AddressToFree]	 ; Load eax with address of first label in label section
	add eax, _Label_Section
	mov ecx, [AddressToFree]
	add ecx, NumberOfLabels
	mov ecx, [ecx]			 ; Load ecx with number of labels
	test ecx, ecx			 ; if there are none
	jz Add_Label			 ; insert label immediately.

LoopLabels:
	mov edx, [eax]			 ; Load edx with label.
	cmp edx, labelAddr		 ; Compare label with label to be inserted.
	je Label_Exists 		 ; If they match, that means it already exists, so exit.

	add eax, 4			 ; Get address of next label in label section
	inc ebx 			 ; Increment position counter.
	dec ecx 			 ; decrement number of labels
	test ecx, ecx			 ; if there are none left
	jz Add_Label			 ; insert label at the address eax is at.
	jmp LoopLabels			 ; else loop it.

Add_Label:
	mov edx, labelAddr
	mov [eax], edx			 ; Insert label
	mov eax, [AddressToFree]
	add eax, NumberOfLabels
	mov edx, [eax]
	add edx, 1
	mov [eax], edx			 ; increment number of labels

Label_Exists:
	pop edx 			 ; RESTORE REGS
	pop ecx
	pop eax

	mov esp, ebp			 ; LEAVE
	pop ebp
	ret 4				 ; remove arg from stack



;;;; Inserts label in future label tabel.
InsertFutureLabel:
LabelAddress	equ [ebp+0x8]

	push ebp
	mov ebp, esp			 ; ENTER

	xor ebx, ebx			 ; zero ebx (position counter)
	push eax			 ; SAVE REGS
	push ecx
	push edx

;;;; INITIALIZE LOOP

	mov eax, [AddressToFree]	 ; Load eax with address of first label in label section
	add eax, _Future_Label_Section
	mov ecx, [AddressToFree]
	add ecx, NumberOfFutureLabels
	mov ecx, [ecx]			 ; Load ecx with number of labels
	test ecx, ecx			 ; if there are none
	jz Add_Future_Label			; insert label immediately.

LoopFutureLabels:
	mov edx, [eax]			 ; Load edx with label.
	cmp edx, labelAddr		 ; Compare label with label to be inserted.
	je Future_Label_Exists			; If they match, that means it already exists, so exit.

	add eax, 4			 ; Get address of next label in label section
	inc ebx 			 ; Increment position counter.
	dec ecx 			 ; decrement number of labels
	test ecx, ecx			 ; if there are none left
	jz Add_Future_Label			; insert label at the address eax is at.
	jmp LoopFutureLabels		       ; else loop it.

Add_Future_Label:
	mov edx, LabelAddress
	mov [eax], edx			 ; Insert label
	mov eax, [AddressToFree]
	add eax, NumberOfFutureLabels
	mov edx, [eax]			 ; Get number of future labels in edx.
	add edx, 1			 ; Increment number of labels.
	mov [eax], edx			 ; Save number of labels

Future_Label_Exists:
	pop edx 			 ; RESTORE REGS
	pop ecx
	pop eax

	mov esp, ebp			 ; LEAVE
	pop ebp
	ret 4				 ; remove arg from stack



;;;; This function checks if an address in _Code_Section already has been
;;;; disassembled.
;;;; It returns 1 in EAX if it has been disassembled.
;;;; It returns 0 in EAX if it has not been disassembled.
CheckIfAddressIsDisassembled:
AddressToCheck		equ [ebp+0x8]
	push ebp
	mov ebp, esp			 ; ENTER

	push eax
	push ecx
	push edx			 ; SAVE REGS

	mov ecx, edi			 ; Load ecx with the last disassembled instruction (NOTE:
	mov eax, [AddressToFree]	 ; the code is not fully disassembled).
	add eax, _Disassemble_Section	 ; Load eax with address to the first disassembled instr

_@@1:
	cmp eax, ecx			 ; check if all the disassembled instructions
	jae _@NotDisassembled		 ; have been parsed, if yes. the label have not been
					 ; disassembled and the jmp is not a loop.
	mov edx, [eax+14]		 ; load edx with address section of instruction.
	cmp edx, AddressToCheck 	 ; check the address with the label address.
	je _@Disassembled		 ; If they match, it is a loop.

	add eax, 18			 ; Get next disassembled instruction
	jmp _@@1			 ; LOOP IT


_@NotDisassembled:
	pop edx
	pop ecx
	pop eax 			 ; RESTORE REGS
	mov eax, 0			 ; Return value in EAX.
	jmp @RetLoopDisCheck

_@Disassembled:
	pop edx
	pop ecx
	pop eax 			 ; RESTORE REGS
	mov eax, 1			 ; Return value in EAX.


@RetLoopDisCheck:
	mov esp, ebp
	pop ebp 			 ; LEAVE
	ret 4				 ; Remove argument from stack.



;;;; Checks if there are any future labels to be disassembled.
;;;; If there are none, EAX = 0.
;;;; If there are, EAX = address of label in index 0.
CheckFutureLabelTabel:

	push ecx
	push edx			 ; SAVE REGS.

	mov ecx, [ebp+NumberOfFutureLabels]	    ; Load ecx with number of future labels.
	test ecx, ecx			 ; If NumberOfFutureLabels is zero,
	jz @No_Future_Labels		 ; jump.


	mov edx, [AddressToFree]
	add edx, _Future_Label_Section
	dec ecx
	shl ecx, 2
	add edx, ecx
	mov eax, [edx]			 ; Else, load eax with label at index zero.
	jmp @RetFutureLabelCheck



@No_Future_Labels:
	xor eax, eax			   ; Set return value.

@RetFutureLabelCheck:
	pop edx
	pop ecx 			 ; RESTORE REGS.
	ret				 ; RET.




;***************************************************************************************************
;			  END_OF_DISASSEMBLER
;
;
;***************************************************************************************************



Shrinker:
	mov	edi, [AddressToFree]
	add	edi, _Disassemble_Section



@Shrink:
	mov	eax, [edi]		    ; load eax with first instruction
	and	eax, 0xFF		    ;
	cmp	eax, 0xFF		    ; if nop
	je	@@IncEIP		    ; increment EDI (EIP)
	call	ShrinkInstr		    ; else shrink the instruction
	test	eax, eax		    ; if instruction was not shrinked
	jz	@@IncEIP		    ; increment EIP
	call	DecEIP			    ; else decrement eip three times
	call	DecEIP			    ; for rechecking every shrink
	call	DecEIP			    ; even for three instr shrinking.
	jmp	@Shrink 		    ; LOOP SHRINKER


@@IncEIP:
	call	IncEIP				  ; increment EIP
	cmp	edi, [ebp+AddressOfLastInstruction]  ; if eip is at that address
	jne	@Shrink 			  ; if not. Continue shrinking.
					       ; else continue code.

;;;; Remove all NOPs in the end of the disassembly buffer.
RemoveNOPAtLast:
	sub	edi, 18
	mov	eax, [edi]
	and	eax, 0xFF
	cmp	eax, 0xFF
	jne	NoMoreNOPS
	mov	[ebp+AddressOfLastInstruction], edi
	jmp	RemoveNOPAtLast

NoMoreNOPS:
	ret




IncEIP:
	push	eax				  ; save eax
@Inc_Again:
	cmp	edi, [ebp+AddressOfLastInstruction]  ; if eip is at that address
	je	@@End_IncEIP			  ; dont increase EIP
	add	edi, 18 			  ; else increase EIP
	mov	eax, [edi+9]			  ; else get LM.
	or	eax, eax			  ; is LM 1?
	jnz	@@End_IncEIP			  ; if yes, end.
	mov	eax, [edi]
	and	eax, 0xFF
	cmp	eax, 0xFF			  ; is incremented instr NOP?
	je	@Inc_Again			  ; if yes, inc again.

@@End_IncEIP:
	pop	eax
	ret




DecEIP:
	push	eax
@Dec_Again:
	mov	eax, [AddressToFree]
	add	eax, _Disassemble_Section
	cmp	edi, eax
	jz	@@End_IncEIP
	mov	eax, [edi+9]
	or	eax, eax
	jnz	@@End_DecEIP
	sub	edi, 18
	mov	eax, [edi]
	and	eax, 0xFF
	cmp	eax, 0xFF
	je	@Dec_Again

@@End_DecEIP:
	pop	eax
	ret





ShrinkInstr:
	push	edi		       ; save EIP
	mov	byte[ebp+Shrink8bit1], 0x0
	mov	eax, [edi]
	and	eax, 0xFF
	cmp	eax, 0x80
	jb	@Single_No8bit

	cmp	eax, 0xCF
	ja	@Single_No8bit
	mov	byte[ebp+Shrink8bit1], 0x80
	sub	eax, 0x80

@Single_No8bit:
	mov	ecx, 0xFF
	cmp	eax, 0x41
	jne	@Single_Next00
	mov	edx, [edi+1]
	cmp	edx, [edi+5]
	je	@Set_Single_InstrECX
	jmp	@@EndNoCompressed

@Single_Next00:
	cmp	eax, 0x28
	jne	@Single_Next01

@Single_Swap_Sub:
	mov	edx, [edi+5]
	neg	edx
	mov	[edi+5], edx
	mov	eax, [edi]
	sub	eax, 0x28
	jmp	@Set_Single_Instr

@Single_Next01:
	cmp	eax, 0x2C
	je	@Single_Swap_Sub

	cmp	eax, 0x0
	jne	@Single_Next02

@Single_NullOP_NOP:
	mov	edx, [edi+5]
	cmp	edx, 0x80
	jb	@Single_NotSigned
	add	eax, 0FFFFFF00h

@Single_NotSigned:
	mov	eax, [edi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit1]
	cmp	eax, 0x0		  ; Check if instruction is ADD.
	je	Single_DontCHECKAdd	  ; We dont want to NOP a ADD Reg,-1.
	cmp	edx, -1
	je	@Set_Single_InstrECX
Single_DontCHECKAdd:
	test	edx, edx
	jnz	@@EndNoCompressed
	jmp	@Set_Single_InstrECX

@Single_Next02:
	mov	ecx, 0xFF
	cmp	eax, 0x4
	je	@Single_NullOP_NOP
	cmp	eax, 0x8
	je	@Single_NullOP_NOP
	cmp	eax, 0xC
	je	@Single_NullOP_NOP

	cmp	eax, 0x20
	jne	@Single_Next03
@Single_AndNOPPED:
	mov	ecx, [edi]
	and	ecx, 0xFF
	add	ecx, 0x20
	mov	edx, [edi+5]
	test	edx, edx
	jz	@Single_NullOP_NOP
	mov	ecx, 0xFF
	jmp	@Single_NullOP_NOP

@Single_Next03:
	cmp	eax, 0x24
	je	@Single_AndNOPPED

@Single_Next04:
	mov	ecx, [edi]
	and	ecx, 0xFF
	add	ecx, 0x10

	cmp	eax, 0x31
	jne	@Single_Next05

@SingleCheckEqualOPs:
	mov	eax, [edi+1]
	cmp	eax, [edi+5]
	jne	@@EndNoCompressed
	mov	byte[edi+5], 0x0
	sub	ecx, 1				; Set Mov Reg,Imm from Mov Reg,Reg
	jmp	@Set_Single_InstrECX

@Single_Next05:
	cmp	eax, 0x29
	jne	@Single_Next06
	add	ecx, 0x8			; Add only 8 because of the last check for XOR.
	jmp	@SingleCheckEqualOPs

@Single_Next06:
	mov	ecx, [edi]
	and	ecx, 0xFF
	add	ecx, 0x30

	cmp	eax, 0x9
	je	@SingleCheckEqualOPs
	sub	ecx, 0x18
	cmp	eax, 0x21
	je	@SingleCheckEqualOPs
	sub	ecx, 0x28
	cmp	eax, 0x49
	je	@SingleCheckEqualOPs

@Single_End:



;********************************COMPRESSION OF PAIRS***************************************

	mov	esi, edi
	call	IncEIP
	cmp	edi, [ebp+AddressOfLastInstruction]    ; Check if edi is at last instr.
	je	@@EndNoCompressed	       ; Dont compress if it is.
	mov	eax, [edi+9]		       ; Get label
	and	eax, 0xFF
	test	eax, eax
	jnz	@@EndNoCompressed	       ; Dont compress instructions with label mark.

	; ESI is first instruction, EDI is second instruction.

Double_00:
	mov	byte[ebp+Shrink8bit2], 0x0
	mov	eax, [esi]
	and	eax, 0xFF
	cmp	eax, 0x80
	jb	Double_No8bit1
	cmp	eax, 0xCF
	ja	Double_No8bit1
	mov	byte[ebp+Shrink8bit2], 0x80



Double_No8bit1:
	mov	eax, [ebp+Shrink8bit1]
	cmp	eax, [ebp+Shrink8bit2]
	jne	@@EndNoCompressed	     ; Are they the same sizes?

	mov	eax, [esi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit1]
	cmp	eax, 0x68
	jne	Double_01

	mov	eax, [edi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit2]
	mov	edx, eax		; Just to let EAX hold the instr.
	xor	eax, eax
	cmp	edx, 0x58	      ; PUSH Imm/POP Reg
	je	Double_PutMOV
	cmp	edx, 0x59	      ; PUSH Imm/POP Mem
	jne	@@EndNoCompressed

;;;; Does not have [Reg], Imm in disasm or asm.
;	 cmp	 eax, 0x5A
;	 jne	 Double_01
;Double_PutMOVPtrRegImm:
;	 mov	 eax, [esi+1]		  ; Get imm from Push Imm.
;	 mov	 [esi+5], eax		  ; Set Imm in Src position.
;	 mov	 eax, [edi+1]		  ; Get PtrReg from Pop PtrReg.
;	 mov	 [esi+1], eax		  ; Set PtrReg in Dst position.
;	 mov	 eax,
Double_PutMOVMemImm:
	mov	eax, 0x4	     ; 0x4 + 0x40 = 0x44 (MOV Mem,Imm)

Double_PutMOV:
	mov	edx, [esi+1]
	mov	[esi+5], edx
	mov	edx, [edi+1]
	mov	[esi+1], edx
	add	eax, 0x40
Double_SetInstruction:
	mov	[esi], al
Double_SetNOP:
	mov	eax, 0xFF
	mov	byte[edi], al
	jmp	@@EndCompressed

Double_01:
	cmp	eax, 0x50
	jne	Double_02
	mov	eax, [edi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit2]
	cmp	eax, 0x58	       ; PUSH Reg/POP Reg
	je	Double_PushPop
	cmp	eax, 0x59	       ; PUSH Reg/POP Mem
	je	Double_PushPopMEM
	cmp	eax, 0x5A	       ; PUSH Reg/ POP PtrReg
	jne	Double_END

Double_PushPopPTRREG:
	mov	eax, 6		       ; 0x6 + 0x40 = 0x46 (MOV PtrReg, Reg)
	jmp	Double_PutMOV

Double_PushPopMEM:
	mov	eax, 3		       ; 0x3 + 0x40 = 0x43 (MOV Mem, Reg)
	jmp	Double_PutMOV

Double_PushPop:
	mov	eax, 1		       ; 0x1 + 0x40 = 0x41 (MOV Reg, Reg)
	jmp	Double_PutMOV

Double_02:
	cmp	eax, 0x51	       ; PUSH Mem?
	jne	Double_03
	mov	eax, [edi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit2]
	cmp	eax, 0x58	       ; PUSH Mem/POP Reg
	jne	Double_END

Double_PushMemPopReg:
	mov	eax, 3		       ;0x3 + 0x40 = 0x43 ( MOV Reg,Mem )
	jmp	Double_PutMOV

Double_03:
	call	CheckMemOperands
	test	eax, eax	       ; Are the Mem Operands the same?
	jz	Double_04	       ; No? Jump.
	mov	eax, [esi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit1] ; Remove 8bit indicator (0x80) or 0 if 32bit operands
	cmp	eax, 0xF6	       ; APICALL_STORE?
	je	Double_NextMem_00      ; Go to Mem,Reg , because they are the same.

	cmp	eax, 0x43	       ; MOV Mem,Reg?
	jne	Double_04
Double_NextMem_00:
	mov	eax, [edi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit2]	; Remove 8bit indicator.
	cmp	eax, 0x4C		; OP Mem,Imm
	jbe	Double_Mem_OPRegReg
	cmp	eax, 0x51		; PUSH Mem
	jne	Double_END

;; MOV Mem,Reg/PUSH Mem -> PUSH Reg
Double_Mem_PushReg:
	mov	eax, [esi+5]
	mov	[esi+1], eax
	mov	eax, 0x50		; PUSH Reg
	jmp	Double_SetInstruction

;; MOV Mem,Reg/OP Reg2,Mem -> OP Reg2,Reg
Double_Mem_OPRegReg:
	cmp	eax, 0x3B
	je	Double_Mem_MergeCheck	; CMP Mem,Reg. Yes? Merge
	cmp	eax, 0x4B
	je	Double_Mem_MergeCheck	; TEST Mem,Reg. Yes? Merge
	cmp	eax, 0x4A
	je	Double_Mem_MergeCheck	; TEST Reg,Mem
	and	eax, 7	       ; Get Operands.
	cmp	eax, 2	       ; Check for OP Reg,Mem
	jne	Double_END	; If not. Finish.
	mov	eax, [esi+5]	    ; Merge the two instructions:
	mov	[esi+5], eax	    ; MOV Mem,Reg + OP Reg,Mem = OP Reg,Reg
	mov	eax, [edi+1]
	mov	[esi+1], eax

Double_Mem_SetOP:
	mov	eax, [edi]		; Get operands
	and	eax, 0xF8		; Transform to OP Reg,Reg
	add	eax, 1
	jmp	Double_SetInstruction

Double_Mem_MergeCheck:
	mov	eax, [esi+5]
	mov	[esi+1], eax
	mov	eax, [edi+5]
	mov	[esi+5], eax		 ; Merge Check
	jmp	Double_Mem_SetOP


Double_04:
	mov	eax, [esi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit1]
	cmp	eax, 0x44		    ; Is first instr MOV Mem,Imm?
	jne	Double_05
	mov	eax, [edi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit1]
	cmp	eax, 0x51		    ; PUSH Mem?
	je	Double_Set_PushImm
	cmp	eax, 0x4F		; OP?
	ja	Double_05
	and	eax, 7			; Get Operands
	cmp	eax, 2			; OP Reg,Mem?
	jne	Double_05

;; MOV Mem,Imm/OP Reg,Mem -> OP Reg,Imm
Double_MergeMovMemOP:
	mov	eax, [edi+1]		; Get Reg
	mov	[esi+1], eax		; Set Reg in first instr. Imm is already set.
	mov	eax, [edi]
	and	eax, 0xF8
	jmp	Double_SetInstruction

;; MOV Mem,Imm/PUSH Mem -> PUSH Imm
Double_Set_PushImm:
	mov	eax, [esi+5]		; Get Imm
	mov	[esi+1], eax		; Set Imm for PUSH Imm.
	mov	eax, 0x68
	jmp	Double_SetInstruction

Double_05:
	mov	eax, [esi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit1]
	cmp	eax, 0x59		; POP Mem?
	jne	Double_06
	mov	eax, [edi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit1]
	cmp	eax, 0x42		; POP Mem + MOV Reg,Mem
	je	Double_05_PopReg
	cmp	eax, 0x51		; POP Mem + PUSH Mem
	je	Double_SetDoubleNOP
	cmp	eax, 0xEB		; POP Mem + JMP Mem
	jne	Double_06

;; POP Mem/JMP Mem -> RET
Double_05_RET:
	mov	eax, 0xFE		; POP Mem + JMP Mem = RET
	jmp	Double_SetInstruction

;; POP Mem/MOV Reg,Mem -> POP Reg
Double_05_PopReg:
	mov	eax, [edi+1]
	mov	[esi+1], eax
	mov	eax, 0x58		; POP Reg
	jmp	Double_SetInstruction

;; POP Mem/PUSH Mem -> NOP
Double_SetDoubleNOP:
	mov	eax, 0xFF		; NOP
	jmp	Double_SetInstruction

Double_06:
	mov	eax, [esi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit1]
	cmp	eax, 0x4F		; Generic OP?
	ja	Double_07
	mov	eax, [edi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit1]
	cmp	eax, 0x4F		; Second Instr is Generic OP?
	ja	Double_07
	mov	eax, [esi]
	and	eax, 7
	cmp	eax, 4			; OP Mem,Imm + Generic OP?
	je	Double_06_OPMemImm
	test	eax, eax		; OP Reg,Imm + Generic OP?
	jnz	Double_07

Double_06_OPRegImm:
	mov	eax, [edi]
	and	eax, 7
	test	eax, eax		; OP Reg,Imm + OP Reg,Imm
	jnz	Double_07
	mov	eax, [esi+1]
	cmp	eax, [edi+1]		; Are the Regs the same?
	jne	Double_07
	xor	ebx, ebx

Double_CalculateOperation:
	push	ebx
	mov	ecx, [esi+5]
	mov	edx, [edi+5]
Double_CalculateOperation_01:
	mov	eax, [edi]
	and	eax, 0x78
	mov	ebx, eax
	mov	eax, [esi]
	and	eax, 0x78
	call	CalculateOperation
	pop	ebx
	cmp	eax, 0xFE
	je	Double_END
	cmp	eax, 0xFF
	je	Double_SetNOP1st
	mov	[esi+5], ecx
	add	eax, ebx
	add	eax, [ebp+Shrink8bit1]
	jmp	Double_SetInstruction

Double_SetNOP1st:
	mov	eax, 0xFF
	mov	[esi], eax
	jmp	@@EndCompressed

Double_06_OPMemImm:
	mov	eax, [edi]
	and	eax, 7
	cmp	eax, 4			; OP Mem,Imm + OP Mem,Imm?
	jne	Double_07
	mov	eax, [esi+1]
	cmp	eax, [edi+1]
	jne	Double_07
	mov	ebx, 4
	jmp	Double_CalculateOperation

Double_07:
	mov	eax, [esi]
	and	eax, 0xFF
	cmp	eax, 0x70	; Jcc?
	jb	Double_08
	cmp	eax, 0x7F
	ja	Double_08
	mov	eax, [edi]
	and	eax, 0xFF
	cmp	eax, 0xE9	; Jcc + Jmp?
	je	Double_END
	cmp	eax, 0x70	; Jcc + Jcc?
	jb	Double_08
	cmp	eax, 0x7F
	ja	Double_08
	mov	eax, [esi+10]
	and	eax, 0xFF
	mov	ebx, [edi+10]
	and	ebx, 0xFF
	cmp	eax, ebx
	jne	Double_08
	mov	eax, [esi]
	and	eax, 0xF
	mov	ebx, eax
	mov	eax, [edi]
	and	eax, 0xF
	call	GetRealCheck
	cmp	eax, 0xFF
	je	Double_END
	add	eax, 0x70
	jmp	Double_SetInstruction

Double_07_JMP:



Double_08:
	mov	eax, [esi]
	and	eax, 0xFF
	cmp	eax, -10;0xEA	      ; Call Mem?
	jne	Double_09

Double_08_CheckAPICallStore:
	mov	eax, [edi]
	and	eax, 0xFF
	cmp	eax, 0x43	  ; Mem,Reg?
	jne	Double_END
	mov	eax, [edi+5]
	test	eax, eax	  ; Is Reg EAX?
	jne	Double_END
	mov	eax, 0xF6	  ; APICALL_STORE
	mov	byte[edi], al
	xor	eax, eax
	mov	[edi], eax	  ; Set 0 to Reg for treating this as special opcode.
	jmp	@@EndCompressed

Double_09:
	cmp	eax, 0xEC
	je	Double_08_CheckAPICallStore

Double_10:


Double_END:


Check_Triple:
	mov	edx, esi
	mov	esi, edi
	call	IncEIP
	cmp	edi, [ebp+AddressOfLastInstruction]
	je	@@EndNoCompressed
	xor	eax, eax
	mov	eax, [edi+9]
	and	eax, 0xFF
	test	eax, eax
	jnz	@@EndNoCompressed
       ; Check triplets EDX, ESI, EDI

Triple_00:
	mov	byte[ebp+Shrink8bit3], 0x0
	mov	eax, [edi]
	and	eax, 0xFF
	cmp	eax, 0x70		; Include Jcc's
	jae	Triple_JCC
	cmp	eax, 0x7F
	jbe	Triple_JCC
	cmp	eax, 0x80
	jb	Triple_No8Bit
	cmp	eax, 0xCF
	ja	Triple_No8Bit
	mov	byte[ebp+Shrink8bit3], 0x80

Triple_No8Bit:
	mov	eax, [ebp+Shrink8bit2]
	cmp	eax, [ebp+Shrink8bit3]
	jne	@@EndNoCompressed

Triple_JCC:
	mov	eax, [edx]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit1]
	cmp	eax, 0x43		; MOV Mem,Reg?
	jne	Triple_01
	push	edi
	mov	edi, edx
	call	CheckMemOperands	; Compare ESI and EDX
	pop	edi
	test	eax, eax
	jz	Triple_01
	mov	eax, [edi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit3]
	cmp	eax, 0x42		; 3rd instruction == MOV Reg,Mem?
	je	Triple_00_Constr00
	add	eax, [ebp+Shrink8bit3]	; Add 8bit indicator for detecting Jcc's
	cmp	eax, 0x70		; 3rd instruction == Jcc?
	jb	Triple_01
	cmp	eax, 0x7F
	ja	Triple_01
	mov	eax, [esi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit2]
	and	eax, 0xF8
	test	eax, eax
	je	Triple_00_Maybe01
	cmp	eax, 0x20	    ; AND?
	je	Triple_00_Maybe01
	cmp	eax, 0x28	    ; SUB?
	je	Triple_00_Maybe01
	cmp	eax, 0x38	    ; CMP?
	je	Triple_00_Maybe01
	cmp	eax, 0x48	    ; TEST?
	jne	Triple_END
Triple_00_Maybe01:
	xor	ebx, ebx

	mov	eax, [esi]
	and	eax, 0x7F
	cmp	eax, 0x48
	jbe	Triple_00_CheckCMPTEST00
	and	eax, 7
	cmp	eax, 2			; OP Reg,Mem?
	je	Triple_00_CMPTESTRegReg
	jmp	Triple_00_CheckCMPTEST01

Triple_00_CheckCMPTEST00:
	and	eax, 7
	cmp	eax, 3			; OP Mem,Reg?
	je	Triple_00_CMPTESTRegReg

Triple_00_CheckCMPTEST01:
	cmp	eax, 4			; OP Mem,Imm?
	jne	Triple_END

Triple_00_CMPTESTRegImm:
	mov	eax, [edx+5]
	and	eax, 0xFF
	mov	[esi+1], eax

Triple_00_Set_CMPTEST:
	mov	eax, [esi]
	and	eax, 0x78
	cmp	eax, 0x48
	je	Triple_00_SetInstruction
	cmp	eax, 0x20
	je	Triple_00_Cont80
	cmp	eax, 0x38
	je	Triple_00_SetInstruction
	test	eax, eax
	je	Triple_00_NegateImm
Triple_00_SetCMP:
	mov	eax, 0x38
	jmp	Triple_00_SetInstruction

Triple_00_NegateImm:
	mov	eax, [esi+5]
	neg	eax
	mov	[esi+5], eax
	jmp	Triple_00_SetCMP

Triple_00_Cont80:
	mov	eax, 0x48
Triple_00_SetInstruction:
	add	eax, ebx
	add	eax, [ebp+Shrink8bit2]
	mov	[esi], al
	mov	eax, 0xFF
	mov	[edx], al
	jmp	@@EndCompressed

Triple_00_CMPTESTRegReg:
	mov	eax, [esi]
	and	eax, 0x78
	test	eax, eax
	jz	Triple_END
	mov	eax, [esi+5]
	mov	[esi+5], al
	mov	eax, [edx+5]
	mov	[esi+1], al
	add	ebx, 1
	jmp	Triple_00_Set_CMPTEST

Triple_00_Constr00:
	mov	eax, [esi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit2]
	cmp	eax, 0x4F		; Common OP?
	ja	Triple_01
	xor	ebx, ebx

Triple_00_Common:
	mov	eax, [esi]
	and	eax, 0x78
	cmp	eax, 0x48	     ; If its not TEST, jmp
	jb	Triple_00_Common00
	mov	eax, [esi]
	and	eax, 0xFF
	and	eax, 7
	cmp	eax, 2		     ; TEST Reg,Mem?
	je	Triple_00_Maybe00
	jmp	Triple_00_Common01
Triple_00_Common00:
	mov	eax, [esi]
	and	eax, 0xFF
	and	eax, 7
	cmp	eax, 3		     ; OP Mem,Reg?
	je	Triple_00_Maybe00

Triple_00_Common01:
	cmp	eax, 4			; OP Mem,Imm?
	jne	Triple_END
Triple_00_Maybe00:
	push	edi
	mov	edi, edx
	call	CheckMemOperands	; Check <[ESI], [EDX]> for same Mem operands.
	pop	edi
	test	eax, eax
	jz	Triple_END
	call	CheckMemOperands	; Check <[ESI], [EDI]> for same Mem operands.
	test	eax, eax
	jz	Triple_END
	mov	eax, [edx+5]
	cmp	eax, [edi+1]		; Check <[EDX], [EDI]> for same Reg or Imm operands.
	jne	Triple_END
	mov	eax, [esi]
	and	eax, 0x78
	cmp	eax, 0x48		; TEST?
	jb	Triple_00_00
	mov	eax, [esi]
	and	eax, 0xFF
	and	eax, 7
	cmp	eax, 2			; TEST Reg,Mem?
	je	Triple_00_MaybeOPRegReg
	jmp	Triple_00_01

Triple_00_00:
	mov	eax, [esi]
	and	eax, 7
	cmp	eax, 3			; OP Mem,Reg?
	je	Triple_00_MaybeOPRegReg
Triple_00_01:
	mov	eax, [edx+5]
	mov	[edx+1], eax
	mov	eax, [esi+5]
	mov	[edx+5], eax
	mov	eax, [esi]
	and	eax, 0x78
	add	eax, ebx
Triple_SetInstruction:
	add	eax, [ebp+Shrink8bit3]
	mov	[edx], al
Triple_SetNOP:
	mov	eax, 0xFF
	mov	[esi], al
	mov	[edi], al	       ; Eliminate 2nd and 3rd instruction.
	jmp	@@EndCompressed
Triple_00_MaybeOPRegReg:
	mov	eax, [esi+5]
	mov	[edx+5], eax
	mov	eax, [edi+1]
	mov	[edx+1], eax
	mov	eax, [esi]
	and	eax, 0xF8
	sub	eax, [ebp+Shrink8bit3]
	add	eax, 1
	jmp	Triple_SetInstruction

Triple_01:
	mov	eax, [edx]
	sub	al, [ebp+Shrink8bit3]
	cmp	al, 0x44		; 1st instruction is MOV Mem,Imm?
	jne	Triple_02
	mov	eax, [edi]
	sub	al, [ebp+Shrink8bit3]
	cmp	al, 0x42		; 3rd instruction is MOV Reg,Mem
	je	Triple_01_Constr00
	cmp	al, 0x70		; 3rd instruction is Jcc?
	jb	Triple_02
	cmp	al, 0x7F
	ja	Triple_02
	mov	eax, [esi]
Triple_01_Check_CMPTEST:
	cmp	al, 0x3A		; CMP Reg,Mem?
	je	Triple_01_CMPRegImm
	cmp	al, 0x4A		; TEST Reg,Mem?
	jne	Triple_END

Triple_01_CMPRegImm:
Triple_01_TESTRegImm:
	mov	eax, [esi]
	and	eax, 0xF8
	mov	[edx], al
	mov	eax, [esi+5]
	mov	[edx+1], al
	mov	eax, 0xFF
	mov	[esi], al
	jmp	@@EndCompressed

Triple_01_Constr00:
	mov	eax, [esi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit2]
	cmp	eax, 0xF6
	je	Triple_01_Common_F6
	cmp	eax, 0x4F
	ja	Triple_02
Triple_01_Common:
	and	eax, 0x78
	cmp	eax, 0x48
	jb	Triple_01_00
	mov	eax, [esi]
	and	eax, 7
	cmp	eax, 2
	je	Triple_01_Common_F6
	jmp	Triple_END
Triple_01_00:
	mov	eax, [esi]
	and	eax, 7
	cmp	eax, 3
	jne	Triple_END
Triple_01_Common_F6:
	push	edi
	mov	edi, edx
	call	CheckMemOperands
	pop	edi
	test	eax, eax
	jz	Triple_END
	call	CheckMemOperands
	test	eax, eax
	jz	Triple_END
	mov	eax, [esi+5]
	cmp	eax, [edi+1]
	jne	Triple_END
	mov	eax, [esi+5]
	mov	[edx+1], eax
	mov	eax, [esi]
	and	eax, 0xF8
	jmp	Triple_SetInstruction

Triple_02:
	mov	eax, [edx]
	and	eax, 0xFF
	cmp	eax, 0x50		 ; PUSH Reg?
	je	Triple_APICALL_BEGIN_00
	cmp	eax, 0x58		 ; POP Reg?
	jne	Triple_03

Triple_APICALL_END_00:
	mov	eax, [edx+1]
	cmp	eax, 2			 ; POP EDX?
	jne	Triple_03
	mov	eax, [esi]
	and	eax, 0xFF
	cmp	eax, 0x58
	jne	Triple_03
	mov	eax, [esi+1]
	cmp	eax, 1			 ; POP ECX?
	jne	Triple_03
	mov	eax, [edi]
	and	eax, 0xFF
	cmp	eax, 0x58
	jne	Triple_03
	mov	eax, [edi+1]
	cmp	eax, 0			 ; POP EAX
	jne	Triple_03
	mov	eax, 0xF5		 ; F5: APICALL_END
	mov	[edx], al
	mov	eax, 0xFF
	mov	[esi], al
	mov	[edi], al		 ; 2nd and 3rd are NOPPED
	jmp	@@EndCompressed

Triple_APICALL_BEGIN_00:
	mov	eax, [edx+1]
	cmp	eax, 0			 ; PUSH EAX
	jne	Triple_03
	mov	eax, [esi]
	and	eax, 0xFF
	cmp	eax, 0x50
	jne	Triple_03
	mov	eax, [esi+1]
	cmp	eax, 1			 ; PUSH ECX
	jne	Triple_03
	mov	eax, [edi]
	and	eax, 0xFF
	cmp	eax, 0x50
	jne	Triple_03
	mov	eax, [edi+1]
	cmp	eax, 2			 ; PUSH EDX
	jne	Triple_03
	mov	eax, 0xF4		 ; F4: APICALL_BEGIN
	mov	[edx], al
	mov	eax, 0xFF
	mov	[esi], al
	mov	[edi], al		 ; 2nd and 3rd are NOPPED
	jmp	@@EndCompressed





Triple_03:




Triple_END:

	jmp	@@EndNoCompressed


@Set_Single_InstrECX:
	mov	eax, ecx
	jmp	@Set_Single_Instr
@Set_Single_NOP:
	mov	eax, 0xFF
@Set_Single_Instr:
	mov	byte[edi], al
	jmp	@@EndCompressed


@@EndCompressed:
	mov	eax, 1
	pop	edi
	ret

@@EndNoCompressed:
	xor	eax, eax
	pop	edi
	ret




;; This function merges two flag checks (like JNZ/JA, for example) to get a
;; direct check to use in a conditional jump.
;; In:
;;  EAX = Flag to check 1
;;  EBX = Flag to check 2
;; Out:
;;  EAX = Direct flag (+70h = 7xh, opcode of Jcc)
;;	= 79h if unconditional jump is performed (+70h = E9h, opcode of JMP)
;;	= 0FFh if no direct flag can be used
;; This function only tests the flags that are coded by this engine (not all
;; the possible types).
;;
;; Checks can be merged as:
;;
;; X(even) + X+1 = JMP(unconditional)
;; NB(3) + E(4) = NB(3)
;; NB(3) + A(7) = NB(3)
;; E(4) + A(7) = NB(3)
;;
;; B(2) + A(7) = NE(5)
;; B(2) + NE(5) = NE (5)
;; NE(5) + A(7) = NE(5)
;;
;; B(2) + E(4) = BE(6)
;; B(2) + BE(6) = BE(6)
;; E(4) + BE(6) = BE(6)
;;
;; NB(3) + BE(6) = JMP(unconditional)
;; NE(5) + BE(6) = JMP (unconditional)
GetRealCheck:
	cmp	eax, ebx
	jb    __@@1
	mov	ecx, ebx
	mov	edx, eax
	jmp   __@@2
__@@1:	 mov	 ecx, eax
	mov	edx, ebx
__@@2:	 test	 ecx, 1    ; ECX <= EDX
	jnz   @@NoUnconditional
	sub	edx, 1	  ; If Jcc1 == 7x and Jcc2 == 7x+1, it's an
	cmp	ecx, edx  ; unconditional JMP (for example,
	jz    @@UnconditionalJump ; opcodes 74h/75h (JZ/JNZ), etc.
	add	edx, 1
@@NoUnconditional:
	cmp	ecx, edx  ; If Jcc1 == Jcc2, the result is the same Jcc
	jz    @@ReturnCurrent
	cmp	ecx, 2	  ; JB?
	jz    @@Check2_x
	cmp	ecx, 3	  ; JAE?
	jz    @@Check3_x
	cmp	ecx, 4	  ; JZ?
	jz    @@Check4_x
	cmp	ecx, 5	  ; JNZ?
	jnz   @@NoOption
;; Check merge with JNZ
@@Check5_x:
	cmp	edx, 7	  ; JNZ + JA?
	jz    @@SetNE	  ;   Then, set JNZ
	cmp	edx, 6	  ; JNZ + JBE?
	jz    @@UnconditionalJump ; Then, set JMP (unconditional)
	jmp   @@NoOption  ; If there isn't any of these options, it
			  ; can't be compressed
;; Check merge with JB
@@Check2_x:
	cmp	edx, 4	  ; If 2nd < 4, it can't be compressed
	jb    @@NoOption
	cmp	edx, 7	  ; If 2nd > 7, it can't be compressed
	ja    @@NoOption
	test	edx, 1	  ; JB + JNZ/JA = JNZ
	jnz   @@SetNE
	jmp   @@SetBE	  ; JB + JZ/JBE = JBE

;; Check merge with JAE
@@Check3_x:
	cmp	edx, 4	  ; JAE + JZ = JAE
	jz    @@SetNB
	cmp	edx, 7	  ; JAE + JA = JAE
	jz    @@SetNB
	cmp	edx, 6	  ; JAE + JBE = JMP
	jz    @@UnconditionalJump
	jmp   @@NoOption  ; Others can't be compressed

;; Check merge with JZ
@@Check4_x:
	cmp	edx, 6	  ; JZ + JBE = JBE
	jz    @@SetBE
	cmp	edx, 7	  ; JZ + JA = JAE/JNB
	jnz   @@NoOption
     ;	jmp   @@SetNB

@@SetNB: mov	 eax, 3    ; Set JAE
	 ret
@@SetNE: mov	 eax, 5    ; Set JNZ
	 ret
@@SetBE: mov	 eax, 6    ; Set JBE
	 ret
@@NoOption:
	 mov	 eax, 0FFh ; Set "no compression"
@@ReturnCurrent:
	 ret
@@UnconditionalJump:
	 mov	 eax, 79h  ; Set JMP
	 ret



;; This function merges the Imms passed in ECX and EDX depending on the
;; operations passed in EBX and EAX. The return values are the result of
;; merging the operations. For example, if we pass MOV EAX,1234 / ADD EAX,5
;; then the returned operation will be MOV EAX,1239. It's also made for
;; ADD + ADD/SUB and many more. If the operation can't be joined then the
;; return value is 0FEh. If there are no merging, but the first instruction
;; does nothing (for example, ADD EAX,1234 / MOV EAX,5 --> MOV EAX,5) then
;; the return value is NOP.
; In:
;; ECX = First Imm
;; EDX = 2nd Imm
;; EAX = First OP
;; EBX = 2nd OP (in lower 8 bits)
; Out:
;; ECX = Value to OP
;; EAX = OP to perform
;;	FEh if it isn't shrinkable.
;;	FFh if we must eliminate 1st instruction and leave 2nd invariable.
CalculateOperation:
		and	ebx, 0FFh
		and	eax, 0FFh
		cmp	ebx, 40h   ; If 2nd instruction is MOV, eliminate 1st
		jz    @@Eliminate1st
		cmp	eax, 40h   ; First instruction == MOV?
		jz    @@MOV	   ; Then, do the merge
		or	eax, eax   ; ADD?
		jz    @@ADD
		cmp	eax, 8	   ; OR?
		jz    @@OR
		cmp	eax, 20h   ; AND?
		jz    @@AND
		cmp	eax, 28h   ; SUB?
		jz    @@SUB
		cmp	eax, 30h   ; XOR?
		jz    @@XOR
		cmp	eax, 38h   ; CMP
		jz    @@Eliminate1st
		cmp	eax, 48h   ; TEST
		jnz   @@Eliminate1st
		jmp   @@NoCompression

     ; Check a merging with the ADD as first instruction
     @@ADD:	or	ebx, ebx  ; 2nd instr. ADD?
		jz    @@ADD_ADD   ; Then, merge
		cmp	ebx, 28h  ; 2nd instr. SUB?
		jz    @@ADD_SUB   ; Then, merge
		jmp   @@NoCompression  ; Exit with no compression

     ; Try the merging with OR
     @@OR:	cmp	ebx, 8	  ; 2nd instruction == OR?
		jz    @@OR_OR	  ; Merge OR / OR
		jmp   @@NoCompression  ; Exit with no compression

     @@AND:	cmp	ebx, 20h  ; Check AND / AND
		jz    @@AND_AND   ; If it is, merge ANDs
		jmp   @@NoCompression  ; Exit with no compression

     @@SUB:	or	ebx, ebx  ; Check SUB / ADD or SUB / SUB
		jz    @@SUB_ADD
		cmp	ebx, 28h
		jnz   @@NoCompression  ; Exit with no compression
     @@SUB_SUB: neg	ecx	  ; Merge the SUBs into a single operation:
		sub	ecx, edx  ; -(1st) - 2nd = ADD Imm
		xor	eax, eax
		ret
     @@SUB_ADD: sub	edx, ecx  ; 2nd - 1st = ADD Imm
		mov	ecx, edx
		xor	eax, eax
		ret

     @@XOR:	cmp	ebx, 30h  ; XOR / XOR?
		jz    @@XOR_XOR   ; Then merge XORs
		jmp   @@NoCompression ; If it's not XOR, don't merge

     @@MOV:	or	ebx, ebx  ; MOV / ADD?
		jz    @@MOV_ADD
		cmp	ebx, 8	  ; MOV / OR?
		jz    @@MOV_OR
		cmp	ebx, 20h  ; MOV / AND?
		jz    @@MOV_AND
		cmp	ebx, 28h  ; MOV / SUB?
		jz    @@MOV_SUB
		cmp	ebx, 30h  ; MOV / XOR?
		jz    @@MOV_XOR
     @@NoCompression:
		mov	eax, 0FEh ; Set "no compression" return value
		ret
     @@Eliminate1st:
		mov	eax, 0FFh ; Set NOP to first instruction (and leave the
		ret		  ; second instruction untouched)

     @@ADD_ADD:
     @@MOV_ADD: add	ecx, edx  ; MOV + ADD or ADD + ADD = Add both Imms
		ret
     @@OR_OR:			  ; MOV + OR or OR + OR = OR both Imms
     @@MOV_OR:	or	ecx, edx
		ret
     @@AND_AND: 		  ; MOV + AND or AND + AND = AND both Imms
     @@MOV_AND: and	ecx, edx
		ret
     @@ADD_SUB: 		  ; MOV + SUB or ADD + SUB = SUB 2nd Imm from
     @@MOV_SUB: sub	ecx, edx  ; first Imm
		ret
     @@XOR_XOR: 		  ; MOV + XOR or XOR + XOR = XOR both Imms
     @@MOV_XOR: xor	ecx, edx
		ret



;;;; This functions takes 2 inputs and checks if they have Mem Operands
;;;; and compares them to see if they are the same. Arguments for this function
;;;; is ESI, EDI. If they have the same Mem Operand it will return EAX = 1, else
;;;; EAX = 0.
CheckMemOperands:
	push	edx
	mov	edx, [edi+10]
	cmp	edx, [esi+10]
	jne	NotSame 	     ; Are the offsets the same? If no, jump.

	mov	edx, [edi]
	and	edx, 0xFF
	sub	edx, [ebp+Shrink8bit2]

	mov	eax, [esi]
	and	eax, 0xFF
	sub	eax, [ebp+Shrink8bit2]

	cmp	eax, 0x51	       ; PUSH Mem?
	je	Double_MemReg
	cmp	eax, 0x52	       ; PUSH [Reg]?
	je	Double_MemReg
	cmp	eax, 0x59	       ; POP Mem?
	je	Double_MemReg
	cmp	eax, 0x5A	       ; POP [Reg]?
	je	Double_MemReg

	cmp	eax, 0x4F
	ja	NotSame

	and	eax, 7
	cmp	eax, 4		       ; Mem,Imm
	je	Double_MemReg
	cmp	eax, 5		       ; Reg,[Reg]
	je	Double_RegMem
	cmp	eax, 6		       ; [Reg],Reg
	je	Double_MemReg
	cmp	eax, 2		       ; Reg,Mem
	je	Double_RegMem
	cmp	eax, 3		       ; Mem,Reg
	jne	NotSame

Double_MemReg:
	cmp	edx, 0x51	       ; PUSH Mem?
	je	Double_CheckMemReg_MemReg
	cmp	edx, 0x52	       ; PUSH [Reg]?
	je	Double_CheckMemReg_MemReg
	cmp	edx, 0x59	       ; POP Mem?
	je	Double_CheckMemReg_MemReg
	cmp	edx, 0x5A	       ; POP [Reg]?
	je	Double_CheckMemReg_MemReg
	cmp	edx, 0x4F
	ja	NotSame

	and	edx, 7
	cmp	edx, 4
	je	Double_CheckMemReg_MemReg
	cmp	edx, 5
	je	Double_CheckMemReg_RegMem
	cmp	edx, 6
	je	Double_CheckMemReg_MemReg
	cmp	edx, 2
	je	Double_CheckMemReg_RegMem
	cmp	edx, 3
	jne	NotSame
Double_CheckMemReg_MemReg:	      ; Compare Mem's of Mem,Reg & Mem,Reg
	mov	eax, [esi+1]
	cmp	eax, [edi+1]
	jne	NotSame
	jmp	Same

Double_CheckMemReg_RegMem:	      ; Compare Mem's of Mem,Reg & Reg,Mem
	mov	eax, [esi+1]
	cmp	eax, [edi+5]
	jne	NotSame
	jmp	Same


Double_RegMem:
	cmp	edx, 0x51	       ; PUSH Mem?
	je	Double_CheckRegMem_MemReg
	cmp	edx, 0x52	       ; PUSH [Reg]?
	je	Double_CheckRegMem_MemReg
	cmp	edx, 0x59	       ; POP Mem?
	je	Double_CheckRegMem_MemReg
	cmp	edx, 0x5A	       ; POP [Reg]?
	je	Double_CheckRegMem_MemReg
	cmp	edx, 0x4F
	ja	NotSame

	and	edx, 7
	cmp	edx, 4
	je	Double_CheckRegMem_MemReg
	cmp	edx, 5
	je	Double_CheckRegMem_RegMem
	cmp	edx, 6
	je	Double_CheckRegMem_MemReg
	cmp	edx, 2
	je	Double_CheckRegMem_RegMem
	cmp	edx, 3
	jne	NotSame
Double_CheckRegMem_MemReg:	      ; Compare Mem's of Reg,Mem & Mem,Reg
	mov	eax, [esi+5]
	cmp	edx, [edi+1]
	jne	NotSame
	jmp	Same

Double_CheckRegMem_RegMem:	      ; Compare Mem's of Reg,Mem & Reg,Mem
	mov	eax, [esi+5]
	cmp	eax, [edi+5]
	jne	NotSame

NotSame:
	xor	eax, eax
	jmp	DoneChecks
Same:
	mov	eax, 1
DoneChecks:
	pop	edx
ret



;********************************************************************************
;			  Permutator
;
;	The permutator uses the fact that a label is connected with a jump
;	by a unique number ex. 3. So the permutator can create jmp's in the code
;	by getting a unique number eg. (the last stored number as a label) + 1.
;
;	The permutator starts by creating different sized frames in the FramesTable.
;	Including instructions such as single RETs, JCCs and JMPs.
;	It then writes a first jump to the first "REAL" instruction to be executed.
;	Later, it retrieves a random label from the label table and stores a label at
;	the first instruction. Now that instruction can be accessed by the JMP
;	which have that label as destination address.
;	Then it starts copying the bytes to a buffer. When it is finished. It
;	writes a JMP to the label which has the next "REAL" instruction to be
;	executed. And continues by retrieving a new frame to be copied in the same manner.
;
;********************************************************************************


Permutator:
	mov	eax, _Buffer_Section
	add	eax, ebp
	mov	[ebp+FramesTable], eax		      ; The buffer section will hold the frame table.
	mov	eax, _Disasm2_Section
	add	eax, ebp
	mov	[ebp+PermutationResult], eax	      ; PermutationResult is saved in DisasmSection2.

	mov	edi, [ebp+FramesTable]		      ; EDI = FramesTable
	mov	esi, _Disassemble_Section
	add	esi, ebp			      ; ESI = Disassembled code

	mov	ebx, [ebp+AddressOfLastInstruction]   ; EBX = AddressOfLastInstruction



@@NextFrame:
	mov	eax, [ebp+NumberOfFrames]
	add	eax, 1				     ; Increase number of frames.
	mov	[ebp+NumberOfFrames], eax
	call	Random				     ; Get random size of frame.
	and	eax, 10
	add	eax, 4
	mov	edx, 18 			     ; Multiply by 18 to get the amount
	mul	edx				     ; of bytes these disassembled instruction need.
	mov	[edi], esi			     ; Save start of frame.
	add	esi, eax			     ; Add frame size to the EIP.
	jmp	@@DontGoToNext

@@GoToNext:
	add	esi, 18
	add	eax, 18
@@DontGoToNext:
	mov	edx, [esi]			     ; Get the opcode.
	and	edx, 0xFF			     ; Isolate it.

	cmp	edx, 0xEB			     ; JMP Mem?
	je	@@Include_Instruction
	cmp	edx, 0xE9			     ; Check if it is JMP.
	je	@@Include_Instruction		     ; If it is, include it in frame.
	cmp	edx, 0xFE			     ; Check if it is RET.
	je	@@Include_Instruction
	cmp	edx, 0xFF			     ; Check if it is NOP.
	je	@@GoToNext			     ; If it is, go to next opcode.
	cmp	edx, 0x70			     ; Check if it is in JCC limit.
	jae	@@Check_JCC			     ; If it is, jump for further checking.

@@No_JCC:
	cmp	esi, ebx			     ; Check if ESI (EIP) is at AddressOfLastInstruction.
	jae	@FinishedFrames 		     ; If it is, Then all frames have been assembled, so jump.
	mov	[edi+4], esi			     ; Else, store the end of the frame.
	add	edi, 8				     ; Go to next spot in FramesTable.
	jmp	@@NextFrame			     ; Get new frame.

@@Check_JCC:
	cmp	edx, 0x7F			     ; Check if it really is JCC.
	ja	@@No_JCC			     ; if not, jump back.
@@Include_Instruction:
	add	esi, 18 			     ; Include current instruction by going to next
	add	eax, 18 			     ; instruction. Add this size to the frame size.
	jmp	@@DontGoToNext			     ; Repeat check.

@FinishedFrames:
	sub	esi, eax			     ; If frame end is over the address of last instruction.
	mov	[edi], esi			     ; Sub the frame size and overwrite the start of frame.
	mov	esi, ebx			     ; And put the address of the last instruction
	mov	[edi+4], esi			     ; as the ending of this frame.
	add	edi, 8				     ; Go to last frametable spot.
	mov	[ebp+AddressOfLastFrame], edi	     ; Save it.


;;;; Copy Frames Init:
	mov	eax, [ebp+NumberOfFrames]	     ; Save the number of frames
	mov	[ebp+FrameCounter], eax 	     ; in the frame counter.

	mov	edi, [ebp+PermutationResult]	     ; Set EDI as the result of the permutation.
	call	InsertFirstPermutationJump	     ; Set a jump to the first instruction frame.

	call	GetNewFrame			     ; Get a random frame to start with.
	call	InsertPermutationLabel		     ; Insert a label to the first instruction of the frame.
	mov	eax, [esi]			     ; Set EAX as the frame start address.

;;;; Copying function, parsing through disassembled
;;;; code and copying every byte.
@@CopyFrames:
	cmp	eax, [esi+4]			     ; Check if EAX has reached end of frame.
	jae	@DoneFrame			     ; If it has, jump. The frame is finished copying.
	mov	bl, byte[eax]			     ; Use BL as buffer for moving byte
	mov	byte[edi], bl			     ; to EDI.
	add	eax, 1				     ; Go to next byte.
	add	edi, 1				     ; Go to next spot to store byte.
	jmp	@@CopyFrames			     ; Repeat.

@DoneFrame:
	cmp	eax, [ebp+AddressOfLastInstruction]  ; If it is the last instruction, nothing
	jae	@@NoJmp 			     ; will pass this. So no JMP is needed.

	call	InsertPermutationJump		     ; Else, insert JMP.

@@NoJmp:
	call	CleanFrame			     ; Zero out the frame addresses in FramesTable.
	mov	eax, [ebp+FrameCounter] 	     ; Check if all the frames have been copied.
	test	eax, eax			     ; If it has,
	jz	@DoneCopy			     ; finish permutation.

	call	GetNewFrame			     ; Else, get new frame.
	call	InsertPermutationLabel		     ; And insert label at first instruction.

	mov	eax, [esi]			     ; Load EAX with the start address of frame.
	jmp	@@CopyFrames			     ; Loop copy.

@DoneCopy:
	mov	[ebp+AddressOfLastInstruction], edi  ; Change Address Of Last instruction for Permutation result buffer.
	mov	eax, [ebp+NumberOfLabels]	     ; Get number of labels.
	add	eax, [ebp+NumberOfFrames]	     ; Add new inserted jumps to it.
	mov	[ebp+NumberOfLabels], eax	     ; Store
	ret					     ; RETURN


;;;; This function is called when a new frame is needed.
;;;; It returns a new frame that has not been disassembled yet
;;;; and decrements FrameCounter.
;;;; It generates a random number between 0 and NumberOfFrames.
;;;; Then multiplies it by 8 (size of a frame spot), and adds the FramesTable address.
;;;; Then it checks if the addresses of that frame spot is zero.
;;;;		    If it's not, it returns that frame spot in ESI.
;;;;		    If it is, it gets a new frame spot and repeats until it finds a valid spot.
GetNewFrame:
	xor	ebx, ebx			     ; Zero out EBX.
LoopInc:
	call	RandomBool
	test	eax, eax
	jz	@DoneIncEBX
	inc	ebx
	cmp	ebx, [ebp+NumberOfFrames]
	jae	@DoneIncEBX
	jmp	LoopInc

@DoneIncEBX:
	mov	eax, ebx			     ; Get the random number to EAX.
	mov	ebx, 8				     ; EBX = 8
	mul	ebx				     ; EAX * EBX(8)
	add	eax, [ebp+FramesTable]		     ; Add frames table address.
	mov	esi, [eax]			     ; Get the address stored at that spot in ESI.
	test	esi, esi			     ; Check if ESI is 0.
	jz	GetNewFrame			     ; if it is, get new frame spot.
	mov	ebx, [ebp+FrameCounter] 	     ; Else,
	sub	ebx, 1				     ;	      decrement FrameCounter.
	mov	[ebp+FrameCounter], ebx 	     ; Store
	mov	esi, eax			     ; Move the frame spot to ESI.
	ret					     ; Ret

;;;; This function clears the frame spot in ESI.
CleanFrame:
	xor	eax, eax			     ; EAX = 0
	mov	[esi], eax			     ; [ESI] = 0
	mov	[esi+4], eax			     ; [ESI+4] = 0
	ret					     ; Ret

;;;; This function is only used for the first permutation jump.
;;;; The first permutation jump before the actual code should
;;;; always point to the first instruction of the code.
;;;; That instruction is labeled NumberOfLabels + 1.
InsertFirstPermutationJump:
	mov	eax, [ebp+NumberOfLabels]	     ; Get number of labels.
	add	eax, 1				     ; + 1
	mov	[ebp+NumberOfLabels], eax	     ; Update number of labels.
	mov	byte[edi], 0xE9 		     ; Store JMP opcode.
	mov	[edi+10], eax			     ; Set jump destination.
	add	edi, 18 			     ; Go to next instruction.

	;; Increment number of instructions and return.
	mov	eax, [ebp+NumberOfInstructions]
	add	eax, 1
	mov	[ebp+NumberOfInstructions], eax
	ret

;;;; This function is called for every permutation jump
;;;; except the first jump.
;;;; It takes the frame position from ESI (the frame that was last copied).
;;;; Divide it by 8 to get the Frame Spot. Then it adds the number of labels to the frame spot number.
;;;; And saves it at jump destination.
InsertPermutationJump:
	mov	eax, esi			     ; EAX = Frame spot
	sub	eax, [ebp+FramesTable]		     ; Removes FramesTable offset.
	mov	ebx, 8				     ; EBX = 8
	div	ebx				     ; EAX / EBX(8)
	inc	eax				     ; Cannot be 0, so increment.
	add	eax, [ebp+NumberOfLabels]	     ; Add number of labels to get its spot
	and	eax, 0xFF			     ;
	mov	byte[edi], 0xE9 		     ; Save JMP opcode.
	mov	[edi+10], eax			     ; Store jump destination.
	add	edi, 18 			     ; Go to next instruction.

	;; Increment number of instructions and return.
	mov	eax, [ebp+NumberOfInstructions]
	add	eax, 1
	mov	[ebp+NumberOfInstructions], eax
	ret

;;;; This function is called to insert a label at the first instruction of the frame.
;;;; If this instuction is already labeled, we dont want to overwrite the label
;;;; and mess up the jump that has its destination.
;;;; This is solved by creating a new instrucion (NOP), which we write the label to.
InsertPermutationLabel:
	mov	eax, esi			     ; EAX = Frame Spot.
	sub	eax, [ebp+FramesTable]		     ; Subtract FramesTable offset.
	mov	ebx, 8				     ; EBX = 8
	div	ebx				     ; EAX / EBX(8)
	add	eax, [ebp+NumberOfLabels]	     ; EAX + NumberOfLabels, to get its pos.

;;; Uncommenting this puts LM on an already existing instruction instead of
;;; creating a new F7 or FF(NOP) with LM.
	;mov	 ebx, [esi]			      ; Dereference pointer.
	;mov	 edx, [ebx+9]			      ; Check LM(+09).
	;and	 edx, 0xFF			      ; Only LM.
	;test	 edx, edx			      ; Is it labeled?
	;jnz	 @@Already_Labeled		      ; If yes, jump to insert NOP.
	;mov	 byte[ebx+9], al		      ; Else, write to it.
	;ret					      ; Ret
@@Already_Labeled:
	mov	byte[edi], 0xF7 ;0xFF			   ; Save NOP opcode.
	mov	[edi+9], eax			     ; Write label.
	add	edi, 18 			     ; Go to next instruction.

	;; Increment number of instructions and return.
	mov	eax, [ebp+NumberOfInstructions]
	add	eax, 1
	mov	[ebp+NumberOfInstructions], eax
	ret











;********************************************************************************
;			  REGISTER SCRAMBLER
;	     Formula (z = key):
;		     AND (XOR reg1, z), 7  =	   reg2
;		     AND (XOR reg2, z), 7  =	   reg1
;
;	     This function does not really scramble the regs since it is in a controlled
;	     way. If input is reg1 and the output is reg2, the formula will output
;	     reg1 if input is reg2. It is equivalent to xchg reg1, reg2.
;	     ESP is never exchanged. This means that there is another reg that
;	     cannot be swapped with ESP. But this reg will always change since
;	     the key is randomly generated, so no worries.
;
;
;********************************************************************************
RegisterScrambler:
	call	Random
	and	eax, 0xFF
	mov	edx, [AddressToFree]
	add	edx, RegisterScrambleKey
	mov	[edx], eax		   ; Set XOR key. ([edx] = XOR key)

	mov	eax, 4			   ; Move 4 (value for ESP Reg) to eax.
	xor	eax, [edx]		   ; xor it with xor key.
	and	eax, 7			   ; Get Reg limits.
	mov	ebx, eax		   ; Mov the result (a Reg value) into ebx.

					   ; If Reg = EBX
					   ;	 Dont scramble

	mov	ecx, [AddressToFree]
	add	ecx, AddressOfLastInstruction
	mov	ecx, [ecx]		   ; Set ECX as last instruction.
	mov	esi, [AddressToFree]
	add	esi, _Disassemble_Section  ; ESI is our EIP

RegScram_Loop:
	cmp	esi, ecx		   ; Check if EIP is at last instruction.
	jae	RetRegScram		   ; If yes, return function.

	mov	eax, [esi]		   ; Load EAX with pseudo OPCODE.
	and	eax, 0xFF

	cmp	eax, 0x4F		   ; Is it Generic Opcode?
	jbe	@GenericOPCODE		   ; If yes, go for further checking.

	cmp	eax, 0x50		   ; Is it push?
	je	@Scram_DST		   ; If yes, scramble DST Reg.

	cmp	eax, 0x58		   ; Is it pop?
	je	@Scram_DST		   ; If yes, scramble DST Reg.

	cmp	eax, 0xCF
	jb	@GenericOPCODE

	jmp	GetNextInstr		   ; If none match, get new instruction.




@GenericOPCODE:
	and	eax, 7			   ; Get parameters.

	cmp	eax, 0			   ; Reg,Imm?
	je	@Scram_DST		   ; If yes, scramble DST (Reg).
	cmp	eax, 1			   ; Reg,Reg?
	je	@Scram_DST_SRC		   ; If yes, scramble DST and SRC (Both Reg).
	cmp	eax, 2			   ; Reg,Mem?
	je	@Scram_DST		   ; If yes, scramble DST (Reg).
	cmp	eax, 3			   ; Mem,Reg?
	je	@Scram_SRC		   ; If yes, scramble SRC (Reg).
	cmp	eax, 4			   ; Mem,Imm?
	je	GetNextInstr		   ; If yes, no reg is available. So get new instr.
	cmp	eax, 5			   ; Reg,[Reg]?
	je	@Scram_DST_SRC		   ; If yes, scramble DST and SRC ( Both Reg).
	cmp	eax, 6			   ; [Reg],Reg?
	je	@Scram_DST_SRC		   ; If yes, scramble DST and SRC (Both Reg).



@Scram_DST:
	mov	eax, [esi+1]		   ; Get DST Reg.
	cmp	eax, ebx		   ; Check if it is the reg which will result in ESP.
	je	GetNextInstr		   ; If yes, dont scramble.
	cmp	eax, 4			   ; Check if it is ESP.
	je	GetNextInstr		   ; If yes, dont scramble.
	xor	eax, [edx]		   ; Formula.
	and	eax, 7			   ; Formula.
	mov	[esi+1], eax		   ; Save new Reg in same spot.
	jmp	GetNextInstr		   ; Get new instr.

@Scram_SRC:
	mov	eax, [esi+5]		   ; Get SRC Reg.
	cmp	eax, ebx		   ; Check if it is the reg which will result in ESP.
	je	GetNextInstr		   ; If yes, dont scramble.
	cmp	eax, 4			   ; Check if it is ESP.
	je	GetNextInstr		   ; If yes, dont scramble.
	xor	eax, [edx]		   ; Formula.
	and	eax, 7			   ; Formula.
	mov	[esi+5], eax		   ; Save new Reg in same spot.
	jmp	GetNextInstr		   ; Get new instr.

;;;; SAME AS @Scram_DST but with a jump to @Scram_SRC.
@Scram_DST_SRC:
	mov	eax, [esi+1]
	cmp	eax, ebx
	je	@Scram_SRC		   ; Check next Reg (SRC).
	cmp	eax, 4
	je	@Scram_SRC		   ; Check next Reg (SRC).
	xor	eax, [edx]
	and	eax, 7
	mov	[esi+1], eax
	jmp	@Scram_SRC


RetRegScram:
	ret				   ; RET

GetNextInstr:
	add	esi, 18 		   ; Get next pseudo instr.
	jmp	RegScram_Loop


















;********************************************************************************
;			  REASSEMBLER
;	The assembler assembles each pseudo-instruction to x86 opcode
;	while fixing jmp relocations aswell. It fixes the jumps by checking
;	whether a pseudo-instr. has a label mark. If it has a mark it jumps
;	to a seperate code and updates the label tabel. As you know, the label-
;	mark is a positive integer. (That integer) - 1 * 4 = place in tabel it points to.
;	To update that label, replace the label at the marked position with the
;	current EIP (edi) in the reassembly section.
;	For example:
;	LM: 2
;	label position in label section to be updated = (2 - 1) * 4 = 4
;	mov [LabelSection + 4], esi	; LABEL UPDATED
;
;	The jump instructions can only be adapted when the whole code has been assembled
;	because the distance is not set if it has not been assembled.
;
;	To fix all jmps the code parses the assembled code for jmps, calls, jccs.
;	When found, it checks its destination. Which matches a label mark, for example: 2.
;	It then finds the label at the position 2 ((2 - 1) * 4 = 4(position in label section)).
;	Moves the stored address in that pointer to the jump instrcution.
;
;********************************************************************************

ReAssembler:
	mov	esi, [AddressToFree]		  ; INITIALIZE ASSEMBLER
	add	esi, _Disasm2_Section
	;add	  esi, _Disassemble_Section
	mov	edi, [AddressToFree]
	add	edi, _Reasm_Section

@@ReAsm_Loop:
	mov	eax, [esi+9]		      ; Load eax with LM.
	and	eax, 0xFF
	test	eax, eax		      ; Check if LM is zero.
	jnz	@@Asm_Labeled		      ; If it is not, jump.
@@Asm_CheckBranch:
	mov	eax, [esi]
	and	eax, 0xFF
	push	eax
	call	CheckIfBranchInstr
	test	eax, eax
	jnz	@@Asm_Branch

@@RetToAsm:
	call	Assemble_Instruction	      ; Call assembler for instruction.
	add	esi, 18 		      ; Update EIP (esi).
	mov	eax, [AddressToFree]
	add	eax, AddressOfLastInstruction
	mov	eax, [eax]		      ; Load eax with Address of last instruction
	cmp	esi, eax		      ; Check if EIP has reached it.
	jb	@@ReAsm_Loop		      ; If it is lower, LOOP the assembler.

RetFromReasm:
	mov	[ebp+AddressOfLastReasmInstruction], edi
	sub	edi, [AddressToFree]
	sub	edi, _Reasm_Section
	mov	[ebp+ReasmSize], edi


	call	UpdateJmps
	ret


;;;; Updates the label tabel with the real address from the assembled code to the label section
@@Asm_Labeled:
	dec	eax			      ; LM - 1
	shl	eax, 2			      ; * 4
	mov	edx, [AddressToFree]
	add	edx, _Label_Section
	add	edx, eax		      ; LabelSection + (LM - 1) * 4

	mov	eax, [esi]
	and	eax, 0xFF
	cmp	eax, 0xF7
	je	@@Asm_Overlap_Label

	mov	[edx], edi		      ; Update label.
	jmp	@@Asm_CheckBranch

@@Asm_Overlap_Label:
	mov	eax, edi
	add	eax, 2
	mov	[edx], eax
	jmp	@@Asm_CheckBranch


@@Asm_Branch:
	mov	eax, [ebp+AsmBranchCount]
	shl	eax, 2
	add	eax, ebp
	add	eax, _Future_Label_Section
	mov	[eax], edi
	inc	dword[ebp+AsmBranchCount]
	jmp	@@RetToAsm




Assemble_Instruction:
	mov	eax, [esi]		      ; Load eax with OP pseudo instr.
	and	eax, 0xFF

	cmp	eax, 0x4F		      ; Check if it is GenericOP.
	jbe	@@GenericOP		      ; jump if it is.

	cmp	eax, 0x52
	jbe	@@Asm_Push_Pop		      ; Check push/pop range

	cmp	eax, 0x5A
	jbe	@@Asm_Push_Pop		      ; Check push/pop range

	cmp	eax, 0x68
	je	@@Asm_Push_Pop		      ; Push imm?

	cmp	eax, 0x7F		      ; Is it jcc?
	jbe	@@Asm_Jcc

	cmp	eax, 0xCF
	jb	@@GenericOP		      ; 8bit Generic OP?

	cmp	eax, 0xE8		      ; Is it call label?
	je	@@Asm_Call_Label

	cmp	eax, 0xE9		      ; Is it jmp?
	je	@@Asm_JMP

	cmp	eax, 0xEA		      ; call API?
	je	@@Asm_Call_Mem

	cmp	eax, 0xEB		      ; JMP Mem?
	je	@@Asm_JMP_Mem

	cmp	eax, 0xF4		      ; APICALL_BEGIN?
	je	@@Asm_APICALL_BEGIN

	cmp	eax, 0xF5		      ; APICALL_END?
	je	@@Asm_APICALL_END

	cmp	eax, 0xF7
	je	@@Asm_Overlapped_Dest

	cmp	eax, 0xFE		      ; Is it ret?
	je	@@Asm_Ret

	cmp	eax, 0xFF		      ; NOP?
	je	@@Asm_NOP








;; This creates overlapped instructions with real instructions
;; encoded within them.
@@Asm_Overlapped_Dest:
	mov	byte[edi], 0xC7
	mov	byte[edi+1], 0x80
@@Asm_Overlapped_NoESP:
	call	Random
	and	eax, 7
	cmp	eax, 4
	je	@@Asm_Overlapped_NoESP
	add	byte[edi+1], al
	add	edi, 2
	ret




@@Asm_APICALL_BEGIN:
	xor	edx, edx
	mov	eax, 0x50
@@Asm_APICALL_BEGIN_LOOP:
	mov	[edi+edx], al
	cmp	edx, 2
	je	@@DoneAsmAPICALLBEGIN
	inc	eax
	inc	edx
	jmp	@@Asm_APICALL_BEGIN_LOOP
@@DoneAsmAPICALLBEGIN:
	add	edi, 3
	ret

@@Asm_APICALL_END:
	xor	edx, edx
	mov	eax, 0x5A
@@Asm_APICALL_END_LOOP:
	mov	[edi+edx], al
	cmp	edx, 2
	je	@@DoneAsmAPICALLEND
	dec	eax
	inc	edx
	jmp	@@Asm_APICALL_END_LOOP
@@DoneAsmAPICALLEND:
	add	edi, 3
	ret


@@Asm_JMP_Mem:
	mov	eax, 0x10
	mov	[edi+1], al
	jmp	@@Asm_Call_Mem


@@Asm_Push_Pop:
	cmp	eax, 0x68		      ; Check if it is push imm.
	je	@@Asm_PushImm		      ; Jump if it is.
	and	eax, 3			      ; Else, get what type of push/pop (50: Reg,
					      ; 51: Mem, 52: [Reg].
	cmp	eax, 0			      ; Is it push/pop Reg?
	je	@@Asm_PushPopReg	      ; If yes, jump.
	cmp	eax, 1			      ; Is it push/pop Mem?
	je	@@Asm_PushPopMem
	cmp	eax, 2			      ; Is it push/pop [Reg]
	je	@@Asm_PushPopPtrReg

;; Push Imm
@@Asm_PushImm:
	mov	edx, [esi+1]		      ; Get the imm value.
	cmp	edx, 0x79		      ; Check if it is 1 byter.
	jbe	@Rand_PushImm		      ; If it is, jump.
@SetPushBigImm:
	mov	byte[edi], 0x68 	      ; Set push opcode.
	mov	[edi+1], edx		      ; Set imm16/32
	add	edi, 5
	ret

@Rand_PushImm:
	call	RandomBool		      ; Store as imm8 or imm16/32?
	test	eax, eax
	jz	@SetPushBigImm
	mov	byte[edi], 0x6A 	      ; Store push imm8 opcode.
	mov	[edi+1], edx		      ; Store imm8.
	add	edi, 2
	ret

;; Push/Pop Reg
@@Asm_PushPopReg:
	call	RandomBool
	test	eax, eax
	jz	@@Asm_2byte
	mov	eax, [esi]
	and	eax, 0xFF
	cmp	eax, 0x50		      ; Check if it is Push or Pop.
	je	@@Asm_PushReg
	mov	byte[edi], 0x8		      ; If Pop Reg, 0x50 + 0x8 = 0x58 (Pop Reg opcode).

@@Asm_PushReg:
	add	byte[edi], 0x50 	      ; 0x50 (Push Reg opcode).
	mov	eax, [esi+1]		      ; Get Reg.
	and	eax, 0xFF
	add	[edi], eax		      ; Add Reg.
	add	edi, 1
	ret

@@Asm_2byte:
	mov	eax, [esi]
	and	eax, 0xFF
	cmp	eax, 0x58
	je	@@Asm_2byte_Pop
	mov	byte[edi], 0x70
	mov	byte[edi+1], 0x30

@@Asm_2byte_Pop:
	add	byte[edi], 0x8F
	mov	eax, [esi+1]
	and	eax, 0xFF
	add	eax, 0xC0
	add	[edi+1], eax
	add	edi, 2
	ret


;; Push/Pop Mem
@@Asm_PushPopMem:
	mov	eax, [esi]
	and	eax, 0xFF
	cmp	eax, 0x59		      ; Pop Mem?
	je	@@Asm_PopMem		      ; Jump if it is.
	mov	byte[edi], 0x70 	      ; 0x70 + 0x8F = 0xFF (First byte in Push Mem)
	mov	byte[edi+1], 0x30	      ; 0x30 + 0x05 = 0x35 (Second byte in Push Mem)
@@Asm_PopMem:
	add	byte[edi], 0x8F 	      ; 0x8F (First byte in Pop Mem)
	add	byte[edi+1], 0x05	      ; 0x05 (Second byte in Pop Mem)
	mov	eax, [esi+1]		      ; Get memory address.
	mov	[edi+2], eax		      ; Store memory address.
	add	edi, 6
	ret

;; Push/Pop [Reg]
@@Asm_PushPopPtrReg:
	mov	eax, [esi]
	and	eax, 0xFF
	cmp	eax, 0x5A		      ; Is it Pop [Reg]?
	je	@@Asm_PopPtrReg 	      ; If yes, jump.
	mov	byte[edi], 0x70 	      ; 0x70 + 0x8F = 0xFF (First byte in Push [Reg])
	mov	byte[edi+1], 0x30	      ; 0x30 as second byte of Push [Reg] without offset.

@@Asm_PopPtrReg:
	add	byte[edi], 0x8F 	      ; 0x8F (First byte in Pop [Reg])
	mov	eax, [esi+1]		      ; Check Reg.
	cmp	eax, 4			      ; Is it ESP? Then the instr needs another byte (0x24).
	je	@@Asm_Push_ESP
	cmp	eax, 5			      ; Is it EBP? Then has to be stored with an offset.
	je	@@Asm_Small_Offset
	mov	eax, [esi+10]		      ; Get the offset value.
	test	eax, eax		      ; Check if it is zero.
	je	@@Asm_No_Offset 	      ; If it is, store jump to store without offset.
	cmp	eax, 0x79		      ; Check if the offset is an imm8.
	jbe	@@Asm_Small_Offset	      ; If it is, store jump to store with imm8 offset.

@@Asm_Big_Offset:
	mov	edx, [esi+10]		      ; Get offset.
	mov	eax, [esi+1]		      ; Get Reg.
	add	eax, 0x80		      ; 0x30 + 0x80 = 0xB0 (Push [Reg+imm16/32] opcode) or
	add	[edi+1], eax		      ; 0x0 + 0x80 = 0x80 (Pop [Reg+imm16/32] opcode)
	mov	[edi+2], edx		      ; Store offset.
	add	edi, 6
	ret

@@Asm_No_Offset:
	call	RandomBool		      ; Randomization (1/2) to store without or with offset as 0.
	test	eax, eax
	jz	@@Asm_Small_Offset	      ; Store with imm8 offset as 0.
	mov	eax, [esi+1]		      ; Else, store without offset. Get the Reg
	add	[edi+1], eax		      ; Add the reg to 0x30 for Push [Reg] or 0x0 for Pop [Reg]
	add	edi, 2
	ret

@@Asm_Small_Offset:
	call	RandomBool		      ; Randomization to store offset as imm16/32 or imm8
	test	eax, eax
	jz	@@Asm_Big_Offset	      ; 1/2 possibility to store as imm16/32.
	mov	edx, [esi+10]		      ; Get the offset.
	mov	eax, [esi+1]		      ; Get the Reg.
	add	eax, 0x40		      ; 0x30 + 0x40 = 0x70 (Push [Reg+imm8] opcode) or
	add	[edi+1], eax		      ; 0x0 + 0x40 = 0x40  (Pop [Reg+imm8] opcode).
	mov	[edi+2], edx		      ; Store offset.
	add	edi, 3
	ret

;; Same checks as above but added another byte (0x24) to the instruction to
;; encode ESP reg.
@@Asm_Push_ESP:
	mov	edx, [esi+10]		      ; Get offset.
	test	edx, edx		      ; Is there an offset?
	jz	@NoOfsESP
	cmp	edx, 0x79		      ; Is the offset imm8?
	jbe	@SmallOfsESP
@BigOfsESP:
	add	byte[edi+1], 0x84
	mov	byte[edi+2], 0x24
	mov	[edi+3], edx
	add	edi, 7
	ret

@NoOfsESP:
	call	RandomBool
	test	eax, eax
	jz	@SmallOfsESP
	add	byte[edi+1], 0x04
	mov	byte[edi+2], 0x24
	add	edi, 3
	ret

@SmallOfsESP:
	call	RandomBool
	test	eax, eax
	jz	@BigOfsESP
	add	byte[edi+1], 0x44
	mov	byte[edi+2], 0x24
	mov	[edi+3], edx
	add	edi, 4
	ret



;; Call Mem
@@Asm_Call_Mem:
	mov	eax, 0xFF
	mov	byte[edi], al	     ; Store first byte of CALL MEM (0xFF).
	mov	eax, 0x15
	add	byte[edi+1], al      ; Store second byte (0x15).
	mov	eax, [esi+10]	     ; Load eax with value to call.
	mov	[edi+2], eax	     ; Insert it in x86 instruction.
	add	edi, 6
	ret

;; NOP
@@Asm_NOP:
	mov	eax, 0x90
	mov	[edi], eax	     ; Insert NOP.
	add	edi, 1
	ret

;; Call Label
@@Asm_Call_Label:
	mov	eax, [esi]	     ; Get CALL LABEL opcode from pseudo instruction (same as x86).
	and	eax, 0xFF
	mov	[edi], eax	     ; Insert it.
	mov	eax, [esi+10]	     ; Get address of label to call.
	mov	[edi+1], eax	     ; Insert address to call.
	add	edi, 5
	ret

;; RET
@@Asm_Ret:
	mov	eax, 0xC3
	mov	[edi], eax	     ; Insert RET x86 opcode.
	add	edi, 1
	ret

;; JCC
@@Asm_Jcc:
	mov	edx, 0x0F
	mov	[edi], edx	     ; Store first byte of LONG JCC's.
	add	eax, 0x10	     ; Add 0x10 to Opcode of SHORT JCC's to get long JCC's.
	mov	[edi+1], eax	     ; Insert it in second byte.
	mov	eax, [esi+10]	     ; Load EAX with label address.
	mov	[edi+2], eax	     ; Insert label address.
	add	edi, 6
	ret

;; JMP
@@Asm_JMP:
	mov	eax, [esi]	     ; Get JMP opcode from pseudo instruction (0xE9)
	and	eax, 0xFF
	mov	[edi], eax	     ; Insert it.
	mov	eax, [esi+10]	     ; Get label address.
	mov	[edi+1], eax	     ; Insert label address.
	add	edi, 5
	ret




@@GenericOP:
	mov	ebx, eax
	mov	edx, ebx
	and	eax, 7			      ; Which params?

	cmp	eax, 0x0
	je	@@Asm_Reg_Imm		      ; OP reg,imm

	cmp	eax, 0x4
	je	@@Asm_Mem_Imm		     ; OP Mem,Imm

	cmp	ebx, 0x80		     ; Is it 8 bit?
	jae	@Asm_8BitArgs		     ; If yes, jump.
	jmp	@No8Bit

@Asm_8BitArgs:
	sub	ebx, 0x81		     ; Remove 8 bit indikation (0x80) + 1.
	sub	edx, 0x81		     ; Remove 8 bit indikation (0x80) + 1.
@No8Bit:
	cmp	eax, 0x1
	je	@@Asm_Reg_Reg		      ; OP reg,reg
	cmp	eax, 0x2
	je	@@Asm_Reg_Mem		      ; OP reg,mem
	cmp	eax, 0x3
	je	@@Asm_Mem_Reg		     ; OP mem,reg

	cmp	edx, 0x46
	je	@@Asm_Mov_PtrReg	     ; Mov with a PtrReg
	cmp	edx, 0x45
	je	@@Asm_Mov_PtrReg	     ; Mov with a PtrReg
	cmp	edx, 0x4D
	je	@@Asm_Test_PtrReg	     ; Test with a PtrReg
	cmp	edx, 0x4E
	je	@@Asm_Test_PtrReg	     ; Test with a PtrReg
	jmp	@@No_MOV_or_TEST	     ; Else, normal OP.

@@Asm_Mov_PtrReg:
	add	edx, 0x0C		     ; Add Mov adjustment

@@Asm_Test_PtrReg:
	add	edx, 0x3C		     ; Add Test adjustment

@@No_MOV_or_TEST:
	mov	eax, [esi+1]		     ; Move PtrReg to EAX to avoid overwriting if
	mov	ecx, [esi+5]		     ; PtrReg is SRC.	ECX = other reg.
	mov	ebx, [esi]
	and	ebx, 0xFF
	and	ebx, 7			     ; Get params.

	cmp	ebx, 0x5
	je	@@Asm_Reg_PtrReg	     ; OP Reg,[Reg]
	cmp	ebx, 0x6
	je	@@Asm_PtrReg_Reg	     ; OP [Reg],Reg



;; OP Reg, PtrReg
@@Asm_Reg_PtrReg:
	add	edx, 3			   ; Pseudo Opcode + 3 - 5 = x86 opcode for OP Reg, PtrReg.
	mov	eax, [esi+5]		   ; Overwrite EAX as PtrReg.
	mov	ecx, [esi+1]		   ; Overwrite ECX as Reg.
@@Asm_PtrReg_Reg:
	sub	edx, 5			   ; Pseudo Opcode - 5 = x86 opcode for OP PtrReg, Reg.
	mov	[edi], edx		   ; Store first byte (That defines instruction type).

	shl	ecx, 3			   ; Multiply ECX by 8.
	mov	[edi+1], ecx		   ; Store Reg.
	add	[edi+1], eax		   ; Add PtrReg.

	mov	ebx, [esi+10]	 ; Get PtrReg offset value.
	cmp	eax, 4		 ; If PtrReg is ESP it has to be stored with a special byte (0x24).
	je	@@ESP_Ptr

	cmp	eax, 5		 ; If PtrReg is EBP it has to be stored with an offset.
	je	@@Db_Offset

	test	ebx, ebx	 ; Is there an offset?
	jz	@No_Offset	 ; If no, jump.
	cmp	ebx, 0x79	 ; Is the offset an imm8?
	ja	@@Dd_DwOffset	 ; If yes, jump.

@@Db_Offset:
	call	RandomBool	 ; 1/2 probability to store with imm16/32 offset.
	test	eax, eax
	jz	@@Dd_DwOffset
	add	byte[edi+1], 0x40  ; Add second byte adjustment for imm8 offset.
	mov	[edi+2], ebx	   ; Store imm8 offset.
	add	edi, 3
	ret

@@Dd_DwOffset:
	add	byte[edi+1], 0x80  ; Add second byte adjustment for imm16/32 offset.
	mov	[edi+2], ebx	   ; Store imm16/32 offset.
	add	edi, 6
	ret

@No_Offset:
	call	RandomBool	   ; 1/2 probability to store x86 instr with an offset as 0.
	test	eax, eax
	jz	@@Db_Offset
	add	edi, 2
	ret

;; Same calculations as above but with an ESP special byte (0x24).
@@ESP_Ptr:
	mov	byte[edi+2], 0x24
	test	ebx, ebx
	jz	@ESPNo_Offset
	cmp	ebx, 0x79
	ja	@@ESPDd_DwOffset

@@ESPDb_Offset:
	call	RandomBool
	test	eax, eax
	jz	@@ESPDd_DwOffset
	add	byte[edi+1], 0x40
	mov	[edi+3], ebx
	add	edi, 4
	ret

@@ESPDd_DwOffset:
	add	byte[edi+1], 0x80
	mov	[edi+3], ebx
	add	edi, 7
	ret

@ESPNo_Offset:
	call	RandomBool
	test	eax, eax
	jz	@@ESPDb_Offset
	add	edi, 3
	ret





;; OP Reg, Imm
@@Asm_Reg_Imm:
	cmp	ebx, 0x80	      ; Check if its 8 bit operands.
	jb	@No_8bitz
	mov	ecx, [esi+5]	      ; Get the imm in ECX.

	cmp	ebx, 0xB8	      ; Check if it is normal OP.
	jbe	@@Asm_8bit_Normal
	cmp	ebx, 0xC0	      ; Check if it is Mov.
	je	@@Asm_8bitMOV

;; Else it must be TEST
	mov	byte[edi], 0xF6       ; Store Test Reg8, imm8 first byte.
	mov	eax, [esi+1]
	and	eax, 7		      ; Get Reg8.
	add	eax, 0xC0	      ; Reg8 + 0xC0
	mov	[edi+1], eax
	mov	[edi+2], ecx	      ; Store imm8.
	add	edi, 3
	ret

;; Mov Reg8, Imm8
@@Asm_8bitMOV:
	mov	eax, [esi+1]
	and	eax, 7		      ; Get Reg8.
	add	eax, 0xB0	      ; Add Mov Adjustment.
	mov	[edi], eax	      ; Store.
	mov	[edi+1], ecx	      ; Store imm8.
	add	edi, 2
	ret

@@Asm_8bit_Normal:
	mov	byte[edi], 0x80       ; Store first byte in normal OP 8bit.
	mov	eax, [esi+1]
	and	eax, 7		      ; Get Reg.
	add	eax, 0x40	      ; Add adjustment.
	add	eax, ebx	      ; Pseudo opcode + 8 bit indication.
	mov	[edi+1], eax	      ; Store.
	mov	[edi+2], ecx	      ; Store imm8.
	add	edi, 3
	ret


@No_8bitz:
	cmp	ebx, 0x38		      ; NOT MOV OR TEST.
	jbe	@@Asm_RegImm_Normal
	cmp	ebx, 0x40		      ; MOV REG, IMM
	je	@@Asm_RegImm_MOV

@@Asm_RegImm_TEST:			      ; Test Reg, Imm
	mov	eax, [esi+1]		      ; Load eax with first reg.
	and	eax, 7
	test	eax, eax		      ; Is it EAX?
	jnz	@@Asm_TestRegImm_NotEAX
	call	RandomBool		      ; Randomize, one byte opcode or two byte?
	test	eax, eax
	jz	@@Asm_TestRegImm_NotEAX
	mov	eax, 0xA9		      ; One byter.
	jmp	@@Assemble_RegImm_OneByter

@@Asm_TestRegImm_NotEAX:
	mov	eax, 0xF7		      ; Two byter.
	xor	ebx, ebx
	jmp	@@Assemble_OPRegImm_Normal_01


@@Asm_RegImm_MOV:
	call	RandomBool		      ; Randomize, one byte opcode or two byte?
	and	eax, eax
	jz	@@Asm_MOVRegImm_OneByter
	mov	eax, 0xC7		      ; Two byter.
	xor	ebx, ebx
	jmp	@@Assemble_OPRegImm_Normal_01


@@Asm_MOVRegImm_OneByter:
	mov	eax, [esi+1]
	add	eax, 0xB8		      ; One byter.
	jmp	@@Assemble_RegImm_OneByter


@@Asm_RegImm_Normal:
	mov	eax, [esi+1]	      ; Get the register
	and	eax, 7		      ; Is it EAX?
	or	eax, eax
	jnz   @@Assemble_OPRegImm_Normal_00 ; If it isn't jump
	call	RandomBool	      ; Select randomly to code a
	or	eax, eax	      ; exclusive EAX opcode or not
	jz    @@Assemble_OPRegImm_Normal_00 ; If not, jump
	mov	eax, ebx	      ; Add 5 to the generic opcode
	add	eax, 5		      ; to get an OP EAX,xxx

@@Assemble_RegImm_OneByter:
	mov	[edi], eax
	mov	eax, [esi+5]
	mov	[edi+1], eax
	add	edi, 5
ret

@@Assemble_OPRegImm_Normal_00:
	mov	eax, 0x81	      ; First byte always 0x81 for normal Generic.
@@Assemble_OPRegImm_Normal_01:
	mov	[edi], eax
	mov	eax, [esi+1]
	and	eax, 7
	add	eax, 0xC0
	add	eax, ebx
	mov	[edi+1], eax
	mov	eax, [esi+5]
	mov	[edi+2], eax
	add	edi, 6
ret




@@Asm_Reg_Reg:
	cmp	ebx, 0x40
	jb	@@Asm_RegReg_Next_00
	cmp	ebx, 0x41
	jbe	@@Asm_MOVRegReg

@@Asm_TESTRegReg:
	add	ebx, 0x3C
	call	RandomBool
	jz	@@Inversed_RegReg_2
	jmp	@@Non_Inversed_RegReg

@@Asm_MOVRegReg:
	add	ebx, 0x48
	call	RandomBool
	or	eax, eax
	jz	@@Non_Inversed_RegReg
	jmp	@@Inversed_RegReg



@@Asm_RegReg_Next_00:
	call	RandomBool
	or	eax, eax
	jz	@@Inversed_RegReg


@@Non_Inversed_RegReg:
	mov	ecx, [esi+5]
	mov	edx, [esi+1]
	jmp	@@Asm_OPRegReg_Next

@@Inversed_RegReg:
	add	ebx, 2
@@Inversed_RegReg_2:
	mov	ecx, [esi+1]
	mov	edx, [esi+5]

@@Asm_OPRegReg_Next:
	mov	[edi], ebx	; Set the opcode
	mov	eax, ecx	; Set ECX in bits 5,4,3 and EDX in
	shl	eax, 3		;  bits 2,1,0
	add	eax, 0xC0	; Activate bits 7&6 to use bits 2,1,0
	add	eax, edx	;  as a register rather than as a
	mov	[edi+1], eax	;  memory operand.
	add	edi, 2		; Store it and increment the EIP
ret





@@Asm_Reg_Mem:
	cmp	ebx, 0x40
	jb	@@Asm_RegMem
	cmp	ebx, 0x48
	jb	@@Asm_MOVRegMem

;@@Asm_TESTRegMem:
;	 mov	 ebx, 0x84	 ; + 1 = 0x85

@@Asm_MOVRegMem:
	mov	eax, [esi+1]
	and	eax, 0xFF
	cmp	eax, 0
	jne	@@Asm_RegMem_NotEAX
	call	RandomBool
	or	eax, eax
	jz	@@Asm_RegMem_NotEAX
	add	ebx, 0x5F
	mov	[edi], ebx
	mov	eax, [esi+5]
	mov	[edi+1], eax
	add	edi, 5
ret


@@Asm_RegMem_NotEAX:
	add	ebx, 0x48	; + 1 = 0x8B

@@Asm_RegMem:
	add	ebx, 1
	mov	[edi], ebx

	mov	ebx, [esi+1]
	and	ebx, 0xFF
	shl	ebx, 3
	add	ebx, 5
	mov	[edi+1], ebx

	mov	ebx, [esi+5]
	mov	[edi+2], ebx
	add	edi, 6
ret




@@Asm_Mem_Reg:
	cmp	ebx, 0x40
	jb	@@Asm_MemReg
	cmp	ebx, 0x48
	jb	@@Asm_MOVMemReg

@@Asm_TESTRegMem:
	mov	ebx, 0x87	; - 2 = 0x85
	jmp	@@Asm_MemReg

@@Asm_MOVMemReg:
	mov	eax, [esi+5]
	and	eax, 0xFF
	cmp	eax, 0
	jne	@@Asm_MemReg_NotEAX
	call	RandomBool
	or	eax, eax
	jz	@@Asm_MemReg_NotEAX
	add	ebx, 0x60
	mov	[edi], ebx
	mov	eax, [esi+1]
	mov	[edi+1], eax
	add	edi, 5
ret

@@Asm_MemReg_NotEAX:
	add	ebx, 0x48

@@Asm_MemReg:
	sub	ebx, 2
	mov	[edi], ebx
	mov	ebx, [esi+5]
	and	ebx, 0xFF
	shl	ebx, 3
	add	ebx, 5
	mov	[edi+1], ebx

	mov	ebx, [esi+1]
	mov	[edi+2], ebx
	add	edi, 6
ret



@@Asm_Mem_Imm:
	cmp	ebx, 0x80
	jb	@@Asm_No8Bit

	cmp	ebx, 0xCC
	je	@@Asm_Test_Mem_Imm_8bit
	cmp	ebx, 0xC4
	je	@@Asm_Mov_Mem_Imm_8bit

	sub	ebx, 0x80
	mov	byte[edi], 0x80
	jmp	@@Set8bitOPs

@@Asm_Test_Mem_Imm_8bit:
	mov	byte[edi], 0x30
@@Asm_Mov_Mem_Imm_8bit:
	sub	ebx, 0x80
	add	byte[edi], 0xC6
	mov	byte[edi+1], 0x05
	jmp	@@Set8bitMOVTEST


@@Asm_No8Bit:
	xor	eax, eax
	cmp	ebx, 0x40
	jb	@@Asm_MemImm
	cmp	ebx, 0x48
	jbe	@@Asm_MOVMemImm

	mov	eax, 0x30

@@Asm_MOVMemImm:
	add	eax, 0xC7
	mov	[edi], eax
	mov	ebx, 0x05
	mov	[edi+1], ebx
	jmp	@@Asm_AddrNimm

@@Asm_MemImm:
	mov	eax, [esi+5]
	cmp	eax, 0x79
	jbe	@@Small_Imm
@@Asm_MemBigImm:
	mov	eax, 0x81
	mov	[edi], eax
	add	ebx, 1
	mov	[edi+1], ebx
@@Asm_AddrNimm:
	mov	eax, [esi+1]
	mov	[edi+2], eax
	mov	eax, [esi+5]
	mov	[edi+6], eax
	add	edi, 10
ret

@@Small_Imm:
	call	RandomBool
	or	eax, eax
	jnz	@@Asm_MemBigImm
	mov	eax, 0x83
	mov	[edi], eax
@@Set8bitOPs:
	add	ebx, 1
	mov	[edi+1], ebx
@@Set8bitMOVTEST:
	mov	eax, [esi+1]
	mov	[edi+2], eax
	mov	eax, [esi+5]
	and	eax, 0xFF
	mov	[edi+6], eax
	add	edi, 7
ret




UpdateJmps:

	mov	ecx, [ebp+AsmBranchCount]	; ECX is the counter.
	push	ecx				; Save ECX
UpdateOverlapJmps:
	pop	ecx				; Restore ECX
	test	ecx, ecx
	jz	OverlapUpdateFinished		; Is it zero?
	dec	ecx
	push	ecx				; Save ECX
	mov	eax, ecx
	shl	eax, 2
	add	eax, ebp
	add	eax, _Future_Label_Section
	mov	ecx, [eax]
	mov	edx, [ecx]		       ; Dereference EAX twice.
	and	edx, 0xFF
	cmp	edx, 0xE9
	je	@@Update_Jmp
	cmp	edx, 0xE8
	je	@@Update_Call_Label
	jmp	@@Update_Jcc
	; IT WILL BE LOOPED BECAUSE IT CAN ONLY BE A BRANCH
OverlapUpdateFinished:
	ret



@@Update_Call_Label:
	mov	eax, [ecx+1]
	dec	eax
	shl	eax, 2
	mov	edx, [AddressToFree]
	add	edx, _Label_Section
	add	edx, eax
	mov	eax, [edx]

	push	eax
	jmp	@@Long



;;;; This updates the E9 (jmp) instructions. They are saved as long jmps
;;;; because long jumps are the bigger size compared to short jumps.
;;;; If the relocation is lower than 0x7F it has a 50% chance to be a short jump.
;;;; Short jumps are nop padded because the code is already assembled, nops will be eliminated
;;;; on next generations.
@@Update_Jmp:
	mov	eax, [ecx+1]			    ; Check the label section position for the jmp dest.
	cmp	eax, 0x1000
	ja	UpdateOverlapJmps
	mov	edx, [AddressToFree]
	add	edx, _Label_Section
	dec	eax
	shl	eax, 2				    ; (EAX - 1) * 2
	add	edx, eax			    ; Add label section address to label position.
	mov	eax, [edx]			    ; EAX = jmp destination address.

	mov	edx, eax			    ; EDX = EAX
	cmp	edx, ecx			    ; Compare destination address with current EIP.
	jb	@@BiggerThan			    ; Is destination address lower? if yes, jump.
	sub	edx, ecx			    ; delta address = destination address - EIP
	;neg	 edx				     ; abs(delta address)
	jmp	@DoneAbs

@@BiggerThan:
	sub	edx, ecx			    ; delta address = destination address - EIP
	neg	edx				    ; abs(delta address)

@DoneAbs:
	push	eax				    ; SAVE EAX (jump destination address)
	cmp	edx, 0x7F			    ; if (abs(delta address) <= 0x7F)
	jbe	@@Rand_Shrt_Long		    ;	    jump  @@Rand_Shrt_Long

@@Long:
	pop	eax				    ; Restore destination address
	sub	eax, 5
	sub	eax, ecx			    ; New Delta Address = destination address - EIP - instr. size.

	mov	[ecx+1], eax			    ; Insert new relocation.
	jmp	UpdateOverlapJmps

@@Rand_Shrt_Long:
	call	RandomBool			    ; if (RandomBool() == 0)
	test	eax, eax			    ;	 jump @@Shrt
	jz	@@Shrt				    ; else
	jmp	@@Long				    ;	 jump @@Long

@@Shrt:
	pop	eax				    ; Restore destination address
	sub	eax, 2				    ;
	sub	eax, ecx			    ; New Delta Address = destination address - EIP - instr. size.
	mov	[ecx+1], eax			    ; Insert new delta address in instruction.

	mov	edx, 0xEB
	mov	byte[ecx], dl			    ; Insert Short jmp.
	mov	edx, 0x90
	mov	byte[ecx+2], dl 		    ; NOP pad.
	mov	byte[ecx+3], dl
	mov	byte[ecx+4], dl
	jmp	UpdateOverlapJmps			     ; Continue parsing.


;;;; All Jcc's are assembled as long Jcc's. Same as jmps, for jumps with less delta than 0x7F
;;;; have a 50% to be assembled as short jumps.
@@Update_Jcc:
	mov	eax, [ecx+1]			    ; Get the type of long jcc in eax.
	and	eax, 0xFF
	cmp	eax, 0x8F			    ; Check if it is in the frame of all the jcc's.
	ja	UpdateOverlapJmps			     ; If not, jump back to parsing.
	cmp	eax, 0x80			    ; Check if it is in the frame of all the jcc's.
	jb	UpdateOverlapJmps			     ; If not, jump back to parsing.

	mov	eax, [ecx+2]			    ; Load position in label section to eax.
	mov	edx, [AddressToFree]
	add	edx, _Label_Section		    ; Add label section address.
	dec	eax
	shl	eax, 2				    ; (position - 1) * 4 = address of desired label
	add	edx, eax
	mov	eax, [edx]			    ; EAX = label (destination of jump).

	mov	edx, eax			    ; EDX = EAX
	cmp	edx, ecx			    ; Same absolute computation as for jmps (above).
	jb	@@Jcc_BiggerThan
	sub	edx, ecx
	jmp	@Jcc_DoneAbs

@@Jcc_BiggerThan:
	sub	edx, ecx
	neg	edx

@Jcc_DoneAbs:
	push	eax				    ; SAVE EAX (jump destination address)
	cmp	edx, 0x7F			    ; Check if it requires 1 byte to store offset.
	jbe	@@Jcc_Rand_Shrt_Long		    ; Jump if yes.

@@Jcc_Long:
	pop	eax
	sub	eax, 6
	sub	eax, ecx

	mov	[ecx+2], eax
	jmp	UpdateOverlapJmps

@@Jcc_Shrt:
	pop	eax
	sub	eax, 2
	sub	eax, ecx

	mov	edx, [ecx+1]
	sub	edx, 0x10
	mov	[ecx], edx
	mov	[ecx+1], eax

	mov	edx, 0x90
	mov	byte[ecx+2], dl
	mov	byte[ecx+3], dl
	mov	byte[ecx+4], dl
	mov	byte[ecx+5], dl
	jmp	UpdateOverlapJmps


@@Jcc_Rand_Shrt_Long:
	call	RandomBool
	test	eax, eax
	jz	@@Jcc_Shrt
	jmp	@@Jcc_Long





;;;; This sub routine checks if the First arg is
;;;; a branch instr to a label (jmp, jcc, call).
;;;; Returns EAX = 1 if it is a branch instr.
;;;; Returns EAX = 0 if it isnt.
CheckIfBranchInstr:
	mov	eax, [esp+4]
	cmp	eax, 0xE8
	je	Branch
	cmp	eax, 0xE9
	je	Branch
	cmp	eax, 0x70
	jae	Overlap_JCC
	jmp	NoBranch
Overlap_JCC:
	cmp	eax, 0x7F
	ja	NoBranch
Branch:
	mov	eax, 1
	ret	4
NoBranch:
	xor	eax, eax
	ret	4



;******************************************************************************************
;				Utilities:
;
;******************************************************************************************

;;;;	RANDOM ALGORITHM
;;;;	Seed from RDTSC
Random:
	push	edx
	push	ecx
	mov	eax, [RndSeed1]
	mov	ecx, [RndSeed2]
	add	eax, ecx
	call	RandomMod1
	xor	eax, [RndSeed1]
	mov	[RndSeed1], eax

	mov	ecx, eax
	mov	eax, [RndSeed2]
	add	[RndSeed2], ecx
	call	RandomMod2
	xor	eax, [RndSeed2]
	mov	[RndSeed2], eax
	xor	eax, [RndSeed1]
	call	RandomMod2
	pop	ecx
	pop	edx
ret

RandomMod1:
	mov	edx, eax
	and	edx, 0x1FFF
	shl	edx, 0x13
	and	eax, 0xFFFFFE
	shr	eax, 0xD
	or	eax, edx
	add	eax, ecx
ret

RandomMod2:
	mov	edx, eax
	and	edx, 1FFFFh
	shl	edx, 0Fh
	and	eax, 0FFFFE000h
	shr	eax, 11h
	or	eax, edx
	add	eax, ecx
ret

RandomBool:
	call	Random
	and	eax, 1
ret






section '.data' readable writeable
hex			 db "%X",13,10,0
AddressToFree		 dd ?
RndSeed1		 dd ?
RndSeed2		 dd ?
val			 dd ?

pEntry		PROCESSENTRY32
hSnap		dd ?
mEntry		MODULEENTRY32
mSnap		dd ?

pId		dd ?
hProc		dd ?
clientDll	dd ?

playerBase	dd ?
flags		dw ?

procName db 'csgo.exe', 0
clientName db 'client.dll', 0

jump dw 6
attack dw 6

dwLocalPlayer dd 0xAA6834
dwForceJump dd 0x4F5FCE4



section '.idata' data import readable
library kernel32, 'KERNEL32.DLL',\
		user32, 'USER32.DLL',\
		msvcrt, 'MSVCRT.DLL'
			
import	kernel32,\
		CreateToolhelp32Snapshot, 'CreateToolhelp32Snapshot',\
		ExitProcess, 'ExitProcess',\
		Module32First, 'Module32First',\
		Module32Next, 'Module32Next',\
		CloseHandle, 'CloseHandle',\
		WriteProcessMemory, 'WriteProcessMemory',\
		ReadProcessMemory, 'ReadProcessMemory',\
		OpenProcess, 'OpenProcess',\
		Process32First, 'Process32First',\
		Process32Next, 'Process32Next',\
		Sleep, 'Sleep',\
		VirtualAlloc, 'VirtualAlloc',\
		VirtualFree, 'VirtualFree',\
		GetSystemTime, 'GetSystemTime',\
		CreateFile, 'CreateFileA',\
		WriteFile, 'WriteFile'
		
import	user32,\
		FindWindow, 'FindWindowA',\
		GetWindowThreadProcessId, 'GetWindowThreadProcessId',\
		GetAsyncKeyState, 'GetAsyncKeyState'
 
import	msvcrt,\
		printf, 'printf',\
		stricmp, '_stricmp'
