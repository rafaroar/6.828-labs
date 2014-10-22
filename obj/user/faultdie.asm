
obj/user/faultdie:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 61 00 00 00       	call   800092 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	66 90                	xchg   %ax,%ax
  800035:	66 90                	xchg   %ax,%ax
  800037:	66 90                	xchg   %ax,%ax
  800039:	66 90                	xchg   %ax,%ax
  80003b:	66 90                	xchg   %ax,%ax
  80003d:	66 90                	xchg   %ax,%ax
  80003f:	90                   	nop

00800040 <handler>:

#include <inc/lib.h>

void
handler(struct UTrapframe *utf)
{
  800040:	55                   	push   %ebp
  800041:	89 e5                	mov    %esp,%ebp
  800043:	83 ec 18             	sub    $0x18,%esp
  800046:	8b 45 08             	mov    0x8(%ebp),%eax
	void *addr = (void*)utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	cprintf("i faulted at va %x, err %x\n", addr, err & 7);
  800049:	8b 50 04             	mov    0x4(%eax),%edx
  80004c:	83 e2 07             	and    $0x7,%edx
  80004f:	89 54 24 08          	mov    %edx,0x8(%esp)
  800053:	8b 00                	mov    (%eax),%eax
  800055:	89 44 24 04          	mov    %eax,0x4(%esp)
  800059:	c7 04 24 20 11 80 00 	movl   $0x801120,(%esp)
  800060:	e8 2c 01 00 00       	call   800191 <cprintf>
	sys_env_destroy(sys_getenvid());
  800065:	e8 2b 0b 00 00       	call   800b95 <sys_getenvid>
  80006a:	89 04 24             	mov    %eax,(%esp)
  80006d:	e8 d1 0a 00 00       	call   800b43 <sys_env_destroy>
}
  800072:	c9                   	leave  
  800073:	c3                   	ret    

00800074 <umain>:

void
umain(int argc, char **argv)
{
  800074:	55                   	push   %ebp
  800075:	89 e5                	mov    %esp,%ebp
  800077:	83 ec 18             	sub    $0x18,%esp
	set_pgfault_handler(handler);
  80007a:	c7 04 24 40 00 80 00 	movl   $0x800040,(%esp)
  800081:	e8 62 0d 00 00       	call   800de8 <set_pgfault_handler>
	*(int*)0xDeadBeef = 0;
  800086:	c7 05 ef be ad de 00 	movl   $0x0,0xdeadbeef
  80008d:	00 00 00 
}
  800090:	c9                   	leave  
  800091:	c3                   	ret    

00800092 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800092:	55                   	push   %ebp
  800093:	89 e5                	mov    %esp,%ebp
  800095:	56                   	push   %esi
  800096:	53                   	push   %ebx
  800097:	83 ec 10             	sub    $0x10,%esp
  80009a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80009d:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	
	thisenv = (struct Env *) envs + ENVX(sys_getenvid());
  8000a0:	e8 f0 0a 00 00       	call   800b95 <sys_getenvid>
  8000a5:	25 ff 03 00 00       	and    $0x3ff,%eax
  8000aa:	6b c0 7c             	imul   $0x7c,%eax,%eax
  8000ad:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  8000b2:	a3 04 20 80 00       	mov    %eax,0x802004
	//UENVS array
	//thisenv->env_link
	//thisenv = 0;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  8000b7:	85 db                	test   %ebx,%ebx
  8000b9:	7e 07                	jle    8000c2 <libmain+0x30>
		binaryname = argv[0];
  8000bb:	8b 06                	mov    (%esi),%eax
  8000bd:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  8000c2:	89 74 24 04          	mov    %esi,0x4(%esp)
  8000c6:	89 1c 24             	mov    %ebx,(%esp)
  8000c9:	e8 a6 ff ff ff       	call   800074 <umain>

	// exit gracefully
	exit();
  8000ce:	e8 07 00 00 00       	call   8000da <exit>
}
  8000d3:	83 c4 10             	add    $0x10,%esp
  8000d6:	5b                   	pop    %ebx
  8000d7:	5e                   	pop    %esi
  8000d8:	5d                   	pop    %ebp
  8000d9:	c3                   	ret    

008000da <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000da:	55                   	push   %ebp
  8000db:	89 e5                	mov    %esp,%ebp
  8000dd:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000e7:	e8 57 0a 00 00       	call   800b43 <sys_env_destroy>
}
  8000ec:	c9                   	leave  
  8000ed:	c3                   	ret    

008000ee <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000ee:	55                   	push   %ebp
  8000ef:	89 e5                	mov    %esp,%ebp
  8000f1:	53                   	push   %ebx
  8000f2:	83 ec 14             	sub    $0x14,%esp
  8000f5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000f8:	8b 13                	mov    (%ebx),%edx
  8000fa:	8d 42 01             	lea    0x1(%edx),%eax
  8000fd:	89 03                	mov    %eax,(%ebx)
  8000ff:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800102:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800106:	3d ff 00 00 00       	cmp    $0xff,%eax
  80010b:	75 19                	jne    800126 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  80010d:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800114:	00 
  800115:	8d 43 08             	lea    0x8(%ebx),%eax
  800118:	89 04 24             	mov    %eax,(%esp)
  80011b:	e8 e6 09 00 00       	call   800b06 <sys_cputs>
		b->idx = 0;
  800120:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800126:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80012a:	83 c4 14             	add    $0x14,%esp
  80012d:	5b                   	pop    %ebx
  80012e:	5d                   	pop    %ebp
  80012f:	c3                   	ret    

00800130 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800130:	55                   	push   %ebp
  800131:	89 e5                	mov    %esp,%ebp
  800133:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800139:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800140:	00 00 00 
	b.cnt = 0;
  800143:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80014a:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80014d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800150:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800154:	8b 45 08             	mov    0x8(%ebp),%eax
  800157:	89 44 24 08          	mov    %eax,0x8(%esp)
  80015b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800161:	89 44 24 04          	mov    %eax,0x4(%esp)
  800165:	c7 04 24 ee 00 80 00 	movl   $0x8000ee,(%esp)
  80016c:	e8 ad 01 00 00       	call   80031e <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800171:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800177:	89 44 24 04          	mov    %eax,0x4(%esp)
  80017b:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800181:	89 04 24             	mov    %eax,(%esp)
  800184:	e8 7d 09 00 00       	call   800b06 <sys_cputs>

	return b.cnt;
}
  800189:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80018f:	c9                   	leave  
  800190:	c3                   	ret    

00800191 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800191:	55                   	push   %ebp
  800192:	89 e5                	mov    %esp,%ebp
  800194:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800197:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80019a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80019e:	8b 45 08             	mov    0x8(%ebp),%eax
  8001a1:	89 04 24             	mov    %eax,(%esp)
  8001a4:	e8 87 ff ff ff       	call   800130 <vcprintf>
	va_end(ap);

	return cnt;
}
  8001a9:	c9                   	leave  
  8001aa:	c3                   	ret    
  8001ab:	66 90                	xchg   %ax,%ax
  8001ad:	66 90                	xchg   %ax,%ax
  8001af:	90                   	nop

008001b0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8001b0:	55                   	push   %ebp
  8001b1:	89 e5                	mov    %esp,%ebp
  8001b3:	57                   	push   %edi
  8001b4:	56                   	push   %esi
  8001b5:	53                   	push   %ebx
  8001b6:	83 ec 3c             	sub    $0x3c,%esp
  8001b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8001bc:	89 d7                	mov    %edx,%edi
  8001be:	8b 45 08             	mov    0x8(%ebp),%eax
  8001c1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8001c4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8001c7:	89 c3                	mov    %eax,%ebx
  8001c9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8001cc:	8b 45 10             	mov    0x10(%ebp),%eax
  8001cf:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8001d2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8001d7:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8001da:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8001dd:	39 d9                	cmp    %ebx,%ecx
  8001df:	72 05                	jb     8001e6 <printnum+0x36>
  8001e1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8001e4:	77 69                	ja     80024f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001e6:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8001e9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8001ed:	83 ee 01             	sub    $0x1,%esi
  8001f0:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001f4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001f8:	8b 44 24 08          	mov    0x8(%esp),%eax
  8001fc:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800200:	89 c3                	mov    %eax,%ebx
  800202:	89 d6                	mov    %edx,%esi
  800204:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800207:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80020a:	89 54 24 08          	mov    %edx,0x8(%esp)
  80020e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800212:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800215:	89 04 24             	mov    %eax,(%esp)
  800218:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80021b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80021f:	e8 5c 0c 00 00       	call   800e80 <__udivdi3>
  800224:	89 d9                	mov    %ebx,%ecx
  800226:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80022a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80022e:	89 04 24             	mov    %eax,(%esp)
  800231:	89 54 24 04          	mov    %edx,0x4(%esp)
  800235:	89 fa                	mov    %edi,%edx
  800237:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80023a:	e8 71 ff ff ff       	call   8001b0 <printnum>
  80023f:	eb 1b                	jmp    80025c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800241:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800245:	8b 45 18             	mov    0x18(%ebp),%eax
  800248:	89 04 24             	mov    %eax,(%esp)
  80024b:	ff d3                	call   *%ebx
  80024d:	eb 03                	jmp    800252 <printnum+0xa2>
  80024f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800252:	83 ee 01             	sub    $0x1,%esi
  800255:	85 f6                	test   %esi,%esi
  800257:	7f e8                	jg     800241 <printnum+0x91>
  800259:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80025c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800260:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800264:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800267:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80026a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80026e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800272:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800275:	89 04 24             	mov    %eax,(%esp)
  800278:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80027b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80027f:	e8 2c 0d 00 00       	call   800fb0 <__umoddi3>
  800284:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800288:	0f be 80 46 11 80 00 	movsbl 0x801146(%eax),%eax
  80028f:	89 04 24             	mov    %eax,(%esp)
  800292:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800295:	ff d0                	call   *%eax
}
  800297:	83 c4 3c             	add    $0x3c,%esp
  80029a:	5b                   	pop    %ebx
  80029b:	5e                   	pop    %esi
  80029c:	5f                   	pop    %edi
  80029d:	5d                   	pop    %ebp
  80029e:	c3                   	ret    

