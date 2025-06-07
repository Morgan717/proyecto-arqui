*definimos los puertos de la DUART para una mayor comodidad a la hora de programar
*puertos especificos por canal
MRA    EQU $EFFC01        	;MR1A y MR2A modo registro
MRB    EQU $EFFC11        	;igual pero para B

ERA    EQU $EFFC03			;para leer estado
CLKA   EQU $EFFC03        	;seleccionar reloj 
ERB    EQU $EFFC13			;para leer estado
CLKB   EQU $EFFC13        	;seleccionar reloj 
* recepcion y transmision 
CTRLA   EQU $EFFC05        	;registro de ctrl A
CTRLB   EQU $EFFC15        	
RBUFA   EQU $EFFC07        	;buffer recepcion para A
TBUFA   EQU $EFFC07        	;transimison para A
RBUFB   EQU $EFFC17        	
TBUFB   EQU $EFFC17     
   	
*puertos comunes a ambos canales
CTRLG  	EQU $EFFC09        	;ctrl de velocidades general
MASKINT EQU $EFFC0B        	;mascara para interrupciones
EINT   	EQU $EFFC0B        	;mismo puerto leer estado interrupciones
VECINT  EQU $EFFC19        	;vector de interrupciones

*descriptores de canal para cada subrutina
DESCRA       EQU 0              	;descriptor recepcion Línea A
DESCRB       EQU 1              	
DESCTA       EQU 2              	;descriptor transmisión Línea A
DESCTB       EQU 3              	

*buffers y parametros para scan y print
DATABUF  DS.B 2100       	;espacio para datos entrantes/salientes
ADDR     DC.L 0          	;dirección base para SCAN/PRINT
TAMB     DC.W 0          	;tamaño en bytes para SCAN/PRINT
CNT      DC.W 0         	;contador interno de bytes pendientes

*tamaño bloque de lectura y escritura
TAMR     EQU  10         	;tamaño bloque a leer en SCAN
TAMT     EQU  5				;tamaño bloque a escribir en PRINT

*ruta final del programa
