Assembly = nasm
Format = -f elf64

build:
	$(Assembly) $(Format) -g $(I).asm -o $(I).o

link:
	gcc -g -no-pie -nostartfiles $(I).o -o $(I)
	chmod +x $(I)

clean:
	rm -f $(I).o $(I)