0080029f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80029f:	55                   	push   %ebp
  8002a0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8002a2:	83 fa 01             	cmp    $0x1,%edx
  8002a5:	7e 0e                	jle    8002b5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8002a7:	8b 10                	mov    (%eax),%edx
  8002a9:	8d 4a 08             	lea    0x8(%edx),%ecx
  8002ac:	89 08                	mov    %ecx,(%eax)
  8002ae:	8b 02                	mov    (%edx),%eax
  8002b0:	8b 52 04             	mov    0x4(%edx),%edx
  8002b3:	eb 22                	jmp    8002d7 <getuint+0x38>
	else if (lflag)
  8002b5:	85 d2                	test   %edx,%edx
  8002b7:	74 10                	je     8002c9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8002b9:	8b 10                	mov    (%eax),%edx
  8002bb:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002be:	89 08                	mov    %ecx,(%eax)
  8002c0:	8b 02                	mov    (%edx),%eax
  8002c2:	ba 00 00 00 00       	mov    $0x0,%edx
  8002c7:	eb 0e                	jmp    8002d7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8002c9:	8b 10                	mov    (%eax),%edx
  8002cb:	8d 4a 04             	lea    0x4(%edx),%ecx
  8002ce:	89 08                	mov    %ecx,(%eax)
  8002d0:	8b 02                	mov    (%edx),%eax
  8002d2:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8002d7:	5d                   	pop    %ebp
  8002d8:	c3                   	ret    

008002d9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002d9:	55                   	push   %ebp
  8002da:	89 e5                	mov    %esp,%ebp
  8002dc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002df:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002e3:	8b 10                	mov    (%eax),%edx
  8002e5:	3b 50 04             	cmp    0x4(%eax),%edx
  8002e8:	73 0a                	jae    8002f4 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002ea:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002ed:	89 08                	mov    %ecx,(%eax)
  8002ef:	8b 45 08             	mov    0x8(%ebp),%eax
  8002f2:	88 02                	mov    %al,(%edx)
}
  8002f4:	5d                   	pop    %ebp
  8002f5:	c3                   	ret    

008002f6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002f6:	55                   	push   %ebp
  8002f7:	89 e5                	mov    %esp,%ebp
  8002f9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8002fc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002ff:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800303:	8b 45 10             	mov    0x10(%ebp),%eax
  800306:	89 44 24 08          	mov    %eax,0x8(%esp)
  80030a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80030d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800311:	8b 45 08             	mov    0x8(%ebp),%eax
  800314:	89 04 24             	mov    %eax,(%esp)
  800317:	e8 02 00 00 00       	call   80031e <vprintfmt>
	va_end(ap);
}
  80031c:	c9                   	leave  
  80031d:	c3                   	ret    

0080031e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80031e:	55                   	push   %ebp
  80031f:	89 e5                	mov    %esp,%ebp
  800321:	57                   	push   %edi
  800322:	56                   	push   %esi
  800323:	53                   	push   %ebx
  800324:	83 ec 3c             	sub    $0x3c,%esp
  800327:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80032a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80032d:	eb 14                	jmp    800343 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80032f:	85 c0                	test   %eax,%eax
  800331:	0f 84 b3 03 00 00    	je     8006ea <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  800337:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80033b:	89 04 24             	mov    %eax,(%esp)
  80033e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800341:	89 f3                	mov    %esi,%ebx
  800343:	8d 73 01             	lea    0x1(%ebx),%esi
  800346:	0f b6 03             	movzbl (%ebx),%eax
  800349:	83 f8 25             	cmp    $0x25,%eax
  80034c:	75 e1                	jne    80032f <vprintfmt+0x11>
  80034e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800352:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800359:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800360:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800367:	ba 00 00 00 00       	mov    $0x0,%edx
  80036c:	eb 1d                	jmp    80038b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80036e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  800370:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800374:	eb 15                	jmp    80038b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800376:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800378:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80037c:	eb 0d                	jmp    80038b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80037e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800381:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800384:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80038b:	8d 5e 01             	lea    0x1(%esi),%ebx
  80038e:	0f b6 0e             	movzbl (%esi),%ecx
  800391:	0f b6 c1             	movzbl %cl,%eax
  800394:	83 e9 23             	sub    $0x23,%ecx
  800397:	80 f9 55             	cmp    $0x55,%cl
  80039a:	0f 87 2a 03 00 00    	ja     8006ca <vprintfmt+0x3ac>
  8003a0:	0f b6 c9             	movzbl %cl,%ecx
  8003a3:	ff 24 8d 00 12 80 00 	jmp    *0x801200(,%ecx,4)
  8003aa:	89 de                	mov    %ebx,%esi
  8003ac:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8003b1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  8003b4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  8003b8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  8003bb:	8d 58 d0             	lea    -0x30(%eax),%ebx
  8003be:	83 fb 09             	cmp    $0x9,%ebx
  8003c1:	77 36                	ja     8003f9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8003c3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8003c6:	eb e9                	jmp    8003b1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8003c8:	8b 45 14             	mov    0x14(%ebp),%eax
  8003cb:	8d 48 04             	lea    0x4(%eax),%ecx
  8003ce:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8003d1:	8b 00                	mov    (%eax),%eax
  8003d3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8003d8:	eb 22                	jmp    8003fc <vprintfmt+0xde>
  8003da:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8003dd:	85 c9                	test   %ecx,%ecx
  8003df:	b8 00 00 00 00       	mov    $0x0,%eax
  8003e4:	0f 49 c1             	cmovns %ecx,%eax
  8003e7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ea:	89 de                	mov    %ebx,%esi
  8003ec:	eb 9d                	jmp    80038b <vprintfmt+0x6d>
  8003ee:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003f0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  8003f7:	eb 92                	jmp    80038b <vprintfmt+0x6d>
  8003f9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  8003fc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800400:	79 89                	jns    80038b <vprintfmt+0x6d>
  800402:	e9 77 ff ff ff       	jmp    80037e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800407:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80040a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80040c:	e9 7a ff ff ff       	jmp    80038b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800411:	8b 45 14             	mov    0x14(%ebp),%eax
  800414:	8d 50 04             	lea    0x4(%eax),%edx
  800417:	89 55 14             	mov    %edx,0x14(%ebp)
  80041a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80041e:	8b 00                	mov    (%eax),%eax
  800420:	89 04 24             	mov    %eax,(%esp)
  800423:	ff 55 08             	call   *0x8(%ebp)
			break;
  800426:	e9 18 ff ff ff       	jmp    800343 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80042b:	8b 45 14             	mov    0x14(%ebp),%eax
  80042e:	8d 50 04             	lea    0x4(%eax),%edx
  800431:	89 55 14             	mov    %edx,0x14(%ebp)
  800434:	8b 00                	mov    (%eax),%eax
  800436:	99                   	cltd   
  800437:	31 d0                	xor    %edx,%eax
  800439:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80043b:	83 f8 09             	cmp    $0x9,%eax
  80043e:	7f 0b                	jg     80044b <vprintfmt+0x12d>
  800440:	8b 14 85 60 13 80 00 	mov    0x801360(,%eax,4),%edx
  800447:	85 d2                	test   %edx,%edx
  800449:	75 20                	jne    80046b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  80044b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80044f:	c7 44 24 08 5e 11 80 	movl   $0x80115e,0x8(%esp)
  800456:	00 
  800457:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80045b:	8b 45 08             	mov    0x8(%ebp),%eax
  80045e:	89 04 24             	mov    %eax,(%esp)
  800461:	e8 90 fe ff ff       	call   8002f6 <printfmt>
  800466:	e9 d8 fe ff ff       	jmp    800343 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80046b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80046f:	c7 44 24 08 67 11 80 	movl   $0x801167,0x8(%esp)
  800476:	00 
  800477:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80047b:	8b 45 08             	mov    0x8(%ebp),%eax
  80047e:	89 04 24             	mov    %eax,(%esp)
  800481:	e8 70 fe ff ff       	call   8002f6 <printfmt>
  800486:	e9 b8 fe ff ff       	jmp    800343 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80048b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  80048e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800491:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800494:	8b 45 14             	mov    0x14(%ebp),%eax
  800497:	8d 50 04             	lea    0x4(%eax),%edx
  80049a:	89 55 14             	mov    %edx,0x14(%ebp)
  80049d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  80049f:	85 f6                	test   %esi,%esi
  8004a1:	b8 57 11 80 00       	mov    $0x801157,%eax
  8004a6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  8004a9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  8004ad:	0f 84 97 00 00 00    	je     80054a <vprintfmt+0x22c>
  8004b3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  8004b7:	0f 8e 9b 00 00 00    	jle    800558 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  8004bd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8004c1:	89 34 24             	mov    %esi,(%esp)
  8004c4:	e8 cf 02 00 00       	call   800798 <strnlen>
  8004c9:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8004cc:	29 c2                	sub    %eax,%edx
  8004ce:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  8004d1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8004d5:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8004d8:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8004db:	8b 75 08             	mov    0x8(%ebp),%esi
  8004de:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8004e1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004e3:	eb 0f                	jmp    8004f4 <vprintfmt+0x1d6>
					putch(padc, putdat);
  8004e5:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004e9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8004ec:	89 04 24             	mov    %eax,(%esp)
  8004ef:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004f1:	83 eb 01             	sub    $0x1,%ebx
  8004f4:	85 db                	test   %ebx,%ebx
  8004f6:	7f ed                	jg     8004e5 <vprintfmt+0x1c7>
  8004f8:	8b 75 d8             	mov    -0x28(%ebp),%esi
  8004fb:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8004fe:	85 d2                	test   %edx,%edx
  800500:	b8 00 00 00 00       	mov    $0x0,%eax
  800505:	0f 49 c2             	cmovns %edx,%eax
  800508:	29 c2                	sub    %eax,%edx
  80050a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80050d:	89 d7                	mov    %edx,%edi
  80050f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800512:	eb 50                	jmp    800564 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800514:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800518:	74 1e                	je     800538 <vprintfmt+0x21a>
  80051a:	0f be d2             	movsbl %dl,%edx
  80051d:	83 ea 20             	sub    $0x20,%edx
  800520:	83 fa 5e             	cmp    $0x5e,%edx
  800523:	76 13                	jbe    800538 <vprintfmt+0x21a>
					putch('?', putdat);
  800525:	8b 45 0c             	mov    0xc(%ebp),%eax
  800528:	89 44 24 04          	mov    %eax,0x4(%esp)
  80052c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800533:	ff 55 08             	call   *0x8(%ebp)
  800536:	eb 0d                	jmp    800545 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  800538:	8b 55 0c             	mov    0xc(%ebp),%edx
  80053b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80053f:	89 04 24             	mov    %eax,(%esp)
  800542:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800545:	83 ef 01             	sub    $0x1,%edi
  800548:	eb 1a                	jmp    800564 <vprintfmt+0x246>
  80054a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80054d:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800550:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800553:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800556:	eb 0c                	jmp    800564 <vprintfmt+0x246>
  800558:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80055b:	8b 7d dc             	mov    -0x24(%ebp),%edi
  80055e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800561:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800564:	83 c6 01             	add    $0x1,%esi
  800567:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  80056b:	0f be c2             	movsbl %dl,%eax
  80056e:	85 c0                	test   %eax,%eax
  800570:	74 27                	je     800599 <vprintfmt+0x27b>
  800572:	85 db                	test   %ebx,%ebx
  800574:	78 9e                	js     800514 <vprintfmt+0x1f6>
  800576:	83 eb 01             	sub    $0x1,%ebx
  800579:	79 99                	jns    800514 <vprintfmt+0x1f6>
  80057b:	89 f8                	mov    %edi,%eax
  80057d:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800580:	8b 75 08             	mov    0x8(%ebp),%esi
  800583:	89 c3                	mov    %eax,%ebx
  800585:	eb 1a                	jmp    8005a1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800587:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80058b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800592:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800594:	83 eb 01             	sub    $0x1,%ebx
  800597:	eb 08                	jmp    8005a1 <vprintfmt+0x283>
  800599:	89 fb                	mov    %edi,%ebx
  80059b:	8b 75 08             	mov    0x8(%ebp),%esi
  80059e:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8005a1:	85 db                	test   %ebx,%ebx
  8005a3:	7f e2                	jg     800587 <vprintfmt+0x269>
  8005a5:	89 75 08             	mov    %esi,0x8(%ebp)
  8005a8:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8005ab:	e9 93 fd ff ff       	jmp    800343 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8005b0:	83 fa 01             	cmp    $0x1,%edx
  8005b3:	7e 16                	jle    8005cb <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  8005b5:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b8:	8d 50 08             	lea    0x8(%eax),%edx
  8005bb:	89 55 14             	mov    %edx,0x14(%ebp)
  8005be:	8b 50 04             	mov    0x4(%eax),%edx
  8005c1:	8b 00                	mov    (%eax),%eax
  8005c3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8005c6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8005c9:	eb 32                	jmp    8005fd <vprintfmt+0x2df>
	else if (lflag)
  8005cb:	85 d2                	test   %edx,%edx
  8005cd:	74 18                	je     8005e7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  8005cf:	8b 45 14             	mov    0x14(%ebp),%eax
  8005d2:	8d 50 04             	lea    0x4(%eax),%edx
  8005d5:	89 55 14             	mov    %edx,0x14(%ebp)
  8005d8:	8b 30                	mov    (%eax),%esi
  8005da:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8005dd:	89 f0                	mov    %esi,%eax
  8005df:	c1 f8 1f             	sar    $0x1f,%eax
  8005e2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8005e5:	eb 16                	jmp    8005fd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  8005e7:	8b 45 14             	mov    0x14(%ebp),%eax
  8005ea:	8d 50 04             	lea    0x4(%eax),%edx
  8005ed:	89 55 14             	mov    %edx,0x14(%ebp)
  8005f0:	8b 30                	mov    (%eax),%esi
  8005f2:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8005f5:	89 f0                	mov    %esi,%eax
  8005f7:	c1 f8 1f             	sar    $0x1f,%eax
  8005fa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005fd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800600:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800603:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800608:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  80060c:	0f 89 80 00 00 00    	jns    800692 <vprintfmt+0x374>
				putch('-', putdat);
  800612:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800616:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  80061d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  800620:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800623:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800626:	f7 d8                	neg    %eax
  800628:	83 d2 00             	adc    $0x0,%edx
  80062b:	f7 da                	neg    %edx
			}
			base = 10;
  80062d:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800632:	eb 5e                	jmp    800692 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800634:	8d 45 14             	lea    0x14(%ebp),%eax
  800637:	e8 63 fc ff ff       	call   80029f <getuint>
			base = 10;
  80063c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800641:	eb 4f                	jmp    800692 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800643:	8d 45 14             	lea    0x14(%ebp),%eax
  800646:	e8 54 fc ff ff       	call   80029f <getuint>
			base = 8;
  80064b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800650:	eb 40                	jmp    800692 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
  800652:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800656:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80065d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800660:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800664:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80066b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80066e:	8b 45 14             	mov    0x14(%ebp),%eax
  800671:	8d 50 04             	lea    0x4(%eax),%edx
  800674:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800677:	8b 00                	mov    (%eax),%eax
  800679:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80067e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800683:	eb 0d                	jmp    800692 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800685:	8d 45 14             	lea    0x14(%ebp),%eax
  800688:	e8 12 fc ff ff       	call   80029f <getuint>
			base = 16;
  80068d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800692:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  800696:	89 74 24 10          	mov    %esi,0x10(%esp)
  80069a:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80069d:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8006a1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8006a5:	89 04 24             	mov    %eax,(%esp)
  8006a8:	89 54 24 04          	mov    %edx,0x4(%esp)
  8006ac:	89 fa                	mov    %edi,%edx
  8006ae:	8b 45 08             	mov    0x8(%ebp),%eax
  8006b1:	e8 fa fa ff ff       	call   8001b0 <printnum>
			break;
  8006b6:	e9 88 fc ff ff       	jmp    800343 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8006bb:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006bf:	89 04 24             	mov    %eax,(%esp)
  8006c2:	ff 55 08             	call   *0x8(%ebp)
			break;
  8006c5:	e9 79 fc ff ff       	jmp    800343 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006ca:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006ce:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8006d5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006d8:	89 f3                	mov    %esi,%ebx
  8006da:	eb 03                	jmp    8006df <vprintfmt+0x3c1>
  8006dc:	83 eb 01             	sub    $0x1,%ebx
  8006df:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8006e3:	75 f7                	jne    8006dc <vprintfmt+0x3be>
  8006e5:	e9 59 fc ff ff       	jmp    800343 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8006ea:	83 c4 3c             	add    $0x3c,%esp
  8006ed:	5b                   	pop    %ebx
  8006ee:	5e                   	pop    %esi
  8006ef:	5f                   	pop    %edi
  8006f0:	5d                   	pop    %ebp
  8006f1:	c3                   	ret    

