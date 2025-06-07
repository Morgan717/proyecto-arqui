MAIN:
    MOVE.L #$6000,SP     ;Inicializa pila
    BSR INIT             ;Inicializa buffers, DUART
    MOVE.W #$2000,SR     ;Habilita interrupciones

	PRUEBA:
	*leemos diez bytes desde A
	MOVE.W #10,D2         	;tamaño restante a leer
	MOVE.L #BUFFER,PARDIR 	;Parametro BUFFER = comienzo del buffer

	SCANLOOP:			
	MOVE.W D2,-(SP)			;preparamos pila llamamos y restauramos pila
	MOVE.W #0,-(SP)
	MOVE.L PARDIR,-(SP)
	BSR SCAN
	ADD.L #8,SP

	ADD.L D0,PARDIR         ;avanza puntero en función de lo leído
	SUB.W D0,D2             ;resta lo leído SI 
	BNE SCANLOOP			;si todavai queda por leer volvemos

	*escritura de los 10 bytes en bloques de 5
	MOVE.W #10,D3           ;total a escribir
	MOVE.L #BUFFER,PARDIR 	;parametro BUFFER = comienzo del buffer
	PRINTLOOP:
	MOVE.W #5,D2         	;tamaño de bloque

	PRINTB:
	MOVE.W D2,-(SP)			;preparamos pila
	MOVE.W #0,-(SP)
	MOVE.L PARDIR,-(SP)
	BSR PRINT
	ADD.L #8,SP

	ADD.L D0,PARDIR
	SUB.W D0,D3				;si hemos acabado de imprimr lo pendiente volvemos a empezar
	BEQ SAL

	SUB.W D0,D2
	BNE PRINTB				;todavia no pues otra vez a print

	CMP.W #5,D3
	BHI PRINTLOOP			;si jsuto queda la mitad del bloque otra vez a print

	MOVE.W D3,D2            ;si hay caracteres de mqs del bloque
	BRA PRINTB

	SAL:
	BRA PRUEBA

	ORG $1500

	*Buffer para pruebas
	BUFFER: DS.B 2100 	; Buffer para lectura y escritura de caracteres
	PARDIR: DC.L 0 		; Direccion que se pasa como parametro