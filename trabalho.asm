	.model		small
	.stack

CR		equ		0dh
LF		equ		0ah 

	.data
FileNameSrc			db		12 dup (?)		; Nome do arquivo a ser lido
FileType			db		".res", 0		; Tipo do arquivo
FileNameDst			db		12 dup (?)		;
FileBuffer			db		10 dup (?)		; Buffer de leitura do arquivo
FileHandleSrc		dw		0				; Handler do arquivo origem
FileHandleDst		dw		0				; Handler do arquivo destino
FileNameBuffer		db		150 dup (?)

pointer				dw		0				;Variável Ponteiro 
IntCounter			dw		0				;Contador de números inteiros armazenados
FracCounter			dw		0				;Contador de números fracionados armazenados
IntBuffer			dw		200 dup (?)		; Buffer de leitura do arquivo
FracBuffer			dw		200 dup (?)		; Buffer de leitura do arquivo

OutputDash			db 	" - "
MsgPedeArquivoSrc	db	"Nome do arquivo: ", 0
MsgPedeArquivoDst	db	"Nome do arquivo destino: ", 0
MsgErroOpenFile		db	"Erro na abertura do arquivo.", CR, LF, 0
MsgErroCreateFile	db	"Erro na criacao do arquivo.", CR, LF, 0
MsgErroReadFile		db	"Erro na leitura do arquivo.", CR, LF, 0
MsgErroWriteFile	db	"Erro na escrita do arquivo.", CR, LF, 0
MsgCRLF				db	CR, LF, 0

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
	mov		bx,FileHandleSrc							;PEGA O CARACTERE DO FILEHANDLESRC E CHANA GETCHAR
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
	jz		EndFile
	
	;	dl = toUpper(dl)
	cmp		dl,'a'
	jb		Continue4
	cmp		dl,'z'
	ja		Continue4
	sub		dl,20h		

Continue4:

	;	if ( setChar(FileHandleDst, DL) == 0) continue;
	mov		bx,FileHandleDst
	call	setChar
	jnc		Continue2

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
;Funcao Pede o nome do arquivo de destino salva-o em FileNameDst
;--------------------------------------------------------------------
GetFileNameDst	proc	near
	;printf("Nome do arquivo destino: ");
	lea		bx, MsgPedeArquivoDst
	call	printf_s
	
	;gets(FileNameDst);
	lea		bx, FileNameDst
	call	gets
	
	;printf("\r\n")
	lea		bx, MsgCRLF
	call	printf_s
	
	ret
GetFileNameDst	endp

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
;Fun��o	Le um caractere do arquivo identificado pelo HANLDE BX
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
;   Checa se FileName tem extensão em txt e converte para .txt
;--------------------------------------------------------------------
FileNameOutput proc	near
	lea		di, FileNameDst
	lea		si, FileNameSrc
	mov		cx, 12
	rep 	movsb

	lea		bx, FileNameDst				;DEBBUG
	call	printf_s

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
	

	lea		bx, FileNameDst				;DEBBUG
	call	printf_s
	

end_FileNameOutput:
	ret
FileNameOutput endp



;--------------------------------------------------------------------
;Fun��o:Converte um ASCII-DECIMAL para HEXA
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
