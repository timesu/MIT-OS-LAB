
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		_start
_start:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fb                   	sti    
f0100009:	4f                   	dec    %edi
f010000a:	52                   	push   %edx
f010000b:	e4 66                	in     $0x66,%al

f010000c <_start>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 

	# Establish our own GDT in place of the boot loader's temporary GDT.
	lgdt	RELOC(mygdtdesc)		# load descriptor table
f0100015:	0f 01 15 18 f0 10 00 	lgdtl  0x10f018

	# Immediately reload all segment registers (including CS!)
	# with segment selectors from the new GDT.
	movl	$DATA_SEL, %eax			# Data segment selector
f010001c:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax,%ds				# -> DS: Data Segment
f0100021:	8e d8                	mov    %eax,%ds
	movw	%ax,%es				# -> ES: Extra Segment
f0100023:	8e c0                	mov    %eax,%es
	movw	%ax,%ss				# -> SS: Stack Segment
f0100025:	8e d0                	mov    %eax,%ss
	ljmp	$CODE_SEL,$relocated		# reload CS by jumping
f0100027:	ea 2e 00 10 f0 08 00 	ljmp   $0x8,$0xf010002e

f010002e <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002e:	bd 00 00 00 00       	mov    $0x0,%ebp

        # Set the stack pointer
	movl	$(bootstacktop),%esp
f0100033:	bc 00 f0 10 f0       	mov    $0xf010f000,%esp

	# now to C code
	call	i386_init
f0100038:	e8 60 00 00 00       	call   f010009d <i386_init>

f010003d <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003d:	eb fe                	jmp    f010003d <spin>
	...

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 60 16 10 f0 	movl   $0xf0101660,(%esp)
f0100055:	e8 f0 08 00 00       	call   f010094a <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 25 07 00 00       	call   f01007ac <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 7c 16 10 f0 	movl   $0xf010167c,(%esp)
f0100092:	e8 b3 08 00 00       	call   f010094a <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 80 f9 10 f0       	mov    $0xf010f980,%eax
f01000a8:	2d 20 f3 10 f0       	sub    $0xf010f320,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 20 f3 10 f0 	movl   $0xf010f320,(%esp)
f01000c0:	e8 2c 11 00 00       	call   f01011f1 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 83 05 00 00       	call   f010064d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 97 16 10 f0 	movl   $0xf0101697,(%esp)
f01000d9:	e8 6c 08 00 00       	call   f010094a <cprintf>




	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 c0 06 00 00       	call   f01007b6 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	if (panicstr)
f01000fe:	83 3d 20 f3 10 f0 00 	cmpl   $0x0,0xf010f320
f0100105:	75 40                	jne    f0100147 <_panic+0x4f>
		goto dead;
	panicstr = fmt;
f0100107:	8b 45 10             	mov    0x10(%ebp),%eax
f010010a:	a3 20 f3 10 f0       	mov    %eax,0xf010f320

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
f010010f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100112:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100116:	8b 45 08             	mov    0x8(%ebp),%eax
f0100119:	89 44 24 04          	mov    %eax,0x4(%esp)
f010011d:	c7 04 24 b2 16 10 f0 	movl   $0xf01016b2,(%esp)
f0100124:	e8 21 08 00 00       	call   f010094a <cprintf>

	if (panicstr)
		goto dead;
	panicstr = fmt;

	va_start(ap, fmt);
f0100129:	8d 45 14             	lea    0x14(%ebp),%eax
	cprintf("kernel panic at %s:%d: ", file, line);
	vcprintf(fmt, ap);
f010012c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100130:	8b 45 10             	mov    0x10(%ebp),%eax
f0100133:	89 04 24             	mov    %eax,(%esp)
f0100136:	e8 dc 07 00 00       	call   f0100917 <vcprintf>
	cprintf("\n");
f010013b:	c7 04 24 ee 16 10 f0 	movl   $0xf01016ee,(%esp)
f0100142:	e8 03 08 00 00       	call   f010094a <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100147:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010014e:	e8 63 06 00 00       	call   f01007b6 <monitor>
f0100153:	eb f2                	jmp    f0100147 <_panic+0x4f>

f0100155 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100155:	55                   	push   %ebp
f0100156:	89 e5                	mov    %esp,%ebp
f0100158:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
f010015b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010015e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100162:	8b 45 08             	mov    0x8(%ebp),%eax
f0100165:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100169:	c7 04 24 ca 16 10 f0 	movl   $0xf01016ca,(%esp)
f0100170:	e8 d5 07 00 00       	call   f010094a <cprintf>
void
_warn(const char *file, int line, const char *fmt,...)
{
	va_list ap;

	va_start(ap, fmt);
f0100175:	8d 45 14             	lea    0x14(%ebp),%eax
	cprintf("kernel warning at %s:%d: ", file, line);
	vcprintf(fmt, ap);
f0100178:	89 44 24 04          	mov    %eax,0x4(%esp)
f010017c:	8b 45 10             	mov    0x10(%ebp),%eax
f010017f:	89 04 24             	mov    %eax,(%esp)
f0100182:	e8 90 07 00 00       	call   f0100917 <vcprintf>
	cprintf("\n");
f0100187:	c7 04 24 ee 16 10 f0 	movl   $0xf01016ee,(%esp)
f010018e:	e8 b7 07 00 00       	call   f010094a <cprintf>
	va_end(ap);
}
f0100193:	c9                   	leave  
f0100194:	c3                   	ret    
	...

f01001a0 <serial_proc_data>:

static bool serial_exists;

int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	89 c2                	mov    %eax,%edx
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001ab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
static bool serial_exists;

int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b0:	f6 c2 01             	test   $0x1,%dl
f01001b3:	74 09                	je     f01001be <serial_proc_data+0x1e>
f01001b5:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001ba:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001bb:	0f b6 c0             	movzbl %al,%eax
}
f01001be:	5d                   	pop    %ebp
f01001bf:	c3                   	ret    

f01001c0 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001c0:	55                   	push   %ebp
f01001c1:	89 e5                	mov    %esp,%ebp
f01001c3:	53                   	push   %ebx
f01001c4:	83 ec 14             	sub    $0x14,%esp
f01001c7:	ba 64 00 00 00       	mov    $0x64,%edx
f01001cc:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01001cd:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001d2:	a8 01                	test   $0x1,%al
f01001d4:	0f 84 de 00 00 00    	je     f01002b8 <kbd_proc_data+0xf8>
f01001da:	b2 60                	mov    $0x60,%dl
f01001dc:	ec                   	in     (%dx),%al
f01001dd:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001df:	3c e0                	cmp    $0xe0,%al
f01001e1:	75 11                	jne    f01001f4 <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f01001e3:	83 0d 68 f5 10 f0 40 	orl    $0x40,0xf010f568
		return 0;
f01001ea:	bb 00 00 00 00       	mov    $0x0,%ebx
f01001ef:	e9 c4 00 00 00       	jmp    f01002b8 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01001f4:	84 c0                	test   %al,%al
f01001f6:	79 37                	jns    f010022f <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001f8:	8b 0d 68 f5 10 f0    	mov    0xf010f568,%ecx
f01001fe:	89 cb                	mov    %ecx,%ebx
f0100200:	83 e3 40             	and    $0x40,%ebx
f0100203:	83 e0 7f             	and    $0x7f,%eax
f0100206:	85 db                	test   %ebx,%ebx
f0100208:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010020b:	0f b6 d2             	movzbl %dl,%edx
f010020e:	0f b6 82 20 17 10 f0 	movzbl -0xfefe8e0(%edx),%eax
f0100215:	83 c8 40             	or     $0x40,%eax
f0100218:	0f b6 c0             	movzbl %al,%eax
f010021b:	f7 d0                	not    %eax
f010021d:	21 c1                	and    %eax,%ecx
f010021f:	89 0d 68 f5 10 f0    	mov    %ecx,0xf010f568
		return 0;
f0100225:	bb 00 00 00 00       	mov    $0x0,%ebx
f010022a:	e9 89 00 00 00       	jmp    f01002b8 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f010022f:	8b 0d 68 f5 10 f0    	mov    0xf010f568,%ecx
f0100235:	f6 c1 40             	test   $0x40,%cl
f0100238:	74 0e                	je     f0100248 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010023a:	89 c2                	mov    %eax,%edx
f010023c:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010023f:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100242:	89 0d 68 f5 10 f0    	mov    %ecx,0xf010f568
	}

	shift |= shiftcode[data];
f0100248:	0f b6 d2             	movzbl %dl,%edx
f010024b:	0f b6 82 20 17 10 f0 	movzbl -0xfefe8e0(%edx),%eax
f0100252:	0b 05 68 f5 10 f0    	or     0xf010f568,%eax
	shift ^= togglecode[data];
f0100258:	0f b6 8a 20 18 10 f0 	movzbl -0xfefe7e0(%edx),%ecx
f010025f:	31 c8                	xor    %ecx,%eax
f0100261:	a3 68 f5 10 f0       	mov    %eax,0xf010f568

	c = charcode[shift & (CTL | SHIFT)][data];
f0100266:	89 c1                	mov    %eax,%ecx
f0100268:	83 e1 03             	and    $0x3,%ecx
f010026b:	8b 0c 8d 20 19 10 f0 	mov    -0xfefe6e0(,%ecx,4),%ecx
f0100272:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100276:	a8 08                	test   $0x8,%al
f0100278:	74 19                	je     f0100293 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f010027a:	8d 53 9f             	lea    -0x61(%ebx),%edx
f010027d:	83 fa 19             	cmp    $0x19,%edx
f0100280:	77 05                	ja     f0100287 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f0100282:	83 eb 20             	sub    $0x20,%ebx
f0100285:	eb 0c                	jmp    f0100293 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100287:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f010028a:	8d 53 20             	lea    0x20(%ebx),%edx
f010028d:	83 f9 19             	cmp    $0x19,%ecx
f0100290:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100293:	f7 d0                	not    %eax
f0100295:	a8 06                	test   $0x6,%al
f0100297:	75 1f                	jne    f01002b8 <kbd_proc_data+0xf8>
f0100299:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010029f:	75 17                	jne    f01002b8 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f01002a1:	c7 04 24 e4 16 10 f0 	movl   $0xf01016e4,(%esp)
f01002a8:	e8 9d 06 00 00       	call   f010094a <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ad:	ba 92 00 00 00       	mov    $0x92,%edx
f01002b2:	b8 03 00 00 00       	mov    $0x3,%eax
f01002b7:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002b8:	89 d8                	mov    %ebx,%eax
f01002ba:	83 c4 14             	add    $0x14,%esp
f01002bd:	5b                   	pop    %ebx
f01002be:	5d                   	pop    %ebp
f01002bf:	c3                   	ret    

f01002c0 <serial_init>:
		cons_intr(serial_proc_data);
}

void
serial_init(void)
{
f01002c0:	55                   	push   %ebp
f01002c1:	89 e5                	mov    %esp,%ebp
f01002c3:	53                   	push   %ebx
f01002c4:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01002c9:	b8 00 00 00 00       	mov    $0x0,%eax
f01002ce:	89 da                	mov    %ebx,%edx
f01002d0:	ee                   	out    %al,(%dx)
f01002d1:	b2 fb                	mov    $0xfb,%dl
f01002d3:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01002d8:	ee                   	out    %al,(%dx)
f01002d9:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01002de:	b8 0c 00 00 00       	mov    $0xc,%eax
f01002e3:	89 ca                	mov    %ecx,%edx
f01002e5:	ee                   	out    %al,(%dx)
f01002e6:	b2 f9                	mov    $0xf9,%dl
f01002e8:	b8 00 00 00 00       	mov    $0x0,%eax
f01002ed:	ee                   	out    %al,(%dx)
f01002ee:	b2 fb                	mov    $0xfb,%dl
f01002f0:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f5:	ee                   	out    %al,(%dx)
f01002f6:	b2 fc                	mov    $0xfc,%dl
f01002f8:	b8 00 00 00 00       	mov    $0x0,%eax
f01002fd:	ee                   	out    %al,(%dx)
f01002fe:	b2 f9                	mov    $0xf9,%dl
f0100300:	b8 01 00 00 00       	mov    $0x1,%eax
f0100305:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100306:	b2 fd                	mov    $0xfd,%dl
f0100308:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100309:	3c ff                	cmp    $0xff,%al
f010030b:	0f 95 c0             	setne  %al
f010030e:	0f b6 c0             	movzbl %al,%eax
f0100311:	a3 40 f3 10 f0       	mov    %eax,0xf010f340
f0100316:	89 da                	mov    %ebx,%edx
f0100318:	ec                   	in     (%dx),%al
f0100319:	89 ca                	mov    %ecx,%edx
f010031b:	ec                   	in     (%dx),%al
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

}
f010031c:	5b                   	pop    %ebx
f010031d:	5d                   	pop    %ebp
f010031e:	c3                   	ret    

