
obj/user/faultreadkernel:     file format elf32-i386


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
  80002c:	e8 1f 00 00 00       	call   800050 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	cprintf("I read %08x from location 0xf0100000!\n", *(unsigned*)0xf0100000);
  800039:	a1 00 00 10 f0       	mov    0xf0100000,%eax
  80003e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800042:	c7 04 24 a0 10 80 00 	movl   $0x8010a0,(%esp)
  800049:	e8 01 01 00 00       	call   80014f <cprintf>
}
  80004e:	c9                   	leave  
  80004f:	c3                   	ret    

00800050 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800050:	55                   	push   %ebp
  800051:	89 e5                	mov    %esp,%ebp
  800053:	56                   	push   %esi
  800054:	53                   	push   %ebx
  800055:	83 ec 10             	sub    $0x10,%esp
  800058:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80005b:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	
	thisenv = (struct Env *) envs + ENVX(sys_getenvid());
  80005e:	e8 f2 0a 00 00       	call   800b55 <sys_getenvid>
  800063:	25 ff 03 00 00       	and    $0x3ff,%eax
  800068:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80006b:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800070:	a3 04 20 80 00       	mov    %eax,0x802004
	//UENVS array
	//thisenv->env_link
	//thisenv = 0;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800075:	85 db                	test   %ebx,%ebx
  800077:	7e 07                	jle    800080 <libmain+0x30>
		binaryname = argv[0];
  800079:	8b 06                	mov    (%esi),%eax
  80007b:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800080:	89 74 24 04          	mov    %esi,0x4(%esp)
  800084:	89 1c 24             	mov    %ebx,(%esp)
  800087:	e8 a7 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008c:	e8 07 00 00 00       	call   800098 <exit>
}
  800091:	83 c4 10             	add    $0x10,%esp
  800094:	5b                   	pop    %ebx
  800095:	5e                   	pop    %esi
  800096:	5d                   	pop    %ebp
  800097:	c3                   	ret    

00800098 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800098:	55                   	push   %ebp
  800099:	89 e5                	mov    %esp,%ebp
  80009b:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80009e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000a5:	e8 59 0a 00 00       	call   800b03 <sys_env_destroy>
}
  8000aa:	c9                   	leave  
  8000ab:	c3                   	ret    

008000ac <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000ac:	55                   	push   %ebp
  8000ad:	89 e5                	mov    %esp,%ebp
  8000af:	53                   	push   %ebx
  8000b0:	83 ec 14             	sub    $0x14,%esp
  8000b3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000b6:	8b 13                	mov    (%ebx),%edx
  8000b8:	8d 42 01             	lea    0x1(%edx),%eax
  8000bb:	89 03                	mov    %eax,(%ebx)
  8000bd:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000c0:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000c4:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000c9:	75 19                	jne    8000e4 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000cb:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000d2:	00 
  8000d3:	8d 43 08             	lea    0x8(%ebx),%eax
  8000d6:	89 04 24             	mov    %eax,(%esp)
  8000d9:	e8 e8 09 00 00       	call   800ac6 <sys_cputs>
		b->idx = 0;
  8000de:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8000e4:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000e8:	83 c4 14             	add    $0x14,%esp
  8000eb:	5b                   	pop    %ebx
  8000ec:	5d                   	pop    %ebp
  8000ed:	c3                   	ret    

008000ee <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000ee:	55                   	push   %ebp
  8000ef:	89 e5                	mov    %esp,%ebp
  8000f1:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8000f7:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8000fe:	00 00 00 
	b.cnt = 0;
  800101:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800108:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80010b:	8b 45 0c             	mov    0xc(%ebp),%eax
  80010e:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800112:	8b 45 08             	mov    0x8(%ebp),%eax
  800115:	89 44 24 08          	mov    %eax,0x8(%esp)
  800119:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80011f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800123:	c7 04 24 ac 00 80 00 	movl   $0x8000ac,(%esp)
  80012a:	e8 af 01 00 00       	call   8002de <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80012f:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800135:	89 44 24 04          	mov    %eax,0x4(%esp)
  800139:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80013f:	89 04 24             	mov    %eax,(%esp)
  800142:	e8 7f 09 00 00       	call   800ac6 <sys_cputs>

	return b.cnt;
}
  800147:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80014d:	c9                   	leave  
  80014e:	c3                   	ret    

0080014f <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80014f:	55                   	push   %ebp
  800150:	89 e5                	mov    %esp,%ebp
  800152:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800155:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800158:	89 44 24 04          	mov    %eax,0x4(%esp)
  80015c:	8b 45 08             	mov    0x8(%ebp),%eax
  80015f:	89 04 24             	mov    %eax,(%esp)
  800162:	e8 87 ff ff ff       	call   8000ee <vcprintf>
	va_end(ap);

	return cnt;
}
  800167:	c9                   	leave  
  800168:	c3                   	ret    
  800169:	66 90                	xchg   %ax,%ax
  80016b:	66 90                	xchg   %ax,%ax
  80016d:	66 90                	xchg   %ax,%ax
  80016f:	90                   	nop

00800170 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800170:	55                   	push   %ebp
  800171:	89 e5                	mov    %esp,%ebp
  800173:	57                   	push   %edi
  800174:	56                   	push   %esi
  800175:	53                   	push   %ebx
  800176:	83 ec 3c             	sub    $0x3c,%esp
  800179:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80017c:	89 d7                	mov    %edx,%edi
  80017e:	8b 45 08             	mov    0x8(%ebp),%eax
  800181:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800184:	8b 45 0c             	mov    0xc(%ebp),%eax
  800187:	89 c3                	mov    %eax,%ebx
  800189:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80018c:	8b 45 10             	mov    0x10(%ebp),%eax
  80018f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800192:	b9 00 00 00 00       	mov    $0x0,%ecx
  800197:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80019a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80019d:	39 d9                	cmp    %ebx,%ecx
  80019f:	72 05                	jb     8001a6 <printnum+0x36>
  8001a1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8001a4:	77 69                	ja     80020f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001a6:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8001a9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8001ad:	83 ee 01             	sub    $0x1,%esi
  8001b0:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001b4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001b8:	8b 44 24 08          	mov    0x8(%esp),%eax
  8001bc:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8001c0:	89 c3                	mov    %eax,%ebx
  8001c2:	89 d6                	mov    %edx,%esi
  8001c4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8001c7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8001ca:	89 54 24 08          	mov    %edx,0x8(%esp)
  8001ce:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8001d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8001d5:	89 04 24             	mov    %eax,(%esp)
  8001d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8001db:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001df:	e8 1c 0c 00 00       	call   800e00 <__udivdi3>
  8001e4:	89 d9                	mov    %ebx,%ecx
  8001e6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8001ea:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001ee:	89 04 24             	mov    %eax,(%esp)
  8001f1:	89 54 24 04          	mov    %edx,0x4(%esp)
  8001f5:	89 fa                	mov    %edi,%edx
  8001f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8001fa:	e8 71 ff ff ff       	call   800170 <printnum>
  8001ff:	eb 1b                	jmp    80021c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800201:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800205:	8b 45 18             	mov    0x18(%ebp),%eax
  800208:	89 04 24             	mov    %eax,(%esp)
  80020b:	ff d3                	call   *%ebx
  80020d:	eb 03                	jmp    800212 <printnum+0xa2>
  80020f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800212:	83 ee 01             	sub    $0x1,%esi
  800215:	85 f6                	test   %esi,%esi
  800217:	7f e8                	jg     800201 <printnum+0x91>
  800219:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80021c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800220:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800224:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800227:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80022a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80022e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800232:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800235:	89 04 24             	mov    %eax,(%esp)
  800238:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80023b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80023f:	e8 ec 0c 00 00       	call   800f30 <__umoddi3>
  800244:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800248:	0f be 80 d1 10 80 00 	movsbl 0x8010d1(%eax),%eax
  80024f:	89 04 24             	mov    %eax,(%esp)
  800252:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800255:	ff d0                	call   *%eax
}
  800257:	83 c4 3c             	add    $0x3c,%esp
  80025a:	5b                   	pop    %ebx
  80025b:	5e                   	pop    %esi
  80025c:	5f                   	pop    %edi
  80025d:	5d                   	pop    %ebp
  80025e:	c3                   	ret    

0080025f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80025f:	55                   	push   %ebp
  800260:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800262:	83 fa 01             	cmp    $0x1,%edx
  800265:	7e 0e                	jle    800275 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800267:	8b 10                	mov    (%eax),%edx
  800269:	8d 4a 08             	lea    0x8(%edx),%ecx
  80026c:	89 08                	mov    %ecx,(%eax)
  80026e:	8b 02                	mov    (%edx),%eax
  800270:	8b 52 04             	mov    0x4(%edx),%edx
  800273:	eb 22                	jmp    800297 <getuint+0x38>
	else if (lflag)
  800275:	85 d2                	test   %edx,%edx
  800277:	74 10                	je     800289 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800279:	8b 10                	mov    (%eax),%edx
  80027b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80027e:	89 08                	mov    %ecx,(%eax)
  800280:	8b 02                	mov    (%edx),%eax
  800282:	ba 00 00 00 00       	mov    $0x0,%edx
  800287:	eb 0e                	jmp    800297 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800289:	8b 10                	mov    (%eax),%edx
  80028b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80028e:	89 08                	mov    %ecx,(%eax)
  800290:	8b 02                	mov    (%edx),%eax
  800292:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800297:	5d                   	pop    %ebp
  800298:	c3                   	ret    

