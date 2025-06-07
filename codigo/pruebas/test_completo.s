
MAIN:
        MOVE.L #$1500,SP     ;Inicializa pila
        BSR INIT             ;Inicializa buffers, DUART
        MOVE.W #$2000,SR     ;Habilita interrupciones