f010031f <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
cga_init(void)
{
f010031f:	55                   	push   %ebp
f0100320:	89 e5                	mov    %esp,%ebp
f0100322:	83 ec 0c             	sub    $0xc,%esp
f0100325:	89 1c 24             	mov    %ebx,(%esp)
f0100328:	89 74 24 04          	mov    %esi,0x4(%esp)
f010032c:	89 7c 24 08          	mov    %edi,0x8(%esp)
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100330:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100337:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010033e:	5a a5 
	if (*cp != 0xA55A) {
f0100340:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100347:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010034b:	74 11                	je     f010035e <cga_init+0x3f>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010034d:	c7 05 74 f5 10 f0 b4 	movl   $0x3b4,0xf010f574
f0100354:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100357:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010035c:	eb 16                	jmp    f0100374 <cga_init+0x55>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010035e:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100365:	c7 05 74 f5 10 f0 d4 	movl   $0x3d4,0xf010f574
f010036c:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010036f:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100374:	8b 0d 74 f5 10 f0    	mov    0xf010f574,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010037a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010037f:	89 ca                	mov    %ecx,%edx
f0100381:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100382:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100385:	89 da                	mov    %ebx,%edx
f0100387:	ec                   	in     (%dx),%al
f0100388:	0f b6 f8             	movzbl %al,%edi
f010038b:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010038e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100393:	89 ca                	mov    %ecx,%edx
f0100395:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100396:	89 da                	mov    %ebx,%edx
f0100398:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100399:	89 35 70 f5 10 f0    	mov    %esi,0xf010f570
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010039f:	0f b6 d8             	movzbl %al,%ebx
f01003a2:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01003a4:	66 89 3d 6c f5 10 f0 	mov    %di,0xf010f56c
}
f01003ab:	8b 1c 24             	mov    (%esp),%ebx
f01003ae:	8b 74 24 04          	mov    0x4(%esp),%esi
f01003b2:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01003b6:	89 ec                	mov    %ebp,%esp
f01003b8:	5d                   	pop    %ebp
f01003b9:	c3                   	ret    

f01003ba <kbd_init>:
	cons_intr(kbd_proc_data);
}

void
kbd_init(void)
{
f01003ba:	55                   	push   %ebp
f01003bb:	89 e5                	mov    %esp,%ebp
}
f01003bd:	5d                   	pop    %ebp
f01003be:	c3                   	ret    

f01003bf <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
f01003bf:	55                   	push   %ebp
f01003c0:	89 e5                	mov    %esp,%ebp
f01003c2:	53                   	push   %ebx
f01003c3:	83 ec 04             	sub    $0x4,%esp
f01003c6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01003c9:	eb 25                	jmp    f01003f0 <cons_intr+0x31>
		if (c == 0)
f01003cb:	85 c0                	test   %eax,%eax
f01003cd:	74 21                	je     f01003f0 <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f01003cf:	8b 15 64 f5 10 f0    	mov    0xf010f564,%edx
f01003d5:	88 82 60 f3 10 f0    	mov    %al,-0xfef0ca0(%edx)
f01003db:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01003de:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01003e3:	ba 00 00 00 00       	mov    $0x0,%edx
f01003e8:	0f 44 c2             	cmove  %edx,%eax
f01003eb:	a3 64 f5 10 f0       	mov    %eax,0xf010f564
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01003f0:	ff d3                	call   *%ebx
f01003f2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01003f5:	75 d4                	jne    f01003cb <cons_intr+0xc>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01003f7:	83 c4 04             	add    $0x4,%esp
f01003fa:	5b                   	pop    %ebx
f01003fb:	5d                   	pop    %ebp
f01003fc:	c3                   	ret    

f01003fd <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01003fd:	55                   	push   %ebp
f01003fe:	89 e5                	mov    %esp,%ebp
f0100400:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
f0100403:	c7 04 24 c0 01 10 f0 	movl   $0xf01001c0,(%esp)
f010040a:	e8 b0 ff ff ff       	call   f01003bf <cons_intr>
}
f010040f:	c9                   	leave  
f0100410:	c3                   	ret    

f0100411 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100411:	55                   	push   %ebp
f0100412:	89 e5                	mov    %esp,%ebp
f0100414:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
f0100417:	83 3d 40 f3 10 f0 00 	cmpl   $0x0,0xf010f340
f010041e:	74 0c                	je     f010042c <serial_intr+0x1b>
		cons_intr(serial_proc_data);
f0100420:	c7 04 24 a0 01 10 f0 	movl   $0xf01001a0,(%esp)
f0100427:	e8 93 ff ff ff       	call   f01003bf <cons_intr>
}
f010042c:	c9                   	leave  
f010042d:	c3                   	ret    

f010042e <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010042e:	55                   	push   %ebp
f010042f:	89 e5                	mov    %esp,%ebp
f0100431:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100434:	e8 d8 ff ff ff       	call   f0100411 <serial_intr>
	kbd_intr();
f0100439:	e8 bf ff ff ff       	call   f01003fd <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010043e:	8b 15 60 f5 10 f0    	mov    0xf010f560,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100444:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100449:	3b 15 64 f5 10 f0    	cmp    0xf010f564,%edx
f010044f:	74 1e                	je     f010046f <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f0100451:	0f b6 82 60 f3 10 f0 	movzbl -0xfef0ca0(%edx),%eax
f0100458:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f010045b:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100461:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100466:	0f 44 d1             	cmove  %ecx,%edx
f0100469:	89 15 60 f5 10 f0    	mov    %edx,0xf010f560
		return c;
	}
	return 0;
}
f010046f:	c9                   	leave  
f0100470:	c3                   	ret    

f0100471 <cons_putc>:

// output a character to the console
void
cons_putc(int c)
{
f0100471:	55                   	push   %ebp
f0100472:	89 e5                	mov    %esp,%ebp
f0100474:	57                   	push   %edi
f0100475:	56                   	push   %esi
f0100476:	53                   	push   %ebx
f0100477:	83 ec 1c             	sub    $0x1c,%esp
f010047a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010047d:	ba 79 03 00 00       	mov    $0x379,%edx
f0100482:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100483:	84 c0                	test   %al,%al
f0100485:	78 21                	js     f01004a8 <cons_putc+0x37>
f0100487:	bb 00 32 00 00       	mov    $0x3200,%ebx
f010048c:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100491:	be 79 03 00 00       	mov    $0x379,%esi
f0100496:	89 ca                	mov    %ecx,%edx
f0100498:	ec                   	in     (%dx),%al
f0100499:	ec                   	in     (%dx),%al
f010049a:	ec                   	in     (%dx),%al
f010049b:	ec                   	in     (%dx),%al
f010049c:	89 f2                	mov    %esi,%edx
f010049e:	ec                   	in     (%dx),%al
f010049f:	84 c0                	test   %al,%al
f01004a1:	78 05                	js     f01004a8 <cons_putc+0x37>
f01004a3:	83 eb 01             	sub    $0x1,%ebx
f01004a6:	75 ee                	jne    f0100496 <cons_putc+0x25>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004a8:	ba 78 03 00 00       	mov    $0x378,%edx
f01004ad:	89 f8                	mov    %edi,%eax
f01004af:	ee                   	out    %al,(%dx)
f01004b0:	b2 7a                	mov    $0x7a,%dl
f01004b2:	b8 0d 00 00 00       	mov    $0xd,%eax
f01004b7:	ee                   	out    %al,(%dx)
f01004b8:	b8 08 00 00 00       	mov    $0x8,%eax
f01004bd:	ee                   	out    %al,(%dx)
// output a character to the console
void
cons_putc(int c)
{
	lpt_putc(c);
	cga_putc(c);
f01004be:	89 3c 24             	mov    %edi,(%esp)
f01004c1:	e8 08 00 00 00       	call   f01004ce <cga_putc>
}
f01004c6:	83 c4 1c             	add    $0x1c,%esp
f01004c9:	5b                   	pop    %ebx
f01004ca:	5e                   	pop    %esi
f01004cb:	5f                   	pop    %edi
f01004cc:	5d                   	pop    %ebp
f01004cd:	c3                   	ret    

f01004ce <cga_putc>:



void
cga_putc(int c)
{
f01004ce:	55                   	push   %ebp
f01004cf:	89 e5                	mov    %esp,%ebp
f01004d1:	56                   	push   %esi
f01004d2:	53                   	push   %ebx
f01004d3:	83 ec 10             	sub    $0x10,%esp
f01004d6:	8b 45 08             	mov    0x8(%ebp),%eax
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004d9:	89 c1                	mov    %eax,%ecx
f01004db:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f01004e1:	89 c2                	mov    %eax,%edx
f01004e3:	80 ce 07             	or     $0x7,%dh
f01004e6:	85 c9                	test   %ecx,%ecx
f01004e8:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f01004eb:	0f b6 d0             	movzbl %al,%edx
f01004ee:	83 fa 09             	cmp    $0x9,%edx
f01004f1:	74 7c                	je     f010056f <cga_putc+0xa1>
f01004f3:	83 fa 09             	cmp    $0x9,%edx
f01004f6:	7f 0b                	jg     f0100503 <cga_putc+0x35>
f01004f8:	83 fa 08             	cmp    $0x8,%edx
f01004fb:	0f 85 ac 00 00 00    	jne    f01005ad <cga_putc+0xdf>
f0100501:	eb 15                	jmp    f0100518 <cga_putc+0x4a>
f0100503:	83 fa 0a             	cmp    $0xa,%edx
f0100506:	74 41                	je     f0100549 <cga_putc+0x7b>
f0100508:	83 fa 0d             	cmp    $0xd,%edx
f010050b:	90                   	nop
f010050c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100510:	0f 85 97 00 00 00    	jne    f01005ad <cga_putc+0xdf>
f0100516:	eb 39                	jmp    f0100551 <cga_putc+0x83>
	case '\b':
		if (crt_pos > 0) {
f0100518:	0f b7 15 6c f5 10 f0 	movzwl 0xf010f56c,%edx
f010051f:	66 85 d2             	test   %dx,%dx
f0100522:	0f 84 f0 00 00 00    	je     f0100618 <cga_putc+0x14a>
			crt_pos--;
f0100528:	83 ea 01             	sub    $0x1,%edx
f010052b:	66 89 15 6c f5 10 f0 	mov    %dx,0xf010f56c
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100532:	0f b7 d2             	movzwl %dx,%edx
f0100535:	b0 00                	mov    $0x0,%al
f0100537:	83 c8 20             	or     $0x20,%eax
f010053a:	8b 0d 70 f5 10 f0    	mov    0xf010f570,%ecx
f0100540:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100544:	e9 82 00 00 00       	jmp    f01005cb <cga_putc+0xfd>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100549:	66 83 05 6c f5 10 f0 	addw   $0x50,0xf010f56c
f0100550:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100551:	0f b7 05 6c f5 10 f0 	movzwl 0xf010f56c,%eax
f0100558:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010055e:	c1 e8 16             	shr    $0x16,%eax
f0100561:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100564:	c1 e0 04             	shl    $0x4,%eax
f0100567:	66 a3 6c f5 10 f0    	mov    %ax,0xf010f56c
		break;
f010056d:	eb 5c                	jmp    f01005cb <cga_putc+0xfd>
	case '\t':
		cons_putc(' ');
f010056f:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100576:	e8 f6 fe ff ff       	call   f0100471 <cons_putc>
		cons_putc(' ');
f010057b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100582:	e8 ea fe ff ff       	call   f0100471 <cons_putc>
		cons_putc(' ');
f0100587:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010058e:	e8 de fe ff ff       	call   f0100471 <cons_putc>
		cons_putc(' ');
f0100593:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010059a:	e8 d2 fe ff ff       	call   f0100471 <cons_putc>
		cons_putc(' ');
f010059f:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01005a6:	e8 c6 fe ff ff       	call   f0100471 <cons_putc>
		break;
f01005ab:	eb 1e                	jmp    f01005cb <cga_putc+0xfd>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01005ad:	0f b7 15 6c f5 10 f0 	movzwl 0xf010f56c,%edx
f01005b4:	0f b7 da             	movzwl %dx,%ebx
f01005b7:	8b 0d 70 f5 10 f0    	mov    0xf010f570,%ecx
f01005bd:	66 89 04 59          	mov    %ax,(%ecx,%ebx,2)
f01005c1:	83 c2 01             	add    $0x1,%edx
f01005c4:	66 89 15 6c f5 10 f0 	mov    %dx,0xf010f56c
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005cb:	66 81 3d 6c f5 10 f0 	cmpw   $0x7cf,0xf010f56c
f01005d2:	cf 07 
f01005d4:	76 42                	jbe    f0100618 <cga_putc+0x14a>
		int i;

		memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005d6:	a1 70 f5 10 f0       	mov    0xf010f570,%eax
f01005db:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01005e2:	00 
f01005e3:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005e9:	89 54 24 04          	mov    %edx,0x4(%esp)
f01005ed:	89 04 24             	mov    %eax,(%esp)
f01005f0:	e8 21 0c 00 00       	call   f0101216 <memcpy>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005f5:	8b 15 70 f5 10 f0    	mov    0xf010f570,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005fb:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100600:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100606:	83 c0 01             	add    $0x1,%eax
f0100609:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010060e:	75 f0                	jne    f0100600 <cga_putc+0x132>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100610:	66 83 2d 6c f5 10 f0 	subw   $0x50,0xf010f56c
f0100617:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100618:	8b 0d 74 f5 10 f0    	mov    0xf010f574,%ecx
f010061e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100623:	89 ca                	mov    %ecx,%edx
f0100625:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100626:	0f b7 35 6c f5 10 f0 	movzwl 0xf010f56c,%esi
f010062d:	8d 59 01             	lea    0x1(%ecx),%ebx
f0100630:	89 f0                	mov    %esi,%eax
f0100632:	66 c1 e8 08          	shr    $0x8,%ax
f0100636:	89 da                	mov    %ebx,%edx
f0100638:	ee                   	out    %al,(%dx)
f0100639:	b8 0f 00 00 00       	mov    $0xf,%eax
f010063e:	89 ca                	mov    %ecx,%edx
f0100640:	ee                   	out    %al,(%dx)
f0100641:	89 f0                	mov    %esi,%eax
f0100643:	89 da                	mov    %ebx,%edx
f0100645:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
	outb(addr_6845 + 1, crt_pos);
}
f0100646:	83 c4 10             	add    $0x10,%esp
f0100649:	5b                   	pop    %ebx
f010064a:	5e                   	pop    %esi
f010064b:	5d                   	pop    %ebp
f010064c:	c3                   	ret    

f010064d <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010064d:	55                   	push   %ebp
f010064e:	89 e5                	mov    %esp,%ebp
f0100650:	83 ec 18             	sub    $0x18,%esp
	cga_init();
f0100653:	e8 c7 fc ff ff       	call   f010031f <cga_init>
	kbd_init();
	serial_init();
f0100658:	e8 63 fc ff ff       	call   f01002c0 <serial_init>

	if (!serial_exists)
f010065d:	83 3d 40 f3 10 f0 00 	cmpl   $0x0,0xf010f340
f0100664:	75 0c                	jne    f0100672 <cons_init+0x25>
		cprintf("Serial port does not exist!\n");
f0100666:	c7 04 24 f0 16 10 f0 	movl   $0xf01016f0,(%esp)
f010066d:	e8 d8 02 00 00       	call   f010094a <cprintf>
}
f0100672:	c9                   	leave  
f0100673:	c3                   	ret    

f0100674 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100674:	55                   	push   %ebp
f0100675:	89 e5                	mov    %esp,%ebp
f0100677:	83 ec 18             	sub    $0x18,%esp
	cons_putc(c);
f010067a:	8b 45 08             	mov    0x8(%ebp),%eax
f010067d:	89 04 24             	mov    %eax,(%esp)
f0100680:	e8 ec fd ff ff       	call   f0100471 <cons_putc>
}
f0100685:	c9                   	leave  
f0100686:	c3                   	ret    

