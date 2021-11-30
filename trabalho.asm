	.model		small
	.stack

CR					equ		0dh
LF					equ		0ah 

	.data
FileNameSrc			db		12 dup (?)		; Nome do arquivo a ser lido
FileType			db		".res", 0		; Tipo do arquivo
FileNameDst			db		12 dup (?)		;
FileBuffer			db		10 dup (?)		; Buffer de leitura do arquivo
FileHandleSrc		dw		0				; Handler do arquivo origem
FileHandleDst		dw		0				; Handler do arquivo destino
FileNameBuffer		db		150 dup (?)

IntPointer			dw		0				;Variável Ponteiro para o IntBuffer
FracPointer			dw		0				;Variável Ponteiro para o FracBuffer
IndexCounter		dw		0				;Índice para contagem para o enderaçamento do IntVectorBuffer e FracVectorBuffer
Counter				db		0				;Contador de números válidos
AuxCounter			dw		0				;Contador auxiliar de números válidos em DW
Counter100			db		0				;Contadores de algarismos do contador para a escrita
Counter010			db		0
Counter001			db		0
IntVectorBuffer		dw		200 dup (?)		;Vetor Buffer da parte inteira dos números válidos
FracVectorBuffer	dw		200 dup (?)		;Vetor Buffer da parte fracionária dos números válidos
IntBuffer			db		4	dup (?)		;Buffer para a string da parte inteira 
FracBuffer			db		3	dup (?)		;Buffer para a string da parte fracionária
LastCharacterFlag	db		0				
HasNumberFlag		db		0
NumberValityFlag	db		0
IntFlag				db		1				;Flags para verificar se estamos analisando um inteiro ou fracionário
FracFlag			db		0				
LineFlag			db		0				;Flag para verificar a validade da linha 0 - Válida / 1 - Inválida ou Fim da Linha
SumInt				dw		0				;Resultado da soma com parte inteira e fracionária
SumFrac				dw		0
MeanInt				dw		0				;;Resultado da média com parte inteira e fracionária
MeanFrac			dw		0
MeantIntFrac		dw		0
MeanDigitCounter	dw		0			

MsgPedeArquivoSrc	db	"Nome do arquivo: ", 0
MsgPedeArquivoDst	db	"Nome do arquivo destino: ", 0
MsgErroOpenFile		db	"Erro na abertura do arquivo.", CR, LF, 0
MsgErroCreateFile	db	"Erro na criacao do arquivo.", CR, LF, 0
MsgErroReadFile		db	"Erro na leitura do arquivo.", CR, LF, 0
MsgErroWriteFile	db	"Erro na escrita do arquivo.", CR, LF, 0
MsgCRLF				db	CR, LF, 0

MeanString			db		6 dup (?)
IntString			db		4 dup (?)				;Variáveis para a função Sprintf
FracString			db		4 dup (?)				;Variáveis para a função Sprintf
IndexString			dw		0
sw_n				dw	0
sw_f				db	0
sw_m				dw	0
BufferWRWORD		db		10 dup (?)				;Variável para a função printf_w

MAXSTRING			equ		200
String				db		MAXSTRING dup (?)		; Usado na funcao gets


	
	.code
	.startup    
;--------------------------------------------------------------------
;Função main
;--------------------------------------------------------------------
	;GetFileName();
	call	GetFileNameSrc
	call	FileNameOutput


	;if (fopen(FileNameSrc)) {
	;	printf("Erro na abertura do arquivo.\r\n")
	;	exit(1)
	;}
	;FileHandleSrc = BX
	lea		dx,FileNameSrc
	call	fopen
	mov		FileHandleSrc,bx
	jnc		Continue1
	lea		bx, MsgErroOpenFile
	call	printf_s
	.exit	1

Continue1:
	;if (fcreate(FileNameDst)) {
	;	fclose(FileHandleSrc);
	;	printf("Erro na criacao do arquivo.\r\n")
	;	exit(1)
	;}
	;FileHandleDst = BX
	lea		dx,FileNameDst
	call	fcreate
	mov		FileHandleDst,bx
	jnc		Continue2
	mov		bx,FileHandleSrc
	call	fclose
	lea		bx, MsgErroCreateFile
	call	printf_s
	.exit	1

