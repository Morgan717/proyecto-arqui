	ORG $0
	DC.L $4000      ; dirección inicial del SP
	DC.L MAIN       ; punto de entrada
	ORG $400

	***********************************************************
	* Proyecto E/S mediante interrupciones
	* Curso 2024-2025
	* Alumno: Gabriel Mateo Morgan
	* Grupo: 4F2T
	************************************************************


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
RBUFA   EQU $EFFC07        	;buffer recepcion para A
TBUFA   EQU $EFFC07        	;transimison para A
RBUFB   EQU $EFFC17        	
TBUFB   EQU $EFFC17

	*puertos comunes a ambos canales
CTRLAUX	EQU $EFFC09 ;ctrl aux
EINT   	EQU $EFFC0B ;puerto IMR pero para leer estado interrupciones
VECINT 	EQU $EFFC19 ;vector de interrupciones

	IMR: DS.B 1
	CPIMR: DS.B 1
	*Buffer para pruebas
	BUFFER: DS.B 1000     
********************************************************
*INIT - Inicializa la DUART y buffers
********************************************************

INIT:
	LINK A6,#0 					;establece marco de pila

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
	MOVE.B #%00100010,$EFFC0B 	;bit 1 y bit 5 habilitan RxRDY

	BSR INI_BUFS 				;iniciación de los buffers
	UNLK A6	;restaura marco de pila
	RTS	;retorno

**********************************************************
* SCAN - Lectura no bloqueante
**********************************************************

SCAN:

	LINK A6,#0	;marco de pila
	*cargamos los parametros desde la pila
	MOVE.L  4(A6),A1             ;A1 puntero al buffer de destino
	MOVE.W  8(A6),D4             ;D4 descriptor 0 o 1 para leer por A o por B
	MOVE.W 10(A6),D2             ;D2 bytes a leer
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
	MOVE.B  D0,(A1)+           ;metemos en el destino el byte que ha dejado LEECAR en D0
	ADD.L   #1,D3               ;incrementamos el contador
	CMP.W D3,D2               	;comprobamos contador = bytes a leer
	BNE BUCSCAN

	
	CONTSCAN:
	MOVE.L D3,D0				;si no hay errores guardamos contador en D0
	FNSCAN:
	UNLK    A6			;destruimo marco de pila
	RTS					;retorno

*****************************************************************
*PRINT - Escritura no bloqueante
*****************************************************************

	
PRINT:
    LINK A6,#0 			;marco de pila
   	*cargamos los parametros desde la pila igual qu en scan
	MOVE.L  4(A6),A1 	;A1 puntero al buffer de destino
	MOVE.W  8(A6),D4 	;D4 descriptor 0 o 1 para leer por A o por B
	MOVE.W 10(A6),D2 	;D2 bytes a leer
	CLR.L   D3          ;D3 contador
	CLR.L 	D0			;iniciamos a 0

	*si tamaño 0 salimos
	CMP.W #0,D2
    BEQ FINPRINT

    *comprobación de descriptor igual que en SCAN
    CMP.W   #0,D4
    BEQ		CONTPRINT
    CMP.W   #1,D4
    BEQ     CONTPRINT

	MOVE.L 	#$FFFFFFFF,D0
	BRA FINPRINT	
	
	CONTPRINT:
	MOVE.W  D4,D5 	;copiamos el descriptor 
	ADD.L #2,D5		;al sumar dos cambiamos para activar transmision en ESCCAR

	BUCP:
	MOVE.L D4,D0	;metemos el descriptor correspondiente en D0
    MOVE.B (A1)+,D1 	;carga siguiente byte en D1 para escribir
    BSR ESCCAR 		;llamamos para que escriba 
	CMP.L #-1,D0	;buffer lleno?
	BEQ ACTINT
    ADD.L #1,D3 	;++contador
    CMP.L D3,D2 	;hemos cabado?
    BEQ ACTINT 		;si pues fin
	BRA BUCP

	ACTINT:
	CMP.L #0,D3				;si el contador esta a 0 no activamos interrupción
	BEQ ULTFIN
	MOVE.W SR,D6			;guarda el SR actual en D6
    MOVE.W #$2700,SR        ;desactiva interrupciones (nivel 7)
	MOVE.B $EFFC0B,CPIMR	;copia el IMR actual a una copia
	*vemos que transmisión activamos
	CMP.W   #0,D4
    BEQ		INTA
    CMP.W   #1,D4
    BEQ    	INTB

	INTA:
	OR.B	#1,CPIMR    	;activa transmision canal A
	BRA 	SEGUIRPR		;seguimos
	INTB:
	OR.B 	#16,CPIMR	

	SEGUIRPR:
    MOVE.B CPIMR,$EFFC0B 	;escribe la nueva máscara en IMR original
    MOVE.W D6,SR            ;restaura el SR original

	ULTFIN:
	MOVE.L D3,D0 		;metemos contador en D0 
	FINPRINT:
    UNLK    A6
	RTS



