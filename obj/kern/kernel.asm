
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 f0 11 00       	mov    $0x11f000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 f0 11 f0       	mov    $0xf011f000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 6a 00 00 00       	call   f01000a8 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	83 ec 10             	sub    $0x10,%esp
f0100048:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010004b:	83 3d 80 ce 22 f0 00 	cmpl   $0x0,0xf022ce80
f0100052:	75 46                	jne    f010009a <_panic+0x5a>
		goto dead;
	panicstr = fmt;
f0100054:	89 35 80 ce 22 f0    	mov    %esi,0xf022ce80

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010005a:	fa                   	cli    
f010005b:	fc                   	cld    

	va_start(ap, fmt);
f010005c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005f:	e8 75 61 00 00       	call   f01061d9 <cpunum>
f0100064:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100067:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010006b:	8b 55 08             	mov    0x8(%ebp),%edx
f010006e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100072:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100076:	c7 04 24 c0 68 10 f0 	movl   $0xf01068c0,(%esp)
f010007d:	e8 ec 3f 00 00       	call   f010406e <cprintf>
	vcprintf(fmt, ap);
f0100082:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100086:	89 34 24             	mov    %esi,(%esp)
f0100089:	e8 ad 3f 00 00       	call   f010403b <vcprintf>
	cprintf("\n");
f010008e:	c7 04 24 a3 71 10 f0 	movl   $0xf01071a3,(%esp)
f0100095:	e8 d4 3f 00 00       	call   f010406e <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010009a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000a1:	e8 f8 08 00 00       	call   f010099e <monitor>
f01000a6:	eb f2                	jmp    f010009a <_panic+0x5a>

f01000a8 <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f01000a8:	55                   	push   %ebp
f01000a9:	89 e5                	mov    %esp,%ebp
f01000ab:	53                   	push   %ebx
f01000ac:	83 ec 14             	sub    $0x14,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000af:	b8 08 e0 26 f0       	mov    $0xf026e008,%eax
f01000b4:	2d 07 bd 22 f0       	sub    $0xf022bd07,%eax
f01000b9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000c4:	00 
f01000c5:	c7 04 24 07 bd 22 f0 	movl   $0xf022bd07,(%esp)
f01000cc:	e8 b6 5a 00 00       	call   f0105b87 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000d1:	e8 b4 05 00 00       	call   f010068a <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d6:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000dd:	00 
f01000de:	c7 04 24 2c 69 10 f0 	movl   $0xf010692c,(%esp)
f01000e5:	e8 84 3f 00 00       	call   f010406e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000ea:	e8 b2 14 00 00       	call   f01015a1 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000ef:	e8 eb 36 00 00       	call   f01037df <env_init>
	trap_init();
f01000f4:	e8 65 40 00 00       	call   f010415e <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000f9:	e8 cc 5d 00 00       	call   f0105eca <mp_init>
	lapic_init();
f01000fe:	66 90                	xchg   %ax,%ax
f0100100:	e8 ef 60 00 00       	call   f01061f4 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f0100105:	e8 94 3e 00 00       	call   f0103f9e <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f010010a:	c7 04 24 80 14 12 f0 	movl   $0xf0121480,(%esp)
f0100111:	e8 41 63 00 00       	call   f0106457 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100116:	83 3d 88 ce 22 f0 07 	cmpl   $0x7,0xf022ce88
f010011d:	77 24                	ja     f0100143 <i386_init+0x9b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010011f:	c7 44 24 0c 00 70 00 	movl   $0x7000,0xc(%esp)
f0100126:	00 
f0100127:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f010012e:	f0 
f010012f:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0100136:	00 
f0100137:	c7 04 24 47 69 10 f0 	movl   $0xf0106947,(%esp)
f010013e:	e8 fd fe ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100143:	b8 02 5e 10 f0       	mov    $0xf0105e02,%eax
f0100148:	2d 88 5d 10 f0       	sub    $0xf0105d88,%eax
f010014d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100151:	c7 44 24 04 88 5d 10 	movl   $0xf0105d88,0x4(%esp)
f0100158:	f0 
f0100159:	c7 04 24 00 70 00 f0 	movl   $0xf0007000,(%esp)
f0100160:	e8 6f 5a 00 00       	call   f0105bd4 <memmove>

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100165:	bb 20 d0 22 f0       	mov    $0xf022d020,%ebx
f010016a:	eb 4d                	jmp    f01001b9 <i386_init+0x111>
		if (c == cpus + cpunum())  // We've started already.
f010016c:	e8 68 60 00 00       	call   f01061d9 <cpunum>
f0100171:	6b c0 74             	imul   $0x74,%eax,%eax
f0100174:	05 20 d0 22 f0       	add    $0xf022d020,%eax
f0100179:	39 c3                	cmp    %eax,%ebx
f010017b:	74 39                	je     f01001b6 <i386_init+0x10e>
f010017d:	89 d8                	mov    %ebx,%eax
f010017f:	2d 20 d0 22 f0       	sub    $0xf022d020,%eax
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100184:	c1 f8 02             	sar    $0x2,%eax
f0100187:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f010018d:	c1 e0 0f             	shl    $0xf,%eax
f0100190:	8d 80 00 60 23 f0    	lea    -0xfdca000(%eax),%eax
f0100196:	a3 84 ce 22 f0       	mov    %eax,0xf022ce84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f010019b:	c7 44 24 04 00 70 00 	movl   $0x7000,0x4(%esp)
f01001a2:	00 
f01001a3:	0f b6 03             	movzbl (%ebx),%eax
f01001a6:	89 04 24             	mov    %eax,(%esp)
f01001a9:	e8 96 61 00 00       	call   f0106344 <lapic_startap>
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f01001ae:	8b 43 04             	mov    0x4(%ebx),%eax
f01001b1:	83 f8 01             	cmp    $0x1,%eax
f01001b4:	75 f8                	jne    f01001ae <i386_init+0x106>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f01001b6:	83 c3 74             	add    $0x74,%ebx
f01001b9:	6b 05 c4 d3 22 f0 74 	imul   $0x74,0xf022d3c4,%eax
f01001c0:	05 20 d0 22 f0       	add    $0xf022d020,%eax
f01001c5:	39 c3                	cmp    %eax,%ebx
f01001c7:	72 a3                	jb     f010016c <i386_init+0xc4>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01001d0:	00 
f01001d1:	c7 04 24 fa 32 22 f0 	movl   $0xf02232fa,(%esp)
f01001d8:	e8 44 38 00 00       	call   f0103a21 <env_create>
	ENV_CREATE(user_yield, ENV_TYPE_USER);
	//ENV_CREATE(user_primes, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001dd:	e8 f0 47 00 00       	call   f01049d2 <sched_yield>

f01001e2 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001e2:	55                   	push   %ebp
f01001e3:	89 e5                	mov    %esp,%ebp
f01001e5:	83 ec 18             	sub    $0x18,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001e8:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001ed:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001f2:	77 20                	ja     f0100214 <mp_main+0x32>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001f4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01001f8:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f01001ff:	f0 
f0100200:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
f0100207:	00 
f0100208:	c7 04 24 47 69 10 f0 	movl   $0xf0106947,(%esp)
f010020f:	e8 2c fe ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100214:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0100219:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f010021c:	e8 b8 5f 00 00       	call   f01061d9 <cpunum>
f0100221:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100225:	c7 04 24 53 69 10 f0 	movl   $0xf0106953,(%esp)
f010022c:	e8 3d 3e 00 00       	call   f010406e <cprintf>

	lapic_init();
f0100231:	e8 be 5f 00 00       	call   f01061f4 <lapic_init>
	env_init_percpu();
f0100236:	e8 7a 35 00 00       	call   f01037b5 <env_init_percpu>
	trap_init_percpu();
f010023b:	90                   	nop
f010023c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100240:	e8 4b 3e 00 00       	call   f0104090 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100245:	e8 8f 5f 00 00       	call   f01061d9 <cpunum>
f010024a:	6b d0 74             	imul   $0x74,%eax,%edx
f010024d:	81 c2 20 d0 22 f0    	add    $0xf022d020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0100253:	b8 01 00 00 00       	mov    $0x1,%eax
f0100258:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010025c:	c7 04 24 80 14 12 f0 	movl   $0xf0121480,(%esp)
f0100263:	e8 ef 61 00 00       	call   f0106457 <spin_lock>
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	
	lock_kernel();
	sched_yield();
f0100268:	e8 65 47 00 00       	call   f01049d2 <sched_yield>

f010026d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010026d:	55                   	push   %ebp
f010026e:	89 e5                	mov    %esp,%ebp
f0100270:	53                   	push   %ebx
f0100271:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100274:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100277:	8b 45 0c             	mov    0xc(%ebp),%eax
f010027a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010027e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100281:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100285:	c7 04 24 69 69 10 f0 	movl   $0xf0106969,(%esp)
f010028c:	e8 dd 3d 00 00       	call   f010406e <cprintf>
	vcprintf(fmt, ap);
f0100291:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100295:	8b 45 10             	mov    0x10(%ebp),%eax
f0100298:	89 04 24             	mov    %eax,(%esp)
f010029b:	e8 9b 3d 00 00       	call   f010403b <vcprintf>
	cprintf("\n");
f01002a0:	c7 04 24 a3 71 10 f0 	movl   $0xf01071a3,(%esp)
f01002a7:	e8 c2 3d 00 00       	call   f010406e <cprintf>
	va_end(ap);
}
f01002ac:	83 c4 14             	add    $0x14,%esp
f01002af:	5b                   	pop    %ebx
f01002b0:	5d                   	pop    %ebp
f01002b1:	c3                   	ret    
f01002b2:	66 90                	xchg   %ax,%ax
f01002b4:	66 90                	xchg   %ax,%ax
f01002b6:	66 90                	xchg   %ax,%ax
f01002b8:	66 90                	xchg   %ax,%ax
f01002ba:	66 90                	xchg   %ax,%ax
f01002bc:	66 90                	xchg   %ax,%ax
f01002be:	66 90                	xchg   %ax,%ax

f01002c0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01002c0:	55                   	push   %ebp
f01002c1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002c8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01002c9:	a8 01                	test   $0x1,%al
f01002cb:	74 08                	je     f01002d5 <serial_proc_data+0x15>
f01002cd:	b2 f8                	mov    $0xf8,%dl
f01002cf:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01002d0:	0f b6 c0             	movzbl %al,%eax
f01002d3:	eb 05                	jmp    f01002da <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01002d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01002da:	5d                   	pop    %ebp
f01002db:	c3                   	ret    

f01002dc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002dc:	55                   	push   %ebp
f01002dd:	89 e5                	mov    %esp,%ebp
f01002df:	53                   	push   %ebx
f01002e0:	83 ec 04             	sub    $0x4,%esp
f01002e3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01002e5:	eb 2a                	jmp    f0100311 <cons_intr+0x35>
		if (c == 0)
f01002e7:	85 d2                	test   %edx,%edx
f01002e9:	74 26                	je     f0100311 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01002eb:	a1 24 c2 22 f0       	mov    0xf022c224,%eax
f01002f0:	8d 48 01             	lea    0x1(%eax),%ecx
f01002f3:	89 0d 24 c2 22 f0    	mov    %ecx,0xf022c224
f01002f9:	88 90 20 c0 22 f0    	mov    %dl,-0xfdd3fe0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01002ff:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100305:	75 0a                	jne    f0100311 <cons_intr+0x35>
			cons.wpos = 0;
f0100307:	c7 05 24 c2 22 f0 00 	movl   $0x0,0xf022c224
f010030e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100311:	ff d3                	call   *%ebx
f0100313:	89 c2                	mov    %eax,%edx
f0100315:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100318:	75 cd                	jne    f01002e7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010031a:	83 c4 04             	add    $0x4,%esp
f010031d:	5b                   	pop    %ebx
f010031e:	5d                   	pop    %ebp
f010031f:	c3                   	ret    

f0100320 <kbd_proc_data>:
f0100320:	ba 64 00 00 00       	mov    $0x64,%edx
f0100325:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100326:	a8 01                	test   $0x1,%al
f0100328:	0f 84 ef 00 00 00    	je     f010041d <kbd_proc_data+0xfd>
f010032e:	b2 60                	mov    $0x60,%dl
f0100330:	ec                   	in     (%dx),%al
f0100331:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100333:	3c e0                	cmp    $0xe0,%al
f0100335:	75 0d                	jne    f0100344 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100337:	83 0d 00 c0 22 f0 40 	orl    $0x40,0xf022c000
		return 0;
f010033e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100343:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100344:	55                   	push   %ebp
f0100345:	89 e5                	mov    %esp,%ebp
f0100347:	53                   	push   %ebx
f0100348:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010034b:	84 c0                	test   %al,%al
f010034d:	79 37                	jns    f0100386 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010034f:	8b 0d 00 c0 22 f0    	mov    0xf022c000,%ecx
f0100355:	89 cb                	mov    %ecx,%ebx
f0100357:	83 e3 40             	and    $0x40,%ebx
f010035a:	83 e0 7f             	and    $0x7f,%eax
f010035d:	85 db                	test   %ebx,%ebx
f010035f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100362:	0f b6 d2             	movzbl %dl,%edx
f0100365:	0f b6 82 e0 6a 10 f0 	movzbl -0xfef9520(%edx),%eax
f010036c:	83 c8 40             	or     $0x40,%eax
f010036f:	0f b6 c0             	movzbl %al,%eax
f0100372:	f7 d0                	not    %eax
f0100374:	21 c1                	and    %eax,%ecx
f0100376:	89 0d 00 c0 22 f0    	mov    %ecx,0xf022c000
		return 0;
f010037c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100381:	e9 9d 00 00 00       	jmp    f0100423 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100386:	8b 0d 00 c0 22 f0    	mov    0xf022c000,%ecx
f010038c:	f6 c1 40             	test   $0x40,%cl
f010038f:	74 0e                	je     f010039f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100391:	83 c8 80             	or     $0xffffff80,%eax
f0100394:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100396:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100399:	89 0d 00 c0 22 f0    	mov    %ecx,0xf022c000
	}

	shift |= shiftcode[data];
f010039f:	0f b6 d2             	movzbl %dl,%edx
f01003a2:	0f b6 82 e0 6a 10 f0 	movzbl -0xfef9520(%edx),%eax
f01003a9:	0b 05 00 c0 22 f0    	or     0xf022c000,%eax
	shift ^= togglecode[data];
f01003af:	0f b6 8a e0 69 10 f0 	movzbl -0xfef9620(%edx),%ecx
f01003b6:	31 c8                	xor    %ecx,%eax
f01003b8:	a3 00 c0 22 f0       	mov    %eax,0xf022c000

	c = charcode[shift & (CTL | SHIFT)][data];
f01003bd:	89 c1                	mov    %eax,%ecx
f01003bf:	83 e1 03             	and    $0x3,%ecx
f01003c2:	8b 0c 8d c0 69 10 f0 	mov    -0xfef9640(,%ecx,4),%ecx
f01003c9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01003cd:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01003d0:	a8 08                	test   $0x8,%al
f01003d2:	74 1b                	je     f01003ef <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01003d4:	89 da                	mov    %ebx,%edx
f01003d6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01003d9:	83 f9 19             	cmp    $0x19,%ecx
f01003dc:	77 05                	ja     f01003e3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01003de:	83 eb 20             	sub    $0x20,%ebx
f01003e1:	eb 0c                	jmp    f01003ef <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01003e3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003e6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003e9:	83 fa 19             	cmp    $0x19,%edx
f01003ec:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003ef:	f7 d0                	not    %eax
f01003f1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003f3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003f5:	f6 c2 06             	test   $0x6,%dl
f01003f8:	75 29                	jne    f0100423 <kbd_proc_data+0x103>
f01003fa:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100400:	75 21                	jne    f0100423 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100402:	c7 04 24 83 69 10 f0 	movl   $0xf0106983,(%esp)
f0100409:	e8 60 3c 00 00       	call   f010406e <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010040e:	ba 92 00 00 00       	mov    $0x92,%edx
f0100413:	b8 03 00 00 00       	mov    $0x3,%eax
f0100418:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100419:	89 d8                	mov    %ebx,%eax
f010041b:	eb 06                	jmp    f0100423 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010041d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100422:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100423:	83 c4 14             	add    $0x14,%esp
f0100426:	5b                   	pop    %ebx
f0100427:	5d                   	pop    %ebp
f0100428:	c3                   	ret    

f0100429 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100429:	55                   	push   %ebp
f010042a:	89 e5                	mov    %esp,%ebp
f010042c:	57                   	push   %edi
f010042d:	56                   	push   %esi
f010042e:	53                   	push   %ebx
f010042f:	83 ec 1c             	sub    $0x1c,%esp
f0100432:	89 c7                	mov    %eax,%edi
f0100434:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100439:	be fd 03 00 00       	mov    $0x3fd,%esi
f010043e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100443:	eb 0c                	jmp    f0100451 <cons_putc+0x28>
f0100445:	89 ca                	mov    %ecx,%edx
f0100447:	ec                   	in     (%dx),%al
f0100448:	89 ca                	mov    %ecx,%edx
f010044a:	ec                   	in     (%dx),%al
f010044b:	89 ca                	mov    %ecx,%edx
f010044d:	ec                   	in     (%dx),%al
f010044e:	89 ca                	mov    %ecx,%edx
f0100450:	ec                   	in     (%dx),%al
f0100451:	89 f2                	mov    %esi,%edx
f0100453:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100454:	a8 20                	test   $0x20,%al
f0100456:	75 05                	jne    f010045d <cons_putc+0x34>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100458:	83 eb 01             	sub    $0x1,%ebx
f010045b:	75 e8                	jne    f0100445 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f010045d:	89 f8                	mov    %edi,%eax
f010045f:	0f b6 c0             	movzbl %al,%eax
f0100462:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100465:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100470:	be 79 03 00 00       	mov    $0x379,%esi
f0100475:	b9 84 00 00 00       	mov    $0x84,%ecx
f010047a:	eb 0c                	jmp    f0100488 <cons_putc+0x5f>
f010047c:	89 ca                	mov    %ecx,%edx
f010047e:	ec                   	in     (%dx),%al
f010047f:	89 ca                	mov    %ecx,%edx
f0100481:	ec                   	in     (%dx),%al
f0100482:	89 ca                	mov    %ecx,%edx
f0100484:	ec                   	in     (%dx),%al
f0100485:	89 ca                	mov    %ecx,%edx
f0100487:	ec                   	in     (%dx),%al
f0100488:	89 f2                	mov    %esi,%edx
f010048a:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010048b:	84 c0                	test   %al,%al
f010048d:	78 05                	js     f0100494 <cons_putc+0x6b>
f010048f:	83 eb 01             	sub    $0x1,%ebx
f0100492:	75 e8                	jne    f010047c <cons_putc+0x53>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100494:	ba 78 03 00 00       	mov    $0x378,%edx
f0100499:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f010049d:	ee                   	out    %al,(%dx)
f010049e:	b2 7a                	mov    $0x7a,%dl
f01004a0:	b8 0d 00 00 00       	mov    $0xd,%eax
f01004a5:	ee                   	out    %al,(%dx)
f01004a6:	b8 08 00 00 00       	mov    $0x8,%eax
f01004ab:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004ac:	89 fa                	mov    %edi,%edx
f01004ae:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01004b4:	89 f8                	mov    %edi,%eax
f01004b6:	80 cc 07             	or     $0x7,%ah
f01004b9:	85 d2                	test   %edx,%edx
f01004bb:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01004be:	89 f8                	mov    %edi,%eax
f01004c0:	0f b6 c0             	movzbl %al,%eax
f01004c3:	83 f8 09             	cmp    $0x9,%eax
f01004c6:	74 75                	je     f010053d <cons_putc+0x114>
f01004c8:	83 f8 09             	cmp    $0x9,%eax
f01004cb:	7f 0a                	jg     f01004d7 <cons_putc+0xae>
f01004cd:	83 f8 08             	cmp    $0x8,%eax
f01004d0:	74 15                	je     f01004e7 <cons_putc+0xbe>
f01004d2:	e9 9a 00 00 00       	jmp    f0100571 <cons_putc+0x148>
f01004d7:	83 f8 0a             	cmp    $0xa,%eax
f01004da:	74 3b                	je     f0100517 <cons_putc+0xee>
f01004dc:	83 f8 0d             	cmp    $0xd,%eax
f01004df:	90                   	nop
f01004e0:	74 3d                	je     f010051f <cons_putc+0xf6>
f01004e2:	e9 8a 00 00 00       	jmp    f0100571 <cons_putc+0x148>
	case '\b':
		if (crt_pos > 0) {
f01004e7:	0f b7 05 28 c2 22 f0 	movzwl 0xf022c228,%eax
f01004ee:	66 85 c0             	test   %ax,%ax
f01004f1:	0f 84 e5 00 00 00    	je     f01005dc <cons_putc+0x1b3>
			crt_pos--;
f01004f7:	83 e8 01             	sub    $0x1,%eax
f01004fa:	66 a3 28 c2 22 f0    	mov    %ax,0xf022c228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100500:	0f b7 c0             	movzwl %ax,%eax
f0100503:	66 81 e7 00 ff       	and    $0xff00,%di
f0100508:	83 cf 20             	or     $0x20,%edi
f010050b:	8b 15 2c c2 22 f0    	mov    0xf022c22c,%edx
f0100511:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100515:	eb 78                	jmp    f010058f <cons_putc+0x166>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100517:	66 83 05 28 c2 22 f0 	addw   $0x50,0xf022c228
f010051e:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010051f:	0f b7 05 28 c2 22 f0 	movzwl 0xf022c228,%eax
f0100526:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010052c:	c1 e8 16             	shr    $0x16,%eax
f010052f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100532:	c1 e0 04             	shl    $0x4,%eax
f0100535:	66 a3 28 c2 22 f0    	mov    %ax,0xf022c228
f010053b:	eb 52                	jmp    f010058f <cons_putc+0x166>
		break;
	case '\t':
		cons_putc(' ');
f010053d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100542:	e8 e2 fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f0100547:	b8 20 00 00 00       	mov    $0x20,%eax
f010054c:	e8 d8 fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f0100551:	b8 20 00 00 00       	mov    $0x20,%eax
f0100556:	e8 ce fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f010055b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100560:	e8 c4 fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f0100565:	b8 20 00 00 00       	mov    $0x20,%eax
f010056a:	e8 ba fe ff ff       	call   f0100429 <cons_putc>
f010056f:	eb 1e                	jmp    f010058f <cons_putc+0x166>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100571:	0f b7 05 28 c2 22 f0 	movzwl 0xf022c228,%eax
f0100578:	8d 50 01             	lea    0x1(%eax),%edx
f010057b:	66 89 15 28 c2 22 f0 	mov    %dx,0xf022c228
f0100582:	0f b7 c0             	movzwl %ax,%eax
f0100585:	8b 15 2c c2 22 f0    	mov    0xf022c22c,%edx
f010058b:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010058f:	66 81 3d 28 c2 22 f0 	cmpw   $0x7cf,0xf022c228
f0100596:	cf 07 
f0100598:	76 42                	jbe    f01005dc <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010059a:	a1 2c c2 22 f0       	mov    0xf022c22c,%eax
f010059f:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01005a6:	00 
f01005a7:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005ad:	89 54 24 04          	mov    %edx,0x4(%esp)
f01005b1:	89 04 24             	mov    %eax,(%esp)
f01005b4:	e8 1b 56 00 00       	call   f0105bd4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005b9:	8b 15 2c c2 22 f0    	mov    0xf022c22c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005bf:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01005c4:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005ca:	83 c0 01             	add    $0x1,%eax
f01005cd:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01005d2:	75 f0                	jne    f01005c4 <cons_putc+0x19b>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005d4:	66 83 2d 28 c2 22 f0 	subw   $0x50,0xf022c228
f01005db:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005dc:	8b 0d 30 c2 22 f0    	mov    0xf022c230,%ecx
f01005e2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005e7:	89 ca                	mov    %ecx,%edx
f01005e9:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005ea:	0f b7 1d 28 c2 22 f0 	movzwl 0xf022c228,%ebx
f01005f1:	8d 71 01             	lea    0x1(%ecx),%esi
f01005f4:	89 d8                	mov    %ebx,%eax
f01005f6:	66 c1 e8 08          	shr    $0x8,%ax
f01005fa:	89 f2                	mov    %esi,%edx
f01005fc:	ee                   	out    %al,(%dx)
f01005fd:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100602:	89 ca                	mov    %ecx,%edx
f0100604:	ee                   	out    %al,(%dx)
f0100605:	89 d8                	mov    %ebx,%eax
f0100607:	89 f2                	mov    %esi,%edx
f0100609:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010060a:	83 c4 1c             	add    $0x1c,%esp
f010060d:	5b                   	pop    %ebx
f010060e:	5e                   	pop    %esi
f010060f:	5f                   	pop    %edi
f0100610:	5d                   	pop    %ebp
f0100611:	c3                   	ret    

f0100612 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100612:	80 3d 34 c2 22 f0 00 	cmpb   $0x0,0xf022c234
f0100619:	74 11                	je     f010062c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010061b:	55                   	push   %ebp
f010061c:	89 e5                	mov    %esp,%ebp
f010061e:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100621:	b8 c0 02 10 f0       	mov    $0xf01002c0,%eax
f0100626:	e8 b1 fc ff ff       	call   f01002dc <cons_intr>
}
f010062b:	c9                   	leave  
f010062c:	f3 c3                	repz ret 

f010062e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010062e:	55                   	push   %ebp
f010062f:	89 e5                	mov    %esp,%ebp
f0100631:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100634:	b8 20 03 10 f0       	mov    $0xf0100320,%eax
f0100639:	e8 9e fc ff ff       	call   f01002dc <cons_intr>
}
f010063e:	c9                   	leave  
f010063f:	c3                   	ret    

f0100640 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100646:	e8 c7 ff ff ff       	call   f0100612 <serial_intr>
	kbd_intr();
f010064b:	e8 de ff ff ff       	call   f010062e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100650:	a1 20 c2 22 f0       	mov    0xf022c220,%eax
f0100655:	3b 05 24 c2 22 f0    	cmp    0xf022c224,%eax
f010065b:	74 26                	je     f0100683 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f010065d:	8d 50 01             	lea    0x1(%eax),%edx
f0100660:	89 15 20 c2 22 f0    	mov    %edx,0xf022c220
f0100666:	0f b6 88 20 c0 22 f0 	movzbl -0xfdd3fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f010066d:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010066f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100675:	75 11                	jne    f0100688 <cons_getc+0x48>
			cons.rpos = 0;
f0100677:	c7 05 20 c2 22 f0 00 	movl   $0x0,0xf022c220
f010067e:	00 00 00 
f0100681:	eb 05                	jmp    f0100688 <cons_getc+0x48>
		return c;
	}
	return 0;
f0100683:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100688:	c9                   	leave  
f0100689:	c3                   	ret    

f010068a <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010068a:	55                   	push   %ebp
f010068b:	89 e5                	mov    %esp,%ebp
f010068d:	57                   	push   %edi
f010068e:	56                   	push   %esi
f010068f:	53                   	push   %ebx
f0100690:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100693:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010069a:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01006a1:	5a a5 
	if (*cp != 0xA55A) {
f01006a3:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01006aa:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01006ae:	74 11                	je     f01006c1 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01006b0:	c7 05 30 c2 22 f0 b4 	movl   $0x3b4,0xf022c230
f01006b7:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01006ba:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01006bf:	eb 16                	jmp    f01006d7 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01006c1:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006c8:	c7 05 30 c2 22 f0 d4 	movl   $0x3d4,0xf022c230
f01006cf:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006d2:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01006d7:	8b 0d 30 c2 22 f0    	mov    0xf022c230,%ecx
f01006dd:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006e2:	89 ca                	mov    %ecx,%edx
f01006e4:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006e5:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006e8:	89 da                	mov    %ebx,%edx
f01006ea:	ec                   	in     (%dx),%al
f01006eb:	0f b6 f0             	movzbl %al,%esi
f01006ee:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006f1:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006f6:	89 ca                	mov    %ecx,%edx
f01006f8:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006f9:	89 da                	mov    %ebx,%edx
f01006fb:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006fc:	89 3d 2c c2 22 f0    	mov    %edi,0xf022c22c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100702:	0f b6 d8             	movzbl %al,%ebx
f0100705:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100707:	66 89 35 28 c2 22 f0 	mov    %si,0xf022c228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f010070e:	e8 1b ff ff ff       	call   f010062e <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f0100713:	0f b7 05 a8 13 12 f0 	movzwl 0xf01213a8,%eax
f010071a:	25 fd ff 00 00       	and    $0xfffd,%eax
f010071f:	89 04 24             	mov    %eax,(%esp)
f0100722:	e8 08 38 00 00       	call   f0103f2f <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100727:	ba fa 03 00 00       	mov    $0x3fa,%edx
f010072c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100731:	ee                   	out    %al,(%dx)
f0100732:	b2 fb                	mov    $0xfb,%dl
f0100734:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100739:	ee                   	out    %al,(%dx)
f010073a:	b2 f8                	mov    $0xf8,%dl
f010073c:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100741:	ee                   	out    %al,(%dx)
f0100742:	b2 f9                	mov    $0xf9,%dl
f0100744:	b8 00 00 00 00       	mov    $0x0,%eax
f0100749:	ee                   	out    %al,(%dx)
f010074a:	b2 fb                	mov    $0xfb,%dl
f010074c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100751:	ee                   	out    %al,(%dx)
f0100752:	b2 fc                	mov    $0xfc,%dl
f0100754:	b8 00 00 00 00       	mov    $0x0,%eax
f0100759:	ee                   	out    %al,(%dx)
f010075a:	b2 f9                	mov    $0xf9,%dl
f010075c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100761:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100762:	b2 fd                	mov    $0xfd,%dl
f0100764:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100765:	3c ff                	cmp    $0xff,%al
f0100767:	0f 95 c1             	setne  %cl
f010076a:	88 0d 34 c2 22 f0    	mov    %cl,0xf022c234
f0100770:	b2 fa                	mov    $0xfa,%dl
f0100772:	ec                   	in     (%dx),%al
f0100773:	b2 f8                	mov    $0xf8,%dl
f0100775:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100776:	84 c9                	test   %cl,%cl
f0100778:	75 0c                	jne    f0100786 <cons_init+0xfc>
		cprintf("Serial port does not exist!\n");
f010077a:	c7 04 24 8f 69 10 f0 	movl   $0xf010698f,(%esp)
f0100781:	e8 e8 38 00 00       	call   f010406e <cprintf>
}
f0100786:	83 c4 1c             	add    $0x1c,%esp
f0100789:	5b                   	pop    %ebx
f010078a:	5e                   	pop    %esi
f010078b:	5f                   	pop    %edi
f010078c:	5d                   	pop    %ebp
f010078d:	c3                   	ret    

f010078e <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010078e:	55                   	push   %ebp
f010078f:	89 e5                	mov    %esp,%ebp
f0100791:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100794:	8b 45 08             	mov    0x8(%ebp),%eax
f0100797:	e8 8d fc ff ff       	call   f0100429 <cons_putc>
}
f010079c:	c9                   	leave  
f010079d:	c3                   	ret    

f010079e <getchar>:

int
getchar(void)
{
f010079e:	55                   	push   %ebp
f010079f:	89 e5                	mov    %esp,%ebp
f01007a1:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01007a4:	e8 97 fe ff ff       	call   f0100640 <cons_getc>
f01007a9:	85 c0                	test   %eax,%eax
f01007ab:	74 f7                	je     f01007a4 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007ad:	c9                   	leave  
f01007ae:	c3                   	ret    

f01007af <iscons>:

int
iscons(int fdnum)
{
f01007af:	55                   	push   %ebp
f01007b0:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01007b2:	b8 01 00 00 00       	mov    $0x1,%eax
f01007b7:	5d                   	pop    %ebp
f01007b8:	c3                   	ret    
f01007b9:	66 90                	xchg   %ax,%ax
f01007bb:	66 90                	xchg   %ax,%ax
f01007bd:	66 90                	xchg   %ax,%ax
f01007bf:	90                   	nop

f01007c0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007c0:	55                   	push   %ebp
f01007c1:	89 e5                	mov    %esp,%ebp
f01007c3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007c6:	c7 44 24 08 e0 6b 10 	movl   $0xf0106be0,0x8(%esp)
f01007cd:	f0 
f01007ce:	c7 44 24 04 fe 6b 10 	movl   $0xf0106bfe,0x4(%esp)
f01007d5:	f0 
f01007d6:	c7 04 24 03 6c 10 f0 	movl   $0xf0106c03,(%esp)
f01007dd:	e8 8c 38 00 00       	call   f010406e <cprintf>
f01007e2:	c7 44 24 08 a0 6c 10 	movl   $0xf0106ca0,0x8(%esp)
f01007e9:	f0 
f01007ea:	c7 44 24 04 0c 6c 10 	movl   $0xf0106c0c,0x4(%esp)
f01007f1:	f0 
f01007f2:	c7 04 24 03 6c 10 f0 	movl   $0xf0106c03,(%esp)
f01007f9:	e8 70 38 00 00       	call   f010406e <cprintf>
f01007fe:	c7 44 24 08 c8 6c 10 	movl   $0xf0106cc8,0x8(%esp)
f0100805:	f0 
f0100806:	c7 44 24 04 15 6c 10 	movl   $0xf0106c15,0x4(%esp)
f010080d:	f0 
f010080e:	c7 04 24 03 6c 10 f0 	movl   $0xf0106c03,(%esp)
f0100815:	e8 54 38 00 00       	call   f010406e <cprintf>
	return 0;
}
f010081a:	b8 00 00 00 00       	mov    $0x0,%eax
f010081f:	c9                   	leave  
f0100820:	c3                   	ret    

f0100821 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100821:	55                   	push   %ebp
f0100822:	89 e5                	mov    %esp,%ebp
f0100824:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100827:	c7 04 24 1f 6c 10 f0 	movl   $0xf0106c1f,(%esp)
f010082e:	e8 3b 38 00 00       	call   f010406e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100833:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010083a:	00 
f010083b:	c7 04 24 f4 6c 10 f0 	movl   $0xf0106cf4,(%esp)
f0100842:	e8 27 38 00 00       	call   f010406e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100847:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010084e:	00 
f010084f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100856:	f0 
f0100857:	c7 04 24 1c 6d 10 f0 	movl   $0xf0106d1c,(%esp)
f010085e:	e8 0b 38 00 00       	call   f010406e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100863:	c7 44 24 08 a7 68 10 	movl   $0x1068a7,0x8(%esp)
f010086a:	00 
f010086b:	c7 44 24 04 a7 68 10 	movl   $0xf01068a7,0x4(%esp)
f0100872:	f0 
f0100873:	c7 04 24 40 6d 10 f0 	movl   $0xf0106d40,(%esp)
f010087a:	e8 ef 37 00 00       	call   f010406e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010087f:	c7 44 24 08 07 bd 22 	movl   $0x22bd07,0x8(%esp)
f0100886:	00 
f0100887:	c7 44 24 04 07 bd 22 	movl   $0xf022bd07,0x4(%esp)
f010088e:	f0 
f010088f:	c7 04 24 64 6d 10 f0 	movl   $0xf0106d64,(%esp)
f0100896:	e8 d3 37 00 00       	call   f010406e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010089b:	c7 44 24 08 08 e0 26 	movl   $0x26e008,0x8(%esp)
f01008a2:	00 
f01008a3:	c7 44 24 04 08 e0 26 	movl   $0xf026e008,0x4(%esp)
f01008aa:	f0 
f01008ab:	c7 04 24 88 6d 10 f0 	movl   $0xf0106d88,(%esp)
f01008b2:	e8 b7 37 00 00       	call   f010406e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01008b7:	b8 07 e4 26 f0       	mov    $0xf026e407,%eax
f01008bc:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01008c1:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008c6:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01008cc:	85 c0                	test   %eax,%eax
f01008ce:	0f 48 c2             	cmovs  %edx,%eax
f01008d1:	c1 f8 0a             	sar    $0xa,%eax
f01008d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d8:	c7 04 24 ac 6d 10 f0 	movl   $0xf0106dac,(%esp)
f01008df:	e8 8a 37 00 00       	call   f010406e <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01008e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01008e9:	c9                   	leave  
f01008ea:	c3                   	ret    

f01008eb <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008eb:	55                   	push   %ebp
f01008ec:	89 e5                	mov    %esp,%ebp
f01008ee:	56                   	push   %esi
f01008ef:	53                   	push   %ebx
f01008f0:	83 ec 40             	sub    $0x40,%esp
	cprintf("Stack backtrace:\n");
f01008f3:	c7 04 24 38 6c 10 f0 	movl   $0xf0106c38,(%esp)
f01008fa:	e8 6f 37 00 00       	call   f010406e <cprintf>
	int *ebp = (int *) read_ebp();
f01008ff:	89 eb                	mov    %ebp,%ebx
	struct Eipdebuginfo info;

	while (ebp != (int *) 0x0) {
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, *(ebp+1), *(ebp+2), *(ebp+3), *(ebp+4), *(ebp+5), *(ebp+6));

		int check = debuginfo_eip(*(ebp+1), &info);
f0100901:	8d 75 e0             	lea    -0x20(%ebp),%esi
	cprintf("Stack backtrace:\n");
	int *ebp = (int *) read_ebp();

	struct Eipdebuginfo info;

	while (ebp != (int *) 0x0) {
f0100904:	e9 81 00 00 00       	jmp    f010098a <mon_backtrace+0x9f>
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, *(ebp+1), *(ebp+2), *(ebp+3), *(ebp+4), *(ebp+5), *(ebp+6));
f0100909:	8b 43 18             	mov    0x18(%ebx),%eax
f010090c:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100910:	8b 43 14             	mov    0x14(%ebx),%eax
f0100913:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100917:	8b 43 10             	mov    0x10(%ebx),%eax
f010091a:	89 44 24 14          	mov    %eax,0x14(%esp)
f010091e:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100921:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100925:	8b 43 08             	mov    0x8(%ebx),%eax
f0100928:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010092c:	8b 43 04             	mov    0x4(%ebx),%eax
f010092f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100933:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100937:	c7 04 24 d8 6d 10 f0 	movl   $0xf0106dd8,(%esp)
f010093e:	e8 2b 37 00 00       	call   f010406e <cprintf>

		int check = debuginfo_eip(*(ebp+1), &info);
f0100943:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100947:	8b 43 04             	mov    0x4(%ebx),%eax
f010094a:	89 04 24             	mov    %eax,(%esp)
f010094d:	e8 87 47 00 00       	call   f01050d9 <debuginfo_eip>

		if (check == 0) cprintf("         %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, *(ebp+1) - info.eip_fn_addr);
f0100952:	85 c0                	test   %eax,%eax
f0100954:	75 32                	jne    f0100988 <mon_backtrace+0x9d>
f0100956:	8b 43 04             	mov    0x4(%ebx),%eax
f0100959:	2b 45 f0             	sub    -0x10(%ebp),%eax
f010095c:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100960:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100963:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100967:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010096a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010096e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100971:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100975:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100978:	89 44 24 04          	mov    %eax,0x4(%esp)
f010097c:	c7 04 24 4a 6c 10 f0 	movl   $0xf0106c4a,(%esp)
f0100983:	e8 e6 36 00 00       	call   f010406e <cprintf>

		ebp = (int *) (*ebp);
f0100988:	8b 1b                	mov    (%ebx),%ebx
	cprintf("Stack backtrace:\n");
	int *ebp = (int *) read_ebp();

	struct Eipdebuginfo info;

	while (ebp != (int *) 0x0) {
f010098a:	85 db                	test   %ebx,%ebx
f010098c:	0f 85 77 ff ff ff    	jne    f0100909 <mon_backtrace+0x1e>
		ebp = (int *) (*ebp);
	}


	return 0;
}
f0100992:	b8 00 00 00 00       	mov    $0x0,%eax
f0100997:	83 c4 40             	add    $0x40,%esp
f010099a:	5b                   	pop    %ebx
f010099b:	5e                   	pop    %esi
f010099c:	5d                   	pop    %ebp
f010099d:	c3                   	ret    

f010099e <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010099e:	55                   	push   %ebp
f010099f:	89 e5                	mov    %esp,%ebp
f01009a1:	57                   	push   %edi
f01009a2:	56                   	push   %esi
f01009a3:	53                   	push   %ebx
f01009a4:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01009a7:	c7 04 24 10 6e 10 f0 	movl   $0xf0106e10,(%esp)
f01009ae:	e8 bb 36 00 00       	call   f010406e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009b3:	c7 04 24 34 6e 10 f0 	movl   $0xf0106e34,(%esp)
f01009ba:	e8 af 36 00 00       	call   f010406e <cprintf>

	if (tf != NULL)
f01009bf:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01009c3:	74 0b                	je     f01009d0 <monitor+0x32>
		print_trapframe(tf);
f01009c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01009c8:	89 04 24             	mov    %eax,(%esp)
f01009cb:	e8 d9 38 00 00       	call   f01042a9 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f01009d0:	c7 04 24 63 6c 10 f0 	movl   $0xf0106c63,(%esp)
f01009d7:	e8 54 4f 00 00       	call   f0105930 <readline>
f01009dc:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01009de:	85 c0                	test   %eax,%eax
f01009e0:	74 ee                	je     f01009d0 <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01009e2:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01009e9:	be 00 00 00 00       	mov    $0x0,%esi
f01009ee:	eb 0a                	jmp    f01009fa <monitor+0x5c>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01009f0:	c6 03 00             	movb   $0x0,(%ebx)
f01009f3:	89 f7                	mov    %esi,%edi
f01009f5:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01009f8:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01009fa:	0f b6 03             	movzbl (%ebx),%eax
f01009fd:	84 c0                	test   %al,%al
f01009ff:	74 63                	je     f0100a64 <monitor+0xc6>
f0100a01:	0f be c0             	movsbl %al,%eax
f0100a04:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a08:	c7 04 24 67 6c 10 f0 	movl   $0xf0106c67,(%esp)
f0100a0f:	e8 36 51 00 00       	call   f0105b4a <strchr>
f0100a14:	85 c0                	test   %eax,%eax
f0100a16:	75 d8                	jne    f01009f0 <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f0100a18:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100a1b:	74 47                	je     f0100a64 <monitor+0xc6>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100a1d:	83 fe 0f             	cmp    $0xf,%esi
f0100a20:	75 16                	jne    f0100a38 <monitor+0x9a>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a22:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100a29:	00 
f0100a2a:	c7 04 24 6c 6c 10 f0 	movl   $0xf0106c6c,(%esp)
f0100a31:	e8 38 36 00 00       	call   f010406e <cprintf>
f0100a36:	eb 98                	jmp    f01009d0 <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f0100a38:	8d 7e 01             	lea    0x1(%esi),%edi
f0100a3b:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100a3f:	eb 03                	jmp    f0100a44 <monitor+0xa6>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100a41:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a44:	0f b6 03             	movzbl (%ebx),%eax
f0100a47:	84 c0                	test   %al,%al
f0100a49:	74 ad                	je     f01009f8 <monitor+0x5a>
f0100a4b:	0f be c0             	movsbl %al,%eax
f0100a4e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a52:	c7 04 24 67 6c 10 f0 	movl   $0xf0106c67,(%esp)
f0100a59:	e8 ec 50 00 00       	call   f0105b4a <strchr>
f0100a5e:	85 c0                	test   %eax,%eax
f0100a60:	74 df                	je     f0100a41 <monitor+0xa3>
f0100a62:	eb 94                	jmp    f01009f8 <monitor+0x5a>
			buf++;
	}
	argv[argc] = 0;
f0100a64:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a6b:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100a6c:	85 f6                	test   %esi,%esi
f0100a6e:	0f 84 5c ff ff ff    	je     f01009d0 <monitor+0x32>
f0100a74:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100a79:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a7c:	8b 04 85 60 6e 10 f0 	mov    -0xfef91a0(,%eax,4),%eax
f0100a83:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a87:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a8a:	89 04 24             	mov    %eax,(%esp)
f0100a8d:	e8 5a 50 00 00       	call   f0105aec <strcmp>
f0100a92:	85 c0                	test   %eax,%eax
f0100a94:	75 24                	jne    f0100aba <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f0100a96:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a99:	8b 55 08             	mov    0x8(%ebp),%edx
f0100a9c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100aa0:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100aa3:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100aa7:	89 34 24             	mov    %esi,(%esp)
f0100aaa:	ff 14 85 68 6e 10 f0 	call   *-0xfef9198(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100ab1:	85 c0                	test   %eax,%eax
f0100ab3:	78 25                	js     f0100ada <monitor+0x13c>
f0100ab5:	e9 16 ff ff ff       	jmp    f01009d0 <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100aba:	83 c3 01             	add    $0x1,%ebx
f0100abd:	83 fb 03             	cmp    $0x3,%ebx
f0100ac0:	75 b7                	jne    f0100a79 <monitor+0xdb>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100ac2:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100ac5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ac9:	c7 04 24 89 6c 10 f0 	movl   $0xf0106c89,(%esp)
f0100ad0:	e8 99 35 00 00       	call   f010406e <cprintf>
f0100ad5:	e9 f6 fe ff ff       	jmp    f01009d0 <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100ada:	83 c4 5c             	add    $0x5c,%esp
f0100add:	5b                   	pop    %ebx
f0100ade:	5e                   	pop    %esi
f0100adf:	5f                   	pop    %edi
f0100ae0:	5d                   	pop    %ebp
f0100ae1:	c3                   	ret    
f0100ae2:	66 90                	xchg   %ax,%ax
f0100ae4:	66 90                	xchg   %ax,%ax
f0100ae6:	66 90                	xchg   %ax,%ax
f0100ae8:	66 90                	xchg   %ax,%ax
f0100aea:	66 90                	xchg   %ax,%ax
f0100aec:	66 90                	xchg   %ax,%ax
f0100aee:	66 90                	xchg   %ax,%ax

f0100af0 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100af0:	83 3d 38 c2 22 f0 00 	cmpl   $0x0,0xf022c238
f0100af7:	75 11                	jne    f0100b0a <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100af9:	ba 07 f0 26 f0       	mov    $0xf026f007,%edx
f0100afe:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b04:	89 15 38 c2 22 f0    	mov    %edx,0xf022c238
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n == 0) {
f0100b0a:	85 c0                	test   %eax,%eax
f0100b0c:	75 06                	jne    f0100b14 <boot_alloc+0x24>
		return nextfree;
f0100b0e:	a1 38 c2 22 f0       	mov    0xf022c238,%eax
f0100b13:	c3                   	ret    
	}

	if ((uint32_t) nextfree + n >= KERNBASE + 0xfc0000) { //we're out of memory
f0100b14:	8b 15 38 c2 22 f0    	mov    0xf022c238,%edx
f0100b1a:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f0100b1d:	81 f9 ff ff fb f0    	cmp    $0xf0fbffff,%ecx
f0100b23:	76 22                	jbe    f0100b47 <boot_alloc+0x57>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b25:	55                   	push   %ebp
f0100b26:	89 e5                	mov    %esp,%ebp
f0100b28:	83 ec 18             	sub    $0x18,%esp
	if (n == 0) {
		return nextfree;
	}

	if ((uint32_t) nextfree + n >= KERNBASE + 0xfc0000) { //we're out of memory
		panic("boot_alloc: out of memory\n");
f0100b2b:	c7 44 24 08 84 6e 10 	movl   $0xf0106e84,0x8(%esp)
f0100b32:	f0 
f0100b33:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f0100b3a:	00 
f0100b3b:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0100b42:	e8 f9 f4 ff ff       	call   f0100040 <_panic>
	}

	result = nextfree;
	nextfree = nextfree + ROUNDUP(n, PGSIZE);
f0100b47:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100b4c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b51:	01 d0                	add    %edx,%eax
f0100b53:	a3 38 c2 22 f0       	mov    %eax,0xf022c238
	return result;
f0100b58:	89 d0                	mov    %edx,%eax
}
f0100b5a:	c3                   	ret    

f0100b5b <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b5b:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0100b61:	c1 f8 03             	sar    $0x3,%eax
f0100b64:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b67:	89 c2                	mov    %eax,%edx
f0100b69:	c1 ea 0c             	shr    $0xc,%edx
f0100b6c:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0100b72:	72 26                	jb     f0100b9a <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100b74:	55                   	push   %ebp
f0100b75:	89 e5                	mov    %esp,%ebp
f0100b77:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b7a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b7e:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0100b85:	f0 
f0100b86:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100b8d:	00 
f0100b8e:	c7 04 24 ab 6e 10 f0 	movl   $0xf0106eab,(%esp)
f0100b95:	e8 a6 f4 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100b9a:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100b9f:	c3                   	ret    

f0100ba0 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100ba0:	89 d1                	mov    %edx,%ecx
f0100ba2:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100ba5:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100ba8:	a8 01                	test   $0x1,%al
f0100baa:	74 5d                	je     f0100c09 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100bac:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bb1:	89 c1                	mov    %eax,%ecx
f0100bb3:	c1 e9 0c             	shr    $0xc,%ecx
f0100bb6:	3b 0d 88 ce 22 f0    	cmp    0xf022ce88,%ecx
f0100bbc:	72 26                	jb     f0100be4 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100bbe:	55                   	push   %ebp
f0100bbf:	89 e5                	mov    %esp,%ebp
f0100bc1:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bc4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100bc8:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0100bcf:	f0 
f0100bd0:	c7 44 24 04 ca 03 00 	movl   $0x3ca,0x4(%esp)
f0100bd7:	00 
f0100bd8:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0100bdf:	e8 5c f4 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100be4:	c1 ea 0c             	shr    $0xc,%edx
f0100be7:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100bed:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100bf4:	89 c2                	mov    %eax,%edx
f0100bf6:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100bf9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bfe:	85 d2                	test   %edx,%edx
f0100c00:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100c05:	0f 44 c2             	cmove  %edx,%eax
f0100c08:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100c09:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100c0e:	c3                   	ret    

f0100c0f <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100c0f:	55                   	push   %ebp
f0100c10:	89 e5                	mov    %esp,%ebp
f0100c12:	57                   	push   %edi
f0100c13:	56                   	push   %esi
f0100c14:	53                   	push   %ebx
f0100c15:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c18:	84 c0                	test   %al,%al
f0100c1a:	0f 85 31 03 00 00    	jne    f0100f51 <check_page_free_list+0x342>
f0100c20:	e9 3e 03 00 00       	jmp    f0100f63 <check_page_free_list+0x354>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100c25:	c7 44 24 08 d8 71 10 	movl   $0xf01071d8,0x8(%esp)
f0100c2c:	f0 
f0100c2d:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
f0100c34:	00 
f0100c35:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0100c3c:	e8 ff f3 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100c41:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100c44:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c47:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c4a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c4d:	89 c2                	mov    %eax,%edx
f0100c4f:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100c55:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100c5b:	0f 95 c2             	setne  %dl
f0100c5e:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100c61:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100c65:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100c67:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c6b:	8b 00                	mov    (%eax),%eax
f0100c6d:	85 c0                	test   %eax,%eax
f0100c6f:	75 dc                	jne    f0100c4d <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100c71:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c74:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100c7a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c7d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c80:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100c82:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100c85:	a3 40 c2 22 f0       	mov    %eax,0xf022c240
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c8a:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c8f:	8b 1d 40 c2 22 f0    	mov    0xf022c240,%ebx
f0100c95:	eb 63                	jmp    f0100cfa <check_page_free_list+0xeb>
f0100c97:	89 d8                	mov    %ebx,%eax
f0100c99:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0100c9f:	c1 f8 03             	sar    $0x3,%eax
f0100ca2:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ca5:	89 c2                	mov    %eax,%edx
f0100ca7:	c1 ea 16             	shr    $0x16,%edx
f0100caa:	39 f2                	cmp    %esi,%edx
f0100cac:	73 4a                	jae    f0100cf8 <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cae:	89 c2                	mov    %eax,%edx
f0100cb0:	c1 ea 0c             	shr    $0xc,%edx
f0100cb3:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0100cb9:	72 20                	jb     f0100cdb <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cbb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cbf:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0100cc6:	f0 
f0100cc7:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100cce:	00 
f0100ccf:	c7 04 24 ab 6e 10 f0 	movl   $0xf0106eab,(%esp)
f0100cd6:	e8 65 f3 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100cdb:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100ce2:	00 
f0100ce3:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100cea:	00 
	return (void *)(pa + KERNBASE);
f0100ceb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cf0:	89 04 24             	mov    %eax,(%esp)
f0100cf3:	e8 8f 4e 00 00       	call   f0105b87 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100cf8:	8b 1b                	mov    (%ebx),%ebx
f0100cfa:	85 db                	test   %ebx,%ebx
f0100cfc:	75 99                	jne    f0100c97 <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100cfe:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d03:	e8 e8 fd ff ff       	call   f0100af0 <boot_alloc>
f0100d08:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d0b:	8b 15 40 c2 22 f0    	mov    0xf022c240,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d11:	8b 0d 90 ce 22 f0    	mov    0xf022ce90,%ecx
		assert(pp < pages + npages);
f0100d17:	a1 88 ce 22 f0       	mov    0xf022ce88,%eax
f0100d1c:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100d1f:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100d22:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d25:	89 4d cc             	mov    %ecx,-0x34(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100d28:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d2d:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d30:	e9 c4 01 00 00       	jmp    f0100ef9 <check_page_free_list+0x2ea>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d35:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100d38:	73 24                	jae    f0100d5e <check_page_free_list+0x14f>
f0100d3a:	c7 44 24 0c b9 6e 10 	movl   $0xf0106eb9,0xc(%esp)
f0100d41:	f0 
f0100d42:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0100d49:	f0 
f0100d4a:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f0100d51:	00 
f0100d52:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0100d59:	e8 e2 f2 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100d5e:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100d61:	72 24                	jb     f0100d87 <check_page_free_list+0x178>
f0100d63:	c7 44 24 0c da 6e 10 	movl   $0xf0106eda,0xc(%esp)
f0100d6a:	f0 
f0100d6b:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0100d72:	f0 
f0100d73:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f0100d7a:	00 
f0100d7b:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0100d82:	e8 b9 f2 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d87:	89 d0                	mov    %edx,%eax
f0100d89:	2b 45 cc             	sub    -0x34(%ebp),%eax
f0100d8c:	a8 07                	test   $0x7,%al
f0100d8e:	74 24                	je     f0100db4 <check_page_free_list+0x1a5>
f0100d90:	c7 44 24 0c fc 71 10 	movl   $0xf01071fc,0xc(%esp)
f0100d97:	f0 
f0100d98:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0100d9f:	f0 
f0100da0:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0100da7:	00 
f0100da8:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0100daf:	e8 8c f2 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100db4:	c1 f8 03             	sar    $0x3,%eax
f0100db7:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100dba:	85 c0                	test   %eax,%eax
f0100dbc:	75 24                	jne    f0100de2 <check_page_free_list+0x1d3>
f0100dbe:	c7 44 24 0c ee 6e 10 	movl   $0xf0106eee,0xc(%esp)
f0100dc5:	f0 
f0100dc6:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0100dcd:	f0 
f0100dce:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0100dd5:	00 
f0100dd6:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0100ddd:	e8 5e f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100de2:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100de7:	75 24                	jne    f0100e0d <check_page_free_list+0x1fe>
f0100de9:	c7 44 24 0c ff 6e 10 	movl   $0xf0106eff,0xc(%esp)
f0100df0:	f0 
f0100df1:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0100df8:	f0 
f0100df9:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0100e00:	00 
f0100e01:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0100e08:	e8 33 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e0d:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e12:	75 24                	jne    f0100e38 <check_page_free_list+0x229>
f0100e14:	c7 44 24 0c 30 72 10 	movl   $0xf0107230,0xc(%esp)
f0100e1b:	f0 
f0100e1c:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0100e23:	f0 
f0100e24:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0100e2b:	00 
f0100e2c:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0100e33:	e8 08 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e38:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e3d:	75 24                	jne    f0100e63 <check_page_free_list+0x254>
f0100e3f:	c7 44 24 0c 18 6f 10 	movl   $0xf0106f18,0xc(%esp)
f0100e46:	f0 
f0100e47:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0100e4e:	f0 
f0100e4f:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0100e56:	00 
f0100e57:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0100e5e:	e8 dd f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e63:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e68:	0f 86 1c 01 00 00    	jbe    f0100f8a <check_page_free_list+0x37b>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e6e:	89 c1                	mov    %eax,%ecx
f0100e70:	c1 e9 0c             	shr    $0xc,%ecx
f0100e73:	39 4d c4             	cmp    %ecx,-0x3c(%ebp)
f0100e76:	77 20                	ja     f0100e98 <check_page_free_list+0x289>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e78:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e7c:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0100e83:	f0 
f0100e84:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100e8b:	00 
f0100e8c:	c7 04 24 ab 6e 10 f0 	movl   $0xf0106eab,(%esp)
f0100e93:	e8 a8 f1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100e98:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f0100e9e:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100ea1:	0f 86 d3 00 00 00    	jbe    f0100f7a <check_page_free_list+0x36b>
f0100ea7:	c7 44 24 0c 54 72 10 	movl   $0xf0107254,0xc(%esp)
f0100eae:	f0 
f0100eaf:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0100eb6:	f0 
f0100eb7:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0100ebe:	00 
f0100ebf:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0100ec6:	e8 75 f1 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100ecb:	c7 44 24 0c 32 6f 10 	movl   $0xf0106f32,0xc(%esp)
f0100ed2:	f0 
f0100ed3:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0100eda:	f0 
f0100edb:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0100ee2:	00 
f0100ee3:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0100eea:	e8 51 f1 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100eef:	83 c3 01             	add    $0x1,%ebx
f0100ef2:	eb 03                	jmp    f0100ef7 <check_page_free_list+0x2e8>
		else
			++nfree_extmem;
f0100ef4:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ef7:	8b 12                	mov    (%edx),%edx
f0100ef9:	85 d2                	test   %edx,%edx
f0100efb:	0f 85 34 fe ff ff    	jne    f0100d35 <check_page_free_list+0x126>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100f01:	85 db                	test   %ebx,%ebx
f0100f03:	7f 24                	jg     f0100f29 <check_page_free_list+0x31a>
f0100f05:	c7 44 24 0c 4f 6f 10 	movl   $0xf0106f4f,0xc(%esp)
f0100f0c:	f0 
f0100f0d:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0100f14:	f0 
f0100f15:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0100f1c:	00 
f0100f1d:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0100f24:	e8 17 f1 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100f29:	85 ff                	test   %edi,%edi
f0100f2b:	7f 6d                	jg     f0100f9a <check_page_free_list+0x38b>
f0100f2d:	c7 44 24 0c 61 6f 10 	movl   $0xf0106f61,0xc(%esp)
f0100f34:	f0 
f0100f35:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0100f3c:	f0 
f0100f3d:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0100f44:	00 
f0100f45:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0100f4c:	e8 ef f0 ff ff       	call   f0100040 <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100f51:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f0100f56:	85 c0                	test   %eax,%eax
f0100f58:	0f 85 e3 fc ff ff    	jne    f0100c41 <check_page_free_list+0x32>
f0100f5e:	e9 c2 fc ff ff       	jmp    f0100c25 <check_page_free_list+0x16>
f0100f63:	83 3d 40 c2 22 f0 00 	cmpl   $0x0,0xf022c240
f0100f6a:	0f 84 b5 fc ff ff    	je     f0100c25 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f70:	be 00 04 00 00       	mov    $0x400,%esi
f0100f75:	e9 15 fd ff ff       	jmp    f0100c8f <check_page_free_list+0x80>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100f7a:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100f7f:	0f 85 6f ff ff ff    	jne    f0100ef4 <check_page_free_list+0x2e5>
f0100f85:	e9 41 ff ff ff       	jmp    f0100ecb <check_page_free_list+0x2bc>
f0100f8a:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100f8f:	0f 85 5a ff ff ff    	jne    f0100eef <check_page_free_list+0x2e0>
f0100f95:	e9 31 ff ff ff       	jmp    f0100ecb <check_page_free_list+0x2bc>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100f9a:	83 c4 4c             	add    $0x4c,%esp
f0100f9d:	5b                   	pop    %ebx
f0100f9e:	5e                   	pop    %esi
f0100f9f:	5f                   	pop    %edi
f0100fa0:	5d                   	pop    %ebp
f0100fa1:	c3                   	ret    

f0100fa2 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100fa2:	55                   	push   %ebp
f0100fa3:	89 e5                	mov    %esp,%ebp
f0100fa5:	57                   	push   %edi
f0100fa6:	56                   	push   %esi
f0100fa7:	53                   	push   %ebx
f0100fa8:	83 ec 1c             	sub    $0x1c,%esp
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!

	size_t i;
	uint32_t free_addr = PADDR(boot_alloc(0));
f0100fab:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fb0:	e8 3b fb ff ff       	call   f0100af0 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100fb5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100fba:	77 20                	ja     f0100fdc <page_init+0x3a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100fbc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fc0:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f0100fc7:	f0 
f0100fc8:	c7 44 24 04 4e 01 00 	movl   $0x14e,0x4(%esp)
f0100fcf:	00 
f0100fd0:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0100fd7:	e8 64 f0 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100fdc:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx

	// 1. physical page 0 in use
	pages[0].pp_ref = 1;
f0100fe2:	a1 90 ce 22 f0       	mov    0xf022ce90,%eax
f0100fe7:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f0100fed:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// 2. base memory is free
	for (i = 1; i < npages_basemem; i++) {
f0100ff3:	8b 3d 44 c2 22 f0    	mov    0xf022c244,%edi
f0100ff9:	8b 35 40 c2 22 f0    	mov    0xf022c240,%esi
f0100fff:	b8 01 00 00 00       	mov    $0x1,%eax
f0101004:	eb 3c                	jmp    f0101042 <page_init+0xa0>
		//except for the MPENTRY_PADDR (lab 4)
		if (i == MPENTRY_PADDR/PGSIZE) {
f0101006:	83 f8 07             	cmp    $0x7,%eax
f0101009:	75 15                	jne    f0101020 <page_init+0x7e>
			pages[i].pp_ref = 1;
f010100b:	8b 15 90 ce 22 f0    	mov    0xf022ce90,%edx
f0101011:	66 c7 42 3c 01 00    	movw   $0x1,0x3c(%edx)
			pages[i].pp_link = NULL;
f0101017:	c7 42 38 00 00 00 00 	movl   $0x0,0x38(%edx)
f010101e:	eb 1f                	jmp    f010103f <page_init+0x9d>
f0101020:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		} else {
			pages[i].pp_ref = 0;
f0101027:	89 d1                	mov    %edx,%ecx
f0101029:	03 0d 90 ce 22 f0    	add    0xf022ce90,%ecx
f010102f:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
			pages[i].pp_link = page_free_list;
f0101035:	89 31                	mov    %esi,(%ecx)
			page_free_list = &pages[i];
f0101037:	89 d6                	mov    %edx,%esi
f0101039:	03 35 90 ce 22 f0    	add    0xf022ce90,%esi
	// 1. physical page 0 in use
	pages[0].pp_ref = 1;
	pages[0].pp_link = NULL;

	// 2. base memory is free
	for (i = 1; i < npages_basemem; i++) {
f010103f:	83 c0 01             	add    $0x1,%eax
f0101042:	39 f8                	cmp    %edi,%eax
f0101044:	72 c0                	jb     f0101006 <page_init+0x64>
f0101046:	89 35 40 c2 22 f0    	mov    %esi,0xf022c240
f010104c:	b8 00 05 00 00       	mov    $0x500,%eax
		}
	}

	// 3. IO hole is not allocated
	for (i = IOPHYSMEM/PGSIZE; i < EXTPHYSMEM/PGSIZE; i++) {
		pages[i].pp_ref = 1;
f0101051:	89 c2                	mov    %eax,%edx
f0101053:	03 15 90 ce 22 f0    	add    0xf022ce90,%edx
f0101059:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
		pages[i].pp_link = NULL;
f010105f:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
f0101065:	83 c0 08             	add    $0x8,%eax
			page_free_list = &pages[i];
		}
	}

	// 3. IO hole is not allocated
	for (i = IOPHYSMEM/PGSIZE; i < EXTPHYSMEM/PGSIZE; i++) {
f0101068:	3d 00 08 00 00       	cmp    $0x800,%eax
f010106d:	75 e2                	jne    f0101051 <page_init+0xaf>
		pages[i].pp_ref = 1;
		pages[i].pp_link = NULL;
	}

	// 4. some of the extended memory is in use
	for (i = EXTPHYSMEM/PGSIZE; i < free_addr/PGSIZE; i++) {
f010106f:	89 d8                	mov    %ebx,%eax
f0101071:	c1 e8 0c             	shr    $0xc,%eax
f0101074:	ba 00 01 00 00       	mov    $0x100,%edx
f0101079:	eb 18                	jmp    f0101093 <page_init+0xf1>
		pages[i].pp_ref = 1;
f010107b:	8b 0d 90 ce 22 f0    	mov    0xf022ce90,%ecx
f0101081:	8d 0c d1             	lea    (%ecx,%edx,8),%ecx
f0101084:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
		pages[i].pp_link = NULL;
f010108a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		pages[i].pp_ref = 1;
		pages[i].pp_link = NULL;
	}

	// 4. some of the extended memory is in use
	for (i = EXTPHYSMEM/PGSIZE; i < free_addr/PGSIZE; i++) {
f0101090:	83 c2 01             	add    $0x1,%edx
f0101093:	39 c2                	cmp    %eax,%edx
f0101095:	72 e4                	jb     f010107b <page_init+0xd9>
f0101097:	8b 1d 40 c2 22 f0    	mov    0xf022c240,%ebx
f010109d:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f01010a4:	eb 1e                	jmp    f01010c4 <page_init+0x122>
		pages[i].pp_link = NULL;
	}

	// and the rest is free
	for (i = free_addr/PGSIZE; i < npages; i++) {
		pages[i].pp_ref = 0;
f01010a6:	89 d1                	mov    %edx,%ecx
f01010a8:	03 0d 90 ce 22 f0    	add    0xf022ce90,%ecx
f01010ae:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f01010b4:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f01010b6:	89 d3                	mov    %edx,%ebx
f01010b8:	03 1d 90 ce 22 f0    	add    0xf022ce90,%ebx
		pages[i].pp_ref = 1;
		pages[i].pp_link = NULL;
	}

	// and the rest is free
	for (i = free_addr/PGSIZE; i < npages; i++) {
f01010be:	83 c0 01             	add    $0x1,%eax
f01010c1:	83 c2 08             	add    $0x8,%edx
f01010c4:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f01010ca:	72 da                	jb     f01010a6 <page_init+0x104>
f01010cc:	89 1d 40 c2 22 f0    	mov    %ebx,0xf022c240
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}

}
f01010d2:	83 c4 1c             	add    $0x1c,%esp
f01010d5:	5b                   	pop    %ebx
f01010d6:	5e                   	pop    %esi
f01010d7:	5f                   	pop    %edi
f01010d8:	5d                   	pop    %ebp
f01010d9:	c3                   	ret    

f01010da <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f01010da:	55                   	push   %ebp
f01010db:	89 e5                	mov    %esp,%ebp
f01010dd:	53                   	push   %ebx
f01010de:	83 ec 14             	sub    $0x14,%esp
	//cprintf("DEBUG page_alloc has been called!\n");

	if (page_free_list == NULL) { //out of free memory
f01010e1:	8b 1d 40 c2 22 f0    	mov    0xf022c240,%ebx
f01010e7:	85 db                	test   %ebx,%ebx
f01010e9:	74 6f                	je     f010115a <page_alloc+0x80>
		return NULL;
	}

	struct PageInfo * pag = page_free_list;
	page_free_list = pag->pp_link;
f01010eb:	8b 03                	mov    (%ebx),%eax
f01010ed:	a3 40 c2 22 f0       	mov    %eax,0xf022c240
	pag->pp_link = NULL;
f01010f2:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)

	if (alloc_flags && ALLOC_ZERO) {
		memset(page2kva(pag), '\0', PGSIZE);
	}
		
	return pag;
f01010f8:	89 d8                	mov    %ebx,%eax

	struct PageInfo * pag = page_free_list;
	page_free_list = pag->pp_link;
	pag->pp_link = NULL;

	if (alloc_flags && ALLOC_ZERO) {
f01010fa:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01010fe:	74 5f                	je     f010115f <page_alloc+0x85>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101100:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0101106:	c1 f8 03             	sar    $0x3,%eax
f0101109:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010110c:	89 c2                	mov    %eax,%edx
f010110e:	c1 ea 0c             	shr    $0xc,%edx
f0101111:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0101117:	72 20                	jb     f0101139 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101119:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010111d:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0101124:	f0 
f0101125:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f010112c:	00 
f010112d:	c7 04 24 ab 6e 10 f0 	movl   $0xf0106eab,(%esp)
f0101134:	e8 07 ef ff ff       	call   f0100040 <_panic>
		memset(page2kva(pag), '\0', PGSIZE);
f0101139:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101140:	00 
f0101141:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101148:	00 
	return (void *)(pa + KERNBASE);
f0101149:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010114e:	89 04 24             	mov    %eax,(%esp)
f0101151:	e8 31 4a 00 00       	call   f0105b87 <memset>
	}
		
	return pag;
f0101156:	89 d8                	mov    %ebx,%eax
f0101158:	eb 05                	jmp    f010115f <page_alloc+0x85>
page_alloc(int alloc_flags)
{
	//cprintf("DEBUG page_alloc has been called!\n");

	if (page_free_list == NULL) { //out of free memory
		return NULL;
f010115a:	b8 00 00 00 00       	mov    $0x0,%eax
	if (alloc_flags && ALLOC_ZERO) {
		memset(page2kva(pag), '\0', PGSIZE);
	}
		
	return pag;
}
f010115f:	83 c4 14             	add    $0x14,%esp
f0101162:	5b                   	pop    %ebx
f0101163:	5d                   	pop    %ebp
f0101164:	c3                   	ret    

f0101165 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101165:	55                   	push   %ebp
f0101166:	89 e5                	mov    %esp,%ebp
f0101168:	83 ec 18             	sub    $0x18,%esp
f010116b:	8b 45 08             	mov    0x8(%ebp),%eax
	//cprintf("DEBUG page_free has been called!\n");
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	if (pp->pp_ref != 0) {
f010116e:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101173:	74 1c                	je     f0101191 <page_free+0x2c>
		panic("page_free: pp_ref is nonzero\n");
f0101175:	c7 44 24 08 72 6f 10 	movl   $0xf0106f72,0x8(%esp)
f010117c:	f0 
f010117d:	c7 44 24 04 a2 01 00 	movl   $0x1a2,0x4(%esp)
f0101184:	00 
f0101185:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010118c:	e8 af ee ff ff       	call   f0100040 <_panic>
	} else if (pp->pp_link != NULL) {
f0101191:	83 38 00             	cmpl   $0x0,(%eax)
f0101194:	74 1c                	je     f01011b2 <page_free+0x4d>
		panic("page_free: pp_link is not NULL\n");
f0101196:	c7 44 24 08 9c 72 10 	movl   $0xf010729c,0x8(%esp)
f010119d:	f0 
f010119e:	c7 44 24 04 a4 01 00 	movl   $0x1a4,0x4(%esp)
f01011a5:	00 
f01011a6:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01011ad:	e8 8e ee ff ff       	call   f0100040 <_panic>
	} else {
		pp->pp_ref = 0;
f01011b2:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pp->pp_link = page_free_list;
f01011b8:	8b 15 40 c2 22 f0    	mov    0xf022c240,%edx
f01011be:	89 10                	mov    %edx,(%eax)
		page_free_list = pp;
f01011c0:	a3 40 c2 22 f0       	mov    %eax,0xf022c240
	}
}
f01011c5:	c9                   	leave  
f01011c6:	c3                   	ret    

f01011c7 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f01011c7:	55                   	push   %ebp
f01011c8:	89 e5                	mov    %esp,%ebp
f01011ca:	83 ec 18             	sub    $0x18,%esp
f01011cd:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f01011d0:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f01011d4:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01011d7:	66 89 50 04          	mov    %dx,0x4(%eax)
f01011db:	66 85 d2             	test   %dx,%dx
f01011de:	75 08                	jne    f01011e8 <page_decref+0x21>
		page_free(pp);
f01011e0:	89 04 24             	mov    %eax,(%esp)
f01011e3:	e8 7d ff ff ff       	call   f0101165 <page_free>
}
f01011e8:	c9                   	leave  
f01011e9:	c3                   	ret    

f01011ea <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that manipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01011ea:	55                   	push   %ebp
f01011eb:	89 e5                	mov    %esp,%ebp
f01011ed:	57                   	push   %edi
f01011ee:	56                   	push   %esi
f01011ef:	53                   	push   %ebx
f01011f0:	83 ec 1c             	sub    $0x1c,%esp
f01011f3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	uint32_t ptx = PTX(va);*/

	pde_t * pde; // va(virtual address) point to pa(physical address)
	pte_t * pgtable; // same as pde
	struct PageInfo *pp;
	pde = &pgdir[PDX(va)]; // va->pgdir
f01011f6:	89 de                	mov    %ebx,%esi
f01011f8:	c1 ee 16             	shr    $0x16,%esi
f01011fb:	c1 e6 02             	shl    $0x2,%esi
f01011fe:	03 75 08             	add    0x8(%ebp),%esi

	if(*pde & PTE_P) {
f0101201:	8b 06                	mov    (%esi),%eax
f0101203:	a8 01                	test   $0x1,%al
f0101205:	74 3d                	je     f0101244 <pgdir_walk+0x5a>
		pgtable = (KADDR(PTE_ADDR(*pde)));
f0101207:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010120c:	89 c2                	mov    %eax,%edx
f010120e:	c1 ea 0c             	shr    $0xc,%edx
f0101211:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0101217:	72 20                	jb     f0101239 <pgdir_walk+0x4f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101219:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010121d:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0101224:	f0 
f0101225:	c7 44 24 04 dc 01 00 	movl   $0x1dc,0x4(%esp)
f010122c:	00 
f010122d:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101234:	e8 07 ee ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101239:	8d 90 00 00 00 f0    	lea    -0x10000000(%eax),%edx
f010123f:	e9 97 00 00 00       	jmp    f01012db <pgdir_walk+0xf1>
	} else {

	//page table page not exist
		if(!create ||
f0101244:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101248:	0f 84 9b 00 00 00    	je     f01012e9 <pgdir_walk+0xff>
f010124e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101255:	e8 80 fe ff ff       	call   f01010da <page_alloc>
f010125a:	85 c0                	test   %eax,%eax
f010125c:	0f 84 8e 00 00 00    	je     f01012f0 <pgdir_walk+0x106>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101262:	89 c1                	mov    %eax,%ecx
f0101264:	2b 0d 90 ce 22 f0    	sub    0xf022ce90,%ecx
f010126a:	c1 f9 03             	sar    $0x3,%ecx
f010126d:	c1 e1 0c             	shl    $0xc,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101270:	89 ca                	mov    %ecx,%edx
f0101272:	c1 ea 0c             	shr    $0xc,%edx
f0101275:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f010127b:	72 20                	jb     f010129d <pgdir_walk+0xb3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010127d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0101281:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0101288:	f0 
f0101289:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101290:	00 
f0101291:	c7 04 24 ab 6e 10 f0 	movl   $0xf0106eab,(%esp)
f0101298:	e8 a3 ed ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010129d:	8d b9 00 00 00 f0    	lea    -0x10000000(%ecx),%edi
f01012a3:	89 fa                	mov    %edi,%edx
		   !(pp = page_alloc(ALLOC_ZERO)) ||
f01012a5:	85 ff                	test   %edi,%edi
f01012a7:	74 4e                	je     f01012f7 <pgdir_walk+0x10d>
		   !(pgtable = (pte_t*)page2kva(pp)))
			return NULL;
		pp->pp_ref++;
f01012a9:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01012ae:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f01012b4:	77 20                	ja     f01012d6 <pgdir_walk+0xec>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01012b6:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01012ba:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f01012c1:	f0 
f01012c2:	c7 44 24 04 e5 01 00 	movl   $0x1e5,0x4(%esp)
f01012c9:	00 
f01012ca:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01012d1:	e8 6a ed ff ff       	call   f0100040 <_panic>
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
f01012d6:	83 c9 07             	or     $0x7,%ecx
f01012d9:	89 0e                	mov    %ecx,(%esi)
	}

	return &pgtable[PTX(va)];
f01012db:	c1 eb 0a             	shr    $0xa,%ebx
f01012de:	89 d8                	mov    %ebx,%eax
f01012e0:	25 fc 0f 00 00       	and    $0xffc,%eax
f01012e5:	01 d0                	add    %edx,%eax
f01012e7:	eb 13                	jmp    f01012fc <pgdir_walk+0x112>

	//page table page not exist
		if(!create ||
		   !(pp = page_alloc(ALLOC_ZERO)) ||
		   !(pgtable = (pte_t*)page2kva(pp)))
			return NULL;
f01012e9:	b8 00 00 00 00       	mov    $0x0,%eax
f01012ee:	eb 0c                	jmp    f01012fc <pgdir_walk+0x112>
f01012f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01012f5:	eb 05                	jmp    f01012fc <pgdir_walk+0x112>
f01012f7:	b8 00 00 00 00       	mov    $0x0,%eax
		*pde = PADDR(pgtable) | PTE_P | PTE_W | PTE_U;
	}

	return &pgtable[PTX(va)];

}
f01012fc:	83 c4 1c             	add    $0x1c,%esp
f01012ff:	5b                   	pop    %ebx
f0101300:	5e                   	pop    %esi
f0101301:	5f                   	pop    %edi
f0101302:	5d                   	pop    %ebp
f0101303:	c3                   	ret    

f0101304 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void 
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101304:	55                   	push   %ebp
f0101305:	89 e5                	mov    %esp,%ebp
f0101307:	57                   	push   %edi
f0101308:	56                   	push   %esi
f0101309:	53                   	push   %ebx
f010130a:	83 ec 2c             	sub    $0x2c,%esp
f010130d:	89 c6                	mov    %eax,%esi
f010130f:	89 cf                	mov    %ecx,%edi
	va &= ~0xfff;
f0101311:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	pa &= ~0xfff;
f0101317:	8b 45 08             	mov    0x8(%ebp),%eax
f010131a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
//
// Hint: the TA solution uses pgdir_walk
static void 
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	va &= ~0xfff;
f010131f:	89 d3                	mov    %edx,%ebx
f0101321:	29 d0                	sub    %edx,%eax
f0101323:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pa &= ~0xfff;
	for ( ; size != 0; va += PGSIZE, pa += PGSIZE, size -= PGSIZE) {
		pde_t *pte_p = pgdir_walk(pgdir, (void *) va, true);
		assert(pte_p);
		*pte_p = pa | perm | PTE_P;
f0101326:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101329:	83 c8 01             	or     $0x1,%eax
f010132c:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void 
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	va &= ~0xfff;
	pa &= ~0xfff;
	for ( ; size != 0; va += PGSIZE, pa += PGSIZE, size -= PGSIZE) {
f010132f:	eb 5a                	jmp    f010138b <boot_map_region+0x87>
		pde_t *pte_p = pgdir_walk(pgdir, (void *) va, true);
f0101331:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101338:	00 
f0101339:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010133d:	89 34 24             	mov    %esi,(%esp)
f0101340:	e8 a5 fe ff ff       	call   f01011ea <pgdir_walk>
		assert(pte_p);
f0101345:	85 c0                	test   %eax,%eax
f0101347:	75 24                	jne    f010136d <boot_map_region+0x69>
f0101349:	c7 44 24 0c 90 6f 10 	movl   $0xf0106f90,0xc(%esp)
f0101350:	f0 
f0101351:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101358:	f0 
f0101359:	c7 44 24 04 fe 01 00 	movl   $0x1fe,0x4(%esp)
f0101360:	00 
f0101361:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101368:	e8 d3 ec ff ff       	call   f0100040 <_panic>
		*pte_p = pa | perm | PTE_P;
f010136d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101370:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101373:	09 ca                	or     %ecx,%edx
f0101375:	89 10                	mov    %edx,(%eax)
		pgdir[PDX(va)] |= perm | PTE_P;
f0101377:	89 d8                	mov    %ebx,%eax
f0101379:	c1 e8 16             	shr    $0x16,%eax
f010137c:	09 0c 86             	or     %ecx,(%esi,%eax,4)
static void 
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	va &= ~0xfff;
	pa &= ~0xfff;
	for ( ; size != 0; va += PGSIZE, pa += PGSIZE, size -= PGSIZE) {
f010137f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101385:	81 ef 00 10 00 00    	sub    $0x1000,%edi
f010138b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010138e:	01 d8                	add    %ebx,%eax
f0101390:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101393:	85 ff                	test   %edi,%edi
f0101395:	75 9a                	jne    f0101331 <boot_map_region+0x2d>
		pde_t *pte_p = pgdir_walk(pgdir, (void *) va, true);
		assert(pte_p);
		*pte_p = pa | perm | PTE_P;
		pgdir[PDX(va)] |= perm | PTE_P;
	}
}
f0101397:	83 c4 2c             	add    $0x2c,%esp
f010139a:	5b                   	pop    %ebx
f010139b:	5e                   	pop    %esi
f010139c:	5f                   	pop    %edi
f010139d:	5d                   	pop    %ebp
f010139e:	c3                   	ret    

f010139f <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010139f:	55                   	push   %ebp
f01013a0:	89 e5                	mov    %esp,%ebp
f01013a2:	53                   	push   %ebx
f01013a3:	83 ec 14             	sub    $0x14,%esp
f01013a6:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pde_t *pte_p = pgdir_walk(pgdir, va, false);
f01013a9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01013b0:	00 
f01013b1:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01013bb:	89 04 24             	mov    %eax,(%esp)
f01013be:	e8 27 fe ff ff       	call   f01011ea <pgdir_walk>

	if (!pte_p)
f01013c3:	85 c0                	test   %eax,%eax
f01013c5:	74 3e                	je     f0101405 <page_lookup+0x66>
		return NULL;

	if (pte_store)
f01013c7:	85 db                	test   %ebx,%ebx
f01013c9:	74 02                	je     f01013cd <page_lookup+0x2e>
		*pte_store = pte_p;
f01013cb:	89 03                	mov    %eax,(%ebx)

	if (*pte_p & PTE_P)
f01013cd:	8b 00                	mov    (%eax),%eax
f01013cf:	a8 01                	test   $0x1,%al
f01013d1:	74 39                	je     f010140c <page_lookup+0x6d>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013d3:	c1 e8 0c             	shr    $0xc,%eax
f01013d6:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f01013dc:	72 1c                	jb     f01013fa <page_lookup+0x5b>
		panic("pa2page called with invalid pa");
f01013de:	c7 44 24 08 bc 72 10 	movl   $0xf01072bc,0x8(%esp)
f01013e5:	f0 
f01013e6:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f01013ed:	00 
f01013ee:	c7 04 24 ab 6e 10 f0 	movl   $0xf0106eab,(%esp)
f01013f5:	e8 46 ec ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f01013fa:	8b 15 90 ce 22 f0    	mov    0xf022ce90,%edx
f0101400:	8d 04 c2             	lea    (%edx,%eax,8),%eax
		return pa2page(PTE_ADDR(*pte_p));
f0101403:	eb 0c                	jmp    f0101411 <page_lookup+0x72>
{
	// Fill this function in
	pde_t *pte_p = pgdir_walk(pgdir, va, false);

	if (!pte_p)
		return NULL;
f0101405:	b8 00 00 00 00       	mov    $0x0,%eax
f010140a:	eb 05                	jmp    f0101411 <page_lookup+0x72>
		*pte_store = pte_p;

	if (*pte_p & PTE_P)
		return pa2page(PTE_ADDR(*pte_p));

	return NULL;
f010140c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101411:	83 c4 14             	add    $0x14,%esp
f0101414:	5b                   	pop    %ebx
f0101415:	5d                   	pop    %ebp
f0101416:	c3                   	ret    

f0101417 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101417:	55                   	push   %ebp
f0101418:	89 e5                	mov    %esp,%ebp
f010141a:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f010141d:	e8 b7 4d 00 00       	call   f01061d9 <cpunum>
f0101422:	6b c0 74             	imul   $0x74,%eax,%eax
f0101425:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f010142c:	74 16                	je     f0101444 <tlb_invalidate+0x2d>
f010142e:	e8 a6 4d 00 00       	call   f01061d9 <cpunum>
f0101433:	6b c0 74             	imul   $0x74,%eax,%eax
f0101436:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f010143c:	8b 55 08             	mov    0x8(%ebp),%edx
f010143f:	39 50 60             	cmp    %edx,0x60(%eax)
f0101442:	75 06                	jne    f010144a <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101444:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101447:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f010144a:	c9                   	leave  
f010144b:	c3                   	ret    

f010144c <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010144c:	55                   	push   %ebp
f010144d:	89 e5                	mov    %esp,%ebp
f010144f:	56                   	push   %esi
f0101450:	53                   	push   %ebx
f0101451:	83 ec 20             	sub    $0x20,%esp
f0101454:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101457:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	struct PageInfo *page = NULL;
	pte_t *pte_p = NULL;
f010145a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	if ((page = page_lookup(pgdir, va, &pte_p)) != NULL) {
f0101461:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101464:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101468:	89 74 24 04          	mov    %esi,0x4(%esp)
f010146c:	89 1c 24             	mov    %ebx,(%esp)
f010146f:	e8 2b ff ff ff       	call   f010139f <page_lookup>
f0101474:	85 c0                	test   %eax,%eax
f0101476:	74 1d                	je     f0101495 <page_remove+0x49>
		page_decref(page);
f0101478:	89 04 24             	mov    %eax,(%esp)
f010147b:	e8 47 fd ff ff       	call   f01011c7 <page_decref>
		*pte_p = *pte_p & (0xfff & ~PTE_P);
f0101480:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101483:	81 20 fe 0f 00 00    	andl   $0xffe,(%eax)
		tlb_invalidate(pgdir, va);
f0101489:	89 74 24 04          	mov    %esi,0x4(%esp)
f010148d:	89 1c 24             	mov    %ebx,(%esp)
f0101490:	e8 82 ff ff ff       	call   f0101417 <tlb_invalidate>
	}
}
f0101495:	83 c4 20             	add    $0x20,%esp
f0101498:	5b                   	pop    %ebx
f0101499:	5e                   	pop    %esi
f010149a:	5d                   	pop    %ebp
f010149b:	c3                   	ret    

f010149c <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010149c:	55                   	push   %ebp
f010149d:	89 e5                	mov    %esp,%ebp
f010149f:	57                   	push   %edi
f01014a0:	56                   	push   %esi
f01014a1:	53                   	push   %ebx
f01014a2:	83 ec 1c             	sub    $0x1c,%esp
f01014a5:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01014a8:	8b 7d 0c             	mov    0xc(%ebp),%edi
	// Fill this function in
	pte_t *pte_p = pgdir_walk(pgdir, va, true);
f01014ab:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01014b2:	00 
f01014b3:	8b 45 10             	mov    0x10(%ebp),%eax
f01014b6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014ba:	89 1c 24             	mov    %ebx,(%esp)
f01014bd:	e8 28 fd ff ff       	call   f01011ea <pgdir_walk>
f01014c2:	89 c6                	mov    %eax,%esi
	if (!pte_p)
f01014c4:	85 c0                	test   %eax,%eax
f01014c6:	74 5d                	je     f0101525 <page_insert+0x89>
		return -E_NO_MEM;

	pp->pp_ref++;
f01014c8:	66 83 47 04 01       	addw   $0x1,0x4(%edi)

	if (*pte_p & PTE_P)
f01014cd:	f6 00 01             	testb  $0x1,(%eax)
f01014d0:	74 0f                	je     f01014e1 <page_insert+0x45>
		page_remove(pgdir, va);
f01014d2:	8b 45 10             	mov    0x10(%ebp),%eax
f01014d5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014d9:	89 1c 24             	mov    %ebx,(%esp)
f01014dc:	e8 6b ff ff ff       	call   f010144c <page_remove>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014e1:	2b 3d 90 ce 22 f0    	sub    0xf022ce90,%edi
f01014e7:	c1 ff 03             	sar    $0x3,%edi
f01014ea:	c1 e7 0c             	shl    $0xc,%edi

	*pte_p = page2pa(pp) | perm | PTE_P;
f01014ed:	0b 7d 14             	or     0x14(%ebp),%edi
f01014f0:	89 f8                	mov    %edi,%eax
f01014f2:	83 c8 01             	or     $0x1,%eax
f01014f5:	89 06                	mov    %eax,(%esi)

	pgdir[PDX(va)] |= *pte_p & 0xfff;
f01014f7:	8b 45 10             	mov    0x10(%ebp),%eax
f01014fa:	c1 e8 16             	shr    $0x16,%eax
f01014fd:	8d 04 83             	lea    (%ebx,%eax,4),%eax
f0101500:	8b 10                	mov    (%eax),%edx
f0101502:	83 ca 01             	or     $0x1,%edx
f0101505:	81 e7 ff 0f 00 00    	and    $0xfff,%edi
f010150b:	09 d7                	or     %edx,%edi
f010150d:	89 38                	mov    %edi,(%eax)
	tlb_invalidate(pgdir, va);
f010150f:	8b 45 10             	mov    0x10(%ebp),%eax
f0101512:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101516:	89 1c 24             	mov    %ebx,(%esp)
f0101519:	e8 f9 fe ff ff       	call   f0101417 <tlb_invalidate>
	return 0;
f010151e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101523:	eb 05                	jmp    f010152a <page_insert+0x8e>
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	// Fill this function in
	pte_t *pte_p = pgdir_walk(pgdir, va, true);
	if (!pte_p)
		return -E_NO_MEM;
f0101525:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	*pte_p = page2pa(pp) | perm | PTE_P;

	pgdir[PDX(va)] |= *pte_p & 0xfff;
	tlb_invalidate(pgdir, va);
	return 0;
}
f010152a:	83 c4 1c             	add    $0x1c,%esp
f010152d:	5b                   	pop    %ebx
f010152e:	5e                   	pop    %esi
f010152f:	5f                   	pop    %edi
f0101530:	5d                   	pop    %ebp
f0101531:	c3                   	ret    

f0101532 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f0101532:	55                   	push   %ebp
f0101533:	89 e5                	mov    %esp,%ebp
f0101535:	53                   	push   %ebx
f0101536:	83 ec 14             	sub    $0x14,%esp
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	
	//round size to be a multiple of PGSIZE
	size = ROUNDUP(size, PGSIZE);
f0101539:	8b 45 0c             	mov    0xc(%ebp),%eax
f010153c:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0101542:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx

	//check if it overflows MMIOLIM
	if (base + size > MMIOLIM)
f0101548:	8b 15 00 13 12 f0    	mov    0xf0121300,%edx
f010154e:	8d 04 13             	lea    (%ebx,%edx,1),%eax
f0101551:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f0101556:	76 1c                	jbe    f0101574 <mmio_map_region+0x42>
		panic("mmio_map_region(): reservation overflows MMIOLIM");
f0101558:	c7 44 24 08 dc 72 10 	movl   $0xf01072dc,0x8(%esp)
f010155f:	f0 
f0101560:	c7 44 24 04 9d 02 00 	movl   $0x29d,0x4(%esp)
f0101567:	00 
f0101568:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010156f:	e8 cc ea ff ff       	call   f0100040 <_panic>

	//reserve the bytes
	boot_map_region(kern_pgdir, base, size, pa, PTE_PCD|PTE_PWT|PTE_W);
f0101574:	c7 44 24 04 1a 00 00 	movl   $0x1a,0x4(%esp)
f010157b:	00 
f010157c:	8b 45 08             	mov    0x8(%ebp),%eax
f010157f:	89 04 24             	mov    %eax,(%esp)
f0101582:	89 d9                	mov    %ebx,%ecx
f0101584:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0101589:	e8 76 fd ff ff       	call   f0101304 <boot_map_region>

	//update base and return old base
	uintptr_t old_base = base;
f010158e:	a1 00 13 12 f0       	mov    0xf0121300,%eax
	base += size;
f0101593:	01 c3                	add    %eax,%ebx
f0101595:	89 1d 00 13 12 f0    	mov    %ebx,0xf0121300
	return (void *) old_base;
	
}
f010159b:	83 c4 14             	add    $0x14,%esp
f010159e:	5b                   	pop    %ebx
f010159f:	5d                   	pop    %ebp
f01015a0:	c3                   	ret    

f01015a1 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01015a1:	55                   	push   %ebp
f01015a2:	89 e5                	mov    %esp,%ebp
f01015a4:	57                   	push   %edi
f01015a5:	56                   	push   %esi
f01015a6:	53                   	push   %ebx
f01015a7:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01015aa:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f01015b1:	e8 4f 29 00 00       	call   f0103f05 <mc146818_read>
f01015b6:	89 c3                	mov    %eax,%ebx
f01015b8:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01015bf:	e8 41 29 00 00       	call   f0103f05 <mc146818_read>
f01015c4:	c1 e0 08             	shl    $0x8,%eax
f01015c7:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01015c9:	89 d8                	mov    %ebx,%eax
f01015cb:	c1 e0 0a             	shl    $0xa,%eax
f01015ce:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01015d4:	85 c0                	test   %eax,%eax
f01015d6:	0f 48 c2             	cmovs  %edx,%eax
f01015d9:	c1 f8 0c             	sar    $0xc,%eax
f01015dc:	a3 44 c2 22 f0       	mov    %eax,0xf022c244
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01015e1:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f01015e8:	e8 18 29 00 00       	call   f0103f05 <mc146818_read>
f01015ed:	89 c3                	mov    %eax,%ebx
f01015ef:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f01015f6:	e8 0a 29 00 00       	call   f0103f05 <mc146818_read>
f01015fb:	c1 e0 08             	shl    $0x8,%eax
f01015fe:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101600:	89 d8                	mov    %ebx,%eax
f0101602:	c1 e0 0a             	shl    $0xa,%eax
f0101605:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010160b:	85 c0                	test   %eax,%eax
f010160d:	0f 48 c2             	cmovs  %edx,%eax
f0101610:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101613:	85 c0                	test   %eax,%eax
f0101615:	74 0e                	je     f0101625 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101617:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010161d:	89 15 88 ce 22 f0    	mov    %edx,0xf022ce88
f0101623:	eb 0c                	jmp    f0101631 <mem_init+0x90>
	else
		npages = npages_basemem;
f0101625:	8b 15 44 c2 22 f0    	mov    0xf022c244,%edx
f010162b:	89 15 88 ce 22 f0    	mov    %edx,0xf022ce88

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101631:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101634:	c1 e8 0a             	shr    $0xa,%eax
f0101637:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f010163b:	a1 44 c2 22 f0       	mov    0xf022c244,%eax
f0101640:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101643:	c1 e8 0a             	shr    $0xa,%eax
f0101646:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010164a:	a1 88 ce 22 f0       	mov    0xf022ce88,%eax
f010164f:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101652:	c1 e8 0a             	shr    $0xa,%eax
f0101655:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101659:	c7 04 24 10 73 10 f0 	movl   $0xf0107310,(%esp)
f0101660:	e8 09 2a 00 00       	call   f010406e <cprintf>
	// Remove this line when you're ready to test this function.
	// panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101665:	b8 00 10 00 00       	mov    $0x1000,%eax
f010166a:	e8 81 f4 ff ff       	call   f0100af0 <boot_alloc>
f010166f:	a3 8c ce 22 f0       	mov    %eax,0xf022ce8c
	memset(kern_pgdir, 0, PGSIZE);
f0101674:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010167b:	00 
f010167c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101683:	00 
f0101684:	89 04 24             	mov    %eax,(%esp)
f0101687:	e8 fb 44 00 00       	call   f0105b87 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f010168c:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101691:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101696:	77 20                	ja     f01016b8 <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101698:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010169c:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f01016a3:	f0 
f01016a4:	c7 44 24 04 9a 00 00 	movl   $0x9a,0x4(%esp)
f01016ab:	00 
f01016ac:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01016b3:	e8 88 e9 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01016b8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01016be:	83 ca 05             	or     $0x5,%edx
f01016c1:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f01016c7:	a1 88 ce 22 f0       	mov    0xf022ce88,%eax
f01016cc:	c1 e0 03             	shl    $0x3,%eax
f01016cf:	e8 1c f4 ff ff       	call   f0100af0 <boot_alloc>
f01016d4:	a3 90 ce 22 f0       	mov    %eax,0xf022ce90
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01016d9:	8b 0d 88 ce 22 f0    	mov    0xf022ce88,%ecx
f01016df:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01016e6:	89 54 24 08          	mov    %edx,0x8(%esp)
f01016ea:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01016f1:	00 
f01016f2:	89 04 24             	mov    %eax,(%esp)
f01016f5:	e8 8d 44 00 00       	call   f0105b87 <memset>
	}*/ 

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *) boot_alloc(NENV * sizeof(struct Env));
f01016fa:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f01016ff:	e8 ec f3 ff ff       	call   f0100af0 <boot_alloc>
f0101704:	a3 48 c2 22 f0       	mov    %eax,0xf022c248
	memset(envs, 0, NENV * sizeof(struct Env));
f0101709:	c7 44 24 08 00 f0 01 	movl   $0x1f000,0x8(%esp)
f0101710:	00 
f0101711:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101718:	00 
f0101719:	89 04 24             	mov    %eax,(%esp)
f010171c:	e8 66 44 00 00       	call   f0105b87 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101721:	e8 7c f8 ff ff       	call   f0100fa2 <page_init>

	check_page_free_list(1);
f0101726:	b8 01 00 00 00       	mov    $0x1,%eax
f010172b:	e8 df f4 ff ff       	call   f0100c0f <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101730:	83 3d 90 ce 22 f0 00 	cmpl   $0x0,0xf022ce90
f0101737:	75 1c                	jne    f0101755 <mem_init+0x1b4>
		panic("'pages' is a null pointer!");
f0101739:	c7 44 24 08 96 6f 10 	movl   $0xf0106f96,0x8(%esp)
f0101740:	f0 
f0101741:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0101748:	00 
f0101749:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101750:	e8 eb e8 ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101755:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f010175a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010175f:	eb 05                	jmp    f0101766 <mem_init+0x1c5>
		++nfree;
f0101761:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101764:	8b 00                	mov    (%eax),%eax
f0101766:	85 c0                	test   %eax,%eax
f0101768:	75 f7                	jne    f0101761 <mem_init+0x1c0>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010176a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101771:	e8 64 f9 ff ff       	call   f01010da <page_alloc>
f0101776:	89 c7                	mov    %eax,%edi
f0101778:	85 c0                	test   %eax,%eax
f010177a:	75 24                	jne    f01017a0 <mem_init+0x1ff>
f010177c:	c7 44 24 0c b1 6f 10 	movl   $0xf0106fb1,0xc(%esp)
f0101783:	f0 
f0101784:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010178b:	f0 
f010178c:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f0101793:	00 
f0101794:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010179b:	e8 a0 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01017a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017a7:	e8 2e f9 ff ff       	call   f01010da <page_alloc>
f01017ac:	89 c6                	mov    %eax,%esi
f01017ae:	85 c0                	test   %eax,%eax
f01017b0:	75 24                	jne    f01017d6 <mem_init+0x235>
f01017b2:	c7 44 24 0c c7 6f 10 	movl   $0xf0106fc7,0xc(%esp)
f01017b9:	f0 
f01017ba:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01017c1:	f0 
f01017c2:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f01017c9:	00 
f01017ca:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01017d1:	e8 6a e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01017d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017dd:	e8 f8 f8 ff ff       	call   f01010da <page_alloc>
f01017e2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017e5:	85 c0                	test   %eax,%eax
f01017e7:	75 24                	jne    f010180d <mem_init+0x26c>
f01017e9:	c7 44 24 0c dd 6f 10 	movl   $0xf0106fdd,0xc(%esp)
f01017f0:	f0 
f01017f1:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01017f8:	f0 
f01017f9:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0101800:	00 
f0101801:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101808:	e8 33 e8 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010180d:	39 f7                	cmp    %esi,%edi
f010180f:	75 24                	jne    f0101835 <mem_init+0x294>
f0101811:	c7 44 24 0c f3 6f 10 	movl   $0xf0106ff3,0xc(%esp)
f0101818:	f0 
f0101819:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101820:	f0 
f0101821:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0101828:	00 
f0101829:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101830:	e8 0b e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101835:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101838:	39 c6                	cmp    %eax,%esi
f010183a:	74 04                	je     f0101840 <mem_init+0x29f>
f010183c:	39 c7                	cmp    %eax,%edi
f010183e:	75 24                	jne    f0101864 <mem_init+0x2c3>
f0101840:	c7 44 24 0c 4c 73 10 	movl   $0xf010734c,0xc(%esp)
f0101847:	f0 
f0101848:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010184f:	f0 
f0101850:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101857:	00 
f0101858:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010185f:	e8 dc e7 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101864:	8b 15 90 ce 22 f0    	mov    0xf022ce90,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010186a:	a1 88 ce 22 f0       	mov    0xf022ce88,%eax
f010186f:	c1 e0 0c             	shl    $0xc,%eax
f0101872:	89 f9                	mov    %edi,%ecx
f0101874:	29 d1                	sub    %edx,%ecx
f0101876:	c1 f9 03             	sar    $0x3,%ecx
f0101879:	c1 e1 0c             	shl    $0xc,%ecx
f010187c:	39 c1                	cmp    %eax,%ecx
f010187e:	72 24                	jb     f01018a4 <mem_init+0x303>
f0101880:	c7 44 24 0c 05 70 10 	movl   $0xf0107005,0xc(%esp)
f0101887:	f0 
f0101888:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010188f:	f0 
f0101890:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0101897:	00 
f0101898:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010189f:	e8 9c e7 ff ff       	call   f0100040 <_panic>
f01018a4:	89 f1                	mov    %esi,%ecx
f01018a6:	29 d1                	sub    %edx,%ecx
f01018a8:	c1 f9 03             	sar    $0x3,%ecx
f01018ab:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01018ae:	39 c8                	cmp    %ecx,%eax
f01018b0:	77 24                	ja     f01018d6 <mem_init+0x335>
f01018b2:	c7 44 24 0c 22 70 10 	movl   $0xf0107022,0xc(%esp)
f01018b9:	f0 
f01018ba:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01018c1:	f0 
f01018c2:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f01018c9:	00 
f01018ca:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01018d1:	e8 6a e7 ff ff       	call   f0100040 <_panic>
f01018d6:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01018d9:	29 d1                	sub    %edx,%ecx
f01018db:	89 ca                	mov    %ecx,%edx
f01018dd:	c1 fa 03             	sar    $0x3,%edx
f01018e0:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01018e3:	39 d0                	cmp    %edx,%eax
f01018e5:	77 24                	ja     f010190b <mem_init+0x36a>
f01018e7:	c7 44 24 0c 3f 70 10 	movl   $0xf010703f,0xc(%esp)
f01018ee:	f0 
f01018ef:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01018f6:	f0 
f01018f7:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f01018fe:	00 
f01018ff:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101906:	e8 35 e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010190b:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f0101910:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101913:	c7 05 40 c2 22 f0 00 	movl   $0x0,0xf022c240
f010191a:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010191d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101924:	e8 b1 f7 ff ff       	call   f01010da <page_alloc>
f0101929:	85 c0                	test   %eax,%eax
f010192b:	74 24                	je     f0101951 <mem_init+0x3b0>
f010192d:	c7 44 24 0c 5c 70 10 	movl   $0xf010705c,0xc(%esp)
f0101934:	f0 
f0101935:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010193c:	f0 
f010193d:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0101944:	00 
f0101945:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010194c:	e8 ef e6 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101951:	89 3c 24             	mov    %edi,(%esp)
f0101954:	e8 0c f8 ff ff       	call   f0101165 <page_free>
	page_free(pp1);
f0101959:	89 34 24             	mov    %esi,(%esp)
f010195c:	e8 04 f8 ff ff       	call   f0101165 <page_free>
	page_free(pp2);
f0101961:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101964:	89 04 24             	mov    %eax,(%esp)
f0101967:	e8 f9 f7 ff ff       	call   f0101165 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010196c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101973:	e8 62 f7 ff ff       	call   f01010da <page_alloc>
f0101978:	89 c6                	mov    %eax,%esi
f010197a:	85 c0                	test   %eax,%eax
f010197c:	75 24                	jne    f01019a2 <mem_init+0x401>
f010197e:	c7 44 24 0c b1 6f 10 	movl   $0xf0106fb1,0xc(%esp)
f0101985:	f0 
f0101986:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010198d:	f0 
f010198e:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f0101995:	00 
f0101996:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010199d:	e8 9e e6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01019a2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019a9:	e8 2c f7 ff ff       	call   f01010da <page_alloc>
f01019ae:	89 c7                	mov    %eax,%edi
f01019b0:	85 c0                	test   %eax,%eax
f01019b2:	75 24                	jne    f01019d8 <mem_init+0x437>
f01019b4:	c7 44 24 0c c7 6f 10 	movl   $0xf0106fc7,0xc(%esp)
f01019bb:	f0 
f01019bc:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01019c3:	f0 
f01019c4:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f01019cb:	00 
f01019cc:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01019d3:	e8 68 e6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01019d8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019df:	e8 f6 f6 ff ff       	call   f01010da <page_alloc>
f01019e4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01019e7:	85 c0                	test   %eax,%eax
f01019e9:	75 24                	jne    f0101a0f <mem_init+0x46e>
f01019eb:	c7 44 24 0c dd 6f 10 	movl   $0xf0106fdd,0xc(%esp)
f01019f2:	f0 
f01019f3:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01019fa:	f0 
f01019fb:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0101a02:	00 
f0101a03:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101a0a:	e8 31 e6 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a0f:	39 fe                	cmp    %edi,%esi
f0101a11:	75 24                	jne    f0101a37 <mem_init+0x496>
f0101a13:	c7 44 24 0c f3 6f 10 	movl   $0xf0106ff3,0xc(%esp)
f0101a1a:	f0 
f0101a1b:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101a22:	f0 
f0101a23:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f0101a2a:	00 
f0101a2b:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101a32:	e8 09 e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a37:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a3a:	39 c7                	cmp    %eax,%edi
f0101a3c:	74 04                	je     f0101a42 <mem_init+0x4a1>
f0101a3e:	39 c6                	cmp    %eax,%esi
f0101a40:	75 24                	jne    f0101a66 <mem_init+0x4c5>
f0101a42:	c7 44 24 0c 4c 73 10 	movl   $0xf010734c,0xc(%esp)
f0101a49:	f0 
f0101a4a:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101a51:	f0 
f0101a52:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f0101a59:	00 
f0101a5a:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101a61:	e8 da e5 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101a66:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a6d:	e8 68 f6 ff ff       	call   f01010da <page_alloc>
f0101a72:	85 c0                	test   %eax,%eax
f0101a74:	74 24                	je     f0101a9a <mem_init+0x4f9>
f0101a76:	c7 44 24 0c 5c 70 10 	movl   $0xf010705c,0xc(%esp)
f0101a7d:	f0 
f0101a7e:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101a85:	f0 
f0101a86:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f0101a8d:	00 
f0101a8e:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101a95:	e8 a6 e5 ff ff       	call   f0100040 <_panic>
f0101a9a:	89 f0                	mov    %esi,%eax
f0101a9c:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0101aa2:	c1 f8 03             	sar    $0x3,%eax
f0101aa5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101aa8:	89 c2                	mov    %eax,%edx
f0101aaa:	c1 ea 0c             	shr    $0xc,%edx
f0101aad:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0101ab3:	72 20                	jb     f0101ad5 <mem_init+0x534>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ab5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101ab9:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0101ac0:	f0 
f0101ac1:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101ac8:	00 
f0101ac9:	c7 04 24 ab 6e 10 f0 	movl   $0xf0106eab,(%esp)
f0101ad0:	e8 6b e5 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101ad5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101adc:	00 
f0101add:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101ae4:	00 
	return (void *)(pa + KERNBASE);
f0101ae5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101aea:	89 04 24             	mov    %eax,(%esp)
f0101aed:	e8 95 40 00 00       	call   f0105b87 <memset>
	page_free(pp0);
f0101af2:	89 34 24             	mov    %esi,(%esp)
f0101af5:	e8 6b f6 ff ff       	call   f0101165 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101afa:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101b01:	e8 d4 f5 ff ff       	call   f01010da <page_alloc>
f0101b06:	85 c0                	test   %eax,%eax
f0101b08:	75 24                	jne    f0101b2e <mem_init+0x58d>
f0101b0a:	c7 44 24 0c 6b 70 10 	movl   $0xf010706b,0xc(%esp)
f0101b11:	f0 
f0101b12:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101b19:	f0 
f0101b1a:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f0101b21:	00 
f0101b22:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101b29:	e8 12 e5 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101b2e:	39 c6                	cmp    %eax,%esi
f0101b30:	74 24                	je     f0101b56 <mem_init+0x5b5>
f0101b32:	c7 44 24 0c 89 70 10 	movl   $0xf0107089,0xc(%esp)
f0101b39:	f0 
f0101b3a:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101b41:	f0 
f0101b42:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0101b49:	00 
f0101b4a:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101b51:	e8 ea e4 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b56:	89 f0                	mov    %esi,%eax
f0101b58:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0101b5e:	c1 f8 03             	sar    $0x3,%eax
f0101b61:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b64:	89 c2                	mov    %eax,%edx
f0101b66:	c1 ea 0c             	shr    $0xc,%edx
f0101b69:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f0101b6f:	72 20                	jb     f0101b91 <mem_init+0x5f0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b71:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101b75:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0101b7c:	f0 
f0101b7d:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101b84:	00 
f0101b85:	c7 04 24 ab 6e 10 f0 	movl   $0xf0106eab,(%esp)
f0101b8c:	e8 af e4 ff ff       	call   f0100040 <_panic>
f0101b91:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101b97:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101b9d:	80 38 00             	cmpb   $0x0,(%eax)
f0101ba0:	74 24                	je     f0101bc6 <mem_init+0x625>
f0101ba2:	c7 44 24 0c 99 70 10 	movl   $0xf0107099,0xc(%esp)
f0101ba9:	f0 
f0101baa:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101bb1:	f0 
f0101bb2:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f0101bb9:	00 
f0101bba:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101bc1:	e8 7a e4 ff ff       	call   f0100040 <_panic>
f0101bc6:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101bc9:	39 d0                	cmp    %edx,%eax
f0101bcb:	75 d0                	jne    f0101b9d <mem_init+0x5fc>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101bcd:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bd0:	a3 40 c2 22 f0       	mov    %eax,0xf022c240

	// free the pages we took
	page_free(pp0);
f0101bd5:	89 34 24             	mov    %esi,(%esp)
f0101bd8:	e8 88 f5 ff ff       	call   f0101165 <page_free>
	page_free(pp1);
f0101bdd:	89 3c 24             	mov    %edi,(%esp)
f0101be0:	e8 80 f5 ff ff       	call   f0101165 <page_free>
	page_free(pp2);
f0101be5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101be8:	89 04 24             	mov    %eax,(%esp)
f0101beb:	e8 75 f5 ff ff       	call   f0101165 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101bf0:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f0101bf5:	eb 05                	jmp    f0101bfc <mem_init+0x65b>
		--nfree;
f0101bf7:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101bfa:	8b 00                	mov    (%eax),%eax
f0101bfc:	85 c0                	test   %eax,%eax
f0101bfe:	75 f7                	jne    f0101bf7 <mem_init+0x656>
		--nfree;
	assert(nfree == 0);
f0101c00:	85 db                	test   %ebx,%ebx
f0101c02:	74 24                	je     f0101c28 <mem_init+0x687>
f0101c04:	c7 44 24 0c a3 70 10 	movl   $0xf01070a3,0xc(%esp)
f0101c0b:	f0 
f0101c0c:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101c13:	f0 
f0101c14:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f0101c1b:	00 
f0101c1c:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101c23:	e8 18 e4 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101c28:	c7 04 24 6c 73 10 f0 	movl   $0xf010736c,(%esp)
f0101c2f:	e8 3a 24 00 00       	call   f010406e <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101c34:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c3b:	e8 9a f4 ff ff       	call   f01010da <page_alloc>
f0101c40:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101c43:	85 c0                	test   %eax,%eax
f0101c45:	75 24                	jne    f0101c6b <mem_init+0x6ca>
f0101c47:	c7 44 24 0c b1 6f 10 	movl   $0xf0106fb1,0xc(%esp)
f0101c4e:	f0 
f0101c4f:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101c56:	f0 
f0101c57:	c7 44 24 04 df 03 00 	movl   $0x3df,0x4(%esp)
f0101c5e:	00 
f0101c5f:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101c66:	e8 d5 e3 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101c6b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c72:	e8 63 f4 ff ff       	call   f01010da <page_alloc>
f0101c77:	89 c3                	mov    %eax,%ebx
f0101c79:	85 c0                	test   %eax,%eax
f0101c7b:	75 24                	jne    f0101ca1 <mem_init+0x700>
f0101c7d:	c7 44 24 0c c7 6f 10 	movl   $0xf0106fc7,0xc(%esp)
f0101c84:	f0 
f0101c85:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101c8c:	f0 
f0101c8d:	c7 44 24 04 e0 03 00 	movl   $0x3e0,0x4(%esp)
f0101c94:	00 
f0101c95:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101c9c:	e8 9f e3 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101ca1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ca8:	e8 2d f4 ff ff       	call   f01010da <page_alloc>
f0101cad:	89 c6                	mov    %eax,%esi
f0101caf:	85 c0                	test   %eax,%eax
f0101cb1:	75 24                	jne    f0101cd7 <mem_init+0x736>
f0101cb3:	c7 44 24 0c dd 6f 10 	movl   $0xf0106fdd,0xc(%esp)
f0101cba:	f0 
f0101cbb:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101cc2:	f0 
f0101cc3:	c7 44 24 04 e1 03 00 	movl   $0x3e1,0x4(%esp)
f0101cca:	00 
f0101ccb:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101cd2:	e8 69 e3 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101cd7:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101cda:	75 24                	jne    f0101d00 <mem_init+0x75f>
f0101cdc:	c7 44 24 0c f3 6f 10 	movl   $0xf0106ff3,0xc(%esp)
f0101ce3:	f0 
f0101ce4:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101ceb:	f0 
f0101cec:	c7 44 24 04 e4 03 00 	movl   $0x3e4,0x4(%esp)
f0101cf3:	00 
f0101cf4:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101cfb:	e8 40 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101d00:	39 c3                	cmp    %eax,%ebx
f0101d02:	74 05                	je     f0101d09 <mem_init+0x768>
f0101d04:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101d07:	75 24                	jne    f0101d2d <mem_init+0x78c>
f0101d09:	c7 44 24 0c 4c 73 10 	movl   $0xf010734c,0xc(%esp)
f0101d10:	f0 
f0101d11:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101d18:	f0 
f0101d19:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f0101d20:	00 
f0101d21:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101d28:	e8 13 e3 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101d2d:	a1 40 c2 22 f0       	mov    0xf022c240,%eax
f0101d32:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101d35:	c7 05 40 c2 22 f0 00 	movl   $0x0,0xf022c240
f0101d3c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101d3f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d46:	e8 8f f3 ff ff       	call   f01010da <page_alloc>
f0101d4b:	85 c0                	test   %eax,%eax
f0101d4d:	74 24                	je     f0101d73 <mem_init+0x7d2>
f0101d4f:	c7 44 24 0c 5c 70 10 	movl   $0xf010705c,0xc(%esp)
f0101d56:	f0 
f0101d57:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101d5e:	f0 
f0101d5f:	c7 44 24 04 ec 03 00 	movl   $0x3ec,0x4(%esp)
f0101d66:	00 
f0101d67:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101d6e:	e8 cd e2 ff ff       	call   f0100040 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101d73:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101d76:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101d7a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101d81:	00 
f0101d82:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0101d87:	89 04 24             	mov    %eax,(%esp)
f0101d8a:	e8 10 f6 ff ff       	call   f010139f <page_lookup>
f0101d8f:	85 c0                	test   %eax,%eax
f0101d91:	74 24                	je     f0101db7 <mem_init+0x816>
f0101d93:	c7 44 24 0c 8c 73 10 	movl   $0xf010738c,0xc(%esp)
f0101d9a:	f0 
f0101d9b:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101da2:	f0 
f0101da3:	c7 44 24 04 ef 03 00 	movl   $0x3ef,0x4(%esp)
f0101daa:	00 
f0101dab:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101db2:	e8 89 e2 ff ff       	call   f0100040 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101db7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101dbe:	00 
f0101dbf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101dc6:	00 
f0101dc7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101dcb:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0101dd0:	89 04 24             	mov    %eax,(%esp)
f0101dd3:	e8 c4 f6 ff ff       	call   f010149c <page_insert>
f0101dd8:	85 c0                	test   %eax,%eax
f0101dda:	78 24                	js     f0101e00 <mem_init+0x85f>
f0101ddc:	c7 44 24 0c c4 73 10 	movl   $0xf01073c4,0xc(%esp)
f0101de3:	f0 
f0101de4:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101deb:	f0 
f0101dec:	c7 44 24 04 f2 03 00 	movl   $0x3f2,0x4(%esp)
f0101df3:	00 
f0101df4:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101dfb:	e8 40 e2 ff ff       	call   f0100040 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101e00:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e03:	89 04 24             	mov    %eax,(%esp)
f0101e06:	e8 5a f3 ff ff       	call   f0101165 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101e0b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e12:	00 
f0101e13:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e1a:	00 
f0101e1b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e1f:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0101e24:	89 04 24             	mov    %eax,(%esp)
f0101e27:	e8 70 f6 ff ff       	call   f010149c <page_insert>
f0101e2c:	85 c0                	test   %eax,%eax
f0101e2e:	74 24                	je     f0101e54 <mem_init+0x8b3>
f0101e30:	c7 44 24 0c f4 73 10 	movl   $0xf01073f4,0xc(%esp)
f0101e37:	f0 
f0101e38:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101e3f:	f0 
f0101e40:	c7 44 24 04 f6 03 00 	movl   $0x3f6,0x4(%esp)
f0101e47:	00 
f0101e48:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101e4f:	e8 ec e1 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e54:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e5a:	a1 90 ce 22 f0       	mov    0xf022ce90,%eax
f0101e5f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e62:	8b 17                	mov    (%edi),%edx
f0101e64:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e6a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e6d:	29 c1                	sub    %eax,%ecx
f0101e6f:	89 c8                	mov    %ecx,%eax
f0101e71:	c1 f8 03             	sar    $0x3,%eax
f0101e74:	c1 e0 0c             	shl    $0xc,%eax
f0101e77:	39 c2                	cmp    %eax,%edx
f0101e79:	74 24                	je     f0101e9f <mem_init+0x8fe>
f0101e7b:	c7 44 24 0c 24 74 10 	movl   $0xf0107424,0xc(%esp)
f0101e82:	f0 
f0101e83:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101e8a:	f0 
f0101e8b:	c7 44 24 04 f7 03 00 	movl   $0x3f7,0x4(%esp)
f0101e92:	00 
f0101e93:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101e9a:	e8 a1 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101e9f:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ea4:	89 f8                	mov    %edi,%eax
f0101ea6:	e8 f5 ec ff ff       	call   f0100ba0 <check_va2pa>
f0101eab:	89 da                	mov    %ebx,%edx
f0101ead:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101eb0:	c1 fa 03             	sar    $0x3,%edx
f0101eb3:	c1 e2 0c             	shl    $0xc,%edx
f0101eb6:	39 d0                	cmp    %edx,%eax
f0101eb8:	74 24                	je     f0101ede <mem_init+0x93d>
f0101eba:	c7 44 24 0c 4c 74 10 	movl   $0xf010744c,0xc(%esp)
f0101ec1:	f0 
f0101ec2:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101ec9:	f0 
f0101eca:	c7 44 24 04 f8 03 00 	movl   $0x3f8,0x4(%esp)
f0101ed1:	00 
f0101ed2:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101ed9:	e8 62 e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101ede:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ee3:	74 24                	je     f0101f09 <mem_init+0x968>
f0101ee5:	c7 44 24 0c ae 70 10 	movl   $0xf01070ae,0xc(%esp)
f0101eec:	f0 
f0101eed:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101ef4:	f0 
f0101ef5:	c7 44 24 04 f9 03 00 	movl   $0x3f9,0x4(%esp)
f0101efc:	00 
f0101efd:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101f04:	e8 37 e1 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101f09:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f0c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f11:	74 24                	je     f0101f37 <mem_init+0x996>
f0101f13:	c7 44 24 0c bf 70 10 	movl   $0xf01070bf,0xc(%esp)
f0101f1a:	f0 
f0101f1b:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101f22:	f0 
f0101f23:	c7 44 24 04 fa 03 00 	movl   $0x3fa,0x4(%esp)
f0101f2a:	00 
f0101f2b:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101f32:	e8 09 e1 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f37:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f3e:	00 
f0101f3f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f46:	00 
f0101f47:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f4b:	89 3c 24             	mov    %edi,(%esp)
f0101f4e:	e8 49 f5 ff ff       	call   f010149c <page_insert>
f0101f53:	85 c0                	test   %eax,%eax
f0101f55:	74 24                	je     f0101f7b <mem_init+0x9da>
f0101f57:	c7 44 24 0c 7c 74 10 	movl   $0xf010747c,0xc(%esp)
f0101f5e:	f0 
f0101f5f:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101f66:	f0 
f0101f67:	c7 44 24 04 fd 03 00 	movl   $0x3fd,0x4(%esp)
f0101f6e:	00 
f0101f6f:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101f76:	e8 c5 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f7b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f80:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0101f85:	e8 16 ec ff ff       	call   f0100ba0 <check_va2pa>
f0101f8a:	89 f2                	mov    %esi,%edx
f0101f8c:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f0101f92:	c1 fa 03             	sar    $0x3,%edx
f0101f95:	c1 e2 0c             	shl    $0xc,%edx
f0101f98:	39 d0                	cmp    %edx,%eax
f0101f9a:	74 24                	je     f0101fc0 <mem_init+0xa1f>
f0101f9c:	c7 44 24 0c b8 74 10 	movl   $0xf01074b8,0xc(%esp)
f0101fa3:	f0 
f0101fa4:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101fab:	f0 
f0101fac:	c7 44 24 04 fe 03 00 	movl   $0x3fe,0x4(%esp)
f0101fb3:	00 
f0101fb4:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101fbb:	e8 80 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101fc0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101fc5:	74 24                	je     f0101feb <mem_init+0xa4a>
f0101fc7:	c7 44 24 0c d0 70 10 	movl   $0xf01070d0,0xc(%esp)
f0101fce:	f0 
f0101fcf:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0101fd6:	f0 
f0101fd7:	c7 44 24 04 ff 03 00 	movl   $0x3ff,0x4(%esp)
f0101fde:	00 
f0101fdf:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0101fe6:	e8 55 e0 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101feb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ff2:	e8 e3 f0 ff ff       	call   f01010da <page_alloc>
f0101ff7:	85 c0                	test   %eax,%eax
f0101ff9:	74 24                	je     f010201f <mem_init+0xa7e>
f0101ffb:	c7 44 24 0c 5c 70 10 	movl   $0xf010705c,0xc(%esp)
f0102002:	f0 
f0102003:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010200a:	f0 
f010200b:	c7 44 24 04 02 04 00 	movl   $0x402,0x4(%esp)
f0102012:	00 
f0102013:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010201a:	e8 21 e0 ff ff       	call   f0100040 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010201f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102026:	00 
f0102027:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010202e:	00 
f010202f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102033:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102038:	89 04 24             	mov    %eax,(%esp)
f010203b:	e8 5c f4 ff ff       	call   f010149c <page_insert>
f0102040:	85 c0                	test   %eax,%eax
f0102042:	74 24                	je     f0102068 <mem_init+0xac7>
f0102044:	c7 44 24 0c 7c 74 10 	movl   $0xf010747c,0xc(%esp)
f010204b:	f0 
f010204c:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102053:	f0 
f0102054:	c7 44 24 04 05 04 00 	movl   $0x405,0x4(%esp)
f010205b:	00 
f010205c:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102063:	e8 d8 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102068:	ba 00 10 00 00       	mov    $0x1000,%edx
f010206d:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102072:	e8 29 eb ff ff       	call   f0100ba0 <check_va2pa>
f0102077:	89 f2                	mov    %esi,%edx
f0102079:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f010207f:	c1 fa 03             	sar    $0x3,%edx
f0102082:	c1 e2 0c             	shl    $0xc,%edx
f0102085:	39 d0                	cmp    %edx,%eax
f0102087:	74 24                	je     f01020ad <mem_init+0xb0c>
f0102089:	c7 44 24 0c b8 74 10 	movl   $0xf01074b8,0xc(%esp)
f0102090:	f0 
f0102091:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102098:	f0 
f0102099:	c7 44 24 04 06 04 00 	movl   $0x406,0x4(%esp)
f01020a0:	00 
f01020a1:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01020a8:	e8 93 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01020ad:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01020b2:	74 24                	je     f01020d8 <mem_init+0xb37>
f01020b4:	c7 44 24 0c d0 70 10 	movl   $0xf01070d0,0xc(%esp)
f01020bb:	f0 
f01020bc:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01020c3:	f0 
f01020c4:	c7 44 24 04 07 04 00 	movl   $0x407,0x4(%esp)
f01020cb:	00 
f01020cc:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01020d3:	e8 68 df ff ff       	call   f0100040 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01020d8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01020df:	e8 f6 ef ff ff       	call   f01010da <page_alloc>
f01020e4:	85 c0                	test   %eax,%eax
f01020e6:	74 24                	je     f010210c <mem_init+0xb6b>
f01020e8:	c7 44 24 0c 5c 70 10 	movl   $0xf010705c,0xc(%esp)
f01020ef:	f0 
f01020f0:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01020f7:	f0 
f01020f8:	c7 44 24 04 0b 04 00 	movl   $0x40b,0x4(%esp)
f01020ff:	00 
f0102100:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102107:	e8 34 df ff ff       	call   f0100040 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010210c:	8b 15 8c ce 22 f0    	mov    0xf022ce8c,%edx
f0102112:	8b 02                	mov    (%edx),%eax
f0102114:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102119:	89 c1                	mov    %eax,%ecx
f010211b:	c1 e9 0c             	shr    $0xc,%ecx
f010211e:	3b 0d 88 ce 22 f0    	cmp    0xf022ce88,%ecx
f0102124:	72 20                	jb     f0102146 <mem_init+0xba5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102126:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010212a:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0102131:	f0 
f0102132:	c7 44 24 04 0e 04 00 	movl   $0x40e,0x4(%esp)
f0102139:	00 
f010213a:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102141:	e8 fa de ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102146:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010214b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010214e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102155:	00 
f0102156:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010215d:	00 
f010215e:	89 14 24             	mov    %edx,(%esp)
f0102161:	e8 84 f0 ff ff       	call   f01011ea <pgdir_walk>
f0102166:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102169:	8d 51 04             	lea    0x4(%ecx),%edx
f010216c:	39 d0                	cmp    %edx,%eax
f010216e:	74 24                	je     f0102194 <mem_init+0xbf3>
f0102170:	c7 44 24 0c e8 74 10 	movl   $0xf01074e8,0xc(%esp)
f0102177:	f0 
f0102178:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010217f:	f0 
f0102180:	c7 44 24 04 0f 04 00 	movl   $0x40f,0x4(%esp)
f0102187:	00 
f0102188:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010218f:	e8 ac de ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102194:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010219b:	00 
f010219c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01021a3:	00 
f01021a4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01021a8:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01021ad:	89 04 24             	mov    %eax,(%esp)
f01021b0:	e8 e7 f2 ff ff       	call   f010149c <page_insert>
f01021b5:	85 c0                	test   %eax,%eax
f01021b7:	74 24                	je     f01021dd <mem_init+0xc3c>
f01021b9:	c7 44 24 0c 28 75 10 	movl   $0xf0107528,0xc(%esp)
f01021c0:	f0 
f01021c1:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01021c8:	f0 
f01021c9:	c7 44 24 04 12 04 00 	movl   $0x412,0x4(%esp)
f01021d0:	00 
f01021d1:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01021d8:	e8 63 de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01021dd:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
f01021e3:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021e8:	89 f8                	mov    %edi,%eax
f01021ea:	e8 b1 e9 ff ff       	call   f0100ba0 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01021ef:	89 f2                	mov    %esi,%edx
f01021f1:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f01021f7:	c1 fa 03             	sar    $0x3,%edx
f01021fa:	c1 e2 0c             	shl    $0xc,%edx
f01021fd:	39 d0                	cmp    %edx,%eax
f01021ff:	74 24                	je     f0102225 <mem_init+0xc84>
f0102201:	c7 44 24 0c b8 74 10 	movl   $0xf01074b8,0xc(%esp)
f0102208:	f0 
f0102209:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102210:	f0 
f0102211:	c7 44 24 04 13 04 00 	movl   $0x413,0x4(%esp)
f0102218:	00 
f0102219:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102220:	e8 1b de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102225:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010222a:	74 24                	je     f0102250 <mem_init+0xcaf>
f010222c:	c7 44 24 0c d0 70 10 	movl   $0xf01070d0,0xc(%esp)
f0102233:	f0 
f0102234:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010223b:	f0 
f010223c:	c7 44 24 04 14 04 00 	movl   $0x414,0x4(%esp)
f0102243:	00 
f0102244:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010224b:	e8 f0 dd ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102250:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102257:	00 
f0102258:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010225f:	00 
f0102260:	89 3c 24             	mov    %edi,(%esp)
f0102263:	e8 82 ef ff ff       	call   f01011ea <pgdir_walk>
f0102268:	f6 00 04             	testb  $0x4,(%eax)
f010226b:	75 24                	jne    f0102291 <mem_init+0xcf0>
f010226d:	c7 44 24 0c 68 75 10 	movl   $0xf0107568,0xc(%esp)
f0102274:	f0 
f0102275:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010227c:	f0 
f010227d:	c7 44 24 04 15 04 00 	movl   $0x415,0x4(%esp)
f0102284:	00 
f0102285:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010228c:	e8 af dd ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102291:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102296:	f6 00 04             	testb  $0x4,(%eax)
f0102299:	75 24                	jne    f01022bf <mem_init+0xd1e>
f010229b:	c7 44 24 0c e1 70 10 	movl   $0xf01070e1,0xc(%esp)
f01022a2:	f0 
f01022a3:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01022aa:	f0 
f01022ab:	c7 44 24 04 16 04 00 	movl   $0x416,0x4(%esp)
f01022b2:	00 
f01022b3:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01022ba:	e8 81 dd ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01022bf:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01022c6:	00 
f01022c7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01022ce:	00 
f01022cf:	89 74 24 04          	mov    %esi,0x4(%esp)
f01022d3:	89 04 24             	mov    %eax,(%esp)
f01022d6:	e8 c1 f1 ff ff       	call   f010149c <page_insert>
f01022db:	85 c0                	test   %eax,%eax
f01022dd:	74 24                	je     f0102303 <mem_init+0xd62>
f01022df:	c7 44 24 0c 7c 74 10 	movl   $0xf010747c,0xc(%esp)
f01022e6:	f0 
f01022e7:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01022ee:	f0 
f01022ef:	c7 44 24 04 19 04 00 	movl   $0x419,0x4(%esp)
f01022f6:	00 
f01022f7:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01022fe:	e8 3d dd ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102303:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010230a:	00 
f010230b:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102312:	00 
f0102313:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102318:	89 04 24             	mov    %eax,(%esp)
f010231b:	e8 ca ee ff ff       	call   f01011ea <pgdir_walk>
f0102320:	f6 00 02             	testb  $0x2,(%eax)
f0102323:	75 24                	jne    f0102349 <mem_init+0xda8>
f0102325:	c7 44 24 0c 9c 75 10 	movl   $0xf010759c,0xc(%esp)
f010232c:	f0 
f010232d:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102334:	f0 
f0102335:	c7 44 24 04 1a 04 00 	movl   $0x41a,0x4(%esp)
f010233c:	00 
f010233d:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102344:	e8 f7 dc ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102349:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102350:	00 
f0102351:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102358:	00 
f0102359:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f010235e:	89 04 24             	mov    %eax,(%esp)
f0102361:	e8 84 ee ff ff       	call   f01011ea <pgdir_walk>
f0102366:	f6 00 04             	testb  $0x4,(%eax)
f0102369:	74 24                	je     f010238f <mem_init+0xdee>
f010236b:	c7 44 24 0c d0 75 10 	movl   $0xf01075d0,0xc(%esp)
f0102372:	f0 
f0102373:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010237a:	f0 
f010237b:	c7 44 24 04 1b 04 00 	movl   $0x41b,0x4(%esp)
f0102382:	00 
f0102383:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010238a:	e8 b1 dc ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010238f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102396:	00 
f0102397:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f010239e:	00 
f010239f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023a2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01023a6:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01023ab:	89 04 24             	mov    %eax,(%esp)
f01023ae:	e8 e9 f0 ff ff       	call   f010149c <page_insert>
f01023b3:	85 c0                	test   %eax,%eax
f01023b5:	78 24                	js     f01023db <mem_init+0xe3a>
f01023b7:	c7 44 24 0c 08 76 10 	movl   $0xf0107608,0xc(%esp)
f01023be:	f0 
f01023bf:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01023c6:	f0 
f01023c7:	c7 44 24 04 1e 04 00 	movl   $0x41e,0x4(%esp)
f01023ce:	00 
f01023cf:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01023d6:	e8 65 dc ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01023db:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01023e2:	00 
f01023e3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01023ea:	00 
f01023eb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01023ef:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01023f4:	89 04 24             	mov    %eax,(%esp)
f01023f7:	e8 a0 f0 ff ff       	call   f010149c <page_insert>
f01023fc:	85 c0                	test   %eax,%eax
f01023fe:	74 24                	je     f0102424 <mem_init+0xe83>
f0102400:	c7 44 24 0c 40 76 10 	movl   $0xf0107640,0xc(%esp)
f0102407:	f0 
f0102408:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010240f:	f0 
f0102410:	c7 44 24 04 21 04 00 	movl   $0x421,0x4(%esp)
f0102417:	00 
f0102418:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010241f:	e8 1c dc ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102424:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010242b:	00 
f010242c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102433:	00 
f0102434:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102439:	89 04 24             	mov    %eax,(%esp)
f010243c:	e8 a9 ed ff ff       	call   f01011ea <pgdir_walk>
f0102441:	f6 00 04             	testb  $0x4,(%eax)
f0102444:	74 24                	je     f010246a <mem_init+0xec9>
f0102446:	c7 44 24 0c d0 75 10 	movl   $0xf01075d0,0xc(%esp)
f010244d:	f0 
f010244e:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102455:	f0 
f0102456:	c7 44 24 04 22 04 00 	movl   $0x422,0x4(%esp)
f010245d:	00 
f010245e:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102465:	e8 d6 db ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010246a:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
f0102470:	ba 00 00 00 00       	mov    $0x0,%edx
f0102475:	89 f8                	mov    %edi,%eax
f0102477:	e8 24 e7 ff ff       	call   f0100ba0 <check_va2pa>
f010247c:	89 c1                	mov    %eax,%ecx
f010247e:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102481:	89 d8                	mov    %ebx,%eax
f0102483:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0102489:	c1 f8 03             	sar    $0x3,%eax
f010248c:	c1 e0 0c             	shl    $0xc,%eax
f010248f:	39 c1                	cmp    %eax,%ecx
f0102491:	74 24                	je     f01024b7 <mem_init+0xf16>
f0102493:	c7 44 24 0c 7c 76 10 	movl   $0xf010767c,0xc(%esp)
f010249a:	f0 
f010249b:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01024a2:	f0 
f01024a3:	c7 44 24 04 25 04 00 	movl   $0x425,0x4(%esp)
f01024aa:	00 
f01024ab:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01024b2:	e8 89 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01024b7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01024bc:	89 f8                	mov    %edi,%eax
f01024be:	e8 dd e6 ff ff       	call   f0100ba0 <check_va2pa>
f01024c3:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01024c6:	74 24                	je     f01024ec <mem_init+0xf4b>
f01024c8:	c7 44 24 0c a8 76 10 	movl   $0xf01076a8,0xc(%esp)
f01024cf:	f0 
f01024d0:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01024d7:	f0 
f01024d8:	c7 44 24 04 26 04 00 	movl   $0x426,0x4(%esp)
f01024df:	00 
f01024e0:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01024e7:	e8 54 db ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01024ec:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01024f1:	74 24                	je     f0102517 <mem_init+0xf76>
f01024f3:	c7 44 24 0c f7 70 10 	movl   $0xf01070f7,0xc(%esp)
f01024fa:	f0 
f01024fb:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102502:	f0 
f0102503:	c7 44 24 04 28 04 00 	movl   $0x428,0x4(%esp)
f010250a:	00 
f010250b:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102512:	e8 29 db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102517:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010251c:	74 24                	je     f0102542 <mem_init+0xfa1>
f010251e:	c7 44 24 0c 08 71 10 	movl   $0xf0107108,0xc(%esp)
f0102525:	f0 
f0102526:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010252d:	f0 
f010252e:	c7 44 24 04 29 04 00 	movl   $0x429,0x4(%esp)
f0102535:	00 
f0102536:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010253d:	e8 fe da ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102542:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102549:	e8 8c eb ff ff       	call   f01010da <page_alloc>
f010254e:	85 c0                	test   %eax,%eax
f0102550:	74 04                	je     f0102556 <mem_init+0xfb5>
f0102552:	39 c6                	cmp    %eax,%esi
f0102554:	74 24                	je     f010257a <mem_init+0xfd9>
f0102556:	c7 44 24 0c d8 76 10 	movl   $0xf01076d8,0xc(%esp)
f010255d:	f0 
f010255e:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102565:	f0 
f0102566:	c7 44 24 04 2c 04 00 	movl   $0x42c,0x4(%esp)
f010256d:	00 
f010256e:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102575:	e8 c6 da ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010257a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102581:	00 
f0102582:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102587:	89 04 24             	mov    %eax,(%esp)
f010258a:	e8 bd ee ff ff       	call   f010144c <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010258f:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
f0102595:	ba 00 00 00 00       	mov    $0x0,%edx
f010259a:	89 f8                	mov    %edi,%eax
f010259c:	e8 ff e5 ff ff       	call   f0100ba0 <check_va2pa>
f01025a1:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025a4:	74 24                	je     f01025ca <mem_init+0x1029>
f01025a6:	c7 44 24 0c fc 76 10 	movl   $0xf01076fc,0xc(%esp)
f01025ad:	f0 
f01025ae:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01025b5:	f0 
f01025b6:	c7 44 24 04 30 04 00 	movl   $0x430,0x4(%esp)
f01025bd:	00 
f01025be:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01025c5:	e8 76 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01025ca:	ba 00 10 00 00       	mov    $0x1000,%edx
f01025cf:	89 f8                	mov    %edi,%eax
f01025d1:	e8 ca e5 ff ff       	call   f0100ba0 <check_va2pa>
f01025d6:	89 da                	mov    %ebx,%edx
f01025d8:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f01025de:	c1 fa 03             	sar    $0x3,%edx
f01025e1:	c1 e2 0c             	shl    $0xc,%edx
f01025e4:	39 d0                	cmp    %edx,%eax
f01025e6:	74 24                	je     f010260c <mem_init+0x106b>
f01025e8:	c7 44 24 0c a8 76 10 	movl   $0xf01076a8,0xc(%esp)
f01025ef:	f0 
f01025f0:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01025f7:	f0 
f01025f8:	c7 44 24 04 31 04 00 	movl   $0x431,0x4(%esp)
f01025ff:	00 
f0102600:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102607:	e8 34 da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f010260c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102611:	74 24                	je     f0102637 <mem_init+0x1096>
f0102613:	c7 44 24 0c ae 70 10 	movl   $0xf01070ae,0xc(%esp)
f010261a:	f0 
f010261b:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102622:	f0 
f0102623:	c7 44 24 04 32 04 00 	movl   $0x432,0x4(%esp)
f010262a:	00 
f010262b:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102632:	e8 09 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102637:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010263c:	74 24                	je     f0102662 <mem_init+0x10c1>
f010263e:	c7 44 24 0c 08 71 10 	movl   $0xf0107108,0xc(%esp)
f0102645:	f0 
f0102646:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010264d:	f0 
f010264e:	c7 44 24 04 33 04 00 	movl   $0x433,0x4(%esp)
f0102655:	00 
f0102656:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010265d:	e8 de d9 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102662:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102669:	00 
f010266a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102671:	00 
f0102672:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102676:	89 3c 24             	mov    %edi,(%esp)
f0102679:	e8 1e ee ff ff       	call   f010149c <page_insert>
f010267e:	85 c0                	test   %eax,%eax
f0102680:	74 24                	je     f01026a6 <mem_init+0x1105>
f0102682:	c7 44 24 0c 20 77 10 	movl   $0xf0107720,0xc(%esp)
f0102689:	f0 
f010268a:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102691:	f0 
f0102692:	c7 44 24 04 36 04 00 	movl   $0x436,0x4(%esp)
f0102699:	00 
f010269a:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01026a1:	e8 9a d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f01026a6:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01026ab:	75 24                	jne    f01026d1 <mem_init+0x1130>
f01026ad:	c7 44 24 0c 19 71 10 	movl   $0xf0107119,0xc(%esp)
f01026b4:	f0 
f01026b5:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01026bc:	f0 
f01026bd:	c7 44 24 04 37 04 00 	movl   $0x437,0x4(%esp)
f01026c4:	00 
f01026c5:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01026cc:	e8 6f d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f01026d1:	83 3b 00             	cmpl   $0x0,(%ebx)
f01026d4:	74 24                	je     f01026fa <mem_init+0x1159>
f01026d6:	c7 44 24 0c 25 71 10 	movl   $0xf0107125,0xc(%esp)
f01026dd:	f0 
f01026de:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01026e5:	f0 
f01026e6:	c7 44 24 04 38 04 00 	movl   $0x438,0x4(%esp)
f01026ed:	00 
f01026ee:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01026f5:	e8 46 d9 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01026fa:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102701:	00 
f0102702:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102707:	89 04 24             	mov    %eax,(%esp)
f010270a:	e8 3d ed ff ff       	call   f010144c <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010270f:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
f0102715:	ba 00 00 00 00       	mov    $0x0,%edx
f010271a:	89 f8                	mov    %edi,%eax
f010271c:	e8 7f e4 ff ff       	call   f0100ba0 <check_va2pa>
f0102721:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102724:	74 24                	je     f010274a <mem_init+0x11a9>
f0102726:	c7 44 24 0c fc 76 10 	movl   $0xf01076fc,0xc(%esp)
f010272d:	f0 
f010272e:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102735:	f0 
f0102736:	c7 44 24 04 3c 04 00 	movl   $0x43c,0x4(%esp)
f010273d:	00 
f010273e:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102745:	e8 f6 d8 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010274a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010274f:	89 f8                	mov    %edi,%eax
f0102751:	e8 4a e4 ff ff       	call   f0100ba0 <check_va2pa>
f0102756:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102759:	74 24                	je     f010277f <mem_init+0x11de>
f010275b:	c7 44 24 0c 58 77 10 	movl   $0xf0107758,0xc(%esp)
f0102762:	f0 
f0102763:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010276a:	f0 
f010276b:	c7 44 24 04 3d 04 00 	movl   $0x43d,0x4(%esp)
f0102772:	00 
f0102773:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010277a:	e8 c1 d8 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f010277f:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102784:	74 24                	je     f01027aa <mem_init+0x1209>
f0102786:	c7 44 24 0c 3a 71 10 	movl   $0xf010713a,0xc(%esp)
f010278d:	f0 
f010278e:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102795:	f0 
f0102796:	c7 44 24 04 3e 04 00 	movl   $0x43e,0x4(%esp)
f010279d:	00 
f010279e:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01027a5:	e8 96 d8 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01027aa:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01027af:	74 24                	je     f01027d5 <mem_init+0x1234>
f01027b1:	c7 44 24 0c 08 71 10 	movl   $0xf0107108,0xc(%esp)
f01027b8:	f0 
f01027b9:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01027c0:	f0 
f01027c1:	c7 44 24 04 3f 04 00 	movl   $0x43f,0x4(%esp)
f01027c8:	00 
f01027c9:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01027d0:	e8 6b d8 ff ff       	call   f0100040 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01027d5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027dc:	e8 f9 e8 ff ff       	call   f01010da <page_alloc>
f01027e1:	85 c0                	test   %eax,%eax
f01027e3:	74 04                	je     f01027e9 <mem_init+0x1248>
f01027e5:	39 c3                	cmp    %eax,%ebx
f01027e7:	74 24                	je     f010280d <mem_init+0x126c>
f01027e9:	c7 44 24 0c 80 77 10 	movl   $0xf0107780,0xc(%esp)
f01027f0:	f0 
f01027f1:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01027f8:	f0 
f01027f9:	c7 44 24 04 42 04 00 	movl   $0x442,0x4(%esp)
f0102800:	00 
f0102801:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102808:	e8 33 d8 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010280d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102814:	e8 c1 e8 ff ff       	call   f01010da <page_alloc>
f0102819:	85 c0                	test   %eax,%eax
f010281b:	74 24                	je     f0102841 <mem_init+0x12a0>
f010281d:	c7 44 24 0c 5c 70 10 	movl   $0xf010705c,0xc(%esp)
f0102824:	f0 
f0102825:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010282c:	f0 
f010282d:	c7 44 24 04 45 04 00 	movl   $0x445,0x4(%esp)
f0102834:	00 
f0102835:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010283c:	e8 ff d7 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102841:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102846:	8b 08                	mov    (%eax),%ecx
f0102848:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010284e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102851:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f0102857:	c1 fa 03             	sar    $0x3,%edx
f010285a:	c1 e2 0c             	shl    $0xc,%edx
f010285d:	39 d1                	cmp    %edx,%ecx
f010285f:	74 24                	je     f0102885 <mem_init+0x12e4>
f0102861:	c7 44 24 0c 24 74 10 	movl   $0xf0107424,0xc(%esp)
f0102868:	f0 
f0102869:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102870:	f0 
f0102871:	c7 44 24 04 48 04 00 	movl   $0x448,0x4(%esp)
f0102878:	00 
f0102879:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102880:	e8 bb d7 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102885:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010288b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010288e:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102893:	74 24                	je     f01028b9 <mem_init+0x1318>
f0102895:	c7 44 24 0c bf 70 10 	movl   $0xf01070bf,0xc(%esp)
f010289c:	f0 
f010289d:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01028a4:	f0 
f01028a5:	c7 44 24 04 4a 04 00 	movl   $0x44a,0x4(%esp)
f01028ac:	00 
f01028ad:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01028b4:	e8 87 d7 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01028b9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01028bc:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01028c2:	89 04 24             	mov    %eax,(%esp)
f01028c5:	e8 9b e8 ff ff       	call   f0101165 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01028ca:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01028d1:	00 
f01028d2:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01028d9:	00 
f01028da:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01028df:	89 04 24             	mov    %eax,(%esp)
f01028e2:	e8 03 e9 ff ff       	call   f01011ea <pgdir_walk>
f01028e7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01028ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01028ed:	8b 15 8c ce 22 f0    	mov    0xf022ce8c,%edx
f01028f3:	8b 7a 04             	mov    0x4(%edx),%edi
f01028f6:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01028fc:	8b 0d 88 ce 22 f0    	mov    0xf022ce88,%ecx
f0102902:	89 f8                	mov    %edi,%eax
f0102904:	c1 e8 0c             	shr    $0xc,%eax
f0102907:	39 c8                	cmp    %ecx,%eax
f0102909:	72 20                	jb     f010292b <mem_init+0x138a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010290b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010290f:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0102916:	f0 
f0102917:	c7 44 24 04 51 04 00 	movl   $0x451,0x4(%esp)
f010291e:	00 
f010291f:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102926:	e8 15 d7 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010292b:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102931:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102934:	74 24                	je     f010295a <mem_init+0x13b9>
f0102936:	c7 44 24 0c 4b 71 10 	movl   $0xf010714b,0xc(%esp)
f010293d:	f0 
f010293e:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102945:	f0 
f0102946:	c7 44 24 04 52 04 00 	movl   $0x452,0x4(%esp)
f010294d:	00 
f010294e:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102955:	e8 e6 d6 ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010295a:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102961:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102964:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010296a:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0102970:	c1 f8 03             	sar    $0x3,%eax
f0102973:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102976:	89 c2                	mov    %eax,%edx
f0102978:	c1 ea 0c             	shr    $0xc,%edx
f010297b:	39 d1                	cmp    %edx,%ecx
f010297d:	77 20                	ja     f010299f <mem_init+0x13fe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010297f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102983:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f010298a:	f0 
f010298b:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0102992:	00 
f0102993:	c7 04 24 ab 6e 10 f0 	movl   $0xf0106eab,(%esp)
f010299a:	e8 a1 d6 ff ff       	call   f0100040 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f010299f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029a6:	00 
f01029a7:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01029ae:	00 
	return (void *)(pa + KERNBASE);
f01029af:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029b4:	89 04 24             	mov    %eax,(%esp)
f01029b7:	e8 cb 31 00 00       	call   f0105b87 <memset>
	page_free(pp0);
f01029bc:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01029bf:	89 3c 24             	mov    %edi,(%esp)
f01029c2:	e8 9e e7 ff ff       	call   f0101165 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01029c7:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01029ce:	00 
f01029cf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01029d6:	00 
f01029d7:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01029dc:	89 04 24             	mov    %eax,(%esp)
f01029df:	e8 06 e8 ff ff       	call   f01011ea <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029e4:	89 fa                	mov    %edi,%edx
f01029e6:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f01029ec:	c1 fa 03             	sar    $0x3,%edx
f01029ef:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029f2:	89 d0                	mov    %edx,%eax
f01029f4:	c1 e8 0c             	shr    $0xc,%eax
f01029f7:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f01029fd:	72 20                	jb     f0102a1f <mem_init+0x147e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029ff:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102a03:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0102a0a:	f0 
f0102a0b:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0102a12:	00 
f0102a13:	c7 04 24 ab 6e 10 f0 	movl   $0xf0106eab,(%esp)
f0102a1a:	e8 21 d6 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102a1f:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102a25:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102a28:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102a2e:	f6 00 01             	testb  $0x1,(%eax)
f0102a31:	74 24                	je     f0102a57 <mem_init+0x14b6>
f0102a33:	c7 44 24 0c 63 71 10 	movl   $0xf0107163,0xc(%esp)
f0102a3a:	f0 
f0102a3b:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102a42:	f0 
f0102a43:	c7 44 24 04 5c 04 00 	movl   $0x45c,0x4(%esp)
f0102a4a:	00 
f0102a4b:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102a52:	e8 e9 d5 ff ff       	call   f0100040 <_panic>
f0102a57:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102a5a:	39 d0                	cmp    %edx,%eax
f0102a5c:	75 d0                	jne    f0102a2e <mem_init+0x148d>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102a5e:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102a63:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102a69:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a6c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102a72:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102a75:	89 0d 40 c2 22 f0    	mov    %ecx,0xf022c240

	// free the pages we took
	page_free(pp0);
f0102a7b:	89 04 24             	mov    %eax,(%esp)
f0102a7e:	e8 e2 e6 ff ff       	call   f0101165 <page_free>
	page_free(pp1);
f0102a83:	89 1c 24             	mov    %ebx,(%esp)
f0102a86:	e8 da e6 ff ff       	call   f0101165 <page_free>
	page_free(pp2);
f0102a8b:	89 34 24             	mov    %esi,(%esp)
f0102a8e:	e8 d2 e6 ff ff       	call   f0101165 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102a93:	c7 44 24 04 01 10 00 	movl   $0x1001,0x4(%esp)
f0102a9a:	00 
f0102a9b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102aa2:	e8 8b ea ff ff       	call   f0101532 <mmio_map_region>
f0102aa7:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102aa9:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102ab0:	00 
f0102ab1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ab8:	e8 75 ea ff ff       	call   f0101532 <mmio_map_region>
f0102abd:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f0102abf:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f0102ac5:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102aca:	77 08                	ja     f0102ad4 <mem_init+0x1533>
f0102acc:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102ad2:	77 24                	ja     f0102af8 <mem_init+0x1557>
f0102ad4:	c7 44 24 0c a4 77 10 	movl   $0xf01077a4,0xc(%esp)
f0102adb:	f0 
f0102adc:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102ae3:	f0 
f0102ae4:	c7 44 24 04 6c 04 00 	movl   $0x46c,0x4(%esp)
f0102aeb:	00 
f0102aec:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102af3:	e8 48 d5 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102af8:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f0102afe:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102b04:	77 08                	ja     f0102b0e <mem_init+0x156d>
f0102b06:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102b0c:	77 24                	ja     f0102b32 <mem_init+0x1591>
f0102b0e:	c7 44 24 0c cc 77 10 	movl   $0xf01077cc,0xc(%esp)
f0102b15:	f0 
f0102b16:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102b1d:	f0 
f0102b1e:	c7 44 24 04 6d 04 00 	movl   $0x46d,0x4(%esp)
f0102b25:	00 
f0102b26:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102b2d:	e8 0e d5 ff ff       	call   f0100040 <_panic>
f0102b32:	89 da                	mov    %ebx,%edx
f0102b34:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102b36:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102b3c:	74 24                	je     f0102b62 <mem_init+0x15c1>
f0102b3e:	c7 44 24 0c f4 77 10 	movl   $0xf01077f4,0xc(%esp)
f0102b45:	f0 
f0102b46:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102b4d:	f0 
f0102b4e:	c7 44 24 04 6f 04 00 	movl   $0x46f,0x4(%esp)
f0102b55:	00 
f0102b56:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102b5d:	e8 de d4 ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f0102b62:	39 c6                	cmp    %eax,%esi
f0102b64:	73 24                	jae    f0102b8a <mem_init+0x15e9>
f0102b66:	c7 44 24 0c 7a 71 10 	movl   $0xf010717a,0xc(%esp)
f0102b6d:	f0 
f0102b6e:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102b75:	f0 
f0102b76:	c7 44 24 04 71 04 00 	movl   $0x471,0x4(%esp)
f0102b7d:	00 
f0102b7e:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102b85:	e8 b6 d4 ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102b8a:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi
f0102b90:	89 da                	mov    %ebx,%edx
f0102b92:	89 f8                	mov    %edi,%eax
f0102b94:	e8 07 e0 ff ff       	call   f0100ba0 <check_va2pa>
f0102b99:	85 c0                	test   %eax,%eax
f0102b9b:	74 24                	je     f0102bc1 <mem_init+0x1620>
f0102b9d:	c7 44 24 0c 1c 78 10 	movl   $0xf010781c,0xc(%esp)
f0102ba4:	f0 
f0102ba5:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102bac:	f0 
f0102bad:	c7 44 24 04 73 04 00 	movl   $0x473,0x4(%esp)
f0102bb4:	00 
f0102bb5:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102bbc:	e8 7f d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102bc1:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102bc7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102bca:	89 c2                	mov    %eax,%edx
f0102bcc:	89 f8                	mov    %edi,%eax
f0102bce:	e8 cd df ff ff       	call   f0100ba0 <check_va2pa>
f0102bd3:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102bd8:	74 24                	je     f0102bfe <mem_init+0x165d>
f0102bda:	c7 44 24 0c 40 78 10 	movl   $0xf0107840,0xc(%esp)
f0102be1:	f0 
f0102be2:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102be9:	f0 
f0102bea:	c7 44 24 04 74 04 00 	movl   $0x474,0x4(%esp)
f0102bf1:	00 
f0102bf2:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102bf9:	e8 42 d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102bfe:	89 f2                	mov    %esi,%edx
f0102c00:	89 f8                	mov    %edi,%eax
f0102c02:	e8 99 df ff ff       	call   f0100ba0 <check_va2pa>
f0102c07:	85 c0                	test   %eax,%eax
f0102c09:	74 24                	je     f0102c2f <mem_init+0x168e>
f0102c0b:	c7 44 24 0c 70 78 10 	movl   $0xf0107870,0xc(%esp)
f0102c12:	f0 
f0102c13:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102c1a:	f0 
f0102c1b:	c7 44 24 04 75 04 00 	movl   $0x475,0x4(%esp)
f0102c22:	00 
f0102c23:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102c2a:	e8 11 d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102c2f:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102c35:	89 f8                	mov    %edi,%eax
f0102c37:	e8 64 df ff ff       	call   f0100ba0 <check_va2pa>
f0102c3c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102c3f:	74 24                	je     f0102c65 <mem_init+0x16c4>
f0102c41:	c7 44 24 0c 94 78 10 	movl   $0xf0107894,0xc(%esp)
f0102c48:	f0 
f0102c49:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102c50:	f0 
f0102c51:	c7 44 24 04 76 04 00 	movl   $0x476,0x4(%esp)
f0102c58:	00 
f0102c59:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102c60:	e8 db d3 ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102c65:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102c6c:	00 
f0102c6d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102c71:	89 3c 24             	mov    %edi,(%esp)
f0102c74:	e8 71 e5 ff ff       	call   f01011ea <pgdir_walk>
f0102c79:	f6 00 1a             	testb  $0x1a,(%eax)
f0102c7c:	75 24                	jne    f0102ca2 <mem_init+0x1701>
f0102c7e:	c7 44 24 0c c0 78 10 	movl   $0xf01078c0,0xc(%esp)
f0102c85:	f0 
f0102c86:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102c8d:	f0 
f0102c8e:	c7 44 24 04 78 04 00 	movl   $0x478,0x4(%esp)
f0102c95:	00 
f0102c96:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102c9d:	e8 9e d3 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102ca2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102ca9:	00 
f0102caa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102cae:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102cb3:	89 04 24             	mov    %eax,(%esp)
f0102cb6:	e8 2f e5 ff ff       	call   f01011ea <pgdir_walk>
f0102cbb:	f6 00 04             	testb  $0x4,(%eax)
f0102cbe:	74 24                	je     f0102ce4 <mem_init+0x1743>
f0102cc0:	c7 44 24 0c 04 79 10 	movl   $0xf0107904,0xc(%esp)
f0102cc7:	f0 
f0102cc8:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102ccf:	f0 
f0102cd0:	c7 44 24 04 79 04 00 	movl   $0x479,0x4(%esp)
f0102cd7:	00 
f0102cd8:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102cdf:	e8 5c d3 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102ce4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102ceb:	00 
f0102cec:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102cf0:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102cf5:	89 04 24             	mov    %eax,(%esp)
f0102cf8:	e8 ed e4 ff ff       	call   f01011ea <pgdir_walk>
f0102cfd:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102d03:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102d0a:	00 
f0102d0b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d0e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d12:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102d17:	89 04 24             	mov    %eax,(%esp)
f0102d1a:	e8 cb e4 ff ff       	call   f01011ea <pgdir_walk>
f0102d1f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102d25:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102d2c:	00 
f0102d2d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102d31:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102d36:	89 04 24             	mov    %eax,(%esp)
f0102d39:	e8 ac e4 ff ff       	call   f01011ea <pgdir_walk>
f0102d3e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102d44:	c7 04 24 8c 71 10 f0 	movl   $0xf010718c,(%esp)
f0102d4b:	e8 1e 13 00 00       	call   f010406e <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE), PADDR(pages), PTE_U | PTE_P);
f0102d50:	a1 90 ce 22 f0       	mov    0xf022ce90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d55:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d5a:	77 20                	ja     f0102d7c <mem_init+0x17db>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d5c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d60:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f0102d67:	f0 
f0102d68:	c7 44 24 04 cb 00 00 	movl   $0xcb,0x4(%esp)
f0102d6f:	00 
f0102d70:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102d77:	e8 c4 d2 ff ff       	call   f0100040 <_panic>
f0102d7c:	8b 15 88 ce 22 f0    	mov    0xf022ce88,%edx
f0102d82:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102d89:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102d8f:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102d96:	00 
	return (physaddr_t)kva - KERNBASE;
f0102d97:	05 00 00 00 10       	add    $0x10000000,%eax
f0102d9c:	89 04 24             	mov    %eax,(%esp)
f0102d9f:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102da4:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102da9:	e8 56 e5 ff ff       	call   f0101304 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, ROUNDUP(NENV * sizeof(struct Env), PGSIZE), PADDR(envs), PTE_U | PTE_P);
f0102dae:	a1 48 c2 22 f0       	mov    0xf022c248,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102db3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102db8:	77 20                	ja     f0102dda <mem_init+0x1839>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102dba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102dbe:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f0102dc5:	f0 
f0102dc6:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
f0102dcd:	00 
f0102dce:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102dd5:	e8 66 d2 ff ff       	call   f0100040 <_panic>
f0102dda:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102de1:	00 
	return (physaddr_t)kva - KERNBASE;
f0102de2:	05 00 00 00 10       	add    $0x10000000,%eax
f0102de7:	89 04 24             	mov    %eax,(%esp)
f0102dea:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f0102def:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102df4:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102df9:	e8 06 e5 ff ff       	call   f0101304 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102dfe:	b8 00 70 11 f0       	mov    $0xf0117000,%eax
f0102e03:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e08:	77 20                	ja     f0102e2a <mem_init+0x1889>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e0a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102e0e:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f0102e15:	f0 
f0102e16:	c7 44 24 04 e1 00 00 	movl   $0xe1,0x4(%esp)
f0102e1d:	00 
f0102e1e:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102e25:	e8 16 d2 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P); 
f0102e2a:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102e31:	00 
f0102e32:	c7 04 24 00 70 11 00 	movl   $0x117000,(%esp)
f0102e39:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102e3e:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102e43:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102e48:	e8 b7 e4 ff ff       	call   f0101304 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	uint64_t kern_map_length = 0x100000000 - (uint64_t) KERNBASE;
	boot_map_region(kern_pgdir, KERNBASE, (uint32_t) kern_map_length, 0, PTE_W|PTE_P);
f0102e4d:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102e54:	00 
f0102e55:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e5c:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102e61:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102e66:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102e6b:	e8 94 e4 ff ff       	call   f0101304 <boot_map_region>
f0102e70:	bf 00 e0 26 f0       	mov    $0xf026e000,%edi
f0102e75:	bb 00 e0 22 f0       	mov    $0xf022e000,%ebx
f0102e7a:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e7f:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102e85:	77 20                	ja     f0102ea7 <mem_init+0x1906>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e87:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102e8b:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f0102e92:	f0 
f0102e93:	c7 44 24 04 22 01 00 	movl   $0x122,0x4(%esp)
f0102e9a:	00 
f0102e9b:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102ea2:	e8 99 d1 ff ff       	call   f0100040 <_panic>
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	uint32_t i = 0;
	for ( ; i < NCPU; i++) {
		boot_map_region(kern_pgdir, KSTACKTOP - i * (KSTKSIZE + KSTKGAP) - KSTKSIZE, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W | PTE_P);
f0102ea7:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102eae:	00 
f0102eaf:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0102eb5:	89 04 24             	mov    %eax,(%esp)
f0102eb8:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102ebd:	89 f2                	mov    %esi,%edx
f0102ebf:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0102ec4:	e8 3b e4 ff ff       	call   f0101304 <boot_map_region>
f0102ec9:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102ecf:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:
	uint32_t i = 0;
	for ( ; i < NCPU; i++) {
f0102ed5:	39 fb                	cmp    %edi,%ebx
f0102ed7:	75 a6                	jne    f0102e7f <mem_init+0x18de>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102ed9:	8b 3d 8c ce 22 f0    	mov    0xf022ce8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102edf:	a1 88 ce 22 f0       	mov    0xf022ce88,%eax
f0102ee4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102ee7:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102eee:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102ef3:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102ef6:	8b 35 90 ce 22 f0    	mov    0xf022ce90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102efc:	89 75 cc             	mov    %esi,-0x34(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102eff:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0102f05:	89 45 c8             	mov    %eax,-0x38(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102f08:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102f0d:	eb 6a                	jmp    f0102f79 <mem_init+0x19d8>
f0102f0f:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102f15:	89 f8                	mov    %edi,%eax
f0102f17:	e8 84 dc ff ff       	call   f0100ba0 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f1c:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102f23:	77 20                	ja     f0102f45 <mem_init+0x19a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f25:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102f29:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f0102f30:	f0 
f0102f31:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f0102f38:	00 
f0102f39:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102f40:	e8 fb d0 ff ff       	call   f0100040 <_panic>
f0102f45:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102f48:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f0102f4b:	39 d0                	cmp    %edx,%eax
f0102f4d:	74 24                	je     f0102f73 <mem_init+0x19d2>
f0102f4f:	c7 44 24 0c 38 79 10 	movl   $0xf0107938,0xc(%esp)
f0102f56:	f0 
f0102f57:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102f5e:	f0 
f0102f5f:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f0102f66:	00 
f0102f67:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102f6e:	e8 cd d0 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102f73:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102f79:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102f7c:	77 91                	ja     f0102f0f <mem_init+0x196e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102f7e:	8b 1d 48 c2 22 f0    	mov    0xf022c248,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f84:	89 de                	mov    %ebx,%esi
f0102f86:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102f8b:	89 f8                	mov    %edi,%eax
f0102f8d:	e8 0e dc ff ff       	call   f0100ba0 <check_va2pa>
f0102f92:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102f98:	77 20                	ja     f0102fba <mem_init+0x1a19>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f9a:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102f9e:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f0102fa5:	f0 
f0102fa6:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0102fad:	00 
f0102fae:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102fb5:	e8 86 d0 ff ff       	call   f0100040 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102fba:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102fbf:	81 c6 00 00 40 21    	add    $0x21400000,%esi
f0102fc5:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f0102fc8:	39 d0                	cmp    %edx,%eax
f0102fca:	74 24                	je     f0102ff0 <mem_init+0x1a4f>
f0102fcc:	c7 44 24 0c 6c 79 10 	movl   $0xf010796c,0xc(%esp)
f0102fd3:	f0 
f0102fd4:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0102fdb:	f0 
f0102fdc:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0102fe3:	00 
f0102fe4:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0102feb:	e8 50 d0 ff ff       	call   f0100040 <_panic>
f0102ff0:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102ff6:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102ffc:	0f 85 a8 05 00 00    	jne    f01035aa <mem_init+0x2009>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0103002:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0103005:	c1 e6 0c             	shl    $0xc,%esi
f0103008:	bb 00 00 00 00       	mov    $0x0,%ebx
f010300d:	eb 3b                	jmp    f010304a <mem_init+0x1aa9>
f010300f:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0103015:	89 f8                	mov    %edi,%eax
f0103017:	e8 84 db ff ff       	call   f0100ba0 <check_va2pa>
f010301c:	39 c3                	cmp    %eax,%ebx
f010301e:	74 24                	je     f0103044 <mem_init+0x1aa3>
f0103020:	c7 44 24 0c a0 79 10 	movl   $0xf01079a0,0xc(%esp)
f0103027:	f0 
f0103028:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010302f:	f0 
f0103030:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0103037:	00 
f0103038:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010303f:	e8 fc cf ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0103044:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010304a:	39 f3                	cmp    %esi,%ebx
f010304c:	72 c1                	jb     f010300f <mem_init+0x1a6e>
f010304e:	c7 45 d0 00 e0 22 f0 	movl   $0xf022e000,-0x30(%ebp)
f0103055:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f010305c:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0103061:	b8 00 e0 22 f0       	mov    $0xf022e000,%eax
f0103066:	05 00 80 00 20       	add    $0x20008000,%eax
f010306b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f010306e:	8d 86 00 80 00 00    	lea    0x8000(%esi),%eax
f0103074:	89 45 cc             	mov    %eax,-0x34(%ebp)
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0103077:	89 f2                	mov    %esi,%edx
f0103079:	89 f8                	mov    %edi,%eax
f010307b:	e8 20 db ff ff       	call   f0100ba0 <check_va2pa>
f0103080:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103083:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f0103089:	77 20                	ja     f01030ab <mem_init+0x1b0a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010308b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010308f:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f0103096:	f0 
f0103097:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f010309e:	00 
f010309f:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01030a6:	e8 95 cf ff ff       	call   f0100040 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030ab:	89 f3                	mov    %esi,%ebx
f01030ad:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01030b0:	03 4d d4             	add    -0x2c(%ebp),%ecx
f01030b3:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f01030b6:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01030b9:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
f01030bc:	39 c2                	cmp    %eax,%edx
f01030be:	74 24                	je     f01030e4 <mem_init+0x1b43>
f01030c0:	c7 44 24 0c c8 79 10 	movl   $0xf01079c8,0xc(%esp)
f01030c7:	f0 
f01030c8:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01030cf:	f0 
f01030d0:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f01030d7:	00 
f01030d8:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01030df:	e8 5c cf ff ff       	call   f0100040 <_panic>
f01030e4:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01030ea:	3b 5d cc             	cmp    -0x34(%ebp),%ebx
f01030ed:	0f 85 a9 04 00 00    	jne    f010359c <mem_init+0x1ffb>
f01030f3:	8d 9e 00 80 ff ff    	lea    -0x8000(%esi),%ebx
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01030f9:	89 da                	mov    %ebx,%edx
f01030fb:	89 f8                	mov    %edi,%eax
f01030fd:	e8 9e da ff ff       	call   f0100ba0 <check_va2pa>
f0103102:	83 f8 ff             	cmp    $0xffffffff,%eax
f0103105:	74 24                	je     f010312b <mem_init+0x1b8a>
f0103107:	c7 44 24 0c 10 7a 10 	movl   $0xf0107a10,0xc(%esp)
f010310e:	f0 
f010310f:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0103116:	f0 
f0103117:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f010311e:	00 
f010311f:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0103126:	e8 15 cf ff ff       	call   f0100040 <_panic>
f010312b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0103131:	39 de                	cmp    %ebx,%esi
f0103133:	75 c4                	jne    f01030f9 <mem_init+0x1b58>
f0103135:	81 ee 00 00 01 00    	sub    $0x10000,%esi
f010313b:	81 45 d4 00 80 01 00 	addl   $0x18000,-0x2c(%ebp)
f0103142:	81 45 d0 00 80 00 00 	addl   $0x8000,-0x30(%ebp)
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0103149:	81 fe 00 80 f7 ef    	cmp    $0xeff78000,%esi
f010314f:	0f 85 19 ff ff ff    	jne    f010306e <mem_init+0x1acd>
f0103155:	b8 00 00 00 00       	mov    $0x0,%eax
f010315a:	e9 c2 00 00 00       	jmp    f0103221 <mem_init+0x1c80>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f010315f:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0103165:	83 fa 04             	cmp    $0x4,%edx
f0103168:	77 2e                	ja     f0103198 <mem_init+0x1bf7>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f010316a:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f010316e:	0f 85 aa 00 00 00    	jne    f010321e <mem_init+0x1c7d>
f0103174:	c7 44 24 0c a5 71 10 	movl   $0xf01071a5,0xc(%esp)
f010317b:	f0 
f010317c:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0103183:	f0 
f0103184:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f010318b:	00 
f010318c:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0103193:	e8 a8 ce ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0103198:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010319d:	76 55                	jbe    f01031f4 <mem_init+0x1c53>
				assert(pgdir[i] & PTE_P);
f010319f:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01031a2:	f6 c2 01             	test   $0x1,%dl
f01031a5:	75 24                	jne    f01031cb <mem_init+0x1c2a>
f01031a7:	c7 44 24 0c a5 71 10 	movl   $0xf01071a5,0xc(%esp)
f01031ae:	f0 
f01031af:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01031b6:	f0 
f01031b7:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f01031be:	00 
f01031bf:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01031c6:	e8 75 ce ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f01031cb:	f6 c2 02             	test   $0x2,%dl
f01031ce:	75 4e                	jne    f010321e <mem_init+0x1c7d>
f01031d0:	c7 44 24 0c b6 71 10 	movl   $0xf01071b6,0xc(%esp)
f01031d7:	f0 
f01031d8:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01031df:	f0 
f01031e0:	c7 44 24 04 b4 03 00 	movl   $0x3b4,0x4(%esp)
f01031e7:	00 
f01031e8:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01031ef:	e8 4c ce ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f01031f4:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f01031f8:	74 24                	je     f010321e <mem_init+0x1c7d>
f01031fa:	c7 44 24 0c c7 71 10 	movl   $0xf01071c7,0xc(%esp)
f0103201:	f0 
f0103202:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0103209:	f0 
f010320a:	c7 44 24 04 b6 03 00 	movl   $0x3b6,0x4(%esp)
f0103211:	00 
f0103212:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0103219:	e8 22 ce ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010321e:	83 c0 01             	add    $0x1,%eax
f0103221:	3d 00 04 00 00       	cmp    $0x400,%eax
f0103226:	0f 85 33 ff ff ff    	jne    f010315f <mem_init+0x1bbe>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f010322c:	c7 04 24 34 7a 10 f0 	movl   $0xf0107a34,(%esp)
f0103233:	e8 36 0e 00 00       	call   f010406e <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0103238:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f010323d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103242:	77 20                	ja     f0103264 <mem_init+0x1cc3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103244:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103248:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f010324f:	f0 
f0103250:	c7 44 24 04 fb 00 00 	movl   $0xfb,0x4(%esp)
f0103257:	00 
f0103258:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010325f:	e8 dc cd ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103264:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103269:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010326c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103271:	e8 99 d9 ff ff       	call   f0100c0f <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0103276:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0103279:	83 e0 f3             	and    $0xfffffff3,%eax
f010327c:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0103281:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0103284:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010328b:	e8 4a de ff ff       	call   f01010da <page_alloc>
f0103290:	89 c3                	mov    %eax,%ebx
f0103292:	85 c0                	test   %eax,%eax
f0103294:	75 24                	jne    f01032ba <mem_init+0x1d19>
f0103296:	c7 44 24 0c b1 6f 10 	movl   $0xf0106fb1,0xc(%esp)
f010329d:	f0 
f010329e:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01032a5:	f0 
f01032a6:	c7 44 24 04 8e 04 00 	movl   $0x48e,0x4(%esp)
f01032ad:	00 
f01032ae:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01032b5:	e8 86 cd ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01032ba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01032c1:	e8 14 de ff ff       	call   f01010da <page_alloc>
f01032c6:	89 c7                	mov    %eax,%edi
f01032c8:	85 c0                	test   %eax,%eax
f01032ca:	75 24                	jne    f01032f0 <mem_init+0x1d4f>
f01032cc:	c7 44 24 0c c7 6f 10 	movl   $0xf0106fc7,0xc(%esp)
f01032d3:	f0 
f01032d4:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01032db:	f0 
f01032dc:	c7 44 24 04 8f 04 00 	movl   $0x48f,0x4(%esp)
f01032e3:	00 
f01032e4:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01032eb:	e8 50 cd ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01032f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01032f7:	e8 de dd ff ff       	call   f01010da <page_alloc>
f01032fc:	89 c6                	mov    %eax,%esi
f01032fe:	85 c0                	test   %eax,%eax
f0103300:	75 24                	jne    f0103326 <mem_init+0x1d85>
f0103302:	c7 44 24 0c dd 6f 10 	movl   $0xf0106fdd,0xc(%esp)
f0103309:	f0 
f010330a:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0103311:	f0 
f0103312:	c7 44 24 04 90 04 00 	movl   $0x490,0x4(%esp)
f0103319:	00 
f010331a:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0103321:	e8 1a cd ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0103326:	89 1c 24             	mov    %ebx,(%esp)
f0103329:	e8 37 de ff ff       	call   f0101165 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f010332e:	89 f8                	mov    %edi,%eax
f0103330:	e8 26 d8 ff ff       	call   f0100b5b <page2kva>
f0103335:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010333c:	00 
f010333d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0103344:	00 
f0103345:	89 04 24             	mov    %eax,(%esp)
f0103348:	e8 3a 28 00 00       	call   f0105b87 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f010334d:	89 f0                	mov    %esi,%eax
f010334f:	e8 07 d8 ff ff       	call   f0100b5b <page2kva>
f0103354:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010335b:	00 
f010335c:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0103363:	00 
f0103364:	89 04 24             	mov    %eax,(%esp)
f0103367:	e8 1b 28 00 00       	call   f0105b87 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f010336c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103373:	00 
f0103374:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010337b:	00 
f010337c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103380:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0103385:	89 04 24             	mov    %eax,(%esp)
f0103388:	e8 0f e1 ff ff       	call   f010149c <page_insert>
	assert(pp1->pp_ref == 1);
f010338d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0103392:	74 24                	je     f01033b8 <mem_init+0x1e17>
f0103394:	c7 44 24 0c ae 70 10 	movl   $0xf01070ae,0xc(%esp)
f010339b:	f0 
f010339c:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01033a3:	f0 
f01033a4:	c7 44 24 04 95 04 00 	movl   $0x495,0x4(%esp)
f01033ab:	00 
f01033ac:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01033b3:	e8 88 cc ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01033b8:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01033bf:	01 01 01 
f01033c2:	74 24                	je     f01033e8 <mem_init+0x1e47>
f01033c4:	c7 44 24 0c 54 7a 10 	movl   $0xf0107a54,0xc(%esp)
f01033cb:	f0 
f01033cc:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01033d3:	f0 
f01033d4:	c7 44 24 04 96 04 00 	movl   $0x496,0x4(%esp)
f01033db:	00 
f01033dc:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01033e3:	e8 58 cc ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f01033e8:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01033ef:	00 
f01033f0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01033f7:	00 
f01033f8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01033fc:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0103401:	89 04 24             	mov    %eax,(%esp)
f0103404:	e8 93 e0 ff ff       	call   f010149c <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103409:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0103410:	02 02 02 
f0103413:	74 24                	je     f0103439 <mem_init+0x1e98>
f0103415:	c7 44 24 0c 78 7a 10 	movl   $0xf0107a78,0xc(%esp)
f010341c:	f0 
f010341d:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0103424:	f0 
f0103425:	c7 44 24 04 98 04 00 	movl   $0x498,0x4(%esp)
f010342c:	00 
f010342d:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0103434:	e8 07 cc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0103439:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010343e:	74 24                	je     f0103464 <mem_init+0x1ec3>
f0103440:	c7 44 24 0c d0 70 10 	movl   $0xf01070d0,0xc(%esp)
f0103447:	f0 
f0103448:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010344f:	f0 
f0103450:	c7 44 24 04 99 04 00 	movl   $0x499,0x4(%esp)
f0103457:	00 
f0103458:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010345f:	e8 dc cb ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0103464:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0103469:	74 24                	je     f010348f <mem_init+0x1eee>
f010346b:	c7 44 24 0c 3a 71 10 	movl   $0xf010713a,0xc(%esp)
f0103472:	f0 
f0103473:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010347a:	f0 
f010347b:	c7 44 24 04 9a 04 00 	movl   $0x49a,0x4(%esp)
f0103482:	00 
f0103483:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010348a:	e8 b1 cb ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f010348f:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0103496:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0103499:	89 f0                	mov    %esi,%eax
f010349b:	e8 bb d6 ff ff       	call   f0100b5b <page2kva>
f01034a0:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f01034a6:	74 24                	je     f01034cc <mem_init+0x1f2b>
f01034a8:	c7 44 24 0c 9c 7a 10 	movl   $0xf0107a9c,0xc(%esp)
f01034af:	f0 
f01034b0:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01034b7:	f0 
f01034b8:	c7 44 24 04 9c 04 00 	movl   $0x49c,0x4(%esp)
f01034bf:	00 
f01034c0:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f01034c7:	e8 74 cb ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01034cc:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01034d3:	00 
f01034d4:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f01034d9:	89 04 24             	mov    %eax,(%esp)
f01034dc:	e8 6b df ff ff       	call   f010144c <page_remove>
	assert(pp2->pp_ref == 0);
f01034e1:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01034e6:	74 24                	je     f010350c <mem_init+0x1f6b>
f01034e8:	c7 44 24 0c 08 71 10 	movl   $0xf0107108,0xc(%esp)
f01034ef:	f0 
f01034f0:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f01034f7:	f0 
f01034f8:	c7 44 24 04 9e 04 00 	movl   $0x49e,0x4(%esp)
f01034ff:	00 
f0103500:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0103507:	e8 34 cb ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010350c:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
f0103511:	8b 08                	mov    (%eax),%ecx
f0103513:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0103519:	89 da                	mov    %ebx,%edx
f010351b:	2b 15 90 ce 22 f0    	sub    0xf022ce90,%edx
f0103521:	c1 fa 03             	sar    $0x3,%edx
f0103524:	c1 e2 0c             	shl    $0xc,%edx
f0103527:	39 d1                	cmp    %edx,%ecx
f0103529:	74 24                	je     f010354f <mem_init+0x1fae>
f010352b:	c7 44 24 0c 24 74 10 	movl   $0xf0107424,0xc(%esp)
f0103532:	f0 
f0103533:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010353a:	f0 
f010353b:	c7 44 24 04 a1 04 00 	movl   $0x4a1,0x4(%esp)
f0103542:	00 
f0103543:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010354a:	e8 f1 ca ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f010354f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0103555:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010355a:	74 24                	je     f0103580 <mem_init+0x1fdf>
f010355c:	c7 44 24 0c bf 70 10 	movl   $0xf01070bf,0xc(%esp)
f0103563:	f0 
f0103564:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f010356b:	f0 
f010356c:	c7 44 24 04 a3 04 00 	movl   $0x4a3,0x4(%esp)
f0103573:	00 
f0103574:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f010357b:	e8 c0 ca ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0103580:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0103586:	89 1c 24             	mov    %ebx,(%esp)
f0103589:	e8 d7 db ff ff       	call   f0101165 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010358e:	c7 04 24 c8 7a 10 f0 	movl   $0xf0107ac8,(%esp)
f0103595:	e8 d4 0a 00 00       	call   f010406e <cprintf>
f010359a:	eb 1c                	jmp    f01035b8 <mem_init+0x2017>
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f010359c:	89 da                	mov    %ebx,%edx
f010359e:	89 f8                	mov    %edi,%eax
f01035a0:	e8 fb d5 ff ff       	call   f0100ba0 <check_va2pa>
f01035a5:	e9 0c fb ff ff       	jmp    f01030b6 <mem_init+0x1b15>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01035aa:	89 da                	mov    %ebx,%edx
f01035ac:	89 f8                	mov    %edi,%eax
f01035ae:	e8 ed d5 ff ff       	call   f0100ba0 <check_va2pa>
f01035b3:	e9 0d fa ff ff       	jmp    f0102fc5 <mem_init+0x1a24>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01035b8:	83 c4 4c             	add    $0x4c,%esp
f01035bb:	5b                   	pop    %ebx
f01035bc:	5e                   	pop    %esi
f01035bd:	5f                   	pop    %edi
f01035be:	5d                   	pop    %ebp
f01035bf:	c3                   	ret    

f01035c0 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01035c0:	55                   	push   %ebp
f01035c1:	89 e5                	mov    %esp,%ebp
f01035c3:	57                   	push   %edi
f01035c4:	56                   	push   %esi
f01035c5:	53                   	push   %ebx
f01035c6:	83 ec 1c             	sub    $0x1c,%esp
f01035c9:	8b 7d 08             	mov    0x8(%ebp),%edi
f01035cc:	8b 45 0c             	mov    0xc(%ebp),%eax
	// LAB 3: Your code here.
	
	//uint32_t ia = ROUNDDOWN((uint32_t) va, PGSIZE);
	//uint32_t ialen = ROUNDDOWN((uint32_t) va + len, PGSIZE);
	uint32_t ia = (uint32_t) va;
	perm |= PTE_P;
f01035cf:	8b 75 14             	mov    0x14(%ebp),%esi
f01035d2:	83 ce 01             	or     $0x1,%esi
{
	// LAB 3: Your code here.
	
	//uint32_t ia = ROUNDDOWN((uint32_t) va, PGSIZE);
	//uint32_t ialen = ROUNDDOWN((uint32_t) va + len, PGSIZE);
	uint32_t ia = (uint32_t) va;
f01035d5:	89 c3                	mov    %eax,%ebx
	perm |= PTE_P;

	for ( ; ia < (uint32_t) va + len; ia++){
f01035d7:	03 45 10             	add    0x10(%ebp),%eax
f01035da:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01035dd:	eb 55                	jmp    f0103634 <user_mem_check+0x74>
	//for ( ; ia < ialen; ia++){
		if (ia > ULIM){
f01035df:	81 fb 00 00 80 ef    	cmp    $0xef800000,%ebx
f01035e5:	76 0d                	jbe    f01035f4 <user_mem_check+0x34>
			user_mem_check_addr = ia;
f01035e7:	89 1d 3c c2 22 f0    	mov    %ebx,0xf022c23c
			return -E_FAULT;
f01035ed:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01035f2:	eb 4a                	jmp    f010363e <user_mem_check+0x7e>
		}
		pte_t * p = pgdir_walk(env->env_pgdir, (void *) ia, 0);
f01035f4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01035fb:	00 
f01035fc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103600:	8b 47 60             	mov    0x60(%edi),%eax
f0103603:	89 04 24             	mov    %eax,(%esp)
f0103606:	e8 df db ff ff       	call   f01011ea <pgdir_walk>
		//check if it's null
		if (!p) {
f010360b:	85 c0                	test   %eax,%eax
f010360d:	75 0d                	jne    f010361c <user_mem_check+0x5c>
			user_mem_check_addr = ia;
f010360f:	89 1d 3c c2 22 f0    	mov    %ebx,0xf022c23c
			return -E_FAULT;
f0103615:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010361a:	eb 22                	jmp    f010363e <user_mem_check+0x7e>
		}
		//check the permission bits
		if ((*p & perm) != perm) {
f010361c:	89 f2                	mov    %esi,%edx
f010361e:	23 10                	and    (%eax),%edx
f0103620:	39 d6                	cmp    %edx,%esi
f0103622:	74 0d                	je     f0103631 <user_mem_check+0x71>
			user_mem_check_addr = ia;
f0103624:	89 1d 3c c2 22 f0    	mov    %ebx,0xf022c23c
			return -E_FAULT;
f010362a:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010362f:	eb 0d                	jmp    f010363e <user_mem_check+0x7e>
	//uint32_t ia = ROUNDDOWN((uint32_t) va, PGSIZE);
	//uint32_t ialen = ROUNDDOWN((uint32_t) va + len, PGSIZE);
	uint32_t ia = (uint32_t) va;
	perm |= PTE_P;

	for ( ; ia < (uint32_t) va + len; ia++){
f0103631:	83 c3 01             	add    $0x1,%ebx
f0103634:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0103637:	72 a6                	jb     f01035df <user_mem_check+0x1f>
			user_mem_check_addr = ia;
			return -E_FAULT;
		}
	}

	return 0;
f0103639:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010363e:	83 c4 1c             	add    $0x1c,%esp
f0103641:	5b                   	pop    %ebx
f0103642:	5e                   	pop    %esi
f0103643:	5f                   	pop    %edi
f0103644:	5d                   	pop    %ebp
f0103645:	c3                   	ret    

f0103646 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0103646:	55                   	push   %ebp
f0103647:	89 e5                	mov    %esp,%ebp
f0103649:	53                   	push   %ebx
f010364a:	83 ec 14             	sub    $0x14,%esp
f010364d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0103650:	8b 45 14             	mov    0x14(%ebp),%eax
f0103653:	83 c8 04             	or     $0x4,%eax
f0103656:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010365a:	8b 45 10             	mov    0x10(%ebp),%eax
f010365d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103661:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103664:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103668:	89 1c 24             	mov    %ebx,(%esp)
f010366b:	e8 50 ff ff ff       	call   f01035c0 <user_mem_check>
f0103670:	85 c0                	test   %eax,%eax
f0103672:	79 24                	jns    f0103698 <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f0103674:	a1 3c c2 22 f0       	mov    0xf022c23c,%eax
f0103679:	89 44 24 08          	mov    %eax,0x8(%esp)
f010367d:	8b 43 48             	mov    0x48(%ebx),%eax
f0103680:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103684:	c7 04 24 f4 7a 10 f0 	movl   $0xf0107af4,(%esp)
f010368b:	e8 de 09 00 00       	call   f010406e <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0103690:	89 1c 24             	mov    %ebx,(%esp)
f0103693:	e8 f0 06 00 00       	call   f0103d88 <env_destroy>
	}
}
f0103698:	83 c4 14             	add    $0x14,%esp
f010369b:	5b                   	pop    %ebx
f010369c:	5d                   	pop    %ebp
f010369d:	c3                   	ret    
f010369e:	66 90                	xchg   %ax,%ax

f01036a0 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01036a0:	55                   	push   %ebp
f01036a1:	89 e5                	mov    %esp,%ebp
f01036a3:	57                   	push   %edi
f01036a4:	56                   	push   %esi
f01036a5:	53                   	push   %ebx
f01036a6:	83 ec 1c             	sub    $0x1c,%esp
f01036a9:	89 c7                	mov    %eax,%edi
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)

	uint32_t begin = ROUNDDOWN((uint32_t) va, PGSIZE);
f01036ab:	89 d3                	mov    %edx,%ebx
f01036ad:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uint32_t end = ROUNDUP((uint32_t) va + len, PGSIZE);
f01036b3:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01036ba:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo *p;

	uint32_t i;
	for (i = begin; i < end; i++){
f01036c0:	eb 4a                	jmp    f010370c <region_alloc+0x6c>
		if (!(p = page_alloc(0)))
f01036c2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01036c9:	e8 0c da ff ff       	call   f01010da <page_alloc>
f01036ce:	85 c0                	test   %eax,%eax
f01036d0:	75 1c                	jne    f01036ee <region_alloc+0x4e>
			panic("region_alloc(): allocation failure");
f01036d2:	c7 44 24 08 2c 7b 10 	movl   $0xf0107b2c,0x8(%esp)
f01036d9:	f0 
f01036da:	c7 44 24 04 49 01 00 	movl   $0x149,0x4(%esp)
f01036e1:	00 
f01036e2:	c7 04 24 75 7b 10 f0 	movl   $0xf0107b75,(%esp)
f01036e9:	e8 52 c9 ff ff       	call   f0100040 <_panic>

		page_insert(e->env_pgdir, p, (void *) i, PTE_U | PTE_W);
f01036ee:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01036f5:	00 
f01036f6:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01036fa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036fe:	8b 47 60             	mov    0x60(%edi),%eax
f0103701:	89 04 24             	mov    %eax,(%esp)
f0103704:	e8 93 dd ff ff       	call   f010149c <page_insert>
	uint32_t begin = ROUNDDOWN((uint32_t) va, PGSIZE);
	uint32_t end = ROUNDUP((uint32_t) va + len, PGSIZE);
	struct PageInfo *p;

	uint32_t i;
	for (i = begin; i < end; i++){
f0103709:	83 c3 01             	add    $0x1,%ebx
f010370c:	39 f3                	cmp    %esi,%ebx
f010370e:	72 b2                	jb     f01036c2 <region_alloc+0x22>
		if (!(p = page_alloc(0)))
			panic("region_alloc(): allocation failure");

		page_insert(e->env_pgdir, p, (void *) i, PTE_U | PTE_W);
	}
}
f0103710:	83 c4 1c             	add    $0x1c,%esp
f0103713:	5b                   	pop    %ebx
f0103714:	5e                   	pop    %esi
f0103715:	5f                   	pop    %edi
f0103716:	5d                   	pop    %ebp
f0103717:	c3                   	ret    

f0103718 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0103718:	55                   	push   %ebp
f0103719:	89 e5                	mov    %esp,%ebp
f010371b:	56                   	push   %esi
f010371c:	53                   	push   %ebx
f010371d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103720:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0103723:	85 c0                	test   %eax,%eax
f0103725:	75 1a                	jne    f0103741 <envid2env+0x29>
		*env_store = curenv;
f0103727:	e8 ad 2a 00 00       	call   f01061d9 <cpunum>
f010372c:	6b c0 74             	imul   $0x74,%eax,%eax
f010372f:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103735:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103738:	89 01                	mov    %eax,(%ecx)
		return 0;
f010373a:	b8 00 00 00 00       	mov    $0x0,%eax
f010373f:	eb 70                	jmp    f01037b1 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103741:	89 c3                	mov    %eax,%ebx
f0103743:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0103749:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f010374c:	03 1d 48 c2 22 f0    	add    0xf022c248,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103752:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0103756:	74 05                	je     f010375d <envid2env+0x45>
f0103758:	39 43 48             	cmp    %eax,0x48(%ebx)
f010375b:	74 10                	je     f010376d <envid2env+0x55>
		*env_store = 0;
f010375d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103760:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103766:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010376b:	eb 44                	jmp    f01037b1 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010376d:	84 d2                	test   %dl,%dl
f010376f:	74 36                	je     f01037a7 <envid2env+0x8f>
f0103771:	e8 63 2a 00 00       	call   f01061d9 <cpunum>
f0103776:	6b c0 74             	imul   $0x74,%eax,%eax
f0103779:	39 98 28 d0 22 f0    	cmp    %ebx,-0xfdd2fd8(%eax)
f010377f:	74 26                	je     f01037a7 <envid2env+0x8f>
f0103781:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103784:	e8 50 2a 00 00       	call   f01061d9 <cpunum>
f0103789:	6b c0 74             	imul   $0x74,%eax,%eax
f010378c:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103792:	3b 70 48             	cmp    0x48(%eax),%esi
f0103795:	74 10                	je     f01037a7 <envid2env+0x8f>
		*env_store = 0;
f0103797:	8b 45 0c             	mov    0xc(%ebp),%eax
f010379a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01037a0:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01037a5:	eb 0a                	jmp    f01037b1 <envid2env+0x99>
	}

	*env_store = e;
f01037a7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01037aa:	89 18                	mov    %ebx,(%eax)
	return 0;
f01037ac:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01037b1:	5b                   	pop    %ebx
f01037b2:	5e                   	pop    %esi
f01037b3:	5d                   	pop    %ebp
f01037b4:	c3                   	ret    

f01037b5 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01037b5:	55                   	push   %ebp
f01037b6:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f01037b8:	b8 20 13 12 f0       	mov    $0xf0121320,%eax
f01037bd:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01037c0:	b8 23 00 00 00       	mov    $0x23,%eax
f01037c5:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01037c7:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01037c9:	b0 10                	mov    $0x10,%al
f01037cb:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01037cd:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01037cf:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01037d1:	ea d8 37 10 f0 08 00 	ljmp   $0x8,$0xf01037d8
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f01037d8:	b0 00                	mov    $0x0,%al
f01037da:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01037dd:	5d                   	pop    %ebp
f01037de:	c3                   	ret    

f01037df <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01037df:	55                   	push   %ebp
f01037e0:	89 e5                	mov    %esp,%ebp
f01037e2:	53                   	push   %ebx
	}*/


	int i;
	for(i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
f01037e3:	8b 1d 48 c2 22 f0    	mov    0xf022c248,%ebx
f01037e9:	8b 0d 4c c2 22 f0    	mov    0xf022c24c,%ecx
f01037ef:	89 d8                	mov    %ebx,%eax
		env_free_list = &envs[i];
	}*/


	int i;
	for(i = 0; i < NENV; i++) {
f01037f1:	ba 00 00 00 00       	mov    $0x0,%edx
		envs[i].env_id = 0;
f01037f6:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_parent_id = 0;
f01037fd:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
		envs[i].env_status = 0;
f0103804:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_runs = 0;
f010380b:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)
		envs[i].env_pgdir = NULL;
f0103812:	c7 40 60 00 00 00 00 	movl   $0x0,0x60(%eax)

		if (i == 0)
f0103819:	85 d2                	test   %edx,%edx
f010381b:	74 1e                	je     f010383b <env_init+0x5c>
			env_free_list = &envs[0];
		else
			envs[i-1].env_link = &envs[i];
f010381d:	89 40 c8             	mov    %eax,-0x38(%eax)
		env_free_list = &envs[i];
	}*/


	int i;
	for(i = 0; i < NENV; i++) {
f0103820:	83 c2 01             	add    $0x1,%edx
f0103823:	83 c0 7c             	add    $0x7c,%eax
f0103826:	81 fa 00 04 00 00    	cmp    $0x400,%edx
f010382c:	75 c8                	jne    f01037f6 <env_init+0x17>
f010382e:	89 0d 4c c2 22 f0    	mov    %ecx,0xf022c24c
	}


	//cprintf("DEBUG free list %d\n", env_free_list);
	// Per-CPU part of the initialization
	env_init_percpu();
f0103834:	e8 7c ff ff ff       	call   f01037b5 <env_init_percpu>
f0103839:	eb 0a                	jmp    f0103845 <env_init+0x66>
		env_free_list = &envs[i];
	}*/


	int i;
	for(i = 0; i < NENV; i++) {
f010383b:	83 c2 01             	add    $0x1,%edx
f010383e:	83 c0 7c             	add    $0x7c,%eax
		envs[i].env_status = 0;
		envs[i].env_runs = 0;
		envs[i].env_pgdir = NULL;

		if (i == 0)
			env_free_list = &envs[0];
f0103841:	89 d9                	mov    %ebx,%ecx
f0103843:	eb b1                	jmp    f01037f6 <env_init+0x17>


	//cprintf("DEBUG free list %d\n", env_free_list);
	// Per-CPU part of the initialization
	env_init_percpu();
}
f0103845:	5b                   	pop    %ebx
f0103846:	5d                   	pop    %ebp
f0103847:	c3                   	ret    

f0103848 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103848:	55                   	push   %ebp
f0103849:	89 e5                	mov    %esp,%ebp
f010384b:	53                   	push   %ebx
f010384c:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list)) {
f010384f:	8b 1d 4c c2 22 f0    	mov    0xf022c24c,%ebx
f0103855:	85 db                	test   %ebx,%ebx
f0103857:	75 1e                	jne    f0103877 <env_alloc+0x2f>
		cprintf("DEBUG first break %d\n", -E_NO_FREE_ENV);
f0103859:	c7 44 24 04 fb ff ff 	movl   $0xfffffffb,0x4(%esp)
f0103860:	ff 
f0103861:	c7 04 24 80 7b 10 f0 	movl   $0xf0107b80,(%esp)
f0103868:	e8 01 08 00 00       	call   f010406e <cprintf>
		return -E_NO_FREE_ENV;
f010386d:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103872:	e9 a4 01 00 00       	jmp    f0103a1b <env_alloc+0x1d3>
	//cprintf("DEBUG env_setup_vm() called\n");
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103877:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010387e:	e8 57 d8 ff ff       	call   f01010da <page_alloc>
f0103883:	85 c0                	test   %eax,%eax
f0103885:	0f 84 77 01 00 00    	je     f0103a02 <env_alloc+0x1ba>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f010388b:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f0103890:	2b 05 90 ce 22 f0    	sub    0xf022ce90,%eax
f0103896:	c1 f8 03             	sar    $0x3,%eax
f0103899:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010389c:	89 c2                	mov    %eax,%edx
f010389e:	c1 ea 0c             	shr    $0xc,%edx
f01038a1:	3b 15 88 ce 22 f0    	cmp    0xf022ce88,%edx
f01038a7:	72 20                	jb     f01038c9 <env_alloc+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01038a9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01038ad:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f01038b4:	f0 
f01038b5:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01038bc:	00 
f01038bd:	c7 04 24 ab 6e 10 f0 	movl   $0xf0106eab,(%esp)
f01038c4:	e8 77 c7 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01038c9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01038ce:	89 43 60             	mov    %eax,0x60(%ebx)
	e->env_pgdir = page2kva(p);
f01038d1:	b8 ec 0e 00 00       	mov    $0xeec,%eax

	for (i = PDX(UTOP); i < NPDENTRIES; i++) {
		e->env_pgdir[i] = kern_pgdir[i];
f01038d6:	8b 15 8c ce 22 f0    	mov    0xf022ce8c,%edx
f01038dc:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f01038df:	8b 53 60             	mov    0x60(%ebx),%edx
f01038e2:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f01038e5:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = page2kva(p);

	for (i = PDX(UTOP); i < NPDENTRIES; i++) {
f01038e8:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01038ed:	75 e7                	jne    f01038d6 <env_alloc+0x8e>
		e->env_pgdir[i] = kern_pgdir[i];
	}

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01038ef:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01038f2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01038f7:	77 20                	ja     f0103919 <env_alloc+0xd1>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01038f9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01038fd:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f0103904:	f0 
f0103905:	c7 44 24 04 de 00 00 	movl   $0xde,0x4(%esp)
f010390c:	00 
f010390d:	c7 04 24 75 7b 10 f0 	movl   $0xf0107b75,(%esp)
f0103914:	e8 27 c7 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103919:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010391f:	83 ca 05             	or     $0x5,%edx
f0103922:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
		cprintf("DEBUG second break %d\n", r);
		return r;
	}

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103928:	8b 43 48             	mov    0x48(%ebx),%eax
f010392b:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103930:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103935:	ba 00 10 00 00       	mov    $0x1000,%edx
f010393a:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010393d:	89 da                	mov    %ebx,%edx
f010393f:	2b 15 48 c2 22 f0    	sub    0xf022c248,%edx
f0103945:	c1 fa 02             	sar    $0x2,%edx
f0103948:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f010394e:	09 d0                	or     %edx,%eax
f0103950:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103953:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103956:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103959:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103960:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103967:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010396e:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103975:	00 
f0103976:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010397d:	00 
f010397e:	89 1c 24             	mov    %ebx,(%esp)
f0103981:	e8 01 22 00 00       	call   f0105b87 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103986:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f010398c:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103992:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103998:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010399f:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f01039a5:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f01039ac:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f01039b0:	8b 43 44             	mov    0x44(%ebx),%eax
f01039b3:	a3 4c c2 22 f0       	mov    %eax,0xf022c24c
	*newenv_store = e;
f01039b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01039bb:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01039bd:	8b 5b 48             	mov    0x48(%ebx),%ebx
f01039c0:	e8 14 28 00 00       	call   f01061d9 <cpunum>
f01039c5:	6b d0 74             	imul   $0x74,%eax,%edx
f01039c8:	b8 00 00 00 00       	mov    $0x0,%eax
f01039cd:	83 ba 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%edx)
f01039d4:	74 11                	je     f01039e7 <env_alloc+0x19f>
f01039d6:	e8 fe 27 00 00       	call   f01061d9 <cpunum>
f01039db:	6b c0 74             	imul   $0x74,%eax,%eax
f01039de:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01039e4:	8b 40 48             	mov    0x48(%eax),%eax
f01039e7:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01039eb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039ef:	c7 04 24 96 7b 10 f0 	movl   $0xf0107b96,(%esp)
f01039f6:	e8 73 06 00 00       	call   f010406e <cprintf>
	return 0;
f01039fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a00:	eb 19                	jmp    f0103a1b <env_alloc+0x1d3>
		return -E_NO_FREE_ENV;
	}

	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0) {
		cprintf("DEBUG second break %d\n", r);
f0103a02:	c7 44 24 04 fc ff ff 	movl   $0xfffffffc,0x4(%esp)
f0103a09:	ff 
f0103a0a:	c7 04 24 ab 7b 10 f0 	movl   $0xf0107bab,(%esp)
f0103a11:	e8 58 06 00 00       	call   f010406e <cprintf>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103a16:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103a1b:	83 c4 14             	add    $0x14,%esp
f0103a1e:	5b                   	pop    %ebx
f0103a1f:	5d                   	pop    %ebp
f0103a20:	c3                   	ret    

f0103a21 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103a21:	55                   	push   %ebp
f0103a22:	89 e5                	mov    %esp,%ebp
f0103a24:	57                   	push   %edi
f0103a25:	56                   	push   %esi
f0103a26:	53                   	push   %ebx
f0103a27:	83 ec 3c             	sub    $0x3c,%esp
f0103a2a:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	//cprintf("DEBUG env_create() called\n");
	struct Env * new_env;

	int result = env_alloc(&new_env, 0);
f0103a2d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103a34:	00 
f0103a35:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103a38:	89 04 24             	mov    %eax,(%esp)
f0103a3b:	e8 08 fe ff ff       	call   f0103848 <env_alloc>
	//cprintf("DEBUG result %d\n", result);
	if (result != 0)
f0103a40:	85 c0                	test   %eax,%eax
f0103a42:	74 1c                	je     f0103a60 <env_create+0x3f>
		panic("env_create(): env allocation failure");
f0103a44:	c7 44 24 08 50 7b 10 	movl   $0xf0107b50,0x8(%esp)
f0103a4b:	f0 
f0103a4c:	c7 44 24 04 ca 01 00 	movl   $0x1ca,0x4(%esp)
f0103a53:	00 
f0103a54:	c7 04 24 75 7b 10 f0 	movl   $0xf0107b75,(%esp)
f0103a5b:	e8 e0 c5 ff ff       	call   f0100040 <_panic>
		//cprintf("env_create(): env allocation failure\n");

	load_icode(new_env, binary);
f0103a60:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a63:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// read 1st page off disk
	//readseg((uint32_t) ELFHDR, SECTSIZE*8, 0);

	// is this a valid ELF?
	if (elf->e_magic != ELF_MAGIC)
f0103a66:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103a6c:	74 1c                	je     f0103a8a <env_create+0x69>
		panic("load_icode(): elf failure");
f0103a6e:	c7 44 24 08 c2 7b 10 	movl   $0xf0107bc2,0x8(%esp)
f0103a75:	f0 
f0103a76:	c7 44 24 04 91 01 00 	movl   $0x191,0x4(%esp)
f0103a7d:	00 
f0103a7e:	c7 04 24 75 7b 10 f0 	movl   $0xf0107b75,(%esp)
f0103a85:	e8 b6 c5 ff ff       	call   f0100040 <_panic>

	// load each program segment (ignores ph flags)
	//struct PageInfo *page_alloc(int alloc_flags)

	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
f0103a8a:	89 fb                	mov    %edi,%ebx
f0103a8c:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f0103a8f:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103a93:	c1 e6 05             	shl    $0x5,%esi
f0103a96:	01 de                	add    %ebx,%esi

	lcr3(PADDR(e->env_pgdir));
f0103a98:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103a9b:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103a9e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103aa3:	77 20                	ja     f0103ac5 <env_create+0xa4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103aa5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103aa9:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f0103ab0:	f0 
f0103ab1:	c7 44 24 04 99 01 00 	movl   $0x199,0x4(%esp)
f0103ab8:	00 
f0103ab9:	c7 04 24 75 7b 10 f0 	movl   $0xf0107b75,(%esp)
f0103ac0:	e8 7b c5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103ac5:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103aca:	0f 22 d8             	mov    %eax,%cr3

	//fix tf
	e->env_tf.tf_eip = elf->e_entry;
f0103acd:	8b 47 18             	mov    0x18(%edi),%eax
f0103ad0:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103ad3:	89 41 30             	mov    %eax,0x30(%ecx)
f0103ad6:	eb 50                	jmp    f0103b28 <env_create+0x107>

	for (; ph < eph; ph++) {
		if (ph->p_type != ELF_PROG_LOAD)
f0103ad8:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103adb:	75 48                	jne    f0103b25 <env_create+0x104>
			continue;
			//panic("load_icode(): ph has wrong type");
		region_alloc(e, (void *) ph->p_va, ph->p_memsz);
f0103add:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103ae0:	8b 53 08             	mov    0x8(%ebx),%edx
f0103ae3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103ae6:	e8 b5 fb ff ff       	call   f01036a0 <region_alloc>
		memmove((void *) ph->p_va, (char *) binary + ph->p_offset, ph->p_filesz);
f0103aeb:	8b 43 10             	mov    0x10(%ebx),%eax
f0103aee:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103af2:	89 f8                	mov    %edi,%eax
f0103af4:	03 43 04             	add    0x4(%ebx),%eax
f0103af7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103afb:	8b 43 08             	mov    0x8(%ebx),%eax
f0103afe:	89 04 24             	mov    %eax,(%esp)
f0103b01:	e8 ce 20 00 00       	call   f0105bd4 <memmove>
		memset((void *) ph->p_va + ph->p_filesz, 0, ph->p_memsz - ph->p_filesz);
f0103b06:	8b 43 10             	mov    0x10(%ebx),%eax
f0103b09:	8b 53 14             	mov    0x14(%ebx),%edx
f0103b0c:	29 c2                	sub    %eax,%edx
f0103b0e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103b12:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103b19:	00 
f0103b1a:	03 43 08             	add    0x8(%ebx),%eax
f0103b1d:	89 04 24             	mov    %eax,(%esp)
f0103b20:	e8 62 20 00 00       	call   f0105b87 <memset>
	lcr3(PADDR(e->env_pgdir));

	//fix tf
	e->env_tf.tf_eip = elf->e_entry;

	for (; ph < eph; ph++) {
f0103b25:	83 c3 20             	add    $0x20,%ebx
f0103b28:	39 de                	cmp    %ebx,%esi
f0103b2a:	77 ac                	ja     f0103ad8 <env_create+0xb7>

	// call the entry point from the ELF header
	// note: does not return!
	//((void (*)(void)) (ELFHDR->e_entry))();

	lcr3(PADDR(kern_pgdir));
f0103b2c:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103b31:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103b36:	77 20                	ja     f0103b58 <env_create+0x137>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103b38:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103b3c:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f0103b43:	f0 
f0103b44:	c7 44 24 04 ae 01 00 	movl   $0x1ae,0x4(%esp)
f0103b4b:	00 
f0103b4c:	c7 04 24 75 7b 10 f0 	movl   $0xf0107b75,(%esp)
f0103b53:	e8 e8 c4 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103b58:	05 00 00 00 10       	add    $0x10000000,%eax
f0103b5d:	0f 22 d8             	mov    %eax,%cr3

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void *)(USTACKTOP - PGSIZE), PGSIZE);
f0103b60:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103b65:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103b6a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103b6d:	e8 2e fb ff ff       	call   f01036a0 <region_alloc>
	if (result != 0)
		panic("env_create(): env allocation failure");
		//cprintf("env_create(): env allocation failure\n");

	load_icode(new_env, binary);
	new_env->env_type = type;
f0103b72:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103b75:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103b78:	89 50 50             	mov    %edx,0x50(%eax)
	//new_env->env_parent_id = 0;
}
f0103b7b:	83 c4 3c             	add    $0x3c,%esp
f0103b7e:	5b                   	pop    %ebx
f0103b7f:	5e                   	pop    %esi
f0103b80:	5f                   	pop    %edi
f0103b81:	5d                   	pop    %ebp
f0103b82:	c3                   	ret    

f0103b83 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103b83:	55                   	push   %ebp
f0103b84:	89 e5                	mov    %esp,%ebp
f0103b86:	57                   	push   %edi
f0103b87:	56                   	push   %esi
f0103b88:	53                   	push   %ebx
f0103b89:	83 ec 2c             	sub    $0x2c,%esp
f0103b8c:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103b8f:	e8 45 26 00 00       	call   f01061d9 <cpunum>
f0103b94:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b97:	39 b8 28 d0 22 f0    	cmp    %edi,-0xfdd2fd8(%eax)
f0103b9d:	75 34                	jne    f0103bd3 <env_free+0x50>
		lcr3(PADDR(kern_pgdir));
f0103b9f:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103ba4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103ba9:	77 20                	ja     f0103bcb <env_free+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103bab:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103baf:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f0103bb6:	f0 
f0103bb7:	c7 44 24 04 e0 01 00 	movl   $0x1e0,0x4(%esp)
f0103bbe:	00 
f0103bbf:	c7 04 24 75 7b 10 f0 	movl   $0xf0107b75,(%esp)
f0103bc6:	e8 75 c4 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103bcb:	05 00 00 00 10       	add    $0x10000000,%eax
f0103bd0:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103bd3:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103bd6:	e8 fe 25 00 00       	call   f01061d9 <cpunum>
f0103bdb:	6b d0 74             	imul   $0x74,%eax,%edx
f0103bde:	b8 00 00 00 00       	mov    $0x0,%eax
f0103be3:	83 ba 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%edx)
f0103bea:	74 11                	je     f0103bfd <env_free+0x7a>
f0103bec:	e8 e8 25 00 00       	call   f01061d9 <cpunum>
f0103bf1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bf4:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103bfa:	8b 40 48             	mov    0x48(%eax),%eax
f0103bfd:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103c01:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c05:	c7 04 24 dc 7b 10 f0 	movl   $0xf0107bdc,(%esp)
f0103c0c:	e8 5d 04 00 00       	call   f010406e <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103c11:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103c18:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103c1b:	89 c8                	mov    %ecx,%eax
f0103c1d:	c1 e0 02             	shl    $0x2,%eax
f0103c20:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103c23:	8b 47 60             	mov    0x60(%edi),%eax
f0103c26:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f0103c29:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103c2f:	0f 84 b7 00 00 00    	je     f0103cec <env_free+0x169>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103c35:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103c3b:	89 f0                	mov    %esi,%eax
f0103c3d:	c1 e8 0c             	shr    $0xc,%eax
f0103c40:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103c43:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f0103c49:	72 20                	jb     f0103c6b <env_free+0xe8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103c4b:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103c4f:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0103c56:	f0 
f0103c57:	c7 44 24 04 ef 01 00 	movl   $0x1ef,0x4(%esp)
f0103c5e:	00 
f0103c5f:	c7 04 24 75 7b 10 f0 	movl   $0xf0107b75,(%esp)
f0103c66:	e8 d5 c3 ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103c6b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103c6e:	c1 e0 16             	shl    $0x16,%eax
f0103c71:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103c74:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103c79:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103c80:	01 
f0103c81:	74 17                	je     f0103c9a <env_free+0x117>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103c83:	89 d8                	mov    %ebx,%eax
f0103c85:	c1 e0 0c             	shl    $0xc,%eax
f0103c88:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103c8b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c8f:	8b 47 60             	mov    0x60(%edi),%eax
f0103c92:	89 04 24             	mov    %eax,(%esp)
f0103c95:	e8 b2 d7 ff ff       	call   f010144c <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103c9a:	83 c3 01             	add    $0x1,%ebx
f0103c9d:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103ca3:	75 d4                	jne    f0103c79 <env_free+0xf6>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103ca5:	8b 47 60             	mov    0x60(%edi),%eax
f0103ca8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103cab:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103cb2:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103cb5:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f0103cbb:	72 1c                	jb     f0103cd9 <env_free+0x156>
		panic("pa2page called with invalid pa");
f0103cbd:	c7 44 24 08 bc 72 10 	movl   $0xf01072bc,0x8(%esp)
f0103cc4:	f0 
f0103cc5:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103ccc:	00 
f0103ccd:	c7 04 24 ab 6e 10 f0 	movl   $0xf0106eab,(%esp)
f0103cd4:	e8 67 c3 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103cd9:	a1 90 ce 22 f0       	mov    0xf022ce90,%eax
f0103cde:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103ce1:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103ce4:	89 04 24             	mov    %eax,(%esp)
f0103ce7:	e8 db d4 ff ff       	call   f01011c7 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103cec:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103cf0:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103cf7:	0f 85 1b ff ff ff    	jne    f0103c18 <env_free+0x95>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103cfd:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103d00:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103d05:	77 20                	ja     f0103d27 <env_free+0x1a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103d07:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103d0b:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f0103d12:	f0 
f0103d13:	c7 44 24 04 fd 01 00 	movl   $0x1fd,0x4(%esp)
f0103d1a:	00 
f0103d1b:	c7 04 24 75 7b 10 f0 	movl   $0xf0107b75,(%esp)
f0103d22:	e8 19 c3 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103d27:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103d2e:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103d33:	c1 e8 0c             	shr    $0xc,%eax
f0103d36:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f0103d3c:	72 1c                	jb     f0103d5a <env_free+0x1d7>
		panic("pa2page called with invalid pa");
f0103d3e:	c7 44 24 08 bc 72 10 	movl   $0xf01072bc,0x8(%esp)
f0103d45:	f0 
f0103d46:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103d4d:	00 
f0103d4e:	c7 04 24 ab 6e 10 f0 	movl   $0xf0106eab,(%esp)
f0103d55:	e8 e6 c2 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103d5a:	8b 15 90 ce 22 f0    	mov    0xf022ce90,%edx
f0103d60:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103d63:	89 04 24             	mov    %eax,(%esp)
f0103d66:	e8 5c d4 ff ff       	call   f01011c7 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103d6b:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103d72:	a1 4c c2 22 f0       	mov    0xf022c24c,%eax
f0103d77:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103d7a:	89 3d 4c c2 22 f0    	mov    %edi,0xf022c24c
}
f0103d80:	83 c4 2c             	add    $0x2c,%esp
f0103d83:	5b                   	pop    %ebx
f0103d84:	5e                   	pop    %esi
f0103d85:	5f                   	pop    %edi
f0103d86:	5d                   	pop    %ebp
f0103d87:	c3                   	ret    

f0103d88 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103d88:	55                   	push   %ebp
f0103d89:	89 e5                	mov    %esp,%ebp
f0103d8b:	53                   	push   %ebx
f0103d8c:	83 ec 14             	sub    $0x14,%esp
f0103d8f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103d92:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103d96:	75 19                	jne    f0103db1 <env_destroy+0x29>
f0103d98:	e8 3c 24 00 00       	call   f01061d9 <cpunum>
f0103d9d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103da0:	39 98 28 d0 22 f0    	cmp    %ebx,-0xfdd2fd8(%eax)
f0103da6:	74 09                	je     f0103db1 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103da8:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103daf:	eb 2f                	jmp    f0103de0 <env_destroy+0x58>
	}

	env_free(e);
f0103db1:	89 1c 24             	mov    %ebx,(%esp)
f0103db4:	e8 ca fd ff ff       	call   f0103b83 <env_free>

	if (curenv == e) {
f0103db9:	e8 1b 24 00 00       	call   f01061d9 <cpunum>
f0103dbe:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dc1:	39 98 28 d0 22 f0    	cmp    %ebx,-0xfdd2fd8(%eax)
f0103dc7:	75 17                	jne    f0103de0 <env_destroy+0x58>
		curenv = NULL;
f0103dc9:	e8 0b 24 00 00       	call   f01061d9 <cpunum>
f0103dce:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dd1:	c7 80 28 d0 22 f0 00 	movl   $0x0,-0xfdd2fd8(%eax)
f0103dd8:	00 00 00 
		sched_yield();
f0103ddb:	e8 f2 0b 00 00       	call   f01049d2 <sched_yield>
	}
}
f0103de0:	83 c4 14             	add    $0x14,%esp
f0103de3:	5b                   	pop    %ebx
f0103de4:	5d                   	pop    %ebp
f0103de5:	c3                   	ret    

f0103de6 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103de6:	55                   	push   %ebp
f0103de7:	89 e5                	mov    %esp,%ebp
f0103de9:	53                   	push   %ebx
f0103dea:	83 ec 14             	sub    $0x14,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103ded:	e8 e7 23 00 00       	call   f01061d9 <cpunum>
f0103df2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103df5:	8b 98 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%ebx
f0103dfb:	e8 d9 23 00 00       	call   f01061d9 <cpunum>
f0103e00:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f0103e03:	8b 65 08             	mov    0x8(%ebp),%esp
f0103e06:	61                   	popa   
f0103e07:	07                   	pop    %es
f0103e08:	1f                   	pop    %ds
f0103e09:	83 c4 08             	add    $0x8,%esp
f0103e0c:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103e0d:	c7 44 24 08 f2 7b 10 	movl   $0xf0107bf2,0x8(%esp)
f0103e14:	f0 
f0103e15:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
f0103e1c:	00 
f0103e1d:	c7 04 24 75 7b 10 f0 	movl   $0xf0107b75,(%esp)
f0103e24:	e8 17 c2 ff ff       	call   f0100040 <_panic>

f0103e29 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103e29:	55                   	push   %ebp
f0103e2a:	89 e5                	mov    %esp,%ebp
f0103e2c:	83 ec 18             	sub    $0x18,%esp

	// LAB 3: Your code here.
	//cprintf("DEBUG env_run() called\n");

	//step 1
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103e2f:	e8 a5 23 00 00       	call   f01061d9 <cpunum>
f0103e34:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e37:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f0103e3e:	74 29                	je     f0103e69 <env_run+0x40>
f0103e40:	e8 94 23 00 00       	call   f01061d9 <cpunum>
f0103e45:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e48:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103e4e:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103e52:	75 15                	jne    f0103e69 <env_run+0x40>
		curenv->env_status = ENV_RUNNABLE;
f0103e54:	e8 80 23 00 00       	call   f01061d9 <cpunum>
f0103e59:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e5c:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103e62:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	curenv = e;
f0103e69:	e8 6b 23 00 00       	call   f01061d9 <cpunum>
f0103e6e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e71:	8b 55 08             	mov    0x8(%ebp),%edx
f0103e74:	89 90 28 d0 22 f0    	mov    %edx,-0xfdd2fd8(%eax)
	//curenv->env_cpunum = cpunum();
	curenv->env_status = ENV_RUNNING;
f0103e7a:	e8 5a 23 00 00       	call   f01061d9 <cpunum>
f0103e7f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e82:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103e88:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0103e8f:	e8 45 23 00 00       	call   f01061d9 <cpunum>
f0103e94:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e97:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103e9d:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv->env_pgdir));
f0103ea1:	e8 33 23 00 00       	call   f01061d9 <cpunum>
f0103ea6:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ea9:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103eaf:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103eb2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103eb7:	77 20                	ja     f0103ed9 <env_run+0xb0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103eb9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103ebd:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f0103ec4:	f0 
f0103ec5:	c7 44 24 04 5a 02 00 	movl   $0x25a,0x4(%esp)
f0103ecc:	00 
f0103ecd:	c7 04 24 75 7b 10 f0 	movl   $0xf0107b75,(%esp)
f0103ed4:	e8 67 c1 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103ed9:	05 00 00 00 10       	add    $0x10000000,%eax
f0103ede:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103ee1:	c7 04 24 80 14 12 f0 	movl   $0xf0121480,(%esp)
f0103ee8:	e8 16 26 00 00       	call   f0106503 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103eed:	f3 90                	pause  

	//step 2
	unlock_kernel();
	env_pop_tf(&(curenv->env_tf));
f0103eef:	e8 e5 22 00 00       	call   f01061d9 <cpunum>
f0103ef4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ef7:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0103efd:	89 04 24             	mov    %eax,(%esp)
f0103f00:	e8 e1 fe ff ff       	call   f0103de6 <env_pop_tf>

f0103f05 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103f05:	55                   	push   %ebp
f0103f06:	89 e5                	mov    %esp,%ebp
f0103f08:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103f0c:	ba 70 00 00 00       	mov    $0x70,%edx
f0103f11:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103f12:	b2 71                	mov    $0x71,%dl
f0103f14:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103f15:	0f b6 c0             	movzbl %al,%eax
}
f0103f18:	5d                   	pop    %ebp
f0103f19:	c3                   	ret    

f0103f1a <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103f1a:	55                   	push   %ebp
f0103f1b:	89 e5                	mov    %esp,%ebp
f0103f1d:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103f21:	ba 70 00 00 00       	mov    $0x70,%edx
f0103f26:	ee                   	out    %al,(%dx)
f0103f27:	b2 71                	mov    $0x71,%dl
f0103f29:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f2c:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103f2d:	5d                   	pop    %ebp
f0103f2e:	c3                   	ret    

f0103f2f <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103f2f:	55                   	push   %ebp
f0103f30:	89 e5                	mov    %esp,%ebp
f0103f32:	56                   	push   %esi
f0103f33:	53                   	push   %ebx
f0103f34:	83 ec 10             	sub    $0x10,%esp
f0103f37:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103f3a:	66 a3 a8 13 12 f0    	mov    %ax,0xf01213a8
	if (!didinit)
f0103f40:	80 3d 50 c2 22 f0 00 	cmpb   $0x0,0xf022c250
f0103f47:	74 4e                	je     f0103f97 <irq_setmask_8259A+0x68>
f0103f49:	89 c6                	mov    %eax,%esi
f0103f4b:	ba 21 00 00 00       	mov    $0x21,%edx
f0103f50:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103f51:	66 c1 e8 08          	shr    $0x8,%ax
f0103f55:	b2 a1                	mov    $0xa1,%dl
f0103f57:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103f58:	c7 04 24 fe 7b 10 f0 	movl   $0xf0107bfe,(%esp)
f0103f5f:	e8 0a 01 00 00       	call   f010406e <cprintf>
	for (i = 0; i < 16; i++)
f0103f64:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103f69:	0f b7 f6             	movzwl %si,%esi
f0103f6c:	f7 d6                	not    %esi
f0103f6e:	0f a3 de             	bt     %ebx,%esi
f0103f71:	73 10                	jae    f0103f83 <irq_setmask_8259A+0x54>
			cprintf(" %d", i);
f0103f73:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103f77:	c7 04 24 57 82 10 f0 	movl   $0xf0108257,(%esp)
f0103f7e:	e8 eb 00 00 00       	call   f010406e <cprintf>
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103f83:	83 c3 01             	add    $0x1,%ebx
f0103f86:	83 fb 10             	cmp    $0x10,%ebx
f0103f89:	75 e3                	jne    f0103f6e <irq_setmask_8259A+0x3f>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103f8b:	c7 04 24 a3 71 10 f0 	movl   $0xf01071a3,(%esp)
f0103f92:	e8 d7 00 00 00       	call   f010406e <cprintf>
}
f0103f97:	83 c4 10             	add    $0x10,%esp
f0103f9a:	5b                   	pop    %ebx
f0103f9b:	5e                   	pop    %esi
f0103f9c:	5d                   	pop    %ebp
f0103f9d:	c3                   	ret    

f0103f9e <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f0103f9e:	c6 05 50 c2 22 f0 01 	movb   $0x1,0xf022c250
f0103fa5:	ba 21 00 00 00       	mov    $0x21,%edx
f0103faa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103faf:	ee                   	out    %al,(%dx)
f0103fb0:	b2 a1                	mov    $0xa1,%dl
f0103fb2:	ee                   	out    %al,(%dx)
f0103fb3:	b2 20                	mov    $0x20,%dl
f0103fb5:	b8 11 00 00 00       	mov    $0x11,%eax
f0103fba:	ee                   	out    %al,(%dx)
f0103fbb:	b2 21                	mov    $0x21,%dl
f0103fbd:	b8 20 00 00 00       	mov    $0x20,%eax
f0103fc2:	ee                   	out    %al,(%dx)
f0103fc3:	b8 04 00 00 00       	mov    $0x4,%eax
f0103fc8:	ee                   	out    %al,(%dx)
f0103fc9:	b8 03 00 00 00       	mov    $0x3,%eax
f0103fce:	ee                   	out    %al,(%dx)
f0103fcf:	b2 a0                	mov    $0xa0,%dl
f0103fd1:	b8 11 00 00 00       	mov    $0x11,%eax
f0103fd6:	ee                   	out    %al,(%dx)
f0103fd7:	b2 a1                	mov    $0xa1,%dl
f0103fd9:	b8 28 00 00 00       	mov    $0x28,%eax
f0103fde:	ee                   	out    %al,(%dx)
f0103fdf:	b8 02 00 00 00       	mov    $0x2,%eax
f0103fe4:	ee                   	out    %al,(%dx)
f0103fe5:	b8 01 00 00 00       	mov    $0x1,%eax
f0103fea:	ee                   	out    %al,(%dx)
f0103feb:	b2 20                	mov    $0x20,%dl
f0103fed:	b8 68 00 00 00       	mov    $0x68,%eax
f0103ff2:	ee                   	out    %al,(%dx)
f0103ff3:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103ff8:	ee                   	out    %al,(%dx)
f0103ff9:	b2 a0                	mov    $0xa0,%dl
f0103ffb:	b8 68 00 00 00       	mov    $0x68,%eax
f0104000:	ee                   	out    %al,(%dx)
f0104001:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104006:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0104007:	0f b7 05 a8 13 12 f0 	movzwl 0xf01213a8,%eax
f010400e:	66 83 f8 ff          	cmp    $0xffff,%ax
f0104012:	74 12                	je     f0104026 <pic_init+0x88>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0104014:	55                   	push   %ebp
f0104015:	89 e5                	mov    %esp,%ebp
f0104017:	83 ec 18             	sub    $0x18,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f010401a:	0f b7 c0             	movzwl %ax,%eax
f010401d:	89 04 24             	mov    %eax,(%esp)
f0104020:	e8 0a ff ff ff       	call   f0103f2f <irq_setmask_8259A>
}
f0104025:	c9                   	leave  
f0104026:	f3 c3                	repz ret 

f0104028 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0104028:	55                   	push   %ebp
f0104029:	89 e5                	mov    %esp,%ebp
f010402b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010402e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104031:	89 04 24             	mov    %eax,(%esp)
f0104034:	e8 55 c7 ff ff       	call   f010078e <cputchar>
	*cnt++;
}
f0104039:	c9                   	leave  
f010403a:	c3                   	ret    

f010403b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010403b:	55                   	push   %ebp
f010403c:	89 e5                	mov    %esp,%ebp
f010403e:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0104041:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0104048:	8b 45 0c             	mov    0xc(%ebp),%eax
f010404b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010404f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104052:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104056:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104059:	89 44 24 04          	mov    %eax,0x4(%esp)
f010405d:	c7 04 24 28 40 10 f0 	movl   $0xf0104028,(%esp)
f0104064:	e8 65 14 00 00       	call   f01054ce <vprintfmt>
	return cnt;
}
f0104069:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010406c:	c9                   	leave  
f010406d:	c3                   	ret    

f010406e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010406e:	55                   	push   %ebp
f010406f:	89 e5                	mov    %esp,%ebp
f0104071:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0104074:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0104077:	89 44 24 04          	mov    %eax,0x4(%esp)
f010407b:	8b 45 08             	mov    0x8(%ebp),%eax
f010407e:	89 04 24             	mov    %eax,(%esp)
f0104081:	e8 b5 ff ff ff       	call   f010403b <vcprintf>
	va_end(ap);

	return cnt;
}
f0104086:	c9                   	leave  
f0104087:	c3                   	ret    
f0104088:	66 90                	xchg   %ax,%ax
f010408a:	66 90                	xchg   %ax,%ax
f010408c:	66 90                	xchg   %ax,%ax
f010408e:	66 90                	xchg   %ax,%ax

f0104090 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0104090:	55                   	push   %ebp
f0104091:	89 e5                	mov    %esp,%ebp
f0104093:	57                   	push   %edi
f0104094:	56                   	push   %esi
f0104095:	53                   	push   %ebx
f0104096:	83 ec 1c             	sub    $0x1c,%esp
	// get a triple fault.  If you set up an individual CPU's TSS
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:
	uint32_t i = thiscpu->cpu_id;
f0104099:	e8 3b 21 00 00       	call   f01061d9 <cpunum>
f010409e:	6b c0 74             	imul   $0x74,%eax,%eax
f01040a1:	0f b6 80 20 d0 22 f0 	movzbl -0xfdd2fe0(%eax),%eax
f01040a8:	88 45 e7             	mov    %al,-0x19(%ebp)
f01040ab:	0f b6 d8             	movzbl %al,%ebx
	thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
f01040ae:	e8 26 21 00 00       	call   f01061d9 <cpunum>
f01040b3:	6b c0 74             	imul   $0x74,%eax,%eax
f01040b6:	89 da                	mov    %ebx,%edx
f01040b8:	f7 da                	neg    %edx
f01040ba:	c1 e2 10             	shl    $0x10,%edx
f01040bd:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f01040c3:	89 90 30 d0 22 f0    	mov    %edx,-0xfdd2fd0(%eax)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f01040c9:	e8 0b 21 00 00       	call   f01061d9 <cpunum>
f01040ce:	6b c0 74             	imul   $0x74,%eax,%eax
f01040d1:	66 c7 80 34 d0 22 f0 	movw   $0x10,-0xfdd2fcc(%eax)
f01040d8:	10 00 
	// when we trap to the kernel.
	//ts.ts_esp0 = KSTACKTOP;
	//ts.ts_ss0 = GD_KD;

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3) + i] = SEG16(STS_T32A, (uint32_t) (&thiscpu->cpu_ts),
f01040da:	83 c3 05             	add    $0x5,%ebx
f01040dd:	e8 f7 20 00 00       	call   f01061d9 <cpunum>
f01040e2:	89 c7                	mov    %eax,%edi
f01040e4:	e8 f0 20 00 00       	call   f01061d9 <cpunum>
f01040e9:	89 c6                	mov    %eax,%esi
f01040eb:	e8 e9 20 00 00       	call   f01061d9 <cpunum>
f01040f0:	66 c7 04 dd 40 13 12 	movw   $0x67,-0xfedecc0(,%ebx,8)
f01040f7:	f0 67 00 
f01040fa:	6b ff 74             	imul   $0x74,%edi,%edi
f01040fd:	81 c7 2c d0 22 f0    	add    $0xf022d02c,%edi
f0104103:	66 89 3c dd 42 13 12 	mov    %di,-0xfedecbe(,%ebx,8)
f010410a:	f0 
f010410b:	6b d6 74             	imul   $0x74,%esi,%edx
f010410e:	81 c2 2c d0 22 f0    	add    $0xf022d02c,%edx
f0104114:	c1 ea 10             	shr    $0x10,%edx
f0104117:	88 14 dd 44 13 12 f0 	mov    %dl,-0xfedecbc(,%ebx,8)
f010411e:	c6 04 dd 46 13 12 f0 	movb   $0x40,-0xfedecba(,%ebx,8)
f0104125:	40 
f0104126:	6b c0 74             	imul   $0x74,%eax,%eax
f0104129:	05 2c d0 22 f0       	add    $0xf022d02c,%eax
f010412e:	c1 e8 18             	shr    $0x18,%eax
f0104131:	88 04 dd 47 13 12 f0 	mov    %al,-0xfedecb9(,%ebx,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + i].sd_s = 0;
f0104138:	c6 04 dd 45 13 12 f0 	movb   $0x89,-0xfedecbb(,%ebx,8)
f010413f:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0 + (i << 3));
f0104140:	0f b6 75 e7          	movzbl -0x19(%ebp),%esi
f0104144:	8d 34 f5 28 00 00 00 	lea    0x28(,%esi,8),%esi
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f010414b:	0f 00 de             	ltr    %si
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f010414e:	b8 aa 13 12 f0       	mov    $0xf01213aa,%eax
f0104153:	0f 01 18             	lidtl  (%eax)

	// Load the IDT
	lidt(&idt_pd);
}
f0104156:	83 c4 1c             	add    $0x1c,%esp
f0104159:	5b                   	pop    %ebx
f010415a:	5e                   	pop    %esi
f010415b:	5f                   	pop    %edi
f010415c:	5d                   	pop    %ebp
f010415d:	c3                   	ret    

f010415e <trap_init>:
	void handler29();
	void handler30();
	void handler31();
	void handler48();*/

	int i = 0;
f010415e:	b8 00 00 00 00       	mov    $0x0,%eax
	for ( ; i <= 48; i++)
		SETGATE(idt[i], 0, GD_KT, handlers[i], 0);
f0104163:	8b 14 85 b0 13 12 f0 	mov    -0xfedec50(,%eax,4),%edx
f010416a:	66 89 14 c5 60 c2 22 	mov    %dx,-0xfdd3da0(,%eax,8)
f0104171:	f0 
f0104172:	66 c7 04 c5 62 c2 22 	movw   $0x8,-0xfdd3d9e(,%eax,8)
f0104179:	f0 08 00 
f010417c:	c6 04 c5 64 c2 22 f0 	movb   $0x0,-0xfdd3d9c(,%eax,8)
f0104183:	00 
f0104184:	c6 04 c5 65 c2 22 f0 	movb   $0x8e,-0xfdd3d9b(,%eax,8)
f010418b:	8e 
f010418c:	c1 ea 10             	shr    $0x10,%edx
f010418f:	66 89 14 c5 66 c2 22 	mov    %dx,-0xfdd3d9a(,%eax,8)
f0104196:	f0 
	void handler30();
	void handler31();
	void handler48();*/

	int i = 0;
	for ( ; i <= 48; i++)
f0104197:	83 c0 01             	add    $0x1,%eax
f010419a:	83 f8 31             	cmp    $0x31,%eax
f010419d:	75 c4                	jne    f0104163 <trap_init+0x5>

extern long handlers[48];

void
trap_init(void)
{
f010419f:	55                   	push   %ebp
f01041a0:	89 e5                	mov    %esp,%ebp
f01041a2:	83 ec 08             	sub    $0x8,%esp

	int i = 0;
	for ( ; i <= 48; i++)
		SETGATE(idt[i], 0, GD_KT, handlers[i], 0);

	SETGATE(idt[T_BRKPT], 0, GD_KT, handlers[T_BRKPT], 3);
f01041a5:	a1 bc 13 12 f0       	mov    0xf01213bc,%eax
f01041aa:	66 a3 78 c2 22 f0    	mov    %ax,0xf022c278
f01041b0:	66 c7 05 7a c2 22 f0 	movw   $0x8,0xf022c27a
f01041b7:	08 00 
f01041b9:	c6 05 7c c2 22 f0 00 	movb   $0x0,0xf022c27c
f01041c0:	c6 05 7d c2 22 f0 ee 	movb   $0xee,0xf022c27d
f01041c7:	c1 e8 10             	shr    $0x10,%eax
f01041ca:	66 a3 7e c2 22 f0    	mov    %ax,0xf022c27e
	SETGATE(idt[T_SYSCALL], 0, GD_KT, handlers[T_SYSCALL], 3);
f01041d0:	a1 70 14 12 f0       	mov    0xf0121470,%eax
f01041d5:	66 a3 e0 c3 22 f0    	mov    %ax,0xf022c3e0
f01041db:	66 c7 05 e2 c3 22 f0 	movw   $0x8,0xf022c3e2
f01041e2:	08 00 
f01041e4:	c6 05 e4 c3 22 f0 00 	movb   $0x0,0xf022c3e4
f01041eb:	c6 05 e5 c3 22 f0 ee 	movb   $0xee,0xf022c3e5
f01041f2:	c1 e8 10             	shr    $0x10,%eax
f01041f5:	66 a3 e6 c3 22 f0    	mov    %ax,0xf022c3e6
	SETGATE(idt[30], 0, GD_KT, handler30, 0);
	SETGATE(idt[31], 0, GD_KT, handler31, 0);
	SETGATE(idt[48], 0, GD_KT, handler48, 3);*/

	// Per-CPU setup 
	trap_init_percpu();
f01041fb:	e8 90 fe ff ff       	call   f0104090 <trap_init_percpu>
}
f0104200:	c9                   	leave  
f0104201:	c3                   	ret    

f0104202 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0104202:	55                   	push   %ebp
f0104203:	89 e5                	mov    %esp,%ebp
f0104205:	53                   	push   %ebx
f0104206:	83 ec 14             	sub    $0x14,%esp
f0104209:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010420c:	8b 03                	mov    (%ebx),%eax
f010420e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104212:	c7 04 24 12 7c 10 f0 	movl   $0xf0107c12,(%esp)
f0104219:	e8 50 fe ff ff       	call   f010406e <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f010421e:	8b 43 04             	mov    0x4(%ebx),%eax
f0104221:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104225:	c7 04 24 21 7c 10 f0 	movl   $0xf0107c21,(%esp)
f010422c:	e8 3d fe ff ff       	call   f010406e <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0104231:	8b 43 08             	mov    0x8(%ebx),%eax
f0104234:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104238:	c7 04 24 30 7c 10 f0 	movl   $0xf0107c30,(%esp)
f010423f:	e8 2a fe ff ff       	call   f010406e <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0104244:	8b 43 0c             	mov    0xc(%ebx),%eax
f0104247:	89 44 24 04          	mov    %eax,0x4(%esp)
f010424b:	c7 04 24 3f 7c 10 f0 	movl   $0xf0107c3f,(%esp)
f0104252:	e8 17 fe ff ff       	call   f010406e <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0104257:	8b 43 10             	mov    0x10(%ebx),%eax
f010425a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010425e:	c7 04 24 4e 7c 10 f0 	movl   $0xf0107c4e,(%esp)
f0104265:	e8 04 fe ff ff       	call   f010406e <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f010426a:	8b 43 14             	mov    0x14(%ebx),%eax
f010426d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104271:	c7 04 24 5d 7c 10 f0 	movl   $0xf0107c5d,(%esp)
f0104278:	e8 f1 fd ff ff       	call   f010406e <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010427d:	8b 43 18             	mov    0x18(%ebx),%eax
f0104280:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104284:	c7 04 24 6c 7c 10 f0 	movl   $0xf0107c6c,(%esp)
f010428b:	e8 de fd ff ff       	call   f010406e <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0104290:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0104293:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104297:	c7 04 24 7b 7c 10 f0 	movl   $0xf0107c7b,(%esp)
f010429e:	e8 cb fd ff ff       	call   f010406e <cprintf>
}
f01042a3:	83 c4 14             	add    $0x14,%esp
f01042a6:	5b                   	pop    %ebx
f01042a7:	5d                   	pop    %ebp
f01042a8:	c3                   	ret    

f01042a9 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f01042a9:	55                   	push   %ebp
f01042aa:	89 e5                	mov    %esp,%ebp
f01042ac:	56                   	push   %esi
f01042ad:	53                   	push   %ebx
f01042ae:	83 ec 10             	sub    $0x10,%esp
f01042b1:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d and number %d\n", tf, cpunum(), tf->tf_trapno);
f01042b4:	8b 73 28             	mov    0x28(%ebx),%esi
f01042b7:	e8 1d 1f 00 00       	call   f01061d9 <cpunum>
f01042bc:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01042c0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01042c4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01042c8:	c7 04 24 60 7f 10 f0 	movl   $0xf0107f60,(%esp)
f01042cf:	e8 9a fd ff ff       	call   f010406e <cprintf>
	print_regs(&tf->tf_regs);
f01042d4:	89 1c 24             	mov    %ebx,(%esp)
f01042d7:	e8 26 ff ff ff       	call   f0104202 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01042dc:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01042e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042e4:	c7 04 24 d0 7c 10 f0 	movl   $0xf0107cd0,(%esp)
f01042eb:	e8 7e fd ff ff       	call   f010406e <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01042f0:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01042f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042f8:	c7 04 24 e3 7c 10 f0 	movl   $0xf0107ce3,(%esp)
f01042ff:	e8 6a fd ff ff       	call   f010406e <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0104304:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0104307:	83 f8 13             	cmp    $0x13,%eax
f010430a:	77 09                	ja     f0104315 <print_trapframe+0x6c>
		return excnames[trapno];
f010430c:	8b 14 85 c0 7f 10 f0 	mov    -0xfef8040(,%eax,4),%edx
f0104313:	eb 2e                	jmp    f0104343 <print_trapframe+0x9a>
	if (trapno == T_SYSCALL)
f0104315:	83 f8 30             	cmp    $0x30,%eax
f0104318:	74 24                	je     f010433e <print_trapframe+0x95>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f010431a:	8d 48 e0             	lea    -0x20(%eax),%ecx
		cprintf("trapno %d\n", trapno);
		return "Hardware Interrupt";
f010431d:	ba 96 7c 10 f0       	mov    $0xf0107c96,%edx

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0104322:	83 f9 0f             	cmp    $0xf,%ecx
f0104325:	77 1c                	ja     f0104343 <print_trapframe+0x9a>
		cprintf("trapno %d\n", trapno);
f0104327:	89 44 24 04          	mov    %eax,0x4(%esp)
f010432b:	c7 04 24 f6 7c 10 f0 	movl   $0xf0107cf6,(%esp)
f0104332:	e8 37 fd ff ff       	call   f010406e <cprintf>
		return "Hardware Interrupt";
f0104337:	ba 96 7c 10 f0       	mov    $0xf0107c96,%edx
f010433c:	eb 05                	jmp    f0104343 <print_trapframe+0x9a>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f010433e:	ba 8a 7c 10 f0       	mov    $0xf0107c8a,%edx
{
	cprintf("TRAP frame at %p from CPU %d and number %d\n", tf, cpunum(), tf->tf_trapno);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0104343:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104347:	8b 43 28             	mov    0x28(%ebx),%eax
f010434a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010434e:	c7 04 24 01 7d 10 f0 	movl   $0xf0107d01,(%esp)
f0104355:	e8 14 fd ff ff       	call   f010406e <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f010435a:	3b 1d 60 ca 22 f0    	cmp    0xf022ca60,%ebx
f0104360:	75 19                	jne    f010437b <print_trapframe+0xd2>
f0104362:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0104366:	75 13                	jne    f010437b <print_trapframe+0xd2>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0104368:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f010436b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010436f:	c7 04 24 13 7d 10 f0 	movl   $0xf0107d13,(%esp)
f0104376:	e8 f3 fc ff ff       	call   f010406e <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f010437b:	8b 43 2c             	mov    0x2c(%ebx),%eax
f010437e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104382:	c7 04 24 22 7d 10 f0 	movl   $0xf0107d22,(%esp)
f0104389:	e8 e0 fc ff ff       	call   f010406e <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f010438e:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0104392:	75 51                	jne    f01043e5 <print_trapframe+0x13c>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0104394:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0104397:	89 c2                	mov    %eax,%edx
f0104399:	83 e2 01             	and    $0x1,%edx
f010439c:	ba a9 7c 10 f0       	mov    $0xf0107ca9,%edx
f01043a1:	b9 b4 7c 10 f0       	mov    $0xf0107cb4,%ecx
f01043a6:	0f 45 ca             	cmovne %edx,%ecx
f01043a9:	89 c2                	mov    %eax,%edx
f01043ab:	83 e2 02             	and    $0x2,%edx
f01043ae:	ba c0 7c 10 f0       	mov    $0xf0107cc0,%edx
f01043b3:	be c6 7c 10 f0       	mov    $0xf0107cc6,%esi
f01043b8:	0f 44 d6             	cmove  %esi,%edx
f01043bb:	83 e0 04             	and    $0x4,%eax
f01043be:	b8 cb 7c 10 f0       	mov    $0xf0107ccb,%eax
f01043c3:	be 07 7e 10 f0       	mov    $0xf0107e07,%esi
f01043c8:	0f 44 c6             	cmove  %esi,%eax
f01043cb:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01043cf:	89 54 24 08          	mov    %edx,0x8(%esp)
f01043d3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043d7:	c7 04 24 30 7d 10 f0 	movl   $0xf0107d30,(%esp)
f01043de:	e8 8b fc ff ff       	call   f010406e <cprintf>
f01043e3:	eb 0c                	jmp    f01043f1 <print_trapframe+0x148>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f01043e5:	c7 04 24 a3 71 10 f0 	movl   $0xf01071a3,(%esp)
f01043ec:	e8 7d fc ff ff       	call   f010406e <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01043f1:	8b 43 30             	mov    0x30(%ebx),%eax
f01043f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043f8:	c7 04 24 3f 7d 10 f0 	movl   $0xf0107d3f,(%esp)
f01043ff:	e8 6a fc ff ff       	call   f010406e <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0104404:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0104408:	89 44 24 04          	mov    %eax,0x4(%esp)
f010440c:	c7 04 24 4e 7d 10 f0 	movl   $0xf0107d4e,(%esp)
f0104413:	e8 56 fc ff ff       	call   f010406e <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0104418:	8b 43 38             	mov    0x38(%ebx),%eax
f010441b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010441f:	c7 04 24 61 7d 10 f0 	movl   $0xf0107d61,(%esp)
f0104426:	e8 43 fc ff ff       	call   f010406e <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f010442b:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010442f:	74 27                	je     f0104458 <print_trapframe+0x1af>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0104431:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0104434:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104438:	c7 04 24 70 7d 10 f0 	movl   $0xf0107d70,(%esp)
f010443f:	e8 2a fc ff ff       	call   f010406e <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0104444:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0104448:	89 44 24 04          	mov    %eax,0x4(%esp)
f010444c:	c7 04 24 7f 7d 10 f0 	movl   $0xf0107d7f,(%esp)
f0104453:	e8 16 fc ff ff       	call   f010406e <cprintf>
	}
}
f0104458:	83 c4 10             	add    $0x10,%esp
f010445b:	5b                   	pop    %ebx
f010445c:	5e                   	pop    %esi
f010445d:	5d                   	pop    %ebp
f010445e:	c3                   	ret    

f010445f <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f010445f:	55                   	push   %ebp
f0104460:	89 e5                	mov    %esp,%ebp
f0104462:	57                   	push   %edi
f0104463:	56                   	push   %esi
f0104464:	53                   	push   %ebx
f0104465:	83 ec 1c             	sub    $0x1c,%esp
f0104468:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010446b:	0f 20 d6             	mov    %cr2,%esi

	// LAB 3: Your code here.
	//print_trapframe(tf);
	//if ((tf->tf_cs & 3) != 3) {
	//if (tf->tf_cs == GD_KT) {
	if ((tf->tf_cs & 3) == 0) {
f010446e:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104472:	75 1c                	jne    f0104490 <page_fault_handler+0x31>
		panic("page fault in kernel mode");
f0104474:	c7 44 24 08 92 7d 10 	movl   $0xf0107d92,0x8(%esp)
f010447b:	f0 
f010447c:	c7 44 24 04 8d 01 00 	movl   $0x18d,0x4(%esp)
f0104483:	00 
f0104484:	c7 04 24 ac 7d 10 f0 	movl   $0xf0107dac,(%esp)
f010448b:	e8 b0 bb ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104490:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0104493:	e8 41 1d 00 00       	call   f01061d9 <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104498:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010449c:	89 74 24 08          	mov    %esi,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f01044a0:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01044a3:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01044a9:	8b 40 48             	mov    0x48(%eax),%eax
f01044ac:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044b0:	c7 04 24 8c 7f 10 f0 	movl   $0xf0107f8c,(%esp)
f01044b7:	e8 b2 fb ff ff       	call   f010406e <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01044bc:	89 1c 24             	mov    %ebx,(%esp)
f01044bf:	e8 e5 fd ff ff       	call   f01042a9 <print_trapframe>
	env_destroy(curenv);
f01044c4:	e8 10 1d 00 00       	call   f01061d9 <cpunum>
f01044c9:	6b c0 74             	imul   $0x74,%eax,%eax
f01044cc:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01044d2:	89 04 24             	mov    %eax,(%esp)
f01044d5:	e8 ae f8 ff ff       	call   f0103d88 <env_destroy>
}
f01044da:	83 c4 1c             	add    $0x1c,%esp
f01044dd:	5b                   	pop    %ebx
f01044de:	5e                   	pop    %esi
f01044df:	5f                   	pop    %edi
f01044e0:	5d                   	pop    %ebp
f01044e1:	c3                   	ret    

f01044e2 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01044e2:	55                   	push   %ebp
f01044e3:	89 e5                	mov    %esp,%ebp
f01044e5:	57                   	push   %edi
f01044e6:	56                   	push   %esi
f01044e7:	83 ec 20             	sub    $0x20,%esp
f01044ea:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01044ed:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f01044ee:	83 3d 80 ce 22 f0 00 	cmpl   $0x0,0xf022ce80
f01044f5:	74 01                	je     f01044f8 <trap+0x16>
		asm volatile("hlt");
f01044f7:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f01044f8:	e8 dc 1c 00 00       	call   f01061d9 <cpunum>
f01044fd:	6b d0 74             	imul   $0x74,%eax,%edx
f0104500:	81 c2 20 d0 22 f0    	add    $0xf022d020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0104506:	b8 01 00 00 00       	mov    $0x1,%eax
f010450b:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010450f:	83 f8 02             	cmp    $0x2,%eax
f0104512:	75 0c                	jne    f0104520 <trap+0x3e>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0104514:	c7 04 24 80 14 12 f0 	movl   $0xf0121480,(%esp)
f010451b:	e8 37 1f 00 00       	call   f0106457 <spin_lock>

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0104520:	9c                   	pushf  
f0104521:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0104522:	f6 c4 02             	test   $0x2,%ah
f0104525:	74 24                	je     f010454b <trap+0x69>
f0104527:	c7 44 24 0c b8 7d 10 	movl   $0xf0107db8,0xc(%esp)
f010452e:	f0 
f010452f:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0104536:	f0 
f0104537:	c7 44 24 04 54 01 00 	movl   $0x154,0x4(%esp)
f010453e:	00 
f010453f:	c7 04 24 ac 7d 10 f0 	movl   $0xf0107dac,(%esp)
f0104546:	e8 f5 ba ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f010454b:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010454f:	83 e0 03             	and    $0x3,%eax
f0104552:	66 83 f8 03          	cmp    $0x3,%ax
f0104556:	0f 85 a7 00 00 00    	jne    f0104603 <trap+0x121>
f010455c:	c7 04 24 80 14 12 f0 	movl   $0xf0121480,(%esp)
f0104563:	e8 ef 1e 00 00       	call   f0106457 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f0104568:	e8 6c 1c 00 00       	call   f01061d9 <cpunum>
f010456d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104570:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f0104577:	75 24                	jne    f010459d <trap+0xbb>
f0104579:	c7 44 24 0c d1 7d 10 	movl   $0xf0107dd1,0xc(%esp)
f0104580:	f0 
f0104581:	c7 44 24 08 c5 6e 10 	movl   $0xf0106ec5,0x8(%esp)
f0104588:	f0 
f0104589:	c7 44 24 04 5c 01 00 	movl   $0x15c,0x4(%esp)
f0104590:	00 
f0104591:	c7 04 24 ac 7d 10 f0 	movl   $0xf0107dac,(%esp)
f0104598:	e8 a3 ba ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f010459d:	e8 37 1c 00 00       	call   f01061d9 <cpunum>
f01045a2:	6b c0 74             	imul   $0x74,%eax,%eax
f01045a5:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01045ab:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f01045af:	75 2d                	jne    f01045de <trap+0xfc>
			env_free(curenv);
f01045b1:	e8 23 1c 00 00       	call   f01061d9 <cpunum>
f01045b6:	6b c0 74             	imul   $0x74,%eax,%eax
f01045b9:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01045bf:	89 04 24             	mov    %eax,(%esp)
f01045c2:	e8 bc f5 ff ff       	call   f0103b83 <env_free>
			curenv = NULL;
f01045c7:	e8 0d 1c 00 00       	call   f01061d9 <cpunum>
f01045cc:	6b c0 74             	imul   $0x74,%eax,%eax
f01045cf:	c7 80 28 d0 22 f0 00 	movl   $0x0,-0xfdd2fd8(%eax)
f01045d6:	00 00 00 
			sched_yield();
f01045d9:	e8 f4 03 00 00       	call   f01049d2 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f01045de:	e8 f6 1b 00 00       	call   f01061d9 <cpunum>
f01045e3:	6b c0 74             	imul   $0x74,%eax,%eax
f01045e6:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01045ec:	b9 11 00 00 00       	mov    $0x11,%ecx
f01045f1:	89 c7                	mov    %eax,%edi
f01045f3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f01045f5:	e8 df 1b 00 00       	call   f01061d9 <cpunum>
f01045fa:	6b c0 74             	imul   $0x74,%eax,%eax
f01045fd:	8b b0 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0104603:	89 35 60 ca 22 f0    	mov    %esi,0xf022ca60
	// LAB 3: Your code here.

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0104609:	8b 46 28             	mov    0x28(%esi),%eax
f010460c:	83 f8 27             	cmp    $0x27,%eax
f010460f:	75 19                	jne    f010462a <trap+0x148>
		cprintf("Spurious interrupt on irq 7\n");
f0104611:	c7 04 24 d8 7d 10 f0 	movl   $0xf0107dd8,(%esp)
f0104618:	e8 51 fa ff ff       	call   f010406e <cprintf>
		print_trapframe(tf);
f010461d:	89 34 24             	mov    %esi,(%esp)
f0104620:	e8 84 fc ff ff       	call   f01042a9 <print_trapframe>
f0104625:	e9 bc 00 00 00       	jmp    f01046e6 <trap+0x204>
	if (tf->tf_cs == GD_KT)
		panic("unhandled trap in kernel");
	else
		env_destroy(curenv);*/

	switch (tf->tf_trapno) {
f010462a:	83 f8 0e             	cmp    $0xe,%eax
f010462d:	74 1a                	je     f0104649 <trap+0x167>
f010462f:	83 f8 0e             	cmp    $0xe,%eax
f0104632:	77 07                	ja     f010463b <trap+0x159>
f0104634:	83 f8 03             	cmp    $0x3,%eax
f0104637:	74 21                	je     f010465a <trap+0x178>
f0104639:	eb 6a                	jmp    f01046a5 <trap+0x1c3>
f010463b:	83 f8 20             	cmp    $0x20,%eax
f010463e:	66 90                	xchg   %ax,%ax
f0104640:	74 57                	je     f0104699 <trap+0x1b7>
f0104642:	83 f8 30             	cmp    $0x30,%eax
f0104645:	74 20                	je     f0104667 <trap+0x185>
f0104647:	eb 5c                	jmp    f01046a5 <trap+0x1c3>
	case T_PGFLT:
	//if (tf->tf_trapno == T_PGFLT) {
		page_fault_handler(tf);
f0104649:	89 34 24             	mov    %esi,(%esp)
f010464c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104650:	e8 0a fe ff ff       	call   f010445f <page_fault_handler>
f0104655:	e9 8c 00 00 00       	jmp    f01046e6 <trap+0x204>
	//}
	//if (tf->tf_trapno == T_BRKPT) {
	case T_BRKPT:
		//cprintf("DEBUG breakpoint");
		//print_trapframe(tf);
		monitor(tf);
f010465a:	89 34 24             	mov    %esi,(%esp)
f010465d:	e8 3c c3 ff ff       	call   f010099e <monitor>
f0104662:	e9 7f 00 00 00       	jmp    f01046e6 <trap+0x204>
		//	asm volatile("int3");
		//page_fault_handler(tf);
		//return;
	//}
	case T_SYSCALL:
		tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f0104667:	8b 46 04             	mov    0x4(%esi),%eax
f010466a:	89 44 24 14          	mov    %eax,0x14(%esp)
f010466e:	8b 06                	mov    (%esi),%eax
f0104670:	89 44 24 10          	mov    %eax,0x10(%esp)
f0104674:	8b 46 10             	mov    0x10(%esi),%eax
f0104677:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010467b:	8b 46 18             	mov    0x18(%esi),%eax
f010467e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104682:	8b 46 14             	mov    0x14(%esi),%eax
f0104685:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104689:	8b 46 1c             	mov    0x1c(%esi),%eax
f010468c:	89 04 24             	mov    %eax,(%esp)
f010468f:	e8 3c 04 00 00       	call   f0104ad0 <syscall>
f0104694:	89 46 1c             	mov    %eax,0x1c(%esi)
f0104697:	eb 4d                	jmp    f01046e6 <trap+0x204>
					      tf->tf_regs.reg_ebx,
					      tf->tf_regs.reg_edi,
					      tf->tf_regs.reg_esi);
		return;
	case IRQ_OFFSET + IRQ_TIMER:
		lapic_eoi();
f0104699:	e8 88 1c 00 00       	call   f0106326 <lapic_eoi>
		sched_yield();
f010469e:	66 90                	xchg   %ax,%ax
f01046a0:	e8 2d 03 00 00       	call   f01049d2 <sched_yield>
		return;
	default:
		// Unexpected trap: The user process or the kernel has a bug.
		print_trapframe(tf);
f01046a5:	89 34 24             	mov    %esi,(%esp)
f01046a8:	e8 fc fb ff ff       	call   f01042a9 <print_trapframe>
		if (tf->tf_cs == GD_KT)
f01046ad:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01046b2:	75 1c                	jne    f01046d0 <trap+0x1ee>
			panic("unhandled trap in kernel");
f01046b4:	c7 44 24 08 f5 7d 10 	movl   $0xf0107df5,0x8(%esp)
f01046bb:	f0 
f01046bc:	c7 44 24 04 39 01 00 	movl   $0x139,0x4(%esp)
f01046c3:	00 
f01046c4:	c7 04 24 ac 7d 10 f0 	movl   $0xf0107dac,(%esp)
f01046cb:	e8 70 b9 ff ff       	call   f0100040 <_panic>
		else {
			env_destroy(curenv);
f01046d0:	e8 04 1b 00 00       	call   f01061d9 <cpunum>
f01046d5:	6b c0 74             	imul   $0x74,%eax,%eax
f01046d8:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01046de:	89 04 24             	mov    %eax,(%esp)
f01046e1:	e8 a2 f6 ff ff       	call   f0103d88 <env_destroy>
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f01046e6:	e8 ee 1a 00 00       	call   f01061d9 <cpunum>
f01046eb:	6b c0 74             	imul   $0x74,%eax,%eax
f01046ee:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f01046f5:	74 2a                	je     f0104721 <trap+0x23f>
f01046f7:	e8 dd 1a 00 00       	call   f01061d9 <cpunum>
f01046fc:	6b c0 74             	imul   $0x74,%eax,%eax
f01046ff:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104705:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104709:	75 16                	jne    f0104721 <trap+0x23f>
		env_run(curenv);
f010470b:	e8 c9 1a 00 00       	call   f01061d9 <cpunum>
f0104710:	6b c0 74             	imul   $0x74,%eax,%eax
f0104713:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104719:	89 04 24             	mov    %eax,(%esp)
f010471c:	e8 08 f7 ff ff       	call   f0103e29 <env_run>
	else
		sched_yield();
f0104721:	e8 ac 02 00 00       	call   f01049d2 <sched_yield>

f0104726 <handler0>:
 */

.data
.globl handlers
handlers:
TRAPHANDLER_NOEC(handler0, 0)
f0104726:	6a 00                	push   $0x0
f0104728:	6a 00                	push   $0x0
f010472a:	e9 7b 01 00 00       	jmp    f01048aa <_alltraps>
f010472f:	90                   	nop

f0104730 <handler1>:
TRAPHANDLER_NOEC(handler1, 1)
f0104730:	6a 00                	push   $0x0
f0104732:	6a 01                	push   $0x1
f0104734:	e9 71 01 00 00       	jmp    f01048aa <_alltraps>
f0104739:	90                   	nop

f010473a <handler2>:
TRAPHANDLER_NOEC(handler2, 2)
f010473a:	6a 00                	push   $0x0
f010473c:	6a 02                	push   $0x2
f010473e:	e9 67 01 00 00       	jmp    f01048aa <_alltraps>
f0104743:	90                   	nop

f0104744 <handler3>:
TRAPHANDLER_NOEC(handler3, 3)
f0104744:	6a 00                	push   $0x0
f0104746:	6a 03                	push   $0x3
f0104748:	e9 5d 01 00 00       	jmp    f01048aa <_alltraps>
f010474d:	90                   	nop

f010474e <handler4>:
TRAPHANDLER_NOEC(handler4, 4)
f010474e:	6a 00                	push   $0x0
f0104750:	6a 04                	push   $0x4
f0104752:	e9 53 01 00 00       	jmp    f01048aa <_alltraps>
f0104757:	90                   	nop

f0104758 <handler5>:
TRAPHANDLER_NOEC(handler5, 5)
f0104758:	6a 00                	push   $0x0
f010475a:	6a 05                	push   $0x5
f010475c:	e9 49 01 00 00       	jmp    f01048aa <_alltraps>
f0104761:	90                   	nop

f0104762 <handler6>:
TRAPHANDLER_NOEC(handler6, 6)
f0104762:	6a 00                	push   $0x0
f0104764:	6a 06                	push   $0x6
f0104766:	e9 3f 01 00 00       	jmp    f01048aa <_alltraps>
f010476b:	90                   	nop

f010476c <handler7>:
TRAPHANDLER_NOEC(handler7, 7)
f010476c:	6a 00                	push   $0x0
f010476e:	6a 07                	push   $0x7
f0104770:	e9 35 01 00 00       	jmp    f01048aa <_alltraps>
f0104775:	90                   	nop

f0104776 <handler8>:
TRAPHANDLER(handler8, 8)
f0104776:	6a 08                	push   $0x8
f0104778:	e9 2d 01 00 00       	jmp    f01048aa <_alltraps>
f010477d:	90                   	nop

f010477e <handler9>:
TRAPHANDLER_NOEC(handler9, 9)
f010477e:	6a 00                	push   $0x0
f0104780:	6a 09                	push   $0x9
f0104782:	e9 23 01 00 00       	jmp    f01048aa <_alltraps>
f0104787:	90                   	nop

f0104788 <handler10>:
TRAPHANDLER(handler10, 10)
f0104788:	6a 0a                	push   $0xa
f010478a:	e9 1b 01 00 00       	jmp    f01048aa <_alltraps>
f010478f:	90                   	nop

f0104790 <handler11>:
TRAPHANDLER(handler11, 11)
f0104790:	6a 0b                	push   $0xb
f0104792:	e9 13 01 00 00       	jmp    f01048aa <_alltraps>
f0104797:	90                   	nop

f0104798 <handler12>:
TRAPHANDLER(handler12, 12)
f0104798:	6a 0c                	push   $0xc
f010479a:	e9 0b 01 00 00       	jmp    f01048aa <_alltraps>
f010479f:	90                   	nop

f01047a0 <handler13>:
TRAPHANDLER(handler13, 13)
f01047a0:	6a 0d                	push   $0xd
f01047a2:	e9 03 01 00 00       	jmp    f01048aa <_alltraps>
f01047a7:	90                   	nop

f01047a8 <handler14>:
TRAPHANDLER(handler14, 14)
f01047a8:	6a 0e                	push   $0xe
f01047aa:	e9 fb 00 00 00       	jmp    f01048aa <_alltraps>
f01047af:	90                   	nop

f01047b0 <handler15>:
TRAPHANDLER_NOEC(handler15, 15)
f01047b0:	6a 00                	push   $0x0
f01047b2:	6a 0f                	push   $0xf
f01047b4:	e9 f1 00 00 00       	jmp    f01048aa <_alltraps>
f01047b9:	90                   	nop

f01047ba <handler16>:
TRAPHANDLER_NOEC(handler16, 16)
f01047ba:	6a 00                	push   $0x0
f01047bc:	6a 10                	push   $0x10
f01047be:	e9 e7 00 00 00       	jmp    f01048aa <_alltraps>
f01047c3:	90                   	nop

f01047c4 <handler17>:
TRAPHANDLER(handler17, 17)
f01047c4:	6a 11                	push   $0x11
f01047c6:	e9 df 00 00 00       	jmp    f01048aa <_alltraps>
f01047cb:	90                   	nop

f01047cc <handler18>:
TRAPHANDLER_NOEC(handler18, 18)
f01047cc:	6a 00                	push   $0x0
f01047ce:	6a 12                	push   $0x12
f01047d0:	e9 d5 00 00 00       	jmp    f01048aa <_alltraps>
f01047d5:	90                   	nop

f01047d6 <handler19>:
TRAPHANDLER_NOEC(handler19, 19)
f01047d6:	6a 00                	push   $0x0
f01047d8:	6a 13                	push   $0x13
f01047da:	e9 cb 00 00 00       	jmp    f01048aa <_alltraps>
f01047df:	90                   	nop

f01047e0 <handler20>:
TRAPHANDLER_NOEC(handler20, 20)
f01047e0:	6a 00                	push   $0x0
f01047e2:	6a 14                	push   $0x14
f01047e4:	e9 c1 00 00 00       	jmp    f01048aa <_alltraps>
f01047e9:	90                   	nop

f01047ea <handler21>:
TRAPHANDLER_NOEC(handler21, 21)
f01047ea:	6a 00                	push   $0x0
f01047ec:	6a 15                	push   $0x15
f01047ee:	e9 b7 00 00 00       	jmp    f01048aa <_alltraps>
f01047f3:	90                   	nop

f01047f4 <handler22>:
TRAPHANDLER_NOEC(handler22, 22)
f01047f4:	6a 00                	push   $0x0
f01047f6:	6a 16                	push   $0x16
f01047f8:	e9 ad 00 00 00       	jmp    f01048aa <_alltraps>
f01047fd:	90                   	nop

f01047fe <handler23>:
TRAPHANDLER_NOEC(handler23, 23)
f01047fe:	6a 00                	push   $0x0
f0104800:	6a 17                	push   $0x17
f0104802:	e9 a3 00 00 00       	jmp    f01048aa <_alltraps>
f0104807:	90                   	nop

f0104808 <handler24>:
TRAPHANDLER_NOEC(handler24, 24)
f0104808:	6a 00                	push   $0x0
f010480a:	6a 18                	push   $0x18
f010480c:	e9 99 00 00 00       	jmp    f01048aa <_alltraps>
f0104811:	90                   	nop

f0104812 <handler25>:
TRAPHANDLER_NOEC(handler25, 25)
f0104812:	6a 00                	push   $0x0
f0104814:	6a 19                	push   $0x19
f0104816:	e9 8f 00 00 00       	jmp    f01048aa <_alltraps>
f010481b:	90                   	nop

f010481c <handler26>:
TRAPHANDLER_NOEC(handler26, 26)
f010481c:	6a 00                	push   $0x0
f010481e:	6a 1a                	push   $0x1a
f0104820:	e9 85 00 00 00       	jmp    f01048aa <_alltraps>
f0104825:	90                   	nop

f0104826 <handler27>:
TRAPHANDLER_NOEC(handler27, 27)
f0104826:	6a 00                	push   $0x0
f0104828:	6a 1b                	push   $0x1b
f010482a:	eb 7e                	jmp    f01048aa <_alltraps>

f010482c <handler28>:
TRAPHANDLER_NOEC(handler28, 28)
f010482c:	6a 00                	push   $0x0
f010482e:	6a 1c                	push   $0x1c
f0104830:	eb 78                	jmp    f01048aa <_alltraps>

f0104832 <handler29>:
TRAPHANDLER_NOEC(handler29, 29)
f0104832:	6a 00                	push   $0x0
f0104834:	6a 1d                	push   $0x1d
f0104836:	eb 72                	jmp    f01048aa <_alltraps>

f0104838 <handler30>:
TRAPHANDLER_NOEC(handler30, 30)
f0104838:	6a 00                	push   $0x0
f010483a:	6a 1e                	push   $0x1e
f010483c:	eb 6c                	jmp    f01048aa <_alltraps>

f010483e <handler31>:
TRAPHANDLER_NOEC(handler31, 31)
f010483e:	6a 00                	push   $0x0
f0104840:	6a 1f                	push   $0x1f
f0104842:	eb 66                	jmp    f01048aa <_alltraps>

f0104844 <handler32>:
TRAPHANDLER_NOEC(handler32, 32)
f0104844:	6a 00                	push   $0x0
f0104846:	6a 20                	push   $0x20
f0104848:	eb 60                	jmp    f01048aa <_alltraps>

f010484a <handler33>:
TRAPHANDLER_NOEC(handler33, 33)
f010484a:	6a 00                	push   $0x0
f010484c:	6a 21                	push   $0x21
f010484e:	eb 5a                	jmp    f01048aa <_alltraps>

f0104850 <handler34>:
TRAPHANDLER_NOEC(handler34, 34)
f0104850:	6a 00                	push   $0x0
f0104852:	6a 22                	push   $0x22
f0104854:	eb 54                	jmp    f01048aa <_alltraps>

f0104856 <handler35>:
TRAPHANDLER_NOEC(handler35, 35)
f0104856:	6a 00                	push   $0x0
f0104858:	6a 23                	push   $0x23
f010485a:	eb 4e                	jmp    f01048aa <_alltraps>

f010485c <handler36>:
TRAPHANDLER_NOEC(handler36, 36)
f010485c:	6a 00                	push   $0x0
f010485e:	6a 24                	push   $0x24
f0104860:	eb 48                	jmp    f01048aa <_alltraps>

f0104862 <handler37>:
TRAPHANDLER_NOEC(handler37, 37)
f0104862:	6a 00                	push   $0x0
f0104864:	6a 25                	push   $0x25
f0104866:	eb 42                	jmp    f01048aa <_alltraps>

f0104868 <handler38>:
TRAPHANDLER_NOEC(handler38, 38)
f0104868:	6a 00                	push   $0x0
f010486a:	6a 26                	push   $0x26
f010486c:	eb 3c                	jmp    f01048aa <_alltraps>

f010486e <handler39>:
TRAPHANDLER_NOEC(handler39, 39)
f010486e:	6a 00                	push   $0x0
f0104870:	6a 27                	push   $0x27
f0104872:	eb 36                	jmp    f01048aa <_alltraps>

f0104874 <handler40>:
TRAPHANDLER_NOEC(handler40, 40)
f0104874:	6a 00                	push   $0x0
f0104876:	6a 28                	push   $0x28
f0104878:	eb 30                	jmp    f01048aa <_alltraps>

f010487a <handler41>:
TRAPHANDLER_NOEC(handler41, 41)
f010487a:	6a 00                	push   $0x0
f010487c:	6a 29                	push   $0x29
f010487e:	eb 2a                	jmp    f01048aa <_alltraps>

f0104880 <handler42>:
TRAPHANDLER_NOEC(handler42, 42)
f0104880:	6a 00                	push   $0x0
f0104882:	6a 2a                	push   $0x2a
f0104884:	eb 24                	jmp    f01048aa <_alltraps>

f0104886 <handler43>:
TRAPHANDLER_NOEC(handler43, 43)
f0104886:	6a 00                	push   $0x0
f0104888:	6a 2b                	push   $0x2b
f010488a:	eb 1e                	jmp    f01048aa <_alltraps>

f010488c <handler44>:
TRAPHANDLER_NOEC(handler44, 44)
f010488c:	6a 00                	push   $0x0
f010488e:	6a 2c                	push   $0x2c
f0104890:	eb 18                	jmp    f01048aa <_alltraps>

f0104892 <handler45>:
TRAPHANDLER_NOEC(handler45, 45)
f0104892:	6a 00                	push   $0x0
f0104894:	6a 2d                	push   $0x2d
f0104896:	eb 12                	jmp    f01048aa <_alltraps>

f0104898 <handler46>:
TRAPHANDLER_NOEC(handler46, 46)
f0104898:	6a 00                	push   $0x0
f010489a:	6a 2e                	push   $0x2e
f010489c:	eb 0c                	jmp    f01048aa <_alltraps>

f010489e <handler47>:
TRAPHANDLER_NOEC(handler47, 47)
f010489e:	6a 00                	push   $0x0
f01048a0:	6a 2f                	push   $0x2f
f01048a2:	eb 06                	jmp    f01048aa <_alltraps>

f01048a4 <handler48>:
TRAPHANDLER_NOEC(handler48, 48)
f01048a4:	6a 00                	push   $0x0
f01048a6:	6a 30                	push   $0x30
f01048a8:	eb 00                	jmp    f01048aa <_alltraps>

f01048aa <_alltraps>:
 */

.text
_alltraps:

pushl %ds
f01048aa:	1e                   	push   %ds
pushl %es
f01048ab:	06                   	push   %es
pushal
f01048ac:	60                   	pusha  

movl $GD_KD, %ax
f01048ad:	b8 10 00 00 00       	mov    $0x10,%eax
movw %ax, %es
f01048b2:	8e c0                	mov    %eax,%es
movw %ax, %ds
f01048b4:	8e d8                	mov    %eax,%ds

pushl %esp
f01048b6:	54                   	push   %esp
call trap
f01048b7:	e8 26 fc ff ff       	call   f01044e2 <trap>

f01048bc <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f01048bc:	55                   	push   %ebp
f01048bd:	89 e5                	mov    %esp,%ebp
f01048bf:	53                   	push   %ebx
f01048c0:	83 ec 14             	sub    $0x14,%esp
f01048c3:	a1 48 c2 22 f0       	mov    0xf022c248,%eax
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01048c8:	bb 00 00 00 00       	mov    $0x0,%ebx
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f01048cd:	8b 48 54             	mov    0x54(%eax),%ecx
f01048d0:	8d 51 ff             	lea    -0x1(%ecx),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
f01048d3:	83 fa 02             	cmp    $0x2,%edx
f01048d6:	76 13                	jbe    f01048eb <sched_halt+0x2f>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01048d8:	83 c3 01             	add    $0x1,%ebx
f01048db:	83 c0 7c             	add    $0x7c,%eax
f01048de:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01048e4:	75 e7                	jne    f01048cd <sched_halt+0x11>
f01048e6:	e9 c4 00 00 00       	jmp    f01049af <sched_halt+0xf3>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	cprintf("i is %d, and NENV is %d\n", i, NENV);
f01048eb:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
f01048f2:	00 
f01048f3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01048f7:	c7 04 24 10 80 10 f0 	movl   $0xf0108010,(%esp)
f01048fe:	e8 6b f7 ff ff       	call   f010406e <cprintf>
	if (i == NENV) {
f0104903:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0104909:	75 1a                	jne    f0104925 <sched_halt+0x69>
		cprintf("No runnable environments in the system!\n");
f010490b:	c7 04 24 50 80 10 f0 	movl   $0xf0108050,(%esp)
f0104912:	e8 57 f7 ff ff       	call   f010406e <cprintf>
		while (1)
			monitor(NULL);
f0104917:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010491e:	e8 7b c0 ff ff       	call   f010099e <monitor>
f0104923:	eb f2                	jmp    f0104917 <sched_halt+0x5b>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0104925:	e8 af 18 00 00       	call   f01061d9 <cpunum>
f010492a:	6b c0 74             	imul   $0x74,%eax,%eax
f010492d:	c7 80 28 d0 22 f0 00 	movl   $0x0,-0xfdd2fd8(%eax)
f0104934:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0104937:	a1 8c ce 22 f0       	mov    0xf022ce8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010493c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104941:	77 20                	ja     f0104963 <sched_halt+0xa7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104943:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104947:	c7 44 24 08 08 69 10 	movl   $0xf0106908,0x8(%esp)
f010494e:	f0 
f010494f:	c7 44 24 04 6e 00 00 	movl   $0x6e,0x4(%esp)
f0104956:	00 
f0104957:	c7 04 24 29 80 10 f0 	movl   $0xf0108029,(%esp)
f010495e:	e8 dd b6 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0104963:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0104968:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f010496b:	e8 69 18 00 00       	call   f01061d9 <cpunum>
f0104970:	6b d0 74             	imul   $0x74,%eax,%edx
f0104973:	81 c2 20 d0 22 f0    	add    $0xf022d020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0104979:	b8 02 00 00 00       	mov    $0x2,%eax
f010497e:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0104982:	c7 04 24 80 14 12 f0 	movl   $0xf0121480,(%esp)
f0104989:	e8 75 1b 00 00       	call   f0106503 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f010498e:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104990:	e8 44 18 00 00       	call   f01061d9 <cpunum>
f0104995:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f0104998:	8b 80 30 d0 22 f0    	mov    -0xfdd2fd0(%eax),%eax
f010499e:	bd 00 00 00 00       	mov    $0x0,%ebp
f01049a3:	89 c4                	mov    %eax,%esp
f01049a5:	6a 00                	push   $0x0
f01049a7:	6a 00                	push   $0x0
f01049a9:	fb                   	sti    
f01049aa:	f4                   	hlt    
f01049ab:	eb fd                	jmp    f01049aa <sched_halt+0xee>
f01049ad:	eb 1d                	jmp    f01049cc <sched_halt+0x110>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	cprintf("i is %d, and NENV is %d\n", i, NENV);
f01049af:	c7 44 24 08 00 04 00 	movl   $0x400,0x8(%esp)
f01049b6:	00 
f01049b7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01049bb:	c7 04 24 10 80 10 f0 	movl   $0xf0108010,(%esp)
f01049c2:	e8 a7 f6 ff ff       	call   f010406e <cprintf>
f01049c7:	e9 3f ff ff ff       	jmp    f010490b <sched_halt+0x4f>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f01049cc:	83 c4 14             	add    $0x14,%esp
f01049cf:	5b                   	pop    %ebx
f01049d0:	5d                   	pop    %ebp
f01049d1:	c3                   	ret    

f01049d2 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f01049d2:	55                   	push   %ebp
f01049d3:	89 e5                	mov    %esp,%ebp
f01049d5:	57                   	push   %edi
f01049d6:	56                   	push   %esi
f01049d7:	53                   	push   %ebx
f01049d8:	83 ec 1c             	sub    $0x1c,%esp

	// LAB 4: Your code here.


    int i, cur=0;
    if (curenv) cur=ENVX(curenv->env_id);
f01049db:	e8 f9 17 00 00       	call   f01061d9 <cpunum>
f01049e0:	6b c0 74             	imul   $0x74,%eax,%eax
        else cur = 0;
f01049e3:	bf 00 00 00 00       	mov    $0x0,%edi

	// LAB 4: Your code here.


    int i, cur=0;
    if (curenv) cur=ENVX(curenv->env_id);
f01049e8:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f01049ef:	74 17                	je     f0104a08 <sched_yield+0x36>
f01049f1:	e8 e3 17 00 00       	call   f01061d9 <cpunum>
f01049f6:	6b c0 74             	imul   $0x74,%eax,%eax
f01049f9:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f01049ff:	8b 78 48             	mov    0x48(%eax),%edi
f0104a02:	81 e7 ff 03 00 00    	and    $0x3ff,%edi
        else cur = 0;
    for (i = 0; i < NENV; ++i) {
f0104a08:	be 00 00 00 00       	mov    $0x0,%esi
f0104a0d:	8d 1c 3e             	lea    (%esi,%edi,1),%ebx
        int j = (cur+i) % NENV;
f0104a10:	89 d8                	mov    %ebx,%eax
f0104a12:	c1 f8 1f             	sar    $0x1f,%eax
f0104a15:	c1 e8 16             	shr    $0x16,%eax
f0104a18:	01 c3                	add    %eax,%ebx
f0104a1a:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0104a20:	29 c3                	sub    %eax,%ebx
f0104a22:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
        if (j < 2) cprintf("envs[%x].env_status: %x\n", j, envs[j].env_status);
f0104a25:	83 fb 01             	cmp    $0x1,%ebx
f0104a28:	7f 20                	jg     f0104a4a <sched_yield+0x78>
f0104a2a:	6b c3 7c             	imul   $0x7c,%ebx,%eax
f0104a2d:	03 05 48 c2 22 f0    	add    0xf022c248,%eax
f0104a33:	8b 40 54             	mov    0x54(%eax),%eax
f0104a36:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104a3a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104a3e:	c7 04 24 36 80 10 f0 	movl   $0xf0108036,(%esp)
f0104a45:	e8 24 f6 ff ff       	call   f010406e <cprintf>
        if (envs[j].env_status == ENV_RUNNABLE) {
f0104a4a:	6b c3 7c             	imul   $0x7c,%ebx,%eax
f0104a4d:	89 c3                	mov    %eax,%ebx
f0104a4f:	8b 15 48 c2 22 f0    	mov    0xf022c248,%edx
f0104a55:	83 7c 02 54 02       	cmpl   $0x2,0x54(%edx,%eax,1)
f0104a5a:	75 20                	jne    f0104a7c <sched_yield+0xaa>
            if (j == 1) 
f0104a5c:	83 7d e4 01          	cmpl   $0x1,-0x1c(%ebp)
f0104a60:	75 0c                	jne    f0104a6e <sched_yield+0x9c>
                cprintf("\n");
f0104a62:	c7 04 24 a3 71 10 f0 	movl   $0xf01071a3,(%esp)
f0104a69:	e8 00 f6 ff ff       	call   f010406e <cprintf>
            env_run(envs + j);
f0104a6e:	03 1d 48 c2 22 f0    	add    0xf022c248,%ebx
f0104a74:	89 1c 24             	mov    %ebx,(%esp)
f0104a77:	e8 ad f3 ff ff       	call   f0103e29 <env_run>


    int i, cur=0;
    if (curenv) cur=ENVX(curenv->env_id);
        else cur = 0;
    for (i = 0; i < NENV; ++i) {
f0104a7c:	83 c6 01             	add    $0x1,%esi
f0104a7f:	81 fe 00 04 00 00    	cmp    $0x400,%esi
f0104a85:	75 86                	jne    f0104a0d <sched_yield+0x3b>
            if (j == 1) 
                cprintf("\n");
            env_run(envs + j);
        }
    }
    if (curenv && curenv->env_status == ENV_RUNNING)
f0104a87:	e8 4d 17 00 00       	call   f01061d9 <cpunum>
f0104a8c:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a8f:	83 b8 28 d0 22 f0 00 	cmpl   $0x0,-0xfdd2fd8(%eax)
f0104a96:	74 2a                	je     f0104ac2 <sched_yield+0xf0>
f0104a98:	e8 3c 17 00 00       	call   f01061d9 <cpunum>
f0104a9d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104aa0:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104aa6:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104aaa:	75 16                	jne    f0104ac2 <sched_yield+0xf0>
        env_run(curenv);
f0104aac:	e8 28 17 00 00       	call   f01061d9 <cpunum>
f0104ab1:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ab4:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104aba:	89 04 24             	mov    %eax,(%esp)
f0104abd:	e8 67 f3 ff ff       	call   f0103e29 <env_run>
		return;
	}*/

	// no runnable environments were found...
	// sched_halt never returns
	sched_halt();
f0104ac2:	e8 f5 fd ff ff       	call   f01048bc <sched_halt>
}
f0104ac7:	83 c4 1c             	add    $0x1c,%esp
f0104aca:	5b                   	pop    %ebx
f0104acb:	5e                   	pop    %esi
f0104acc:	5f                   	pop    %edi
f0104acd:	5d                   	pop    %ebp
f0104ace:	c3                   	ret    
f0104acf:	90                   	nop

f0104ad0 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104ad0:	55                   	push   %ebp
f0104ad1:	89 e5                	mov    %esp,%ebp
f0104ad3:	57                   	push   %edi
f0104ad4:	56                   	push   %esi
f0104ad5:	53                   	push   %ebx
f0104ad6:	83 ec 2c             	sub    $0x2c,%esp
f0104ad9:	8b 45 08             	mov    0x8(%ebp),%eax
	// LAB 3: Your code here.

	//panic("syscall not implemented");
	int ret = 0;

	switch (syscallno) {
f0104adc:	83 f8 0a             	cmp    $0xa,%eax
f0104adf:	0f 87 e5 04 00 00    	ja     f0104fca <syscall+0x4fa>
f0104ae5:	ff 24 85 04 82 10 f0 	jmp    *-0xfef7dfc(,%eax,4)
	// Destroy the environment if not.

	// LAB 3: Your code here.

	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104aec:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104aef:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104af3:	8b 45 10             	mov    0x10(%ebp),%eax
f0104af6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104afa:	c7 04 24 79 80 10 f0 	movl   $0xf0108079,(%esp)
f0104b01:	e8 68 f5 ff ff       	call   f010406e <cprintf>
	int ret = 0;

	switch (syscallno) {
	case SYS_cputs:
		sys_cputs((char*)a1, a2);
		ret = 0;
f0104b06:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b0b:	e9 bf 04 00 00       	jmp    f0104fcf <syscall+0x4ff>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104b10:	e8 2b bb ff ff       	call   f0100640 <cons_getc>
		sys_cputs((char*)a1, a2);
		ret = 0;
		break;
	case SYS_cgetc:
		ret = sys_cgetc();
		break;
f0104b15:	e9 b5 04 00 00       	jmp    f0104fcf <syscall+0x4ff>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104b1a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104b20:	e8 b4 16 00 00       	call   f01061d9 <cpunum>
f0104b25:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b28:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104b2e:	8b 40 48             	mov    0x48(%eax),%eax
	case SYS_cgetc:
		ret = sys_cgetc();
		break;
	case SYS_getenvid:
		ret = sys_getenvid();
		break;
f0104b31:	e9 99 04 00 00       	jmp    f0104fcf <syscall+0x4ff>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104b36:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104b3d:	00 
f0104b3e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104b41:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b45:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104b48:	89 04 24             	mov    %eax,(%esp)
f0104b4b:	e8 c8 eb ff ff       	call   f0103718 <envid2env>
f0104b50:	85 c0                	test   %eax,%eax
f0104b52:	78 69                	js     f0104bbd <syscall+0xed>
		return r;
	if (e == curenv)
f0104b54:	e8 80 16 00 00       	call   f01061d9 <cpunum>
f0104b59:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104b5c:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b5f:	39 90 28 d0 22 f0    	cmp    %edx,-0xfdd2fd8(%eax)
f0104b65:	75 23                	jne    f0104b8a <syscall+0xba>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104b67:	e8 6d 16 00 00       	call   f01061d9 <cpunum>
f0104b6c:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b6f:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104b75:	8b 40 48             	mov    0x48(%eax),%eax
f0104b78:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b7c:	c7 04 24 7e 80 10 f0 	movl   $0xf010807e,(%esp)
f0104b83:	e8 e6 f4 ff ff       	call   f010406e <cprintf>
f0104b88:	eb 28                	jmp    f0104bb2 <syscall+0xe2>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104b8a:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104b8d:	e8 47 16 00 00       	call   f01061d9 <cpunum>
f0104b92:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104b96:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b99:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104b9f:	8b 40 48             	mov    0x48(%eax),%eax
f0104ba2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ba6:	c7 04 24 99 80 10 f0 	movl   $0xf0108099,(%esp)
f0104bad:	e8 bc f4 ff ff       	call   f010406e <cprintf>
	env_destroy(e);
f0104bb2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104bb5:	89 04 24             	mov    %eax,(%esp)
f0104bb8:	e8 cb f1 ff ff       	call   f0103d88 <env_destroy>
	case SYS_getenvid:
		ret = sys_getenvid();
		break;
	case SYS_env_destroy:
		sys_env_destroy(a1);
		ret = 0;
f0104bbd:	b8 00 00 00 00       	mov    $0x0,%eax
f0104bc2:	e9 08 04 00 00       	jmp    f0104fcf <syscall+0x4ff>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104bc7:	e8 06 fe ff ff       	call   f01049d2 <sched_yield>
	// status is set to ENV_NOT_RUNNABLE, and the register set is copied
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	cprintf("DEBUG sys_exofork() called\n");
f0104bcc:	c7 04 24 b1 80 10 f0 	movl   $0xf01080b1,(%esp)
f0104bd3:	e8 96 f4 ff ff       	call   f010406e <cprintf>
	struct Env * e;
	int err = env_alloc(&e, curenv->env_id);
f0104bd8:	e8 fc 15 00 00       	call   f01061d9 <cpunum>
f0104bdd:	6b c0 74             	imul   $0x74,%eax,%eax
f0104be0:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f0104be6:	8b 40 48             	mov    0x48(%eax),%eax
f0104be9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104bed:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104bf0:	89 04 24             	mov    %eax,(%esp)
f0104bf3:	e8 50 ec ff ff       	call   f0103848 <env_alloc>
f0104bf8:	89 c3                	mov    %eax,%ebx
	if (err) {
f0104bfa:	85 c0                	test   %eax,%eax
f0104bfc:	74 17                	je     f0104c15 <syscall+0x145>
		cprintf("1 err %d", err);
f0104bfe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c02:	c7 04 24 cd 80 10 f0 	movl   $0xf01080cd,(%esp)
f0104c09:	e8 60 f4 ff ff       	call   f010406e <cprintf>
		return err;
f0104c0e:	89 d8                	mov    %ebx,%eax
f0104c10:	e9 ba 03 00 00       	jmp    f0104fcf <syscall+0x4ff>
	}

	e->env_status = ENV_NOT_RUNNABLE;
f0104c15:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104c18:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)
	e->env_tf = curenv->env_tf;
f0104c1f:	e8 b5 15 00 00       	call   f01061d9 <cpunum>
f0104c24:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c27:	8b b0 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%esi
f0104c2d:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104c32:	89 df                	mov    %ebx,%edi
f0104c34:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	e->env_tf.tf_regs.reg_eax = 0; //tweak
f0104c36:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104c39:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return e->env_id;
f0104c40:	8b 40 48             	mov    0x48(%eax),%eax
		break;
	case SYS_yield:
		sys_yield();
		break;
	case SYS_exofork:
		return sys_exofork();
f0104c43:	e9 87 03 00 00       	jmp    f0104fcf <syscall+0x4ff>
	//   If page_insert() fails, remember to free the page you
	//   allocated!

	// LAB 4: Your code here.

	cprintf("DEBUG sys_page_alloc() called\n");
f0104c48:	c7 04 24 74 81 10 f0 	movl   $0xf0108174,(%esp)
f0104c4f:	e8 1a f4 ff ff       	call   f010406e <cprintf>
	struct Env *e;

	int err = envid2env(envid, &e, 1);
f0104c54:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104c5b:	00 
f0104c5c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104c5f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c63:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104c66:	89 04 24             	mov    %eax,(%esp)
f0104c69:	e8 aa ea ff ff       	call   f0103718 <envid2env>
f0104c6e:	89 c3                	mov    %eax,%ebx
	if (err) {
f0104c70:	85 c0                	test   %eax,%eax
f0104c72:	74 17                	je     f0104c8b <syscall+0x1bb>
		cprintf("4 err %d", err);
f0104c74:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104c78:	c7 04 24 d6 80 10 f0 	movl   $0xf01080d6,(%esp)
f0104c7f:	e8 ea f3 ff ff       	call   f010406e <cprintf>
		return err;	//bad environment
f0104c84:	89 d8                	mov    %ebx,%eax
f0104c86:	e9 44 03 00 00       	jmp    f0104fcf <syscall+0x4ff>
	}

	if (va >= (void*) UTOP) {
f0104c8b:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104c92:	76 16                	jbe    f0104caa <syscall+0x1da>
		cprintf("5 err");
f0104c94:	c7 04 24 df 80 10 f0 	movl   $0xf01080df,(%esp)
f0104c9b:	e8 ce f3 ff ff       	call   f010406e <cprintf>
		return -E_INVAL;
f0104ca0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104ca5:	e9 25 03 00 00       	jmp    f0104fcf <syscall+0x4ff>
	}

	int flag = PTE_U | PTE_P;
	if ((perm & flag) != flag) {
f0104caa:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cad:	83 e0 05             	and    $0x5,%eax
f0104cb0:	83 f8 05             	cmp    $0x5,%eax
f0104cb3:	74 16                	je     f0104ccb <syscall+0x1fb>
		cprintf("6 err");
f0104cb5:	c7 04 24 e5 80 10 f0 	movl   $0xf01080e5,(%esp)
f0104cbc:	e8 ad f3 ff ff       	call   f010406e <cprintf>
		return -E_INVAL;
f0104cc1:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104cc6:	e9 04 03 00 00       	jmp    f0104fcf <syscall+0x4ff>
	}

	struct PageInfo *pag = page_alloc(ALLOC_ZERO);
f0104ccb:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0104cd2:	e8 03 c4 ff ff       	call   f01010da <page_alloc>
f0104cd7:	89 c3                	mov    %eax,%ebx
	if (!pag) {
f0104cd9:	85 c0                	test   %eax,%eax
f0104cdb:	75 16                	jne    f0104cf3 <syscall+0x223>
		cprintf("7 err");
f0104cdd:	c7 04 24 55 81 10 f0 	movl   $0xf0108155,(%esp)
f0104ce4:	e8 85 f3 ff ff       	call   f010406e <cprintf>
		return -E_NO_MEM;
f0104ce9:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0104cee:	e9 dc 02 00 00       	jmp    f0104fcf <syscall+0x4ff>
	}

	pag->pp_ref++;
f0104cf3:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	err = page_insert(e->env_pgdir, pag, va, perm);
f0104cf8:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cfb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104cff:	8b 45 10             	mov    0x10(%ebp),%eax
f0104d02:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104d06:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104d0a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104d0d:	8b 40 60             	mov    0x60(%eax),%eax
f0104d10:	89 04 24             	mov    %eax,(%esp)
f0104d13:	e8 84 c7 ff ff       	call   f010149c <page_insert>
f0104d18:	89 c6                	mov    %eax,%esi
	if (err) {
f0104d1a:	85 f6                	test   %esi,%esi
f0104d1c:	0f 84 ad 02 00 00    	je     f0104fcf <syscall+0x4ff>
		page_free(pag);
f0104d22:	89 1c 24             	mov    %ebx,(%esp)
f0104d25:	e8 3b c4 ff ff       	call   f0101165 <page_free>
		cprintf("8 err %d", err);
f0104d2a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0104d2e:	c7 04 24 eb 80 10 f0 	movl   $0xf01080eb,(%esp)
f0104d35:	e8 34 f3 ff ff       	call   f010406e <cprintf>
		return err;
f0104d3a:	89 f0                	mov    %esi,%eax
		break;
	case SYS_exofork:
		return sys_exofork();
		break;
	case SYS_page_alloc:
		return sys_page_alloc(a1, (void*)a2, a3);
f0104d3c:	e9 8e 02 00 00       	jmp    f0104fcf <syscall+0x4ff>
	//   Use the third argument to page_lookup() to
	//   check the current permissions on the page.

	// LAB 4: Your code here.

	cprintf("DEBUG sys_page_map() called\n");
f0104d41:	c7 04 24 f4 80 10 f0 	movl   $0xf01080f4,(%esp)
f0104d48:	e8 21 f3 ff ff       	call   f010406e <cprintf>
	struct Env *se, *de;

	int err = envid2env(srcenvid, &se, 1);
f0104d4d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104d54:	00 
f0104d55:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104d58:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d5c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d5f:	89 04 24             	mov    %eax,(%esp)
f0104d62:	e8 b1 e9 ff ff       	call   f0103718 <envid2env>
f0104d67:	89 c3                	mov    %eax,%ebx
	if (err) {
f0104d69:	85 c0                	test   %eax,%eax
f0104d6b:	74 17                	je     f0104d84 <syscall+0x2b4>
		cprintf("9 err %d", err);
f0104d6d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d71:	c7 04 24 11 81 10 f0 	movl   $0xf0108111,(%esp)
f0104d78:	e8 f1 f2 ff ff       	call   f010406e <cprintf>
		return err;	//bad environment
f0104d7d:	89 d8                	mov    %ebx,%eax
f0104d7f:	e9 4b 02 00 00       	jmp    f0104fcf <syscall+0x4ff>
	}

	err = envid2env(dstenvid, &de, 1);
f0104d84:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104d8b:	00 
f0104d8c:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104d8f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d93:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d96:	89 04 24             	mov    %eax,(%esp)
f0104d99:	e8 7a e9 ff ff       	call   f0103718 <envid2env>
f0104d9e:	89 c3                	mov    %eax,%ebx
	if (err) {
f0104da0:	85 c0                	test   %eax,%eax
f0104da2:	74 17                	je     f0104dbb <syscall+0x2eb>
		cprintf("10 err %d", err);
f0104da4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104da8:	c7 04 24 1a 81 10 f0 	movl   $0xf010811a,(%esp)
f0104daf:	e8 ba f2 ff ff       	call   f010406e <cprintf>
		return err;	//bad environment
f0104db4:	89 d8                	mov    %ebx,%eax
f0104db6:	e9 14 02 00 00       	jmp    f0104fcf <syscall+0x4ff>
	}

	// -E_INVAL if srcva >= UTOP or srcva is not page-aligned,
	// or dstva >= UTOP or dstva is not page-aligned.
	if (srcva>=(void*)UTOP || dstva>=(void*)UTOP || ROUNDDOWN(srcva,PGSIZE)!=srcva || ROUNDDOWN(dstva,PGSIZE)!=dstva) {
f0104dbb:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104dc2:	77 23                	ja     f0104de7 <syscall+0x317>
f0104dc4:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104dcb:	77 1a                	ja     f0104de7 <syscall+0x317>
f0104dcd:	8b 45 10             	mov    0x10(%ebp),%eax
f0104dd0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0104dd5:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104dd8:	75 0d                	jne    f0104de7 <syscall+0x317>
f0104dda:	8b 45 18             	mov    0x18(%ebp),%eax
f0104ddd:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0104de2:	39 45 18             	cmp    %eax,0x18(%ebp)
f0104de5:	74 16                	je     f0104dfd <syscall+0x32d>
		cprintf("11 err");
f0104de7:	c7 04 24 24 81 10 f0 	movl   $0xf0108124,(%esp)
f0104dee:	e8 7b f2 ff ff       	call   f010406e <cprintf>
		return -E_INVAL;
f0104df3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104df8:	e9 d2 01 00 00       	jmp    f0104fcf <syscall+0x4ff>
	}

	// -E_INVAL is srcva is not mapped in srcenvid's address space.
	pte_t *pte;
	struct PageInfo *pag = page_lookup(se->env_pgdir, srcva, &pte);
f0104dfd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104e00:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104e04:	8b 45 10             	mov    0x10(%ebp),%eax
f0104e07:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e0b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104e0e:	8b 40 60             	mov    0x60(%eax),%eax
f0104e11:	89 04 24             	mov    %eax,(%esp)
f0104e14:	e8 86 c5 ff ff       	call   f010139f <page_lookup>
	if (!pag) {
f0104e19:	85 c0                	test   %eax,%eax
f0104e1b:	75 16                	jne    f0104e33 <syscall+0x363>
		cprintf("12 err");
f0104e1d:	c7 04 24 2b 81 10 f0 	movl   $0xf010812b,(%esp)
f0104e24:	e8 45 f2 ff ff       	call   f010406e <cprintf>
		return -E_INVAL;
f0104e29:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104e2e:	e9 9c 01 00 00       	jmp    f0104fcf <syscall+0x4ff>
	}

	// -E_INVAL if perm is inappropriate (see sys_page_alloc).
	int flag = PTE_U | PTE_P;
	if ((perm & flag) != flag) {
f0104e33:	8b 55 1c             	mov    0x1c(%ebp),%edx
f0104e36:	83 e2 05             	and    $0x5,%edx
f0104e39:	83 fa 05             	cmp    $0x5,%edx
f0104e3c:	74 16                	je     f0104e54 <syscall+0x384>
		cprintf("13 err");
f0104e3e:	c7 04 24 32 81 10 f0 	movl   $0xf0108132,(%esp)
f0104e45:	e8 24 f2 ff ff       	call   f010406e <cprintf>
		return -E_INVAL;
f0104e4a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104e4f:	e9 7b 01 00 00       	jmp    f0104fcf <syscall+0x4ff>
	}

	// -E_INVAL if (perm & PTE_W), but srcva is read-only in srcenvid's
	// address space.
	if (((*pte&PTE_W) == 0) && (perm&PTE_W)) {
f0104e54:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104e57:	f6 02 02             	testb  $0x2,(%edx)
f0104e5a:	75 1c                	jne    f0104e78 <syscall+0x3a8>
f0104e5c:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104e60:	74 16                	je     f0104e78 <syscall+0x3a8>
		cprintf("14 err"); 
f0104e62:	c7 04 24 39 81 10 f0 	movl   $0xf0108139,(%esp)
f0104e69:	e8 00 f2 ff ff       	call   f010406e <cprintf>
		return -E_INVAL;
f0104e6e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104e73:	e9 57 01 00 00       	jmp    f0104fcf <syscall+0x4ff>
	}

	// -E_NO_MEM if there's no memory to allocate any necessary page tables.
	err = page_insert(de->env_pgdir, pag, dstva, perm);
f0104e78:	8b 7d 1c             	mov    0x1c(%ebp),%edi
f0104e7b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104e7f:	8b 7d 18             	mov    0x18(%ebp),%edi
f0104e82:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104e86:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e8a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104e8d:	8b 40 60             	mov    0x60(%eax),%eax
f0104e90:	89 04 24             	mov    %eax,(%esp)
f0104e93:	e8 04 c6 ff ff       	call   f010149c <page_insert>
f0104e98:	89 c3                	mov    %eax,%ebx
	cprintf("15 err %d", err);
f0104e9a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e9e:	c7 04 24 40 81 10 f0 	movl   $0xf0108140,(%esp)
f0104ea5:	e8 c4 f1 ff ff       	call   f010406e <cprintf>
	return err;
f0104eaa:	89 d8                	mov    %ebx,%eax
		break;
	case SYS_page_alloc:
		return sys_page_alloc(a1, (void*)a2, a3);
		break;
	case SYS_page_map:
		return sys_page_map(a1, (void*)a2, a3, (void*)a4, a5);
f0104eac:	e9 1e 01 00 00       	jmp    f0104fcf <syscall+0x4ff>
{
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.

	cprintf("DEBUG sys_page_unmap() called\n");
f0104eb1:	c7 04 24 94 81 10 f0 	movl   $0xf0108194,(%esp)
f0104eb8:	e8 b1 f1 ff ff       	call   f010406e <cprintf>
	struct Env *e;
	int err = envid2env(envid, &e, 1);
f0104ebd:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104ec4:	00 
f0104ec5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104ec8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ecc:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104ecf:	89 04 24             	mov    %eax,(%esp)
f0104ed2:	e8 41 e8 ff ff       	call   f0103718 <envid2env>
f0104ed7:	89 c3                	mov    %eax,%ebx
	if (err) {
f0104ed9:	85 c0                	test   %eax,%eax
f0104edb:	74 17                	je     f0104ef4 <syscall+0x424>
		cprintf("16 err %d", err);
f0104edd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ee1:	c7 04 24 4a 81 10 f0 	movl   $0xf010814a,(%esp)
f0104ee8:	e8 81 f1 ff ff       	call   f010406e <cprintf>
		return err;	//bad environment
f0104eed:	89 d8                	mov    %ebx,%eax
f0104eef:	e9 db 00 00 00       	jmp    f0104fcf <syscall+0x4ff>
	}

	if (va>=(void*)UTOP || ROUNDDOWN(va,PGSIZE)!=va) {
f0104ef4:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104efb:	77 0d                	ja     f0104f0a <syscall+0x43a>
f0104efd:	8b 45 10             	mov    0x10(%ebp),%eax
f0104f00:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0104f05:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104f08:	74 16                	je     f0104f20 <syscall+0x450>
		cprintf("17 err");
f0104f0a:	c7 04 24 54 81 10 f0 	movl   $0xf0108154,(%esp)
f0104f11:	e8 58 f1 ff ff       	call   f010406e <cprintf>
		return -E_INVAL;
f0104f16:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104f1b:	e9 af 00 00 00       	jmp    f0104fcf <syscall+0x4ff>
	}

	page_remove(e->env_pgdir, va);
f0104f20:	8b 45 10             	mov    0x10(%ebp),%eax
f0104f23:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104f27:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104f2a:	8b 40 60             	mov    0x60(%eax),%eax
f0104f2d:	89 04 24             	mov    %eax,(%esp)
f0104f30:	e8 17 c5 ff ff       	call   f010144c <page_remove>
	return 0;
f0104f35:	b8 00 00 00 00       	mov    $0x0,%eax
		break;
	case SYS_page_map:
		return sys_page_map(a1, (void*)a2, a3, (void*)a4, a5);
		break;
	case SYS_page_unmap:
		return sys_page_unmap(a1, (void*)a2);
f0104f3a:	e9 90 00 00 00       	jmp    f0104fcf <syscall+0x4ff>
	// check whether the current environment has permission to set
	// envid's status.

	// LAB 4: Your code here.

	cprintf("DEBUG sys_env_set_status() called\n");
f0104f3f:	c7 04 24 b4 81 10 f0 	movl   $0xf01081b4,(%esp)
f0104f46:	e8 23 f1 ff ff       	call   f010406e <cprintf>
	if (status != ENV_NOT_RUNNABLE && status != ENV_RUNNABLE) {
f0104f4b:	83 7d 10 02          	cmpl   $0x2,0x10(%ebp)
f0104f4f:	74 19                	je     f0104f6a <syscall+0x49a>
f0104f51:	83 7d 10 04          	cmpl   $0x4,0x10(%ebp)
f0104f55:	74 13                	je     f0104f6a <syscall+0x49a>
		cprintf("2 err");
f0104f57:	c7 04 24 2c 81 10 f0 	movl   $0xf010812c,(%esp)
f0104f5e:	e8 0b f1 ff ff       	call   f010406e <cprintf>
		return -E_INVAL;
f0104f63:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104f68:	eb 65                	jmp    f0104fcf <syscall+0x4ff>
	}

	struct Env *e;
	int err = envid2env(envid, &e, 1);
f0104f6a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104f71:	00 
f0104f72:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104f75:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104f79:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104f7c:	89 04 24             	mov    %eax,(%esp)
f0104f7f:	e8 94 e7 ff ff       	call   f0103718 <envid2env>
f0104f84:	89 c3                	mov    %eax,%ebx
	if (err) {
f0104f86:	85 c0                	test   %eax,%eax
f0104f88:	74 14                	je     f0104f9e <syscall+0x4ce>
		cprintf("3 err %d", err);
f0104f8a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104f8e:	c7 04 24 5b 81 10 f0 	movl   $0xf010815b,(%esp)
f0104f95:	e8 d4 f0 ff ff       	call   f010406e <cprintf>
		return err;	//bad environment
f0104f9a:	89 d8                	mov    %ebx,%eax
f0104f9c:	eb 31                	jmp    f0104fcf <syscall+0x4ff>
	}

	e->env_status = status;
f0104f9e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104fa1:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104fa4:	89 48 54             	mov    %ecx,0x54(%eax)
	return 0;
f0104fa7:	b8 00 00 00 00       	mov    $0x0,%eax
		break;
	case SYS_page_unmap:
		return sys_page_unmap(a1, (void*)a2);
		break;
	case SYS_env_set_status:
		return sys_env_set_status(a1, a2);
f0104fac:	eb 21                	jmp    f0104fcf <syscall+0x4ff>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.

	panic("sys_env_set_pgfault_upcall not implemented");
f0104fae:	c7 44 24 08 d8 81 10 	movl   $0xf01081d8,0x8(%esp)
f0104fb5:	f0 
f0104fb6:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f0104fbd:	00 
f0104fbe:	c7 04 24 64 81 10 f0 	movl   $0xf0108164,(%esp)
f0104fc5:	e8 76 b0 ff ff       	call   f0100040 <_panic>
		break;
	case SYS_env_set_pgfault_upcall:
		return sys_env_set_pgfault_upcall(a1, (void*)a2);
		break;
	default:
		ret = -E_INVAL;
f0104fca:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}

	return ret;
}
f0104fcf:	83 c4 2c             	add    $0x2c,%esp
f0104fd2:	5b                   	pop    %ebx
f0104fd3:	5e                   	pop    %esi
f0104fd4:	5f                   	pop    %edi
f0104fd5:	5d                   	pop    %ebp
f0104fd6:	c3                   	ret    

f0104fd7 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104fd7:	55                   	push   %ebp
f0104fd8:	89 e5                	mov    %esp,%ebp
f0104fda:	57                   	push   %edi
f0104fdb:	56                   	push   %esi
f0104fdc:	53                   	push   %ebx
f0104fdd:	83 ec 14             	sub    $0x14,%esp
f0104fe0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104fe3:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104fe6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104fe9:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104fec:	8b 1a                	mov    (%edx),%ebx
f0104fee:	8b 01                	mov    (%ecx),%eax
f0104ff0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104ff3:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104ffa:	e9 88 00 00 00       	jmp    f0105087 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0104fff:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105002:	01 d8                	add    %ebx,%eax
f0105004:	89 c7                	mov    %eax,%edi
f0105006:	c1 ef 1f             	shr    $0x1f,%edi
f0105009:	01 c7                	add    %eax,%edi
f010500b:	d1 ff                	sar    %edi
f010500d:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0105010:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0105013:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0105016:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0105018:	eb 03                	jmp    f010501d <stab_binsearch+0x46>
			m--;
f010501a:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010501d:	39 c3                	cmp    %eax,%ebx
f010501f:	7f 1f                	jg     f0105040 <stab_binsearch+0x69>
f0105021:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0105025:	83 ea 0c             	sub    $0xc,%edx
f0105028:	39 f1                	cmp    %esi,%ecx
f010502a:	75 ee                	jne    f010501a <stab_binsearch+0x43>
f010502c:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010502f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0105032:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0105035:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0105039:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010503c:	76 18                	jbe    f0105056 <stab_binsearch+0x7f>
f010503e:	eb 05                	jmp    f0105045 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0105040:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0105043:	eb 42                	jmp    f0105087 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0105045:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0105048:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f010504a:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010504d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0105054:	eb 31                	jmp    f0105087 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0105056:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0105059:	73 17                	jae    f0105072 <stab_binsearch+0x9b>
			*region_right = m - 1;
f010505b:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010505e:	83 e8 01             	sub    $0x1,%eax
f0105061:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0105064:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0105067:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0105069:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0105070:	eb 15                	jmp    f0105087 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0105072:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105075:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0105078:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f010507a:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010507e:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0105080:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0105087:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010508a:	0f 8e 6f ff ff ff    	jle    f0104fff <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0105090:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0105094:	75 0f                	jne    f01050a5 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0105096:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105099:	8b 00                	mov    (%eax),%eax
f010509b:	83 e8 01             	sub    $0x1,%eax
f010509e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01050a1:	89 07                	mov    %eax,(%edi)
f01050a3:	eb 2c                	jmp    f01050d1 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01050a5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01050a8:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01050aa:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01050ad:	8b 0f                	mov    (%edi),%ecx
f01050af:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01050b2:	8b 7d ec             	mov    -0x14(%ebp),%edi
f01050b5:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01050b8:	eb 03                	jmp    f01050bd <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01050ba:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01050bd:	39 c8                	cmp    %ecx,%eax
f01050bf:	7e 0b                	jle    f01050cc <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f01050c1:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01050c5:	83 ea 0c             	sub    $0xc,%edx
f01050c8:	39 f3                	cmp    %esi,%ebx
f01050ca:	75 ee                	jne    f01050ba <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f01050cc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01050cf:	89 07                	mov    %eax,(%edi)
	}
}
f01050d1:	83 c4 14             	add    $0x14,%esp
f01050d4:	5b                   	pop    %ebx
f01050d5:	5e                   	pop    %esi
f01050d6:	5f                   	pop    %edi
f01050d7:	5d                   	pop    %ebp
f01050d8:	c3                   	ret    

f01050d9 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01050d9:	55                   	push   %ebp
f01050da:	89 e5                	mov    %esp,%ebp
f01050dc:	57                   	push   %edi
f01050dd:	56                   	push   %esi
f01050de:	53                   	push   %ebx
f01050df:	83 ec 4c             	sub    $0x4c,%esp
f01050e2:	8b 75 08             	mov    0x8(%ebp),%esi
f01050e5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01050e8:	c7 03 30 82 10 f0    	movl   $0xf0108230,(%ebx)
	info->eip_line = 0;
f01050ee:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01050f5:	c7 43 08 30 82 10 f0 	movl   $0xf0108230,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01050fc:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0105103:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0105106:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010510d:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0105113:	77 57                	ja     f010516c <debuginfo_eip+0x93>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U | PTE_P))
f0105115:	e8 bf 10 00 00       	call   f01061d9 <cpunum>
f010511a:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0105121:	00 
f0105122:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0105129:	00 
f010512a:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f0105131:	00 
f0105132:	6b c0 74             	imul   $0x74,%eax,%eax
f0105135:	8b 80 28 d0 22 f0    	mov    -0xfdd2fd8(%eax),%eax
f010513b:	89 04 24             	mov    %eax,(%esp)
f010513e:	e8 7d e4 ff ff       	call   f01035c0 <user_mem_check>
f0105143:	85 c0                	test   %eax,%eax
f0105145:	0f 85 e4 01 00 00    	jne    f010532f <debuginfo_eip+0x256>
			return -1;

		stabs = usd->stabs;
f010514b:	a1 00 00 20 00       	mov    0x200000,%eax
f0105150:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		stab_end = usd->stab_end;
f0105153:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0105158:	8b 3d 08 00 20 00    	mov    0x200008,%edi
f010515e:	89 7d c0             	mov    %edi,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0105161:	8b 3d 0c 00 20 00    	mov    0x20000c,%edi
f0105167:	89 7d bc             	mov    %edi,-0x44(%ebp)
f010516a:	eb 1a                	jmp    f0105186 <debuginfo_eip+0xad>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010516c:	c7 45 bc cf 61 11 f0 	movl   $0xf01161cf,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0105173:	c7 45 c0 71 2b 11 f0 	movl   $0xf0112b71,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010517a:	b8 70 2b 11 f0       	mov    $0xf0112b70,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f010517f:	c7 45 c4 18 87 10 f0 	movl   $0xf0108718,-0x3c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0105186:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0105189:	39 7d c0             	cmp    %edi,-0x40(%ebp)
f010518c:	0f 83 a4 01 00 00    	jae    f0105336 <debuginfo_eip+0x25d>
f0105192:	80 7f ff 00          	cmpb   $0x0,-0x1(%edi)
f0105196:	0f 85 a1 01 00 00    	jne    f010533d <debuginfo_eip+0x264>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010519c:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01051a3:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01051a6:	29 f8                	sub    %edi,%eax
f01051a8:	c1 f8 02             	sar    $0x2,%eax
f01051ab:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01051b1:	83 e8 01             	sub    $0x1,%eax
f01051b4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01051b7:	89 74 24 04          	mov    %esi,0x4(%esp)
f01051bb:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01051c2:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01051c5:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01051c8:	89 f8                	mov    %edi,%eax
f01051ca:	e8 08 fe ff ff       	call   f0104fd7 <stab_binsearch>
	if (lfile == 0)
f01051cf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01051d2:	85 c0                	test   %eax,%eax
f01051d4:	0f 84 6a 01 00 00    	je     f0105344 <debuginfo_eip+0x26b>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01051da:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01051dd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01051e0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01051e3:	89 74 24 04          	mov    %esi,0x4(%esp)
f01051e7:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01051ee:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01051f1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01051f4:	89 f8                	mov    %edi,%eax
f01051f6:	e8 dc fd ff ff       	call   f0104fd7 <stab_binsearch>

	if (lfun <= rfun) {
f01051fb:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01051fe:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0105201:	39 c8                	cmp    %ecx,%eax
f0105203:	7f 32                	jg     f0105237 <debuginfo_eip+0x15e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0105205:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0105208:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010520b:	8d 3c 97             	lea    (%edi,%edx,4),%edi
f010520e:	8b 17                	mov    (%edi),%edx
f0105210:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0105213:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0105216:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0105219:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f010521c:	73 09                	jae    f0105227 <debuginfo_eip+0x14e>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010521e:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0105221:	03 55 c0             	add    -0x40(%ebp),%edx
f0105224:	89 53 08             	mov    %edx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0105227:	8b 57 08             	mov    0x8(%edi),%edx
f010522a:	89 53 10             	mov    %edx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010522d:	29 d6                	sub    %edx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010522f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0105232:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0105235:	eb 0f                	jmp    f0105246 <debuginfo_eip+0x16d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0105237:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010523a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010523d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0105240:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105243:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0105246:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f010524d:	00 
f010524e:	8b 43 08             	mov    0x8(%ebx),%eax
f0105251:	89 04 24             	mov    %eax,(%esp)
f0105254:	e8 12 09 00 00       	call   f0105b6b <strfind>
f0105259:	2b 43 08             	sub    0x8(%ebx),%eax
f010525c:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f010525f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0105263:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f010526a:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010526d:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0105270:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0105273:	89 f8                	mov    %edi,%eax
f0105275:	e8 5d fd ff ff       	call   f0104fd7 <stab_binsearch>

	if (lline > rline) 
f010527a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010527d:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0105280:	0f 8f c5 00 00 00    	jg     f010534b <debuginfo_eip+0x272>
		return -1;
	else
		info->eip_line = stabs[lline].n_desc;
f0105286:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0105289:	0f b7 44 87 06       	movzwl 0x6(%edi,%eax,4),%eax
f010528e:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0105291:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105294:	89 c6                	mov    %eax,%esi
f0105296:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105299:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010529c:	8d 14 97             	lea    (%edi,%edx,4),%edx
f010529f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01052a2:	eb 06                	jmp    f01052aa <debuginfo_eip+0x1d1>
f01052a4:	83 e8 01             	sub    $0x1,%eax
f01052a7:	83 ea 0c             	sub    $0xc,%edx
f01052aa:	89 c7                	mov    %eax,%edi
f01052ac:	39 c6                	cmp    %eax,%esi
f01052ae:	7f 3c                	jg     f01052ec <debuginfo_eip+0x213>
	       && stabs[lline].n_type != N_SOL
f01052b0:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01052b4:	80 f9 84             	cmp    $0x84,%cl
f01052b7:	75 08                	jne    f01052c1 <debuginfo_eip+0x1e8>
f01052b9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01052bc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01052bf:	eb 11                	jmp    f01052d2 <debuginfo_eip+0x1f9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01052c1:	80 f9 64             	cmp    $0x64,%cl
f01052c4:	75 de                	jne    f01052a4 <debuginfo_eip+0x1cb>
f01052c6:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01052ca:	74 d8                	je     f01052a4 <debuginfo_eip+0x1cb>
f01052cc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01052cf:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01052d2:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01052d5:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01052d8:	8b 04 86             	mov    (%esi,%eax,4),%eax
f01052db:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01052de:	2b 55 c0             	sub    -0x40(%ebp),%edx
f01052e1:	39 d0                	cmp    %edx,%eax
f01052e3:	73 0a                	jae    f01052ef <debuginfo_eip+0x216>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01052e5:	03 45 c0             	add    -0x40(%ebp),%eax
f01052e8:	89 03                	mov    %eax,(%ebx)
f01052ea:	eb 03                	jmp    f01052ef <debuginfo_eip+0x216>
f01052ec:	8b 5d 0c             	mov    0xc(%ebp),%ebx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01052ef:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01052f2:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01052f5:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01052fa:	39 f2                	cmp    %esi,%edx
f01052fc:	7d 59                	jge    f0105357 <debuginfo_eip+0x27e>
		for (lline = lfun + 1;
f01052fe:	83 c2 01             	add    $0x1,%edx
f0105301:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0105304:	89 d0                	mov    %edx,%eax
f0105306:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0105309:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010530c:	8d 14 97             	lea    (%edi,%edx,4),%edx
f010530f:	eb 04                	jmp    f0105315 <debuginfo_eip+0x23c>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0105311:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0105315:	39 c6                	cmp    %eax,%esi
f0105317:	7e 39                	jle    f0105352 <debuginfo_eip+0x279>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0105319:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010531d:	83 c0 01             	add    $0x1,%eax
f0105320:	83 c2 0c             	add    $0xc,%edx
f0105323:	80 f9 a0             	cmp    $0xa0,%cl
f0105326:	74 e9                	je     f0105311 <debuginfo_eip+0x238>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0105328:	b8 00 00 00 00       	mov    $0x0,%eax
f010532d:	eb 28                	jmp    f0105357 <debuginfo_eip+0x27e>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		if (user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_U | PTE_P))
			return -1;
f010532f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105334:	eb 21                	jmp    f0105357 <debuginfo_eip+0x27e>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0105336:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010533b:	eb 1a                	jmp    f0105357 <debuginfo_eip+0x27e>
f010533d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105342:	eb 13                	jmp    f0105357 <debuginfo_eip+0x27e>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0105344:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105349:	eb 0c                	jmp    f0105357 <debuginfo_eip+0x27e>
	//	which one.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);

	if (lline > rline) 
		return -1;
f010534b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105350:	eb 05                	jmp    f0105357 <debuginfo_eip+0x27e>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0105352:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105357:	83 c4 4c             	add    $0x4c,%esp
f010535a:	5b                   	pop    %ebx
f010535b:	5e                   	pop    %esi
f010535c:	5f                   	pop    %edi
f010535d:	5d                   	pop    %ebp
f010535e:	c3                   	ret    
f010535f:	90                   	nop

f0105360 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0105360:	55                   	push   %ebp
f0105361:	89 e5                	mov    %esp,%ebp
f0105363:	57                   	push   %edi
f0105364:	56                   	push   %esi
f0105365:	53                   	push   %ebx
f0105366:	83 ec 3c             	sub    $0x3c,%esp
f0105369:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010536c:	89 d7                	mov    %edx,%edi
f010536e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105371:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105374:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105377:	89 c3                	mov    %eax,%ebx
f0105379:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010537c:	8b 45 10             	mov    0x10(%ebp),%eax
f010537f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0105382:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105387:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010538a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010538d:	39 d9                	cmp    %ebx,%ecx
f010538f:	72 05                	jb     f0105396 <printnum+0x36>
f0105391:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0105394:	77 69                	ja     f01053ff <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0105396:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0105399:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010539d:	83 ee 01             	sub    $0x1,%esi
f01053a0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01053a4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01053a8:	8b 44 24 08          	mov    0x8(%esp),%eax
f01053ac:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01053b0:	89 c3                	mov    %eax,%ebx
f01053b2:	89 d6                	mov    %edx,%esi
f01053b4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01053b7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01053ba:	89 54 24 08          	mov    %edx,0x8(%esp)
f01053be:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01053c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01053c5:	89 04 24             	mov    %eax,(%esp)
f01053c8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01053cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01053cf:	e8 4c 12 00 00       	call   f0106620 <__udivdi3>
f01053d4:	89 d9                	mov    %ebx,%ecx
f01053d6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01053da:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01053de:	89 04 24             	mov    %eax,(%esp)
f01053e1:	89 54 24 04          	mov    %edx,0x4(%esp)
f01053e5:	89 fa                	mov    %edi,%edx
f01053e7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01053ea:	e8 71 ff ff ff       	call   f0105360 <printnum>
f01053ef:	eb 1b                	jmp    f010540c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01053f1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01053f5:	8b 45 18             	mov    0x18(%ebp),%eax
f01053f8:	89 04 24             	mov    %eax,(%esp)
f01053fb:	ff d3                	call   *%ebx
f01053fd:	eb 03                	jmp    f0105402 <printnum+0xa2>
f01053ff:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0105402:	83 ee 01             	sub    $0x1,%esi
f0105405:	85 f6                	test   %esi,%esi
f0105407:	7f e8                	jg     f01053f1 <printnum+0x91>
f0105409:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010540c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105410:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105414:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105417:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010541a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010541e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0105422:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105425:	89 04 24             	mov    %eax,(%esp)
f0105428:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010542b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010542f:	e8 1c 13 00 00       	call   f0106750 <__umoddi3>
f0105434:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105438:	0f be 80 3a 82 10 f0 	movsbl -0xfef7dc6(%eax),%eax
f010543f:	89 04 24             	mov    %eax,(%esp)
f0105442:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105445:	ff d0                	call   *%eax
}
f0105447:	83 c4 3c             	add    $0x3c,%esp
f010544a:	5b                   	pop    %ebx
f010544b:	5e                   	pop    %esi
f010544c:	5f                   	pop    %edi
f010544d:	5d                   	pop    %ebp
f010544e:	c3                   	ret    

f010544f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010544f:	55                   	push   %ebp
f0105450:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0105452:	83 fa 01             	cmp    $0x1,%edx
f0105455:	7e 0e                	jle    f0105465 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0105457:	8b 10                	mov    (%eax),%edx
f0105459:	8d 4a 08             	lea    0x8(%edx),%ecx
f010545c:	89 08                	mov    %ecx,(%eax)
f010545e:	8b 02                	mov    (%edx),%eax
f0105460:	8b 52 04             	mov    0x4(%edx),%edx
f0105463:	eb 22                	jmp    f0105487 <getuint+0x38>
	else if (lflag)
f0105465:	85 d2                	test   %edx,%edx
f0105467:	74 10                	je     f0105479 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0105469:	8b 10                	mov    (%eax),%edx
f010546b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010546e:	89 08                	mov    %ecx,(%eax)
f0105470:	8b 02                	mov    (%edx),%eax
f0105472:	ba 00 00 00 00       	mov    $0x0,%edx
f0105477:	eb 0e                	jmp    f0105487 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0105479:	8b 10                	mov    (%eax),%edx
f010547b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010547e:	89 08                	mov    %ecx,(%eax)
f0105480:	8b 02                	mov    (%edx),%eax
f0105482:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0105487:	5d                   	pop    %ebp
f0105488:	c3                   	ret    

f0105489 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0105489:	55                   	push   %ebp
f010548a:	89 e5                	mov    %esp,%ebp
f010548c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010548f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0105493:	8b 10                	mov    (%eax),%edx
f0105495:	3b 50 04             	cmp    0x4(%eax),%edx
f0105498:	73 0a                	jae    f01054a4 <sprintputch+0x1b>
		*b->buf++ = ch;
f010549a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010549d:	89 08                	mov    %ecx,(%eax)
f010549f:	8b 45 08             	mov    0x8(%ebp),%eax
f01054a2:	88 02                	mov    %al,(%edx)
}
f01054a4:	5d                   	pop    %ebp
f01054a5:	c3                   	ret    

f01054a6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01054a6:	55                   	push   %ebp
f01054a7:	89 e5                	mov    %esp,%ebp
f01054a9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01054ac:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01054af:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01054b3:	8b 45 10             	mov    0x10(%ebp),%eax
f01054b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01054ba:	8b 45 0c             	mov    0xc(%ebp),%eax
f01054bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01054c1:	8b 45 08             	mov    0x8(%ebp),%eax
f01054c4:	89 04 24             	mov    %eax,(%esp)
f01054c7:	e8 02 00 00 00       	call   f01054ce <vprintfmt>
	va_end(ap);
}
f01054cc:	c9                   	leave  
f01054cd:	c3                   	ret    

f01054ce <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01054ce:	55                   	push   %ebp
f01054cf:	89 e5                	mov    %esp,%ebp
f01054d1:	57                   	push   %edi
f01054d2:	56                   	push   %esi
f01054d3:	53                   	push   %ebx
f01054d4:	83 ec 3c             	sub    $0x3c,%esp
f01054d7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01054da:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01054dd:	eb 14                	jmp    f01054f3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01054df:	85 c0                	test   %eax,%eax
f01054e1:	0f 84 b3 03 00 00    	je     f010589a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f01054e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01054eb:	89 04 24             	mov    %eax,(%esp)
f01054ee:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01054f1:	89 f3                	mov    %esi,%ebx
f01054f3:	8d 73 01             	lea    0x1(%ebx),%esi
f01054f6:	0f b6 03             	movzbl (%ebx),%eax
f01054f9:	83 f8 25             	cmp    $0x25,%eax
f01054fc:	75 e1                	jne    f01054df <vprintfmt+0x11>
f01054fe:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0105502:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0105509:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0105510:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0105517:	ba 00 00 00 00       	mov    $0x0,%edx
f010551c:	eb 1d                	jmp    f010553b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010551e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0105520:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0105524:	eb 15                	jmp    f010553b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105526:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0105528:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010552c:	eb 0d                	jmp    f010553b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010552e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105531:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0105534:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010553b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010553e:	0f b6 0e             	movzbl (%esi),%ecx
f0105541:	0f b6 c1             	movzbl %cl,%eax
f0105544:	83 e9 23             	sub    $0x23,%ecx
f0105547:	80 f9 55             	cmp    $0x55,%cl
f010554a:	0f 87 2a 03 00 00    	ja     f010587a <vprintfmt+0x3ac>
f0105550:	0f b6 c9             	movzbl %cl,%ecx
f0105553:	ff 24 8d 00 83 10 f0 	jmp    *-0xfef7d00(,%ecx,4)
f010555a:	89 de                	mov    %ebx,%esi
f010555c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0105561:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0105564:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0105568:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010556b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010556e:	83 fb 09             	cmp    $0x9,%ebx
f0105571:	77 36                	ja     f01055a9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0105573:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0105576:	eb e9                	jmp    f0105561 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0105578:	8b 45 14             	mov    0x14(%ebp),%eax
f010557b:	8d 48 04             	lea    0x4(%eax),%ecx
f010557e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0105581:	8b 00                	mov    (%eax),%eax
f0105583:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105586:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0105588:	eb 22                	jmp    f01055ac <vprintfmt+0xde>
f010558a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010558d:	85 c9                	test   %ecx,%ecx
f010558f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105594:	0f 49 c1             	cmovns %ecx,%eax
f0105597:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010559a:	89 de                	mov    %ebx,%esi
f010559c:	eb 9d                	jmp    f010553b <vprintfmt+0x6d>
f010559e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01055a0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f01055a7:	eb 92                	jmp    f010553b <vprintfmt+0x6d>
f01055a9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f01055ac:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01055b0:	79 89                	jns    f010553b <vprintfmt+0x6d>
f01055b2:	e9 77 ff ff ff       	jmp    f010552e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01055b7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01055ba:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01055bc:	e9 7a ff ff ff       	jmp    f010553b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01055c1:	8b 45 14             	mov    0x14(%ebp),%eax
f01055c4:	8d 50 04             	lea    0x4(%eax),%edx
f01055c7:	89 55 14             	mov    %edx,0x14(%ebp)
f01055ca:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01055ce:	8b 00                	mov    (%eax),%eax
f01055d0:	89 04 24             	mov    %eax,(%esp)
f01055d3:	ff 55 08             	call   *0x8(%ebp)
			break;
f01055d6:	e9 18 ff ff ff       	jmp    f01054f3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01055db:	8b 45 14             	mov    0x14(%ebp),%eax
f01055de:	8d 50 04             	lea    0x4(%eax),%edx
f01055e1:	89 55 14             	mov    %edx,0x14(%ebp)
f01055e4:	8b 00                	mov    (%eax),%eax
f01055e6:	99                   	cltd   
f01055e7:	31 d0                	xor    %edx,%eax
f01055e9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01055eb:	83 f8 09             	cmp    $0x9,%eax
f01055ee:	7f 0b                	jg     f01055fb <vprintfmt+0x12d>
f01055f0:	8b 14 85 60 84 10 f0 	mov    -0xfef7ba0(,%eax,4),%edx
f01055f7:	85 d2                	test   %edx,%edx
f01055f9:	75 20                	jne    f010561b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f01055fb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01055ff:	c7 44 24 08 52 82 10 	movl   $0xf0108252,0x8(%esp)
f0105606:	f0 
f0105607:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010560b:	8b 45 08             	mov    0x8(%ebp),%eax
f010560e:	89 04 24             	mov    %eax,(%esp)
f0105611:	e8 90 fe ff ff       	call   f01054a6 <printfmt>
f0105616:	e9 d8 fe ff ff       	jmp    f01054f3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010561b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010561f:	c7 44 24 08 d7 6e 10 	movl   $0xf0106ed7,0x8(%esp)
f0105626:	f0 
f0105627:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010562b:	8b 45 08             	mov    0x8(%ebp),%eax
f010562e:	89 04 24             	mov    %eax,(%esp)
f0105631:	e8 70 fe ff ff       	call   f01054a6 <printfmt>
f0105636:	e9 b8 fe ff ff       	jmp    f01054f3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010563b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010563e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105641:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0105644:	8b 45 14             	mov    0x14(%ebp),%eax
f0105647:	8d 50 04             	lea    0x4(%eax),%edx
f010564a:	89 55 14             	mov    %edx,0x14(%ebp)
f010564d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010564f:	85 f6                	test   %esi,%esi
f0105651:	b8 4b 82 10 f0       	mov    $0xf010824b,%eax
f0105656:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0105659:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010565d:	0f 84 97 00 00 00    	je     f01056fa <vprintfmt+0x22c>
f0105663:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0105667:	0f 8e 9b 00 00 00    	jle    f0105708 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010566d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105671:	89 34 24             	mov    %esi,(%esp)
f0105674:	e8 9f 03 00 00       	call   f0105a18 <strnlen>
f0105679:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010567c:	29 c2                	sub    %eax,%edx
f010567e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0105681:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0105685:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0105688:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010568b:	8b 75 08             	mov    0x8(%ebp),%esi
f010568e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105691:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105693:	eb 0f                	jmp    f01056a4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0105695:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105699:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010569c:	89 04 24             	mov    %eax,(%esp)
f010569f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01056a1:	83 eb 01             	sub    $0x1,%ebx
f01056a4:	85 db                	test   %ebx,%ebx
f01056a6:	7f ed                	jg     f0105695 <vprintfmt+0x1c7>
f01056a8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01056ab:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01056ae:	85 d2                	test   %edx,%edx
f01056b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01056b5:	0f 49 c2             	cmovns %edx,%eax
f01056b8:	29 c2                	sub    %eax,%edx
f01056ba:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01056bd:	89 d7                	mov    %edx,%edi
f01056bf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01056c2:	eb 50                	jmp    f0105714 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01056c4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01056c8:	74 1e                	je     f01056e8 <vprintfmt+0x21a>
f01056ca:	0f be d2             	movsbl %dl,%edx
f01056cd:	83 ea 20             	sub    $0x20,%edx
f01056d0:	83 fa 5e             	cmp    $0x5e,%edx
f01056d3:	76 13                	jbe    f01056e8 <vprintfmt+0x21a>
					putch('?', putdat);
f01056d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01056d8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01056dc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01056e3:	ff 55 08             	call   *0x8(%ebp)
f01056e6:	eb 0d                	jmp    f01056f5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f01056e8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01056eb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01056ef:	89 04 24             	mov    %eax,(%esp)
f01056f2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01056f5:	83 ef 01             	sub    $0x1,%edi
f01056f8:	eb 1a                	jmp    f0105714 <vprintfmt+0x246>
f01056fa:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01056fd:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0105700:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105703:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105706:	eb 0c                	jmp    f0105714 <vprintfmt+0x246>
f0105708:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010570b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010570e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105711:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105714:	83 c6 01             	add    $0x1,%esi
f0105717:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010571b:	0f be c2             	movsbl %dl,%eax
f010571e:	85 c0                	test   %eax,%eax
f0105720:	74 27                	je     f0105749 <vprintfmt+0x27b>
f0105722:	85 db                	test   %ebx,%ebx
f0105724:	78 9e                	js     f01056c4 <vprintfmt+0x1f6>
f0105726:	83 eb 01             	sub    $0x1,%ebx
f0105729:	79 99                	jns    f01056c4 <vprintfmt+0x1f6>
f010572b:	89 f8                	mov    %edi,%eax
f010572d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105730:	8b 75 08             	mov    0x8(%ebp),%esi
f0105733:	89 c3                	mov    %eax,%ebx
f0105735:	eb 1a                	jmp    f0105751 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0105737:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010573b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0105742:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0105744:	83 eb 01             	sub    $0x1,%ebx
f0105747:	eb 08                	jmp    f0105751 <vprintfmt+0x283>
f0105749:	89 fb                	mov    %edi,%ebx
f010574b:	8b 75 08             	mov    0x8(%ebp),%esi
f010574e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105751:	85 db                	test   %ebx,%ebx
f0105753:	7f e2                	jg     f0105737 <vprintfmt+0x269>
f0105755:	89 75 08             	mov    %esi,0x8(%ebp)
f0105758:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010575b:	e9 93 fd ff ff       	jmp    f01054f3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0105760:	83 fa 01             	cmp    $0x1,%edx
f0105763:	7e 16                	jle    f010577b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0105765:	8b 45 14             	mov    0x14(%ebp),%eax
f0105768:	8d 50 08             	lea    0x8(%eax),%edx
f010576b:	89 55 14             	mov    %edx,0x14(%ebp)
f010576e:	8b 50 04             	mov    0x4(%eax),%edx
f0105771:	8b 00                	mov    (%eax),%eax
f0105773:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105776:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0105779:	eb 32                	jmp    f01057ad <vprintfmt+0x2df>
	else if (lflag)
f010577b:	85 d2                	test   %edx,%edx
f010577d:	74 18                	je     f0105797 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010577f:	8b 45 14             	mov    0x14(%ebp),%eax
f0105782:	8d 50 04             	lea    0x4(%eax),%edx
f0105785:	89 55 14             	mov    %edx,0x14(%ebp)
f0105788:	8b 30                	mov    (%eax),%esi
f010578a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010578d:	89 f0                	mov    %esi,%eax
f010578f:	c1 f8 1f             	sar    $0x1f,%eax
f0105792:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105795:	eb 16                	jmp    f01057ad <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0105797:	8b 45 14             	mov    0x14(%ebp),%eax
f010579a:	8d 50 04             	lea    0x4(%eax),%edx
f010579d:	89 55 14             	mov    %edx,0x14(%ebp)
f01057a0:	8b 30                	mov    (%eax),%esi
f01057a2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01057a5:	89 f0                	mov    %esi,%eax
f01057a7:	c1 f8 1f             	sar    $0x1f,%eax
f01057aa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01057ad:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01057b0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01057b3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01057b8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01057bc:	0f 89 80 00 00 00    	jns    f0105842 <vprintfmt+0x374>
				putch('-', putdat);
f01057c2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01057c6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01057cd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01057d0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01057d3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01057d6:	f7 d8                	neg    %eax
f01057d8:	83 d2 00             	adc    $0x0,%edx
f01057db:	f7 da                	neg    %edx
			}
			base = 10;
f01057dd:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01057e2:	eb 5e                	jmp    f0105842 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01057e4:	8d 45 14             	lea    0x14(%ebp),%eax
f01057e7:	e8 63 fc ff ff       	call   f010544f <getuint>
			base = 10;
f01057ec:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01057f1:	eb 4f                	jmp    f0105842 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
f01057f3:	8d 45 14             	lea    0x14(%ebp),%eax
f01057f6:	e8 54 fc ff ff       	call   f010544f <getuint>
			base = 8;
f01057fb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0105800:	eb 40                	jmp    f0105842 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
f0105802:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105806:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010580d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0105810:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105814:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010581b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010581e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105821:	8d 50 04             	lea    0x4(%eax),%edx
f0105824:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0105827:	8b 00                	mov    (%eax),%eax
f0105829:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010582e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0105833:	eb 0d                	jmp    f0105842 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0105835:	8d 45 14             	lea    0x14(%ebp),%eax
f0105838:	e8 12 fc ff ff       	call   f010544f <getuint>
			base = 16;
f010583d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0105842:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0105846:	89 74 24 10          	mov    %esi,0x10(%esp)
f010584a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010584d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105851:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105855:	89 04 24             	mov    %eax,(%esp)
f0105858:	89 54 24 04          	mov    %edx,0x4(%esp)
f010585c:	89 fa                	mov    %edi,%edx
f010585e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105861:	e8 fa fa ff ff       	call   f0105360 <printnum>
			break;
f0105866:	e9 88 fc ff ff       	jmp    f01054f3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010586b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010586f:	89 04 24             	mov    %eax,(%esp)
f0105872:	ff 55 08             	call   *0x8(%ebp)
			break;
f0105875:	e9 79 fc ff ff       	jmp    f01054f3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010587a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010587e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0105885:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105888:	89 f3                	mov    %esi,%ebx
f010588a:	eb 03                	jmp    f010588f <vprintfmt+0x3c1>
f010588c:	83 eb 01             	sub    $0x1,%ebx
f010588f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0105893:	75 f7                	jne    f010588c <vprintfmt+0x3be>
f0105895:	e9 59 fc ff ff       	jmp    f01054f3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010589a:	83 c4 3c             	add    $0x3c,%esp
f010589d:	5b                   	pop    %ebx
f010589e:	5e                   	pop    %esi
f010589f:	5f                   	pop    %edi
f01058a0:	5d                   	pop    %ebp
f01058a1:	c3                   	ret    

f01058a2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01058a2:	55                   	push   %ebp
f01058a3:	89 e5                	mov    %esp,%ebp
f01058a5:	83 ec 28             	sub    $0x28,%esp
f01058a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01058ab:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01058ae:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01058b1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01058b5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01058b8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01058bf:	85 c0                	test   %eax,%eax
f01058c1:	74 30                	je     f01058f3 <vsnprintf+0x51>
f01058c3:	85 d2                	test   %edx,%edx
f01058c5:	7e 2c                	jle    f01058f3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01058c7:	8b 45 14             	mov    0x14(%ebp),%eax
f01058ca:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01058ce:	8b 45 10             	mov    0x10(%ebp),%eax
f01058d1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01058d5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01058d8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01058dc:	c7 04 24 89 54 10 f0 	movl   $0xf0105489,(%esp)
f01058e3:	e8 e6 fb ff ff       	call   f01054ce <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01058e8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01058eb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01058ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01058f1:	eb 05                	jmp    f01058f8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01058f3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01058f8:	c9                   	leave  
f01058f9:	c3                   	ret    

f01058fa <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01058fa:	55                   	push   %ebp
f01058fb:	89 e5                	mov    %esp,%ebp
f01058fd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105900:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0105903:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105907:	8b 45 10             	mov    0x10(%ebp),%eax
f010590a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010590e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105911:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105915:	8b 45 08             	mov    0x8(%ebp),%eax
f0105918:	89 04 24             	mov    %eax,(%esp)
f010591b:	e8 82 ff ff ff       	call   f01058a2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0105920:	c9                   	leave  
f0105921:	c3                   	ret    
f0105922:	66 90                	xchg   %ax,%ax
f0105924:	66 90                	xchg   %ax,%ax
f0105926:	66 90                	xchg   %ax,%ax
f0105928:	66 90                	xchg   %ax,%ax
f010592a:	66 90                	xchg   %ax,%ax
f010592c:	66 90                	xchg   %ax,%ax
f010592e:	66 90                	xchg   %ax,%ax

f0105930 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0105930:	55                   	push   %ebp
f0105931:	89 e5                	mov    %esp,%ebp
f0105933:	57                   	push   %edi
f0105934:	56                   	push   %esi
f0105935:	53                   	push   %ebx
f0105936:	83 ec 1c             	sub    $0x1c,%esp
f0105939:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010593c:	85 c0                	test   %eax,%eax
f010593e:	74 10                	je     f0105950 <readline+0x20>
		cprintf("%s", prompt);
f0105940:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105944:	c7 04 24 d7 6e 10 f0 	movl   $0xf0106ed7,(%esp)
f010594b:	e8 1e e7 ff ff       	call   f010406e <cprintf>

	i = 0;
	echoing = iscons(0);
f0105950:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0105957:	e8 53 ae ff ff       	call   f01007af <iscons>
f010595c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010595e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105963:	e8 36 ae ff ff       	call   f010079e <getchar>
f0105968:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010596a:	85 c0                	test   %eax,%eax
f010596c:	79 17                	jns    f0105985 <readline+0x55>
			cprintf("read error: %e\n", c);
f010596e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105972:	c7 04 24 88 84 10 f0 	movl   $0xf0108488,(%esp)
f0105979:	e8 f0 e6 ff ff       	call   f010406e <cprintf>
			return NULL;
f010597e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105983:	eb 6d                	jmp    f01059f2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105985:	83 f8 7f             	cmp    $0x7f,%eax
f0105988:	74 05                	je     f010598f <readline+0x5f>
f010598a:	83 f8 08             	cmp    $0x8,%eax
f010598d:	75 19                	jne    f01059a8 <readline+0x78>
f010598f:	85 f6                	test   %esi,%esi
f0105991:	7e 15                	jle    f01059a8 <readline+0x78>
			if (echoing)
f0105993:	85 ff                	test   %edi,%edi
f0105995:	74 0c                	je     f01059a3 <readline+0x73>
				cputchar('\b');
f0105997:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010599e:	e8 eb ad ff ff       	call   f010078e <cputchar>
			i--;
f01059a3:	83 ee 01             	sub    $0x1,%esi
f01059a6:	eb bb                	jmp    f0105963 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01059a8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01059ae:	7f 1c                	jg     f01059cc <readline+0x9c>
f01059b0:	83 fb 1f             	cmp    $0x1f,%ebx
f01059b3:	7e 17                	jle    f01059cc <readline+0x9c>
			if (echoing)
f01059b5:	85 ff                	test   %edi,%edi
f01059b7:	74 08                	je     f01059c1 <readline+0x91>
				cputchar(c);
f01059b9:	89 1c 24             	mov    %ebx,(%esp)
f01059bc:	e8 cd ad ff ff       	call   f010078e <cputchar>
			buf[i++] = c;
f01059c1:	88 9e 80 ca 22 f0    	mov    %bl,-0xfdd3580(%esi)
f01059c7:	8d 76 01             	lea    0x1(%esi),%esi
f01059ca:	eb 97                	jmp    f0105963 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01059cc:	83 fb 0d             	cmp    $0xd,%ebx
f01059cf:	74 05                	je     f01059d6 <readline+0xa6>
f01059d1:	83 fb 0a             	cmp    $0xa,%ebx
f01059d4:	75 8d                	jne    f0105963 <readline+0x33>
			if (echoing)
f01059d6:	85 ff                	test   %edi,%edi
f01059d8:	74 0c                	je     f01059e6 <readline+0xb6>
				cputchar('\n');
f01059da:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01059e1:	e8 a8 ad ff ff       	call   f010078e <cputchar>
			buf[i] = 0;
f01059e6:	c6 86 80 ca 22 f0 00 	movb   $0x0,-0xfdd3580(%esi)
			return buf;
f01059ed:	b8 80 ca 22 f0       	mov    $0xf022ca80,%eax
		}
	}
}
f01059f2:	83 c4 1c             	add    $0x1c,%esp
f01059f5:	5b                   	pop    %ebx
f01059f6:	5e                   	pop    %esi
f01059f7:	5f                   	pop    %edi
f01059f8:	5d                   	pop    %ebp
f01059f9:	c3                   	ret    
f01059fa:	66 90                	xchg   %ax,%ax
f01059fc:	66 90                	xchg   %ax,%ax
f01059fe:	66 90                	xchg   %ax,%ax

f0105a00 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105a00:	55                   	push   %ebp
f0105a01:	89 e5                	mov    %esp,%ebp
f0105a03:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0105a06:	b8 00 00 00 00       	mov    $0x0,%eax
f0105a0b:	eb 03                	jmp    f0105a10 <strlen+0x10>
		n++;
f0105a0d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105a10:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105a14:	75 f7                	jne    f0105a0d <strlen+0xd>
		n++;
	return n;
}
f0105a16:	5d                   	pop    %ebp
f0105a17:	c3                   	ret    

f0105a18 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0105a18:	55                   	push   %ebp
f0105a19:	89 e5                	mov    %esp,%ebp
f0105a1b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105a1e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105a21:	b8 00 00 00 00       	mov    $0x0,%eax
f0105a26:	eb 03                	jmp    f0105a2b <strnlen+0x13>
		n++;
f0105a28:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105a2b:	39 d0                	cmp    %edx,%eax
f0105a2d:	74 06                	je     f0105a35 <strnlen+0x1d>
f0105a2f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0105a33:	75 f3                	jne    f0105a28 <strnlen+0x10>
		n++;
	return n;
}
f0105a35:	5d                   	pop    %ebp
f0105a36:	c3                   	ret    

f0105a37 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105a37:	55                   	push   %ebp
f0105a38:	89 e5                	mov    %esp,%ebp
f0105a3a:	53                   	push   %ebx
f0105a3b:	8b 45 08             	mov    0x8(%ebp),%eax
f0105a3e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105a41:	89 c2                	mov    %eax,%edx
f0105a43:	83 c2 01             	add    $0x1,%edx
f0105a46:	83 c1 01             	add    $0x1,%ecx
f0105a49:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0105a4d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105a50:	84 db                	test   %bl,%bl
f0105a52:	75 ef                	jne    f0105a43 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105a54:	5b                   	pop    %ebx
f0105a55:	5d                   	pop    %ebp
f0105a56:	c3                   	ret    

f0105a57 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105a57:	55                   	push   %ebp
f0105a58:	89 e5                	mov    %esp,%ebp
f0105a5a:	53                   	push   %ebx
f0105a5b:	83 ec 08             	sub    $0x8,%esp
f0105a5e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105a61:	89 1c 24             	mov    %ebx,(%esp)
f0105a64:	e8 97 ff ff ff       	call   f0105a00 <strlen>
	strcpy(dst + len, src);
f0105a69:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105a6c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105a70:	01 d8                	add    %ebx,%eax
f0105a72:	89 04 24             	mov    %eax,(%esp)
f0105a75:	e8 bd ff ff ff       	call   f0105a37 <strcpy>
	return dst;
}
f0105a7a:	89 d8                	mov    %ebx,%eax
f0105a7c:	83 c4 08             	add    $0x8,%esp
f0105a7f:	5b                   	pop    %ebx
f0105a80:	5d                   	pop    %ebp
f0105a81:	c3                   	ret    

f0105a82 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105a82:	55                   	push   %ebp
f0105a83:	89 e5                	mov    %esp,%ebp
f0105a85:	56                   	push   %esi
f0105a86:	53                   	push   %ebx
f0105a87:	8b 75 08             	mov    0x8(%ebp),%esi
f0105a8a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105a8d:	89 f3                	mov    %esi,%ebx
f0105a8f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105a92:	89 f2                	mov    %esi,%edx
f0105a94:	eb 0f                	jmp    f0105aa5 <strncpy+0x23>
		*dst++ = *src;
f0105a96:	83 c2 01             	add    $0x1,%edx
f0105a99:	0f b6 01             	movzbl (%ecx),%eax
f0105a9c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105a9f:	80 39 01             	cmpb   $0x1,(%ecx)
f0105aa2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105aa5:	39 da                	cmp    %ebx,%edx
f0105aa7:	75 ed                	jne    f0105a96 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0105aa9:	89 f0                	mov    %esi,%eax
f0105aab:	5b                   	pop    %ebx
f0105aac:	5e                   	pop    %esi
f0105aad:	5d                   	pop    %ebp
f0105aae:	c3                   	ret    

f0105aaf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105aaf:	55                   	push   %ebp
f0105ab0:	89 e5                	mov    %esp,%ebp
f0105ab2:	56                   	push   %esi
f0105ab3:	53                   	push   %ebx
f0105ab4:	8b 75 08             	mov    0x8(%ebp),%esi
f0105ab7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105aba:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0105abd:	89 f0                	mov    %esi,%eax
f0105abf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105ac3:	85 c9                	test   %ecx,%ecx
f0105ac5:	75 0b                	jne    f0105ad2 <strlcpy+0x23>
f0105ac7:	eb 1d                	jmp    f0105ae6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0105ac9:	83 c0 01             	add    $0x1,%eax
f0105acc:	83 c2 01             	add    $0x1,%edx
f0105acf:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105ad2:	39 d8                	cmp    %ebx,%eax
f0105ad4:	74 0b                	je     f0105ae1 <strlcpy+0x32>
f0105ad6:	0f b6 0a             	movzbl (%edx),%ecx
f0105ad9:	84 c9                	test   %cl,%cl
f0105adb:	75 ec                	jne    f0105ac9 <strlcpy+0x1a>
f0105add:	89 c2                	mov    %eax,%edx
f0105adf:	eb 02                	jmp    f0105ae3 <strlcpy+0x34>
f0105ae1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0105ae3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0105ae6:	29 f0                	sub    %esi,%eax
}
f0105ae8:	5b                   	pop    %ebx
f0105ae9:	5e                   	pop    %esi
f0105aea:	5d                   	pop    %ebp
f0105aeb:	c3                   	ret    

f0105aec <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105aec:	55                   	push   %ebp
f0105aed:	89 e5                	mov    %esp,%ebp
f0105aef:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105af2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105af5:	eb 06                	jmp    f0105afd <strcmp+0x11>
		p++, q++;
f0105af7:	83 c1 01             	add    $0x1,%ecx
f0105afa:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0105afd:	0f b6 01             	movzbl (%ecx),%eax
f0105b00:	84 c0                	test   %al,%al
f0105b02:	74 04                	je     f0105b08 <strcmp+0x1c>
f0105b04:	3a 02                	cmp    (%edx),%al
f0105b06:	74 ef                	je     f0105af7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105b08:	0f b6 c0             	movzbl %al,%eax
f0105b0b:	0f b6 12             	movzbl (%edx),%edx
f0105b0e:	29 d0                	sub    %edx,%eax
}
f0105b10:	5d                   	pop    %ebp
f0105b11:	c3                   	ret    

f0105b12 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105b12:	55                   	push   %ebp
f0105b13:	89 e5                	mov    %esp,%ebp
f0105b15:	53                   	push   %ebx
f0105b16:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b19:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105b1c:	89 c3                	mov    %eax,%ebx
f0105b1e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105b21:	eb 06                	jmp    f0105b29 <strncmp+0x17>
		n--, p++, q++;
f0105b23:	83 c0 01             	add    $0x1,%eax
f0105b26:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105b29:	39 d8                	cmp    %ebx,%eax
f0105b2b:	74 15                	je     f0105b42 <strncmp+0x30>
f0105b2d:	0f b6 08             	movzbl (%eax),%ecx
f0105b30:	84 c9                	test   %cl,%cl
f0105b32:	74 04                	je     f0105b38 <strncmp+0x26>
f0105b34:	3a 0a                	cmp    (%edx),%cl
f0105b36:	74 eb                	je     f0105b23 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105b38:	0f b6 00             	movzbl (%eax),%eax
f0105b3b:	0f b6 12             	movzbl (%edx),%edx
f0105b3e:	29 d0                	sub    %edx,%eax
f0105b40:	eb 05                	jmp    f0105b47 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0105b42:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0105b47:	5b                   	pop    %ebx
f0105b48:	5d                   	pop    %ebp
f0105b49:	c3                   	ret    

f0105b4a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105b4a:	55                   	push   %ebp
f0105b4b:	89 e5                	mov    %esp,%ebp
f0105b4d:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b50:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105b54:	eb 07                	jmp    f0105b5d <strchr+0x13>
		if (*s == c)
f0105b56:	38 ca                	cmp    %cl,%dl
f0105b58:	74 0f                	je     f0105b69 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0105b5a:	83 c0 01             	add    $0x1,%eax
f0105b5d:	0f b6 10             	movzbl (%eax),%edx
f0105b60:	84 d2                	test   %dl,%dl
f0105b62:	75 f2                	jne    f0105b56 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105b64:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105b69:	5d                   	pop    %ebp
f0105b6a:	c3                   	ret    

f0105b6b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105b6b:	55                   	push   %ebp
f0105b6c:	89 e5                	mov    %esp,%ebp
f0105b6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105b71:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105b75:	eb 07                	jmp    f0105b7e <strfind+0x13>
		if (*s == c)
f0105b77:	38 ca                	cmp    %cl,%dl
f0105b79:	74 0a                	je     f0105b85 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0105b7b:	83 c0 01             	add    $0x1,%eax
f0105b7e:	0f b6 10             	movzbl (%eax),%edx
f0105b81:	84 d2                	test   %dl,%dl
f0105b83:	75 f2                	jne    f0105b77 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0105b85:	5d                   	pop    %ebp
f0105b86:	c3                   	ret    

f0105b87 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105b87:	55                   	push   %ebp
f0105b88:	89 e5                	mov    %esp,%ebp
f0105b8a:	57                   	push   %edi
f0105b8b:	56                   	push   %esi
f0105b8c:	53                   	push   %ebx
f0105b8d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105b90:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105b93:	85 c9                	test   %ecx,%ecx
f0105b95:	74 36                	je     f0105bcd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105b97:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0105b9d:	75 28                	jne    f0105bc7 <memset+0x40>
f0105b9f:	f6 c1 03             	test   $0x3,%cl
f0105ba2:	75 23                	jne    f0105bc7 <memset+0x40>
		c &= 0xFF;
f0105ba4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105ba8:	89 d3                	mov    %edx,%ebx
f0105baa:	c1 e3 08             	shl    $0x8,%ebx
f0105bad:	89 d6                	mov    %edx,%esi
f0105baf:	c1 e6 18             	shl    $0x18,%esi
f0105bb2:	89 d0                	mov    %edx,%eax
f0105bb4:	c1 e0 10             	shl    $0x10,%eax
f0105bb7:	09 f0                	or     %esi,%eax
f0105bb9:	09 c2                	or     %eax,%edx
f0105bbb:	89 d0                	mov    %edx,%eax
f0105bbd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0105bbf:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0105bc2:	fc                   	cld    
f0105bc3:	f3 ab                	rep stos %eax,%es:(%edi)
f0105bc5:	eb 06                	jmp    f0105bcd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105bc7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105bca:	fc                   	cld    
f0105bcb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105bcd:	89 f8                	mov    %edi,%eax
f0105bcf:	5b                   	pop    %ebx
f0105bd0:	5e                   	pop    %esi
f0105bd1:	5f                   	pop    %edi
f0105bd2:	5d                   	pop    %ebp
f0105bd3:	c3                   	ret    

f0105bd4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105bd4:	55                   	push   %ebp
f0105bd5:	89 e5                	mov    %esp,%ebp
f0105bd7:	57                   	push   %edi
f0105bd8:	56                   	push   %esi
f0105bd9:	8b 45 08             	mov    0x8(%ebp),%eax
f0105bdc:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105bdf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105be2:	39 c6                	cmp    %eax,%esi
f0105be4:	73 35                	jae    f0105c1b <memmove+0x47>
f0105be6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105be9:	39 d0                	cmp    %edx,%eax
f0105beb:	73 2e                	jae    f0105c1b <memmove+0x47>
		s += n;
		d += n;
f0105bed:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0105bf0:	89 d6                	mov    %edx,%esi
f0105bf2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105bf4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105bfa:	75 13                	jne    f0105c0f <memmove+0x3b>
f0105bfc:	f6 c1 03             	test   $0x3,%cl
f0105bff:	75 0e                	jne    f0105c0f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105c01:	83 ef 04             	sub    $0x4,%edi
f0105c04:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105c07:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0105c0a:	fd                   	std    
f0105c0b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105c0d:	eb 09                	jmp    f0105c18 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0105c0f:	83 ef 01             	sub    $0x1,%edi
f0105c12:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105c15:	fd                   	std    
f0105c16:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105c18:	fc                   	cld    
f0105c19:	eb 1d                	jmp    f0105c38 <memmove+0x64>
f0105c1b:	89 f2                	mov    %esi,%edx
f0105c1d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105c1f:	f6 c2 03             	test   $0x3,%dl
f0105c22:	75 0f                	jne    f0105c33 <memmove+0x5f>
f0105c24:	f6 c1 03             	test   $0x3,%cl
f0105c27:	75 0a                	jne    f0105c33 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105c29:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0105c2c:	89 c7                	mov    %eax,%edi
f0105c2e:	fc                   	cld    
f0105c2f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105c31:	eb 05                	jmp    f0105c38 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105c33:	89 c7                	mov    %eax,%edi
f0105c35:	fc                   	cld    
f0105c36:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105c38:	5e                   	pop    %esi
f0105c39:	5f                   	pop    %edi
f0105c3a:	5d                   	pop    %ebp
f0105c3b:	c3                   	ret    

f0105c3c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105c3c:	55                   	push   %ebp
f0105c3d:	89 e5                	mov    %esp,%ebp
f0105c3f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105c42:	8b 45 10             	mov    0x10(%ebp),%eax
f0105c45:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105c49:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105c4c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105c50:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c53:	89 04 24             	mov    %eax,(%esp)
f0105c56:	e8 79 ff ff ff       	call   f0105bd4 <memmove>
}
f0105c5b:	c9                   	leave  
f0105c5c:	c3                   	ret    

f0105c5d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105c5d:	55                   	push   %ebp
f0105c5e:	89 e5                	mov    %esp,%ebp
f0105c60:	56                   	push   %esi
f0105c61:	53                   	push   %ebx
f0105c62:	8b 55 08             	mov    0x8(%ebp),%edx
f0105c65:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105c68:	89 d6                	mov    %edx,%esi
f0105c6a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105c6d:	eb 1a                	jmp    f0105c89 <memcmp+0x2c>
		if (*s1 != *s2)
f0105c6f:	0f b6 02             	movzbl (%edx),%eax
f0105c72:	0f b6 19             	movzbl (%ecx),%ebx
f0105c75:	38 d8                	cmp    %bl,%al
f0105c77:	74 0a                	je     f0105c83 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105c79:	0f b6 c0             	movzbl %al,%eax
f0105c7c:	0f b6 db             	movzbl %bl,%ebx
f0105c7f:	29 d8                	sub    %ebx,%eax
f0105c81:	eb 0f                	jmp    f0105c92 <memcmp+0x35>
		s1++, s2++;
f0105c83:	83 c2 01             	add    $0x1,%edx
f0105c86:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105c89:	39 f2                	cmp    %esi,%edx
f0105c8b:	75 e2                	jne    f0105c6f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0105c8d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105c92:	5b                   	pop    %ebx
f0105c93:	5e                   	pop    %esi
f0105c94:	5d                   	pop    %ebp
f0105c95:	c3                   	ret    

f0105c96 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105c96:	55                   	push   %ebp
f0105c97:	89 e5                	mov    %esp,%ebp
f0105c99:	8b 45 08             	mov    0x8(%ebp),%eax
f0105c9c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0105c9f:	89 c2                	mov    %eax,%edx
f0105ca1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105ca4:	eb 07                	jmp    f0105cad <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105ca6:	38 08                	cmp    %cl,(%eax)
f0105ca8:	74 07                	je     f0105cb1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105caa:	83 c0 01             	add    $0x1,%eax
f0105cad:	39 d0                	cmp    %edx,%eax
f0105caf:	72 f5                	jb     f0105ca6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0105cb1:	5d                   	pop    %ebp
f0105cb2:	c3                   	ret    

f0105cb3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105cb3:	55                   	push   %ebp
f0105cb4:	89 e5                	mov    %esp,%ebp
f0105cb6:	57                   	push   %edi
f0105cb7:	56                   	push   %esi
f0105cb8:	53                   	push   %ebx
f0105cb9:	8b 55 08             	mov    0x8(%ebp),%edx
f0105cbc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105cbf:	eb 03                	jmp    f0105cc4 <strtol+0x11>
		s++;
f0105cc1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105cc4:	0f b6 0a             	movzbl (%edx),%ecx
f0105cc7:	80 f9 09             	cmp    $0x9,%cl
f0105cca:	74 f5                	je     f0105cc1 <strtol+0xe>
f0105ccc:	80 f9 20             	cmp    $0x20,%cl
f0105ccf:	74 f0                	je     f0105cc1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0105cd1:	80 f9 2b             	cmp    $0x2b,%cl
f0105cd4:	75 0a                	jne    f0105ce0 <strtol+0x2d>
		s++;
f0105cd6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0105cd9:	bf 00 00 00 00       	mov    $0x0,%edi
f0105cde:	eb 11                	jmp    f0105cf1 <strtol+0x3e>
f0105ce0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105ce5:	80 f9 2d             	cmp    $0x2d,%cl
f0105ce8:	75 07                	jne    f0105cf1 <strtol+0x3e>
		s++, neg = 1;
f0105cea:	8d 52 01             	lea    0x1(%edx),%edx
f0105ced:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105cf1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0105cf6:	75 15                	jne    f0105d0d <strtol+0x5a>
f0105cf8:	80 3a 30             	cmpb   $0x30,(%edx)
f0105cfb:	75 10                	jne    f0105d0d <strtol+0x5a>
f0105cfd:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0105d01:	75 0a                	jne    f0105d0d <strtol+0x5a>
		s += 2, base = 16;
f0105d03:	83 c2 02             	add    $0x2,%edx
f0105d06:	b8 10 00 00 00       	mov    $0x10,%eax
f0105d0b:	eb 10                	jmp    f0105d1d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0105d0d:	85 c0                	test   %eax,%eax
f0105d0f:	75 0c                	jne    f0105d1d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105d11:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105d13:	80 3a 30             	cmpb   $0x30,(%edx)
f0105d16:	75 05                	jne    f0105d1d <strtol+0x6a>
		s++, base = 8;
f0105d18:	83 c2 01             	add    $0x1,%edx
f0105d1b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0105d1d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105d22:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105d25:	0f b6 0a             	movzbl (%edx),%ecx
f0105d28:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0105d2b:	89 f0                	mov    %esi,%eax
f0105d2d:	3c 09                	cmp    $0x9,%al
f0105d2f:	77 08                	ja     f0105d39 <strtol+0x86>
			dig = *s - '0';
f0105d31:	0f be c9             	movsbl %cl,%ecx
f0105d34:	83 e9 30             	sub    $0x30,%ecx
f0105d37:	eb 20                	jmp    f0105d59 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0105d39:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0105d3c:	89 f0                	mov    %esi,%eax
f0105d3e:	3c 19                	cmp    $0x19,%al
f0105d40:	77 08                	ja     f0105d4a <strtol+0x97>
			dig = *s - 'a' + 10;
f0105d42:	0f be c9             	movsbl %cl,%ecx
f0105d45:	83 e9 57             	sub    $0x57,%ecx
f0105d48:	eb 0f                	jmp    f0105d59 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0105d4a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0105d4d:	89 f0                	mov    %esi,%eax
f0105d4f:	3c 19                	cmp    $0x19,%al
f0105d51:	77 16                	ja     f0105d69 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0105d53:	0f be c9             	movsbl %cl,%ecx
f0105d56:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0105d59:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0105d5c:	7d 0f                	jge    f0105d6d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0105d5e:	83 c2 01             	add    $0x1,%edx
f0105d61:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0105d65:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0105d67:	eb bc                	jmp    f0105d25 <strtol+0x72>
f0105d69:	89 d8                	mov    %ebx,%eax
f0105d6b:	eb 02                	jmp    f0105d6f <strtol+0xbc>
f0105d6d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0105d6f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105d73:	74 05                	je     f0105d7a <strtol+0xc7>
		*endptr = (char *) s;
f0105d75:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105d78:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0105d7a:	f7 d8                	neg    %eax
f0105d7c:	85 ff                	test   %edi,%edi
f0105d7e:	0f 44 c3             	cmove  %ebx,%eax
}
f0105d81:	5b                   	pop    %ebx
f0105d82:	5e                   	pop    %esi
f0105d83:	5f                   	pop    %edi
f0105d84:	5d                   	pop    %ebp
f0105d85:	c3                   	ret    
f0105d86:	66 90                	xchg   %ax,%ax

f0105d88 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105d88:	fa                   	cli    

	xorw    %ax, %ax
f0105d89:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0105d8b:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105d8d:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105d8f:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105d91:	0f 01 16             	lgdtl  (%esi)
f0105d94:	74 70                	je     f0105e06 <mpentry_end+0x4>
	movl    %cr0, %eax
f0105d96:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0105d99:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105d9d:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105da0:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0105da6:	08 00                	or     %al,(%eax)

f0105da8 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0105da8:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105dac:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105dae:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105db0:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105db2:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0105db6:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0105db8:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0105dba:	b8 00 f0 11 00       	mov    $0x11f000,%eax
	movl    %eax, %cr3
f0105dbf:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105dc2:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105dc5:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0105dca:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105dcd:	8b 25 84 ce 22 f0    	mov    0xf022ce84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105dd3:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0105dd8:	b8 e2 01 10 f0       	mov    $0xf01001e2,%eax
	call    *%eax
f0105ddd:	ff d0                	call   *%eax

f0105ddf <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105ddf:	eb fe                	jmp    f0105ddf <spin>
f0105de1:	8d 76 00             	lea    0x0(%esi),%esi

f0105de4 <gdt>:
	...
f0105dec:	ff                   	(bad)  
f0105ded:	ff 00                	incl   (%eax)
f0105def:	00 00                	add    %al,(%eax)
f0105df1:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105df8:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f0105dfc <gdtdesc>:
f0105dfc:	17                   	pop    %ss
f0105dfd:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105e02 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105e02:	90                   	nop
f0105e03:	66 90                	xchg   %ax,%ax
f0105e05:	66 90                	xchg   %ax,%ax
f0105e07:	66 90                	xchg   %ax,%ax
f0105e09:	66 90                	xchg   %ax,%ax
f0105e0b:	66 90                	xchg   %ax,%ax
f0105e0d:	66 90                	xchg   %ax,%ax
f0105e0f:	90                   	nop

f0105e10 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105e10:	55                   	push   %ebp
f0105e11:	89 e5                	mov    %esp,%ebp
f0105e13:	56                   	push   %esi
f0105e14:	53                   	push   %ebx
f0105e15:	83 ec 10             	sub    $0x10,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105e18:	8b 0d 88 ce 22 f0    	mov    0xf022ce88,%ecx
f0105e1e:	89 c3                	mov    %eax,%ebx
f0105e20:	c1 eb 0c             	shr    $0xc,%ebx
f0105e23:	39 cb                	cmp    %ecx,%ebx
f0105e25:	72 20                	jb     f0105e47 <mpsearch1+0x37>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105e27:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105e2b:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0105e32:	f0 
f0105e33:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0105e3a:	00 
f0105e3b:	c7 04 24 25 86 10 f0 	movl   $0xf0108625,(%esp)
f0105e42:	e8 f9 a1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105e47:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105e4d:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105e4f:	89 c2                	mov    %eax,%edx
f0105e51:	c1 ea 0c             	shr    $0xc,%edx
f0105e54:	39 d1                	cmp    %edx,%ecx
f0105e56:	77 20                	ja     f0105e78 <mpsearch1+0x68>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105e58:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105e5c:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0105e63:	f0 
f0105e64:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0105e6b:	00 
f0105e6c:	c7 04 24 25 86 10 f0 	movl   $0xf0108625,(%esp)
f0105e73:	e8 c8 a1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105e78:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0105e7e:	eb 36                	jmp    f0105eb6 <mpsearch1+0xa6>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105e80:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0105e87:	00 
f0105e88:	c7 44 24 04 35 86 10 	movl   $0xf0108635,0x4(%esp)
f0105e8f:	f0 
f0105e90:	89 1c 24             	mov    %ebx,(%esp)
f0105e93:	e8 c5 fd ff ff       	call   f0105c5d <memcmp>
f0105e98:	85 c0                	test   %eax,%eax
f0105e9a:	75 17                	jne    f0105eb3 <mpsearch1+0xa3>
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105e9c:	ba 00 00 00 00       	mov    $0x0,%edx
		sum += ((uint8_t *)addr)[i];
f0105ea1:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0105ea5:	01 c8                	add    %ecx,%eax
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105ea7:	83 c2 01             	add    $0x1,%edx
f0105eaa:	83 fa 10             	cmp    $0x10,%edx
f0105ead:	75 f2                	jne    f0105ea1 <mpsearch1+0x91>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105eaf:	84 c0                	test   %al,%al
f0105eb1:	74 0e                	je     f0105ec1 <mpsearch1+0xb1>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105eb3:	83 c3 10             	add    $0x10,%ebx
f0105eb6:	39 f3                	cmp    %esi,%ebx
f0105eb8:	72 c6                	jb     f0105e80 <mpsearch1+0x70>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0105eba:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ebf:	eb 02                	jmp    f0105ec3 <mpsearch1+0xb3>
f0105ec1:	89 d8                	mov    %ebx,%eax
}
f0105ec3:	83 c4 10             	add    $0x10,%esp
f0105ec6:	5b                   	pop    %ebx
f0105ec7:	5e                   	pop    %esi
f0105ec8:	5d                   	pop    %ebp
f0105ec9:	c3                   	ret    

f0105eca <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105eca:	55                   	push   %ebp
f0105ecb:	89 e5                	mov    %esp,%ebp
f0105ecd:	57                   	push   %edi
f0105ece:	56                   	push   %esi
f0105ecf:	53                   	push   %ebx
f0105ed0:	83 ec 2c             	sub    $0x2c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105ed3:	c7 05 c0 d3 22 f0 20 	movl   $0xf022d020,0xf022d3c0
f0105eda:	d0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105edd:	83 3d 88 ce 22 f0 00 	cmpl   $0x0,0xf022ce88
f0105ee4:	75 24                	jne    f0105f0a <mp_init+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105ee6:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
f0105eed:	00 
f0105eee:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0105ef5:	f0 
f0105ef6:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f0105efd:	00 
f0105efe:	c7 04 24 25 86 10 f0 	movl   $0xf0108625,(%esp)
f0105f05:	e8 36 a1 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105f0a:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105f11:	85 c0                	test   %eax,%eax
f0105f13:	74 16                	je     f0105f2b <mp_init+0x61>
		p <<= 4;	// Translate from segment to PA
f0105f15:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105f18:	ba 00 04 00 00       	mov    $0x400,%edx
f0105f1d:	e8 ee fe ff ff       	call   f0105e10 <mpsearch1>
f0105f22:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105f25:	85 c0                	test   %eax,%eax
f0105f27:	75 3c                	jne    f0105f65 <mp_init+0x9b>
f0105f29:	eb 20                	jmp    f0105f4b <mp_init+0x81>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105f2b:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105f32:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105f35:	2d 00 04 00 00       	sub    $0x400,%eax
f0105f3a:	ba 00 04 00 00       	mov    $0x400,%edx
f0105f3f:	e8 cc fe ff ff       	call   f0105e10 <mpsearch1>
f0105f44:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105f47:	85 c0                	test   %eax,%eax
f0105f49:	75 1a                	jne    f0105f65 <mp_init+0x9b>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105f4b:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105f50:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105f55:	e8 b6 fe ff ff       	call   f0105e10 <mpsearch1>
f0105f5a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105f5d:	85 c0                	test   %eax,%eax
f0105f5f:	0f 84 54 02 00 00    	je     f01061b9 <mp_init+0x2ef>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105f65:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105f68:	8b 70 04             	mov    0x4(%eax),%esi
f0105f6b:	85 f6                	test   %esi,%esi
f0105f6d:	74 06                	je     f0105f75 <mp_init+0xab>
f0105f6f:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105f73:	74 11                	je     f0105f86 <mp_init+0xbc>
		cprintf("SMP: Default configurations not implemented\n");
f0105f75:	c7 04 24 98 84 10 f0 	movl   $0xf0108498,(%esp)
f0105f7c:	e8 ed e0 ff ff       	call   f010406e <cprintf>
f0105f81:	e9 33 02 00 00       	jmp    f01061b9 <mp_init+0x2ef>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105f86:	89 f0                	mov    %esi,%eax
f0105f88:	c1 e8 0c             	shr    $0xc,%eax
f0105f8b:	3b 05 88 ce 22 f0    	cmp    0xf022ce88,%eax
f0105f91:	72 20                	jb     f0105fb3 <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105f93:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105f97:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f0105f9e:	f0 
f0105f9f:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
f0105fa6:	00 
f0105fa7:	c7 04 24 25 86 10 f0 	movl   $0xf0108625,(%esp)
f0105fae:	e8 8d a0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105fb3:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105fb9:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0105fc0:	00 
f0105fc1:	c7 44 24 04 3a 86 10 	movl   $0xf010863a,0x4(%esp)
f0105fc8:	f0 
f0105fc9:	89 1c 24             	mov    %ebx,(%esp)
f0105fcc:	e8 8c fc ff ff       	call   f0105c5d <memcmp>
f0105fd1:	85 c0                	test   %eax,%eax
f0105fd3:	74 11                	je     f0105fe6 <mp_init+0x11c>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105fd5:	c7 04 24 c8 84 10 f0 	movl   $0xf01084c8,(%esp)
f0105fdc:	e8 8d e0 ff ff       	call   f010406e <cprintf>
f0105fe1:	e9 d3 01 00 00       	jmp    f01061b9 <mp_init+0x2ef>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105fe6:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f0105fea:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f0105fee:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105ff1:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105ff6:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ffb:	eb 0d                	jmp    f010600a <mp_init+0x140>
		sum += ((uint8_t *)addr)[i];
f0105ffd:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0106004:	f0 
f0106005:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0106007:	83 c0 01             	add    $0x1,%eax
f010600a:	39 c7                	cmp    %eax,%edi
f010600c:	7f ef                	jg     f0105ffd <mp_init+0x133>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010600e:	84 d2                	test   %dl,%dl
f0106010:	74 11                	je     f0106023 <mp_init+0x159>
		cprintf("SMP: Bad MP configuration checksum\n");
f0106012:	c7 04 24 fc 84 10 f0 	movl   $0xf01084fc,(%esp)
f0106019:	e8 50 e0 ff ff       	call   f010406e <cprintf>
f010601e:	e9 96 01 00 00       	jmp    f01061b9 <mp_init+0x2ef>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0106023:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0106027:	3c 04                	cmp    $0x4,%al
f0106029:	74 1f                	je     f010604a <mp_init+0x180>
f010602b:	3c 01                	cmp    $0x1,%al
f010602d:	8d 76 00             	lea    0x0(%esi),%esi
f0106030:	74 18                	je     f010604a <mp_init+0x180>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0106032:	0f b6 c0             	movzbl %al,%eax
f0106035:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106039:	c7 04 24 20 85 10 f0 	movl   $0xf0108520,(%esp)
f0106040:	e8 29 e0 ff ff       	call   f010406e <cprintf>
f0106045:	e9 6f 01 00 00       	jmp    f01061b9 <mp_init+0x2ef>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010604a:	0f b7 73 28          	movzwl 0x28(%ebx),%esi
f010604e:	0f b7 7d e2          	movzwl -0x1e(%ebp),%edi
f0106052:	01 df                	add    %ebx,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0106054:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0106059:	b8 00 00 00 00       	mov    $0x0,%eax
f010605e:	eb 09                	jmp    f0106069 <mp_init+0x19f>
		sum += ((uint8_t *)addr)[i];
f0106060:	0f b6 0c 07          	movzbl (%edi,%eax,1),%ecx
f0106064:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0106066:	83 c0 01             	add    $0x1,%eax
f0106069:	39 c6                	cmp    %eax,%esi
f010606b:	7f f3                	jg     f0106060 <mp_init+0x196>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010606d:	02 53 2a             	add    0x2a(%ebx),%dl
f0106070:	84 d2                	test   %dl,%dl
f0106072:	74 11                	je     f0106085 <mp_init+0x1bb>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0106074:	c7 04 24 40 85 10 f0 	movl   $0xf0108540,(%esp)
f010607b:	e8 ee df ff ff       	call   f010406e <cprintf>
f0106080:	e9 34 01 00 00       	jmp    f01061b9 <mp_init+0x2ef>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0106085:	85 db                	test   %ebx,%ebx
f0106087:	0f 84 2c 01 00 00    	je     f01061b9 <mp_init+0x2ef>
		return;
	ismp = 1;
f010608d:	c7 05 00 d0 22 f0 01 	movl   $0x1,0xf022d000
f0106094:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0106097:	8b 43 24             	mov    0x24(%ebx),%eax
f010609a:	a3 00 e0 26 f0       	mov    %eax,0xf026e000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010609f:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f01060a2:	be 00 00 00 00       	mov    $0x0,%esi
f01060a7:	e9 86 00 00 00       	jmp    f0106132 <mp_init+0x268>
		switch (*p) {
f01060ac:	0f b6 07             	movzbl (%edi),%eax
f01060af:	84 c0                	test   %al,%al
f01060b1:	74 06                	je     f01060b9 <mp_init+0x1ef>
f01060b3:	3c 04                	cmp    $0x4,%al
f01060b5:	77 57                	ja     f010610e <mp_init+0x244>
f01060b7:	eb 50                	jmp    f0106109 <mp_init+0x23f>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01060b9:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01060bd:	8d 76 00             	lea    0x0(%esi),%esi
f01060c0:	74 11                	je     f01060d3 <mp_init+0x209>
				bootcpu = &cpus[ncpu];
f01060c2:	6b 05 c4 d3 22 f0 74 	imul   $0x74,0xf022d3c4,%eax
f01060c9:	05 20 d0 22 f0       	add    $0xf022d020,%eax
f01060ce:	a3 c0 d3 22 f0       	mov    %eax,0xf022d3c0
			if (ncpu < NCPU) {
f01060d3:	a1 c4 d3 22 f0       	mov    0xf022d3c4,%eax
f01060d8:	83 f8 07             	cmp    $0x7,%eax
f01060db:	7f 13                	jg     f01060f0 <mp_init+0x226>
				cpus[ncpu].cpu_id = ncpu;
f01060dd:	6b d0 74             	imul   $0x74,%eax,%edx
f01060e0:	88 82 20 d0 22 f0    	mov    %al,-0xfdd2fe0(%edx)
				ncpu++;
f01060e6:	83 c0 01             	add    $0x1,%eax
f01060e9:	a3 c4 d3 22 f0       	mov    %eax,0xf022d3c4
f01060ee:	eb 14                	jmp    f0106104 <mp_init+0x23a>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01060f0:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01060f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01060f8:	c7 04 24 70 85 10 f0 	movl   $0xf0108570,(%esp)
f01060ff:	e8 6a df ff ff       	call   f010406e <cprintf>
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0106104:	83 c7 14             	add    $0x14,%edi
			continue;
f0106107:	eb 26                	jmp    f010612f <mp_init+0x265>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0106109:	83 c7 08             	add    $0x8,%edi
			continue;
f010610c:	eb 21                	jmp    f010612f <mp_init+0x265>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f010610e:	0f b6 c0             	movzbl %al,%eax
f0106111:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106115:	c7 04 24 98 85 10 f0 	movl   $0xf0108598,(%esp)
f010611c:	e8 4d df ff ff       	call   f010406e <cprintf>
			ismp = 0;
f0106121:	c7 05 00 d0 22 f0 00 	movl   $0x0,0xf022d000
f0106128:	00 00 00 
			i = conf->entry;
f010612b:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f010612f:	83 c6 01             	add    $0x1,%esi
f0106132:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0106136:	39 c6                	cmp    %eax,%esi
f0106138:	0f 82 6e ff ff ff    	jb     f01060ac <mp_init+0x1e2>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f010613e:	a1 c0 d3 22 f0       	mov    0xf022d3c0,%eax
f0106143:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010614a:	83 3d 00 d0 22 f0 00 	cmpl   $0x0,0xf022d000
f0106151:	75 22                	jne    f0106175 <mp_init+0x2ab>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0106153:	c7 05 c4 d3 22 f0 01 	movl   $0x1,0xf022d3c4
f010615a:	00 00 00 
		lapicaddr = 0;
f010615d:	c7 05 00 e0 26 f0 00 	movl   $0x0,0xf026e000
f0106164:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0106167:	c7 04 24 b8 85 10 f0 	movl   $0xf01085b8,(%esp)
f010616e:	e8 fb de ff ff       	call   f010406e <cprintf>
		return;
f0106173:	eb 44                	jmp    f01061b9 <mp_init+0x2ef>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0106175:	8b 15 c4 d3 22 f0    	mov    0xf022d3c4,%edx
f010617b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010617f:	0f b6 00             	movzbl (%eax),%eax
f0106182:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106186:	c7 04 24 3f 86 10 f0 	movl   $0xf010863f,(%esp)
f010618d:	e8 dc de ff ff       	call   f010406e <cprintf>

	if (mp->imcrp) {
f0106192:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0106195:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0106199:	74 1e                	je     f01061b9 <mp_init+0x2ef>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f010619b:	c7 04 24 e4 85 10 f0 	movl   $0xf01085e4,(%esp)
f01061a2:	e8 c7 de ff ff       	call   f010406e <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01061a7:	ba 22 00 00 00       	mov    $0x22,%edx
f01061ac:	b8 70 00 00 00       	mov    $0x70,%eax
f01061b1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01061b2:	b2 23                	mov    $0x23,%dl
f01061b4:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f01061b5:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01061b8:	ee                   	out    %al,(%dx)
	}
}
f01061b9:	83 c4 2c             	add    $0x2c,%esp
f01061bc:	5b                   	pop    %ebx
f01061bd:	5e                   	pop    %esi
f01061be:	5f                   	pop    %edi
f01061bf:	5d                   	pop    %ebp
f01061c0:	c3                   	ret    

f01061c1 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01061c1:	55                   	push   %ebp
f01061c2:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01061c4:	8b 0d 04 e0 26 f0    	mov    0xf026e004,%ecx
f01061ca:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01061cd:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01061cf:	a1 04 e0 26 f0       	mov    0xf026e004,%eax
f01061d4:	8b 40 20             	mov    0x20(%eax),%eax
}
f01061d7:	5d                   	pop    %ebp
f01061d8:	c3                   	ret    

f01061d9 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01061d9:	55                   	push   %ebp
f01061da:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01061dc:	a1 04 e0 26 f0       	mov    0xf026e004,%eax
f01061e1:	85 c0                	test   %eax,%eax
f01061e3:	74 08                	je     f01061ed <cpunum+0x14>
		return lapic[ID] >> 24;
f01061e5:	8b 40 20             	mov    0x20(%eax),%eax
f01061e8:	c1 e8 18             	shr    $0x18,%eax
f01061eb:	eb 05                	jmp    f01061f2 <cpunum+0x19>
	return 0;
f01061ed:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01061f2:	5d                   	pop    %ebp
f01061f3:	c3                   	ret    

f01061f4 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f01061f4:	a1 00 e0 26 f0       	mov    0xf026e000,%eax
f01061f9:	85 c0                	test   %eax,%eax
f01061fb:	0f 84 23 01 00 00    	je     f0106324 <lapic_init+0x130>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0106201:	55                   	push   %ebp
f0106202:	89 e5                	mov    %esp,%ebp
f0106204:	83 ec 18             	sub    $0x18,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0106207:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010620e:	00 
f010620f:	89 04 24             	mov    %eax,(%esp)
f0106212:	e8 1b b3 ff ff       	call   f0101532 <mmio_map_region>
f0106217:	a3 04 e0 26 f0       	mov    %eax,0xf026e004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f010621c:	ba 27 01 00 00       	mov    $0x127,%edx
f0106221:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0106226:	e8 96 ff ff ff       	call   f01061c1 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f010622b:	ba 0b 00 00 00       	mov    $0xb,%edx
f0106230:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0106235:	e8 87 ff ff ff       	call   f01061c1 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f010623a:	ba 20 00 02 00       	mov    $0x20020,%edx
f010623f:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0106244:	e8 78 ff ff ff       	call   f01061c1 <lapicw>
	lapicw(TICR, 10000000); 
f0106249:	ba 80 96 98 00       	mov    $0x989680,%edx
f010624e:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0106253:	e8 69 ff ff ff       	call   f01061c1 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0106258:	e8 7c ff ff ff       	call   f01061d9 <cpunum>
f010625d:	6b c0 74             	imul   $0x74,%eax,%eax
f0106260:	05 20 d0 22 f0       	add    $0xf022d020,%eax
f0106265:	39 05 c0 d3 22 f0    	cmp    %eax,0xf022d3c0
f010626b:	74 0f                	je     f010627c <lapic_init+0x88>
		lapicw(LINT0, MASKED);
f010626d:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106272:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0106277:	e8 45 ff ff ff       	call   f01061c1 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f010627c:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106281:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0106286:	e8 36 ff ff ff       	call   f01061c1 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f010628b:	a1 04 e0 26 f0       	mov    0xf026e004,%eax
f0106290:	8b 40 30             	mov    0x30(%eax),%eax
f0106293:	c1 e8 10             	shr    $0x10,%eax
f0106296:	3c 03                	cmp    $0x3,%al
f0106298:	76 0f                	jbe    f01062a9 <lapic_init+0xb5>
		lapicw(PCINT, MASKED);
f010629a:	ba 00 00 01 00       	mov    $0x10000,%edx
f010629f:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01062a4:	e8 18 ff ff ff       	call   f01061c1 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f01062a9:	ba 33 00 00 00       	mov    $0x33,%edx
f01062ae:	b8 dc 00 00 00       	mov    $0xdc,%eax
f01062b3:	e8 09 ff ff ff       	call   f01061c1 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f01062b8:	ba 00 00 00 00       	mov    $0x0,%edx
f01062bd:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01062c2:	e8 fa fe ff ff       	call   f01061c1 <lapicw>
	lapicw(ESR, 0);
f01062c7:	ba 00 00 00 00       	mov    $0x0,%edx
f01062cc:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01062d1:	e8 eb fe ff ff       	call   f01061c1 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f01062d6:	ba 00 00 00 00       	mov    $0x0,%edx
f01062db:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01062e0:	e8 dc fe ff ff       	call   f01061c1 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f01062e5:	ba 00 00 00 00       	mov    $0x0,%edx
f01062ea:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01062ef:	e8 cd fe ff ff       	call   f01061c1 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f01062f4:	ba 00 85 08 00       	mov    $0x88500,%edx
f01062f9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01062fe:	e8 be fe ff ff       	call   f01061c1 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0106303:	8b 15 04 e0 26 f0    	mov    0xf026e004,%edx
f0106309:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010630f:	f6 c4 10             	test   $0x10,%ah
f0106312:	75 f5                	jne    f0106309 <lapic_init+0x115>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0106314:	ba 00 00 00 00       	mov    $0x0,%edx
f0106319:	b8 20 00 00 00       	mov    $0x20,%eax
f010631e:	e8 9e fe ff ff       	call   f01061c1 <lapicw>
}
f0106323:	c9                   	leave  
f0106324:	f3 c3                	repz ret 

f0106326 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0106326:	83 3d 04 e0 26 f0 00 	cmpl   $0x0,0xf026e004
f010632d:	74 13                	je     f0106342 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010632f:	55                   	push   %ebp
f0106330:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0106332:	ba 00 00 00 00       	mov    $0x0,%edx
f0106337:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010633c:	e8 80 fe ff ff       	call   f01061c1 <lapicw>
}
f0106341:	5d                   	pop    %ebp
f0106342:	f3 c3                	repz ret 

f0106344 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0106344:	55                   	push   %ebp
f0106345:	89 e5                	mov    %esp,%ebp
f0106347:	56                   	push   %esi
f0106348:	53                   	push   %ebx
f0106349:	83 ec 10             	sub    $0x10,%esp
f010634c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010634f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0106352:	ba 70 00 00 00       	mov    $0x70,%edx
f0106357:	b8 0f 00 00 00       	mov    $0xf,%eax
f010635c:	ee                   	out    %al,(%dx)
f010635d:	b2 71                	mov    $0x71,%dl
f010635f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0106364:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0106365:	83 3d 88 ce 22 f0 00 	cmpl   $0x0,0xf022ce88
f010636c:	75 24                	jne    f0106392 <lapic_startap+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010636e:	c7 44 24 0c 67 04 00 	movl   $0x467,0xc(%esp)
f0106375:	00 
f0106376:	c7 44 24 08 e4 68 10 	movl   $0xf01068e4,0x8(%esp)
f010637d:	f0 
f010637e:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f0106385:	00 
f0106386:	c7 04 24 5c 86 10 f0 	movl   $0xf010865c,(%esp)
f010638d:	e8 ae 9c ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0106392:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0106399:	00 00 
	wrv[1] = addr >> 4;
f010639b:	89 f0                	mov    %esi,%eax
f010639d:	c1 e8 04             	shr    $0x4,%eax
f01063a0:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01063a6:	c1 e3 18             	shl    $0x18,%ebx
f01063a9:	89 da                	mov    %ebx,%edx
f01063ab:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01063b0:	e8 0c fe ff ff       	call   f01061c1 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f01063b5:	ba 00 c5 00 00       	mov    $0xc500,%edx
f01063ba:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01063bf:	e8 fd fd ff ff       	call   f01061c1 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f01063c4:	ba 00 85 00 00       	mov    $0x8500,%edx
f01063c9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01063ce:	e8 ee fd ff ff       	call   f01061c1 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01063d3:	c1 ee 0c             	shr    $0xc,%esi
f01063d6:	81 ce 00 06 00 00    	or     $0x600,%esi
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01063dc:	89 da                	mov    %ebx,%edx
f01063de:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01063e3:	e8 d9 fd ff ff       	call   f01061c1 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01063e8:	89 f2                	mov    %esi,%edx
f01063ea:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01063ef:	e8 cd fd ff ff       	call   f01061c1 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01063f4:	89 da                	mov    %ebx,%edx
f01063f6:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01063fb:	e8 c1 fd ff ff       	call   f01061c1 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106400:	89 f2                	mov    %esi,%edx
f0106402:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106407:	e8 b5 fd ff ff       	call   f01061c1 <lapicw>
		microdelay(200);
	}
}
f010640c:	83 c4 10             	add    $0x10,%esp
f010640f:	5b                   	pop    %ebx
f0106410:	5e                   	pop    %esi
f0106411:	5d                   	pop    %ebp
f0106412:	c3                   	ret    

f0106413 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0106413:	55                   	push   %ebp
f0106414:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0106416:	8b 55 08             	mov    0x8(%ebp),%edx
f0106419:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010641f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106424:	e8 98 fd ff ff       	call   f01061c1 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0106429:	8b 15 04 e0 26 f0    	mov    0xf026e004,%edx
f010642f:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0106435:	f6 c4 10             	test   $0x10,%ah
f0106438:	75 f5                	jne    f010642f <lapic_ipi+0x1c>
		;
}
f010643a:	5d                   	pop    %ebp
f010643b:	c3                   	ret    

f010643c <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f010643c:	55                   	push   %ebp
f010643d:	89 e5                	mov    %esp,%ebp
f010643f:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0106442:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0106448:	8b 55 0c             	mov    0xc(%ebp),%edx
f010644b:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f010644e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0106455:	5d                   	pop    %ebp
f0106456:	c3                   	ret    

f0106457 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0106457:	55                   	push   %ebp
f0106458:	89 e5                	mov    %esp,%ebp
f010645a:	56                   	push   %esi
f010645b:	53                   	push   %ebx
f010645c:	83 ec 20             	sub    $0x20,%esp
f010645f:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0106462:	83 3b 00             	cmpl   $0x0,(%ebx)
f0106465:	75 07                	jne    f010646e <spin_lock+0x17>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0106467:	ba 01 00 00 00       	mov    $0x1,%edx
f010646c:	eb 42                	jmp    f01064b0 <spin_lock+0x59>
f010646e:	8b 73 08             	mov    0x8(%ebx),%esi
f0106471:	e8 63 fd ff ff       	call   f01061d9 <cpunum>
f0106476:	6b c0 74             	imul   $0x74,%eax,%eax
f0106479:	05 20 d0 22 f0       	add    $0xf022d020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f010647e:	39 c6                	cmp    %eax,%esi
f0106480:	75 e5                	jne    f0106467 <spin_lock+0x10>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0106482:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0106485:	e8 4f fd ff ff       	call   f01061d9 <cpunum>
f010648a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f010648e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0106492:	c7 44 24 08 6c 86 10 	movl   $0xf010866c,0x8(%esp)
f0106499:	f0 
f010649a:	c7 44 24 04 41 00 00 	movl   $0x41,0x4(%esp)
f01064a1:	00 
f01064a2:	c7 04 24 d0 86 10 f0 	movl   $0xf01086d0,(%esp)
f01064a9:	e8 92 9b ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f01064ae:	f3 90                	pause  
f01064b0:	89 d0                	mov    %edx,%eax
f01064b2:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f01064b5:	85 c0                	test   %eax,%eax
f01064b7:	75 f5                	jne    f01064ae <spin_lock+0x57>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f01064b9:	e8 1b fd ff ff       	call   f01061d9 <cpunum>
f01064be:	6b c0 74             	imul   $0x74,%eax,%eax
f01064c1:	05 20 d0 22 f0       	add    $0xf022d020,%eax
f01064c6:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f01064c9:	83 c3 0c             	add    $0xc,%ebx
get_caller_pcs(uint32_t pcs[])
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
f01064cc:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f01064ce:	b8 00 00 00 00       	mov    $0x0,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f01064d3:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f01064d9:	76 12                	jbe    f01064ed <spin_lock+0x96>
			break;
		pcs[i] = ebp[1];          // saved %eip
f01064db:	8b 4a 04             	mov    0x4(%edx),%ecx
f01064de:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f01064e1:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01064e3:	83 c0 01             	add    $0x1,%eax
f01064e6:	83 f8 0a             	cmp    $0xa,%eax
f01064e9:	75 e8                	jne    f01064d3 <spin_lock+0x7c>
f01064eb:	eb 0f                	jmp    f01064fc <spin_lock+0xa5>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f01064ed:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f01064f4:	83 c0 01             	add    $0x1,%eax
f01064f7:	83 f8 09             	cmp    $0x9,%eax
f01064fa:	7e f1                	jle    f01064ed <spin_lock+0x96>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f01064fc:	83 c4 20             	add    $0x20,%esp
f01064ff:	5b                   	pop    %ebx
f0106500:	5e                   	pop    %esi
f0106501:	5d                   	pop    %ebp
f0106502:	c3                   	ret    

f0106503 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0106503:	55                   	push   %ebp
f0106504:	89 e5                	mov    %esp,%ebp
f0106506:	57                   	push   %edi
f0106507:	56                   	push   %esi
f0106508:	53                   	push   %ebx
f0106509:	83 ec 6c             	sub    $0x6c,%esp
f010650c:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f010650f:	83 3e 00             	cmpl   $0x0,(%esi)
f0106512:	74 18                	je     f010652c <spin_unlock+0x29>
f0106514:	8b 5e 08             	mov    0x8(%esi),%ebx
f0106517:	e8 bd fc ff ff       	call   f01061d9 <cpunum>
f010651c:	6b c0 74             	imul   $0x74,%eax,%eax
f010651f:	05 20 d0 22 f0       	add    $0xf022d020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0106524:	39 c3                	cmp    %eax,%ebx
f0106526:	0f 84 ce 00 00 00    	je     f01065fa <spin_unlock+0xf7>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f010652c:	c7 44 24 08 28 00 00 	movl   $0x28,0x8(%esp)
f0106533:	00 
f0106534:	8d 46 0c             	lea    0xc(%esi),%eax
f0106537:	89 44 24 04          	mov    %eax,0x4(%esp)
f010653b:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f010653e:	89 1c 24             	mov    %ebx,(%esp)
f0106541:	e8 8e f6 ff ff       	call   f0105bd4 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0106546:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0106549:	0f b6 38             	movzbl (%eax),%edi
f010654c:	8b 76 04             	mov    0x4(%esi),%esi
f010654f:	e8 85 fc ff ff       	call   f01061d9 <cpunum>
f0106554:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106558:	89 74 24 08          	mov    %esi,0x8(%esp)
f010655c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106560:	c7 04 24 98 86 10 f0 	movl   $0xf0108698,(%esp)
f0106567:	e8 02 db ff ff       	call   f010406e <cprintf>
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f010656c:	8d 7d a8             	lea    -0x58(%ebp),%edi
f010656f:	eb 65                	jmp    f01065d6 <spin_unlock+0xd3>
f0106571:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0106575:	89 04 24             	mov    %eax,(%esp)
f0106578:	e8 5c eb ff ff       	call   f01050d9 <debuginfo_eip>
f010657d:	85 c0                	test   %eax,%eax
f010657f:	78 39                	js     f01065ba <spin_unlock+0xb7>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0106581:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0106583:	89 c2                	mov    %eax,%edx
f0106585:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0106588:	89 54 24 18          	mov    %edx,0x18(%esp)
f010658c:	8b 55 b0             	mov    -0x50(%ebp),%edx
f010658f:	89 54 24 14          	mov    %edx,0x14(%esp)
f0106593:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f0106596:	89 54 24 10          	mov    %edx,0x10(%esp)
f010659a:	8b 55 ac             	mov    -0x54(%ebp),%edx
f010659d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01065a1:	8b 55 a8             	mov    -0x58(%ebp),%edx
f01065a4:	89 54 24 08          	mov    %edx,0x8(%esp)
f01065a8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01065ac:	c7 04 24 e0 86 10 f0 	movl   $0xf01086e0,(%esp)
f01065b3:	e8 b6 da ff ff       	call   f010406e <cprintf>
f01065b8:	eb 12                	jmp    f01065cc <spin_unlock+0xc9>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f01065ba:	8b 06                	mov    (%esi),%eax
f01065bc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01065c0:	c7 04 24 f7 86 10 f0 	movl   $0xf01086f7,(%esp)
f01065c7:	e8 a2 da ff ff       	call   f010406e <cprintf>
f01065cc:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f01065cf:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01065d2:	39 c3                	cmp    %eax,%ebx
f01065d4:	74 08                	je     f01065de <spin_unlock+0xdb>
f01065d6:	89 de                	mov    %ebx,%esi
f01065d8:	8b 03                	mov    (%ebx),%eax
f01065da:	85 c0                	test   %eax,%eax
f01065dc:	75 93                	jne    f0106571 <spin_unlock+0x6e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f01065de:	c7 44 24 08 ff 86 10 	movl   $0xf01086ff,0x8(%esp)
f01065e5:	f0 
f01065e6:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
f01065ed:	00 
f01065ee:	c7 04 24 d0 86 10 f0 	movl   $0xf01086d0,(%esp)
f01065f5:	e8 46 9a ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f01065fa:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0106601:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f0106608:	b8 00 00 00 00       	mov    $0x0,%eax
f010660d:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0106610:	83 c4 6c             	add    $0x6c,%esp
f0106613:	5b                   	pop    %ebx
f0106614:	5e                   	pop    %esi
f0106615:	5f                   	pop    %edi
f0106616:	5d                   	pop    %ebp
f0106617:	c3                   	ret    
f0106618:	66 90                	xchg   %ax,%ax
f010661a:	66 90                	xchg   %ax,%ax
f010661c:	66 90                	xchg   %ax,%ax
f010661e:	66 90                	xchg   %ax,%ax

f0106620 <__udivdi3>:
f0106620:	55                   	push   %ebp
f0106621:	57                   	push   %edi
f0106622:	56                   	push   %esi
f0106623:	83 ec 0c             	sub    $0xc,%esp
f0106626:	8b 44 24 28          	mov    0x28(%esp),%eax
f010662a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010662e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0106632:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0106636:	85 c0                	test   %eax,%eax
f0106638:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010663c:	89 ea                	mov    %ebp,%edx
f010663e:	89 0c 24             	mov    %ecx,(%esp)
f0106641:	75 2d                	jne    f0106670 <__udivdi3+0x50>
f0106643:	39 e9                	cmp    %ebp,%ecx
f0106645:	77 61                	ja     f01066a8 <__udivdi3+0x88>
f0106647:	85 c9                	test   %ecx,%ecx
f0106649:	89 ce                	mov    %ecx,%esi
f010664b:	75 0b                	jne    f0106658 <__udivdi3+0x38>
f010664d:	b8 01 00 00 00       	mov    $0x1,%eax
f0106652:	31 d2                	xor    %edx,%edx
f0106654:	f7 f1                	div    %ecx
f0106656:	89 c6                	mov    %eax,%esi
f0106658:	31 d2                	xor    %edx,%edx
f010665a:	89 e8                	mov    %ebp,%eax
f010665c:	f7 f6                	div    %esi
f010665e:	89 c5                	mov    %eax,%ebp
f0106660:	89 f8                	mov    %edi,%eax
f0106662:	f7 f6                	div    %esi
f0106664:	89 ea                	mov    %ebp,%edx
f0106666:	83 c4 0c             	add    $0xc,%esp
f0106669:	5e                   	pop    %esi
f010666a:	5f                   	pop    %edi
f010666b:	5d                   	pop    %ebp
f010666c:	c3                   	ret    
f010666d:	8d 76 00             	lea    0x0(%esi),%esi
f0106670:	39 e8                	cmp    %ebp,%eax
f0106672:	77 24                	ja     f0106698 <__udivdi3+0x78>
f0106674:	0f bd e8             	bsr    %eax,%ebp
f0106677:	83 f5 1f             	xor    $0x1f,%ebp
f010667a:	75 3c                	jne    f01066b8 <__udivdi3+0x98>
f010667c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0106680:	39 34 24             	cmp    %esi,(%esp)
f0106683:	0f 86 9f 00 00 00    	jbe    f0106728 <__udivdi3+0x108>
f0106689:	39 d0                	cmp    %edx,%eax
f010668b:	0f 82 97 00 00 00    	jb     f0106728 <__udivdi3+0x108>
f0106691:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106698:	31 d2                	xor    %edx,%edx
f010669a:	31 c0                	xor    %eax,%eax
f010669c:	83 c4 0c             	add    $0xc,%esp
f010669f:	5e                   	pop    %esi
f01066a0:	5f                   	pop    %edi
f01066a1:	5d                   	pop    %ebp
f01066a2:	c3                   	ret    
f01066a3:	90                   	nop
f01066a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01066a8:	89 f8                	mov    %edi,%eax
f01066aa:	f7 f1                	div    %ecx
f01066ac:	31 d2                	xor    %edx,%edx
f01066ae:	83 c4 0c             	add    $0xc,%esp
f01066b1:	5e                   	pop    %esi
f01066b2:	5f                   	pop    %edi
f01066b3:	5d                   	pop    %ebp
f01066b4:	c3                   	ret    
f01066b5:	8d 76 00             	lea    0x0(%esi),%esi
f01066b8:	89 e9                	mov    %ebp,%ecx
f01066ba:	8b 3c 24             	mov    (%esp),%edi
f01066bd:	d3 e0                	shl    %cl,%eax
f01066bf:	89 c6                	mov    %eax,%esi
f01066c1:	b8 20 00 00 00       	mov    $0x20,%eax
f01066c6:	29 e8                	sub    %ebp,%eax
f01066c8:	89 c1                	mov    %eax,%ecx
f01066ca:	d3 ef                	shr    %cl,%edi
f01066cc:	89 e9                	mov    %ebp,%ecx
f01066ce:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01066d2:	8b 3c 24             	mov    (%esp),%edi
f01066d5:	09 74 24 08          	or     %esi,0x8(%esp)
f01066d9:	89 d6                	mov    %edx,%esi
f01066db:	d3 e7                	shl    %cl,%edi
f01066dd:	89 c1                	mov    %eax,%ecx
f01066df:	89 3c 24             	mov    %edi,(%esp)
f01066e2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01066e6:	d3 ee                	shr    %cl,%esi
f01066e8:	89 e9                	mov    %ebp,%ecx
f01066ea:	d3 e2                	shl    %cl,%edx
f01066ec:	89 c1                	mov    %eax,%ecx
f01066ee:	d3 ef                	shr    %cl,%edi
f01066f0:	09 d7                	or     %edx,%edi
f01066f2:	89 f2                	mov    %esi,%edx
f01066f4:	89 f8                	mov    %edi,%eax
f01066f6:	f7 74 24 08          	divl   0x8(%esp)
f01066fa:	89 d6                	mov    %edx,%esi
f01066fc:	89 c7                	mov    %eax,%edi
f01066fe:	f7 24 24             	mull   (%esp)
f0106701:	39 d6                	cmp    %edx,%esi
f0106703:	89 14 24             	mov    %edx,(%esp)
f0106706:	72 30                	jb     f0106738 <__udivdi3+0x118>
f0106708:	8b 54 24 04          	mov    0x4(%esp),%edx
f010670c:	89 e9                	mov    %ebp,%ecx
f010670e:	d3 e2                	shl    %cl,%edx
f0106710:	39 c2                	cmp    %eax,%edx
f0106712:	73 05                	jae    f0106719 <__udivdi3+0xf9>
f0106714:	3b 34 24             	cmp    (%esp),%esi
f0106717:	74 1f                	je     f0106738 <__udivdi3+0x118>
f0106719:	89 f8                	mov    %edi,%eax
f010671b:	31 d2                	xor    %edx,%edx
f010671d:	e9 7a ff ff ff       	jmp    f010669c <__udivdi3+0x7c>
f0106722:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106728:	31 d2                	xor    %edx,%edx
f010672a:	b8 01 00 00 00       	mov    $0x1,%eax
f010672f:	e9 68 ff ff ff       	jmp    f010669c <__udivdi3+0x7c>
f0106734:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106738:	8d 47 ff             	lea    -0x1(%edi),%eax
f010673b:	31 d2                	xor    %edx,%edx
f010673d:	83 c4 0c             	add    $0xc,%esp
f0106740:	5e                   	pop    %esi
f0106741:	5f                   	pop    %edi
f0106742:	5d                   	pop    %ebp
f0106743:	c3                   	ret    
f0106744:	66 90                	xchg   %ax,%ax
f0106746:	66 90                	xchg   %ax,%ax
f0106748:	66 90                	xchg   %ax,%ax
f010674a:	66 90                	xchg   %ax,%ax
f010674c:	66 90                	xchg   %ax,%ax
f010674e:	66 90                	xchg   %ax,%ax

f0106750 <__umoddi3>:
f0106750:	55                   	push   %ebp
f0106751:	57                   	push   %edi
f0106752:	56                   	push   %esi
f0106753:	83 ec 14             	sub    $0x14,%esp
f0106756:	8b 44 24 28          	mov    0x28(%esp),%eax
f010675a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010675e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0106762:	89 c7                	mov    %eax,%edi
f0106764:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106768:	8b 44 24 30          	mov    0x30(%esp),%eax
f010676c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0106770:	89 34 24             	mov    %esi,(%esp)
f0106773:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106777:	85 c0                	test   %eax,%eax
f0106779:	89 c2                	mov    %eax,%edx
f010677b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010677f:	75 17                	jne    f0106798 <__umoddi3+0x48>
f0106781:	39 fe                	cmp    %edi,%esi
f0106783:	76 4b                	jbe    f01067d0 <__umoddi3+0x80>
f0106785:	89 c8                	mov    %ecx,%eax
f0106787:	89 fa                	mov    %edi,%edx
f0106789:	f7 f6                	div    %esi
f010678b:	89 d0                	mov    %edx,%eax
f010678d:	31 d2                	xor    %edx,%edx
f010678f:	83 c4 14             	add    $0x14,%esp
f0106792:	5e                   	pop    %esi
f0106793:	5f                   	pop    %edi
f0106794:	5d                   	pop    %ebp
f0106795:	c3                   	ret    
f0106796:	66 90                	xchg   %ax,%ax
f0106798:	39 f8                	cmp    %edi,%eax
f010679a:	77 54                	ja     f01067f0 <__umoddi3+0xa0>
f010679c:	0f bd e8             	bsr    %eax,%ebp
f010679f:	83 f5 1f             	xor    $0x1f,%ebp
f01067a2:	75 5c                	jne    f0106800 <__umoddi3+0xb0>
f01067a4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01067a8:	39 3c 24             	cmp    %edi,(%esp)
f01067ab:	0f 87 e7 00 00 00    	ja     f0106898 <__umoddi3+0x148>
f01067b1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01067b5:	29 f1                	sub    %esi,%ecx
f01067b7:	19 c7                	sbb    %eax,%edi
f01067b9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01067bd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01067c1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01067c5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01067c9:	83 c4 14             	add    $0x14,%esp
f01067cc:	5e                   	pop    %esi
f01067cd:	5f                   	pop    %edi
f01067ce:	5d                   	pop    %ebp
f01067cf:	c3                   	ret    
f01067d0:	85 f6                	test   %esi,%esi
f01067d2:	89 f5                	mov    %esi,%ebp
f01067d4:	75 0b                	jne    f01067e1 <__umoddi3+0x91>
f01067d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01067db:	31 d2                	xor    %edx,%edx
f01067dd:	f7 f6                	div    %esi
f01067df:	89 c5                	mov    %eax,%ebp
f01067e1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01067e5:	31 d2                	xor    %edx,%edx
f01067e7:	f7 f5                	div    %ebp
f01067e9:	89 c8                	mov    %ecx,%eax
f01067eb:	f7 f5                	div    %ebp
f01067ed:	eb 9c                	jmp    f010678b <__umoddi3+0x3b>
f01067ef:	90                   	nop
f01067f0:	89 c8                	mov    %ecx,%eax
f01067f2:	89 fa                	mov    %edi,%edx
f01067f4:	83 c4 14             	add    $0x14,%esp
f01067f7:	5e                   	pop    %esi
f01067f8:	5f                   	pop    %edi
f01067f9:	5d                   	pop    %ebp
f01067fa:	c3                   	ret    
f01067fb:	90                   	nop
f01067fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106800:	8b 04 24             	mov    (%esp),%eax
f0106803:	be 20 00 00 00       	mov    $0x20,%esi
f0106808:	89 e9                	mov    %ebp,%ecx
f010680a:	29 ee                	sub    %ebp,%esi
f010680c:	d3 e2                	shl    %cl,%edx
f010680e:	89 f1                	mov    %esi,%ecx
f0106810:	d3 e8                	shr    %cl,%eax
f0106812:	89 e9                	mov    %ebp,%ecx
f0106814:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106818:	8b 04 24             	mov    (%esp),%eax
f010681b:	09 54 24 04          	or     %edx,0x4(%esp)
f010681f:	89 fa                	mov    %edi,%edx
f0106821:	d3 e0                	shl    %cl,%eax
f0106823:	89 f1                	mov    %esi,%ecx
f0106825:	89 44 24 08          	mov    %eax,0x8(%esp)
f0106829:	8b 44 24 10          	mov    0x10(%esp),%eax
f010682d:	d3 ea                	shr    %cl,%edx
f010682f:	89 e9                	mov    %ebp,%ecx
f0106831:	d3 e7                	shl    %cl,%edi
f0106833:	89 f1                	mov    %esi,%ecx
f0106835:	d3 e8                	shr    %cl,%eax
f0106837:	89 e9                	mov    %ebp,%ecx
f0106839:	09 f8                	or     %edi,%eax
f010683b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010683f:	f7 74 24 04          	divl   0x4(%esp)
f0106843:	d3 e7                	shl    %cl,%edi
f0106845:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106849:	89 d7                	mov    %edx,%edi
f010684b:	f7 64 24 08          	mull   0x8(%esp)
f010684f:	39 d7                	cmp    %edx,%edi
f0106851:	89 c1                	mov    %eax,%ecx
f0106853:	89 14 24             	mov    %edx,(%esp)
f0106856:	72 2c                	jb     f0106884 <__umoddi3+0x134>
f0106858:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010685c:	72 22                	jb     f0106880 <__umoddi3+0x130>
f010685e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0106862:	29 c8                	sub    %ecx,%eax
f0106864:	19 d7                	sbb    %edx,%edi
f0106866:	89 e9                	mov    %ebp,%ecx
f0106868:	89 fa                	mov    %edi,%edx
f010686a:	d3 e8                	shr    %cl,%eax
f010686c:	89 f1                	mov    %esi,%ecx
f010686e:	d3 e2                	shl    %cl,%edx
f0106870:	89 e9                	mov    %ebp,%ecx
f0106872:	d3 ef                	shr    %cl,%edi
f0106874:	09 d0                	or     %edx,%eax
f0106876:	89 fa                	mov    %edi,%edx
f0106878:	83 c4 14             	add    $0x14,%esp
f010687b:	5e                   	pop    %esi
f010687c:	5f                   	pop    %edi
f010687d:	5d                   	pop    %ebp
f010687e:	c3                   	ret    
f010687f:	90                   	nop
f0106880:	39 d7                	cmp    %edx,%edi
f0106882:	75 da                	jne    f010685e <__umoddi3+0x10e>
f0106884:	8b 14 24             	mov    (%esp),%edx
f0106887:	89 c1                	mov    %eax,%ecx
f0106889:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010688d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0106891:	eb cb                	jmp    f010685e <__umoddi3+0x10e>
f0106893:	90                   	nop
f0106894:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106898:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010689c:	0f 82 0f ff ff ff    	jb     f01067b1 <__umoddi3+0x61>
f01068a2:	e9 1a ff ff ff       	jmp    f01067c1 <__umoddi3+0x71>