00800299 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800299:	55                   	push   %ebp
  80029a:	89 e5                	mov    %esp,%ebp
  80029c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80029f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002a3:	8b 10                	mov    (%eax),%edx
  8002a5:	3b 50 04             	cmp    0x4(%eax),%edx
  8002a8:	73 0a                	jae    8002b4 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002aa:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002ad:	89 08                	mov    %ecx,(%eax)
  8002af:	8b 45 08             	mov    0x8(%ebp),%eax
  8002b2:	88 02                	mov    %al,(%edx)
}
  8002b4:	5d                   	pop    %ebp
  8002b5:	c3                   	ret    

008002b6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002b6:	55                   	push   %ebp
  8002b7:	89 e5                	mov    %esp,%ebp
  8002b9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8002bc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002bf:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002c3:	8b 45 10             	mov    0x10(%ebp),%eax
  8002c6:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002ca:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002cd:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002d1:	8b 45 08             	mov    0x8(%ebp),%eax
  8002d4:	89 04 24             	mov    %eax,(%esp)
  8002d7:	e8 02 00 00 00       	call   8002de <vprintfmt>
	va_end(ap);
}
  8002dc:	c9                   	leave  
  8002dd:	c3                   	ret    

008002de <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002de:	55                   	push   %ebp
  8002df:	89 e5                	mov    %esp,%ebp
  8002e1:	57                   	push   %edi
  8002e2:	56                   	push   %esi
  8002e3:	53                   	push   %ebx
  8002e4:	83 ec 3c             	sub    $0x3c,%esp
  8002e7:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8002ea:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002ed:	eb 14                	jmp    800303 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  8002ef:	85 c0                	test   %eax,%eax
  8002f1:	0f 84 b3 03 00 00    	je     8006aa <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  8002f7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002fb:	89 04 24             	mov    %eax,(%esp)
  8002fe:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800301:	89 f3                	mov    %esi,%ebx
  800303:	8d 73 01             	lea    0x1(%ebx),%esi
  800306:	0f b6 03             	movzbl (%ebx),%eax
  800309:	83 f8 25             	cmp    $0x25,%eax
  80030c:	75 e1                	jne    8002ef <vprintfmt+0x11>
  80030e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800312:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800319:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800320:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800327:	ba 00 00 00 00       	mov    $0x0,%edx
  80032c:	eb 1d                	jmp    80034b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80032e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  800330:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800334:	eb 15                	jmp    80034b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800336:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800338:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80033c:	eb 0d                	jmp    80034b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80033e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800341:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800344:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80034b:	8d 5e 01             	lea    0x1(%esi),%ebx
  80034e:	0f b6 0e             	movzbl (%esi),%ecx
  800351:	0f b6 c1             	movzbl %cl,%eax
  800354:	83 e9 23             	sub    $0x23,%ecx
  800357:	80 f9 55             	cmp    $0x55,%cl
  80035a:	0f 87 2a 03 00 00    	ja     80068a <vprintfmt+0x3ac>
  800360:	0f b6 c9             	movzbl %cl,%ecx
  800363:	ff 24 8d a0 11 80 00 	jmp    *0x8011a0(,%ecx,4)
  80036a:	89 de                	mov    %ebx,%esi
  80036c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800371:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  800374:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  800378:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  80037b:	8d 58 d0             	lea    -0x30(%eax),%ebx
  80037e:	83 fb 09             	cmp    $0x9,%ebx
  800381:	77 36                	ja     8003b9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800383:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800386:	eb e9                	jmp    800371 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800388:	8b 45 14             	mov    0x14(%ebp),%eax
  80038b:	8d 48 04             	lea    0x4(%eax),%ecx
  80038e:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800391:	8b 00                	mov    (%eax),%eax
  800393:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800396:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800398:	eb 22                	jmp    8003bc <vprintfmt+0xde>
  80039a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80039d:	85 c9                	test   %ecx,%ecx
  80039f:	b8 00 00 00 00       	mov    $0x0,%eax
  8003a4:	0f 49 c1             	cmovns %ecx,%eax
  8003a7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003aa:	89 de                	mov    %ebx,%esi
  8003ac:	eb 9d                	jmp    80034b <vprintfmt+0x6d>
  8003ae:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8003b0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  8003b7:	eb 92                	jmp    80034b <vprintfmt+0x6d>
  8003b9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  8003bc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8003c0:	79 89                	jns    80034b <vprintfmt+0x6d>
  8003c2:	e9 77 ff ff ff       	jmp    80033e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8003c7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ca:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8003cc:	e9 7a ff ff ff       	jmp    80034b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8003d1:	8b 45 14             	mov    0x14(%ebp),%eax
  8003d4:	8d 50 04             	lea    0x4(%eax),%edx
  8003d7:	89 55 14             	mov    %edx,0x14(%ebp)
  8003da:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003de:	8b 00                	mov    (%eax),%eax
  8003e0:	89 04 24             	mov    %eax,(%esp)
  8003e3:	ff 55 08             	call   *0x8(%ebp)
			break;
  8003e6:	e9 18 ff ff ff       	jmp    800303 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003eb:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ee:	8d 50 04             	lea    0x4(%eax),%edx
  8003f1:	89 55 14             	mov    %edx,0x14(%ebp)
  8003f4:	8b 00                	mov    (%eax),%eax
  8003f6:	99                   	cltd   
  8003f7:	31 d0                	xor    %edx,%eax
  8003f9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003fb:	83 f8 09             	cmp    $0x9,%eax
  8003fe:	7f 0b                	jg     80040b <vprintfmt+0x12d>
  800400:	8b 14 85 00 13 80 00 	mov    0x801300(,%eax,4),%edx
  800407:	85 d2                	test   %edx,%edx
  800409:	75 20                	jne    80042b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  80040b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80040f:	c7 44 24 08 e9 10 80 	movl   $0x8010e9,0x8(%esp)
  800416:	00 
  800417:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80041b:	8b 45 08             	mov    0x8(%ebp),%eax
  80041e:	89 04 24             	mov    %eax,(%esp)
  800421:	e8 90 fe ff ff       	call   8002b6 <printfmt>
  800426:	e9 d8 fe ff ff       	jmp    800303 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80042b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80042f:	c7 44 24 08 f2 10 80 	movl   $0x8010f2,0x8(%esp)
  800436:	00 
  800437:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80043b:	8b 45 08             	mov    0x8(%ebp),%eax
  80043e:	89 04 24             	mov    %eax,(%esp)
  800441:	e8 70 fe ff ff       	call   8002b6 <printfmt>
  800446:	e9 b8 fe ff ff       	jmp    800303 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80044b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  80044e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800451:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800454:	8b 45 14             	mov    0x14(%ebp),%eax
  800457:	8d 50 04             	lea    0x4(%eax),%edx
  80045a:	89 55 14             	mov    %edx,0x14(%ebp)
  80045d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  80045f:	85 f6                	test   %esi,%esi
  800461:	b8 e2 10 80 00       	mov    $0x8010e2,%eax
  800466:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  800469:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  80046d:	0f 84 97 00 00 00    	je     80050a <vprintfmt+0x22c>
  800473:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800477:	0f 8e 9b 00 00 00    	jle    800518 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  80047d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800481:	89 34 24             	mov    %esi,(%esp)
  800484:	e8 cf 02 00 00       	call   800758 <strnlen>
  800489:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80048c:	29 c2                	sub    %eax,%edx
  80048e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  800491:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  800495:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800498:	89 75 d8             	mov    %esi,-0x28(%ebp)
  80049b:	8b 75 08             	mov    0x8(%ebp),%esi
  80049e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8004a1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004a3:	eb 0f                	jmp    8004b4 <vprintfmt+0x1d6>
					putch(padc, putdat);
  8004a5:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004a9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8004ac:	89 04 24             	mov    %eax,(%esp)
  8004af:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004b1:	83 eb 01             	sub    $0x1,%ebx
  8004b4:	85 db                	test   %ebx,%ebx
  8004b6:	7f ed                	jg     8004a5 <vprintfmt+0x1c7>
  8004b8:	8b 75 d8             	mov    -0x28(%ebp),%esi
  8004bb:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8004be:	85 d2                	test   %edx,%edx
  8004c0:	b8 00 00 00 00       	mov    $0x0,%eax
  8004c5:	0f 49 c2             	cmovns %edx,%eax
  8004c8:	29 c2                	sub    %eax,%edx
  8004ca:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8004cd:	89 d7                	mov    %edx,%edi
  8004cf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8004d2:	eb 50                	jmp    800524 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004d4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004d8:	74 1e                	je     8004f8 <vprintfmt+0x21a>
  8004da:	0f be d2             	movsbl %dl,%edx
  8004dd:	83 ea 20             	sub    $0x20,%edx
  8004e0:	83 fa 5e             	cmp    $0x5e,%edx
  8004e3:	76 13                	jbe    8004f8 <vprintfmt+0x21a>
					putch('?', putdat);
  8004e5:	8b 45 0c             	mov    0xc(%ebp),%eax
  8004e8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8004ec:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8004f3:	ff 55 08             	call   *0x8(%ebp)
  8004f6:	eb 0d                	jmp    800505 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  8004f8:	8b 55 0c             	mov    0xc(%ebp),%edx
  8004fb:	89 54 24 04          	mov    %edx,0x4(%esp)
  8004ff:	89 04 24             	mov    %eax,(%esp)
  800502:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800505:	83 ef 01             	sub    $0x1,%edi
  800508:	eb 1a                	jmp    800524 <vprintfmt+0x246>
  80050a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80050d:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800510:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800513:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800516:	eb 0c                	jmp    800524 <vprintfmt+0x246>
  800518:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80051b:	8b 7d dc             	mov    -0x24(%ebp),%edi
  80051e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800521:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800524:	83 c6 01             	add    $0x1,%esi
  800527:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  80052b:	0f be c2             	movsbl %dl,%eax
  80052e:	85 c0                	test   %eax,%eax
  800530:	74 27                	je     800559 <vprintfmt+0x27b>
  800532:	85 db                	test   %ebx,%ebx
  800534:	78 9e                	js     8004d4 <vprintfmt+0x1f6>
  800536:	83 eb 01             	sub    $0x1,%ebx
  800539:	79 99                	jns    8004d4 <vprintfmt+0x1f6>
  80053b:	89 f8                	mov    %edi,%eax
  80053d:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800540:	8b 75 08             	mov    0x8(%ebp),%esi
  800543:	89 c3                	mov    %eax,%ebx
  800545:	eb 1a                	jmp    800561 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800547:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80054b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800552:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800554:	83 eb 01             	sub    $0x1,%ebx
  800557:	eb 08                	jmp    800561 <vprintfmt+0x283>
  800559:	89 fb                	mov    %edi,%ebx
  80055b:	8b 75 08             	mov    0x8(%ebp),%esi
  80055e:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800561:	85 db                	test   %ebx,%ebx
  800563:	7f e2                	jg     800547 <vprintfmt+0x269>
  800565:	89 75 08             	mov    %esi,0x8(%ebp)
  800568:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80056b:	e9 93 fd ff ff       	jmp    800303 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800570:	83 fa 01             	cmp    $0x1,%edx
  800573:	7e 16                	jle    80058b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  800575:	8b 45 14             	mov    0x14(%ebp),%eax
  800578:	8d 50 08             	lea    0x8(%eax),%edx
  80057b:	89 55 14             	mov    %edx,0x14(%ebp)
  80057e:	8b 50 04             	mov    0x4(%eax),%edx
  800581:	8b 00                	mov    (%eax),%eax
  800583:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800586:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800589:	eb 32                	jmp    8005bd <vprintfmt+0x2df>
	else if (lflag)
  80058b:	85 d2                	test   %edx,%edx
  80058d:	74 18                	je     8005a7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  80058f:	8b 45 14             	mov    0x14(%ebp),%eax
  800592:	8d 50 04             	lea    0x4(%eax),%edx
  800595:	89 55 14             	mov    %edx,0x14(%ebp)
  800598:	8b 30                	mov    (%eax),%esi
  80059a:	89 75 e0             	mov    %esi,-0x20(%ebp)
  80059d:	89 f0                	mov    %esi,%eax
  80059f:	c1 f8 1f             	sar    $0x1f,%eax
  8005a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8005a5:	eb 16                	jmp    8005bd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  8005a7:	8b 45 14             	mov    0x14(%ebp),%eax
  8005aa:	8d 50 04             	lea    0x4(%eax),%edx
  8005ad:	89 55 14             	mov    %edx,0x14(%ebp)
  8005b0:	8b 30                	mov    (%eax),%esi
  8005b2:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8005b5:	89 f0                	mov    %esi,%eax
  8005b7:	c1 f8 1f             	sar    $0x1f,%eax
  8005ba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005c0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005c3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005c8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8005cc:	0f 89 80 00 00 00    	jns    800652 <vprintfmt+0x374>
				putch('-', putdat);
  8005d2:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005d6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8005dd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8005e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005e3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8005e6:	f7 d8                	neg    %eax
  8005e8:	83 d2 00             	adc    $0x0,%edx
  8005eb:	f7 da                	neg    %edx
			}
			base = 10;
  8005ed:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8005f2:	eb 5e                	jmp    800652 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8005f4:	8d 45 14             	lea    0x14(%ebp),%eax
  8005f7:	e8 63 fc ff ff       	call   80025f <getuint>
			base = 10;
  8005fc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800601:	eb 4f                	jmp    800652 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800603:	8d 45 14             	lea    0x14(%ebp),%eax
  800606:	e8 54 fc ff ff       	call   80025f <getuint>
			base = 8;
  80060b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800610:	eb 40                	jmp    800652 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
  800612:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800616:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80061d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800620:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800624:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80062b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80062e:	8b 45 14             	mov    0x14(%ebp),%eax
  800631:	8d 50 04             	lea    0x4(%eax),%edx
  800634:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800637:	8b 00                	mov    (%eax),%eax
  800639:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80063e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800643:	eb 0d                	jmp    800652 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800645:	8d 45 14             	lea    0x14(%ebp),%eax
  800648:	e8 12 fc ff ff       	call   80025f <getuint>
			base = 16;
  80064d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800652:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  800656:	89 74 24 10          	mov    %esi,0x10(%esp)
  80065a:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80065d:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800661:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800665:	89 04 24             	mov    %eax,(%esp)
  800668:	89 54 24 04          	mov    %edx,0x4(%esp)
  80066c:	89 fa                	mov    %edi,%edx
  80066e:	8b 45 08             	mov    0x8(%ebp),%eax
  800671:	e8 fa fa ff ff       	call   800170 <printnum>
			break;
  800676:	e9 88 fc ff ff       	jmp    800303 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80067b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80067f:	89 04 24             	mov    %eax,(%esp)
  800682:	ff 55 08             	call   *0x8(%ebp)
			break;
  800685:	e9 79 fc ff ff       	jmp    800303 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80068a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80068e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800695:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  800698:	89 f3                	mov    %esi,%ebx
  80069a:	eb 03                	jmp    80069f <vprintfmt+0x3c1>
  80069c:	83 eb 01             	sub    $0x1,%ebx
  80069f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8006a3:	75 f7                	jne    80069c <vprintfmt+0x3be>
  8006a5:	e9 59 fc ff ff       	jmp    800303 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8006aa:	83 c4 3c             	add    $0x3c,%esp
  8006ad:	5b                   	pop    %ebx
  8006ae:	5e                   	pop    %esi
  8006af:	5f                   	pop    %edi
  8006b0:	5d                   	pop    %ebp
  8006b1:	c3                   	ret    

