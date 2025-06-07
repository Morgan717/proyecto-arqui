	ORG		$0
	DC.L	$8000	*Valor inicial del puntero de pila
	DC.L	MAIN	*Etiqueta del programa principal
	
	ORG		$400
	
	*TAMANO EQU	2001
COPIAIMR 	DS.B	1
			DS.B 	3

MR1A	EQU	$EFFC01
MR2A	EQU $EFFC01
SRA		EQU	$EFFC03
CSRA	EQU	$EFFC03
CRA		EQU	$EFFC05	* de control A (escritura)
TBA		EQU	$effc07	* buffer transmision A (escritura)
RBA		EQU	$EFFC07	* buffer recepcion A (lectura)
ACR		EQU $EFFC09	* de control auxiliar
IMR		EQU $EFFC0B	* de máscara de interrupción (escritura)
ISR		EQU $EFFC0B
MR1B	EQU $EFFC11
MR2B	EQU $EFFC11
CRB		EQU $EFFC15
TBB		EQU $EFFC17
RBB		EQU $EFFC17
SRB		EQU $EFFC13
CSRB	EQU $EFFC13
IVR		EQU $EFFC19
LINEAA	EQU		0					
LINEAB	EQU		1
ELA		EQU 	2
ELB		EQU		3

	BUFFER: DS.B 2100       * Buffer para lectura y escritura de caracteres
	PARDIR: DC.L 0          * Direccion que se pasa como parametro
	PARTAM: DC.W 0          * Tamano que se pasa como parametro
	CONTC:  DC.W 0          * Contador de caracteres a imprimir
	DESA:   EQU 0           * Descriptor lınea A
	DESB:   EQU 1           * Descriptor lınea B
	TAMBS:  EQU 10          * Tamano de bloque para SCAN
	TAMBP:  EQU 5           * Tamano de bloque para PRINT