008006f2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006f2:	55                   	push   %ebp
  8006f3:	89 e5                	mov    %esp,%ebp
  8006f5:	83 ec 28             	sub    $0x28,%esp
  8006f8:	8b 45 08             	mov    0x8(%ebp),%eax
  8006fb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800701:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800705:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800708:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80070f:	85 c0                	test   %eax,%eax
  800711:	74 30                	je     800743 <vsnprintf+0x51>
  800713:	85 d2                	test   %edx,%edx
  800715:	7e 2c                	jle    800743 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800717:	8b 45 14             	mov    0x14(%ebp),%eax
  80071a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80071e:	8b 45 10             	mov    0x10(%ebp),%eax
  800721:	89 44 24 08          	mov    %eax,0x8(%esp)
  800725:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800728:	89 44 24 04          	mov    %eax,0x4(%esp)
  80072c:	c7 04 24 d9 02 80 00 	movl   $0x8002d9,(%esp)
  800733:	e8 e6 fb ff ff       	call   80031e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800738:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80073b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80073e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800741:	eb 05                	jmp    800748 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800743:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800748:	c9                   	leave  
  800749:	c3                   	ret    

0080074a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80074a:	55                   	push   %ebp
  80074b:	89 e5                	mov    %esp,%ebp
  80074d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800750:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800753:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800757:	8b 45 10             	mov    0x10(%ebp),%eax
  80075a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80075e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800761:	89 44 24 04          	mov    %eax,0x4(%esp)
  800765:	8b 45 08             	mov    0x8(%ebp),%eax
  800768:	89 04 24             	mov    %eax,(%esp)
  80076b:	e8 82 ff ff ff       	call   8006f2 <vsnprintf>
	va_end(ap);

	return rc;
}
  800770:	c9                   	leave  
  800771:	c3                   	ret    
  800772:	66 90                	xchg   %ax,%ax
  800774:	66 90                	xchg   %ax,%ax
  800776:	66 90                	xchg   %ax,%ax
  800778:	66 90                	xchg   %ax,%ax
  80077a:	66 90                	xchg   %ax,%ax
  80077c:	66 90                	xchg   %ax,%ax
  80077e:	66 90                	xchg   %ax,%ax

00800780 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800780:	55                   	push   %ebp
  800781:	89 e5                	mov    %esp,%ebp
  800783:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800786:	b8 00 00 00 00       	mov    $0x0,%eax
  80078b:	eb 03                	jmp    800790 <strlen+0x10>
		n++;
  80078d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800790:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800794:	75 f7                	jne    80078d <strlen+0xd>
		n++;
	return n;
}
  800796:	5d                   	pop    %ebp
  800797:	c3                   	ret    

00800798 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800798:	55                   	push   %ebp
  800799:	89 e5                	mov    %esp,%ebp
  80079b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80079e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007a1:	b8 00 00 00 00       	mov    $0x0,%eax
  8007a6:	eb 03                	jmp    8007ab <strnlen+0x13>
		n++;
  8007a8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8007ab:	39 d0                	cmp    %edx,%eax
  8007ad:	74 06                	je     8007b5 <strnlen+0x1d>
  8007af:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  8007b3:	75 f3                	jne    8007a8 <strnlen+0x10>
		n++;
	return n;
}
  8007b5:	5d                   	pop    %ebp
  8007b6:	c3                   	ret    

