all:
# 	odin run main.odin -collection:lib=../src -out=../bin/main.exe
	odin run main.odin -collection:lib=../src > dotfile
	dot -Tpng dotfile > dot.png

dot:
	odin run main.odin -collection:lib=../src > dotfile
	dot -Tpng dotfile > dot.png