*******************************************************************
*RTI - tratamiento de interrupciones
*******************************************************************
RTI:
	LINK A6,#0 
	*guardamos el estado actual del MC
	MOVEM.L D0-D7/A0-A6,-(A7)
	*vemos la causas de interrupción
	MOVE.B $EFFC0B,IMR ;copia IMR cambiamos nombre por si acaso afecta con print
	BUCRTI:
    MOVE.B EINT,D1			;en D1 el estado guardamos estado
	AND.B IMR,D1			;filtramos solo las habilitadas

   	BTST #1,D1     ; recepción A
	BNE RECA
	BTST #5,D1     ; recepción B
	BNE RECB
	BTST #3,D1     ; transmisión A
	BNE TRA
	BTST #7,D1     ; transmisión B
	BNE TRB

	BRA FINRTI				;ninguna activa salimos

	RECA:
	MOVE.B RBUFA,D1 	;D1 metemos dato de la DUART por A para que escriba
	MOVE.L #0,D0       	;descritpor canal A = 0
    BSR ESCCAR 			;llamamos a escritura
	CMP.L #-1,D0		
    BEQ FINRTI	
	BRA BUCRTI			;acabamos

	RECB:
    MOVE.B RBUFB,D1
	MOVE.L #1,D0  
    BSR ESCCAR 		
	CMP.L #-1,D0		
    BEQ FINRTI	
	BRA BUCRTI			;acabamos

	TRA:
	MOVE.L #2,D0  			;descriptor 2 transmision A
    BSR LEECAR 				;extraer dato del buffer interno
    CMP.L #-1,D0			;esta vacio?
    BEQ FINA				;desactivamos canal
    MOVE.B D0,TBUFA			;enviamos a DAURT si no lo esta
    BRA BUCRTI

	TRB:
	MOVE.L #3,D0  			;descriptor 2 transmision B
    BSR LEECAR
    CMP.L #-1,D0
    BEQ FINB
    MOVE.B D0,TBUFB
    BRA FINRTI

	FINA:
    ANDI.B #%11111110,IMR	;deshabilitamos transmision de A
    MOVE.B IMR,$EFFC0B		;actualizamos la mascara
    BRA BUCRTI

	FINB:
    ANDI.B #%11101111,IMR	;deshabilitamos transmision de B
    MOVE.B IMR,$EFFC0B		
    BRA BUCRTI

	FINRTI:
	MOVEM.L (A7)+,D0-D7/A0-A6
    UNLK A6
	RTE						;RTE restuara SC y PC



MAIN:
    MOVE.L #$1500,SP     ;Inicializa pila
    BSR INIT             ;Inicializa buffers, DUART
    MOVE.W #$2000,SR     ;Habilita interrupciones

	PRUEBA:
	*leemos diez bytes desde A
	LEA BUFFER,A1
	MOVE.W #10,D2         	;tamaño restante a leer

	SCANLOOP:			
	MOVE.W D2,-(SP)			;preparamos pila llamamos y restauramos pila
	MOVE.W #0,-(SP)
	MOVE.L A1,-(SP)
	BSR SCAN
	ADD.L #8,SP

	ADD.L D0,A1              ;avanza puntero en función de lo leído
	SUB.W D0,D2              ;resta lo leído
	BNE SCANLOOP

	*escritura de los 10 bytes en bloques de 5
	LEA BUFFER,A1
	MOVE.W #10,D3           ;total a escribir

	PRINTLOOP:
	MOVE.W #5,D2         	;tamaño de bloque

	PRINTB:
	MOVE.W D2,-(SP)			;preparamos pila
	MOVE.W #1,-(SP)
	MOVE.L A1,-(SP)
	BSR PRINT
	ADD.L #8,SP

	ADD.L D0,A1
	SUB.W D0,D3				;si hemos acabado de imprimr lo pendiente volvemos a empezar
	BEQ PRUEBA

	SUB.W D0,D2
	BNE PRINTB				;todavia no pues 

	CMP.W #5,D3
	BHI PRINTLOOP

	MOVE.W D3,D2             ; Último bloque parcial
	BRA PRINTB
	
INCLUDE bib_aux.s      	;para la subrutinas auxiliares