008007b7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8007b7:	55                   	push   %ebp
  8007b8:	89 e5                	mov    %esp,%ebp
  8007ba:	53                   	push   %ebx
  8007bb:	8b 45 08             	mov    0x8(%ebp),%eax
  8007be:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007c1:	89 c2                	mov    %eax,%edx
  8007c3:	83 c2 01             	add    $0x1,%edx
  8007c6:	83 c1 01             	add    $0x1,%ecx
  8007c9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007cd:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007d0:	84 db                	test   %bl,%bl
  8007d2:	75 ef                	jne    8007c3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007d4:	5b                   	pop    %ebx
  8007d5:	5d                   	pop    %ebp
  8007d6:	c3                   	ret    

008007d7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007d7:	55                   	push   %ebp
  8007d8:	89 e5                	mov    %esp,%ebp
  8007da:	53                   	push   %ebx
  8007db:	83 ec 08             	sub    $0x8,%esp
  8007de:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007e1:	89 1c 24             	mov    %ebx,(%esp)
  8007e4:	e8 97 ff ff ff       	call   800780 <strlen>
	strcpy(dst + len, src);
  8007e9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007ec:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007f0:	01 d8                	add    %ebx,%eax
  8007f2:	89 04 24             	mov    %eax,(%esp)
  8007f5:	e8 bd ff ff ff       	call   8007b7 <strcpy>
	return dst;
}
  8007fa:	89 d8                	mov    %ebx,%eax
  8007fc:	83 c4 08             	add    $0x8,%esp
  8007ff:	5b                   	pop    %ebx
  800800:	5d                   	pop    %ebp
  800801:	c3                   	ret    

00800802 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800802:	55                   	push   %ebp
  800803:	89 e5                	mov    %esp,%ebp
  800805:	56                   	push   %esi
  800806:	53                   	push   %ebx
  800807:	8b 75 08             	mov    0x8(%ebp),%esi
  80080a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80080d:	89 f3                	mov    %esi,%ebx
  80080f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800812:	89 f2                	mov    %esi,%edx
  800814:	eb 0f                	jmp    800825 <strncpy+0x23>
		*dst++ = *src;
  800816:	83 c2 01             	add    $0x1,%edx
  800819:	0f b6 01             	movzbl (%ecx),%eax
  80081c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80081f:	80 39 01             	cmpb   $0x1,(%ecx)
  800822:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800825:	39 da                	cmp    %ebx,%edx
  800827:	75 ed                	jne    800816 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800829:	89 f0                	mov    %esi,%eax
  80082b:	5b                   	pop    %ebx
  80082c:	5e                   	pop    %esi
  80082d:	5d                   	pop    %ebp
  80082e:	c3                   	ret    

0080082f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80082f:	55                   	push   %ebp
  800830:	89 e5                	mov    %esp,%ebp
  800832:	56                   	push   %esi
  800833:	53                   	push   %ebx
  800834:	8b 75 08             	mov    0x8(%ebp),%esi
  800837:	8b 55 0c             	mov    0xc(%ebp),%edx
  80083a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80083d:	89 f0                	mov    %esi,%eax
  80083f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800843:	85 c9                	test   %ecx,%ecx
  800845:	75 0b                	jne    800852 <strlcpy+0x23>
  800847:	eb 1d                	jmp    800866 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800849:	83 c0 01             	add    $0x1,%eax
  80084c:	83 c2 01             	add    $0x1,%edx
  80084f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800852:	39 d8                	cmp    %ebx,%eax
  800854:	74 0b                	je     800861 <strlcpy+0x32>
  800856:	0f b6 0a             	movzbl (%edx),%ecx
  800859:	84 c9                	test   %cl,%cl
  80085b:	75 ec                	jne    800849 <strlcpy+0x1a>
  80085d:	89 c2                	mov    %eax,%edx
  80085f:	eb 02                	jmp    800863 <strlcpy+0x34>
  800861:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800863:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800866:	29 f0                	sub    %esi,%eax
}
  800868:	5b                   	pop    %ebx
  800869:	5e                   	pop    %esi
  80086a:	5d                   	pop    %ebp
  80086b:	c3                   	ret    

0080086c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80086c:	55                   	push   %ebp
  80086d:	89 e5                	mov    %esp,%ebp
  80086f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800872:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800875:	eb 06                	jmp    80087d <strcmp+0x11>
		p++, q++;
  800877:	83 c1 01             	add    $0x1,%ecx
  80087a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80087d:	0f b6 01             	movzbl (%ecx),%eax
  800880:	84 c0                	test   %al,%al
  800882:	74 04                	je     800888 <strcmp+0x1c>
  800884:	3a 02                	cmp    (%edx),%al
  800886:	74 ef                	je     800877 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800888:	0f b6 c0             	movzbl %al,%eax
  80088b:	0f b6 12             	movzbl (%edx),%edx
  80088e:	29 d0                	sub    %edx,%eax
}
  800890:	5d                   	pop    %ebp
  800891:	c3                   	ret    

00800892 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800892:	55                   	push   %ebp
  800893:	89 e5                	mov    %esp,%ebp
  800895:	53                   	push   %ebx
  800896:	8b 45 08             	mov    0x8(%ebp),%eax
  800899:	8b 55 0c             	mov    0xc(%ebp),%edx
  80089c:	89 c3                	mov    %eax,%ebx
  80089e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  8008a1:	eb 06                	jmp    8008a9 <strncmp+0x17>
		n--, p++, q++;
  8008a3:	83 c0 01             	add    $0x1,%eax
  8008a6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  8008a9:	39 d8                	cmp    %ebx,%eax
  8008ab:	74 15                	je     8008c2 <strncmp+0x30>
  8008ad:	0f b6 08             	movzbl (%eax),%ecx
  8008b0:	84 c9                	test   %cl,%cl
  8008b2:	74 04                	je     8008b8 <strncmp+0x26>
  8008b4:	3a 0a                	cmp    (%edx),%cl
  8008b6:	74 eb                	je     8008a3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  8008b8:	0f b6 00             	movzbl (%eax),%eax
  8008bb:	0f b6 12             	movzbl (%edx),%edx
  8008be:	29 d0                	sub    %edx,%eax
  8008c0:	eb 05                	jmp    8008c7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008c2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008c7:	5b                   	pop    %ebx
  8008c8:	5d                   	pop    %ebp
  8008c9:	c3                   	ret    

008008ca <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008ca:	55                   	push   %ebp
  8008cb:	89 e5                	mov    %esp,%ebp
  8008cd:	8b 45 08             	mov    0x8(%ebp),%eax
  8008d0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008d4:	eb 07                	jmp    8008dd <strchr+0x13>
		if (*s == c)
  8008d6:	38 ca                	cmp    %cl,%dl
  8008d8:	74 0f                	je     8008e9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008da:	83 c0 01             	add    $0x1,%eax
  8008dd:	0f b6 10             	movzbl (%eax),%edx
  8008e0:	84 d2                	test   %dl,%dl
  8008e2:	75 f2                	jne    8008d6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008e4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008e9:	5d                   	pop    %ebp
  8008ea:	c3                   	ret    

008008eb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008eb:	55                   	push   %ebp
  8008ec:	89 e5                	mov    %esp,%ebp
  8008ee:	8b 45 08             	mov    0x8(%ebp),%eax
  8008f1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008f5:	eb 07                	jmp    8008fe <strfind+0x13>
		if (*s == c)
  8008f7:	38 ca                	cmp    %cl,%dl
  8008f9:	74 0a                	je     800905 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8008fb:	83 c0 01             	add    $0x1,%eax
  8008fe:	0f b6 10             	movzbl (%eax),%edx
  800901:	84 d2                	test   %dl,%dl
  800903:	75 f2                	jne    8008f7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800905:	5d                   	pop    %ebp
  800906:	c3                   	ret    

00800907 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800907:	55                   	push   %ebp
  800908:	89 e5                	mov    %esp,%ebp
  80090a:	57                   	push   %edi
  80090b:	56                   	push   %esi
  80090c:	53                   	push   %ebx
  80090d:	8b 7d 08             	mov    0x8(%ebp),%edi
  800910:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800913:	85 c9                	test   %ecx,%ecx
  800915:	74 36                	je     80094d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800917:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80091d:	75 28                	jne    800947 <memset+0x40>
  80091f:	f6 c1 03             	test   $0x3,%cl
  800922:	75 23                	jne    800947 <memset+0x40>
		c &= 0xFF;
  800924:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800928:	89 d3                	mov    %edx,%ebx
  80092a:	c1 e3 08             	shl    $0x8,%ebx
  80092d:	89 d6                	mov    %edx,%esi
  80092f:	c1 e6 18             	shl    $0x18,%esi
  800932:	89 d0                	mov    %edx,%eax
  800934:	c1 e0 10             	shl    $0x10,%eax
  800937:	09 f0                	or     %esi,%eax
  800939:	09 c2                	or     %eax,%edx
  80093b:	89 d0                	mov    %edx,%eax
  80093d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  80093f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800942:	fc                   	cld    
  800943:	f3 ab                	rep stos %eax,%es:(%edi)
  800945:	eb 06                	jmp    80094d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800947:	8b 45 0c             	mov    0xc(%ebp),%eax
  80094a:	fc                   	cld    
  80094b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80094d:	89 f8                	mov    %edi,%eax
  80094f:	5b                   	pop    %ebx
  800950:	5e                   	pop    %esi
  800951:	5f                   	pop    %edi
  800952:	5d                   	pop    %ebp
  800953:	c3                   	ret    

