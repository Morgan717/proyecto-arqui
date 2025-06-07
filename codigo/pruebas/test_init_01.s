    ORG $0
    DC.L START
    ORG $400

START:
    BSR INIT            ;llamamos a INIT
    MOVE.W #$2000,SR    ;habilitamos interrupciones para el MC68k
    RTS                 ;terminamos

    INCLUDE es_int.s

    