Continue2:
	;do {
	;	if ( (CF,DL,AX = getChar(FileHandleSrc)) ) {
	;		printf("");
	;		fclose(FileHandleSrc)
	;		fclose(FileHandleDst)
	;		exit(1)
	;	}
	mov		bx,FileHandleSrc							;PEGA O CARACTERE DO FILEHANDLESRC E CHAMA GETCHAR
	call	getChar
	jnc		Continue3
	lea		bx, MsgErroReadFile
	call	printf_s
	mov		bx,FileHandleSrc
	call	fclose
	mov		bx,FileHandleDst
	call	fclose
	.exit	1

Continue3:

	;	if (AX==0) break;
	cmp		ax,0
	jz		Set_LastCharacterFlag
	cmp		dl,CR
	jz		end_Line
	cmp		dl,LF
	jz		Continue2
	cmp		LineFlag,1				;Se a LineFlag estiver ligada, logo a linha é inválida, pula para o próximo caractere até achar o CR ou LF
	jz		Continue2
	cmp		dl,20h					;dl - 20h(SPACE)
	jz		Continue2				
	cmp		dl,9h					; dl - 9h(TAB)
	jz		Continue2
	cmp		dl,','
	jz		Set_NumberFlag
	cmp		dl,'.'
	jz		Set_NumberFlag
	cmp		dl,'0'
	jb		Set_InvalidLineFlag
	cmp		dl,'9'
	ja		Set_InvalidLineFlag
	jmp		Set_Number

Set_LastCharacterFlag:
	mov		LastCharacterFlag,1
	jmp		end_Line

Set_InvalidLineFlag:
	mov		LineFlag,1
	jmp		Continue2

Set_NumberFlag:
	cmp		IntFlag,0					;Checa se a flag do inteiro está ligada
	jz		Set_InvalidLineFlag			;Caso não esteja estamos lidando com um fracionário logo a linha é inválida
	mov		IntFlag,0					;Desliga a flag do inteiro
	mov		FracFlag,1					;Liga a flag do fracionário
	jmp		Continue2					

end_Line:
	cmp		HasNumberFlag,0				;Checa se a linha tem algum número a ser validado
	jz		InitializeNewLine
	call 	CheckNumberVality			;Checa a válidade do número armazenado na linha e armazena no vetor de números
	cmp		NumberValityFlag,1
	jz		InitializeWrite
InitializeNewLine:
	mov		NumberValityFlag,0
	mov		HasNumberFlag,0
	mov		LineFlag,0					;Avança para a próxima linha e considera ela inicialmente válida
	mov		IntFlag,1					;Incializa as flags dos números
	mov		FracFlag,0	
	mov		IntPointer,0				;Inicializa os ponteiros com o início do Buffer String
	mov		FracPointer,0
	cmp		LastCharacterFlag,1
	mov		Counter001,0
	mov		Counter010,0
	mov		Counter100,0
	jz		MidJumpFunctionWrite
	jmp		Continue2					;Ao fim da linha pula para a escrita do próximo caractere 

Set_Number:
	mov		HasNumberFlag,1
	cmp		IntFlag,1
	jz		Set_Int
	cmp		FracFlag,1
	jz		Set_Frac
	jmp		Set_InvalidLineFlag

Set_Int:
	lea		bx,IntBuffer
	add		bx,IntPointer
	mov		byte ptr[bx],dl
	inc		IntPointer
	inc		bx
	mov		byte ptr[bx],0h
	jmp		Continue2

	

Set_Frac:
	lea		bx,FracBuffer
	add		bx,FracPointer
	mov		byte ptr[bx],dl
	inc		FracPointer
	inc		bx
	mov		byte ptr[bx],0h
	jmp		Continue2

MidJumpFunctionWrite:
	jmp		FunctionWrite


InitializeWrite:
	call 	ConvertCounter					;Escreve a string com os digítos 000 - 
	mov		bx,FileHandleDst
	mov		dl,'0'
	add		dl,Counter100
	call	setChar
	mov		dl,'0'
	add		dl,Counter010
	call	setChar
	mov		dl,'0'
	add		dl,Counter001
	call	setChar
	mov		dl,' '
	call	setChar
	mov		dl,'-'
	call	setChar


	lea		bx, IntVectorBuffer			;Checa se a quantidade de algarismos na parte inteira para o controle de vírgula e espaços
	add		bx, IndexCounter
	sub		bx, 2
	mov		ax,[bx]
	cmp		ax,99
	ja		SP_one
	cmp		ax,9
	ja		SP_two
	mov		dl,' '
	mov		bx,FileHandleDst
	call	setChar
SP_two:
	mov		dl,' '
	mov		bx,FileHandleDst
	call	setChar
SP_one:
	mov		dl,' '
	mov		bx,FileHandleDst
	call	setChar
	jmp		NumberWrite

NumberWrite:
	lea		bx, IntVectorBuffer			;Transfere o valor do vetor para o Ax
	add		bx, IndexCounter
	sub		bx, 2
	mov		ax,[bx]
	lea		bx,IntString				;Converte o inteiro de 16bits em uma string
	call	sprintf_w
	mov		IndexString,0

SetIntString:	;*****************
	lea		bx, IntString				;Escreve a String do Número inteiro no arquivo até encontrar \0
	add		bx, IndexString
	mov		dl,[bx]
	cmp		dl,0
	jz		NumberWrite2
	mov		bx,FileHandleDst
	call	setChar
	inc		IndexString
	jmp		SetIntString



NumberWrite2:
	mov		bx,FileHandleDst
	mov		dl,','
	call	setChar

	lea		bx, FracVectorBuffer			;Transfere o valor do vetor para o Ax
	add		bx, IndexCounter
	sub		bx, 2
	mov		ax,[bx]
	lea		bx,FracString			;Converte o inteiro de 16bits em uma string
	call	sprintf_w
	mov		IndexString,0

SetFracString:	;******************
	lea		bx, FracString				;Escreve a String do Número inteiro no arquivo até encontrar \0	
	add		bx, IndexString
	mov		dl,[bx]
	cmp		dl,0
	jz		NumberWrite3
	mov		bx,FileHandleDst
	call	setChar
	inc		IndexString
	jmp		SetFracString

MidJumpInitializeNewLine:
	jmp		InitializeNewLine

NumberWrite3:
	mov		bx,FileHandleDst
	mov		dl,' '
	call	setChar
	mov		dl,'-'
	call	setChar
	mov		dl,' '
	call	setChar

	lea		bx, IntVectorBuffer			;Transfere o valor do vetor para o Ax
	add		bx, IndexCounter
	sub		bx, 2
	mov		ax,[bx]
	call	Parity
	add		dl, '0'
	mov		bx,FileHandleDst
	call	setChar

	lea		bx, FracVectorBuffer		;Transfere o valor do vetor para o Ax
	add		bx, IndexCounter
	sub		bx, 2
	mov		ax,[bx]
	call	Parity
	add		dl, '0'
	mov		bx,FileHandleDst
	call	setChar

	mov		bx,FileHandleDst
	mov		dl,CR
	call	setChar
	mov		dl,LF
	call	setChar
	jnc		MidJumpInitializeNewLine
	jmp		Continue4

FunctionWrite:
	mov		bx,FileHandleDst
	mov		dl,'S'
	call	setChar
	mov		dl,'O'
	call	setChar
	mov		dl,'M'
	call	setChar
	mov		dl,'A'
	call	setChar
	mov		dl,':'
	call	setChar
	mov		dl,' '
	call	setChar
	call	Sum
	mov		ax,SumInt
	lea		bx, IntString
	call	sprintf_w
	mov		IndexString,0

SetFunctionIntString:	;*****************
	lea		bx, IntString				;Escreve a String do Número inteiro no arquivo até encontrar \0
	add		bx, IndexString
	mov		dl,[bx]
	cmp		dl,0
	jz		FunctionWrite2
	mov		bx,FileHandleDst
	call	setChar
	inc		IndexString
	jmp		SetFunctionIntString

FunctionWrite2:
	mov		bx,FileHandleDst
	mov		dl,','
	call	setChar
	mov		ax,SumFrac
	lea		bx, FracString
	call	sprintf_w
	mov		IndexString,0

SetFunctionFracString:	;*****************
	lea		bx, FracString				;Escreve a String do Número inteiro no arquivo até encontrar \0
	add		bx, IndexString
	mov		dl,[bx]
	cmp		dl,0
	jz		FunctionWrite3
	mov		bx,FileHandleDst
	call	setChar
	inc		IndexString
	jmp		SetFunctionFracString

FunctionWrite3:
	mov		bx,FileHandleDst
	mov		dl,CR
	call	setChar
	mov		dl,LF
	call	setChar
	mov		dl,'M'
	call	setChar
	mov		dl,'E'
	call	setChar
	mov		dl,'D'
	call	setChar
	mov		dl,'I'
	call	setChar
	mov		dl,'A'
	call	setChar
	mov		dl,':'
	call	setChar
	mov		dl,' '
	call	setChar


	
	call	Mean
	mov		ax,MeantIntFrac
	
	cmp		ax,999
	jbe		Mean3digits
	cmp		ax,9999
	jbe		Mean4digits
	cmp		ax,9999
	jae		Mean5digits
	jmp		MeanNumberWrite

Mean3digits:
	mov		MeanDigitCounter,3
	jmp		MeanNumberWrite
Mean4digits:
	mov		MeanDigitCounter,4
	jmp		MeanNumberWrite
Mean5digits:
	mov		MeanDigitCounter,5

MeanNumberWrite:
	mov		ax,MeantIntFrac
	lea		bx, MeanString
	call	sprintf_w
	mov		IndexString,0

MeanIntWrite:	
	cmp		MeanDigitCounter,2
	jz		FunctionWrite4
	lea		bx, MeanString				;Escreve a String do Número inteiro no arquivo até o contador chegar a ter somente 2 digitos sobrando
	add		bx, IndexString
	mov		dl,[bx]
	mov		bx,FileHandleDst
	call	setChar
	dec		MeanDigitCounter
	inc		IndexString
	jmp		MeanIntWrite

FunctionWrite4:
	mov		bx,FileHandleDst
	mov		dl,','
	call	setChar

MeanFracWrite:	
	lea		bx, MeanString				;Escreve a String do Número inteiro no arquivo até o contador chegar a 0 digitos sobrando
	add		bx, IndexString
	mov		dl,[bx]
	cmp		dl,0
	jz		FunctionWrite5
	mov		bx,FileHandleDst
	call	setChar
	inc		IndexString
	jmp		MeanFracWrite


FunctionWrite5:
	mov		bx,FileHandleDst
	mov		dl,CR
	call	setChar
	mov		dl,LF
	call	setChar
	jnc		EndFile



Continue4:
	;	if ( setChar(FileHandleDst, DL) == 0) continue;
	;mov		bx,FileHandleDst
	;call	setChar
	;jnc		MidJumpContinue2
	;	printf ("Erro na escrita....;)")
	;	fclose(FileHandleSrc)
	;	fclose(FileHandleDst)
	;	exit(1)
	lea		bx, MsgErroWriteFile
	call	printf_s
	mov		bx,FileHandleSrc		; Fecha arquivo origem
	call	fclose
	mov		bx,FileHandleDst		; Fecha arquivo destino
	call	fclose
	.exit	1
	
	;} while(1);
		