f0100687 <getchar>:

int
getchar(void)
{
f0100687:	55                   	push   %ebp
f0100688:	89 e5                	mov    %esp,%ebp
f010068a:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010068d:	e8 9c fd ff ff       	call   f010042e <cons_getc>
f0100692:	85 c0                	test   %eax,%eax
f0100694:	74 f7                	je     f010068d <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100696:	c9                   	leave  
f0100697:	c3                   	ret    

f0100698 <iscons>:

int
iscons(int fdnum)
{
f0100698:	55                   	push   %ebp
f0100699:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010069b:	b8 01 00 00 00       	mov    $0x1,%eax
f01006a0:	5d                   	pop    %ebp
f01006a1:	c3                   	ret    
	...

f01006b0 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006b0:	55                   	push   %ebp
f01006b1:	89 e5                	mov    %esp,%ebp
f01006b3:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006b6:	c7 04 24 30 19 10 f0 	movl   $0xf0101930,(%esp)
f01006bd:	e8 88 02 00 00       	call   f010094a <cprintf>
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
f01006c2:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006c9:	00 
f01006ca:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006d1:	f0 
f01006d2:	c7 04 24 bc 19 10 f0 	movl   $0xf01019bc,(%esp)
f01006d9:	e8 6c 02 00 00       	call   f010094a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006de:	c7 44 24 08 55 16 10 	movl   $0x101655,0x8(%esp)
f01006e5:	00 
f01006e6:	c7 44 24 04 55 16 10 	movl   $0xf0101655,0x4(%esp)
f01006ed:	f0 
f01006ee:	c7 04 24 e0 19 10 f0 	movl   $0xf01019e0,(%esp)
f01006f5:	e8 50 02 00 00       	call   f010094a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006fa:	c7 44 24 08 20 f3 10 	movl   $0x10f320,0x8(%esp)
f0100701:	00 
f0100702:	c7 44 24 04 20 f3 10 	movl   $0xf010f320,0x4(%esp)
f0100709:	f0 
f010070a:	c7 04 24 04 1a 10 f0 	movl   $0xf0101a04,(%esp)
f0100711:	e8 34 02 00 00       	call   f010094a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100716:	c7 44 24 08 80 f9 10 	movl   $0x10f980,0x8(%esp)
f010071d:	00 
f010071e:	c7 44 24 04 80 f9 10 	movl   $0xf010f980,0x4(%esp)
f0100725:	f0 
f0100726:	c7 04 24 28 1a 10 f0 	movl   $0xf0101a28,(%esp)
f010072d:	e8 18 02 00 00       	call   f010094a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-_start+1023)/1024);
f0100732:	b8 0c 00 10 f0       	mov    $0xf010000c,%eax
f0100737:	f7 d8                	neg    %eax
f0100739:	05 7f fd 10 f0       	add    $0xf010fd7f,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010073e:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100744:	85 c0                	test   %eax,%eax
f0100746:	0f 48 c2             	cmovs  %edx,%eax
f0100749:	c1 f8 0a             	sar    $0xa,%eax
f010074c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100750:	c7 04 24 4c 1a 10 f0 	movl   $0xf0101a4c,(%esp)
f0100757:	e8 ee 01 00 00       	call   f010094a <cprintf>
		(end-_start+1023)/1024);
	return 0;
}
f010075c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100761:	c9                   	leave  
f0100762:	c3                   	ret    

f0100763 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100763:	55                   	push   %ebp
f0100764:	89 e5                	mov    %esp,%ebp
f0100766:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100769:	a1 f0 1a 10 f0       	mov    0xf0101af0,%eax
f010076e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100772:	a1 ec 1a 10 f0       	mov    0xf0101aec,%eax
f0100777:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077b:	c7 04 24 49 19 10 f0 	movl   $0xf0101949,(%esp)
f0100782:	e8 c3 01 00 00       	call   f010094a <cprintf>
f0100787:	a1 fc 1a 10 f0       	mov    0xf0101afc,%eax
f010078c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100790:	a1 f8 1a 10 f0       	mov    0xf0101af8,%eax
f0100795:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100799:	c7 04 24 49 19 10 f0 	movl   $0xf0101949,(%esp)
f01007a0:	e8 a5 01 00 00       	call   f010094a <cprintf>
	return 0;
}
f01007a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01007aa:	c9                   	leave  
f01007ab:	c3                   	ret    

f01007ac <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007ac:	55                   	push   %ebp
f01007ad:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f01007af:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b4:	5d                   	pop    %ebp
f01007b5:	c3                   	ret    

f01007b6 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007b6:	55                   	push   %ebp
f01007b7:	89 e5                	mov    %esp,%ebp
f01007b9:	57                   	push   %edi
f01007ba:	56                   	push   %esi
f01007bb:	53                   	push   %ebx
f01007bc:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007bf:	c7 04 24 78 1a 10 f0 	movl   $0xf0101a78,(%esp)
f01007c6:	e8 7f 01 00 00       	call   f010094a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007cb:	c7 04 24 9c 1a 10 f0 	movl   $0xf0101a9c,(%esp)
f01007d2:	e8 73 01 00 00       	call   f010094a <cprintf>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f01007d7:	8d 7d a8             	lea    -0x58(%ebp),%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f01007da:	c7 04 24 52 19 10 f0 	movl   $0xf0101952,(%esp)
f01007e1:	e8 9a 07 00 00       	call   f0100f80 <readline>
f01007e6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007e8:	85 c0                	test   %eax,%eax
f01007ea:	74 ee                	je     f01007da <monitor+0x24>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007ec:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007f3:	be 00 00 00 00       	mov    $0x0,%esi
f01007f8:	eb 06                	jmp    f0100800 <monitor+0x4a>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007fa:	c6 03 00             	movb   $0x0,(%ebx)
f01007fd:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100800:	0f b6 03             	movzbl (%ebx),%eax
f0100803:	84 c0                	test   %al,%al
f0100805:	74 6a                	je     f0100871 <monitor+0xbb>
f0100807:	0f be c0             	movsbl %al,%eax
f010080a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010080e:	c7 04 24 56 19 10 f0 	movl   $0xf0101956,(%esp)
f0100815:	e8 77 09 00 00       	call   f0101191 <strchr>
f010081a:	85 c0                	test   %eax,%eax
f010081c:	75 dc                	jne    f01007fa <monitor+0x44>
			*buf++ = 0;
		if (*buf == 0)
f010081e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100821:	74 4e                	je     f0100871 <monitor+0xbb>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100823:	83 fe 0f             	cmp    $0xf,%esi
f0100826:	75 16                	jne    f010083e <monitor+0x88>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100828:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010082f:	00 
f0100830:	c7 04 24 5b 19 10 f0 	movl   $0xf010195b,(%esp)
f0100837:	e8 0e 01 00 00       	call   f010094a <cprintf>
f010083c:	eb 9c                	jmp    f01007da <monitor+0x24>
			return 0;
		}
		argv[argc++] = buf;
f010083e:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100842:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100845:	0f b6 03             	movzbl (%ebx),%eax
f0100848:	84 c0                	test   %al,%al
f010084a:	75 0c                	jne    f0100858 <monitor+0xa2>
f010084c:	eb b2                	jmp    f0100800 <monitor+0x4a>
			buf++;
f010084e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100851:	0f b6 03             	movzbl (%ebx),%eax
f0100854:	84 c0                	test   %al,%al
f0100856:	74 a8                	je     f0100800 <monitor+0x4a>
f0100858:	0f be c0             	movsbl %al,%eax
f010085b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010085f:	c7 04 24 56 19 10 f0 	movl   $0xf0101956,(%esp)
f0100866:	e8 26 09 00 00       	call   f0101191 <strchr>
f010086b:	85 c0                	test   %eax,%eax
f010086d:	74 df                	je     f010084e <monitor+0x98>
f010086f:	eb 8f                	jmp    f0100800 <monitor+0x4a>
			buf++;
	}
	argv[argc] = 0;
f0100871:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100878:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100879:	85 f6                	test   %esi,%esi
f010087b:	0f 84 59 ff ff ff    	je     f01007da <monitor+0x24>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100881:	a1 ec 1a 10 f0       	mov    0xf0101aec,%eax
f0100886:	89 44 24 04          	mov    %eax,0x4(%esp)
f010088a:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010088d:	89 04 24             	mov    %eax,(%esp)
f0100890:	e8 82 08 00 00       	call   f0101117 <strcmp>
f0100895:	ba 00 00 00 00       	mov    $0x0,%edx
f010089a:	85 c0                	test   %eax,%eax
f010089c:	74 1d                	je     f01008bb <monitor+0x105>
f010089e:	a1 f8 1a 10 f0       	mov    0xf0101af8,%eax
f01008a3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008a7:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008aa:	89 04 24             	mov    %eax,(%esp)
f01008ad:	e8 65 08 00 00       	call   f0101117 <strcmp>
f01008b2:	85 c0                	test   %eax,%eax
f01008b4:	75 25                	jne    f01008db <monitor+0x125>
f01008b6:	ba 01 00 00 00       	mov    $0x1,%edx
			return commands[i].func(argc, argv, tf);
f01008bb:	6b d2 0c             	imul   $0xc,%edx,%edx
f01008be:	8b 45 08             	mov    0x8(%ebp),%eax
f01008c1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01008c5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01008c9:	89 34 24             	mov    %esi,(%esp)
f01008cc:	ff 92 f4 1a 10 f0    	call   *-0xfefe50c(%edx)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008d2:	85 c0                	test   %eax,%eax
f01008d4:	78 1d                	js     f01008f3 <monitor+0x13d>
f01008d6:	e9 ff fe ff ff       	jmp    f01007da <monitor+0x24>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008db:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008de:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e2:	c7 04 24 78 19 10 f0 	movl   $0xf0101978,(%esp)
f01008e9:	e8 5c 00 00 00       	call   f010094a <cprintf>
f01008ee:	e9 e7 fe ff ff       	jmp    f01007da <monitor+0x24>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008f3:	83 c4 5c             	add    $0x5c,%esp
f01008f6:	5b                   	pop    %ebx
f01008f7:	5e                   	pop    %esi
f01008f8:	5f                   	pop    %edi
f01008f9:	5d                   	pop    %ebp
f01008fa:	c3                   	ret    

f01008fb <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f01008fb:	55                   	push   %ebp
f01008fc:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01008fe:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100901:	5d                   	pop    %ebp
f0100902:	c3                   	ret    
	...

f0100904 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100904:	55                   	push   %ebp
f0100905:	89 e5                	mov    %esp,%ebp
f0100907:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010090a:	8b 45 08             	mov    0x8(%ebp),%eax
f010090d:	89 04 24             	mov    %eax,(%esp)
f0100910:	e8 5f fd ff ff       	call   f0100674 <cputchar>
	*cnt++;
}
f0100915:	c9                   	leave  
f0100916:	c3                   	ret    

