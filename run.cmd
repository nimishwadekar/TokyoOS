@echo off
qemu-system-x86_64 -machine q35 -cpu qemu64 -bios bin/OVMF.fd -m 128 -drive file=bin/TokyoOS.img,format=raw -serial file:log/serial.log