00800954 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800954:	55                   	push   %ebp
  800955:	89 e5                	mov    %esp,%ebp
  800957:	57                   	push   %edi
  800958:	56                   	push   %esi
  800959:	8b 45 08             	mov    0x8(%ebp),%eax
  80095c:	8b 75 0c             	mov    0xc(%ebp),%esi
  80095f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800962:	39 c6                	cmp    %eax,%esi
  800964:	73 35                	jae    80099b <memmove+0x47>
  800966:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800969:	39 d0                	cmp    %edx,%eax
  80096b:	73 2e                	jae    80099b <memmove+0x47>
		s += n;
		d += n;
  80096d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800970:	89 d6                	mov    %edx,%esi
  800972:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800974:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80097a:	75 13                	jne    80098f <memmove+0x3b>
  80097c:	f6 c1 03             	test   $0x3,%cl
  80097f:	75 0e                	jne    80098f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800981:	83 ef 04             	sub    $0x4,%edi
  800984:	8d 72 fc             	lea    -0x4(%edx),%esi
  800987:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  80098a:	fd                   	std    
  80098b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80098d:	eb 09                	jmp    800998 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  80098f:	83 ef 01             	sub    $0x1,%edi
  800992:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800995:	fd                   	std    
  800996:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800998:	fc                   	cld    
  800999:	eb 1d                	jmp    8009b8 <memmove+0x64>
  80099b:	89 f2                	mov    %esi,%edx
  80099d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80099f:	f6 c2 03             	test   $0x3,%dl
  8009a2:	75 0f                	jne    8009b3 <memmove+0x5f>
  8009a4:	f6 c1 03             	test   $0x3,%cl
  8009a7:	75 0a                	jne    8009b3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  8009a9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  8009ac:	89 c7                	mov    %eax,%edi
  8009ae:	fc                   	cld    
  8009af:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009b1:	eb 05                	jmp    8009b8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  8009b3:	89 c7                	mov    %eax,%edi
  8009b5:	fc                   	cld    
  8009b6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  8009b8:	5e                   	pop    %esi
  8009b9:	5f                   	pop    %edi
  8009ba:	5d                   	pop    %ebp
  8009bb:	c3                   	ret    

008009bc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  8009bc:	55                   	push   %ebp
  8009bd:	89 e5                	mov    %esp,%ebp
  8009bf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  8009c2:	8b 45 10             	mov    0x10(%ebp),%eax
  8009c5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8009c9:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009cc:	89 44 24 04          	mov    %eax,0x4(%esp)
  8009d0:	8b 45 08             	mov    0x8(%ebp),%eax
  8009d3:	89 04 24             	mov    %eax,(%esp)
  8009d6:	e8 79 ff ff ff       	call   800954 <memmove>
}
  8009db:	c9                   	leave  
  8009dc:	c3                   	ret    

008009dd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009dd:	55                   	push   %ebp
  8009de:	89 e5                	mov    %esp,%ebp
  8009e0:	56                   	push   %esi
  8009e1:	53                   	push   %ebx
  8009e2:	8b 55 08             	mov    0x8(%ebp),%edx
  8009e5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8009e8:	89 d6                	mov    %edx,%esi
  8009ea:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009ed:	eb 1a                	jmp    800a09 <memcmp+0x2c>
		if (*s1 != *s2)
  8009ef:	0f b6 02             	movzbl (%edx),%eax
  8009f2:	0f b6 19             	movzbl (%ecx),%ebx
  8009f5:	38 d8                	cmp    %bl,%al
  8009f7:	74 0a                	je     800a03 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009f9:	0f b6 c0             	movzbl %al,%eax
  8009fc:	0f b6 db             	movzbl %bl,%ebx
  8009ff:	29 d8                	sub    %ebx,%eax
  800a01:	eb 0f                	jmp    800a12 <memcmp+0x35>
		s1++, s2++;
  800a03:	83 c2 01             	add    $0x1,%edx
  800a06:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a09:	39 f2                	cmp    %esi,%edx
  800a0b:	75 e2                	jne    8009ef <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a0d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a12:	5b                   	pop    %ebx
  800a13:	5e                   	pop    %esi
  800a14:	5d                   	pop    %ebp
  800a15:	c3                   	ret    

00800a16 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a16:	55                   	push   %ebp
  800a17:	89 e5                	mov    %esp,%ebp
  800a19:	8b 45 08             	mov    0x8(%ebp),%eax
  800a1c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800a1f:	89 c2                	mov    %eax,%edx
  800a21:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800a24:	eb 07                	jmp    800a2d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a26:	38 08                	cmp    %cl,(%eax)
  800a28:	74 07                	je     800a31 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a2a:	83 c0 01             	add    $0x1,%eax
  800a2d:	39 d0                	cmp    %edx,%eax
  800a2f:	72 f5                	jb     800a26 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a31:	5d                   	pop    %ebp
  800a32:	c3                   	ret    

00800a33 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a33:	55                   	push   %ebp
  800a34:	89 e5                	mov    %esp,%ebp
  800a36:	57                   	push   %edi
  800a37:	56                   	push   %esi
  800a38:	53                   	push   %ebx
  800a39:	8b 55 08             	mov    0x8(%ebp),%edx
  800a3c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a3f:	eb 03                	jmp    800a44 <strtol+0x11>
		s++;
  800a41:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a44:	0f b6 0a             	movzbl (%edx),%ecx
  800a47:	80 f9 09             	cmp    $0x9,%cl
  800a4a:	74 f5                	je     800a41 <strtol+0xe>
  800a4c:	80 f9 20             	cmp    $0x20,%cl
  800a4f:	74 f0                	je     800a41 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a51:	80 f9 2b             	cmp    $0x2b,%cl
  800a54:	75 0a                	jne    800a60 <strtol+0x2d>
		s++;
  800a56:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a59:	bf 00 00 00 00       	mov    $0x0,%edi
  800a5e:	eb 11                	jmp    800a71 <strtol+0x3e>
  800a60:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a65:	80 f9 2d             	cmp    $0x2d,%cl
  800a68:	75 07                	jne    800a71 <strtol+0x3e>
		s++, neg = 1;
  800a6a:	8d 52 01             	lea    0x1(%edx),%edx
  800a6d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a71:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800a76:	75 15                	jne    800a8d <strtol+0x5a>
  800a78:	80 3a 30             	cmpb   $0x30,(%edx)
  800a7b:	75 10                	jne    800a8d <strtol+0x5a>
  800a7d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800a81:	75 0a                	jne    800a8d <strtol+0x5a>
		s += 2, base = 16;
  800a83:	83 c2 02             	add    $0x2,%edx
  800a86:	b8 10 00 00 00       	mov    $0x10,%eax
  800a8b:	eb 10                	jmp    800a9d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800a8d:	85 c0                	test   %eax,%eax
  800a8f:	75 0c                	jne    800a9d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a91:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a93:	80 3a 30             	cmpb   $0x30,(%edx)
  800a96:	75 05                	jne    800a9d <strtol+0x6a>
		s++, base = 8;
  800a98:	83 c2 01             	add    $0x1,%edx
  800a9b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800a9d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800aa2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800aa5:	0f b6 0a             	movzbl (%edx),%ecx
  800aa8:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800aab:	89 f0                	mov    %esi,%eax
  800aad:	3c 09                	cmp    $0x9,%al
  800aaf:	77 08                	ja     800ab9 <strtol+0x86>
			dig = *s - '0';
  800ab1:	0f be c9             	movsbl %cl,%ecx
  800ab4:	83 e9 30             	sub    $0x30,%ecx
  800ab7:	eb 20                	jmp    800ad9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800ab9:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800abc:	89 f0                	mov    %esi,%eax
  800abe:	3c 19                	cmp    $0x19,%al
  800ac0:	77 08                	ja     800aca <strtol+0x97>
			dig = *s - 'a' + 10;
  800ac2:	0f be c9             	movsbl %cl,%ecx
  800ac5:	83 e9 57             	sub    $0x57,%ecx
  800ac8:	eb 0f                	jmp    800ad9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800aca:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800acd:	89 f0                	mov    %esi,%eax
  800acf:	3c 19                	cmp    $0x19,%al
  800ad1:	77 16                	ja     800ae9 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800ad3:	0f be c9             	movsbl %cl,%ecx
  800ad6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800ad9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800adc:	7d 0f                	jge    800aed <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800ade:	83 c2 01             	add    $0x1,%edx
  800ae1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800ae5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800ae7:	eb bc                	jmp    800aa5 <strtol+0x72>
  800ae9:	89 d8                	mov    %ebx,%eax
  800aeb:	eb 02                	jmp    800aef <strtol+0xbc>
  800aed:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800aef:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800af3:	74 05                	je     800afa <strtol+0xc7>
		*endptr = (char *) s;
  800af5:	8b 75 0c             	mov    0xc(%ebp),%esi
  800af8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800afa:	f7 d8                	neg    %eax
  800afc:	85 ff                	test   %edi,%edi
  800afe:	0f 44 c3             	cmove  %ebx,%eax
}
  800b01:	5b                   	pop    %ebx
  800b02:	5e                   	pop    %esi
  800b03:	5f                   	pop    %edi
  800b04:	5d                   	pop    %ebp
  800b05:	c3                   	ret    

00800b06 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800b06:	55                   	push   %ebp
  800b07:	89 e5                	mov    %esp,%ebp
  800b09:	57                   	push   %edi
  800b0a:	56                   	push   %esi
  800b0b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b0c:	b8 00 00 00 00       	mov    $0x0,%eax
  800b11:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b14:	8b 55 08             	mov    0x8(%ebp),%edx
  800b17:	89 c3                	mov    %eax,%ebx
  800b19:	89 c7                	mov    %eax,%edi
  800b1b:	89 c6                	mov    %eax,%esi
  800b1d:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b1f:	5b                   	pop    %ebx
  800b20:	5e                   	pop    %esi
  800b21:	5f                   	pop    %edi
  800b22:	5d                   	pop    %ebp
  800b23:	c3                   	ret    

00800b24 <sys_cgetc>:

int
sys_cgetc(void)
{
  800b24:	55                   	push   %ebp
  800b25:	89 e5                	mov    %esp,%ebp
  800b27:	57                   	push   %edi
  800b28:	56                   	push   %esi
  800b29:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b2a:	ba 00 00 00 00       	mov    $0x0,%edx
  800b2f:	b8 01 00 00 00       	mov    $0x1,%eax
  800b34:	89 d1                	mov    %edx,%ecx
  800b36:	89 d3                	mov    %edx,%ebx
  800b38:	89 d7                	mov    %edx,%edi
  800b3a:	89 d6                	mov    %edx,%esi
  800b3c:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b3e:	5b                   	pop    %ebx
  800b3f:	5e                   	pop    %esi
  800b40:	5f                   	pop    %edi
  800b41:	5d                   	pop    %ebp
  800b42:	c3                   	ret    

00800b43 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b43:	55                   	push   %ebp
  800b44:	89 e5                	mov    %esp,%ebp
  800b46:	57                   	push   %edi
  800b47:	56                   	push   %esi
  800b48:	53                   	push   %ebx
  800b49:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b4c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b51:	b8 03 00 00 00       	mov    $0x3,%eax
  800b56:	8b 55 08             	mov    0x8(%ebp),%edx
  800b59:	89 cb                	mov    %ecx,%ebx
  800b5b:	89 cf                	mov    %ecx,%edi
  800b5d:	89 ce                	mov    %ecx,%esi
  800b5f:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800b61:	85 c0                	test   %eax,%eax
  800b63:	7e 28                	jle    800b8d <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b65:	89 44 24 10          	mov    %eax,0x10(%esp)
  800b69:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800b70:	00 
  800b71:	c7 44 24 08 88 13 80 	movl   $0x801388,0x8(%esp)
  800b78:	00 
  800b79:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800b80:	00 
  800b81:	c7 04 24 a5 13 80 00 	movl   $0x8013a5,(%esp)
  800b88:	e8 90 02 00 00       	call   800e1d <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b8d:	83 c4 2c             	add    $0x2c,%esp
  800b90:	5b                   	pop    %ebx
  800b91:	5e                   	pop    %esi
  800b92:	5f                   	pop    %edi
  800b93:	5d                   	pop    %ebp
  800b94:	c3                   	ret    

00800b95 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b95:	55                   	push   %ebp
  800b96:	89 e5                	mov    %esp,%ebp
  800b98:	57                   	push   %edi
  800b99:	56                   	push   %esi
  800b9a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b9b:	ba 00 00 00 00       	mov    $0x0,%edx
  800ba0:	b8 02 00 00 00       	mov    $0x2,%eax
  800ba5:	89 d1                	mov    %edx,%ecx
  800ba7:	89 d3                	mov    %edx,%ebx
  800ba9:	89 d7                	mov    %edx,%edi
  800bab:	89 d6                	mov    %edx,%esi
  800bad:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800baf:	5b                   	pop    %ebx
  800bb0:	5e                   	pop    %esi
  800bb1:	5f                   	pop    %edi
  800bb2:	5d                   	pop    %ebp
  800bb3:	c3                   	ret    

00800bb4 <sys_yield>:

void
sys_yield(void)
{
  800bb4:	55                   	push   %ebp
  800bb5:	89 e5                	mov    %esp,%ebp
  800bb7:	57                   	push   %edi
  800bb8:	56                   	push   %esi
  800bb9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bba:	ba 00 00 00 00       	mov    $0x0,%edx
  800bbf:	b8 0a 00 00 00       	mov    $0xa,%eax
  800bc4:	89 d1                	mov    %edx,%ecx
  800bc6:	89 d3                	mov    %edx,%ebx
  800bc8:	89 d7                	mov    %edx,%edi
  800bca:	89 d6                	mov    %edx,%esi
  800bcc:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800bce:	5b                   	pop    %ebx
  800bcf:	5e                   	pop    %esi
  800bd0:	5f                   	pop    %edi
  800bd1:	5d                   	pop    %ebp
  800bd2:	c3                   	ret    

00800bd3 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800bd3:	55                   	push   %ebp
  800bd4:	89 e5                	mov    %esp,%ebp
  800bd6:	57                   	push   %edi
  800bd7:	56                   	push   %esi
  800bd8:	53                   	push   %ebx
  800bd9:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bdc:	be 00 00 00 00       	mov    $0x0,%esi
  800be1:	b8 04 00 00 00       	mov    $0x4,%eax
  800be6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800be9:	8b 55 08             	mov    0x8(%ebp),%edx
  800bec:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800bef:	89 f7                	mov    %esi,%edi
  800bf1:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800bf3:	85 c0                	test   %eax,%eax
  800bf5:	7e 28                	jle    800c1f <sys_page_alloc+0x4c>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bf7:	89 44 24 10          	mov    %eax,0x10(%esp)
  800bfb:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800c02:	00 
  800c03:	c7 44 24 08 88 13 80 	movl   $0x801388,0x8(%esp)
  800c0a:	00 
  800c0b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c12:	00 
  800c13:	c7 04 24 a5 13 80 00 	movl   $0x8013a5,(%esp)
  800c1a:	e8 fe 01 00 00       	call   800e1d <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800c1f:	83 c4 2c             	add    $0x2c,%esp
  800c22:	5b                   	pop    %ebx
  800c23:	5e                   	pop    %esi
  800c24:	5f                   	pop    %edi
  800c25:	5d                   	pop    %ebp
  800c26:	c3                   	ret    

00800c27 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800c27:	55                   	push   %ebp
  800c28:	89 e5                	mov    %esp,%ebp
  800c2a:	57                   	push   %edi
  800c2b:	56                   	push   %esi
  800c2c:	53                   	push   %ebx
  800c2d:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c30:	b8 05 00 00 00       	mov    $0x5,%eax
  800c35:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c38:	8b 55 08             	mov    0x8(%ebp),%edx
  800c3b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c3e:	8b 7d 14             	mov    0x14(%ebp),%edi
  800c41:	8b 75 18             	mov    0x18(%ebp),%esi
  800c44:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c46:	85 c0                	test   %eax,%eax
  800c48:	7e 28                	jle    800c72 <sys_page_map+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c4a:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c4e:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800c55:	00 
  800c56:	c7 44 24 08 88 13 80 	movl   $0x801388,0x8(%esp)
  800c5d:	00 
  800c5e:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c65:	00 
  800c66:	c7 04 24 a5 13 80 00 	movl   $0x8013a5,(%esp)
  800c6d:	e8 ab 01 00 00       	call   800e1d <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800c72:	83 c4 2c             	add    $0x2c,%esp
  800c75:	5b                   	pop    %ebx
  800c76:	5e                   	pop    %esi
  800c77:	5f                   	pop    %edi
  800c78:	5d                   	pop    %ebp
  800c79:	c3                   	ret    

00800c7a <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800c7a:	55                   	push   %ebp
  800c7b:	89 e5                	mov    %esp,%ebp
  800c7d:	57                   	push   %edi
  800c7e:	56                   	push   %esi
  800c7f:	53                   	push   %ebx
  800c80:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c83:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c88:	b8 06 00 00 00       	mov    $0x6,%eax
  800c8d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c90:	8b 55 08             	mov    0x8(%ebp),%edx
  800c93:	89 df                	mov    %ebx,%edi
  800c95:	89 de                	mov    %ebx,%esi
  800c97:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c99:	85 c0                	test   %eax,%eax
  800c9b:	7e 28                	jle    800cc5 <sys_page_unmap+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c9d:	89 44 24 10          	mov    %eax,0x10(%esp)
  800ca1:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800ca8:	00 
  800ca9:	c7 44 24 08 88 13 80 	movl   $0x801388,0x8(%esp)
  800cb0:	00 
  800cb1:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800cb8:	00 
  800cb9:	c7 04 24 a5 13 80 00 	movl   $0x8013a5,(%esp)
  800cc0:	e8 58 01 00 00       	call   800e1d <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800cc5:	83 c4 2c             	add    $0x2c,%esp
  800cc8:	5b                   	pop    %ebx
  800cc9:	5e                   	pop    %esi
  800cca:	5f                   	pop    %edi
  800ccb:	5d                   	pop    %ebp
  800ccc:	c3                   	ret    

00800ccd <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800ccd:	55                   	push   %ebp
  800cce:	89 e5                	mov    %esp,%ebp
  800cd0:	57                   	push   %edi
  800cd1:	56                   	push   %esi
  800cd2:	53                   	push   %ebx
  800cd3:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800cd6:	bb 00 00 00 00       	mov    $0x0,%ebx
  800cdb:	b8 08 00 00 00       	mov    $0x8,%eax
  800ce0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ce3:	8b 55 08             	mov    0x8(%ebp),%edx
  800ce6:	89 df                	mov    %ebx,%edi
  800ce8:	89 de                	mov    %ebx,%esi
  800cea:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800cec:	85 c0                	test   %eax,%eax
  800cee:	7e 28                	jle    800d18 <sys_env_set_status+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cf0:	89 44 24 10          	mov    %eax,0x10(%esp)
  800cf4:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800cfb:	00 
  800cfc:	c7 44 24 08 88 13 80 	movl   $0x801388,0x8(%esp)
  800d03:	00 
  800d04:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d0b:	00 
  800d0c:	c7 04 24 a5 13 80 00 	movl   $0x8013a5,(%esp)
  800d13:	e8 05 01 00 00       	call   800e1d <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800d18:	83 c4 2c             	add    $0x2c,%esp
  800d1b:	5b                   	pop    %ebx
  800d1c:	5e                   	pop    %esi
  800d1d:	5f                   	pop    %edi
  800d1e:	5d                   	pop    %ebp
  800d1f:	c3                   	ret    

00800d20 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800d20:	55                   	push   %ebp
  800d21:	89 e5                	mov    %esp,%ebp
  800d23:	57                   	push   %edi
  800d24:	56                   	push   %esi
  800d25:	53                   	push   %ebx
  800d26:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d29:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d2e:	b8 09 00 00 00       	mov    $0x9,%eax
  800d33:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d36:	8b 55 08             	mov    0x8(%ebp),%edx
  800d39:	89 df                	mov    %ebx,%edi
  800d3b:	89 de                	mov    %ebx,%esi
  800d3d:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d3f:	85 c0                	test   %eax,%eax
  800d41:	7e 28                	jle    800d6b <sys_env_set_pgfault_upcall+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d43:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d47:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800d4e:	00 
  800d4f:	c7 44 24 08 88 13 80 	movl   $0x801388,0x8(%esp)
  800d56:	00 
  800d57:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d5e:	00 
  800d5f:	c7 04 24 a5 13 80 00 	movl   $0x8013a5,(%esp)
  800d66:	e8 b2 00 00 00       	call   800e1d <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800d6b:	83 c4 2c             	add    $0x2c,%esp
  800d6e:	5b                   	pop    %ebx
  800d6f:	5e                   	pop    %esi
  800d70:	5f                   	pop    %edi
  800d71:	5d                   	pop    %ebp
  800d72:	c3                   	ret    

00800d73 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800d73:	55                   	push   %ebp
  800d74:	89 e5                	mov    %esp,%ebp
  800d76:	57                   	push   %edi
  800d77:	56                   	push   %esi
  800d78:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d79:	be 00 00 00 00       	mov    $0x0,%esi
  800d7e:	b8 0b 00 00 00       	mov    $0xb,%eax
  800d83:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d86:	8b 55 08             	mov    0x8(%ebp),%edx
  800d89:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d8c:	8b 7d 14             	mov    0x14(%ebp),%edi
  800d8f:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800d91:	5b                   	pop    %ebx
  800d92:	5e                   	pop    %esi
  800d93:	5f                   	pop    %edi
  800d94:	5d                   	pop    %ebp
  800d95:	c3                   	ret    

00800d96 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800d96:	55                   	push   %ebp
  800d97:	89 e5                	mov    %esp,%ebp
  800d99:	57                   	push   %edi
  800d9a:	56                   	push   %esi
  800d9b:	53                   	push   %ebx
  800d9c:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d9f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800da4:	b8 0c 00 00 00       	mov    $0xc,%eax
  800da9:	8b 55 08             	mov    0x8(%ebp),%edx
  800dac:	89 cb                	mov    %ecx,%ebx
  800dae:	89 cf                	mov    %ecx,%edi
  800db0:	89 ce                	mov    %ecx,%esi
  800db2:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800db4:	85 c0                	test   %eax,%eax
  800db6:	7e 28                	jle    800de0 <sys_ipc_recv+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800db8:	89 44 24 10          	mov    %eax,0x10(%esp)
  800dbc:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800dc3:	00 
  800dc4:	c7 44 24 08 88 13 80 	movl   $0x801388,0x8(%esp)
  800dcb:	00 
  800dcc:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800dd3:	00 
  800dd4:	c7 04 24 a5 13 80 00 	movl   $0x8013a5,(%esp)
  800ddb:	e8 3d 00 00 00       	call   800e1d <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800de0:	83 c4 2c             	add    $0x2c,%esp
  800de3:	5b                   	pop    %ebx
  800de4:	5e                   	pop    %esi
  800de5:	5f                   	pop    %edi
  800de6:	5d                   	pop    %ebp
  800de7:	c3                   	ret    

00800de8 <set_pgfault_handler>:
// at UXSTACKTOP), and tell the kernel to call the assembly-language
// _pgfault_upcall routine when a page fault occurs.
//
void
set_pgfault_handler(void (*handler)(struct UTrapframe *utf))
{
  800de8:	55                   	push   %ebp
  800de9:	89 e5                	mov    %esp,%ebp
  800deb:	83 ec 18             	sub    $0x18,%esp
	int r;

	if (_pgfault_handler == 0) {
  800dee:	83 3d 08 20 80 00 00 	cmpl   $0x0,0x802008
  800df5:	75 1c                	jne    800e13 <set_pgfault_handler+0x2b>
		// First time through!
		// LAB 4: Your code here.
		panic("set_pgfault_handler not implemented");
  800df7:	c7 44 24 08 b4 13 80 	movl   $0x8013b4,0x8(%esp)
  800dfe:	00 
  800dff:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
  800e06:	00 
  800e07:	c7 04 24 d8 13 80 00 	movl   $0x8013d8,(%esp)
  800e0e:	e8 0a 00 00 00       	call   800e1d <_panic>
	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
  800e13:	8b 45 08             	mov    0x8(%ebp),%eax
  800e16:	a3 08 20 80 00       	mov    %eax,0x802008
}
  800e1b:	c9                   	leave  
  800e1c:	c3                   	ret    

00800e1d <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800e1d:	55                   	push   %ebp
  800e1e:	89 e5                	mov    %esp,%ebp
  800e20:	56                   	push   %esi
  800e21:	53                   	push   %ebx
  800e22:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800e25:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800e28:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800e2e:	e8 62 fd ff ff       	call   800b95 <sys_getenvid>
  800e33:	8b 55 0c             	mov    0xc(%ebp),%edx
  800e36:	89 54 24 10          	mov    %edx,0x10(%esp)
  800e3a:	8b 55 08             	mov    0x8(%ebp),%edx
  800e3d:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800e41:	89 74 24 08          	mov    %esi,0x8(%esp)
  800e45:	89 44 24 04          	mov    %eax,0x4(%esp)
  800e49:	c7 04 24 e8 13 80 00 	movl   $0x8013e8,(%esp)
  800e50:	e8 3c f3 ff ff       	call   800191 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800e55:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800e59:	8b 45 10             	mov    0x10(%ebp),%eax
  800e5c:	89 04 24             	mov    %eax,(%esp)
  800e5f:	e8 cc f2 ff ff       	call   800130 <vcprintf>
	cprintf("\n");
  800e64:	c7 04 24 3a 11 80 00 	movl   $0x80113a,(%esp)
  800e6b:	e8 21 f3 ff ff       	call   800191 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800e70:	cc                   	int3   
  800e71:	eb fd                	jmp    800e70 <_panic+0x53>
  800e73:	66 90                	xchg   %ax,%ax
  800e75:	66 90                	xchg   %ax,%ax
  800e77:	66 90                	xchg   %ax,%ax
  800e79:	66 90                	xchg   %ax,%ax
  800e7b:	66 90                	xchg   %ax,%ax
  800e7d:	66 90                	xchg   %ax,%ax
  800e7f:	90                   	nop

00800e80 <__udivdi3>:
  800e80:	55                   	push   %ebp
  800e81:	57                   	push   %edi
  800e82:	56                   	push   %esi
  800e83:	83 ec 0c             	sub    $0xc,%esp
  800e86:	8b 44 24 28          	mov    0x28(%esp),%eax
  800e8a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800e8e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800e92:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800e96:	85 c0                	test   %eax,%eax
  800e98:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800e9c:	89 ea                	mov    %ebp,%edx
  800e9e:	89 0c 24             	mov    %ecx,(%esp)
  800ea1:	75 2d                	jne    800ed0 <__udivdi3+0x50>
  800ea3:	39 e9                	cmp    %ebp,%ecx
  800ea5:	77 61                	ja     800f08 <__udivdi3+0x88>
  800ea7:	85 c9                	test   %ecx,%ecx
  800ea9:	89 ce                	mov    %ecx,%esi
  800eab:	75 0b                	jne    800eb8 <__udivdi3+0x38>
  800ead:	b8 01 00 00 00       	mov    $0x1,%eax
  800eb2:	31 d2                	xor    %edx,%edx
  800eb4:	f7 f1                	div    %ecx
  800eb6:	89 c6                	mov    %eax,%esi
  800eb8:	31 d2                	xor    %edx,%edx
  800eba:	89 e8                	mov    %ebp,%eax
  800ebc:	f7 f6                	div    %esi
  800ebe:	89 c5                	mov    %eax,%ebp
  800ec0:	89 f8                	mov    %edi,%eax
  800ec2:	f7 f6                	div    %esi
  800ec4:	89 ea                	mov    %ebp,%edx
  800ec6:	83 c4 0c             	add    $0xc,%esp
  800ec9:	5e                   	pop    %esi
  800eca:	5f                   	pop    %edi
  800ecb:	5d                   	pop    %ebp
  800ecc:	c3                   	ret    
  800ecd:	8d 76 00             	lea    0x0(%esi),%esi
  800ed0:	39 e8                	cmp    %ebp,%eax
  800ed2:	77 24                	ja     800ef8 <__udivdi3+0x78>
  800ed4:	0f bd e8             	bsr    %eax,%ebp
  800ed7:	83 f5 1f             	xor    $0x1f,%ebp
  800eda:	75 3c                	jne    800f18 <__udivdi3+0x98>
  800edc:	8b 74 24 04          	mov    0x4(%esp),%esi
  800ee0:	39 34 24             	cmp    %esi,(%esp)
  800ee3:	0f 86 9f 00 00 00    	jbe    800f88 <__udivdi3+0x108>
  800ee9:	39 d0                	cmp    %edx,%eax
  800eeb:	0f 82 97 00 00 00    	jb     800f88 <__udivdi3+0x108>
  800ef1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800ef8:	31 d2                	xor    %edx,%edx
  800efa:	31 c0                	xor    %eax,%eax
  800efc:	83 c4 0c             	add    $0xc,%esp
  800eff:	5e                   	pop    %esi
  800f00:	5f                   	pop    %edi
  800f01:	5d                   	pop    %ebp
  800f02:	c3                   	ret    
  800f03:	90                   	nop
  800f04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f08:	89 f8                	mov    %edi,%eax
  800f0a:	f7 f1                	div    %ecx
  800f0c:	31 d2                	xor    %edx,%edx
  800f0e:	83 c4 0c             	add    $0xc,%esp
  800f11:	5e                   	pop    %esi
  800f12:	5f                   	pop    %edi
  800f13:	5d                   	pop    %ebp
  800f14:	c3                   	ret    
  800f15:	8d 76 00             	lea    0x0(%esi),%esi
  800f18:	89 e9                	mov    %ebp,%ecx
  800f1a:	8b 3c 24             	mov    (%esp),%edi
  800f1d:	d3 e0                	shl    %cl,%eax
  800f1f:	89 c6                	mov    %eax,%esi
  800f21:	b8 20 00 00 00       	mov    $0x20,%eax
  800f26:	29 e8                	sub    %ebp,%eax
  800f28:	89 c1                	mov    %eax,%ecx
  800f2a:	d3 ef                	shr    %cl,%edi
  800f2c:	89 e9                	mov    %ebp,%ecx
  800f2e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800f32:	8b 3c 24             	mov    (%esp),%edi
  800f35:	09 74 24 08          	or     %esi,0x8(%esp)
  800f39:	89 d6                	mov    %edx,%esi
  800f3b:	d3 e7                	shl    %cl,%edi
  800f3d:	89 c1                	mov    %eax,%ecx
  800f3f:	89 3c 24             	mov    %edi,(%esp)
  800f42:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800f46:	d3 ee                	shr    %cl,%esi
  800f48:	89 e9                	mov    %ebp,%ecx
  800f4a:	d3 e2                	shl    %cl,%edx
  800f4c:	89 c1                	mov    %eax,%ecx
  800f4e:	d3 ef                	shr    %cl,%edi
  800f50:	09 d7                	or     %edx,%edi
  800f52:	89 f2                	mov    %esi,%edx
  800f54:	89 f8                	mov    %edi,%eax
  800f56:	f7 74 24 08          	divl   0x8(%esp)
  800f5a:	89 d6                	mov    %edx,%esi
  800f5c:	89 c7                	mov    %eax,%edi
  800f5e:	f7 24 24             	mull   (%esp)
  800f61:	39 d6                	cmp    %edx,%esi
  800f63:	89 14 24             	mov    %edx,(%esp)
  800f66:	72 30                	jb     800f98 <__udivdi3+0x118>
  800f68:	8b 54 24 04          	mov    0x4(%esp),%edx
  800f6c:	89 e9                	mov    %ebp,%ecx
  800f6e:	d3 e2                	shl    %cl,%edx
  800f70:	39 c2                	cmp    %eax,%edx
  800f72:	73 05                	jae    800f79 <__udivdi3+0xf9>
  800f74:	3b 34 24             	cmp    (%esp),%esi
  800f77:	74 1f                	je     800f98 <__udivdi3+0x118>
  800f79:	89 f8                	mov    %edi,%eax
  800f7b:	31 d2                	xor    %edx,%edx
  800f7d:	e9 7a ff ff ff       	jmp    800efc <__udivdi3+0x7c>
  800f82:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800f88:	31 d2                	xor    %edx,%edx
  800f8a:	b8 01 00 00 00       	mov    $0x1,%eax
  800f8f:	e9 68 ff ff ff       	jmp    800efc <__udivdi3+0x7c>
  800f94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f98:	8d 47 ff             	lea    -0x1(%edi),%eax
  800f9b:	31 d2                	xor    %edx,%edx
  800f9d:	83 c4 0c             	add    $0xc,%esp
  800fa0:	5e                   	pop    %esi
  800fa1:	5f                   	pop    %edi
  800fa2:	5d                   	pop    %ebp
  800fa3:	c3                   	ret    
  800fa4:	66 90                	xchg   %ax,%ax
  800fa6:	66 90                	xchg   %ax,%ax
  800fa8:	66 90                	xchg   %ax,%ax
  800faa:	66 90                	xchg   %ax,%ax
  800fac:	66 90                	xchg   %ax,%ax
  800fae:	66 90                	xchg   %ax,%ax

00800fb0 <__umoddi3>:
  800fb0:	55                   	push   %ebp
  800fb1:	57                   	push   %edi
  800fb2:	56                   	push   %esi
  800fb3:	83 ec 14             	sub    $0x14,%esp
  800fb6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800fba:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800fbe:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800fc2:	89 c7                	mov    %eax,%edi
  800fc4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800fc8:	8b 44 24 30          	mov    0x30(%esp),%eax
  800fcc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800fd0:	89 34 24             	mov    %esi,(%esp)
  800fd3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800fd7:	85 c0                	test   %eax,%eax
  800fd9:	89 c2                	mov    %eax,%edx
  800fdb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800fdf:	75 17                	jne    800ff8 <__umoddi3+0x48>
  800fe1:	39 fe                	cmp    %edi,%esi
  800fe3:	76 4b                	jbe    801030 <__umoddi3+0x80>
  800fe5:	89 c8                	mov    %ecx,%eax
  800fe7:	89 fa                	mov    %edi,%edx
  800fe9:	f7 f6                	div    %esi
  800feb:	89 d0                	mov    %edx,%eax
  800fed:	31 d2                	xor    %edx,%edx
  800fef:	83 c4 14             	add    $0x14,%esp
  800ff2:	5e                   	pop    %esi
  800ff3:	5f                   	pop    %edi
  800ff4:	5d                   	pop    %ebp
  800ff5:	c3                   	ret    
  800ff6:	66 90                	xchg   %ax,%ax
  800ff8:	39 f8                	cmp    %edi,%eax
  800ffa:	77 54                	ja     801050 <__umoddi3+0xa0>
  800ffc:	0f bd e8             	bsr    %eax,%ebp
  800fff:	83 f5 1f             	xor    $0x1f,%ebp
  801002:	75 5c                	jne    801060 <__umoddi3+0xb0>
  801004:	8b 7c 24 08          	mov    0x8(%esp),%edi
  801008:	39 3c 24             	cmp    %edi,(%esp)
  80100b:	0f 87 e7 00 00 00    	ja     8010f8 <__umoddi3+0x148>
  801011:	8b 7c 24 04          	mov    0x4(%esp),%edi
  801015:	29 f1                	sub    %esi,%ecx
  801017:	19 c7                	sbb    %eax,%edi
  801019:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80101d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801021:	8b 44 24 08          	mov    0x8(%esp),%eax
  801025:	8b 54 24 0c          	mov    0xc(%esp),%edx
  801029:	83 c4 14             	add    $0x14,%esp
  80102c:	5e                   	pop    %esi
  80102d:	5f                   	pop    %edi
  80102e:	5d                   	pop    %ebp
  80102f:	c3                   	ret    
  801030:	85 f6                	test   %esi,%esi
  801032:	89 f5                	mov    %esi,%ebp
  801034:	75 0b                	jne    801041 <__umoddi3+0x91>
  801036:	b8 01 00 00 00       	mov    $0x1,%eax
  80103b:	31 d2                	xor    %edx,%edx
  80103d:	f7 f6                	div    %esi
  80103f:	89 c5                	mov    %eax,%ebp
  801041:	8b 44 24 04          	mov    0x4(%esp),%eax
  801045:	31 d2                	xor    %edx,%edx
  801047:	f7 f5                	div    %ebp
  801049:	89 c8                	mov    %ecx,%eax
  80104b:	f7 f5                	div    %ebp
  80104d:	eb 9c                	jmp    800feb <__umoddi3+0x3b>
  80104f:	90                   	nop
  801050:	89 c8                	mov    %ecx,%eax
  801052:	89 fa                	mov    %edi,%edx
  801054:	83 c4 14             	add    $0x14,%esp
  801057:	5e                   	pop    %esi
  801058:	5f                   	pop    %edi
  801059:	5d                   	pop    %ebp
  80105a:	c3                   	ret    
  80105b:	90                   	nop
  80105c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801060:	8b 04 24             	mov    (%esp),%eax
  801063:	be 20 00 00 00       	mov    $0x20,%esi
  801068:	89 e9                	mov    %ebp,%ecx
  80106a:	29 ee                	sub    %ebp,%esi
  80106c:	d3 e2                	shl    %cl,%edx
  80106e:	89 f1                	mov    %esi,%ecx
  801070:	d3 e8                	shr    %cl,%eax
  801072:	89 e9                	mov    %ebp,%ecx
  801074:	89 44 24 04          	mov    %eax,0x4(%esp)
  801078:	8b 04 24             	mov    (%esp),%eax
  80107b:	09 54 24 04          	or     %edx,0x4(%esp)
  80107f:	89 fa                	mov    %edi,%edx
  801081:	d3 e0                	shl    %cl,%eax
  801083:	89 f1                	mov    %esi,%ecx
  801085:	89 44 24 08          	mov    %eax,0x8(%esp)
  801089:	8b 44 24 10          	mov    0x10(%esp),%eax
  80108d:	d3 ea                	shr    %cl,%edx
  80108f:	89 e9                	mov    %ebp,%ecx
  801091:	d3 e7                	shl    %cl,%edi
  801093:	89 f1                	mov    %esi,%ecx
  801095:	d3 e8                	shr    %cl,%eax
  801097:	89 e9                	mov    %ebp,%ecx
  801099:	09 f8                	or     %edi,%eax
  80109b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  80109f:	f7 74 24 04          	divl   0x4(%esp)
  8010a3:	d3 e7                	shl    %cl,%edi
  8010a5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8010a9:	89 d7                	mov    %edx,%edi
  8010ab:	f7 64 24 08          	mull   0x8(%esp)
  8010af:	39 d7                	cmp    %edx,%edi
  8010b1:	89 c1                	mov    %eax,%ecx
  8010b3:	89 14 24             	mov    %edx,(%esp)
  8010b6:	72 2c                	jb     8010e4 <__umoddi3+0x134>
  8010b8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  8010bc:	72 22                	jb     8010e0 <__umoddi3+0x130>
  8010be:	8b 44 24 0c          	mov    0xc(%esp),%eax
  8010c2:	29 c8                	sub    %ecx,%eax
  8010c4:	19 d7                	sbb    %edx,%edi
  8010c6:	89 e9                	mov    %ebp,%ecx
  8010c8:	89 fa                	mov    %edi,%edx
  8010ca:	d3 e8                	shr    %cl,%eax
  8010cc:	89 f1                	mov    %esi,%ecx
  8010ce:	d3 e2                	shl    %cl,%edx
  8010d0:	89 e9                	mov    %ebp,%ecx
  8010d2:	d3 ef                	shr    %cl,%edi
  8010d4:	09 d0                	or     %edx,%eax
  8010d6:	89 fa                	mov    %edi,%edx
  8010d8:	83 c4 14             	add    $0x14,%esp
  8010db:	5e                   	pop    %esi
  8010dc:	5f                   	pop    %edi
  8010dd:	5d                   	pop    %ebp
  8010de:	c3                   	ret    
  8010df:	90                   	nop
  8010e0:	39 d7                	cmp    %edx,%edi
  8010e2:	75 da                	jne    8010be <__umoddi3+0x10e>
  8010e4:	8b 14 24             	mov    (%esp),%edx
  8010e7:	89 c1                	mov    %eax,%ecx
  8010e9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  8010ed:	1b 54 24 04          	sbb    0x4(%esp),%edx
  8010f1:	eb cb                	jmp    8010be <__umoddi3+0x10e>
  8010f3:	90                   	nop
  8010f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8010f8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  8010fc:	0f 82 0f ff ff ff    	jb     801011 <__umoddi3+0x61>
  801102:	e9 1a ff ff ff       	jmp    801021 <__umoddi3+0x71>
