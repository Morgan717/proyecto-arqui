MAIN:
    MOVE.L #$1500,SP     ;Inicializa pila
    BSR INIT             ;Inicializa buffers, DUART
    MOVE.W #$2000,SR     ;Habilita interrupciones

	*Simular que llegan 'A', 'B', 'C', 'D' al canal A
    MOVE.L #0,D0
    MOVE.B #'A',D1
    BSR ESCCAR
    MOVE.B #'B',D1
    BSR ESCCAR
    MOVE.B #'C',D1
	BSR ESCCAR
    MOVE.B #'D',D1
    BSR ESCCAR

	*Preparar parámetros para SCAN
  	 LEA BUFFER,A1
    MOVE.W #0,D1          ; descriptor canal A
    MOVE.W #4,D2          ; leer 4 caracteres

    MOVE.W D2,-(SP)       ; número de caracteres
    MOVE.W D1,-(SP)       ; descriptor
    MOVE.L A1,-(SP)       ; buffer destino

    BSR SCAN
    ADD.L #8,SP

    ORG $3200
BUFFER: DS.B 10               ; buffer de recepción
