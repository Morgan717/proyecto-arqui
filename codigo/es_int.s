	ORG $0
	DC.L $6000      ;dirección inicial del SP
	DC.L MAIN		;punto de entrada
	ORG $400

	***********************************************************
	* Proyecto E/S mediante interrupciones
	* Curso 2024-2025
	* Alumno: Gabriel Mateo Morgan
	* Grupo: 4F2T
	************************************************************

	IMR:	DS.B 1
			DS.B 3
	*definimos los puertos de la DUART 
	*puertos especificos por canal
MRA EQU $EFFC01 ;MR1A y MR2A modo registro
MRB EQU $EFFC11 ;igual pero para B


CLKA EQU $EFFC03	;seleccionar reloj 
CLKB EQU $EFFC13	;seleccionar reloj 

	*registros de control 
CTRLA EQU $EFFC05	;registro de ctrl A
CTRLB EQU $EFFC15        	
	*transimision y recepción
RBUFA   EQU $EFFC07	;buffer recepcion para A
TBUFA   EQU $EFFC07	;transimison para A
RBUFB   EQU $EFFC17        	
TBUFB   EQU $EFFC17

	*puertos comunes a ambos canales
CTRLAUX	EQU $EFFC09 ;ctrl aux
MASKINT EQU $EFFC0B ;IMR 
EINT   	EQU $EFFC0B ;puerto IMR pero para leer estado interrupciones
VECINT 	EQU $EFFC19 ;vector de interrupciones


********************************************************
*INIT - Inicializa la DUART y buffers
********************************************************

INIT:

	*primero reiniciamos el puntero de registro de modo para los dos canales para que apunten a MR1
	*por si acaso estaba desplazado
	MOVE.B #%00010000,CTRLA  	;con %00010000 activamos en el control de registro de A resetear el MR1
	MOVE.B #%00010000,CTRLB  	;lo mismo para el canal B

	*ahora tenemos que configurar el formato a 8 bits
	MOVE.B #%00000011,MRA		;00000011 -> 8 bits
	MOVE.B #%00000000,MRA		;desactivamos el eco para que la duart no responda y añada interrupciones
	MOVE.B #%00000011,MRB		;hacemos lo mismo para el canal B
	MOVE.B #%00000000,MRB

	*elegimos una velocidad de bps
	MOVE.B #%11001100,CLKA  	;38400 bps conjunto 1 y 19200 de conjunto 2 
	MOVE.B #%11001100,CLKB  	
	MOVE.B #0,CTRLAUX			;ponemos el control auxiliar a 0 para usar conjunto 1

		*activamos transmision y recepcion 
	MOVE.B #%00000101,CTRLA   	;bits 3y2  activa transmision y bits 1 y 0 activa recepción
	MOVE.B #%00000101,CTRLB   	;igual que en el A

		*definimos un vector interno
	MOVE.B #$40,VECINT 			;cuando haya interrupcion y usara el 64 del vector para encontrar RTI
	MOVE.L #RTI,256 			;vector de entrada RTI VECTINT x 4 = 256

	*lo ultimo habilita la petición de interrupciones
	MOVE.B #%00100010,IMR
	MOVE.B IMR,MASKINT			;bit 1 y bit 5 habilitan RxRDY


	BSR INI_BUFS 				;iniciación de los buffers
	RTS							;retorno

**********************************************************
* SCAN - Lectura no bloqueante
**********************************************************