f0100917 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100917:	55                   	push   %ebp
f0100918:	89 e5                	mov    %esp,%ebp
f010091a:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010091d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100924:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100927:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010092b:	8b 45 08             	mov    0x8(%ebp),%eax
f010092e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100932:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100935:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100939:	c7 04 24 04 09 10 f0 	movl   $0xf0100904,(%esp)
f0100940:	e8 95 01 00 00       	call   f0100ada <vprintfmt>
	return cnt;
}
f0100945:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100948:	c9                   	leave  
f0100949:	c3                   	ret    

f010094a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010094a:	55                   	push   %ebp
f010094b:	89 e5                	mov    %esp,%ebp
f010094d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100950:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100953:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100957:	8b 45 08             	mov    0x8(%ebp),%eax
f010095a:	89 04 24             	mov    %eax,(%esp)
f010095d:	e8 b5 ff ff ff       	call   f0100917 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100962:	c9                   	leave  
f0100963:	c3                   	ret    
	...

f0100970 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100970:	55                   	push   %ebp
f0100971:	89 e5                	mov    %esp,%ebp
f0100973:	57                   	push   %edi
f0100974:	56                   	push   %esi
f0100975:	53                   	push   %ebx
f0100976:	83 ec 4c             	sub    $0x4c,%esp
f0100979:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010097c:	89 d6                	mov    %edx,%esi
f010097e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100981:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100984:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100987:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010098a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010098d:	8b 7d 18             	mov    0x18(%ebp),%edi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100990:	b8 00 00 00 00       	mov    $0x0,%eax
f0100995:	39 d0                	cmp    %edx,%eax
f0100997:	72 11                	jb     f01009aa <printnum+0x3a>
f0100999:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010099c:	39 4d 10             	cmp    %ecx,0x10(%ebp)
f010099f:	76 09                	jbe    f01009aa <printnum+0x3a>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01009a1:	83 eb 01             	sub    $0x1,%ebx
f01009a4:	85 db                	test   %ebx,%ebx
f01009a6:	7f 5d                	jg     f0100a05 <printnum+0x95>
f01009a8:	eb 6c                	jmp    f0100a16 <printnum+0xa6>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01009aa:	89 7c 24 10          	mov    %edi,0x10(%esp)
f01009ae:	83 eb 01             	sub    $0x1,%ebx
f01009b1:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01009b5:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01009b8:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01009bc:	8b 44 24 08          	mov    0x8(%esp),%eax
f01009c0:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01009c4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01009c7:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01009ca:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01009d1:	00 
f01009d2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01009d5:	89 14 24             	mov    %edx,(%esp)
f01009d8:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01009db:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01009df:	e8 1c 0a 00 00       	call   f0101400 <__udivdi3>
f01009e4:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01009e7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01009ea:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01009ee:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01009f2:	89 04 24             	mov    %eax,(%esp)
f01009f5:	89 54 24 04          	mov    %edx,0x4(%esp)
f01009f9:	89 f2                	mov    %esi,%edx
f01009fb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009fe:	e8 6d ff ff ff       	call   f0100970 <printnum>
f0100a03:	eb 11                	jmp    f0100a16 <printnum+0xa6>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100a05:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100a09:	89 3c 24             	mov    %edi,(%esp)
f0100a0c:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100a0f:	83 eb 01             	sub    $0x1,%ebx
f0100a12:	85 db                	test   %ebx,%ebx
f0100a14:	7f ef                	jg     f0100a05 <printnum+0x95>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100a16:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100a1a:	8b 74 24 04          	mov    0x4(%esp),%esi
f0100a1e:	8b 45 10             	mov    0x10(%ebp),%eax
f0100a21:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a25:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100a2c:	00 
f0100a2d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a30:	89 14 24             	mov    %edx,(%esp)
f0100a33:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100a36:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100a3a:	e8 d1 0a 00 00       	call   f0101510 <__umoddi3>
f0100a3f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100a43:	0f be 80 04 1b 10 f0 	movsbl -0xfefe4fc(%eax),%eax
f0100a4a:	89 04 24             	mov    %eax,(%esp)
f0100a4d:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100a50:	83 c4 4c             	add    $0x4c,%esp
f0100a53:	5b                   	pop    %ebx
f0100a54:	5e                   	pop    %esi
f0100a55:	5f                   	pop    %edi
f0100a56:	5d                   	pop    %ebp
f0100a57:	c3                   	ret    

f0100a58 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100a58:	55                   	push   %ebp
f0100a59:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100a5b:	83 fa 01             	cmp    $0x1,%edx
f0100a5e:	7e 0f                	jle    f0100a6f <getuint+0x17>
		return va_arg(*ap, unsigned long long);
f0100a60:	8b 10                	mov    (%eax),%edx
f0100a62:	83 c2 08             	add    $0x8,%edx
f0100a65:	89 10                	mov    %edx,(%eax)
f0100a67:	8b 42 f8             	mov    -0x8(%edx),%eax
f0100a6a:	8b 52 fc             	mov    -0x4(%edx),%edx
f0100a6d:	eb 24                	jmp    f0100a93 <getuint+0x3b>
	else if (lflag)
f0100a6f:	85 d2                	test   %edx,%edx
f0100a71:	74 11                	je     f0100a84 <getuint+0x2c>
		return va_arg(*ap, unsigned long);
f0100a73:	8b 10                	mov    (%eax),%edx
f0100a75:	83 c2 04             	add    $0x4,%edx
f0100a78:	89 10                	mov    %edx,(%eax)
f0100a7a:	8b 42 fc             	mov    -0x4(%edx),%eax
f0100a7d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100a82:	eb 0f                	jmp    f0100a93 <getuint+0x3b>
	else
		return va_arg(*ap, unsigned int);
f0100a84:	8b 10                	mov    (%eax),%edx
f0100a86:	83 c2 04             	add    $0x4,%edx
f0100a89:	89 10                	mov    %edx,(%eax)
f0100a8b:	8b 42 fc             	mov    -0x4(%edx),%eax
f0100a8e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100a93:	5d                   	pop    %ebp
f0100a94:	c3                   	ret    

f0100a95 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100a95:	55                   	push   %ebp
f0100a96:	89 e5                	mov    %esp,%ebp
f0100a98:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100a9b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100a9f:	8b 10                	mov    (%eax),%edx
f0100aa1:	3b 50 04             	cmp    0x4(%eax),%edx
f0100aa4:	73 0a                	jae    f0100ab0 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100aa6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100aa9:	88 0a                	mov    %cl,(%edx)
f0100aab:	83 c2 01             	add    $0x1,%edx
f0100aae:	89 10                	mov    %edx,(%eax)
}
f0100ab0:	5d                   	pop    %ebp
f0100ab1:	c3                   	ret    

f0100ab2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100ab2:	55                   	push   %ebp
f0100ab3:	89 e5                	mov    %esp,%ebp
f0100ab5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100ab8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100abb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100abf:	8b 45 10             	mov    0x10(%ebp),%eax
f0100ac2:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ac6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ac9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100acd:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ad0:	89 04 24             	mov    %eax,(%esp)
f0100ad3:	e8 02 00 00 00       	call   f0100ada <vprintfmt>
	va_end(ap);
}
f0100ad8:	c9                   	leave  
f0100ad9:	c3                   	ret    

f0100ada <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100ada:	55                   	push   %ebp
f0100adb:	89 e5                	mov    %esp,%ebp
f0100add:	57                   	push   %edi
f0100ade:	56                   	push   %esi
f0100adf:	53                   	push   %ebx
f0100ae0:	83 ec 4c             	sub    $0x4c,%esp
f0100ae3:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100ae6:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100ae9:	eb 12                	jmp    f0100afd <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100aeb:	85 c0                	test   %eax,%eax
f0100aed:	0f 84 f9 03 00 00    	je     f0100eec <vprintfmt+0x412>
				return;
			putch(ch, putdat);
f0100af3:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100af7:	89 04 24             	mov    %eax,(%esp)
f0100afa:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100afd:	0f b6 03             	movzbl (%ebx),%eax
f0100b00:	83 c3 01             	add    $0x1,%ebx
f0100b03:	83 f8 25             	cmp    $0x25,%eax
f0100b06:	75 e3                	jne    f0100aeb <vprintfmt+0x11>
f0100b08:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100b0c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100b13:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100b18:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100b1f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100b24:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100b27:	eb 2b                	jmp    f0100b54 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100b29:	8b 5d e0             	mov    -0x20(%ebp),%ebx

		// flag to pad on the right
		case '-':
			padc = '-';