008006b2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006b2:	55                   	push   %ebp
  8006b3:	89 e5                	mov    %esp,%ebp
  8006b5:	83 ec 28             	sub    $0x28,%esp
  8006b8:	8b 45 08             	mov    0x8(%ebp),%eax
  8006bb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006be:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006c1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006c5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006c8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006cf:	85 c0                	test   %eax,%eax
  8006d1:	74 30                	je     800703 <vsnprintf+0x51>
  8006d3:	85 d2                	test   %edx,%edx
  8006d5:	7e 2c                	jle    800703 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006d7:	8b 45 14             	mov    0x14(%ebp),%eax
  8006da:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006de:	8b 45 10             	mov    0x10(%ebp),%eax
  8006e1:	89 44 24 08          	mov    %eax,0x8(%esp)
  8006e5:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006e8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8006ec:	c7 04 24 99 02 80 00 	movl   $0x800299,(%esp)
  8006f3:	e8 e6 fb ff ff       	call   8002de <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8006f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8006fb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  8006fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800701:	eb 05                	jmp    800708 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800703:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800708:	c9                   	leave  
  800709:	c3                   	ret    

0080070a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80070a:	55                   	push   %ebp
  80070b:	89 e5                	mov    %esp,%ebp
  80070d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800710:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800713:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800717:	8b 45 10             	mov    0x10(%ebp),%eax
  80071a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80071e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800721:	89 44 24 04          	mov    %eax,0x4(%esp)
  800725:	8b 45 08             	mov    0x8(%ebp),%eax
  800728:	89 04 24             	mov    %eax,(%esp)
  80072b:	e8 82 ff ff ff       	call   8006b2 <vsnprintf>
	va_end(ap);

	return rc;
}
  800730:	c9                   	leave  
  800731:	c3                   	ret    
  800732:	66 90                	xchg   %ax,%ax
  800734:	66 90                	xchg   %ax,%ax
  800736:	66 90                	xchg   %ax,%ax
  800738:	66 90                	xchg   %ax,%ax
  80073a:	66 90                	xchg   %ax,%ax
  80073c:	66 90                	xchg   %ax,%ax
  80073e:	66 90                	xchg   %ax,%ax

00800740 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800740:	55                   	push   %ebp
  800741:	89 e5                	mov    %esp,%ebp
  800743:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800746:	b8 00 00 00 00       	mov    $0x0,%eax
  80074b:	eb 03                	jmp    800750 <strlen+0x10>
		n++;
  80074d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800750:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800754:	75 f7                	jne    80074d <strlen+0xd>
		n++;
	return n;
}
  800756:	5d                   	pop    %ebp
  800757:	c3                   	ret    

00800758 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800758:	55                   	push   %ebp
  800759:	89 e5                	mov    %esp,%ebp
  80075b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80075e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800761:	b8 00 00 00 00       	mov    $0x0,%eax
  800766:	eb 03                	jmp    80076b <strnlen+0x13>
		n++;
  800768:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80076b:	39 d0                	cmp    %edx,%eax
  80076d:	74 06                	je     800775 <strnlen+0x1d>
  80076f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800773:	75 f3                	jne    800768 <strnlen+0x10>
		n++;
	return n;
}
  800775:	5d                   	pop    %ebp
  800776:	c3                   	ret    

00800777 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800777:	55                   	push   %ebp
  800778:	89 e5                	mov    %esp,%ebp
  80077a:	53                   	push   %ebx
  80077b:	8b 45 08             	mov    0x8(%ebp),%eax
  80077e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800781:	89 c2                	mov    %eax,%edx
  800783:	83 c2 01             	add    $0x1,%edx
  800786:	83 c1 01             	add    $0x1,%ecx
  800789:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80078d:	88 5a ff             	mov    %bl,-0x1(%edx)
  800790:	84 db                	test   %bl,%bl
  800792:	75 ef                	jne    800783 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800794:	5b                   	pop    %ebx
  800795:	5d                   	pop    %ebp
  800796:	c3                   	ret    

