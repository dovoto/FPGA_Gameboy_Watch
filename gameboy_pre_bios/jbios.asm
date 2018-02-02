;
; A simple bios to init hardware, load the menu...that sort of thing

SECTION	"Org $00",HOME[$00]
begin:
	

nop	
;load the cart data
ld a, "h"
ld [$ff01], a
ld a, "i"
ld [$ff01], a
ld a, " "
ld [$ff01], a
ld a, "w"
ld [$ff01], a
ld a, $00
ld [$ff83], a
ld a, [$0147]
ld [$ff80], a
ld a, [$0148]
ld [$ff81], a
ld a, [$0149]
ld [$ff82], a


jr begin