f0100b2c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100b30:	eb 22                	jmp    f0100b54 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100b32:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100b35:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100b39:	eb 19                	jmp    f0100b54 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100b3b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100b3e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100b45:	eb 0d                	jmp    f0100b54 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100b47:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100b4a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100b4d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100b54:	0f b6 03             	movzbl (%ebx),%eax
f0100b57:	0f b6 d0             	movzbl %al,%edx
f0100b5a:	8d 73 01             	lea    0x1(%ebx),%esi
f0100b5d:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0100b60:	83 e8 23             	sub    $0x23,%eax
f0100b63:	3c 55                	cmp    $0x55,%al
f0100b65:	0f 87 61 03 00 00    	ja     f0100ecc <vprintfmt+0x3f2>
f0100b6b:	0f b6 c0             	movzbl %al,%eax
f0100b6e:	ff 24 85 94 1b 10 f0 	jmp    *-0xfefe46c(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100b75:	83 ea 30             	sub    $0x30,%edx
f0100b78:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f0100b7b:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0100b7e:	0f be 02             	movsbl (%edx),%eax
				if (ch < '0' || ch > '9')
f0100b81:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100b84:	8b 5d e0             	mov    -0x20(%ebp),%ebx
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0100b87:	83 fa 09             	cmp    $0x9,%edx
f0100b8a:	77 4f                	ja     f0100bdb <vprintfmt+0x101>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100b8c:	8b 75 d4             	mov    -0x2c(%ebp),%esi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100b8f:	83 c3 01             	add    $0x1,%ebx
				precision = precision * 10 + ch - '0';
f0100b92:	8d 14 b6             	lea    (%esi,%esi,4),%edx
f0100b95:	8d 74 50 d0          	lea    -0x30(%eax,%edx,2),%esi
				ch = *fmt;
f0100b99:	0f be 03             	movsbl (%ebx),%eax
				if (ch < '0' || ch > '9')
f0100b9c:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100b9f:	83 fa 09             	cmp    $0x9,%edx
f0100ba2:	76 eb                	jbe    f0100b8f <vprintfmt+0xb5>
f0100ba4:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100ba7:	eb 32                	jmp    f0100bdb <vprintfmt+0x101>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100ba9:	8b 45 14             	mov    0x14(%ebp),%eax
f0100bac:	83 c0 04             	add    $0x4,%eax
f0100baf:	89 45 14             	mov    %eax,0x14(%ebp)
f0100bb2:	8b 40 fc             	mov    -0x4(%eax),%eax
f0100bb5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100bb8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100bbb:	eb 1e                	jmp    f0100bdb <vprintfmt+0x101>

		case '.':
			if (width < 0)
f0100bbd:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100bc1:	0f 88 74 ff ff ff    	js     f0100b3b <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100bc7:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100bca:	eb 88                	jmp    f0100b54 <vprintfmt+0x7a>
f0100bcc:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100bcf:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0100bd6:	e9 79 ff ff ff       	jmp    f0100b54 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0100bdb:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100bdf:	0f 89 6f ff ff ff    	jns    f0100b54 <vprintfmt+0x7a>
f0100be5:	e9 5d ff ff ff       	jmp    f0100b47 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100bea:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100bed:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100bf0:	e9 5f ff ff ff       	jmp    f0100b54 <vprintfmt+0x7a>
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100bf5:	8b 45 14             	mov    0x14(%ebp),%eax
f0100bf8:	83 c0 04             	add    $0x4,%eax
f0100bfb:	89 45 14             	mov    %eax,0x14(%ebp)
f0100bfe:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c02:	8b 40 fc             	mov    -0x4(%eax),%eax
f0100c05:	89 04 24             	mov    %eax,(%esp)
f0100c08:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100c0b:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100c0e:	e9 ea fe ff ff       	jmp    f0100afd <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100c13:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c16:	83 c0 04             	add    $0x4,%eax
f0100c19:	89 45 14             	mov    %eax,0x14(%ebp)
f0100c1c:	8b 40 fc             	mov    -0x4(%eax),%eax
f0100c1f:	89 c2                	mov    %eax,%edx
f0100c21:	c1 fa 1f             	sar    $0x1f,%edx
f0100c24:	31 d0                	xor    %edx,%eax
f0100c26:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f0100c28:	83 f8 06             	cmp    $0x6,%eax
f0100c2b:	7f 0b                	jg     f0100c38 <vprintfmt+0x15e>
f0100c2d:	8b 14 85 ec 1c 10 f0 	mov    -0xfefe314(,%eax,4),%edx
f0100c34:	85 d2                	test   %edx,%edx
f0100c36:	75 23                	jne    f0100c5b <vprintfmt+0x181>
				printfmt(putch, putdat, "error %d", err);
f0100c38:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c3c:	c7 44 24 08 1c 1b 10 	movl   $0xf0101b1c,0x8(%esp)
f0100c43:	f0 
f0100c44:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c48:	8b 75 08             	mov    0x8(%ebp),%esi
f0100c4b:	89 34 24             	mov    %esi,(%esp)
f0100c4e:	e8 5f fe ff ff       	call   f0100ab2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100c53:	8b 5d e0             	mov    -0x20(%ebp),%ebx
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100c56:	e9 a2 fe ff ff       	jmp    f0100afd <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0100c5b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100c5f:	c7 44 24 08 25 1b 10 	movl   $0xf0101b25,0x8(%esp)
f0100c66:	f0 
f0100c67:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c6b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c6e:	89 04 24             	mov    %eax,(%esp)
f0100c71:	e8 3c fe ff ff       	call   f0100ab2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100c76:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100c79:	e9 7f fe ff ff       	jmp    f0100afd <vprintfmt+0x23>
f0100c7e:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100c81:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100c84:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c87:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100c8a:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c8d:	83 c0 04             	add    $0x4,%eax
f0100c90:	89 45 14             	mov    %eax,0x14(%ebp)
f0100c93:	8b 40 fc             	mov    -0x4(%eax),%eax
f0100c96:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				p = "(null)";
f0100c99:	85 c0                	test   %eax,%eax
f0100c9b:	b8 15 1b 10 f0       	mov    $0xf0101b15,%eax
f0100ca0:	0f 45 45 d4          	cmovne -0x2c(%ebp),%eax
f0100ca4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
			if (width > 0 && padc != '-')
f0100ca7:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0100cab:	7e 06                	jle    f0100cb3 <vprintfmt+0x1d9>
f0100cad:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0100cb1:	75 13                	jne    f0100cc6 <vprintfmt+0x1ec>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100cb3:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100cb6:	0f be 02             	movsbl (%edx),%eax
f0100cb9:	85 c0                	test   %eax,%eax
f0100cbb:	0f 85 97 00 00 00    	jne    f0100d58 <vprintfmt+0x27e>
f0100cc1:	e9 84 00 00 00       	jmp    f0100d4a <vprintfmt+0x270>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100cc6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100cca:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ccd:	89 04 24             	mov    %eax,(%esp)
f0100cd0:	e8 86 03 00 00       	call   f010105b <strnlen>
f0100cd5:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100cd8:	29 c2                	sub    %eax,%edx
f0100cda:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100cdd:	85 d2                	test   %edx,%edx
f0100cdf:	7e d2                	jle    f0100cb3 <vprintfmt+0x1d9>
					putch(padc, putdat);
f0100ce1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0100ce5:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0100ce8:	89 5d cc             	mov    %ebx,-0x34(%ebp)
f0100ceb:	89 d3                	mov    %edx,%ebx
f0100ced:	89 c6                	mov    %eax,%esi
f0100cef:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cf3:	89 34 24             	mov    %esi,(%esp)
f0100cf6:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100cf9:	83 eb 01             	sub    $0x1,%ebx
f0100cfc:	85 db                	test   %ebx,%ebx
f0100cfe:	7f ef                	jg     f0100cef <vprintfmt+0x215>
f0100d00:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0100d03:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0100d06:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100d0d:	eb a4                	jmp    f0100cb3 <vprintfmt+0x1d9>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100d0f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100d13:	74 18                	je     f0100d2d <vprintfmt+0x253>
f0100d15:	8d 50 e0             	lea    -0x20(%eax),%edx
f0100d18:	83 fa 5e             	cmp    $0x5e,%edx
f0100d1b:	76 10                	jbe    f0100d2d <vprintfmt+0x253>
					putch('?', putdat);
f0100d1d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d21:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100d28:	ff 55 08             	call   *0x8(%ebp)
f0100d2b:	eb 0a                	jmp    f0100d37 <vprintfmt+0x25d>
				else
					putch(ch, putdat);
f0100d2d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d31:	89 04 24             	mov    %eax,(%esp)
f0100d34:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100d37:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0100d3b:	0f be 03             	movsbl (%ebx),%eax
f0100d3e:	85 c0                	test   %eax,%eax
f0100d40:	74 05                	je     f0100d47 <vprintfmt+0x26d>
f0100d42:	83 c3 01             	add    $0x1,%ebx
f0100d45:	eb 1c                	jmp    f0100d63 <vprintfmt+0x289>
f0100d47:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100d4a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100d4e:	7f 21                	jg     f0100d71 <vprintfmt+0x297>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100d50:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100d53:	e9 a5 fd ff ff       	jmp    f0100afd <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100d58:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100d5b:	83 c2 01             	add    $0x1,%edx
f0100d5e:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0100d61:	89 d3                	mov    %edx,%ebx
f0100d63:	85 f6                	test   %esi,%esi
f0100d65:	78 a8                	js     f0100d0f <vprintfmt+0x235>
f0100d67:	83 ee 01             	sub    $0x1,%esi
f0100d6a:	79 a3                	jns    f0100d0f <vprintfmt+0x235>
f0100d6c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d6f:	eb d9                	jmp    f0100d4a <vprintfmt+0x270>
f0100d71:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d74:	89 5d e0             	mov    %ebx,-0x20(%ebp)
f0100d77:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100d7a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d7e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100d85:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100d87:	83 eb 01             	sub    $0x1,%ebx
f0100d8a:	85 db                	test   %ebx,%ebx
f0100d8c:	7f ec                	jg     f0100d7a <vprintfmt+0x2a0>
f0100d8e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100d91:	e9 67 fd ff ff       	jmp    f0100afd <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100d96:	83 f9 01             	cmp    $0x1,%ecx
f0100d99:	7e 11                	jle    f0100dac <vprintfmt+0x2d2>
		return va_arg(*ap, long long);
f0100d9b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d9e:	83 c0 08             	add    $0x8,%eax
f0100da1:	89 45 14             	mov    %eax,0x14(%ebp)
f0100da4:	8b 58 f8             	mov    -0x8(%eax),%ebx
f0100da7:	8b 70 fc             	mov    -0x4(%eax),%esi
f0100daa:	eb 28                	jmp    f0100dd4 <vprintfmt+0x2fa>
	else if (lflag)
f0100dac:	85 c9                	test   %ecx,%ecx
f0100dae:	74 13                	je     f0100dc3 <vprintfmt+0x2e9>
		return va_arg(*ap, long);
f0100db0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100db3:	83 c0 04             	add    $0x4,%eax
f0100db6:	89 45 14             	mov    %eax,0x14(%ebp)
f0100db9:	8b 58 fc             	mov    -0x4(%eax),%ebx
f0100dbc:	89 de                	mov    %ebx,%esi
f0100dbe:	c1 fe 1f             	sar    $0x1f,%esi
f0100dc1:	eb 11                	jmp    f0100dd4 <vprintfmt+0x2fa>
	else
		return va_arg(*ap, int);
f0100dc3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dc6:	83 c0 04             	add    $0x4,%eax
f0100dc9:	89 45 14             	mov    %eax,0x14(%ebp)
f0100dcc:	8b 58 fc             	mov    -0x4(%eax),%ebx
f0100dcf:	89 de                	mov    %ebx,%esi
f0100dd1:	c1 fe 1f             	sar    $0x1f,%esi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0100dd4:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0100dd9:	85 f6                	test   %esi,%esi
f0100ddb:	0f 89 ad 00 00 00    	jns    f0100e8e <vprintfmt+0x3b4>
				putch('-', putdat);
f0100de1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100de5:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0100dec:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0100def:	f7 db                	neg    %ebx
f0100df1:	83 d6 00             	adc    $0x0,%esi
f0100df4:	f7 de                	neg    %esi
			}
			base = 10;
f0100df6:	b8 0a 00 00 00       	mov    $0xa,%eax
f0100dfb:	e9 8e 00 00 00       	jmp    f0100e8e <vprintfmt+0x3b4>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0100e00:	89 ca                	mov    %ecx,%edx
f0100e02:	8d 45 14             	lea    0x14(%ebp),%eax
f0100e05:	e8 4e fc ff ff       	call   f0100a58 <getuint>
f0100e0a:	89 c3                	mov    %eax,%ebx
f0100e0c:	89 d6                	mov    %edx,%esi
			base = 10;
f0100e0e:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f0100e13:	eb 79                	jmp    f0100e8e <vprintfmt+0x3b4>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0100e15:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e19:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0100e20:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f0100e23:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e27:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0100e2e:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f0100e31:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e35:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0100e3c:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e3f:	8b 5d e0             	mov    -0x20(%ebp),%ebx
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0100e42:	e9 b6 fc ff ff       	jmp    f0100afd <vprintfmt+0x23>

		// pointer
		case 'p':
			putch('0', putdat);
f0100e47:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e4b:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0100e52:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0100e55:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e59:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0100e60:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0100e63:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e66:	83 c0 04             	add    $0x4,%eax
f0100e69:	89 45 14             	mov    %eax,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0100e6c:	8b 58 fc             	mov    -0x4(%eax),%ebx
f0100e6f:	be 00 00 00 00       	mov    $0x0,%esi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0100e74:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0100e79:	eb 13                	jmp    f0100e8e <vprintfmt+0x3b4>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0100e7b:	89 ca                	mov    %ecx,%edx
f0100e7d:	8d 45 14             	lea    0x14(%ebp),%eax
f0100e80:	e8 d3 fb ff ff       	call   f0100a58 <getuint>
f0100e85:	89 c3                	mov    %eax,%ebx
f0100e87:	89 d6                	mov    %edx,%esi
			base = 16;
f0100e89:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0100e8e:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f0100e92:	89 54 24 10          	mov    %edx,0x10(%esp)
f0100e96:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100e99:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100e9d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ea1:	89 1c 24             	mov    %ebx,(%esp)
f0100ea4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ea8:	89 fa                	mov    %edi,%edx
f0100eaa:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ead:	e8 be fa ff ff       	call   f0100970 <printnum>
			break;
f0100eb2:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100eb5:	e9 43 fc ff ff       	jmp    f0100afd <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0100eba:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ebe:	89 14 24             	mov    %edx,(%esp)
f0100ec1:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ec4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0100ec7:	e9 31 fc ff ff       	jmp    f0100afd <vprintfmt+0x23>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0100ecc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ed0:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0100ed7:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100eda:	eb 02                	jmp    f0100ede <vprintfmt+0x404>
f0100edc:	89 c3                	mov    %eax,%ebx
f0100ede:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100ee1:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0100ee5:	75 f5                	jne    f0100edc <vprintfmt+0x402>
f0100ee7:	e9 11 fc ff ff       	jmp    f0100afd <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f0100eec:	83 c4 4c             	add    $0x4c,%esp
f0100eef:	5b                   	pop    %ebx
f0100ef0:	5e                   	pop    %esi
f0100ef1:	5f                   	pop    %edi
f0100ef2:	5d                   	pop    %ebp
f0100ef3:	c3                   	ret    

f0100ef4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0100ef4:	55                   	push   %ebp
f0100ef5:	89 e5                	mov    %esp,%ebp
f0100ef7:	83 ec 28             	sub    $0x28,%esp
f0100efa:	8b 45 08             	mov    0x8(%ebp),%eax
f0100efd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0100f00:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100f03:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0100f07:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100f0a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0100f11:	85 c0                	test   %eax,%eax
f0100f13:	74 30                	je     f0100f45 <vsnprintf+0x51>
f0100f15:	85 d2                	test   %edx,%edx
f0100f17:	7e 2c                	jle    f0100f45 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0100f19:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f1c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f20:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f23:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f27:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0100f2a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f2e:	c7 04 24 95 0a 10 f0 	movl   $0xf0100a95,(%esp)
f0100f35:	e8 a0 fb ff ff       	call   f0100ada <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0100f3a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100f3d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0100f40:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f43:	eb 05                	jmp    f0100f4a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0100f45:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0100f4a:	c9                   	leave  
f0100f4b:	c3                   	ret    

f0100f4c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0100f4c:	55                   	push   %ebp
f0100f4d:	89 e5                	mov    %esp,%ebp
f0100f4f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0100f52:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0100f55:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f59:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f5c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f60:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f63:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f67:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f6a:	89 04 24             	mov    %eax,(%esp)
f0100f6d:	e8 82 ff ff ff       	call   f0100ef4 <vsnprintf>
	va_end(ap);

	return rc;
}
f0100f72:	c9                   	leave  
f0100f73:	c3                   	ret    
	...

f0100f80 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0100f80:	55                   	push   %ebp
f0100f81:	89 e5                	mov    %esp,%ebp
f0100f83:	57                   	push   %edi
f0100f84:	56                   	push   %esi
f0100f85:	53                   	push   %ebx
f0100f86:	83 ec 1c             	sub    $0x1c,%esp
f0100f89:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0100f8c:	85 c0                	test   %eax,%eax
f0100f8e:	74 10                	je     f0100fa0 <readline+0x20>
		cprintf("%s", prompt);