00800797 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800797:	55                   	push   %ebp
  800798:	89 e5                	mov    %esp,%ebp
  80079a:	53                   	push   %ebx
  80079b:	83 ec 08             	sub    $0x8,%esp
  80079e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007a1:	89 1c 24             	mov    %ebx,(%esp)
  8007a4:	e8 97 ff ff ff       	call   800740 <strlen>
	strcpy(dst + len, src);
  8007a9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007ac:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007b0:	01 d8                	add    %ebx,%eax
  8007b2:	89 04 24             	mov    %eax,(%esp)
  8007b5:	e8 bd ff ff ff       	call   800777 <strcpy>
	return dst;
}
  8007ba:	89 d8                	mov    %ebx,%eax
  8007bc:	83 c4 08             	add    $0x8,%esp
  8007bf:	5b                   	pop    %ebx
  8007c0:	5d                   	pop    %ebp
  8007c1:	c3                   	ret    

008007c2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007c2:	55                   	push   %ebp
  8007c3:	89 e5                	mov    %esp,%ebp
  8007c5:	56                   	push   %esi
  8007c6:	53                   	push   %ebx
  8007c7:	8b 75 08             	mov    0x8(%ebp),%esi
  8007ca:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007cd:	89 f3                	mov    %esi,%ebx
  8007cf:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007d2:	89 f2                	mov    %esi,%edx
  8007d4:	eb 0f                	jmp    8007e5 <strncpy+0x23>
		*dst++ = *src;
  8007d6:	83 c2 01             	add    $0x1,%edx
  8007d9:	0f b6 01             	movzbl (%ecx),%eax
  8007dc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007df:	80 39 01             	cmpb   $0x1,(%ecx)
  8007e2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007e5:	39 da                	cmp    %ebx,%edx
  8007e7:	75 ed                	jne    8007d6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007e9:	89 f0                	mov    %esi,%eax
  8007eb:	5b                   	pop    %ebx
  8007ec:	5e                   	pop    %esi
  8007ed:	5d                   	pop    %ebp
  8007ee:	c3                   	ret    

008007ef <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007ef:	55                   	push   %ebp
  8007f0:	89 e5                	mov    %esp,%ebp
  8007f2:	56                   	push   %esi
  8007f3:	53                   	push   %ebx
  8007f4:	8b 75 08             	mov    0x8(%ebp),%esi
  8007f7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007fa:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8007fd:	89 f0                	mov    %esi,%eax
  8007ff:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800803:	85 c9                	test   %ecx,%ecx
  800805:	75 0b                	jne    800812 <strlcpy+0x23>
  800807:	eb 1d                	jmp    800826 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800809:	83 c0 01             	add    $0x1,%eax
  80080c:	83 c2 01             	add    $0x1,%edx
  80080f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800812:	39 d8                	cmp    %ebx,%eax
  800814:	74 0b                	je     800821 <strlcpy+0x32>
  800816:	0f b6 0a             	movzbl (%edx),%ecx
  800819:	84 c9                	test   %cl,%cl
  80081b:	75 ec                	jne    800809 <strlcpy+0x1a>
  80081d:	89 c2                	mov    %eax,%edx
  80081f:	eb 02                	jmp    800823 <strlcpy+0x34>
  800821:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800823:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800826:	29 f0                	sub    %esi,%eax
}
  800828:	5b                   	pop    %ebx
  800829:	5e                   	pop    %esi
  80082a:	5d                   	pop    %ebp
  80082b:	c3                   	ret    

0080082c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80082c:	55                   	push   %ebp
  80082d:	89 e5                	mov    %esp,%ebp
  80082f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800832:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800835:	eb 06                	jmp    80083d <strcmp+0x11>
		p++, q++;
  800837:	83 c1 01             	add    $0x1,%ecx
  80083a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80083d:	0f b6 01             	movzbl (%ecx),%eax
  800840:	84 c0                	test   %al,%al
  800842:	74 04                	je     800848 <strcmp+0x1c>
  800844:	3a 02                	cmp    (%edx),%al
  800846:	74 ef                	je     800837 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800848:	0f b6 c0             	movzbl %al,%eax
  80084b:	0f b6 12             	movzbl (%edx),%edx
  80084e:	29 d0                	sub    %edx,%eax
}
  800850:	5d                   	pop    %ebp
  800851:	c3                   	ret    

00800852 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800852:	55                   	push   %ebp
  800853:	89 e5                	mov    %esp,%ebp
  800855:	53                   	push   %ebx
  800856:	8b 45 08             	mov    0x8(%ebp),%eax
  800859:	8b 55 0c             	mov    0xc(%ebp),%edx
  80085c:	89 c3                	mov    %eax,%ebx
  80085e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800861:	eb 06                	jmp    800869 <strncmp+0x17>
		n--, p++, q++;
  800863:	83 c0 01             	add    $0x1,%eax
  800866:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800869:	39 d8                	cmp    %ebx,%eax
  80086b:	74 15                	je     800882 <strncmp+0x30>
  80086d:	0f b6 08             	movzbl (%eax),%ecx
  800870:	84 c9                	test   %cl,%cl
  800872:	74 04                	je     800878 <strncmp+0x26>
  800874:	3a 0a                	cmp    (%edx),%cl
  800876:	74 eb                	je     800863 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800878:	0f b6 00             	movzbl (%eax),%eax
  80087b:	0f b6 12             	movzbl (%edx),%edx
  80087e:	29 d0                	sub    %edx,%eax
  800880:	eb 05                	jmp    800887 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800882:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800887:	5b                   	pop    %ebx
  800888:	5d                   	pop    %ebp
  800889:	c3                   	ret    

0080088a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80088a:	55                   	push   %ebp
  80088b:	89 e5                	mov    %esp,%ebp
  80088d:	8b 45 08             	mov    0x8(%ebp),%eax
  800890:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800894:	eb 07                	jmp    80089d <strchr+0x13>
		if (*s == c)
  800896:	38 ca                	cmp    %cl,%dl
  800898:	74 0f                	je     8008a9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80089a:	83 c0 01             	add    $0x1,%eax
  80089d:	0f b6 10             	movzbl (%eax),%edx
  8008a0:	84 d2                	test   %dl,%dl
  8008a2:	75 f2                	jne    800896 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008a4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008a9:	5d                   	pop    %ebp
  8008aa:	c3                   	ret    

008008ab <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008ab:	55                   	push   %ebp
  8008ac:	89 e5                	mov    %esp,%ebp
  8008ae:	8b 45 08             	mov    0x8(%ebp),%eax
  8008b1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008b5:	eb 07                	jmp    8008be <strfind+0x13>
		if (*s == c)
  8008b7:	38 ca                	cmp    %cl,%dl
  8008b9:	74 0a                	je     8008c5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8008bb:	83 c0 01             	add    $0x1,%eax
  8008be:	0f b6 10             	movzbl (%eax),%edx
  8008c1:	84 d2                	test   %dl,%dl
  8008c3:	75 f2                	jne    8008b7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  8008c5:	5d                   	pop    %ebp
  8008c6:	c3                   	ret    

008008c7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008c7:	55                   	push   %ebp
  8008c8:	89 e5                	mov    %esp,%ebp
  8008ca:	57                   	push   %edi
  8008cb:	56                   	push   %esi
  8008cc:	53                   	push   %ebx
  8008cd:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008d0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008d3:	85 c9                	test   %ecx,%ecx
  8008d5:	74 36                	je     80090d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008d7:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008dd:	75 28                	jne    800907 <memset+0x40>
  8008df:	f6 c1 03             	test   $0x3,%cl
  8008e2:	75 23                	jne    800907 <memset+0x40>
		c &= 0xFF;
  8008e4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008e8:	89 d3                	mov    %edx,%ebx
  8008ea:	c1 e3 08             	shl    $0x8,%ebx
  8008ed:	89 d6                	mov    %edx,%esi
  8008ef:	c1 e6 18             	shl    $0x18,%esi
  8008f2:	89 d0                	mov    %edx,%eax
  8008f4:	c1 e0 10             	shl    $0x10,%eax
  8008f7:	09 f0                	or     %esi,%eax
  8008f9:	09 c2                	or     %eax,%edx
  8008fb:	89 d0                	mov    %edx,%eax
  8008fd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  8008ff:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800902:	fc                   	cld    
  800903:	f3 ab                	rep stos %eax,%es:(%edi)
  800905:	eb 06                	jmp    80090d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800907:	8b 45 0c             	mov    0xc(%ebp),%eax
  80090a:	fc                   	cld    
  80090b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80090d:	89 f8                	mov    %edi,%eax
  80090f:	5b                   	pop    %ebx
  800910:	5e                   	pop    %esi
  800911:	5f                   	pop    %edi
  800912:	5d                   	pop    %ebp
  800913:	c3                   	ret    