EndFile:
	;fclose(FileHandleSrc)
	;fclose(FileHandleDst)
	;exit(0)
	mov		bx,FileHandleSrc	; Fecha arquivo origem
	call	fclose
	mov		bx,FileHandleDst	; Fecha arquivo destino
	call	fclose
	.exit	0


;--------------------------------------------------------------------
;Funcao Pede o nome do arquivo de origem salva-o em FileNameSrc
;--------------------------------------------------------------------
GetFileNameSrc	proc	near
	;printf("Nome do arquivo origem: ")
	lea		bx, MsgPedeArquivoSrc
	call	printf_s

	;gets(FileNameSrc);
	lea		bx, FileNameSrc
	call	gets
	
	;printf("\r\n")
	lea		bx, MsgCRLF
	call	printf_s
	
	ret
GetFileNameSrc	endp


;--------------------------------------------------------------------
;Fun��o	Abre o arquivo cujo nome est� no string apontado por DX
;		boolean fopen(char *FileName -> DX)
;Entra: DX -> ponteiro para o string com o nome do arquivo
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fopen	proc	near
	mov		al,0
	mov		ah,3dh
	int		21h
	mov		bx,ax
	ret
fopen	endp

;--------------------------------------------------------------------
;Fun��o Cria o arquivo cujo nome est� no string apontado por DX
;		boolean fcreate(char *FileName -> DX)
;Sai:   BX -> handle do arquivo
;       CF -> 0, se OK
;--------------------------------------------------------------------
fcreate	proc	near
	mov		cx,0
	mov		ah,3ch
	int		21h
	mov		bx,ax
	ret