f0100f90:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f94:	c7 04 24 25 1b 10 f0 	movl   $0xf0101b25,(%esp)
f0100f9b:	e8 aa f9 ff ff       	call   f010094a <cprintf>

	i = 0;
	echoing = iscons(0);
f0100fa0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100fa7:	e8 ec f6 ff ff       	call   f0100698 <iscons>
f0100fac:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0100fae:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0100fb3:	e8 cf f6 ff ff       	call   f0100687 <getchar>
f0100fb8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0100fba:	85 c0                	test   %eax,%eax
f0100fbc:	79 17                	jns    f0100fd5 <readline+0x55>
			cprintf("read error: %e\n", c);
f0100fbe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100fc2:	c7 04 24 08 1d 10 f0 	movl   $0xf0101d08,(%esp)
f0100fc9:	e8 7c f9 ff ff       	call   f010094a <cprintf>
			return NULL;
f0100fce:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fd3:	eb 61                	jmp    f0101036 <readline+0xb6>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0100fd5:	83 f8 1f             	cmp    $0x1f,%eax
f0100fd8:	7e 1f                	jle    f0100ff9 <readline+0x79>
f0100fda:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0100fe0:	7f 17                	jg     f0100ff9 <readline+0x79>
			if (echoing)
f0100fe2:	85 ff                	test   %edi,%edi
f0100fe4:	74 08                	je     f0100fee <readline+0x6e>
				cputchar(c);
f0100fe6:	89 04 24             	mov    %eax,(%esp)
f0100fe9:	e8 86 f6 ff ff       	call   f0100674 <cputchar>
			buf[i++] = c;
f0100fee:	88 9e 80 f5 10 f0    	mov    %bl,-0xfef0a80(%esi)
f0100ff4:	83 c6 01             	add    $0x1,%esi
f0100ff7:	eb ba                	jmp    f0100fb3 <readline+0x33>
		} else if (c == '\b' && i > 0) {
f0100ff9:	83 fb 08             	cmp    $0x8,%ebx
f0100ffc:	75 15                	jne    f0101013 <readline+0x93>
f0100ffe:	85 f6                	test   %esi,%esi
f0101000:	7e 11                	jle    f0101013 <readline+0x93>
			if (echoing)
f0101002:	85 ff                	test   %edi,%edi
f0101004:	74 08                	je     f010100e <readline+0x8e>
				cputchar(c);
f0101006:	89 1c 24             	mov    %ebx,(%esp)
f0101009:	e8 66 f6 ff ff       	call   f0100674 <cputchar>
			i--;
f010100e:	83 ee 01             	sub    $0x1,%esi
f0101011:	eb a0                	jmp    f0100fb3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0101013:	83 fb 0a             	cmp    $0xa,%ebx
f0101016:	74 05                	je     f010101d <readline+0x9d>
f0101018:	83 fb 0d             	cmp    $0xd,%ebx
f010101b:	75 96                	jne    f0100fb3 <readline+0x33>
			if (echoing)
f010101d:	85 ff                	test   %edi,%edi
f010101f:	90                   	nop
f0101020:	74 08                	je     f010102a <readline+0xaa>
				cputchar(c);
f0101022:	89 1c 24             	mov    %ebx,(%esp)
f0101025:	e8 4a f6 ff ff       	call   f0100674 <cputchar>
			buf[i] = 0;
f010102a:	c6 86 80 f5 10 f0 00 	movb   $0x0,-0xfef0a80(%esi)
			return buf;
f0101031:	b8 80 f5 10 f0       	mov    $0xf010f580,%eax
		}
	}
}
f0101036:	83 c4 1c             	add    $0x1c,%esp
f0101039:	5b                   	pop    %ebx
f010103a:	5e                   	pop    %esi
f010103b:	5f                   	pop    %edi
f010103c:	5d                   	pop    %ebp
f010103d:	c3                   	ret    
	...

f0101040 <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
f0101040:	55                   	push   %ebp
f0101041:	89 e5                	mov    %esp,%ebp
f0101043:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101046:	b8 00 00 00 00       	mov    $0x0,%eax
f010104b:	80 3a 00             	cmpb   $0x0,(%edx)
f010104e:	74 09                	je     f0101059 <strlen+0x19>
		n++;
f0101050:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101053:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101057:	75 f7                	jne    f0101050 <strlen+0x10>
		n++;
	return n;
}
f0101059:	5d                   	pop    %ebp
f010105a:	c3                   	ret    

f010105b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010105b:	55                   	push   %ebp
f010105c:	89 e5                	mov    %esp,%ebp
f010105e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101061:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101064:	b8 00 00 00 00       	mov    $0x0,%eax
f0101069:	85 d2                	test   %edx,%edx
f010106b:	74 12                	je     f010107f <strnlen+0x24>
f010106d:	80 39 00             	cmpb   $0x0,(%ecx)
f0101070:	74 0d                	je     f010107f <strnlen+0x24>
		n++;
f0101072:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101075:	39 d0                	cmp    %edx,%eax
f0101077:	74 06                	je     f010107f <strnlen+0x24>
f0101079:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010107d:	75 f3                	jne    f0101072 <strnlen+0x17>
		n++;
	return n;
}
f010107f:	5d                   	pop    %ebp
f0101080:	c3                   	ret    

f0101081 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101081:	55                   	push   %ebp
f0101082:	89 e5                	mov    %esp,%ebp
f0101084:	53                   	push   %ebx
f0101085:	8b 45 08             	mov    0x8(%ebp),%eax
f0101088:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010108b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101090:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0101094:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101097:	83 c2 01             	add    $0x1,%edx
f010109a:	84 c9                	test   %cl,%cl
f010109c:	75 f2                	jne    f0101090 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f010109e:	5b                   	pop    %ebx
f010109f:	5d                   	pop    %ebp
f01010a0:	c3                   	ret    

f01010a1 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01010a1:	55                   	push   %ebp
f01010a2:	89 e5                	mov    %esp,%ebp
f01010a4:	56                   	push   %esi
f01010a5:	53                   	push   %ebx
f01010a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01010a9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01010ac:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01010af:	85 f6                	test   %esi,%esi
f01010b1:	74 18                	je     f01010cb <strncpy+0x2a>
f01010b3:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01010b8:	0f b6 1a             	movzbl (%edx),%ebx
f01010bb:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01010be:	80 3a 01             	cmpb   $0x1,(%edx)
f01010c1:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01010c4:	83 c1 01             	add    $0x1,%ecx
f01010c7:	39 ce                	cmp    %ecx,%esi
f01010c9:	77 ed                	ja     f01010b8 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01010cb:	5b                   	pop    %ebx
f01010cc:	5e                   	pop    %esi
f01010cd:	5d                   	pop    %ebp
f01010ce:	c3                   	ret    

f01010cf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01010cf:	55                   	push   %ebp
f01010d0:	89 e5                	mov    %esp,%ebp
f01010d2:	57                   	push   %edi
f01010d3:	56                   	push   %esi
f01010d4:	53                   	push   %ebx
f01010d5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01010d8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010db:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01010de:	89 f8                	mov    %edi,%eax
f01010e0:	85 f6                	test   %esi,%esi
f01010e2:	74 2c                	je     f0101110 <strlcpy+0x41>
		while (--size > 0 && *src != '\0')
f01010e4:	83 fe 01             	cmp    $0x1,%esi
f01010e7:	74 24                	je     f010110d <strlcpy+0x3e>
f01010e9:	0f b6 0b             	movzbl (%ebx),%ecx
f01010ec:	84 c9                	test   %cl,%cl
f01010ee:	74 1d                	je     f010110d <strlcpy+0x3e>
f01010f0:	ba 00 00 00 00       	mov    $0x0,%edx
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f01010f5:	83 ee 02             	sub    $0x2,%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01010f8:	88 08                	mov    %cl,(%eax)
f01010fa:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01010fd:	39 f2                	cmp    %esi,%edx
f01010ff:	74 0c                	je     f010110d <strlcpy+0x3e>
f0101101:	0f b6 4c 13 01       	movzbl 0x1(%ebx,%edx,1),%ecx
f0101106:	83 c2 01             	add    $0x1,%edx
f0101109:	84 c9                	test   %cl,%cl
f010110b:	75 eb                	jne    f01010f8 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f010110d:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101110:	29 f8                	sub    %edi,%eax
}
f0101112:	5b                   	pop    %ebx
f0101113:	5e                   	pop    %esi
f0101114:	5f                   	pop    %edi
f0101115:	5d                   	pop    %ebp
f0101116:	c3                   	ret    

f0101117 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101117:	55                   	push   %ebp
f0101118:	89 e5                	mov    %esp,%ebp
f010111a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010111d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101120:	0f b6 01             	movzbl (%ecx),%eax
f0101123:	84 c0                	test   %al,%al
f0101125:	74 15                	je     f010113c <strcmp+0x25>
f0101127:	3a 02                	cmp    (%edx),%al
f0101129:	75 11                	jne    f010113c <strcmp+0x25>
		p++, q++;
f010112b:	83 c1 01             	add    $0x1,%ecx
f010112e:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101131:	0f b6 01             	movzbl (%ecx),%eax
f0101134:	84 c0                	test   %al,%al
f0101136:	74 04                	je     f010113c <strcmp+0x25>
f0101138:	3a 02                	cmp    (%edx),%al
f010113a:	74 ef                	je     f010112b <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010113c:	0f b6 c0             	movzbl %al,%eax
f010113f:	0f b6 12             	movzbl (%edx),%edx
f0101142:	29 d0                	sub    %edx,%eax
}
f0101144:	5d                   	pop    %ebp
f0101145:	c3                   	ret    

f0101146 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101146:	55                   	push   %ebp
f0101147:	89 e5                	mov    %esp,%ebp
f0101149:	53                   	push   %ebx
f010114a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010114d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101150:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101153:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101158:	85 d2                	test   %edx,%edx
f010115a:	74 28                	je     f0101184 <strncmp+0x3e>
f010115c:	0f b6 01             	movzbl (%ecx),%eax
f010115f:	84 c0                	test   %al,%al
f0101161:	74 24                	je     f0101187 <strncmp+0x41>
f0101163:	3a 03                	cmp    (%ebx),%al
f0101165:	75 20                	jne    f0101187 <strncmp+0x41>
f0101167:	83 ea 01             	sub    $0x1,%edx
f010116a:	74 13                	je     f010117f <strncmp+0x39>
		n--, p++, q++;
f010116c:	83 c1 01             	add    $0x1,%ecx
f010116f:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101172:	0f b6 01             	movzbl (%ecx),%eax
f0101175:	84 c0                	test   %al,%al
f0101177:	74 0e                	je     f0101187 <strncmp+0x41>
f0101179:	3a 03                	cmp    (%ebx),%al
f010117b:	74 ea                	je     f0101167 <strncmp+0x21>
f010117d:	eb 08                	jmp    f0101187 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f010117f:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101184:	5b                   	pop    %ebx
f0101185:	5d                   	pop    %ebp
f0101186:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101187:	0f b6 01             	movzbl (%ecx),%eax
f010118a:	0f b6 13             	movzbl (%ebx),%edx
f010118d:	29 d0                	sub    %edx,%eax
f010118f:	eb f3                	jmp    f0101184 <strncmp+0x3e>

f0101191 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101191:	55                   	push   %ebp
f0101192:	89 e5                	mov    %esp,%ebp
f0101194:	8b 45 08             	mov    0x8(%ebp),%eax
f0101197:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010119b:	0f b6 10             	movzbl (%eax),%edx
f010119e:	84 d2                	test   %dl,%dl
f01011a0:	74 21                	je     f01011c3 <strchr+0x32>
		if (*s == c)
f01011a2:	38 ca                	cmp    %cl,%dl
f01011a4:	75 0c                	jne    f01011b2 <strchr+0x21>
f01011a6:	eb 20                	jmp    f01011c8 <strchr+0x37>
f01011a8:	38 ca                	cmp    %cl,%dl
f01011aa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01011b0:	74 16                	je     f01011c8 <strchr+0x37>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01011b2:	83 c0 01             	add    $0x1,%eax
f01011b5:	0f b6 10             	movzbl (%eax),%edx
f01011b8:	84 d2                	test   %dl,%dl
f01011ba:	75 ec                	jne    f01011a8 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f01011bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01011c1:	eb 05                	jmp    f01011c8 <strchr+0x37>
f01011c3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01011c8:	5d                   	pop    %ebp
f01011c9:	c3                   	ret    

f01011ca <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01011ca:	55                   	push   %ebp
f01011cb:	89 e5                	mov    %esp,%ebp
f01011cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01011d0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01011d4:	0f b6 10             	movzbl (%eax),%edx
f01011d7:	84 d2                	test   %dl,%dl
f01011d9:	74 14                	je     f01011ef <strfind+0x25>
		if (*s == c)
f01011db:	38 ca                	cmp    %cl,%dl
f01011dd:	75 06                	jne    f01011e5 <strfind+0x1b>
f01011df:	eb 0e                	jmp    f01011ef <strfind+0x25>
f01011e1:	38 ca                	cmp    %cl,%dl
f01011e3:	74 0a                	je     f01011ef <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01011e5:	83 c0 01             	add    $0x1,%eax
f01011e8:	0f b6 10             	movzbl (%eax),%edx
f01011eb:	84 d2                	test   %dl,%dl
f01011ed:	75 f2                	jne    f01011e1 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f01011ef:	5d                   	pop    %ebp
f01011f0:	c3                   	ret    

