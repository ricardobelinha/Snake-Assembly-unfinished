;------------------------------------------------------------------------
;
;	Base para TRABALHO PRATICO - TECNOLOGIAS e ARQUITECTURAS de COMPUTADORES
;   
;	ANO LECTIVO 2018/2019
;
;
;	
;
;		press ESC to exit
;------------------------------------------------------------------------
; MACROS
;------------------------------------------------------------------------
;MACRO GOTO_XY
; COLOCA O CURSOR NA POSIÇÃO POS_X,POS_Y
;	POS_X -> COLUNA
;	POS_Y -> LINHA
;------------------------------------------------------------------------
GOTO_XY		MACRO	POS_X,POS_Y
			MOV	AH,02H
			MOV	BH,0
			MOV	DL,POS_X
			MOV	DH,POS_Y
			INT	10H
ENDM

; MOSTRA - Faz o display de uma string terminada em $
;---------------------------------------------------------------------------
MOSTRA MACRO STR 
			MOV AH,09H
			LEA DX,STR 
			INT 21H
ENDM
; FIM DAS MACROS

;---------------------------------------------------------------------------


.8086
.model smALl
.stack 2048h

PILHA	SEGMENT PARA STACK 'STACK'
		db 2048 dup(?)
PILHA	ENDS
	

DSEG    SEGMENT PARA PUBLIC 'DATA'

		POS_Y					db		10	; a linha pode ir de [1 .. 25]
		POS_X					db		40	; POS_X pode ir [1..80]	
		POS_Y_ANT				db		5	; Posição anterior de y
		POS_X_ANT				db		10	; Posição anterior de x
	
	
		PASSA_T					dw		0
		PASSA_T_ANT				dw		0
		DIRECAO					db		3
		
		CENTESIMOS				dw 		0
		FACTOR					db		100
		METADE_FACTOR			db		?
		RESTO					db		0
						
		ERRO_ABRIR       		db      'Erro ao tentar abrir o ficheiro$'
		ERRO_LER_MSG    		db      'Erro ao tentar ler do ficheiro$'
		ERRO_FECHAR      		db      'Erro ao tentar fechar o ficheiro$'
		
		FICH         			db      'moldura.TXT', 0
		MENU_PRINCIPAL			db 		'princ.TXT', 0 ; 0 - Menu iniciAL / 1 - Jogo / 2 - Estatistica Menu / 3 - HISTORICO / 4 - Estatistica / 5 - Nivel de Jogo
		MENU_ESTATISTICA		db		'menu.TXT', 0
		FICHEIRO_ESTATISTICA	db		'stats.TXT', 0
		FICHEIRO_HISTORICO		db		'hist.TXT', 0
		MENU_DIFICULDADE		db 		'nivel.TXT', 0
		NIVEL_1					db		'Lesma$'
		NIVEL_2					db		'Lebre$'
		NIVEL_3					db		'Hiena$'
		NIVEL_4					db		'Chita$'
		QUAL_MENU				db		0
		PONTUACAO				dw		0
		HANDLE_FICH      		dw      0
		ultimo_num_aleat 		dw 		0
		CAR_FICH      			db      ?
DSEG    ENDS

CSEG    SEGMENT PARA PUBLIC 'CODE'
	ASSUME  CS:CSEG, DS:DSEG, SS:PILHA
	


;********************************************************************************



PASSA_TEMPO PROC	
		MOV 	AH, 2CH             				; Buscar a hORAS
		INT		21H                 
		
 		XOR 	AX,AX
		MOV 	AL, DL              				; CENTESIMOS de segundo para AX		
		MOV 	CENTESIMOS, AX
	
		MOV 	BL, FACTOR							; define velocidade da snake (100; 50; 33; 25; 20; 10)
		DIV 	BL
		MOV 	RESTO, AH
		MOV 	AL, FACTOR
		MOV 	AH, 0
		MOV 	BL, 2
		DIV 	BL
		MOV 	METADE_FACTOR, AL
		MOV 	AL, RESTO
		MOV 	AH, 0
		MOV 	BL, METADE_FACTOR					; deve ficar sempre com metade do vALor iniciAL
		MOV 	AH, 0
		CMP 	AX, BX
		JBE 	MENOR
		MOV 	AX, 1
		MOV 	PASSA_T, AX	
		JMP 	FIM_PASSA		
MENOR:		
		MOV 	AX,0
		MOV 	PASSA_T, AX		
FIM_PASSA:	 
 		RET 
PASSA_TEMPO   ENDP 




;********************************************************************************	