00800914 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800914:	55                   	push   %ebp
  800915:	89 e5                	mov    %esp,%ebp
  800917:	57                   	push   %edi
  800918:	56                   	push   %esi
  800919:	8b 45 08             	mov    0x8(%ebp),%eax
  80091c:	8b 75 0c             	mov    0xc(%ebp),%esi
  80091f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800922:	39 c6                	cmp    %eax,%esi
  800924:	73 35                	jae    80095b <memmove+0x47>
  800926:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800929:	39 d0                	cmp    %edx,%eax
  80092b:	73 2e                	jae    80095b <memmove+0x47>
		s += n;
		d += n;
  80092d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800930:	89 d6                	mov    %edx,%esi
  800932:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800934:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80093a:	75 13                	jne    80094f <memmove+0x3b>
  80093c:	f6 c1 03             	test   $0x3,%cl
  80093f:	75 0e                	jne    80094f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800941:	83 ef 04             	sub    $0x4,%edi
  800944:	8d 72 fc             	lea    -0x4(%edx),%esi
  800947:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  80094a:	fd                   	std    
  80094b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80094d:	eb 09                	jmp    800958 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  80094f:	83 ef 01             	sub    $0x1,%edi
  800952:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800955:	fd                   	std    
  800956:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800958:	fc                   	cld    
  800959:	eb 1d                	jmp    800978 <memmove+0x64>
  80095b:	89 f2                	mov    %esi,%edx
  80095d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80095f:	f6 c2 03             	test   $0x3,%dl
  800962:	75 0f                	jne    800973 <memmove+0x5f>
  800964:	f6 c1 03             	test   $0x3,%cl
  800967:	75 0a                	jne    800973 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800969:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  80096c:	89 c7                	mov    %eax,%edi
  80096e:	fc                   	cld    
  80096f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800971:	eb 05                	jmp    800978 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800973:	89 c7                	mov    %eax,%edi
  800975:	fc                   	cld    
  800976:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800978:	5e                   	pop    %esi
  800979:	5f                   	pop    %edi
  80097a:	5d                   	pop    %ebp
  80097b:	c3                   	ret    

0080097c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80097c:	55                   	push   %ebp
  80097d:	89 e5                	mov    %esp,%ebp
  80097f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800982:	8b 45 10             	mov    0x10(%ebp),%eax
  800985:	89 44 24 08          	mov    %eax,0x8(%esp)
  800989:	8b 45 0c             	mov    0xc(%ebp),%eax
  80098c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800990:	8b 45 08             	mov    0x8(%ebp),%eax
  800993:	89 04 24             	mov    %eax,(%esp)
  800996:	e8 79 ff ff ff       	call   800914 <memmove>
}
  80099b:	c9                   	leave  
  80099c:	c3                   	ret    

0080099d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  80099d:	55                   	push   %ebp
  80099e:	89 e5                	mov    %esp,%ebp
  8009a0:	56                   	push   %esi
  8009a1:	53                   	push   %ebx
  8009a2:	8b 55 08             	mov    0x8(%ebp),%edx
  8009a5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8009a8:	89 d6                	mov    %edx,%esi
  8009aa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009ad:	eb 1a                	jmp    8009c9 <memcmp+0x2c>
		if (*s1 != *s2)
  8009af:	0f b6 02             	movzbl (%edx),%eax
  8009b2:	0f b6 19             	movzbl (%ecx),%ebx
  8009b5:	38 d8                	cmp    %bl,%al
  8009b7:	74 0a                	je     8009c3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009b9:	0f b6 c0             	movzbl %al,%eax
  8009bc:	0f b6 db             	movzbl %bl,%ebx
  8009bf:	29 d8                	sub    %ebx,%eax
  8009c1:	eb 0f                	jmp    8009d2 <memcmp+0x35>
		s1++, s2++;
  8009c3:	83 c2 01             	add    $0x1,%edx
  8009c6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009c9:	39 f2                	cmp    %esi,%edx
  8009cb:	75 e2                	jne    8009af <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009cd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009d2:	5b                   	pop    %ebx
  8009d3:	5e                   	pop    %esi
  8009d4:	5d                   	pop    %ebp
  8009d5:	c3                   	ret    

008009d6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009d6:	55                   	push   %ebp
  8009d7:	89 e5                	mov    %esp,%ebp
  8009d9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009dc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8009df:	89 c2                	mov    %eax,%edx
  8009e1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  8009e4:	eb 07                	jmp    8009ed <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009e6:	38 08                	cmp    %cl,(%eax)
  8009e8:	74 07                	je     8009f1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009ea:	83 c0 01             	add    $0x1,%eax
  8009ed:	39 d0                	cmp    %edx,%eax
  8009ef:	72 f5                	jb     8009e6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  8009f1:	5d                   	pop    %ebp
  8009f2:	c3                   	ret    

008009f3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  8009f3:	55                   	push   %ebp
  8009f4:	89 e5                	mov    %esp,%ebp
  8009f6:	57                   	push   %edi
  8009f7:	56                   	push   %esi
  8009f8:	53                   	push   %ebx
  8009f9:	8b 55 08             	mov    0x8(%ebp),%edx
  8009fc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  8009ff:	eb 03                	jmp    800a04 <strtol+0x11>
		s++;
  800a01:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a04:	0f b6 0a             	movzbl (%edx),%ecx
  800a07:	80 f9 09             	cmp    $0x9,%cl
  800a0a:	74 f5                	je     800a01 <strtol+0xe>
  800a0c:	80 f9 20             	cmp    $0x20,%cl
  800a0f:	74 f0                	je     800a01 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a11:	80 f9 2b             	cmp    $0x2b,%cl
  800a14:	75 0a                	jne    800a20 <strtol+0x2d>
		s++;
  800a16:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a19:	bf 00 00 00 00       	mov    $0x0,%edi
  800a1e:	eb 11                	jmp    800a31 <strtol+0x3e>
  800a20:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a25:	80 f9 2d             	cmp    $0x2d,%cl
  800a28:	75 07                	jne    800a31 <strtol+0x3e>
		s++, neg = 1;
  800a2a:	8d 52 01             	lea    0x1(%edx),%edx
  800a2d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a31:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800a36:	75 15                	jne    800a4d <strtol+0x5a>
  800a38:	80 3a 30             	cmpb   $0x30,(%edx)
  800a3b:	75 10                	jne    800a4d <strtol+0x5a>
  800a3d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800a41:	75 0a                	jne    800a4d <strtol+0x5a>
		s += 2, base = 16;
  800a43:	83 c2 02             	add    $0x2,%edx
  800a46:	b8 10 00 00 00       	mov    $0x10,%eax
  800a4b:	eb 10                	jmp    800a5d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800a4d:	85 c0                	test   %eax,%eax
  800a4f:	75 0c                	jne    800a5d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a51:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a53:	80 3a 30             	cmpb   $0x30,(%edx)
  800a56:	75 05                	jne    800a5d <strtol+0x6a>
		s++, base = 8;
  800a58:	83 c2 01             	add    $0x1,%edx
  800a5b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800a5d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800a62:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a65:	0f b6 0a             	movzbl (%edx),%ecx
  800a68:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800a6b:	89 f0                	mov    %esi,%eax
  800a6d:	3c 09                	cmp    $0x9,%al
  800a6f:	77 08                	ja     800a79 <strtol+0x86>
			dig = *s - '0';
  800a71:	0f be c9             	movsbl %cl,%ecx
  800a74:	83 e9 30             	sub    $0x30,%ecx
  800a77:	eb 20                	jmp    800a99 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800a79:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800a7c:	89 f0                	mov    %esi,%eax
  800a7e:	3c 19                	cmp    $0x19,%al
  800a80:	77 08                	ja     800a8a <strtol+0x97>
			dig = *s - 'a' + 10;
  800a82:	0f be c9             	movsbl %cl,%ecx
  800a85:	83 e9 57             	sub    $0x57,%ecx
  800a88:	eb 0f                	jmp    800a99 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800a8a:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800a8d:	89 f0                	mov    %esi,%eax
  800a8f:	3c 19                	cmp    $0x19,%al
  800a91:	77 16                	ja     800aa9 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800a93:	0f be c9             	movsbl %cl,%ecx
  800a96:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800a99:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800a9c:	7d 0f                	jge    800aad <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800a9e:	83 c2 01             	add    $0x1,%edx
  800aa1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800aa5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800aa7:	eb bc                	jmp    800a65 <strtol+0x72>
  800aa9:	89 d8                	mov    %ebx,%eax
  800aab:	eb 02                	jmp    800aaf <strtol+0xbc>
  800aad:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800aaf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ab3:	74 05                	je     800aba <strtol+0xc7>
		*endptr = (char *) s;
  800ab5:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ab8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800aba:	f7 d8                	neg    %eax
  800abc:	85 ff                	test   %edi,%edi
  800abe:	0f 44 c3             	cmove  %ebx,%eax
}
  800ac1:	5b                   	pop    %ebx
  800ac2:	5e                   	pop    %esi
  800ac3:	5f                   	pop    %edi
  800ac4:	5d                   	pop    %ebp
  800ac5:	c3                   	ret    

00800ac6 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800ac6:	55                   	push   %ebp
  800ac7:	89 e5                	mov    %esp,%ebp
  800ac9:	57                   	push   %edi
  800aca:	56                   	push   %esi
  800acb:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800acc:	b8 00 00 00 00       	mov    $0x0,%eax
  800ad1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ad4:	8b 55 08             	mov    0x8(%ebp),%edx
  800ad7:	89 c3                	mov    %eax,%ebx
  800ad9:	89 c7                	mov    %eax,%edi
  800adb:	89 c6                	mov    %eax,%esi
  800add:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800adf:	5b                   	pop    %ebx
  800ae0:	5e                   	pop    %esi
  800ae1:	5f                   	pop    %edi
  800ae2:	5d                   	pop    %ebp
  800ae3:	c3                   	ret    

00800ae4 <sys_cgetc>:

int
sys_cgetc(void)
{
  800ae4:	55                   	push   %ebp
  800ae5:	89 e5                	mov    %esp,%ebp
  800ae7:	57                   	push   %edi
  800ae8:	56                   	push   %esi
  800ae9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800aea:	ba 00 00 00 00       	mov    $0x0,%edx
  800aef:	b8 01 00 00 00       	mov    $0x1,%eax
  800af4:	89 d1                	mov    %edx,%ecx
  800af6:	89 d3                	mov    %edx,%ebx
  800af8:	89 d7                	mov    %edx,%edi
  800afa:	89 d6                	mov    %edx,%esi
  800afc:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800afe:	5b                   	pop    %ebx
  800aff:	5e                   	pop    %esi
  800b00:	5f                   	pop    %edi
  800b01:	5d                   	pop    %ebp
  800b02:	c3                   	ret    

00800b03 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b03:	55                   	push   %ebp
  800b04:	89 e5                	mov    %esp,%ebp
  800b06:	57                   	push   %edi
  800b07:	56                   	push   %esi
  800b08:	53                   	push   %ebx
  800b09:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b0c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b11:	b8 03 00 00 00       	mov    $0x3,%eax
  800b16:	8b 55 08             	mov    0x8(%ebp),%edx
  800b19:	89 cb                	mov    %ecx,%ebx
  800b1b:	89 cf                	mov    %ecx,%edi
  800b1d:	89 ce                	mov    %ecx,%esi
  800b1f:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800b21:	85 c0                	test   %eax,%eax
  800b23:	7e 28                	jle    800b4d <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b25:	89 44 24 10          	mov    %eax,0x10(%esp)
  800b29:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800b30:	00 
  800b31:	c7 44 24 08 28 13 80 	movl   $0x801328,0x8(%esp)
  800b38:	00 
  800b39:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800b40:	00 
  800b41:	c7 04 24 45 13 80 00 	movl   $0x801345,(%esp)
  800b48:	e8 5b 02 00 00       	call   800da8 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b4d:	83 c4 2c             	add    $0x2c,%esp
  800b50:	5b                   	pop    %ebx
  800b51:	5e                   	pop    %esi
  800b52:	5f                   	pop    %edi
  800b53:	5d                   	pop    %ebp
  800b54:	c3                   	ret    

00800b55 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b55:	55                   	push   %ebp
  800b56:	89 e5                	mov    %esp,%ebp
  800b58:	57                   	push   %edi
  800b59:	56                   	push   %esi
  800b5a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b5b:	ba 00 00 00 00       	mov    $0x0,%edx
  800b60:	b8 02 00 00 00       	mov    $0x2,%eax
  800b65:	89 d1                	mov    %edx,%ecx
  800b67:	89 d3                	mov    %edx,%ebx
  800b69:	89 d7                	mov    %edx,%edi
  800b6b:	89 d6                	mov    %edx,%esi
  800b6d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b6f:	5b                   	pop    %ebx
  800b70:	5e                   	pop    %esi
  800b71:	5f                   	pop    %edi
  800b72:	5d                   	pop    %ebp
  800b73:	c3                   	ret    

00800b74 <sys_yield>:

void
sys_yield(void)
{
  800b74:	55                   	push   %ebp
  800b75:	89 e5                	mov    %esp,%ebp
  800b77:	57                   	push   %edi
  800b78:	56                   	push   %esi
  800b79:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b7a:	ba 00 00 00 00       	mov    $0x0,%edx
  800b7f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800b84:	89 d1                	mov    %edx,%ecx
  800b86:	89 d3                	mov    %edx,%ebx
  800b88:	89 d7                	mov    %edx,%edi
  800b8a:	89 d6                	mov    %edx,%esi
  800b8c:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800b8e:	5b                   	pop    %ebx
  800b8f:	5e                   	pop    %esi
  800b90:	5f                   	pop    %edi
  800b91:	5d                   	pop    %ebp
  800b92:	c3                   	ret    

00800b93 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800b93:	55                   	push   %ebp
  800b94:	89 e5                	mov    %esp,%ebp
  800b96:	57                   	push   %edi
  800b97:	56                   	push   %esi
  800b98:	53                   	push   %ebx
  800b99:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b9c:	be 00 00 00 00       	mov    $0x0,%esi
  800ba1:	b8 04 00 00 00       	mov    $0x4,%eax
  800ba6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ba9:	8b 55 08             	mov    0x8(%ebp),%edx
  800bac:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800baf:	89 f7                	mov    %esi,%edi
  800bb1:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800bb3:	85 c0                	test   %eax,%eax
  800bb5:	7e 28                	jle    800bdf <sys_page_alloc+0x4c>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bb7:	89 44 24 10          	mov    %eax,0x10(%esp)
  800bbb:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800bc2:	00 
  800bc3:	c7 44 24 08 28 13 80 	movl   $0x801328,0x8(%esp)
  800bca:	00 
  800bcb:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800bd2:	00 
  800bd3:	c7 04 24 45 13 80 00 	movl   $0x801345,(%esp)
  800bda:	e8 c9 01 00 00       	call   800da8 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800bdf:	83 c4 2c             	add    $0x2c,%esp
  800be2:	5b                   	pop    %ebx
  800be3:	5e                   	pop    %esi
  800be4:	5f                   	pop    %edi
  800be5:	5d                   	pop    %ebp
  800be6:	c3                   	ret    

00800be7 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800be7:	55                   	push   %ebp
  800be8:	89 e5                	mov    %esp,%ebp
  800bea:	57                   	push   %edi
  800beb:	56                   	push   %esi
  800bec:	53                   	push   %ebx
  800bed:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bf0:	b8 05 00 00 00       	mov    $0x5,%eax
  800bf5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800bf8:	8b 55 08             	mov    0x8(%ebp),%edx
  800bfb:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800bfe:	8b 7d 14             	mov    0x14(%ebp),%edi
  800c01:	8b 75 18             	mov    0x18(%ebp),%esi
  800c04:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c06:	85 c0                	test   %eax,%eax
  800c08:	7e 28                	jle    800c32 <sys_page_map+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c0a:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c0e:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800c15:	00 
  800c16:	c7 44 24 08 28 13 80 	movl   $0x801328,0x8(%esp)
  800c1d:	00 
  800c1e:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c25:	00 
  800c26:	c7 04 24 45 13 80 00 	movl   $0x801345,(%esp)
  800c2d:	e8 76 01 00 00       	call   800da8 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800c32:	83 c4 2c             	add    $0x2c,%esp
  800c35:	5b                   	pop    %ebx
  800c36:	5e                   	pop    %esi
  800c37:	5f                   	pop    %edi
  800c38:	5d                   	pop    %ebp
  800c39:	c3                   	ret    

00800c3a <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800c3a:	55                   	push   %ebp
  800c3b:	89 e5                	mov    %esp,%ebp
  800c3d:	57                   	push   %edi
  800c3e:	56                   	push   %esi
  800c3f:	53                   	push   %ebx
  800c40:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c43:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c48:	b8 06 00 00 00       	mov    $0x6,%eax
  800c4d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c50:	8b 55 08             	mov    0x8(%ebp),%edx
  800c53:	89 df                	mov    %ebx,%edi
  800c55:	89 de                	mov    %ebx,%esi
  800c57:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c59:	85 c0                	test   %eax,%eax
  800c5b:	7e 28                	jle    800c85 <sys_page_unmap+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c5d:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c61:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800c68:	00 
  800c69:	c7 44 24 08 28 13 80 	movl   $0x801328,0x8(%esp)
  800c70:	00 
  800c71:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c78:	00 
  800c79:	c7 04 24 45 13 80 00 	movl   $0x801345,(%esp)
  800c80:	e8 23 01 00 00       	call   800da8 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800c85:	83 c4 2c             	add    $0x2c,%esp
  800c88:	5b                   	pop    %ebx
  800c89:	5e                   	pop    %esi
  800c8a:	5f                   	pop    %edi
  800c8b:	5d                   	pop    %ebp
  800c8c:	c3                   	ret    

00800c8d <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800c8d:	55                   	push   %ebp
  800c8e:	89 e5                	mov    %esp,%ebp
  800c90:	57                   	push   %edi
  800c91:	56                   	push   %esi
  800c92:	53                   	push   %ebx
  800c93:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c96:	bb 00 00 00 00       	mov    $0x0,%ebx
  800c9b:	b8 08 00 00 00       	mov    $0x8,%eax
  800ca0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ca3:	8b 55 08             	mov    0x8(%ebp),%edx
  800ca6:	89 df                	mov    %ebx,%edi
  800ca8:	89 de                	mov    %ebx,%esi
  800caa:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800cac:	85 c0                	test   %eax,%eax
  800cae:	7e 28                	jle    800cd8 <sys_env_set_status+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cb0:	89 44 24 10          	mov    %eax,0x10(%esp)
  800cb4:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800cbb:	00 
  800cbc:	c7 44 24 08 28 13 80 	movl   $0x801328,0x8(%esp)
  800cc3:	00 
  800cc4:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ccb:	00 
  800ccc:	c7 04 24 45 13 80 00 	movl   $0x801345,(%esp)
  800cd3:	e8 d0 00 00 00       	call   800da8 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800cd8:	83 c4 2c             	add    $0x2c,%esp
  800cdb:	5b                   	pop    %ebx
  800cdc:	5e                   	pop    %esi
  800cdd:	5f                   	pop    %edi
  800cde:	5d                   	pop    %ebp
  800cdf:	c3                   	ret    

00800ce0 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800ce0:	55                   	push   %ebp
  800ce1:	89 e5                	mov    %esp,%ebp
  800ce3:	57                   	push   %edi
  800ce4:	56                   	push   %esi
  800ce5:	53                   	push   %ebx
  800ce6:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ce9:	bb 00 00 00 00       	mov    $0x0,%ebx
  800cee:	b8 09 00 00 00       	mov    $0x9,%eax
  800cf3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cf6:	8b 55 08             	mov    0x8(%ebp),%edx
  800cf9:	89 df                	mov    %ebx,%edi
  800cfb:	89 de                	mov    %ebx,%esi
  800cfd:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800cff:	85 c0                	test   %eax,%eax
  800d01:	7e 28                	jle    800d2b <sys_env_set_pgfault_upcall+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d03:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d07:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800d0e:	00 
  800d0f:	c7 44 24 08 28 13 80 	movl   $0x801328,0x8(%esp)
  800d16:	00 
  800d17:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d1e:	00 
  800d1f:	c7 04 24 45 13 80 00 	movl   $0x801345,(%esp)
  800d26:	e8 7d 00 00 00       	call   800da8 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800d2b:	83 c4 2c             	add    $0x2c,%esp
  800d2e:	5b                   	pop    %ebx
  800d2f:	5e                   	pop    %esi
  800d30:	5f                   	pop    %edi
  800d31:	5d                   	pop    %ebp
  800d32:	c3                   	ret    

00800d33 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800d33:	55                   	push   %ebp
  800d34:	89 e5                	mov    %esp,%ebp
  800d36:	57                   	push   %edi
  800d37:	56                   	push   %esi
  800d38:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d39:	be 00 00 00 00       	mov    $0x0,%esi
  800d3e:	b8 0b 00 00 00       	mov    $0xb,%eax
  800d43:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d46:	8b 55 08             	mov    0x8(%ebp),%edx
  800d49:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800d4c:	8b 7d 14             	mov    0x14(%ebp),%edi
  800d4f:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800d51:	5b                   	pop    %ebx
  800d52:	5e                   	pop    %esi
  800d53:	5f                   	pop    %edi
  800d54:	5d                   	pop    %ebp
  800d55:	c3                   	ret    

00800d56 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800d56:	55                   	push   %ebp
  800d57:	89 e5                	mov    %esp,%ebp
  800d59:	57                   	push   %edi
  800d5a:	56                   	push   %esi
  800d5b:	53                   	push   %ebx
  800d5c:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d5f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800d64:	b8 0c 00 00 00       	mov    $0xc,%eax
  800d69:	8b 55 08             	mov    0x8(%ebp),%edx
  800d6c:	89 cb                	mov    %ecx,%ebx
  800d6e:	89 cf                	mov    %ecx,%edi
  800d70:	89 ce                	mov    %ecx,%esi
  800d72:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d74:	85 c0                	test   %eax,%eax
  800d76:	7e 28                	jle    800da0 <sys_ipc_recv+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d78:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d7c:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800d83:	00 
  800d84:	c7 44 24 08 28 13 80 	movl   $0x801328,0x8(%esp)
  800d8b:	00 
  800d8c:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d93:	00 
  800d94:	c7 04 24 45 13 80 00 	movl   $0x801345,(%esp)
  800d9b:	e8 08 00 00 00       	call   800da8 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800da0:	83 c4 2c             	add    $0x2c,%esp
  800da3:	5b                   	pop    %ebx
  800da4:	5e                   	pop    %esi
  800da5:	5f                   	pop    %edi
  800da6:	5d                   	pop    %ebp
  800da7:	c3                   	ret    

00800da8 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800da8:	55                   	push   %ebp
  800da9:	89 e5                	mov    %esp,%ebp
  800dab:	56                   	push   %esi
  800dac:	53                   	push   %ebx
  800dad:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800db0:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800db3:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800db9:	e8 97 fd ff ff       	call   800b55 <sys_getenvid>
  800dbe:	8b 55 0c             	mov    0xc(%ebp),%edx
  800dc1:	89 54 24 10          	mov    %edx,0x10(%esp)
  800dc5:	8b 55 08             	mov    0x8(%ebp),%edx
  800dc8:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800dcc:	89 74 24 08          	mov    %esi,0x8(%esp)
  800dd0:	89 44 24 04          	mov    %eax,0x4(%esp)
  800dd4:	c7 04 24 54 13 80 00 	movl   $0x801354,(%esp)
  800ddb:	e8 6f f3 ff ff       	call   80014f <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800de0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800de4:	8b 45 10             	mov    0x10(%ebp),%eax
  800de7:	89 04 24             	mov    %eax,(%esp)
  800dea:	e8 ff f2 ff ff       	call   8000ee <vcprintf>
	cprintf("\n");
  800def:	c7 04 24 78 13 80 00 	movl   $0x801378,(%esp)
  800df6:	e8 54 f3 ff ff       	call   80014f <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800dfb:	cc                   	int3   
  800dfc:	eb fd                	jmp    800dfb <_panic+0x53>
  800dfe:	66 90                	xchg   %ax,%ax

00800e00 <__udivdi3>:
  800e00:	55                   	push   %ebp
  800e01:	57                   	push   %edi
  800e02:	56                   	push   %esi
  800e03:	83 ec 0c             	sub    $0xc,%esp
  800e06:	8b 44 24 28          	mov    0x28(%esp),%eax
  800e0a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800e0e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800e12:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800e16:	85 c0                	test   %eax,%eax
  800e18:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800e1c:	89 ea                	mov    %ebp,%edx
  800e1e:	89 0c 24             	mov    %ecx,(%esp)
  800e21:	75 2d                	jne    800e50 <__udivdi3+0x50>
  800e23:	39 e9                	cmp    %ebp,%ecx
  800e25:	77 61                	ja     800e88 <__udivdi3+0x88>
  800e27:	85 c9                	test   %ecx,%ecx
  800e29:	89 ce                	mov    %ecx,%esi
  800e2b:	75 0b                	jne    800e38 <__udivdi3+0x38>
  800e2d:	b8 01 00 00 00       	mov    $0x1,%eax
  800e32:	31 d2                	xor    %edx,%edx
  800e34:	f7 f1                	div    %ecx
  800e36:	89 c6                	mov    %eax,%esi
  800e38:	31 d2                	xor    %edx,%edx
  800e3a:	89 e8                	mov    %ebp,%eax
  800e3c:	f7 f6                	div    %esi
  800e3e:	89 c5                	mov    %eax,%ebp
  800e40:	89 f8                	mov    %edi,%eax
  800e42:	f7 f6                	div    %esi
  800e44:	89 ea                	mov    %ebp,%edx
  800e46:	83 c4 0c             	add    $0xc,%esp
  800e49:	5e                   	pop    %esi
  800e4a:	5f                   	pop    %edi
  800e4b:	5d                   	pop    %ebp
  800e4c:	c3                   	ret    
  800e4d:	8d 76 00             	lea    0x0(%esi),%esi
  800e50:	39 e8                	cmp    %ebp,%eax
  800e52:	77 24                	ja     800e78 <__udivdi3+0x78>
  800e54:	0f bd e8             	bsr    %eax,%ebp
  800e57:	83 f5 1f             	xor    $0x1f,%ebp
  800e5a:	75 3c                	jne    800e98 <__udivdi3+0x98>
  800e5c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800e60:	39 34 24             	cmp    %esi,(%esp)
  800e63:	0f 86 9f 00 00 00    	jbe    800f08 <__udivdi3+0x108>
  800e69:	39 d0                	cmp    %edx,%eax
  800e6b:	0f 82 97 00 00 00    	jb     800f08 <__udivdi3+0x108>
  800e71:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800e78:	31 d2                	xor    %edx,%edx
  800e7a:	31 c0                	xor    %eax,%eax
  800e7c:	83 c4 0c             	add    $0xc,%esp
  800e7f:	5e                   	pop    %esi
  800e80:	5f                   	pop    %edi
  800e81:	5d                   	pop    %ebp
  800e82:	c3                   	ret    
  800e83:	90                   	nop
  800e84:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e88:	89 f8                	mov    %edi,%eax
  800e8a:	f7 f1                	div    %ecx
  800e8c:	31 d2                	xor    %edx,%edx
  800e8e:	83 c4 0c             	add    $0xc,%esp
  800e91:	5e                   	pop    %esi
  800e92:	5f                   	pop    %edi
  800e93:	5d                   	pop    %ebp
  800e94:	c3                   	ret    
  800e95:	8d 76 00             	lea    0x0(%esi),%esi
  800e98:	89 e9                	mov    %ebp,%ecx
  800e9a:	8b 3c 24             	mov    (%esp),%edi
  800e9d:	d3 e0                	shl    %cl,%eax
  800e9f:	89 c6                	mov    %eax,%esi
  800ea1:	b8 20 00 00 00       	mov    $0x20,%eax
  800ea6:	29 e8                	sub    %ebp,%eax
  800ea8:	89 c1                	mov    %eax,%ecx
  800eaa:	d3 ef                	shr    %cl,%edi
  800eac:	89 e9                	mov    %ebp,%ecx
  800eae:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800eb2:	8b 3c 24             	mov    (%esp),%edi
  800eb5:	09 74 24 08          	or     %esi,0x8(%esp)
  800eb9:	89 d6                	mov    %edx,%esi
  800ebb:	d3 e7                	shl    %cl,%edi
  800ebd:	89 c1                	mov    %eax,%ecx
  800ebf:	89 3c 24             	mov    %edi,(%esp)
  800ec2:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800ec6:	d3 ee                	shr    %cl,%esi
  800ec8:	89 e9                	mov    %ebp,%ecx
  800eca:	d3 e2                	shl    %cl,%edx
  800ecc:	89 c1                	mov    %eax,%ecx
  800ece:	d3 ef                	shr    %cl,%edi
  800ed0:	09 d7                	or     %edx,%edi
  800ed2:	89 f2                	mov    %esi,%edx
  800ed4:	89 f8                	mov    %edi,%eax
  800ed6:	f7 74 24 08          	divl   0x8(%esp)
  800eda:	89 d6                	mov    %edx,%esi
  800edc:	89 c7                	mov    %eax,%edi
  800ede:	f7 24 24             	mull   (%esp)
  800ee1:	39 d6                	cmp    %edx,%esi
  800ee3:	89 14 24             	mov    %edx,(%esp)
  800ee6:	72 30                	jb     800f18 <__udivdi3+0x118>
  800ee8:	8b 54 24 04          	mov    0x4(%esp),%edx
  800eec:	89 e9                	mov    %ebp,%ecx
  800eee:	d3 e2                	shl    %cl,%edx
  800ef0:	39 c2                	cmp    %eax,%edx
  800ef2:	73 05                	jae    800ef9 <__udivdi3+0xf9>
  800ef4:	3b 34 24             	cmp    (%esp),%esi
  800ef7:	74 1f                	je     800f18 <__udivdi3+0x118>
  800ef9:	89 f8                	mov    %edi,%eax
  800efb:	31 d2                	xor    %edx,%edx
  800efd:	e9 7a ff ff ff       	jmp    800e7c <__udivdi3+0x7c>
  800f02:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800f08:	31 d2                	xor    %edx,%edx
  800f0a:	b8 01 00 00 00       	mov    $0x1,%eax
  800f0f:	e9 68 ff ff ff       	jmp    800e7c <__udivdi3+0x7c>
  800f14:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f18:	8d 47 ff             	lea    -0x1(%edi),%eax
  800f1b:	31 d2                	xor    %edx,%edx
  800f1d:	83 c4 0c             	add    $0xc,%esp
  800f20:	5e                   	pop    %esi
  800f21:	5f                   	pop    %edi
  800f22:	5d                   	pop    %ebp
  800f23:	c3                   	ret    
  800f24:	66 90                	xchg   %ax,%ax
  800f26:	66 90                	xchg   %ax,%ax
  800f28:	66 90                	xchg   %ax,%ax
  800f2a:	66 90                	xchg   %ax,%ax
  800f2c:	66 90                	xchg   %ax,%ax
  800f2e:	66 90                	xchg   %ax,%ax

00800f30 <__umoddi3>:
  800f30:	55                   	push   %ebp
  800f31:	57                   	push   %edi
  800f32:	56                   	push   %esi
  800f33:	83 ec 14             	sub    $0x14,%esp
  800f36:	8b 44 24 28          	mov    0x28(%esp),%eax
  800f3a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800f3e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800f42:	89 c7                	mov    %eax,%edi
  800f44:	89 44 24 04          	mov    %eax,0x4(%esp)
  800f48:	8b 44 24 30          	mov    0x30(%esp),%eax
  800f4c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800f50:	89 34 24             	mov    %esi,(%esp)
  800f53:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800f57:	85 c0                	test   %eax,%eax
  800f59:	89 c2                	mov    %eax,%edx
  800f5b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800f5f:	75 17                	jne    800f78 <__umoddi3+0x48>
  800f61:	39 fe                	cmp    %edi,%esi
  800f63:	76 4b                	jbe    800fb0 <__umoddi3+0x80>
  800f65:	89 c8                	mov    %ecx,%eax
  800f67:	89 fa                	mov    %edi,%edx
  800f69:	f7 f6                	div    %esi
  800f6b:	89 d0                	mov    %edx,%eax
  800f6d:	31 d2                	xor    %edx,%edx
  800f6f:	83 c4 14             	add    $0x14,%esp
  800f72:	5e                   	pop    %esi
  800f73:	5f                   	pop    %edi
  800f74:	5d                   	pop    %ebp
  800f75:	c3                   	ret    
  800f76:	66 90                	xchg   %ax,%ax
  800f78:	39 f8                	cmp    %edi,%eax
  800f7a:	77 54                	ja     800fd0 <__umoddi3+0xa0>
  800f7c:	0f bd e8             	bsr    %eax,%ebp
  800f7f:	83 f5 1f             	xor    $0x1f,%ebp
  800f82:	75 5c                	jne    800fe0 <__umoddi3+0xb0>
  800f84:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800f88:	39 3c 24             	cmp    %edi,(%esp)
  800f8b:	0f 87 e7 00 00 00    	ja     801078 <__umoddi3+0x148>
  800f91:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800f95:	29 f1                	sub    %esi,%ecx
  800f97:	19 c7                	sbb    %eax,%edi
  800f99:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800f9d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800fa1:	8b 44 24 08          	mov    0x8(%esp),%eax
  800fa5:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800fa9:	83 c4 14             	add    $0x14,%esp
  800fac:	5e                   	pop    %esi
  800fad:	5f                   	pop    %edi
  800fae:	5d                   	pop    %ebp
  800faf:	c3                   	ret    
  800fb0:	85 f6                	test   %esi,%esi
  800fb2:	89 f5                	mov    %esi,%ebp
  800fb4:	75 0b                	jne    800fc1 <__umoddi3+0x91>
  800fb6:	b8 01 00 00 00       	mov    $0x1,%eax
  800fbb:	31 d2                	xor    %edx,%edx
  800fbd:	f7 f6                	div    %esi
  800fbf:	89 c5                	mov    %eax,%ebp
  800fc1:	8b 44 24 04          	mov    0x4(%esp),%eax
  800fc5:	31 d2                	xor    %edx,%edx
  800fc7:	f7 f5                	div    %ebp
  800fc9:	89 c8                	mov    %ecx,%eax
  800fcb:	f7 f5                	div    %ebp
  800fcd:	eb 9c                	jmp    800f6b <__umoddi3+0x3b>
  800fcf:	90                   	nop
  800fd0:	89 c8                	mov    %ecx,%eax
  800fd2:	89 fa                	mov    %edi,%edx
  800fd4:	83 c4 14             	add    $0x14,%esp
  800fd7:	5e                   	pop    %esi
  800fd8:	5f                   	pop    %edi
  800fd9:	5d                   	pop    %ebp
  800fda:	c3                   	ret    
  800fdb:	90                   	nop
  800fdc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800fe0:	8b 04 24             	mov    (%esp),%eax
  800fe3:	be 20 00 00 00       	mov    $0x20,%esi
  800fe8:	89 e9                	mov    %ebp,%ecx
  800fea:	29 ee                	sub    %ebp,%esi
  800fec:	d3 e2                	shl    %cl,%edx
  800fee:	89 f1                	mov    %esi,%ecx
  800ff0:	d3 e8                	shr    %cl,%eax
  800ff2:	89 e9                	mov    %ebp,%ecx
  800ff4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800ff8:	8b 04 24             	mov    (%esp),%eax
  800ffb:	09 54 24 04          	or     %edx,0x4(%esp)
  800fff:	89 fa                	mov    %edi,%edx
  801001:	d3 e0                	shl    %cl,%eax
  801003:	89 f1                	mov    %esi,%ecx
  801005:	89 44 24 08          	mov    %eax,0x8(%esp)
  801009:	8b 44 24 10          	mov    0x10(%esp),%eax
  80100d:	d3 ea                	shr    %cl,%edx
  80100f:	89 e9                	mov    %ebp,%ecx
  801011:	d3 e7                	shl    %cl,%edi
  801013:	89 f1                	mov    %esi,%ecx
  801015:	d3 e8                	shr    %cl,%eax
  801017:	89 e9                	mov    %ebp,%ecx
  801019:	09 f8                	or     %edi,%eax
  80101b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  80101f:	f7 74 24 04          	divl   0x4(%esp)
  801023:	d3 e7                	shl    %cl,%edi
  801025:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801029:	89 d7                	mov    %edx,%edi
  80102b:	f7 64 24 08          	mull   0x8(%esp)
  80102f:	39 d7                	cmp    %edx,%edi
  801031:	89 c1                	mov    %eax,%ecx
  801033:	89 14 24             	mov    %edx,(%esp)
  801036:	72 2c                	jb     801064 <__umoddi3+0x134>
  801038:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  80103c:	72 22                	jb     801060 <__umoddi3+0x130>
  80103e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801042:	29 c8                	sub    %ecx,%eax
  801044:	19 d7                	sbb    %edx,%edi
  801046:	89 e9                	mov    %ebp,%ecx
  801048:	89 fa                	mov    %edi,%edx
  80104a:	d3 e8                	shr    %cl,%eax
  80104c:	89 f1                	mov    %esi,%ecx
  80104e:	d3 e2                	shl    %cl,%edx
  801050:	89 e9                	mov    %ebp,%ecx
  801052:	d3 ef                	shr    %cl,%edi
  801054:	09 d0                	or     %edx,%eax
  801056:	89 fa                	mov    %edi,%edx
  801058:	83 c4 14             	add    $0x14,%esp
  80105b:	5e                   	pop    %esi
  80105c:	5f                   	pop    %edi
  80105d:	5d                   	pop    %ebp
  80105e:	c3                   	ret    
  80105f:	90                   	nop
  801060:	39 d7                	cmp    %edx,%edi
  801062:	75 da                	jne    80103e <__umoddi3+0x10e>
  801064:	8b 14 24             	mov    (%esp),%edx
  801067:	89 c1                	mov    %eax,%ecx
  801069:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  80106d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  801071:	eb cb                	jmp    80103e <__umoddi3+0x10e>
  801073:	90                   	nop
  801074:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801078:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  80107c:	0f 82 0f ff ff ff    	jb     800f91 <__umoddi3+0x61>
  801082:	e9 1a ff ff ff       	jmp    800fa1 <__umoddi3+0x71>