f01011f1 <memset>:


void *
memset(void *v, int c, size_t n)
{
f01011f1:	55                   	push   %ebp
f01011f2:	89 e5                	mov    %esp,%ebp
f01011f4:	53                   	push   %ebx
f01011f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01011f8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01011fb:	8b 5d 10             	mov    0x10(%ebp),%ebx
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f01011fe:	89 da                	mov    %ebx,%edx
f0101200:	83 ea 01             	sub    $0x1,%edx
f0101203:	78 0e                	js     f0101213 <memset+0x22>
memset(void *v, int c, size_t n)
{
	char *p;
	int m;

	p = v;
f0101205:	89 c2                	mov    %eax,%edx
	return (char *) s;
}


void *
memset(void *v, int c, size_t n)
f0101207:	8d 1c 18             	lea    (%eax,%ebx,1),%ebx
	int m;

	p = v;
	m = n;
	while (--m >= 0)
		*p++ = c;
f010120a:	88 0a                	mov    %cl,(%edx)
f010120c:	83 c2 01             	add    $0x1,%edx
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f010120f:	39 da                	cmp    %ebx,%edx
f0101211:	75 f7                	jne    f010120a <memset+0x19>
		*p++ = c;

	return v;
}
f0101213:	5b                   	pop    %ebx
f0101214:	5d                   	pop    %ebp
f0101215:	c3                   	ret    

f0101216 <memcpy>:

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101216:	55                   	push   %ebp
f0101217:	89 e5                	mov    %esp,%ebp
f0101219:	56                   	push   %esi
f010121a:	53                   	push   %ebx
f010121b:	8b 45 08             	mov    0x8(%ebp),%eax
f010121e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101221:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const char *s;
	char *d;

	s = src;
	d = dst;
	while (n-- > 0)
f0101224:	85 db                	test   %ebx,%ebx
f0101226:	74 13                	je     f010123b <memcpy+0x25>
f0101228:	ba 00 00 00 00       	mov    $0x0,%edx
		*d++ = *s++;
f010122d:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101231:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101234:	83 c2 01             	add    $0x1,%edx
	const char *s;
	char *d;

	s = src;
	d = dst;
	while (n-- > 0)
f0101237:	39 da                	cmp    %ebx,%edx
f0101239:	75 f2                	jne    f010122d <memcpy+0x17>
		*d++ = *s++;

	return dst;
}
f010123b:	5b                   	pop    %ebx
f010123c:	5e                   	pop    %esi
f010123d:	5d                   	pop    %ebp
f010123e:	c3                   	ret    

f010123f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010123f:	55                   	push   %ebp
f0101240:	89 e5                	mov    %esp,%ebp
f0101242:	57                   	push   %edi
f0101243:	56                   	push   %esi
f0101244:	53                   	push   %ebx
f0101245:	8b 45 08             	mov    0x8(%ebp),%eax
f0101248:	8b 75 0c             	mov    0xc(%ebp),%esi
f010124b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010124e:	39 c6                	cmp    %eax,%esi
f0101250:	72 0b                	jb     f010125d <memmove+0x1e>
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0101252:	ba 00 00 00 00       	mov    $0x0,%edx
f0101257:	85 db                	test   %ebx,%ebx
f0101259:	75 2a                	jne    f0101285 <memmove+0x46>
f010125b:	eb 36                	jmp    f0101293 <memmove+0x54>
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010125d:	8d 3c 1e             	lea    (%esi,%ebx,1),%edi
f0101260:	39 f8                	cmp    %edi,%eax
f0101262:	73 ee                	jae    f0101252 <memmove+0x13>
		s += n;
		d += n;
		while (n-- > 0)
f0101264:	85 db                	test   %ebx,%ebx
f0101266:	74 2b                	je     f0101293 <memmove+0x54>
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
f0101268:	8d 34 18             	lea    (%eax,%ebx,1),%esi
f010126b:	ba 00 00 00 00       	mov    $0x0,%edx
		while (n-- > 0)
			*--d = *--s;
f0101270:	0f b6 4c 17 ff       	movzbl -0x1(%edi,%edx,1),%ecx
f0101275:	88 4c 16 ff          	mov    %cl,-0x1(%esi,%edx,1)
f0101279:	83 ea 01             	sub    $0x1,%edx
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
f010127c:	8d 0c 1a             	lea    (%edx,%ebx,1),%ecx
f010127f:	85 c9                	test   %ecx,%ecx
f0101281:	75 ed                	jne    f0101270 <memmove+0x31>
f0101283:	eb 0e                	jmp    f0101293 <memmove+0x54>
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
f0101285:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101289:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f010128c:	83 c2 01             	add    $0x1,%edx
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f010128f:	39 d3                	cmp    %edx,%ebx
f0101291:	75 f2                	jne    f0101285 <memmove+0x46>
			*d++ = *s++;

	return dst;
}
f0101293:	5b                   	pop    %ebx
f0101294:	5e                   	pop    %esi
f0101295:	5f                   	pop    %edi
f0101296:	5d                   	pop    %ebp
f0101297:	c3                   	ret    

f0101298 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101298:	55                   	push   %ebp
f0101299:	89 e5                	mov    %esp,%ebp
f010129b:	57                   	push   %edi
f010129c:	56                   	push   %esi
f010129d:	53                   	push   %ebx
f010129e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01012a1:	8b 75 0c             	mov    0xc(%ebp),%esi
f01012a4:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01012a7:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01012ac:	85 ff                	test   %edi,%edi
f01012ae:	74 38                	je     f01012e8 <memcmp+0x50>
		if (*s1 != *s2)
f01012b0:	0f b6 03             	movzbl (%ebx),%eax
f01012b3:	0f b6 0e             	movzbl (%esi),%ecx
f01012b6:	38 c8                	cmp    %cl,%al
f01012b8:	74 1d                	je     f01012d7 <memcmp+0x3f>
f01012ba:	eb 11                	jmp    f01012cd <memcmp+0x35>
f01012bc:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01012c1:	0f b6 4c 16 01       	movzbl 0x1(%esi,%edx,1),%ecx
f01012c6:	83 c2 01             	add    $0x1,%edx
f01012c9:	38 c8                	cmp    %cl,%al
f01012cb:	74 12                	je     f01012df <memcmp+0x47>
			return (int) *s1 - (int) *s2;
f01012cd:	0f b6 c0             	movzbl %al,%eax
f01012d0:	0f b6 c9             	movzbl %cl,%ecx
f01012d3:	29 c8                	sub    %ecx,%eax
f01012d5:	eb 11                	jmp    f01012e8 <memcmp+0x50>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01012d7:	83 ef 01             	sub    $0x1,%edi
f01012da:	ba 00 00 00 00       	mov    $0x0,%edx
f01012df:	39 fa                	cmp    %edi,%edx
f01012e1:	75 d9                	jne    f01012bc <memcmp+0x24>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01012e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01012e8:	5b                   	pop    %ebx
f01012e9:	5e                   	pop    %esi
f01012ea:	5f                   	pop    %edi
f01012eb:	5d                   	pop    %ebp
f01012ec:	c3                   	ret    

f01012ed <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01012ed:	55                   	push   %ebp
f01012ee:	89 e5                	mov    %esp,%ebp
f01012f0:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01012f3:	89 c2                	mov    %eax,%edx
f01012f5:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01012f8:	39 d0                	cmp    %edx,%eax
f01012fa:	73 16                	jae    f0101312 <memfind+0x25>
		if (*(const unsigned char *) s == (unsigned char) c)
f01012fc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101300:	38 08                	cmp    %cl,(%eax)
f0101302:	75 06                	jne    f010130a <memfind+0x1d>
f0101304:	eb 0c                	jmp    f0101312 <memfind+0x25>
f0101306:	38 08                	cmp    %cl,(%eax)
f0101308:	74 08                	je     f0101312 <memfind+0x25>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010130a:	83 c0 01             	add    $0x1,%eax
f010130d:	39 c2                	cmp    %eax,%edx
f010130f:	90                   	nop
f0101310:	77 f4                	ja     f0101306 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101312:	5d                   	pop    %ebp
f0101313:	c3                   	ret    

f0101314 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101314:	55                   	push   %ebp
f0101315:	89 e5                	mov    %esp,%ebp
f0101317:	57                   	push   %edi
f0101318:	56                   	push   %esi
f0101319:	53                   	push   %ebx
f010131a:	8b 55 08             	mov    0x8(%ebp),%edx
f010131d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101320:	0f b6 02             	movzbl (%edx),%eax
f0101323:	3c 20                	cmp    $0x20,%al
f0101325:	74 04                	je     f010132b <strtol+0x17>
f0101327:	3c 09                	cmp    $0x9,%al
f0101329:	75 0e                	jne    f0101339 <strtol+0x25>
		s++;
f010132b:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010132e:	0f b6 02             	movzbl (%edx),%eax
f0101331:	3c 20                	cmp    $0x20,%al
f0101333:	74 f6                	je     f010132b <strtol+0x17>
f0101335:	3c 09                	cmp    $0x9,%al
f0101337:	74 f2                	je     f010132b <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101339:	3c 2b                	cmp    $0x2b,%al
f010133b:	75 0a                	jne    f0101347 <strtol+0x33>
		s++;
f010133d:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101340:	bf 00 00 00 00       	mov    $0x0,%edi
f0101345:	eb 10                	jmp    f0101357 <strtol+0x43>
f0101347:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010134c:	3c 2d                	cmp    $0x2d,%al
f010134e:	75 07                	jne    f0101357 <strtol+0x43>
		s++, neg = 1;
f0101350:	83 c2 01             	add    $0x1,%edx
f0101353:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101357:	85 db                	test   %ebx,%ebx
f0101359:	0f 94 c0             	sete   %al
f010135c:	74 05                	je     f0101363 <strtol+0x4f>
f010135e:	83 fb 10             	cmp    $0x10,%ebx
f0101361:	75 15                	jne    f0101378 <strtol+0x64>
f0101363:	80 3a 30             	cmpb   $0x30,(%edx)
f0101366:	75 10                	jne    f0101378 <strtol+0x64>
f0101368:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010136c:	75 0a                	jne    f0101378 <strtol+0x64>
		s += 2, base = 16;
f010136e:	83 c2 02             	add    $0x2,%edx
f0101371:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101376:	eb 13                	jmp    f010138b <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101378:	84 c0                	test   %al,%al
f010137a:	74 0f                	je     f010138b <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010137c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101381:	80 3a 30             	cmpb   $0x30,(%edx)
f0101384:	75 05                	jne    f010138b <strtol+0x77>
		s++, base = 8;
f0101386:	83 c2 01             	add    $0x1,%edx
f0101389:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010138b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101390:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101392:	0f b6 0a             	movzbl (%edx),%ecx
f0101395:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101398:	80 fb 09             	cmp    $0x9,%bl
f010139b:	77 08                	ja     f01013a5 <strtol+0x91>
			dig = *s - '0';
f010139d:	0f be c9             	movsbl %cl,%ecx
f01013a0:	83 e9 30             	sub    $0x30,%ecx
f01013a3:	eb 1e                	jmp    f01013c3 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f01013a5:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01013a8:	80 fb 19             	cmp    $0x19,%bl
f01013ab:	77 08                	ja     f01013b5 <strtol+0xa1>
			dig = *s - 'a' + 10;
f01013ad:	0f be c9             	movsbl %cl,%ecx
f01013b0:	83 e9 57             	sub    $0x57,%ecx
f01013b3:	eb 0e                	jmp    f01013c3 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f01013b5:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f01013b8:	80 fb 19             	cmp    $0x19,%bl
f01013bb:	77 15                	ja     f01013d2 <strtol+0xbe>
			dig = *s - 'A' + 10;
f01013bd:	0f be c9             	movsbl %cl,%ecx
f01013c0:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01013c3:	39 f1                	cmp    %esi,%ecx
f01013c5:	7d 0f                	jge    f01013d6 <strtol+0xc2>
			break;
		s++, val = (val * base) + dig;
f01013c7:	83 c2 01             	add    $0x1,%edx
f01013ca:	0f af c6             	imul   %esi,%eax
f01013cd:	8d 04 01             	lea    (%ecx,%eax,1),%eax
		// we don't properly detect overflow!
	}
f01013d0:	eb c0                	jmp    f0101392 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01013d2:	89 c1                	mov    %eax,%ecx
f01013d4:	eb 02                	jmp    f01013d8 <strtol+0xc4>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01013d6:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01013d8:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01013dc:	74 05                	je     f01013e3 <strtol+0xcf>
		*endptr = (char *) s;
f01013de:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01013e1:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f01013e3:	89 ca                	mov    %ecx,%edx
f01013e5:	f7 da                	neg    %edx
f01013e7:	85 ff                	test   %edi,%edi
f01013e9:	0f 45 c2             	cmovne %edx,%eax
}
f01013ec:	5b                   	pop    %ebx
f01013ed:	5e                   	pop    %esi
f01013ee:	5f                   	pop    %edi
f01013ef:	5d                   	pop    %ebp
f01013f0:	c3                   	ret    
	...