SCAN:

	*cargamos los parametros desde la pila
	MOVE.L  4(A7),A1            ;A1 puntero al buffer de destino
	MOVE.W  8(A7),D4            ;D4 descriptor 0 o 1 para leer por A o por B
	MOVE.W 10(A7),D2            ;D2 bytes a leer
	CLR.L   D3                  ;ponemos D3 contador a 0 clear D3
	CLR.L 	D0					;lo iniciamos a 0

	*si tamaño 0 salimos
	CMP.W #0,D2
    BEQ FNSCAN

	*comprobar descriptor
	CMP.W   #0,D4				;vale si D4 es 0 saltamos al bucle y no hay eror
	BEQ     BUCSCAN
	CMP.W   #1,D4				;lo mismo si es 1 saltamos al bucle
	BEQ 	BUCSCAN
	MOVE.L 	#$FFFFFFFF,D0		;error ya que D4 no es ni 0 ni 1 osea resultado -1
	BRA FNSCAN					

	BUCSCAN:
	MOVE.L  D4,D0				;metemos en D0 el descritor D1 para indicar a LEECAR el canal
    BSR LEECAR					;llamamos para que lea
	CMP.L #-1,D0              	;si esta vacio LEECAR devuelve -1 en D0 a si que comprobamos IMPORTANTE
	BEQ CONTSCAN				;si esta vacio hemos acabado
	*ahora mandamos el byte leido
	MOVE.B  D0,(A1)+           	;metemos en el destino el byte que ha dejado LEECAR en D0
	ADD.L   #1,D3               ;incrementamos el contador
	CMP.W D3,D2               	;comprobamos contador = bytes a leer
	BNE BUCSCAN

	CONTSCAN:
	MOVE.L D3,D0				;si no hay errores guardamos contador en D0
	FNSCAN:
	RTS	

*****************************************************************
*PRINT - Escritura no bloqueante
*****************************************************************

	
PRINT:
	*cargamos los parametros desde la pila igual qu en scan
	MOVE.L  4(A7),A1 	;A1 puntero al buffer de destino
	MOVE.W  8(A7),D4 	;D4 descriptor 0 o 1 para leer por A o por B
	MOVE.W 10(A7),D2 	;D2 bytes a leer
	CLR.L   D3          ;D3 contador
	CLR.L 	D0			;iniciamos a 0

	*si tamaño 0 salimos
	CMP.W #0,D2
    BEQ FINPRINT

	CMP.W #0,D4              ;canal A
	BEQ PRINTA               
	CMP.W #1,D4              ;canal B
	BEQ PRINTB               
	MOVE.L #$FFFFFFFF,D0     ;descriptor inválido D0 = -1
	BRA FINPRINT             ;salimos

	*aqui tenemos que dividir bucles para a y b ya que metemos un valor disintos a esccar
	PRINTA:
	MOVE.L #2,D0             ;canal A para ESCCAR
	MOVE.B (A1)+,D1          ;D1 siguiente byte a enviar
	BSR ESCCAR               ;llamamos a ESCCAR
	CMP.L #-1,D0             ;buffer lleno?
	BEQ ACTA                 ;si activamos interrupción y salir
	ADD.L #1,D3              ;D3++
	CMP.L D3,D2              ;terminamos?
	BEQ ACTA                 ;si salir
	BRA PRINTA               ;no siguiente byte

	PRINTB:
	MOVE.L #3,D0             
	MOVE.B (A1)+,D1          
	BSR ESCCAR
	CMP.L #-1,D0             
	BEQ ACTB                 
	ADD.L #1,D3              
	CMP.L D3,D2              
	BEQ ACTB
	BRA PRINTB

	ACTA:
	CMP.L #0,D3              ;se escribio algo?
	BEQ FINPRINT             ;no activamos interrupcion
	MOVE.W SR,D6             ;guardamos SR
	MOVE.W #$2700,SR         ;desactivar interrupciones
	OR.B #1,IMR              ;activar interrupción TX A (bit 0)
	MOVE.B IMR,MASKINT       ;actualizar máscara real
	MOVE.W D6,SR             ;restaurar SR
	BRA FINPRINT             ;salir

	ACTB:
	CMP.L #0,D3              ;¿algo escrito?
	BEQ FINPRINT
	MOVE.W SR,D6
	MOVE.W #$2700,SR
	OR.B #16,IMR             ;activar interrupción TX B (bit 4)
	MOVE.B IMR,MASKINT
	MOVE.W D6,SR

	FINPRINT:
	MOVE.L D3,D0             ;D0 ← número de caracteres escritos
	RTS                      ;retorno