fcreate	endp

;--------------------------------------------------------------------
;Entra:	BX -> file handle
;Sai:	CF -> "0" se OK
;--------------------------------------------------------------------
fclose	proc	near
	mov		ah,3eh
	int		21h
	ret
fclose	endp

;--------------------------------------------------------------------
;Função	Le um caractere do arquivo identificado pelo HANLDE BX
;		getChar(handle->BX)
;Entra: BX -> file handle
;Sai:   dl -> caractere
;		AX -> numero de caracteres lidos
;		CF -> "0" se leitura ok
;--------------------------------------------------------------------
getChar	proc	near
	mov		ah,3fh
	mov		cx,1
	lea		dx,FileBuffer
	int		21h
	mov		dl,FileBuffer
	ret
getChar	endp
		
;--------------------------------------------------------------------
;Entra: BX -> file handle
;       dl -> caractere
;Sai:   AX -> numero de caracteres escritos
;		CF -> "0" se escrita ok
;--------------------------------------------------------------------
setChar	proc	near
	mov		ah,40h
	mov		cx,1
	mov		FileBuffer,dl
	lea		dx,FileBuffer
	int		21h
	ret
setChar	endp	

;
;--------------------------------------------------------------------
;Funcao Le um string do teclado e coloca no buffer apontado por BX
;		gets(char *s -> bx)
;--------------------------------------------------------------------
gets	proc	near
	push	bx

	mov		ah,0ah						; L� uma linha do teclado
	lea		dx,String
	mov		byte ptr String, MAXSTRING-4	; 2 caracteres no inicio e um eventual CR LF no final
	int		21h

	lea		si,String+2					; Copia do buffer de teclado para o FileName
	pop		di
	mov		cl,String+1
	mov		ch,0
	mov		ax,ds						; Ajusta ES=DS para poder usar o MOVSB
	mov		es,ax
	rep 	movsb

	mov		byte ptr es:[di],0			; Coloca marca de fim de string
	ret