IMP_FICH	PROC
		;abre FICHeiro
        MOV 	AH, 3dh								; vamos abrir FICHeiro para leitura 
        MOV 	AL, 0								; tipo de FICHeiro
		CMP		QUAL_MENU, 0
		JE 		PRIMEIRO_MENU
		CMP 	QUAL_MENU, 1
		JE 		SEGUNDO_MENU
		CMP 	QUAL_MENU, 2
		JE 		TERCEIRO_MENU
		CMP 	QUAL_MENU, 3
		JE 		QUARTO_MENU
		CMP 	QUAL_MENU, 4
		JE 		QUINTO_MENU
		CMP		QUAL_MENU, 5
		JE		SEXTO_MENU
		MOV		AH, 4Ch
		INT		21h
PRIMEIRO_MENU:
        LEA     DX, MENU_PRINCIPAL					; nome do FICHeiro
		JMP		JA_LEU
SEGUNDO_MENU:
        LEA     DX, MENU_ESTATISTICA				; nome do FICHeiro
		JMP		JA_LEU
TERCEIRO_MENU:
        LEA     DX, FICH							; nome do FICHeiro
		JMP		JA_LEU
QUARTO_MENU:
        LEA     DX, FICHEIRO_HISTORICO				; nome do FICHeiro
		JMP		JA_LEU
QUINTO_MENU:
        LEA     DX, FICHEIRO_ESTATISTICA			; nome do FICHeiro
		JMP		JA_LEU
SEXTO_MENU:
		LEA 	DX, MENU_DIFICULDADE
JA_LEU:
		INT     21h									; abre para leitura 
        JC      ERRO_ABRIR_LABEL					; pode aconter erro a abrir o FICHeiro 
        MOV     HANDLE_FICH, AX						; AX devolve o HanDLe para o FICHeiro 
        JMP     LER_CICLO							; depois de abero vamos ler o FICHeiro 

ERRO_ABRIR_LABEL:
        MOV     AH, 09h
        LEA     DX, ERRO_ABRIR
        INT     21h
        JMP     SAI

LER_CICLO:
        MOV     AH, 3fh								; indica que vai ser lido um FICHeiro 
        MOV     BX, HANDLE_FICH						; BX deve conter o HanDLe do FICHeiro previamente aberto 
        MOV     CX, 1								; numero de bytes a ler 
        LEA     DX, CAR_FICH						; vai ler para o locAL de memoria apontado por DX (CAR_FICH)
        INT     21h									; faz efectivamente a leitura
		JC	    ERRO_LER							; se carry é porque aconteceu um erro
		CMP	    AX, 0								; EOF?	verifica se já estamos no FIM do FICHeiro 
		JE	    FECHA_FICHEIRO						; se EOF fecha o FICHeiro 
        MOV     AH, 02h								; coloca o caracter no ecran
		MOV	    DL, CAR_FICH						; este é o caracter a enviar para o ecran
		INT	    21h									; imprime no ecran
		JMP	    LER_CICLO							; continua a ler o FICHeiro

ERRO_LER:
        MOV     AH, 09h
        LEA     DX, ERRO_LER_MSG
        INT     21h

FECHA_FICHEIRO:										; vamos fechar o FICHeiro 
        MOV     AH, 3eh
        MOV     BX, HANDLE_FICH
        INT     21h
        jnc     SAI

        MOV     AH, 09h								; o FICHeiro pode não fechar correctamente
        LEA     DX, ERRO_FECHAR
        INT     21h
SAI:	  RET
IMP_FICH	endp

;########################################################################

;********************************************************************************
;ROTINA PARA APAGAR ECRAN

APAGA_ECRAN	PROC
		PUSH 	BX
		PUSH 	AX
		PUSH 	CX
		PUSH 	SI
		XOR		BX, BX
		MOV		CX, 24*80
		MOV 	BX, 160
		MOV 	SI, BX
APAGA:	
		MOV		AL, ' '
		MOV		BYTE PTR ES:[BX],AL
		MOV		BYTE PTR ES:[BX+1],7
		INC		BX
		INC 	BX
		INC 	SI
		LOOP	APAGA
		POP 	SI
		POP 	CX
		POP 	AX
		POP 	BX
		RET
APAGA_ECRAN	ENDP

;########################################################################
; LE UMA TECLA	

LE_TECLA	PROC
		MOV		AH, 08h
		INT		21h
		MOV		AH, 0
		CMP		AL, 0
		jne		SAI_TECLA
		MOV		AH, 08h
		INT		21h
		MOV		AH, 1