f0101400 <__udivdi3>:
f0101400:	55                   	push   %ebp
f0101401:	89 e5                	mov    %esp,%ebp
f0101403:	57                   	push   %edi
f0101404:	56                   	push   %esi
f0101405:	8d 64 24 e0          	lea    -0x20(%esp),%esp
f0101409:	8b 45 14             	mov    0x14(%ebp),%eax
f010140c:	8b 75 08             	mov    0x8(%ebp),%esi
f010140f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101412:	85 c0                	test   %eax,%eax
f0101414:	89 75 e8             	mov    %esi,-0x18(%ebp)
f0101417:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010141a:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010141d:	75 39                	jne    f0101458 <__udivdi3+0x58>
f010141f:	39 f9                	cmp    %edi,%ecx
f0101421:	77 65                	ja     f0101488 <__udivdi3+0x88>
f0101423:	85 c9                	test   %ecx,%ecx
f0101425:	75 0b                	jne    f0101432 <__udivdi3+0x32>
f0101427:	b8 01 00 00 00       	mov    $0x1,%eax
f010142c:	31 d2                	xor    %edx,%edx
f010142e:	f7 f1                	div    %ecx
f0101430:	89 c1                	mov    %eax,%ecx
f0101432:	89 f8                	mov    %edi,%eax
f0101434:	31 d2                	xor    %edx,%edx
f0101436:	f7 f1                	div    %ecx
f0101438:	89 c7                	mov    %eax,%edi
f010143a:	89 f0                	mov    %esi,%eax
f010143c:	f7 f1                	div    %ecx
f010143e:	89 fa                	mov    %edi,%edx
f0101440:	89 c6                	mov    %eax,%esi
f0101442:	89 75 f0             	mov    %esi,-0x10(%ebp)
f0101445:	89 55 f4             	mov    %edx,-0xc(%ebp)
f0101448:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010144b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010144e:	8d 64 24 20          	lea    0x20(%esp),%esp
f0101452:	5e                   	pop    %esi
f0101453:	5f                   	pop    %edi
f0101454:	5d                   	pop    %ebp
f0101455:	c3                   	ret    
f0101456:	66 90                	xchg   %ax,%ax
f0101458:	31 d2                	xor    %edx,%edx
f010145a:	31 f6                	xor    %esi,%esi
f010145c:	39 f8                	cmp    %edi,%eax
f010145e:	77 e2                	ja     f0101442 <__udivdi3+0x42>
f0101460:	0f bd d0             	bsr    %eax,%edx
f0101463:	83 f2 1f             	xor    $0x1f,%edx
f0101466:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0101469:	75 2d                	jne    f0101498 <__udivdi3+0x98>
f010146b:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f010146e:	39 4d f0             	cmp    %ecx,-0x10(%ebp)
f0101471:	76 06                	jbe    f0101479 <__udivdi3+0x79>
f0101473:	39 f8                	cmp    %edi,%eax
f0101475:	89 f2                	mov    %esi,%edx
f0101477:	73 c9                	jae    f0101442 <__udivdi3+0x42>
f0101479:	31 d2                	xor    %edx,%edx
f010147b:	be 01 00 00 00       	mov    $0x1,%esi
f0101480:	eb c0                	jmp    f0101442 <__udivdi3+0x42>
f0101482:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101488:	89 f0                	mov    %esi,%eax
f010148a:	89 fa                	mov    %edi,%edx
f010148c:	f7 f1                	div    %ecx
f010148e:	31 d2                	xor    %edx,%edx
f0101490:	89 c6                	mov    %eax,%esi
f0101492:	eb ae                	jmp    f0101442 <__udivdi3+0x42>
f0101494:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101498:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f010149c:	89 c2                	mov    %eax,%edx
f010149e:	b8 20 00 00 00       	mov    $0x20,%eax
f01014a3:	2b 45 ec             	sub    -0x14(%ebp),%eax
f01014a6:	d3 e2                	shl    %cl,%edx
f01014a8:	89 c1                	mov    %eax,%ecx
f01014aa:	8b 75 f0             	mov    -0x10(%ebp),%esi
f01014ad:	d3 ee                	shr    %cl,%esi
f01014af:	09 d6                	or     %edx,%esi
f01014b1:	89 fa                	mov    %edi,%edx
f01014b3:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f01014b7:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01014ba:	8b 75 f0             	mov    -0x10(%ebp),%esi
f01014bd:	d3 e6                	shl    %cl,%esi
f01014bf:	89 c1                	mov    %eax,%ecx
f01014c1:	89 75 f0             	mov    %esi,-0x10(%ebp)
f01014c4:	8b 75 e8             	mov    -0x18(%ebp),%esi
f01014c7:	d3 ea                	shr    %cl,%edx
f01014c9:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f01014cd:	d3 e7                	shl    %cl,%edi
f01014cf:	89 c1                	mov    %eax,%ecx
f01014d1:	d3 ee                	shr    %cl,%esi
f01014d3:	09 fe                	or     %edi,%esi
f01014d5:	89 f0                	mov    %esi,%eax
f01014d7:	f7 75 e4             	divl   -0x1c(%ebp)
f01014da:	89 d7                	mov    %edx,%edi
f01014dc:	89 c6                	mov    %eax,%esi
f01014de:	f7 65 f0             	mull   -0x10(%ebp)
f01014e1:	39 d7                	cmp    %edx,%edi
f01014e3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01014e6:	72 12                	jb     f01014fa <__udivdi3+0xfa>
f01014e8:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f01014ec:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01014ef:	d3 e2                	shl    %cl,%edx
f01014f1:	39 c2                	cmp    %eax,%edx
f01014f3:	73 08                	jae    f01014fd <__udivdi3+0xfd>
f01014f5:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f01014f8:	75 03                	jne    f01014fd <__udivdi3+0xfd>
f01014fa:	8d 76 ff             	lea    -0x1(%esi),%esi
f01014fd:	31 d2                	xor    %edx,%edx
f01014ff:	e9 3e ff ff ff       	jmp    f0101442 <__udivdi3+0x42>
	...

f0101510 <__umoddi3>:
f0101510:	55                   	push   %ebp
f0101511:	89 e5                	mov    %esp,%ebp
f0101513:	57                   	push   %edi
f0101514:	56                   	push   %esi
f0101515:	8d 64 24 e0          	lea    -0x20(%esp),%esp
f0101519:	8b 7d 14             	mov    0x14(%ebp),%edi
f010151c:	8b 45 08             	mov    0x8(%ebp),%eax
f010151f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0101522:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101525:	85 ff                	test   %edi,%edi
f0101527:	89 45 e8             	mov    %eax,-0x18(%ebp)
f010152a:	89 4d f4             	mov    %ecx,-0xc(%ebp)
f010152d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101530:	89 f2                	mov    %esi,%edx
f0101532:	75 14                	jne    f0101548 <__umoddi3+0x38>
f0101534:	39 f1                	cmp    %esi,%ecx
f0101536:	76 40                	jbe    f0101578 <__umoddi3+0x68>
f0101538:	f7 f1                	div    %ecx
f010153a:	89 d0                	mov    %edx,%eax
f010153c:	31 d2                	xor    %edx,%edx
f010153e:	8d 64 24 20          	lea    0x20(%esp),%esp
f0101542:	5e                   	pop    %esi
f0101543:	5f                   	pop    %edi
f0101544:	5d                   	pop    %ebp
f0101545:	c3                   	ret    
f0101546:	66 90                	xchg   %ax,%ax
f0101548:	39 f7                	cmp    %esi,%edi
f010154a:	77 4c                	ja     f0101598 <__umoddi3+0x88>
f010154c:	0f bd c7             	bsr    %edi,%eax
f010154f:	83 f0 1f             	xor    $0x1f,%eax
f0101552:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101555:	75 51                	jne    f01015a8 <__umoddi3+0x98>
f0101557:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f010155a:	0f 87 e8 00 00 00    	ja     f0101648 <__umoddi3+0x138>
f0101560:	89 f2                	mov    %esi,%edx
f0101562:	8b 75 f0             	mov    -0x10(%ebp),%esi
f0101565:	29 ce                	sub    %ecx,%esi
f0101567:	19 fa                	sbb    %edi,%edx
f0101569:	89 75 f0             	mov    %esi,-0x10(%ebp)
f010156c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010156f:	8d 64 24 20          	lea    0x20(%esp),%esp
f0101573:	5e                   	pop    %esi
f0101574:	5f                   	pop    %edi
f0101575:	5d                   	pop    %ebp
f0101576:	c3                   	ret    
f0101577:	90                   	nop
f0101578:	85 c9                	test   %ecx,%ecx
f010157a:	75 0b                	jne    f0101587 <__umoddi3+0x77>
f010157c:	b8 01 00 00 00       	mov    $0x1,%eax
f0101581:	31 d2                	xor    %edx,%edx
f0101583:	f7 f1                	div    %ecx
f0101585:	89 c1                	mov    %eax,%ecx
f0101587:	89 f0                	mov    %esi,%eax
f0101589:	31 d2                	xor    %edx,%edx
f010158b:	f7 f1                	div    %ecx
f010158d:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101590:	f7 f1                	div    %ecx
f0101592:	eb a6                	jmp    f010153a <__umoddi3+0x2a>
f0101594:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101598:	89 f2                	mov    %esi,%edx
f010159a:	8d 64 24 20          	lea    0x20(%esp),%esp
f010159e:	5e                   	pop    %esi
f010159f:	5f                   	pop    %edi
f01015a0:	5d                   	pop    %ebp
f01015a1:	c3                   	ret    
f01015a2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01015a8:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f01015ac:	c7 45 f0 20 00 00 00 	movl   $0x20,-0x10(%ebp)
f01015b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01015b6:	29 45 f0             	sub    %eax,-0x10(%ebp)
f01015b9:	d3 e7                	shl    %cl,%edi
f01015bb:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01015be:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f01015c2:	89 f2                	mov    %esi,%edx
f01015c4:	d3 e8                	shr    %cl,%eax
f01015c6:	09 f8                	or     %edi,%eax
f01015c8:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f01015cc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01015cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01015d2:	d3 e0                	shl    %cl,%eax
f01015d4:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f01015d8:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01015db:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01015de:	d3 ea                	shr    %cl,%edx
f01015e0:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f01015e4:	d3 e6                	shl    %cl,%esi
f01015e6:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f01015ea:	d3 e8                	shr    %cl,%eax
f01015ec:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f01015f0:	09 f0                	or     %esi,%eax
f01015f2:	8b 75 e8             	mov    -0x18(%ebp),%esi
f01015f5:	d3 e6                	shl    %cl,%esi
f01015f7:	f7 75 e4             	divl   -0x1c(%ebp)
f01015fa:	89 75 e8             	mov    %esi,-0x18(%ebp)
f01015fd:	89 d6                	mov    %edx,%esi
f01015ff:	f7 65 f4             	mull   -0xc(%ebp)
f0101602:	89 d7                	mov    %edx,%edi
f0101604:	89 c2                	mov    %eax,%edx
f0101606:	39 fe                	cmp    %edi,%esi
f0101608:	89 f9                	mov    %edi,%ecx
f010160a:	72 30                	jb     f010163c <__umoddi3+0x12c>
f010160c:	39 45 e8             	cmp    %eax,-0x18(%ebp)
f010160f:	72 27                	jb     f0101638 <__umoddi3+0x128>
f0101611:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0101614:	29 d0                	sub    %edx,%eax
f0101616:	19 ce                	sbb    %ecx,%esi
f0101618:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f010161c:	89 f2                	mov    %esi,%edx
f010161e:	d3 e8                	shr    %cl,%eax
f0101620:	0f b6 4d f0          	movzbl -0x10(%ebp),%ecx
f0101624:	d3 e2                	shl    %cl,%edx
f0101626:	0f b6 4d ec          	movzbl -0x14(%ebp),%ecx
f010162a:	09 d0                	or     %edx,%eax
f010162c:	89 f2                	mov    %esi,%edx
f010162e:	d3 ea                	shr    %cl,%edx
f0101630:	8d 64 24 20          	lea    0x20(%esp),%esp
f0101634:	5e                   	pop    %esi
f0101635:	5f                   	pop    %edi
f0101636:	5d                   	pop    %ebp
f0101637:	c3                   	ret    
f0101638:	39 fe                	cmp    %edi,%esi
f010163a:	75 d5                	jne    f0101611 <__umoddi3+0x101>
f010163c:	89 f9                	mov    %edi,%ecx
f010163e:	89 c2                	mov    %eax,%edx
f0101640:	2b 55 f4             	sub    -0xc(%ebp),%edx
f0101643:	1b 4d e4             	sbb    -0x1c(%ebp),%ecx
f0101646:	eb c9                	jmp    f0101611 <__umoddi3+0x101>
f0101648:	39 f7                	cmp    %esi,%edi
f010164a:	0f 82 10 ff ff ff    	jb     f0101560 <__umoddi3+0x50>
f0101650:	e9 17 ff ff ff       	jmp    f010156c <__umoddi3+0x5c>
