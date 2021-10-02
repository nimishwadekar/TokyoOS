OS_NAME = TokyoOS

OVMF = bin/OVMF.fd
CC = gcc
LD = ld
ASSEMBLER = nasm
LINK_SCRIPT = src/kern/link.ld

rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

INCDIR = src/kern/include
SRCDIR = src/kern
OBJDIR = lib/kern
BUILDDIR = bin
LOGDIR = log
UTILSDIR = utils
KERNEL_ELF = $(BUILDDIR)/kernel.elf
OS_IMG = $(BUILDDIR)/$(OS_NAME).img

USRDIR = usr
USROBJDIR = lib/usr
USRELFDIR = disk/ext2dir/usr
USER_ELF = $(USRELFDIR)/main.elf

SRC = $(call rwildcard,$(SRCDIR),*.cpp)
ASMSRC = $(call rwildcard,$(SRCDIR),*.s)
PSFSRC = $(call rwildcard,$(SRCDIR),*.psf)
OBJS = $(patsubst $(SRCDIR)/%.cpp, $(OBJDIR)/%.o, $(SRC))
OBJS += $(patsubst $(SRCDIR)/%.s, $(OBJDIR)/%_s.o, $(ASMSRC))
OBJS += $(patsubst $(SRCDIR)/%.psf, $(OBJDIR)/%_font.o, $(PSFSRC))
DIRS = $(wildcard $(SRCDIR)/*)

MKBOOTIMG = $(UTILSDIR)/mkbootimg
BOOTJSON = $(UTILSDIR)/mkbootimg.json

IGNORE_ERRORS = -Wno-unused-variable -Wno-unused-parameter -Wno-unused-function -Wno-unused-but-set-variable
CFLAGS = -ffreestanding -mno-red-zone -fpic -fno-stack-protector -fno-exceptions -fno-rtti -nostdlib -Werror -Wall -Wextra $(IGNORE_ERRORS)
ASMFLAGS = 
LDFLAGS = -nostdlib -nostartfiles
STRIPFLAGS = -s -K mmio -K fb -K bootboot -K environment -K initstack

all: initdir disk

initdir: kernel
	@mkdir initrd initrd/sys 2>/dev/null | true
	cp $(KERNEL_ELF) initrd/sys/core

disk: initdir $(BOOTJSON)
	./$(MKBOOTIMG) $(BOOTJSON) $(OS_IMG)
	@rm -rf initrd

kernel: $(OBJS) link

$(OBJDIR)/Interrupts/Interrupts.o: $(SRCDIR)/Interrupts/Interrupts.cpp
	@echo !==== COMPILING $^
	mkdir -p $(@D)
	$(CC) -I$(INCDIR) -mno-red-zone -mgeneral-regs-only -ffreestanding -c $^ -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	@echo !==== COMPILING $^
	mkdir -p $(@D)
	$(CC) -I$(INCDIR) $(CFLAGS) -c $^ -o $@

$(OBJDIR)/%_s.o: $(SRCDIR)/%.s
	@echo !==== ASSEMBLING $^
	mkdir -p $(@D)
	$(ASSEMBLER) $(ASMFLAGS) $^ -f elf64 -o $@

$(OBJDIR)/%_font.o: $(SRCDIR)/%.psf
	@echo !==== COMPILING $^
	mkdir -p $(@D)
	@cp $^ ./
	$(LD) $(LDFLAGS) -r -b binary -o $@ font.psf
	@rm font.psf

link:
	@echo !==== LINKING
	$(LD) $(LDFLAGS) -T $(LINK_SCRIPT) $(OBJS) -o $(KERNEL_ELF)
	strip $(STRIPFLAGS) $(KERNEL_ELF)
	readelf -hls $(KERNEL_ELF) > $(LOGDIR)/kernel.x86_64.txt
	
run:
	qemu-system-x86_64 -machine q35 -cpu qemu64 -bios $(OVMF) -m 64 -drive file=$(OS_IMG),format=raw -serial file:log/serial.log

clean:
	rm -rf lib/*



########################################################################################
#############                           User files                         #############
########################################################################################

LIBC_CSRC = $(call rwildcard,src/libc,*.c)
LIBC_SSRC = $(call rwildcard,src/libc,*.s)
LIBC_OBJ = $(patsubst src/libc/%.c, lib/libc/%.o, $(LIBC_CSRC))
LIBC_OBJ += $(patsubst src/libc/%.s, lib/libc/%.o, $(LIBC_SSRC))
LIBC_INC = src/libc/include

USR0_SRC = usr/main.c
USR0_OBJ = $(patsubst usr/%.c, lib/usr/%.o, $(USR0_SRC))
USR0_ELF = $(USRELFDIR)/main.elf

USR1_SRC = usr/spawn.c
USR1_OBJ = $(patsubst usr/%.c, lib/usr/%.o, $(USR1_SRC))
USR1_ELF = $(USRELFDIR)/spawn.elf

########################################################################################


libc: $(LIBC_OBJ)

lib/libc/%.o: src/libc/%.c
	@echo !==== COMPILING LIBC $^
	mkdir -p $(@D)
	$(CC) -I$(LIBC_INC) -ffreestanding -nostdlib -c $^ -o $@

lib/libc/%.o: src/libc/%.s
	@echo !==== COMPILING LIBC $^
	mkdir -p $(@D)
	$(ASSEMBLER) $^ -f elf64 -o $@


user0: $(USR0_OBJ) linkUser0
user1: $(USR1_OBJ) linkUser1

lib/usr/%.o: usr/%.c
	@echo !==== COMPILING USER $^
	mkdir -p $(@D)
	$(CC) -I$(LIBC_INC) -ffreestanding -nostdlib -c $^ -o $@

lib/usr/%.o: usr/%.s
	@echo !==== ASSEMBLING USER $^
	mkdir -p $(@D)
	$(ASSEMBLER) $^ -f elf64 -o $@

linkUser0:
	@echo !==== LINKING USER
	$(LD) $(LDFLAGS) $(USR0_OBJ) $(LIBC_OBJ) -o $(USR0_ELF)

linkUser1:
	@echo !==== LINKING USER
	$(LD) $(LDFLAGS) $(USR1_OBJ) $(LIBC_OBJ) -o $(USR1_ELF)

info:
	$(info $$LIBC_OBJ is [${LIBC_OBJ}])