*******************************************************************
*RTI - tratamiento de interrupciones
*******************************************************************
RTI:
	MOVEM.L D0-D7,-(A7)	;guardamos todos los registros

	BUCRTI:
	MOVE.B EINT,D1              ;D1 ← estado de interrupciones
	AND.B IMR,D1                ;filtramos solo las interrupciones habilitadas

	BTST #1,D1                  ;¿recepción A?
	BNE RECA
	BTST #5,D1                  ;¿recepción B?
	BNE RECB
	BTST #0,D1                  ;¿transmisión A?
	BNE TRA
	BTST #4,D1                  ;¿transmisión B?
	BNE TRB
	BRA FINRTI                  ;no hay interrupciones → salir

	RECA:
	MOVE.B RBUFA,D1             ;leer byte recibido por canal A
	MOVE.L #0,D0                ;D0 ← descriptor A
	BSR ESCCAR                  ;escribimos en buffer interno
	CMP.L #-1,D0                ;¿está lleno?
	BEQ FINRTI
	BRA BUCRTI                  ;revisamos si hay más interrupciones

	RECB:
	MOVE.B RBUFB,D1             ;leer byte recibido por canal B
	MOVE.L #1,D0
	BSR ESCCAR
	CMP.L #-1,D0
	BEQ FINRTI
	BRA BUCRTI

	TRA:
	MOVE.L #2,D0                ;D0 ← descriptor de transmisión A
	BSR LEECAR                  ;leer byte desde buffer interno
	CMP.L #-1,D0
	BEQ INHA                    ;si está vacío, desactivar interrupción
	MOVE.B D0,TBUFA             ;enviar a DUART
	BRA BUCRTI

	TRB:
	MOVE.L #3,D0
	BSR LEECAR
	CMP.L #-1,D0
	BEQ INHB
	MOVE.B D0,TBUFB
	BRA BUCRTI

	INHA:
	AND.B #%11111110,IMR        ;desactivar bit 0 (TX A)
	MOVE.B IMR,MASKINT
	BRA BUCRTI

	INHB:
	AND.B #%11101111,IMR        ;desactivar bit 4 (TX B)
	MOVE.B IMR,MASKINT
	BRA BUCRTI

	FINRTI:
	MOVEM.L (A7)+,D0-D7	;recuperamos todos los registros
	RTE                         ;retorno de interrupción

MAIN:
    BSR INIT             	;Inicializa buffers, DUART
    MOVE.W #$2000,SR     	;Habilita interrupciones

	PRUEBA:
	*leemos diez bytes desde A
	MOVE.W #10,D2         	;tamaño restante a leer
	MOVE.L #BUFFER,PARDIR 	;Parametro BUFFER = comienzo del buffer

	SCANLOOP:			
	MOVE.W D2,-(A7)			;preparamos pila llamamos y restauramos pila
	MOVE.W #0,-(A7)
	MOVE.L PARDIR,-(A7)
	BSR SCAN
	ADD.L #8,SP

	ADD.L D0,PARDIR         ;avanza puntero en función de lo leído
	SUB.W D0,D2             ;resta lo leído SI 
	BNE SCANLOOP			;si todavai queda por leer volvemos

	*escritura de los 10 bytes en bloques de 5
	MOVE.W #10,D3           ;total a escribir
	MOVE.L #BUFFER,PARDIR 	;parametro BUFFER = comienzo del buffer
	PRINTLOOP:
	MOVE.W #10,D2         	;tamaño de bloque

	PRINTBLOQUE:
	MOVE.W D2,-(SP)			;preparamos pila
	MOVE.W #1,-(SP)
	MOVE.L PARDIR,-(SP)
	BSR PRINT
	ADD.L #8,SP

	ADD.L D0,PARDIR
	SUB.W D0,D3				;si hemos acabado de imprimr lo pendiente volvemos a empezar
	BEQ SAL

	SUB.W D0,D2
	BNE PRINTBLOQUE				;todavia no pues otra vez a print

	CMP.W #5,D3
	BHI PRINTLOOP			;si jsuto queda la mitad del bloque otra vez a print

	MOVE.W D3,D2            ;si hay caracteres de mqs del bloque
	BRA PRINTBLOQUE

	SAL:
	BRA PRUEBA

	ORG $1500
	*Buffer para pruebas
	BUFFER: DS.B 2100 		; Buffer para lectura y escritura de caracteres
	PARDIR: DC.L 0 			; Direccion que se pasa como parametro

INCLUDE bib_aux.s      		;para la subrutinas auxiliares