gets	endp

;--------------------------------------------------------------------
;	Função que escreve uma string na tela.
;       printf_s(char *s -> BX)
;--------------------------------------------------------------------
printf_s	proc	near
	mov		dl,[bx]
	cmp		dl,0
	je		ps_1

	push	bx
	mov		ah,2
	int		21H
	pop		bx

	inc		bx		
	jmp		printf_s
		
ps_1:
	ret

printf_s	endp

;--------------------------------------------------------------------
;Função: Escreve o valor de AX na tela
;		printf("%
;--------------------------------------------------------------------
printf_w	proc	near
	; sprintf_w(AX, BufferWRWORD)
	lea		bx,BufferWRWORD
	call	sprintf_w
	
	; printf_s(BufferWRWORD)
	lea		bx,BufferWRWORD
	call	printf_s
	
	ret
printf_w	endp

;
;--------------------------------------------------------------------
;Função: Converte um inteiro (n) para (string)
;		 sprintf(string, "%d", n)
;Associação de variaveis com registradores e memória
;	string	-> bx
;	k		-> cx
;	m		-> sw_m dw
;	f		-> sw_f db
;	n		-> sw_n	dw
;--------------------------------------------------------------------

sprintf_w	proc	near

;void sprintf_w(char *string, WORD n) {
	mov		sw_n,ax

;	k=5;
	mov		cx,5
	
;	m=10000;
	mov		sw_m,10000
	
;	f=0;
	mov		sw_f,0
	
;	do {
sw_do:

;		quociente = n / m : resto = n % m;	// Usar instru��o DIV
	mov		dx,0
	mov		ax,sw_n
	div		sw_m
	
;		if (quociente || f) {
;			*string++ = quociente+'0'
;			f = 1;
;		}
	cmp		al,0
	jne		sw_store
	cmp		sw_f,0
	je		sw_continue
sw_store:
	add		al,'0'
	mov		[bx],al
	inc		bx
	
	mov		sw_f,1
sw_continue:
	
;		n = resto;
	mov		sw_n,dx
	
;		m = m/10;
	mov		dx,0
	mov		ax,sw_m
	mov		bp,10
	div		bp
	mov		sw_m,ax
	
;		--k;
	dec		cx
	
;	} while(k);
	cmp		cx,0
	jnz		sw_do

;	if (!f)
;		*string++ = '0';
	cmp		sw_f,0
	jnz		sw_continua2
	mov		[bx],'0'
	inc		bx
sw_continua2:


;	*string = '\0';
	mov		byte ptr[bx],0
		
;}
	ret
		
sprintf_w	endp

;--------------------------------------------------------------------
;   Checa se FileName tem extensão em txt e converte para .txt
;--------------------------------------------------------------------
FileNameOutput proc	near
	lea		di, FileNameDst
	lea		si, FileNameSrc
	mov		cx, 12
	rep 	movsb

	lea		di, FileNameDst
	mov		cx, 12
	cld						;Limpa o Direction Flag
	mov 	al,'.'
	repne	scasb
	dec		di	
	jne		write_extension
	jmp		end_FileNameOutput
	

write_extension:
	lea		si, FileType
	mov		cx, 5
	rep		movsb
	
	

end_FileNameOutput:
	ret
FileNameOutput endp

;--------------------------------------------------------------------
;   Função que checa se o número é válido e armazena ele no vetor de
;	números válidos
;--------------------------------------------------------------------
;ClearBuffer proc	near
;	mov			cx,IntPointer

;ClearLoop1:
;	lea			bx,IntBuffer
;	add			bx,cx
;	mov			byte ptr[bx],0
;	dec			cx
;	cmp			cx,0
;	jz			ClearFrac
;	jmp			ClearLoop1

;ClearFrac:
;	mov			cx,FracPointer

;ClearLoop2:
;	lea			bx,FracBuffer
;	add			bx,cx
;	mov			byte ptr[bx],0
;	dec			cx
;	cmp			cx,0
;	jz			end_ClearBuffer
;	jmp			ClearLoop2
;
;end_ClearBuffer:
;	mov		cx,0
;	ret
;ClearBuffer endp



;--------------------------------------------------------------------
;   Função que checa se o número é válido e armazena ele no vetor de
;	números válidos
;--------------------------------------------------------------------
CheckNumberVality proc	near
	lea			bx,IntBuffer
	call		atoi
	cmp			ax,499
	ja			InvalidNumber

	lea			bx,FracBuffer
	call		atoi
	cmp			ax,99
	ja			InvalidNumber

	lea			bx,FracVectorBuffer
	add			bx,IndexCounter
	mov			[bx],ax

	lea			bx,IntBuffer
	call		atoi
	lea			bx,IntVectorBuffer
	add			bx,IndexCounter
	mov			[bx],ax

	add			IndexCounter,2
	add			Counter,1
	add			AuxCounter,1
	mov			NumberValityFlag,1
	jmp			end_CheckNumberVality
	
InvalidNumber:
	mov		NumberValityFlag,0

end_CheckNumberVality:
	ret
CheckNumberVality endp


;--------------------------------------------------------------------
;   Função que cálcula a paridade dos números armazenados e armazena
;	a paridade da parte inteira e fracionada
;	
;	dl -> Resultado da paridade (0/1)
;	ax -> Número a ser verificado
;--------------------------------------------------------------------
Parity proc	near
		mov		dx, 0h
Loop_shift:	
	shr 	ax, 1
	jc      Invert_dl	
	jmp		Par_test

Invert_dl:
	not     dl
	jmp		Par_test

Par_test:
	cmp		ax, 0h
	je		Continue_par
	jmp		Loop_shift

Continue_par:
	cmp		dl, 255
	je     	Switch_FF_to_1
	jmp     End_shift

End_shift:	
	ret

Switch_FF_to_1:
	mov		dl, 1h
	ret
	
Parity endp


;--------------------------------------------------------------------
;   Função que cálcula a soma dos números armazenados e armazena sua
;	inteira e fracionada
;--------------------------------------------------------------------
Sum proc	near
	mov		cx,IndexCounter
	lea		bx,IntVectorBuffer
	mov		ax,[bx]
	mov		SumInt,ax

SumIntLoop:
	add		bx,2
	add		ax,[bx]
	mov		SumInt,ax
	sub		cx,2
	cmp		cx,0
	jnz		SumIntLoop

	mov		cx,IndexCounter
	lea		bx,FracVectorBuffer
	mov		ax,[bx]
	mov		SumFrac,ax

SumFracLoop:
	add		bx,2
	add		ax,[bx]
	cmp		ax,99
	ja		SumCarry
SumFracLoop2:
	mov		SumFrac,ax
	sub		cx,2
	cmp		cx,0
	jz		end_Sum
	jmp		SumFracLoop

SumCarry:
	sub		ax,100
	add		SumInt,1
	jmp		SumFracLoop2

end_Sum:
	ret
Sum endp


;--------------------------------------------------------------------
;********************************************************************
;   Função que cálcula a média dos números armazenados e armazena sua
;	parte inteira e fracionada
;--------------------------------------------------------------------
Mean proc	near
	mov		dx,0
	mov		ax,SumInt
	mov		bx,100
	mul		bx

	add		ax,SumFrac
	mov		bx,AuxCounter
	div		bx
	mov		MeantIntFrac,ax

	mov		ax,dx
	shl		ax,1
	cmp		ax,dx
	jae		rounding
	jmp		end_Mean

rounding:
	add		MeantIntFrac,1

end_Mean:
	ret
Mean endp

;--------------------------------------------------------------------
;   Função que cálcula o contador para o formato 000 e armazena os
;	contadores individuais para a escrita
;--------------------------------------------------------------------
ConvertCounter proc	near
		mov		al,Counter
		cmp		al,99
		ja		Inc_100
		cmp		al,9
		ja		Inc_010
		jmp		Inc_001
Inc_100:
		add		Counter100,1			;Coloca 100 que é o valor máximo
		jmp		end_ConvertCounter

Inc_010:
		mov		Counter001,0
		inc		Counter010
		dec		al
		cmp		al,0
		jz		end_ConvertCounter
Inc_001:
		inc		Counter001
		cmp		Counter001,9
		ja		Inc_010
		dec		al
		cmp		al,0
		jz		end_ConvertCounter
		jmp		Inc_001


end_ConvertCounter:
	ret
ConvertCounter endp

;--------------------------------------------------------------------
;Função:Converte um ASCII-DECIMAL para HEXA
;Entra: (S) -> DS:BX -> Ponteiro para o string de origem
;Sai:	(A) -> AX -> Valor "Hex" resultante
;Algoritmo:
;	A = 0;
;	while (*S!='\0') {
;		A = 10 * A + (*S - '0')
;		++S;
;	}
;	return
;--------------------------------------------------------------------
atoi	proc near

		; A = 0;
		mov		ax,0
		
atoi_2:
		; while (*S!='\0') {
		cmp		byte ptr[bx], 0
		jz		atoi_1

		; 	A = 10 * A
		mov		cx,10
		mul		cx

		; 	A = A + *S
		mov		ch,0
		mov		cl,[bx]
		add		ax,cx

		; 	A = A - '0'
		sub		ax,'0'

		; 	++S
		inc		bx
		
		;}
		jmp		atoi_2

atoi_1:
		; return
		ret

atoi	endp


;--------------------------------------------------------------------
;   Fim do programa.
;--------------------------------------------------------------------
		end