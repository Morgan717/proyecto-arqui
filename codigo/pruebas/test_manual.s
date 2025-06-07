MAIN: 
	MOVE.L #$6000,SP
	BSR INIT
	MOVE.W #$2000,SR * Permite interrupciones
	BUCPR: 
	MOVE.W #TAMBS,PARTAM * Inicializa par´ametro de tama~no
	MOVE.L #BUFFER,PARDIR * Par´ametro BUFFER = comienzo del buffer
	OTRAL: MOVE.W PARTAM,-(A7) * Tama~no de bloque
	MOVE.W #DESA,-(A7) * Puerto A
	MOVE.L PARDIR,-(A7) * Direcci´on de lectura
	ESPL: 
	BSR SCAN
	ADD.L #8,A7 * Restablece la pila
	ADD.L D0,PARDIR * Calcula la nueva direcci´on de lectura
	SUB.W D0,PARTAM * Actualiza el n´umero de caracteres le´ıdos
	BNE OTRAL * Si no se han le´ıdo todas los caracteres
	* del bloque se vuelve a leer
	MOVE.W #TAMBS,CONTC * Inicializa contador de caracteres a imprimir
	MOVE.L #BUFFER,PARDIR * Par´ametro BUFFER = comienzo del buffer
	OTRAE: 
	MOVE.W #TAMBP,PARTAM * Tama~no de escritura = Tama~no de bloque
	ESPE: 
	MOVE.W PARTAM,-(A7) * Tama~no de escritura
	MOVE.W #DESB,-(A7) * Puerto B
	MOVE.L PARDIR,-(A7) * Direcci´on de escritura
	BSR PRINT
	ADD.L #8,A7 * Restablece la pila
	ADD.L D0,PARDIR * Calcula la nueva direcci´on del buffer
	SUB.W D0,CONTC * Actualiza el contador de caracteres
	BEQ SALIR * Si no quedan caracteres se acaba
	SUB.W D0,PARTAM * Actualiza el tama~no de escritura
	BNE ESPE * Si no se ha escrito todo el bloque se insiste
	CMP.W #TAMBP,CONTC * Si el no de caracteres que quedan es menor que
	* el tama~no establecido se imprime ese n´umero
	BHI OTRAE * Siguiente bloque
	MOVE.W CONTC,PARTAM
	BRA ESPE * Siguiente bloque
	SALIR: 
	BRA BUCPR
BUS_ERROR: 
		BREAK * Bus error handler
		NOP
ADDRESS_ER: 
		BREAK * Address error handler
		NOP
ILLEGAL_IN: BREAK * Illegal instruction handler
		NOP
PRIV_VIOLT: 
		BREAK * Privilege violation handler
		NOP