SAI_TECLA:
		RET
LE_TECLA	endp
;########################################################################

;********************************************************************************
; LEITURA DE UMA TECLA DO TECLADO    (ALTERADO)
; LE UMA TECLA	E DEVOLVE VALOR EM AH E AL
; SE AH=0 É UMA TECLA NORMAL
; SE AH=1 É UMA TECLA EXTENDIDA
; AL DEVOLVE O CÓDIGO DA TECLA PREMIDA
; Se não foi premida tecla, devolve AH=0 e AL = 0
;********************************************************************************
LE_TECLA_0	PROC
	;	CALL 	Trata_Horas
		MOV		AH, 0BH
		INT 	21h
		CMP 	AL, 0
		jne		COM_TECLA
		MOV		AH, 0
		MOV		AL, 0
		JMP		SAI_TECLA
COM_TECLA:		
		MOV		AH, 08H
		INT		21H
		MOV		AH, 0
		CMP		AL, 0
		JNE		SAI_TECLA
		MOV		AH, 08H
		INT		21H
		MOV		AH,1
SAI_TECLA:	
		RET
LE_TECLA_0	ENDP

;#############################################################################
MOVE_SNAKE PROC
CICLO:	
		;CALL 	IMP_PONTUACAO
		GOTO_XY	POS_X,POS_Y			; Vai para nova possição
		MOV		AH, 08h				; Guarda o Caracter que está na posição do Cursor
		MOV		bh, 0				; numero da página
		INT		10h			
		CMP		AL, '#'				;  na posição do Cursor
		JE		FIM
MACA_VERMELHA:
		CMP 	AL, 'm'
		JNE		MACA_VERDE
		;CMP		
		inc 	pontuacao
		jmp 	CONTINUA
MACA_VERDE:
		CMP 	AL, 'M'
		JNE		RATO
		add 	pontuacao, 2
		jmp 	CONTINUA
RATO:
		CMP 	AL, 'R'
		JNE		CONTINUA
		sub 	pontuacao, 3
		jmp 	CONTINUA
CONTINUA:
		GOTO_XY	POS_X_ANT,POS_Y_ANT		; Vai para a posição anterior do cursor
		MOV		AH, 02h
		MOV		DL, ' ' 	; Coloca ESPAÇO
		INT		21H	

		INC		POS_X_ANT
		GOTO_XY	POS_X_ANT,POS_Y_ANT	
		MOV		AH, 02h
		MOV		DL, ' '		;  Coloca ESPAÇO
		INT		21H	
		DEC 	POS_X_ANT
		
		
	
		GOTO_XY	POS_X,POS_Y	; Vai para posição do cursor
IMPRIME:
		MOV		AH, 02h
		MOV		DL, '('	; Coloca AVATAR1
		INT		21H
		
		INC		POS_X
		GOTO_XY	POS_X,POS_Y		
		MOV		AH, 02h
		MOV		DL, ')'	; Coloca AVATAR2
		INT		21H	
		DEC		POS_X
		
		GOTO_XY	POS_X,POS_Y	; Vai para posição do cursor
		
		MOV		AL, POS_X	; Guarda a posição do cursor
		MOV		POS_X_ANT, AL
		MOV		AL, POS_Y	; Guarda a posição do cursor
		MOV		POS_Y_ANT, AL
		
LER_SETA:	
		CALL 	LE_TECLA_0
		CMP		AH, 1
		JE		ESTEND
		CMP 	AL, 27	; ESCAPE
		JE		FIM		
		CALL	PASSA_TEMPO
		MOV		AX, PASSA_T_ANT
		CMP		AX, PASSA_T
		JE		LER_SETA
		MOV		AX, PASSA_T
		MOV		PASSA_T_ANT, AX
		
VERIFICA_0:	
		MOV		AL, DIRECAO
		CMP		AL, 0
		jne		VERIFICA_1
		INC		POS_X		;Direita
		INC		POS_X		;Direita
		JMP		CICLO
		
VERIFICA_1:
		MOV 	AL, DIRECAO
		CMP		AL, 1
		jne		VERIFICA_2
		DEC		POS_Y		;cima
		JMP		CICLO
		
VERIFICA_2:	
		MOV		AL, DIRECAO
		CMP		AL, 2
		jne		VERIFICA_3
		DEC		POS_X		;Esquerda
		DEC		POS_X		;Esquerda
		JMP		CICLO
		
VERIFICA_3:
		MOV		AL, DIRECAO
		CMP		AL, 3		
		jne		CICLO
		INC		POS_Y		;BAIXO		
		JMP		CICLO
		
