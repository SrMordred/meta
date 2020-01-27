all:
	odin run main.odin -collection:meta=meta

dot:
	odin run main.odin -collection:meta=meta > dotfile
	dot -Tpng dotfile > dot.png