MAIN:
	BSR			INIT				* Inicializar controlador
	MOVE.W		#$2000,SR			* Activar interrupciones
	BRA			PRUEBA				* Ejecutar PRUEBAxx
	
		PRUEBA:
	BUCPR:  MOVE.W #TAMBS,PARTAM
			MOVE.L #BUFFER,PARDIR
	OTRAL:  MOVE.W PARTAM,-(A7)
			MOVE.W #DESA,-(A7)
			MOVE.L PARDIR,-(A7)
	ESPL:   BSR SCAN
			ADD.L #8,A7
			ADD.L D0,PARDIR
			SUB.W D0,PARTAM
			BNE OTRAL
			MOVE.W #TAMBS,CONTC
			MOVE.L #BUFFER,PARDIR
	OTRAE:  MOVE.W #TAMBP,PARTAM
	ESPE:   MOVE.W PARTAM,-(A7)
			MOVE.W #DESB,-(A7)
			MOVE.L PARDIR,-(A7)
			BSR PRINT
			ADD.L #8,A7
			ADD.L D0,PARDIR
			SUB.W D0,CONTC
			BEQ SALIR
			SUB.W D0,PARTAM
			BNE ESPE
			CMP.W #TAMBP,CONTC
			BHI OTRAE
			MOVE.W CONTC,PARTAM
			BRA ESPE
	SALIR:  BRA BUCPR




	INIT:	MOVE.B	#%00010000,CRA	* Reinicia el puntero MR1A
			MOVE.B	#%00010000,CRB	* Reinicia el puntero MR1B
			
			MOVE.B	#%00000011,MR1A	* 8 bits por carácter y RxRDY
			MOVE.B	#%00000000,MR2A	* Eco desactivado
			
			MOVE.B	#%00000011,MR1B	* 8 bits por carácter y RxRDY
			MOVE.B	#%00000000,MR2B	* Eco desactivado
			
			MOVE.B	#%11001100,CSRA	* Velocidad = 38400 bps
			MOVE.B	#%11001100,CSRB	* Velocidad = 38400 bps
			
			MOVE.B	#%00000000,ACR	* Conjunto 1 (velocidad = 38400 bps)
			MOVE.B	#%00000101,CRA	* Transmisión y recepción activados
			MOVE.B	#%00000101,CRB	* Transmisión y recepcion activados
			
			MOVE.B	#$40,IVR		* Establecimiento vector de interrupción
			
			MOVE.B	#%00100010,COPIAIMR
			MOVE.B	#%00100010,IMR	
			
			MOVE.L	#RTI,256		* Actualizar dirección RTI en TV
			
			BSR		INI_BUFS
			
			RTS
			
	SCAN:	
			MOVE.L 	4(A7),A1 	*direccion del buffer
			EOR.L   D4,D4
			MOVE.W	8(A7),D2	* Descriptor
			MOVE.W	10(A7),D3	* Tamaño
			CMP.W	#LINEAA,D2
			BEQ		SCANA
			CMP.W	#LINEAB,D2
			BEQ		SCANB
			MOVE.L	#$FFFFFFFF,D0
			BRA		FINSCAN
			
	SCANA:	
			MOVE.L	#LINEAA,D0   * Ponemos D0=0 para la llamada a LEECAR
			BSR		LEECAR
			CMP.L 	#-1,D0	* Si devuelve -1, no hay caracteres para leer y hemos terminado
			BEQ		FINSCAN1
			MOVE.B 	D0,(A1)+	* M(A1)<-D0; A1<-A1+1
			ADD.L	#1,D4	* Incremento contador de caracteres
			SUB.W	#1,D3
			CMP.W	#0,D3
			BNE		SCANA
			BRA		FINSCAN1
			
	SCANB:	MOVE.L	#LINEAB,D0		* Ponemos D0=1 para la llamada a LEECAR
			BSR		LEECAR
			CMP.L 	#-1,D0	* Si devuelve -1, no hay caracteres para leer y hemos terminado
			BEQ		FINSCAN1
			MOVE.B 	D0,(A1)+	* M(A1)<-D0; A1<-A1+1
			ADD.L	#1,D4	* Incremento contador de caracteres
			SUB.W	#1,D3
			CMP.W	#0,D3
			BNE		SCANB
			