ESTEND:
		CMP 	AL, 48h
		jne		BAIXO
		MOV		DIRECAO, 1
		JMP		CICLO

BAIXO:		
		CMP		AL, 50h
		jne		ESQUERDA
		MOV		DIRECAO, 3
		JMP		CICLO

ESQUERDA:
		CMP		AL, 4Bh
		jne		DIREITA
		MOV		DIRECAO, 2
		JMP		CICLO

DIREITA:
		CMP		AL, 4Dh
		jne		LER_SETA 
		MOV		DIRECAO, 0	
		JMP		CICLO

FIM:	
		MOV 	QUAL_MENU, 0
		CALL 	APAGA_ECRAN 
		CALL 	IMP_FICH
		GOTO_XY	40, 23
		RET
MOVE_SNAKE ENDP


;###############################################
; 			LER MENU ESTATISTICA
;###############################################
LER_MENU_STATS PROC
	INICIO:
		MOV 	QUAL_MENU, 1 ; 
		CALL 	APAGA_ECRAN ; Limpa Ecra
		CALL 	IMP_FICH ; Le Menu Stats
	CICLO:
		CALL 	LE_TECLA
		CMP		AL, '1' ; Verifica se e a opcao 1 do menu
		JE 		HISTORICO
		CMP 	AL, '2' ; Verifica se a opcao 2 do menu
		JE 		ESTATISTICOS
		CMP 	AL, '3' ; Verifica se e a opcao 3 do menu
		JE 		VOLTAR
		JMP 	CICLO
	HISTORICO:
		MOV		QUAL_MENU, 3 ; Vai comecar o jogo
		CALL 	APAGA_ECRAN ; Limpa Ecra
		CALL 	IMP_FICH ; Imprime FICHeiro
		CALL 	LE_TECLA
		JMP 	INICIO
	ESTATISTICOS:
		MOV 	QUAL_MENU, 4 ; Vai comecar o jogo
		CALL 	APAGA_ECRAN ; Limpa Ecra	
		CALL 	IMP_FICH ; Imprime FICHeiro
		CALL 	LE_TECLA
		JMP 	INICIO
	VOLTAR:
		RET
LER_MENU_STATS endp

;################################################
; 			LIMPAR VARIAVEIS
;################################################
LIMPAR_VARIAVEIS PROC
		MOV 	POS_Y, 10
		MOV 	POS_X, 40
		MOV 	POS_Y_ANT, 5
		MOV 	POS_X_ANT, 10
		MOV 	PASSA_T, 0
		MOV 	PASSA_T_ANT, 0
		MOV 	DIRECAO, 3
		MOV 	CENTESIMOS, 0
		MOV 	FACTOR, 100
		MOV 	METADE_FACTOR, 50
		MOV		PONTUACAO, 0
		MOV 	RESTO, 0
		RET
LIMPAR_VARIAVEIS endp

;################################################
; 			LER NIVEL
;################################################
LE_NIVEL PROC
		MOV 	QUAL_MENU, 5
		CALL 	APAGA_ECRAN ; Limpa Ecra
		CALL 	IMP_FICH ; Le Menu Stats
CICLO:
		CALL 	LE_TECLA
		CMP		AL, '1'
		JNE		TESTE_2
		MOV		FACTOR, 100
		RET
TESTE_2:	
		CMP		AL, '2'
		JNE		TESTE_3
		MOV		FACTOR, 50
		RET
TESTE_3:	
		CMP		AL, '3'
		JNE		TESTE_4
		MOV		FACTOR, 25
		RET
TESTE_4:
		CMP		AL, '4'
		JNE		CICLO
		MOV		FACTOR, 10
		RET
LE_NIVEL endp


;################################################
; 			IMPRIME NIVEL
;################################################
IMP_NIVEL PROC
		GOTO_XY	14, 24
		CMP		FACTOR, 100
		JNE 	TESTE_2
		LEA		DX, offset NIVEL_1
		JMP 	IMPRIME
TESTE_2:
		CMP		FACTOR, 50
		JNE 	TESTE_3
		LEA		DX, offset NIVEL_2
		JMP 	IMPRIME
TESTE_3:
		CMP		FACTOR, 25
		JNE 	TESTE_4
		LEA		DX, offset NIVEL_3
		JMP 	IMPRIME
TESTE_4:
		CMP		FACTOR, 10
		LEA		DX, offset NIVEL_4
		JMP 	IMPRIME
IMPRIME:
		MOV		AH, 09h
		INT		21H	
		RET