FINSCAN1:	MOVE.L	D4,D0	* Copiamos caracteres leídos a D0
FINSCAN:	
			RTS			
			

		
	PRINT:	MOVE.L	4(A7),A1	* Guardo Buffer en A1, A1<-M(A6+8)
			EOR.L  	D4,D4		*reinicia el contador de caracteres
			MOVE.W	8(A7),D2	* Descriptor
			MOVE.W	10(A7),D3	* Tamaño
			CMP.W	#0,D3
			BEQ		FINPRINT
			CMP.W	#LINEAA,D2
			BEQ		PRINTA
			CMP.W	#LINEAB,D2
			BEQ		PRINTB
			MOVE.L	#$FFFFFFFF,D4
			BRA		FINPRINT
			
	PRINTA:	MOVE.L	#ELA,D0	* Ponemos D0=2 para la llamada a ESCCAR
			BEQ		FINPRINA
			MOVE.B 	(A1)+,D1	* D1<-M(A1); A1<-A1+1
			BSR		ESCCAR
			CMP.L 	#-1,D0	* Si devuelve -1, buffer lleno
			BEQ		FINPRINA			
			ADD.L	#1,D4	* Incremento contador de caracteres escritos
			CMP.L	D4,D3
			BEQ 	FINPRINA
			BRA		PRINTA

	PRINTB:	MOVE.L	#ELB,D0	* Ponemos D0=3 para la llamada a ESCCAR
			BEQ		FINPRINB
			MOVE.B 	(A1)+,D1	* D1<-M(A1); A1<-A1+1
			BSR		ESCCAR
			CMP.L 	#-1,D0	* Si devuelve -1, buffer lleno
			BEQ		FINPRINB			
			ADD.L	#1,D4	* Incremento contador de caracteres escritos
			CMP.L	D4,D3
			BEQ 	FINPRINB			
			BRA		PRINTB
	
	FINPRINA:	CMP.L 	#0,D4	* Para ver si se ha escrito algún carácter
				BEQ		FINPRINT	* Si no se han copiado caracteres, no se activa la interrupción de transmision
				MOVE.W	SR,D6	* Guardamos SR actual para saber cómo están las interrupciones en este momento
				MOVE.W	#$2700,SR	* Inhibo las int un momento para activar las de transmisión
				OR.B	#%00000001,COPIAIMR	    * OR.B 	#1,COPIAIMR
				MOVE.B 	COPIAIMR,IMR	* No hacer BSET #0,IMR, que sale mal
				MOVE.L 	D4,D0	* Copia los caracteres escritos a D0
				MOVE.W	D6,SR	* Recuperamos el SR anterior, termina la zona de exclusión mutua
				BRA		FINPRINT
				
	FINPRINB:	CMP.L 	#0,D4	* Para ver si se ha escrito algún carácter
				BEQ		FINPRINT	* Si no se han copiado caracteres, no se activa la interrupción de transmision
				MOVE.W	SR,D6	* Guardamos SR actual para saber cómo están las interrupciones en este momento
				MOVE.W	#$2700,SR	* Inhibo las int un momento para activar las de transmisión
				OR.B	#%00010000,COPIAIMR	* OR.B 	#16,COPIAIMR
				MOVE.B 	COPIAIMR,IMR	* No hacer BSET #4,IMR, que sale mal
				MOVE.L 	D4,D0	* Copia los caracteres escritos a D0
				MOVE.W	D6,SR	* Recuperamos el SR anterior, termina la zona de exclusión mutua
	FINPRINT:	MOVE.L 	D4,D0	* Copia los caracteres escritos a D0
				RTS
	
	RTI:	MOVEM.L D0-D7,-(A7)
	BUCLE1:	MOVE.B 	ISR,D1
			AND.B 	COPIAIMR,D1
			BTST	#1,D1	* Recepción línea A
			BNE		RLA		* Si el bit no es 0 (será 1 entonces) hay interrupción
			BTST	#5,D1	* Recepción línea B
			BNE		RLB
			BTST	#0,D1	* Transmisión línea A
			BNE		TLA
			BTST	#4,D1	* Transmisión línea B
			BNE		TLB
			BRA		FINRTI
			
	RLA:	MOVE.B 	RBA,D1
			MOVE.L 	#LINEAA,D0
			BSR		ESCCAR
			CMP.L 	#-1,D0
			BEQ		FINRTI	* Si está lleno el buffer terminamos
			BRA		BUCLE1
			
	RLB:	MOVE.B 	RBB,D1
			MOVE.L 	#LINEAB,D0
			BSR		ESCCAR
			CMP.L 	#-1,D0
			BEQ		FINRTI	* Si está lleno el buffer terminamos
			BRA		BUCLE1
			
	TLA:	MOVE.L 	#ELA,D0
			BSR		LEECAR
			CMP.L 	#-1,D0
			BEQ		INHA
			MOVE.B 	D0,TBA
			BRA		BUCLE1
			
	INHA:	AND.B	#%11111110,COPIAIMR
			MOVE.B 	COPIAIMR,IMR
			BRA		BUCLE1
			
	TLB:	MOVE.L 	#ELB,D0
			BSR		LEECAR
			CMP.L 	#-1,D0
			BEQ		INHB
			MOVE.B 	D0,TBB
			BRA		BUCLE1
			
	INHB:	AND.B	#%11101111,COPIAIMR
			MOVE.B 	COPIAIMR,IMR
			BRA		BUCLE1
			
	FINRTI:	MOVEM.L	(A7)+,D0-D7	
			RTE
	
	
	INCLUDE bib_aux.s
	