IMP_NIVEL endp

;################################################
;CalcAleat - calcula um numero aleatorio de 16 bits
;Parametros passados pela pilha
;entrada:
;não tem parametros de entrada
;saida:
;param1 - 16 bits - numero aleatorio calculado
;notas adicionais:
; deve estar definida uma variavel => ultimo_num_aleat dw 0
; assume-se que DS esta a apontar para o segmento onde esta armazenada ultimo_num_aleat
;################################################
CalcAleat proc near

	sub	sp,2		; 
	push	bp
	mov	bp,sp
	push	ax
	push	cx
	push	dx	
	mov	ax,[bp+4]
	mov	[bp+2],ax

	mov	ah,00h
	int	1ah

	add	dx,ultimo_num_aleat	; vai buscar o aleatório anterior
	add	cx,dx	
	mov	ax,65521
	push	dx
	mul	cx			
	pop	dx			 
	xchg	dl,dh
	add	dx,32749
	add	dx,ax

	mov	ultimo_num_aleat,dx	; guarda o novo numero aleatório  

	mov	[BP+4],dx		; o aleatório é passado por pilha

	pop	dx
	pop	cx
	pop	ax
	pop	bp
	ret
CalcAleat endp

;##################################################################################################
; 									CONVERTE NUMERO PARA STRING
; CARACTER CORRESPONDENTE POR EXEMPLO A 4 É 52, PARA REPRESENTAR OS NUMEROS INTEIROS É ADICIONAR 48
;##################################################################################################
CONVERTE proc		;inicio do procedimento
	PUSHF
	PUSH BX		;guarda contexto
	PUSH DX
	ADD DI, 4	;avavnça para o digito das unidades
	MOV BX, 10      ;divisor  = 10
ciclo:
	MOV DX, 0     ;divisor...
	DIV BX	     ;DX:AX/BX = AX (resto = DX)
    ADD DL, 48    ;converte 4 em '4'...
	MOV [DI], DL
	DEC DI
	CMP AX, 0
	JNE ciclo
	POP DX
	POP BX	;recupera contexto
	POPF
	RET		;sai da funçao
CONVERTE  endp		;fim do procedimento

;################################################
; 			IMPRIME PONTUACAO
;################################################
IMP_PONTUACAO  proc 
	MOV DI, 16    		;indice do digito das unidades
	MOV BX, 10    		;divisor = 10

	MOV DX, PONTUACAO	;dividendo = numero...
	CALL CONVERTE
	GOTO_XY	53,24
	MOV	ah, 09h			;print string (...$)
	INT	21h
	RET
IMP_PONTUACAO  endp
		
;################################################
; 			LER MENU INICAL
;################################################
LER_MENU_INICIAL PROC
	INICIO:
		MOV 	QUAL_MENU, 0
		CALL 	APAGA_ECRAN 
		CALL 	IMP_FICH
	CICLO:
		CALL 	LE_TECLA
		CMP		AL, '1' ; Verifica se e a opcao 1 do menu
		JE 		COMECA_JOGO
		CMP 	AL, '2' ; Verifica se a opcao 2 do menu
		JE 		VER_ESTATISTICA
		CMP 	AL, '3' ; Verifica se e a opcao 3 do menu
		JE 		SAIR
		JMP 	CICLO
	COMECA_JOGO:
		CALL 	LIMPAR_VARIAVEIS
		CALL 	LE_NIVEL
		MOV 	QUAL_MENU, 2 ; Vai comecar o jogo
		CALL 	APAGA_ECRAN ; Limpa Ecra
		CALL 	IMP_FICH ; Le mapa de jogo
		CALL 	IMP_NIVEL
		CALL 	MOVE_SNAKE ; Chama funcao do jogo
		JMP 	INICIO
	VER_ESTATISTICA:
		CALL 	LER_MENU_STATS
		JMP 	INICIO
	SAIR:
		MOV		AH, 4Ch
		INT		21h
LER_MENU_INICIAL endp

;###############################################
; 			PINTAR ECRAN
;###############################################
pINTa_ecra PROC
;
;GOTO_XY  5,2
;
pINTa_ecra endp

;#############################################################################
;             MAIN
;#############################################################################
MENU    Proc
		MOV 	AX, DSEG
		MOV 	DS, AX
		MOV		AX, 0B800H
		MOV		ES, AX		; ES indica segmento de memória de VIDEO
		CALL 	LER_MENU_INICIAL
		MOV 	AH, 4Ch
		INT 	21h
MENU    endp
cseg	ends
end     MENU