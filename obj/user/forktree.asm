
obj/user/forktree:     file format elf32-i386


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
  80002c:	e8 c2 00 00 00       	call   8000f3 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <forktree>:
	}
}

void
forktree(const char *cur)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	53                   	push   %ebx
  800037:	83 ec 14             	sub    $0x14,%esp
  80003a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("%04x: I am '%s'\n", sys_getenvid(), cur);
  80003d:	e8 b3 0b 00 00       	call   800bf5 <sys_getenvid>
  800042:	89 5c 24 08          	mov    %ebx,0x8(%esp)
  800046:	89 44 24 04          	mov    %eax,0x4(%esp)
  80004a:	c7 04 24 80 11 80 00 	movl   $0x801180,(%esp)
  800051:	e8 9c 01 00 00       	call   8001f2 <cprintf>

	forkchild(cur, '0');
  800056:	c7 44 24 04 30 00 00 	movl   $0x30,0x4(%esp)
  80005d:	00 
  80005e:	89 1c 24             	mov    %ebx,(%esp)
  800061:	e8 16 00 00 00       	call   80007c <forkchild>
	forkchild(cur, '1');
  800066:	c7 44 24 04 31 00 00 	movl   $0x31,0x4(%esp)
  80006d:	00 
  80006e:	89 1c 24             	mov    %ebx,(%esp)
  800071:	e8 06 00 00 00       	call   80007c <forkchild>
}
  800076:	83 c4 14             	add    $0x14,%esp
  800079:	5b                   	pop    %ebx
  80007a:	5d                   	pop    %ebp
  80007b:	c3                   	ret    

0080007c <forkchild>:

void forktree(const char *cur);

void
forkchild(const char *cur, char branch)
{
  80007c:	55                   	push   %ebp
  80007d:	89 e5                	mov    %esp,%ebp
  80007f:	56                   	push   %esi
  800080:	53                   	push   %ebx
  800081:	83 ec 30             	sub    $0x30,%esp
  800084:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800087:	8b 75 0c             	mov    0xc(%ebp),%esi
	char nxt[DEPTH+1];

	if (strlen(cur) >= DEPTH)
  80008a:	89 1c 24             	mov    %ebx,(%esp)
  80008d:	e8 4e 07 00 00       	call   8007e0 <strlen>
  800092:	83 f8 02             	cmp    $0x2,%eax
  800095:	7f 41                	jg     8000d8 <forkchild+0x5c>
		return;

	snprintf(nxt, DEPTH+1, "%s%c", cur, branch);
  800097:	89 f0                	mov    %esi,%eax
  800099:	0f be f0             	movsbl %al,%esi
  80009c:	89 74 24 10          	mov    %esi,0x10(%esp)
  8000a0:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
  8000a4:	c7 44 24 08 91 11 80 	movl   $0x801191,0x8(%esp)
  8000ab:	00 
  8000ac:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
  8000b3:	00 
  8000b4:	8d 45 f4             	lea    -0xc(%ebp),%eax
  8000b7:	89 04 24             	mov    %eax,(%esp)
  8000ba:	e8 eb 06 00 00       	call   8007aa <snprintf>
	if (fork() == 0) {
  8000bf:	e8 84 0d 00 00       	call   800e48 <fork>
  8000c4:	85 c0                	test   %eax,%eax
  8000c6:	75 10                	jne    8000d8 <forkchild+0x5c>
		forktree(nxt);
  8000c8:	8d 45 f4             	lea    -0xc(%ebp),%eax
  8000cb:	89 04 24             	mov    %eax,(%esp)
  8000ce:	e8 60 ff ff ff       	call   800033 <forktree>
		exit();
  8000d3:	e8 63 00 00 00       	call   80013b <exit>
	}
}
  8000d8:	83 c4 30             	add    $0x30,%esp
  8000db:	5b                   	pop    %ebx
  8000dc:	5e                   	pop    %esi
  8000dd:	5d                   	pop    %ebp
  8000de:	c3                   	ret    

008000df <umain>:
	forkchild(cur, '1');
}

void
umain(int argc, char **argv)
{
  8000df:	55                   	push   %ebp
  8000e0:	89 e5                	mov    %esp,%ebp
  8000e2:	83 ec 18             	sub    $0x18,%esp
	forktree("");
  8000e5:	c7 04 24 90 11 80 00 	movl   $0x801190,(%esp)
  8000ec:	e8 42 ff ff ff       	call   800033 <forktree>
}
  8000f1:	c9                   	leave  
  8000f2:	c3                   	ret    

008000f3 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  8000f3:	55                   	push   %ebp
  8000f4:	89 e5                	mov    %esp,%ebp
  8000f6:	56                   	push   %esi
  8000f7:	53                   	push   %ebx
  8000f8:	83 ec 10             	sub    $0x10,%esp
  8000fb:	8b 5d 08             	mov    0x8(%ebp),%ebx
  8000fe:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	
	thisenv = (struct Env *) envs + ENVX(sys_getenvid());
  800101:	e8 ef 0a 00 00       	call   800bf5 <sys_getenvid>
  800106:	25 ff 03 00 00       	and    $0x3ff,%eax
  80010b:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80010e:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800113:	a3 04 20 80 00       	mov    %eax,0x802004
	//UENVS array
	//thisenv->env_link
	//thisenv = 0;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800118:	85 db                	test   %ebx,%ebx
  80011a:	7e 07                	jle    800123 <libmain+0x30>
		binaryname = argv[0];
  80011c:	8b 06                	mov    (%esi),%eax
  80011e:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800123:	89 74 24 04          	mov    %esi,0x4(%esp)
  800127:	89 1c 24             	mov    %ebx,(%esp)
  80012a:	e8 b0 ff ff ff       	call   8000df <umain>

	// exit gracefully
	exit();
  80012f:	e8 07 00 00 00       	call   80013b <exit>
}
  800134:	83 c4 10             	add    $0x10,%esp
  800137:	5b                   	pop    %ebx
  800138:	5e                   	pop    %esi
  800139:	5d                   	pop    %ebp
  80013a:	c3                   	ret    

0080013b <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80013b:	55                   	push   %ebp
  80013c:	89 e5                	mov    %esp,%ebp
  80013e:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800141:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800148:	e8 56 0a 00 00       	call   800ba3 <sys_env_destroy>
}
  80014d:	c9                   	leave  
  80014e:	c3                   	ret    

0080014f <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80014f:	55                   	push   %ebp
  800150:	89 e5                	mov    %esp,%ebp
  800152:	53                   	push   %ebx
  800153:	83 ec 14             	sub    $0x14,%esp
  800156:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  800159:	8b 13                	mov    (%ebx),%edx
  80015b:	8d 42 01             	lea    0x1(%edx),%eax
  80015e:	89 03                	mov    %eax,(%ebx)
  800160:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800163:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800167:	3d ff 00 00 00       	cmp    $0xff,%eax
  80016c:	75 19                	jne    800187 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  80016e:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800175:	00 
  800176:	8d 43 08             	lea    0x8(%ebx),%eax
  800179:	89 04 24             	mov    %eax,(%esp)
  80017c:	e8 e5 09 00 00       	call   800b66 <sys_cputs>
		b->idx = 0;
  800181:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800187:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80018b:	83 c4 14             	add    $0x14,%esp
  80018e:	5b                   	pop    %ebx
  80018f:	5d                   	pop    %ebp
  800190:	c3                   	ret    

00800191 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800191:	55                   	push   %ebp
  800192:	89 e5                	mov    %esp,%ebp
  800194:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80019a:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001a1:	00 00 00 
	b.cnt = 0;
  8001a4:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001ab:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001ae:	8b 45 0c             	mov    0xc(%ebp),%eax
  8001b1:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8001b5:	8b 45 08             	mov    0x8(%ebp),%eax
  8001b8:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001bc:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  8001c2:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001c6:	c7 04 24 4f 01 80 00 	movl   $0x80014f,(%esp)
  8001cd:	e8 ac 01 00 00       	call   80037e <vprintfmt>
	sys_cputs(b.buf, b.idx);
  8001d2:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  8001d8:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001dc:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  8001e2:	89 04 24             	mov    %eax,(%esp)
  8001e5:	e8 7c 09 00 00       	call   800b66 <sys_cputs>

	return b.cnt;
}
  8001ea:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8001f0:	c9                   	leave  
  8001f1:	c3                   	ret    

008001f2 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8001f2:	55                   	push   %ebp
  8001f3:	89 e5                	mov    %esp,%ebp
  8001f5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8001f8:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8001fb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001ff:	8b 45 08             	mov    0x8(%ebp),%eax
  800202:	89 04 24             	mov    %eax,(%esp)
  800205:	e8 87 ff ff ff       	call   800191 <vcprintf>
	va_end(ap);

	return cnt;
}
  80020a:	c9                   	leave  
  80020b:	c3                   	ret    
  80020c:	66 90                	xchg   %ax,%ax
  80020e:	66 90                	xchg   %ax,%ax

00800210 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800210:	55                   	push   %ebp
  800211:	89 e5                	mov    %esp,%ebp
  800213:	57                   	push   %edi
  800214:	56                   	push   %esi
  800215:	53                   	push   %ebx
  800216:	83 ec 3c             	sub    $0x3c,%esp
  800219:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80021c:	89 d7                	mov    %edx,%edi
  80021e:	8b 45 08             	mov    0x8(%ebp),%eax
  800221:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800224:	8b 45 0c             	mov    0xc(%ebp),%eax
  800227:	89 c3                	mov    %eax,%ebx
  800229:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80022c:	8b 45 10             	mov    0x10(%ebp),%eax
  80022f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800232:	b9 00 00 00 00       	mov    $0x0,%ecx
  800237:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80023a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80023d:	39 d9                	cmp    %ebx,%ecx
  80023f:	72 05                	jb     800246 <printnum+0x36>
  800241:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800244:	77 69                	ja     8002af <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800246:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800249:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80024d:	83 ee 01             	sub    $0x1,%esi
  800250:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800254:	89 44 24 08          	mov    %eax,0x8(%esp)
  800258:	8b 44 24 08          	mov    0x8(%esp),%eax
  80025c:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800260:	89 c3                	mov    %eax,%ebx
  800262:	89 d6                	mov    %edx,%esi
  800264:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800267:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80026a:	89 54 24 08          	mov    %edx,0x8(%esp)
  80026e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800272:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800275:	89 04 24             	mov    %eax,(%esp)
  800278:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80027b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80027f:	e8 6c 0c 00 00       	call   800ef0 <__udivdi3>
  800284:	89 d9                	mov    %ebx,%ecx
  800286:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80028a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80028e:	89 04 24             	mov    %eax,(%esp)
  800291:	89 54 24 04          	mov    %edx,0x4(%esp)
  800295:	89 fa                	mov    %edi,%edx
  800297:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80029a:	e8 71 ff ff ff       	call   800210 <printnum>
  80029f:	eb 1b                	jmp    8002bc <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002a1:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002a5:	8b 45 18             	mov    0x18(%ebp),%eax
  8002a8:	89 04 24             	mov    %eax,(%esp)
  8002ab:	ff d3                	call   *%ebx
  8002ad:	eb 03                	jmp    8002b2 <printnum+0xa2>
  8002af:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  8002b2:	83 ee 01             	sub    $0x1,%esi
  8002b5:	85 f6                	test   %esi,%esi
  8002b7:	7f e8                	jg     8002a1 <printnum+0x91>
  8002b9:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  8002bc:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002c0:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8002c4:	8b 45 d8             	mov    -0x28(%ebp),%eax
  8002c7:	8b 55 dc             	mov    -0x24(%ebp),%edx
  8002ca:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002ce:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8002d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002d5:	89 04 24             	mov    %eax,(%esp)
  8002d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8002db:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002df:	e8 3c 0d 00 00       	call   801020 <__umoddi3>
  8002e4:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002e8:	0f be 80 a0 11 80 00 	movsbl 0x8011a0(%eax),%eax
  8002ef:	89 04 24             	mov    %eax,(%esp)
  8002f2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8002f5:	ff d0                	call   *%eax
}
  8002f7:	83 c4 3c             	add    $0x3c,%esp
  8002fa:	5b                   	pop    %ebx
  8002fb:	5e                   	pop    %esi
  8002fc:	5f                   	pop    %edi
  8002fd:	5d                   	pop    %ebp
  8002fe:	c3                   	ret    

008002ff <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8002ff:	55                   	push   %ebp
  800300:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800302:	83 fa 01             	cmp    $0x1,%edx
  800305:	7e 0e                	jle    800315 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800307:	8b 10                	mov    (%eax),%edx
  800309:	8d 4a 08             	lea    0x8(%edx),%ecx
  80030c:	89 08                	mov    %ecx,(%eax)
  80030e:	8b 02                	mov    (%edx),%eax
  800310:	8b 52 04             	mov    0x4(%edx),%edx
  800313:	eb 22                	jmp    800337 <getuint+0x38>
	else if (lflag)
  800315:	85 d2                	test   %edx,%edx
  800317:	74 10                	je     800329 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800319:	8b 10                	mov    (%eax),%edx
  80031b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80031e:	89 08                	mov    %ecx,(%eax)
  800320:	8b 02                	mov    (%edx),%eax
  800322:	ba 00 00 00 00       	mov    $0x0,%edx
  800327:	eb 0e                	jmp    800337 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800329:	8b 10                	mov    (%eax),%edx
  80032b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80032e:	89 08                	mov    %ecx,(%eax)
  800330:	8b 02                	mov    (%edx),%eax
  800332:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800337:	5d                   	pop    %ebp
  800338:	c3                   	ret    

00800339 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800339:	55                   	push   %ebp
  80033a:	89 e5                	mov    %esp,%ebp
  80033c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80033f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800343:	8b 10                	mov    (%eax),%edx
  800345:	3b 50 04             	cmp    0x4(%eax),%edx
  800348:	73 0a                	jae    800354 <sprintputch+0x1b>
		*b->buf++ = ch;
  80034a:	8d 4a 01             	lea    0x1(%edx),%ecx
  80034d:	89 08                	mov    %ecx,(%eax)
  80034f:	8b 45 08             	mov    0x8(%ebp),%eax
  800352:	88 02                	mov    %al,(%edx)
}
  800354:	5d                   	pop    %ebp
  800355:	c3                   	ret    

00800356 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800356:	55                   	push   %ebp
  800357:	89 e5                	mov    %esp,%ebp
  800359:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  80035c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80035f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800363:	8b 45 10             	mov    0x10(%ebp),%eax
  800366:	89 44 24 08          	mov    %eax,0x8(%esp)
  80036a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80036d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800371:	8b 45 08             	mov    0x8(%ebp),%eax
  800374:	89 04 24             	mov    %eax,(%esp)
  800377:	e8 02 00 00 00       	call   80037e <vprintfmt>
	va_end(ap);
}
  80037c:	c9                   	leave  
  80037d:	c3                   	ret    

0080037e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80037e:	55                   	push   %ebp
  80037f:	89 e5                	mov    %esp,%ebp
  800381:	57                   	push   %edi
  800382:	56                   	push   %esi
  800383:	53                   	push   %ebx
  800384:	83 ec 3c             	sub    $0x3c,%esp
  800387:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80038a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80038d:	eb 14                	jmp    8003a3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80038f:	85 c0                	test   %eax,%eax
  800391:	0f 84 b3 03 00 00    	je     80074a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  800397:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80039b:	89 04 24             	mov    %eax,(%esp)
  80039e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  8003a1:	89 f3                	mov    %esi,%ebx
  8003a3:	8d 73 01             	lea    0x1(%ebx),%esi
  8003a6:	0f b6 03             	movzbl (%ebx),%eax
  8003a9:	83 f8 25             	cmp    $0x25,%eax
  8003ac:	75 e1                	jne    80038f <vprintfmt+0x11>
  8003ae:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  8003b2:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  8003b9:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  8003c0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  8003c7:	ba 00 00 00 00       	mov    $0x0,%edx
  8003cc:	eb 1d                	jmp    8003eb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003ce:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  8003d0:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  8003d4:	eb 15                	jmp    8003eb <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003d6:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  8003d8:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  8003dc:	eb 0d                	jmp    8003eb <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  8003de:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8003e1:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8003e4:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8003eb:	8d 5e 01             	lea    0x1(%esi),%ebx
  8003ee:	0f b6 0e             	movzbl (%esi),%ecx
  8003f1:	0f b6 c1             	movzbl %cl,%eax
  8003f4:	83 e9 23             	sub    $0x23,%ecx
  8003f7:	80 f9 55             	cmp    $0x55,%cl
  8003fa:	0f 87 2a 03 00 00    	ja     80072a <vprintfmt+0x3ac>
  800400:	0f b6 c9             	movzbl %cl,%ecx
  800403:	ff 24 8d 60 12 80 00 	jmp    *0x801260(,%ecx,4)
  80040a:	89 de                	mov    %ebx,%esi
  80040c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800411:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  800414:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  800418:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  80041b:	8d 58 d0             	lea    -0x30(%eax),%ebx
  80041e:	83 fb 09             	cmp    $0x9,%ebx
  800421:	77 36                	ja     800459 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  800423:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  800426:	eb e9                	jmp    800411 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  800428:	8b 45 14             	mov    0x14(%ebp),%eax
  80042b:	8d 48 04             	lea    0x4(%eax),%ecx
  80042e:	89 4d 14             	mov    %ecx,0x14(%ebp)
  800431:	8b 00                	mov    (%eax),%eax
  800433:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800436:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  800438:	eb 22                	jmp    80045c <vprintfmt+0xde>
  80043a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80043d:	85 c9                	test   %ecx,%ecx
  80043f:	b8 00 00 00 00       	mov    $0x0,%eax
  800444:	0f 49 c1             	cmovns %ecx,%eax
  800447:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80044a:	89 de                	mov    %ebx,%esi
  80044c:	eb 9d                	jmp    8003eb <vprintfmt+0x6d>
  80044e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800450:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  800457:	eb 92                	jmp    8003eb <vprintfmt+0x6d>
  800459:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  80045c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800460:	79 89                	jns    8003eb <vprintfmt+0x6d>
  800462:	e9 77 ff ff ff       	jmp    8003de <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800467:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80046a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80046c:	e9 7a ff ff ff       	jmp    8003eb <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800471:	8b 45 14             	mov    0x14(%ebp),%eax
  800474:	8d 50 04             	lea    0x4(%eax),%edx
  800477:	89 55 14             	mov    %edx,0x14(%ebp)
  80047a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80047e:	8b 00                	mov    (%eax),%eax
  800480:	89 04 24             	mov    %eax,(%esp)
  800483:	ff 55 08             	call   *0x8(%ebp)
			break;
  800486:	e9 18 ff ff ff       	jmp    8003a3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80048b:	8b 45 14             	mov    0x14(%ebp),%eax
  80048e:	8d 50 04             	lea    0x4(%eax),%edx
  800491:	89 55 14             	mov    %edx,0x14(%ebp)
  800494:	8b 00                	mov    (%eax),%eax
  800496:	99                   	cltd   
  800497:	31 d0                	xor    %edx,%eax
  800499:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80049b:	83 f8 09             	cmp    $0x9,%eax
  80049e:	7f 0b                	jg     8004ab <vprintfmt+0x12d>
  8004a0:	8b 14 85 c0 13 80 00 	mov    0x8013c0(,%eax,4),%edx
  8004a7:	85 d2                	test   %edx,%edx
  8004a9:	75 20                	jne    8004cb <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  8004ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8004af:	c7 44 24 08 b8 11 80 	movl   $0x8011b8,0x8(%esp)
  8004b6:	00 
  8004b7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004bb:	8b 45 08             	mov    0x8(%ebp),%eax
  8004be:	89 04 24             	mov    %eax,(%esp)
  8004c1:	e8 90 fe ff ff       	call   800356 <printfmt>
  8004c6:	e9 d8 fe ff ff       	jmp    8003a3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  8004cb:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8004cf:	c7 44 24 08 c1 11 80 	movl   $0x8011c1,0x8(%esp)
  8004d6:	00 
  8004d7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004db:	8b 45 08             	mov    0x8(%ebp),%eax
  8004de:	89 04 24             	mov    %eax,(%esp)
  8004e1:	e8 70 fe ff ff       	call   800356 <printfmt>
  8004e6:	e9 b8 fe ff ff       	jmp    8003a3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8004eb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  8004ee:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8004f1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8004f4:	8b 45 14             	mov    0x14(%ebp),%eax
  8004f7:	8d 50 04             	lea    0x4(%eax),%edx
  8004fa:	89 55 14             	mov    %edx,0x14(%ebp)
  8004fd:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  8004ff:	85 f6                	test   %esi,%esi
  800501:	b8 b1 11 80 00       	mov    $0x8011b1,%eax
  800506:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  800509:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  80050d:	0f 84 97 00 00 00    	je     8005aa <vprintfmt+0x22c>
  800513:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800517:	0f 8e 9b 00 00 00    	jle    8005b8 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  80051d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800521:	89 34 24             	mov    %esi,(%esp)
  800524:	e8 cf 02 00 00       	call   8007f8 <strnlen>
  800529:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80052c:	29 c2                	sub    %eax,%edx
  80052e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  800531:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  800535:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800538:	89 75 d8             	mov    %esi,-0x28(%ebp)
  80053b:	8b 75 08             	mov    0x8(%ebp),%esi
  80053e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800541:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800543:	eb 0f                	jmp    800554 <vprintfmt+0x1d6>
					putch(padc, putdat);
  800545:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800549:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80054c:	89 04 24             	mov    %eax,(%esp)
  80054f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800551:	83 eb 01             	sub    $0x1,%ebx
  800554:	85 db                	test   %ebx,%ebx
  800556:	7f ed                	jg     800545 <vprintfmt+0x1c7>
  800558:	8b 75 d8             	mov    -0x28(%ebp),%esi
  80055b:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80055e:	85 d2                	test   %edx,%edx
  800560:	b8 00 00 00 00       	mov    $0x0,%eax
  800565:	0f 49 c2             	cmovns %edx,%eax
  800568:	29 c2                	sub    %eax,%edx
  80056a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80056d:	89 d7                	mov    %edx,%edi
  80056f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800572:	eb 50                	jmp    8005c4 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800574:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800578:	74 1e                	je     800598 <vprintfmt+0x21a>
  80057a:	0f be d2             	movsbl %dl,%edx
  80057d:	83 ea 20             	sub    $0x20,%edx
  800580:	83 fa 5e             	cmp    $0x5e,%edx
  800583:	76 13                	jbe    800598 <vprintfmt+0x21a>
					putch('?', putdat);
  800585:	8b 45 0c             	mov    0xc(%ebp),%eax
  800588:	89 44 24 04          	mov    %eax,0x4(%esp)
  80058c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800593:	ff 55 08             	call   *0x8(%ebp)
  800596:	eb 0d                	jmp    8005a5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  800598:	8b 55 0c             	mov    0xc(%ebp),%edx
  80059b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80059f:	89 04 24             	mov    %eax,(%esp)
  8005a2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005a5:	83 ef 01             	sub    $0x1,%edi
  8005a8:	eb 1a                	jmp    8005c4 <vprintfmt+0x246>
  8005aa:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8005ad:	8b 7d dc             	mov    -0x24(%ebp),%edi
  8005b0:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8005b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8005b6:	eb 0c                	jmp    8005c4 <vprintfmt+0x246>
  8005b8:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8005bb:	8b 7d dc             	mov    -0x24(%ebp),%edi
  8005be:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8005c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8005c4:	83 c6 01             	add    $0x1,%esi
  8005c7:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  8005cb:	0f be c2             	movsbl %dl,%eax
  8005ce:	85 c0                	test   %eax,%eax
  8005d0:	74 27                	je     8005f9 <vprintfmt+0x27b>
  8005d2:	85 db                	test   %ebx,%ebx
  8005d4:	78 9e                	js     800574 <vprintfmt+0x1f6>
  8005d6:	83 eb 01             	sub    $0x1,%ebx
  8005d9:	79 99                	jns    800574 <vprintfmt+0x1f6>
  8005db:	89 f8                	mov    %edi,%eax
  8005dd:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8005e0:	8b 75 08             	mov    0x8(%ebp),%esi
  8005e3:	89 c3                	mov    %eax,%ebx
  8005e5:	eb 1a                	jmp    800601 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  8005e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005eb:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8005f2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8005f4:	83 eb 01             	sub    $0x1,%ebx
  8005f7:	eb 08                	jmp    800601 <vprintfmt+0x283>
  8005f9:	89 fb                	mov    %edi,%ebx
  8005fb:	8b 75 08             	mov    0x8(%ebp),%esi
  8005fe:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800601:	85 db                	test   %ebx,%ebx
  800603:	7f e2                	jg     8005e7 <vprintfmt+0x269>
  800605:	89 75 08             	mov    %esi,0x8(%ebp)
  800608:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80060b:	e9 93 fd ff ff       	jmp    8003a3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800610:	83 fa 01             	cmp    $0x1,%edx
  800613:	7e 16                	jle    80062b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  800615:	8b 45 14             	mov    0x14(%ebp),%eax
  800618:	8d 50 08             	lea    0x8(%eax),%edx
  80061b:	89 55 14             	mov    %edx,0x14(%ebp)
  80061e:	8b 50 04             	mov    0x4(%eax),%edx
  800621:	8b 00                	mov    (%eax),%eax
  800623:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800626:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800629:	eb 32                	jmp    80065d <vprintfmt+0x2df>
	else if (lflag)
  80062b:	85 d2                	test   %edx,%edx
  80062d:	74 18                	je     800647 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  80062f:	8b 45 14             	mov    0x14(%ebp),%eax
  800632:	8d 50 04             	lea    0x4(%eax),%edx
  800635:	89 55 14             	mov    %edx,0x14(%ebp)
  800638:	8b 30                	mov    (%eax),%esi
  80063a:	89 75 e0             	mov    %esi,-0x20(%ebp)
  80063d:	89 f0                	mov    %esi,%eax
  80063f:	c1 f8 1f             	sar    $0x1f,%eax
  800642:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800645:	eb 16                	jmp    80065d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  800647:	8b 45 14             	mov    0x14(%ebp),%eax
  80064a:	8d 50 04             	lea    0x4(%eax),%edx
  80064d:	89 55 14             	mov    %edx,0x14(%ebp)
  800650:	8b 30                	mov    (%eax),%esi
  800652:	89 75 e0             	mov    %esi,-0x20(%ebp)
  800655:	89 f0                	mov    %esi,%eax
  800657:	c1 f8 1f             	sar    $0x1f,%eax
  80065a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80065d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800660:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800663:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800668:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  80066c:	0f 89 80 00 00 00    	jns    8006f2 <vprintfmt+0x374>
				putch('-', putdat);
  800672:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800676:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  80067d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  800680:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800683:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800686:	f7 d8                	neg    %eax
  800688:	83 d2 00             	adc    $0x0,%edx
  80068b:	f7 da                	neg    %edx
			}
			base = 10;
  80068d:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800692:	eb 5e                	jmp    8006f2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800694:	8d 45 14             	lea    0x14(%ebp),%eax
  800697:	e8 63 fc ff ff       	call   8002ff <getuint>
			base = 10;
  80069c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8006a1:	eb 4f                	jmp    8006f2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  8006a3:	8d 45 14             	lea    0x14(%ebp),%eax
  8006a6:	e8 54 fc ff ff       	call   8002ff <getuint>
			base = 8;
  8006ab:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  8006b0:	eb 40                	jmp    8006f2 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
  8006b2:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006b6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8006bd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  8006c0:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006c4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  8006cb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  8006ce:	8b 45 14             	mov    0x14(%ebp),%eax
  8006d1:	8d 50 04             	lea    0x4(%eax),%edx
  8006d4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  8006d7:	8b 00                	mov    (%eax),%eax
  8006d9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  8006de:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  8006e3:	eb 0d                	jmp    8006f2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  8006e5:	8d 45 14             	lea    0x14(%ebp),%eax
  8006e8:	e8 12 fc ff ff       	call   8002ff <getuint>
			base = 16;
  8006ed:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8006f2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  8006f6:	89 74 24 10          	mov    %esi,0x10(%esp)
  8006fa:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8006fd:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800701:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800705:	89 04 24             	mov    %eax,(%esp)
  800708:	89 54 24 04          	mov    %edx,0x4(%esp)
  80070c:	89 fa                	mov    %edi,%edx
  80070e:	8b 45 08             	mov    0x8(%ebp),%eax
  800711:	e8 fa fa ff ff       	call   800210 <printnum>
			break;
  800716:	e9 88 fc ff ff       	jmp    8003a3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80071b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80071f:	89 04 24             	mov    %eax,(%esp)
  800722:	ff 55 08             	call   *0x8(%ebp)
			break;
  800725:	e9 79 fc ff ff       	jmp    8003a3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80072a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80072e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800735:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  800738:	89 f3                	mov    %esi,%ebx
  80073a:	eb 03                	jmp    80073f <vprintfmt+0x3c1>
  80073c:	83 eb 01             	sub    $0x1,%ebx
  80073f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  800743:	75 f7                	jne    80073c <vprintfmt+0x3be>
  800745:	e9 59 fc ff ff       	jmp    8003a3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  80074a:	83 c4 3c             	add    $0x3c,%esp
  80074d:	5b                   	pop    %ebx
  80074e:	5e                   	pop    %esi
  80074f:	5f                   	pop    %edi
  800750:	5d                   	pop    %ebp
  800751:	c3                   	ret    

00800752 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800752:	55                   	push   %ebp
  800753:	89 e5                	mov    %esp,%ebp
  800755:	83 ec 28             	sub    $0x28,%esp
  800758:	8b 45 08             	mov    0x8(%ebp),%eax
  80075b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80075e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800761:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800765:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800768:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80076f:	85 c0                	test   %eax,%eax
  800771:	74 30                	je     8007a3 <vsnprintf+0x51>
  800773:	85 d2                	test   %edx,%edx
  800775:	7e 2c                	jle    8007a3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800777:	8b 45 14             	mov    0x14(%ebp),%eax
  80077a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80077e:	8b 45 10             	mov    0x10(%ebp),%eax
  800781:	89 44 24 08          	mov    %eax,0x8(%esp)
  800785:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800788:	89 44 24 04          	mov    %eax,0x4(%esp)
  80078c:	c7 04 24 39 03 80 00 	movl   $0x800339,(%esp)
  800793:	e8 e6 fb ff ff       	call   80037e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800798:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80079b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80079e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  8007a1:	eb 05                	jmp    8007a8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  8007a3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  8007a8:	c9                   	leave  
  8007a9:	c3                   	ret    

008007aa <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  8007aa:	55                   	push   %ebp
  8007ab:	89 e5                	mov    %esp,%ebp
  8007ad:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  8007b0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  8007b3:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007b7:	8b 45 10             	mov    0x10(%ebp),%eax
  8007ba:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007be:	8b 45 0c             	mov    0xc(%ebp),%eax
  8007c1:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007c5:	8b 45 08             	mov    0x8(%ebp),%eax
  8007c8:	89 04 24             	mov    %eax,(%esp)
  8007cb:	e8 82 ff ff ff       	call   800752 <vsnprintf>
	va_end(ap);

	return rc;
}
  8007d0:	c9                   	leave  
  8007d1:	c3                   	ret    
  8007d2:	66 90                	xchg   %ax,%ax
  8007d4:	66 90                	xchg   %ax,%ax
  8007d6:	66 90                	xchg   %ax,%ax
  8007d8:	66 90                	xchg   %ax,%ax
  8007da:	66 90                	xchg   %ax,%ax
  8007dc:	66 90                	xchg   %ax,%ax
  8007de:	66 90                	xchg   %ax,%ax

008007e0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  8007e0:	55                   	push   %ebp
  8007e1:	89 e5                	mov    %esp,%ebp
  8007e3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  8007e6:	b8 00 00 00 00       	mov    $0x0,%eax
  8007eb:	eb 03                	jmp    8007f0 <strlen+0x10>
		n++;
  8007ed:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8007f0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8007f4:	75 f7                	jne    8007ed <strlen+0xd>
		n++;
	return n;
}
  8007f6:	5d                   	pop    %ebp
  8007f7:	c3                   	ret    

008007f8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8007f8:	55                   	push   %ebp
  8007f9:	89 e5                	mov    %esp,%ebp
  8007fb:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8007fe:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800801:	b8 00 00 00 00       	mov    $0x0,%eax
  800806:	eb 03                	jmp    80080b <strnlen+0x13>
		n++;
  800808:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80080b:	39 d0                	cmp    %edx,%eax
  80080d:	74 06                	je     800815 <strnlen+0x1d>
  80080f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800813:	75 f3                	jne    800808 <strnlen+0x10>
		n++;
	return n;
}
  800815:	5d                   	pop    %ebp
  800816:	c3                   	ret    

00800817 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800817:	55                   	push   %ebp
  800818:	89 e5                	mov    %esp,%ebp
  80081a:	53                   	push   %ebx
  80081b:	8b 45 08             	mov    0x8(%ebp),%eax
  80081e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800821:	89 c2                	mov    %eax,%edx
  800823:	83 c2 01             	add    $0x1,%edx
  800826:	83 c1 01             	add    $0x1,%ecx
  800829:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80082d:	88 5a ff             	mov    %bl,-0x1(%edx)
  800830:	84 db                	test   %bl,%bl
  800832:	75 ef                	jne    800823 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800834:	5b                   	pop    %ebx
  800835:	5d                   	pop    %ebp
  800836:	c3                   	ret    

00800837 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800837:	55                   	push   %ebp
  800838:	89 e5                	mov    %esp,%ebp
  80083a:	53                   	push   %ebx
  80083b:	83 ec 08             	sub    $0x8,%esp
  80083e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800841:	89 1c 24             	mov    %ebx,(%esp)
  800844:	e8 97 ff ff ff       	call   8007e0 <strlen>
	strcpy(dst + len, src);
  800849:	8b 55 0c             	mov    0xc(%ebp),%edx
  80084c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800850:	01 d8                	add    %ebx,%eax
  800852:	89 04 24             	mov    %eax,(%esp)
  800855:	e8 bd ff ff ff       	call   800817 <strcpy>
	return dst;
}
  80085a:	89 d8                	mov    %ebx,%eax
  80085c:	83 c4 08             	add    $0x8,%esp
  80085f:	5b                   	pop    %ebx
  800860:	5d                   	pop    %ebp
  800861:	c3                   	ret    

00800862 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800862:	55                   	push   %ebp
  800863:	89 e5                	mov    %esp,%ebp
  800865:	56                   	push   %esi
  800866:	53                   	push   %ebx
  800867:	8b 75 08             	mov    0x8(%ebp),%esi
  80086a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  80086d:	89 f3                	mov    %esi,%ebx
  80086f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800872:	89 f2                	mov    %esi,%edx
  800874:	eb 0f                	jmp    800885 <strncpy+0x23>
		*dst++ = *src;
  800876:	83 c2 01             	add    $0x1,%edx
  800879:	0f b6 01             	movzbl (%ecx),%eax
  80087c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  80087f:	80 39 01             	cmpb   $0x1,(%ecx)
  800882:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800885:	39 da                	cmp    %ebx,%edx
  800887:	75 ed                	jne    800876 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800889:	89 f0                	mov    %esi,%eax
  80088b:	5b                   	pop    %ebx
  80088c:	5e                   	pop    %esi
  80088d:	5d                   	pop    %ebp
  80088e:	c3                   	ret    

0080088f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80088f:	55                   	push   %ebp
  800890:	89 e5                	mov    %esp,%ebp
  800892:	56                   	push   %esi
  800893:	53                   	push   %ebx
  800894:	8b 75 08             	mov    0x8(%ebp),%esi
  800897:	8b 55 0c             	mov    0xc(%ebp),%edx
  80089a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80089d:	89 f0                	mov    %esi,%eax
  80089f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  8008a3:	85 c9                	test   %ecx,%ecx
  8008a5:	75 0b                	jne    8008b2 <strlcpy+0x23>
  8008a7:	eb 1d                	jmp    8008c6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  8008a9:	83 c0 01             	add    $0x1,%eax
  8008ac:	83 c2 01             	add    $0x1,%edx
  8008af:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  8008b2:	39 d8                	cmp    %ebx,%eax
  8008b4:	74 0b                	je     8008c1 <strlcpy+0x32>
  8008b6:	0f b6 0a             	movzbl (%edx),%ecx
  8008b9:	84 c9                	test   %cl,%cl
  8008bb:	75 ec                	jne    8008a9 <strlcpy+0x1a>
  8008bd:	89 c2                	mov    %eax,%edx
  8008bf:	eb 02                	jmp    8008c3 <strlcpy+0x34>
  8008c1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  8008c3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  8008c6:	29 f0                	sub    %esi,%eax
}
  8008c8:	5b                   	pop    %ebx
  8008c9:	5e                   	pop    %esi
  8008ca:	5d                   	pop    %ebp
  8008cb:	c3                   	ret    

008008cc <strcmp>:

int
strcmp(const char *p, const char *q)
{
  8008cc:	55                   	push   %ebp
  8008cd:	89 e5                	mov    %esp,%ebp
  8008cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8008d2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  8008d5:	eb 06                	jmp    8008dd <strcmp+0x11>
		p++, q++;
  8008d7:	83 c1 01             	add    $0x1,%ecx
  8008da:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  8008dd:	0f b6 01             	movzbl (%ecx),%eax
  8008e0:	84 c0                	test   %al,%al
  8008e2:	74 04                	je     8008e8 <strcmp+0x1c>
  8008e4:	3a 02                	cmp    (%edx),%al
  8008e6:	74 ef                	je     8008d7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  8008e8:	0f b6 c0             	movzbl %al,%eax
  8008eb:	0f b6 12             	movzbl (%edx),%edx
  8008ee:	29 d0                	sub    %edx,%eax
}
  8008f0:	5d                   	pop    %ebp
  8008f1:	c3                   	ret    

008008f2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  8008f2:	55                   	push   %ebp
  8008f3:	89 e5                	mov    %esp,%ebp
  8008f5:	53                   	push   %ebx
  8008f6:	8b 45 08             	mov    0x8(%ebp),%eax
  8008f9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008fc:	89 c3                	mov    %eax,%ebx
  8008fe:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800901:	eb 06                	jmp    800909 <strncmp+0x17>
		n--, p++, q++;
  800903:	83 c0 01             	add    $0x1,%eax
  800906:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800909:	39 d8                	cmp    %ebx,%eax
  80090b:	74 15                	je     800922 <strncmp+0x30>
  80090d:	0f b6 08             	movzbl (%eax),%ecx
  800910:	84 c9                	test   %cl,%cl
  800912:	74 04                	je     800918 <strncmp+0x26>
  800914:	3a 0a                	cmp    (%edx),%cl
  800916:	74 eb                	je     800903 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800918:	0f b6 00             	movzbl (%eax),%eax
  80091b:	0f b6 12             	movzbl (%edx),%edx
  80091e:	29 d0                	sub    %edx,%eax
  800920:	eb 05                	jmp    800927 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800922:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800927:	5b                   	pop    %ebx
  800928:	5d                   	pop    %ebp
  800929:	c3                   	ret    

0080092a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80092a:	55                   	push   %ebp
  80092b:	89 e5                	mov    %esp,%ebp
  80092d:	8b 45 08             	mov    0x8(%ebp),%eax
  800930:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800934:	eb 07                	jmp    80093d <strchr+0x13>
		if (*s == c)
  800936:	38 ca                	cmp    %cl,%dl
  800938:	74 0f                	je     800949 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80093a:	83 c0 01             	add    $0x1,%eax
  80093d:	0f b6 10             	movzbl (%eax),%edx
  800940:	84 d2                	test   %dl,%dl
  800942:	75 f2                	jne    800936 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800944:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800949:	5d                   	pop    %ebp
  80094a:	c3                   	ret    

0080094b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  80094b:	55                   	push   %ebp
  80094c:	89 e5                	mov    %esp,%ebp
  80094e:	8b 45 08             	mov    0x8(%ebp),%eax
  800951:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800955:	eb 07                	jmp    80095e <strfind+0x13>
		if (*s == c)
  800957:	38 ca                	cmp    %cl,%dl
  800959:	74 0a                	je     800965 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  80095b:	83 c0 01             	add    $0x1,%eax
  80095e:	0f b6 10             	movzbl (%eax),%edx
  800961:	84 d2                	test   %dl,%dl
  800963:	75 f2                	jne    800957 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800965:	5d                   	pop    %ebp
  800966:	c3                   	ret    

00800967 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800967:	55                   	push   %ebp
  800968:	89 e5                	mov    %esp,%ebp
  80096a:	57                   	push   %edi
  80096b:	56                   	push   %esi
  80096c:	53                   	push   %ebx
  80096d:	8b 7d 08             	mov    0x8(%ebp),%edi
  800970:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800973:	85 c9                	test   %ecx,%ecx
  800975:	74 36                	je     8009ad <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800977:	f7 c7 03 00 00 00    	test   $0x3,%edi
  80097d:	75 28                	jne    8009a7 <memset+0x40>
  80097f:	f6 c1 03             	test   $0x3,%cl
  800982:	75 23                	jne    8009a7 <memset+0x40>
		c &= 0xFF;
  800984:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800988:	89 d3                	mov    %edx,%ebx
  80098a:	c1 e3 08             	shl    $0x8,%ebx
  80098d:	89 d6                	mov    %edx,%esi
  80098f:	c1 e6 18             	shl    $0x18,%esi
  800992:	89 d0                	mov    %edx,%eax
  800994:	c1 e0 10             	shl    $0x10,%eax
  800997:	09 f0                	or     %esi,%eax
  800999:	09 c2                	or     %eax,%edx
  80099b:	89 d0                	mov    %edx,%eax
  80099d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  80099f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  8009a2:	fc                   	cld    
  8009a3:	f3 ab                	rep stos %eax,%es:(%edi)
  8009a5:	eb 06                	jmp    8009ad <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  8009a7:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009aa:	fc                   	cld    
  8009ab:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  8009ad:	89 f8                	mov    %edi,%eax
  8009af:	5b                   	pop    %ebx
  8009b0:	5e                   	pop    %esi
  8009b1:	5f                   	pop    %edi
  8009b2:	5d                   	pop    %ebp
  8009b3:	c3                   	ret    

008009b4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  8009b4:	55                   	push   %ebp
  8009b5:	89 e5                	mov    %esp,%ebp
  8009b7:	57                   	push   %edi
  8009b8:	56                   	push   %esi
  8009b9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009bc:	8b 75 0c             	mov    0xc(%ebp),%esi
  8009bf:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  8009c2:	39 c6                	cmp    %eax,%esi
  8009c4:	73 35                	jae    8009fb <memmove+0x47>
  8009c6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  8009c9:	39 d0                	cmp    %edx,%eax
  8009cb:	73 2e                	jae    8009fb <memmove+0x47>
		s += n;
		d += n;
  8009cd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  8009d0:	89 d6                	mov    %edx,%esi
  8009d2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009d4:	f7 c6 03 00 00 00    	test   $0x3,%esi
  8009da:	75 13                	jne    8009ef <memmove+0x3b>
  8009dc:	f6 c1 03             	test   $0x3,%cl
  8009df:	75 0e                	jne    8009ef <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  8009e1:	83 ef 04             	sub    $0x4,%edi
  8009e4:	8d 72 fc             	lea    -0x4(%edx),%esi
  8009e7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  8009ea:	fd                   	std    
  8009eb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  8009ed:	eb 09                	jmp    8009f8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  8009ef:	83 ef 01             	sub    $0x1,%edi
  8009f2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  8009f5:	fd                   	std    
  8009f6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  8009f8:	fc                   	cld    
  8009f9:	eb 1d                	jmp    800a18 <memmove+0x64>
  8009fb:	89 f2                	mov    %esi,%edx
  8009fd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  8009ff:	f6 c2 03             	test   $0x3,%dl
  800a02:	75 0f                	jne    800a13 <memmove+0x5f>
  800a04:	f6 c1 03             	test   $0x3,%cl
  800a07:	75 0a                	jne    800a13 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a09:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a0c:	89 c7                	mov    %eax,%edi
  800a0e:	fc                   	cld    
  800a0f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a11:	eb 05                	jmp    800a18 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a13:	89 c7                	mov    %eax,%edi
  800a15:	fc                   	cld    
  800a16:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a18:	5e                   	pop    %esi
  800a19:	5f                   	pop    %edi
  800a1a:	5d                   	pop    %ebp
  800a1b:	c3                   	ret    

00800a1c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a1c:	55                   	push   %ebp
  800a1d:	89 e5                	mov    %esp,%ebp
  800a1f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800a22:	8b 45 10             	mov    0x10(%ebp),%eax
  800a25:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a29:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a2c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a30:	8b 45 08             	mov    0x8(%ebp),%eax
  800a33:	89 04 24             	mov    %eax,(%esp)
  800a36:	e8 79 ff ff ff       	call   8009b4 <memmove>
}
  800a3b:	c9                   	leave  
  800a3c:	c3                   	ret    

00800a3d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a3d:	55                   	push   %ebp
  800a3e:	89 e5                	mov    %esp,%ebp
  800a40:	56                   	push   %esi
  800a41:	53                   	push   %ebx
  800a42:	8b 55 08             	mov    0x8(%ebp),%edx
  800a45:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a48:	89 d6                	mov    %edx,%esi
  800a4a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a4d:	eb 1a                	jmp    800a69 <memcmp+0x2c>
		if (*s1 != *s2)
  800a4f:	0f b6 02             	movzbl (%edx),%eax
  800a52:	0f b6 19             	movzbl (%ecx),%ebx
  800a55:	38 d8                	cmp    %bl,%al
  800a57:	74 0a                	je     800a63 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800a59:	0f b6 c0             	movzbl %al,%eax
  800a5c:	0f b6 db             	movzbl %bl,%ebx
  800a5f:	29 d8                	sub    %ebx,%eax
  800a61:	eb 0f                	jmp    800a72 <memcmp+0x35>
		s1++, s2++;
  800a63:	83 c2 01             	add    $0x1,%edx
  800a66:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800a69:	39 f2                	cmp    %esi,%edx
  800a6b:	75 e2                	jne    800a4f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800a6d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800a72:	5b                   	pop    %ebx
  800a73:	5e                   	pop    %esi
  800a74:	5d                   	pop    %ebp
  800a75:	c3                   	ret    

00800a76 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800a76:	55                   	push   %ebp
  800a77:	89 e5                	mov    %esp,%ebp
  800a79:	8b 45 08             	mov    0x8(%ebp),%eax
  800a7c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800a7f:	89 c2                	mov    %eax,%edx
  800a81:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800a84:	eb 07                	jmp    800a8d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a86:	38 08                	cmp    %cl,(%eax)
  800a88:	74 07                	je     800a91 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a8a:	83 c0 01             	add    $0x1,%eax
  800a8d:	39 d0                	cmp    %edx,%eax
  800a8f:	72 f5                	jb     800a86 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a91:	5d                   	pop    %ebp
  800a92:	c3                   	ret    

00800a93 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a93:	55                   	push   %ebp
  800a94:	89 e5                	mov    %esp,%ebp
  800a96:	57                   	push   %edi
  800a97:	56                   	push   %esi
  800a98:	53                   	push   %ebx
  800a99:	8b 55 08             	mov    0x8(%ebp),%edx
  800a9c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a9f:	eb 03                	jmp    800aa4 <strtol+0x11>
		s++;
  800aa1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800aa4:	0f b6 0a             	movzbl (%edx),%ecx
  800aa7:	80 f9 09             	cmp    $0x9,%cl
  800aaa:	74 f5                	je     800aa1 <strtol+0xe>
  800aac:	80 f9 20             	cmp    $0x20,%cl
  800aaf:	74 f0                	je     800aa1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800ab1:	80 f9 2b             	cmp    $0x2b,%cl
  800ab4:	75 0a                	jne    800ac0 <strtol+0x2d>
		s++;
  800ab6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800ab9:	bf 00 00 00 00       	mov    $0x0,%edi
  800abe:	eb 11                	jmp    800ad1 <strtol+0x3e>
  800ac0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800ac5:	80 f9 2d             	cmp    $0x2d,%cl
  800ac8:	75 07                	jne    800ad1 <strtol+0x3e>
		s++, neg = 1;
  800aca:	8d 52 01             	lea    0x1(%edx),%edx
  800acd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800ad1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800ad6:	75 15                	jne    800aed <strtol+0x5a>
  800ad8:	80 3a 30             	cmpb   $0x30,(%edx)
  800adb:	75 10                	jne    800aed <strtol+0x5a>
  800add:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800ae1:	75 0a                	jne    800aed <strtol+0x5a>
		s += 2, base = 16;
  800ae3:	83 c2 02             	add    $0x2,%edx
  800ae6:	b8 10 00 00 00       	mov    $0x10,%eax
  800aeb:	eb 10                	jmp    800afd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800aed:	85 c0                	test   %eax,%eax
  800aef:	75 0c                	jne    800afd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800af1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800af3:	80 3a 30             	cmpb   $0x30,(%edx)
  800af6:	75 05                	jne    800afd <strtol+0x6a>
		s++, base = 8;
  800af8:	83 c2 01             	add    $0x1,%edx
  800afb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800afd:	bb 00 00 00 00       	mov    $0x0,%ebx
  800b02:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b05:	0f b6 0a             	movzbl (%edx),%ecx
  800b08:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800b0b:	89 f0                	mov    %esi,%eax
  800b0d:	3c 09                	cmp    $0x9,%al
  800b0f:	77 08                	ja     800b19 <strtol+0x86>
			dig = *s - '0';
  800b11:	0f be c9             	movsbl %cl,%ecx
  800b14:	83 e9 30             	sub    $0x30,%ecx
  800b17:	eb 20                	jmp    800b39 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800b19:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800b1c:	89 f0                	mov    %esi,%eax
  800b1e:	3c 19                	cmp    $0x19,%al
  800b20:	77 08                	ja     800b2a <strtol+0x97>
			dig = *s - 'a' + 10;
  800b22:	0f be c9             	movsbl %cl,%ecx
  800b25:	83 e9 57             	sub    $0x57,%ecx
  800b28:	eb 0f                	jmp    800b39 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800b2a:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800b2d:	89 f0                	mov    %esi,%eax
  800b2f:	3c 19                	cmp    $0x19,%al
  800b31:	77 16                	ja     800b49 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800b33:	0f be c9             	movsbl %cl,%ecx
  800b36:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800b39:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800b3c:	7d 0f                	jge    800b4d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800b3e:	83 c2 01             	add    $0x1,%edx
  800b41:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800b45:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800b47:	eb bc                	jmp    800b05 <strtol+0x72>
  800b49:	89 d8                	mov    %ebx,%eax
  800b4b:	eb 02                	jmp    800b4f <strtol+0xbc>
  800b4d:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800b4f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800b53:	74 05                	je     800b5a <strtol+0xc7>
		*endptr = (char *) s;
  800b55:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b58:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800b5a:	f7 d8                	neg    %eax
  800b5c:	85 ff                	test   %edi,%edi
  800b5e:	0f 44 c3             	cmove  %ebx,%eax
}
  800b61:	5b                   	pop    %ebx
  800b62:	5e                   	pop    %esi
  800b63:	5f                   	pop    %edi
  800b64:	5d                   	pop    %ebp
  800b65:	c3                   	ret    

00800b66 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800b66:	55                   	push   %ebp
  800b67:	89 e5                	mov    %esp,%ebp
  800b69:	57                   	push   %edi
  800b6a:	56                   	push   %esi
  800b6b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b6c:	b8 00 00 00 00       	mov    $0x0,%eax
  800b71:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800b74:	8b 55 08             	mov    0x8(%ebp),%edx
  800b77:	89 c3                	mov    %eax,%ebx
  800b79:	89 c7                	mov    %eax,%edi
  800b7b:	89 c6                	mov    %eax,%esi
  800b7d:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800b7f:	5b                   	pop    %ebx
  800b80:	5e                   	pop    %esi
  800b81:	5f                   	pop    %edi
  800b82:	5d                   	pop    %ebp
  800b83:	c3                   	ret    

00800b84 <sys_cgetc>:

int
sys_cgetc(void)
{
  800b84:	55                   	push   %ebp
  800b85:	89 e5                	mov    %esp,%ebp
  800b87:	57                   	push   %edi
  800b88:	56                   	push   %esi
  800b89:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b8a:	ba 00 00 00 00       	mov    $0x0,%edx
  800b8f:	b8 01 00 00 00       	mov    $0x1,%eax
  800b94:	89 d1                	mov    %edx,%ecx
  800b96:	89 d3                	mov    %edx,%ebx
  800b98:	89 d7                	mov    %edx,%edi
  800b9a:	89 d6                	mov    %edx,%esi
  800b9c:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b9e:	5b                   	pop    %ebx
  800b9f:	5e                   	pop    %esi
  800ba0:	5f                   	pop    %edi
  800ba1:	5d                   	pop    %ebp
  800ba2:	c3                   	ret    

00800ba3 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800ba3:	55                   	push   %ebp
  800ba4:	89 e5                	mov    %esp,%ebp
  800ba6:	57                   	push   %edi
  800ba7:	56                   	push   %esi
  800ba8:	53                   	push   %ebx
  800ba9:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bac:	b9 00 00 00 00       	mov    $0x0,%ecx
  800bb1:	b8 03 00 00 00       	mov    $0x3,%eax
  800bb6:	8b 55 08             	mov    0x8(%ebp),%edx
  800bb9:	89 cb                	mov    %ecx,%ebx
  800bbb:	89 cf                	mov    %ecx,%edi
  800bbd:	89 ce                	mov    %ecx,%esi
  800bbf:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800bc1:	85 c0                	test   %eax,%eax
  800bc3:	7e 28                	jle    800bed <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800bc5:	89 44 24 10          	mov    %eax,0x10(%esp)
  800bc9:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800bd0:	00 
  800bd1:	c7 44 24 08 e8 13 80 	movl   $0x8013e8,0x8(%esp)
  800bd8:	00 
  800bd9:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800be0:	00 
  800be1:	c7 04 24 05 14 80 00 	movl   $0x801405,(%esp)
  800be8:	e8 9f 02 00 00       	call   800e8c <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800bed:	83 c4 2c             	add    $0x2c,%esp
  800bf0:	5b                   	pop    %ebx
  800bf1:	5e                   	pop    %esi
  800bf2:	5f                   	pop    %edi
  800bf3:	5d                   	pop    %ebp
  800bf4:	c3                   	ret    

00800bf5 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800bf5:	55                   	push   %ebp
  800bf6:	89 e5                	mov    %esp,%ebp
  800bf8:	57                   	push   %edi
  800bf9:	56                   	push   %esi
  800bfa:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800bfb:	ba 00 00 00 00       	mov    $0x0,%edx
  800c00:	b8 02 00 00 00       	mov    $0x2,%eax
  800c05:	89 d1                	mov    %edx,%ecx
  800c07:	89 d3                	mov    %edx,%ebx
  800c09:	89 d7                	mov    %edx,%edi
  800c0b:	89 d6                	mov    %edx,%esi
  800c0d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800c0f:	5b                   	pop    %ebx
  800c10:	5e                   	pop    %esi
  800c11:	5f                   	pop    %edi
  800c12:	5d                   	pop    %ebp
  800c13:	c3                   	ret    

00800c14 <sys_yield>:

void
sys_yield(void)
{
  800c14:	55                   	push   %ebp
  800c15:	89 e5                	mov    %esp,%ebp
  800c17:	57                   	push   %edi
  800c18:	56                   	push   %esi
  800c19:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c1a:	ba 00 00 00 00       	mov    $0x0,%edx
  800c1f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800c24:	89 d1                	mov    %edx,%ecx
  800c26:	89 d3                	mov    %edx,%ebx
  800c28:	89 d7                	mov    %edx,%edi
  800c2a:	89 d6                	mov    %edx,%esi
  800c2c:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800c2e:	5b                   	pop    %ebx
  800c2f:	5e                   	pop    %esi
  800c30:	5f                   	pop    %edi
  800c31:	5d                   	pop    %ebp
  800c32:	c3                   	ret    

00800c33 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800c33:	55                   	push   %ebp
  800c34:	89 e5                	mov    %esp,%ebp
  800c36:	57                   	push   %edi
  800c37:	56                   	push   %esi
  800c38:	53                   	push   %ebx
  800c39:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c3c:	be 00 00 00 00       	mov    $0x0,%esi
  800c41:	b8 04 00 00 00       	mov    $0x4,%eax
  800c46:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c49:	8b 55 08             	mov    0x8(%ebp),%edx
  800c4c:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c4f:	89 f7                	mov    %esi,%edi
  800c51:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800c53:	85 c0                	test   %eax,%eax
  800c55:	7e 28                	jle    800c7f <sys_page_alloc+0x4c>
		panic("syscall %d returned %d (> 0)", num, ret);
  800c57:	89 44 24 10          	mov    %eax,0x10(%esp)
  800c5b:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800c62:	00 
  800c63:	c7 44 24 08 e8 13 80 	movl   $0x8013e8,0x8(%esp)
  800c6a:	00 
  800c6b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800c72:	00 
  800c73:	c7 04 24 05 14 80 00 	movl   $0x801405,(%esp)
  800c7a:	e8 0d 02 00 00       	call   800e8c <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800c7f:	83 c4 2c             	add    $0x2c,%esp
  800c82:	5b                   	pop    %ebx
  800c83:	5e                   	pop    %esi
  800c84:	5f                   	pop    %edi
  800c85:	5d                   	pop    %ebp
  800c86:	c3                   	ret    

00800c87 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800c87:	55                   	push   %ebp
  800c88:	89 e5                	mov    %esp,%ebp
  800c8a:	57                   	push   %edi
  800c8b:	56                   	push   %esi
  800c8c:	53                   	push   %ebx
  800c8d:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800c90:	b8 05 00 00 00       	mov    $0x5,%eax
  800c95:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800c98:	8b 55 08             	mov    0x8(%ebp),%edx
  800c9b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800c9e:	8b 7d 14             	mov    0x14(%ebp),%edi
  800ca1:	8b 75 18             	mov    0x18(%ebp),%esi
  800ca4:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800ca6:	85 c0                	test   %eax,%eax
  800ca8:	7e 28                	jle    800cd2 <sys_page_map+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800caa:	89 44 24 10          	mov    %eax,0x10(%esp)
  800cae:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800cb5:	00 
  800cb6:	c7 44 24 08 e8 13 80 	movl   $0x8013e8,0x8(%esp)
  800cbd:	00 
  800cbe:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800cc5:	00 
  800cc6:	c7 04 24 05 14 80 00 	movl   $0x801405,(%esp)
  800ccd:	e8 ba 01 00 00       	call   800e8c <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800cd2:	83 c4 2c             	add    $0x2c,%esp
  800cd5:	5b                   	pop    %ebx
  800cd6:	5e                   	pop    %esi
  800cd7:	5f                   	pop    %edi
  800cd8:	5d                   	pop    %ebp
  800cd9:	c3                   	ret    

00800cda <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800cda:	55                   	push   %ebp
  800cdb:	89 e5                	mov    %esp,%ebp
  800cdd:	57                   	push   %edi
  800cde:	56                   	push   %esi
  800cdf:	53                   	push   %ebx
  800ce0:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ce3:	bb 00 00 00 00       	mov    $0x0,%ebx
  800ce8:	b8 06 00 00 00       	mov    $0x6,%eax
  800ced:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cf0:	8b 55 08             	mov    0x8(%ebp),%edx
  800cf3:	89 df                	mov    %ebx,%edi
  800cf5:	89 de                	mov    %ebx,%esi
  800cf7:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800cf9:	85 c0                	test   %eax,%eax
  800cfb:	7e 28                	jle    800d25 <sys_page_unmap+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800cfd:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d01:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800d08:	00 
  800d09:	c7 44 24 08 e8 13 80 	movl   $0x8013e8,0x8(%esp)
  800d10:	00 
  800d11:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d18:	00 
  800d19:	c7 04 24 05 14 80 00 	movl   $0x801405,(%esp)
  800d20:	e8 67 01 00 00       	call   800e8c <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800d25:	83 c4 2c             	add    $0x2c,%esp
  800d28:	5b                   	pop    %ebx
  800d29:	5e                   	pop    %esi
  800d2a:	5f                   	pop    %edi
  800d2b:	5d                   	pop    %ebp
  800d2c:	c3                   	ret    

00800d2d <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800d2d:	55                   	push   %ebp
  800d2e:	89 e5                	mov    %esp,%ebp
  800d30:	57                   	push   %edi
  800d31:	56                   	push   %esi
  800d32:	53                   	push   %ebx
  800d33:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d36:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d3b:	b8 08 00 00 00       	mov    $0x8,%eax
  800d40:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d43:	8b 55 08             	mov    0x8(%ebp),%edx
  800d46:	89 df                	mov    %ebx,%edi
  800d48:	89 de                	mov    %ebx,%esi
  800d4a:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d4c:	85 c0                	test   %eax,%eax
  800d4e:	7e 28                	jle    800d78 <sys_env_set_status+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d50:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d54:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800d5b:	00 
  800d5c:	c7 44 24 08 e8 13 80 	movl   $0x8013e8,0x8(%esp)
  800d63:	00 
  800d64:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d6b:	00 
  800d6c:	c7 04 24 05 14 80 00 	movl   $0x801405,(%esp)
  800d73:	e8 14 01 00 00       	call   800e8c <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800d78:	83 c4 2c             	add    $0x2c,%esp
  800d7b:	5b                   	pop    %ebx
  800d7c:	5e                   	pop    %esi
  800d7d:	5f                   	pop    %edi
  800d7e:	5d                   	pop    %ebp
  800d7f:	c3                   	ret    

00800d80 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800d80:	55                   	push   %ebp
  800d81:	89 e5                	mov    %esp,%ebp
  800d83:	57                   	push   %edi
  800d84:	56                   	push   %esi
  800d85:	53                   	push   %ebx
  800d86:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d89:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d8e:	b8 09 00 00 00       	mov    $0x9,%eax
  800d93:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d96:	8b 55 08             	mov    0x8(%ebp),%edx
  800d99:	89 df                	mov    %ebx,%edi
  800d9b:	89 de                	mov    %ebx,%esi
  800d9d:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d9f:	85 c0                	test   %eax,%eax
  800da1:	7e 28                	jle    800dcb <sys_env_set_pgfault_upcall+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800da3:	89 44 24 10          	mov    %eax,0x10(%esp)
  800da7:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800dae:	00 
  800daf:	c7 44 24 08 e8 13 80 	movl   $0x8013e8,0x8(%esp)
  800db6:	00 
  800db7:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800dbe:	00 
  800dbf:	c7 04 24 05 14 80 00 	movl   $0x801405,(%esp)
  800dc6:	e8 c1 00 00 00       	call   800e8c <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800dcb:	83 c4 2c             	add    $0x2c,%esp
  800dce:	5b                   	pop    %ebx
  800dcf:	5e                   	pop    %esi
  800dd0:	5f                   	pop    %edi
  800dd1:	5d                   	pop    %ebp
  800dd2:	c3                   	ret    

00800dd3 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800dd3:	55                   	push   %ebp
  800dd4:	89 e5                	mov    %esp,%ebp
  800dd6:	57                   	push   %edi
  800dd7:	56                   	push   %esi
  800dd8:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dd9:	be 00 00 00 00       	mov    $0x0,%esi
  800dde:	b8 0b 00 00 00       	mov    $0xb,%eax
  800de3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800de6:	8b 55 08             	mov    0x8(%ebp),%edx
  800de9:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800dec:	8b 7d 14             	mov    0x14(%ebp),%edi
  800def:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800df1:	5b                   	pop    %ebx
  800df2:	5e                   	pop    %esi
  800df3:	5f                   	pop    %edi
  800df4:	5d                   	pop    %ebp
  800df5:	c3                   	ret    

00800df6 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800df6:	55                   	push   %ebp
  800df7:	89 e5                	mov    %esp,%ebp
  800df9:	57                   	push   %edi
  800dfa:	56                   	push   %esi
  800dfb:	53                   	push   %ebx
  800dfc:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dff:	b9 00 00 00 00       	mov    $0x0,%ecx
  800e04:	b8 0c 00 00 00       	mov    $0xc,%eax
  800e09:	8b 55 08             	mov    0x8(%ebp),%edx
  800e0c:	89 cb                	mov    %ecx,%ebx
  800e0e:	89 cf                	mov    %ecx,%edi
  800e10:	89 ce                	mov    %ecx,%esi
  800e12:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e14:	85 c0                	test   %eax,%eax
  800e16:	7e 28                	jle    800e40 <sys_ipc_recv+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e18:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e1c:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800e23:	00 
  800e24:	c7 44 24 08 e8 13 80 	movl   $0x8013e8,0x8(%esp)
  800e2b:	00 
  800e2c:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e33:	00 
  800e34:	c7 04 24 05 14 80 00 	movl   $0x801405,(%esp)
  800e3b:	e8 4c 00 00 00       	call   800e8c <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800e40:	83 c4 2c             	add    $0x2c,%esp
  800e43:	5b                   	pop    %ebx
  800e44:	5e                   	pop    %esi
  800e45:	5f                   	pop    %edi
  800e46:	5d                   	pop    %ebp
  800e47:	c3                   	ret    

00800e48 <fork>:
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
  800e48:	55                   	push   %ebp
  800e49:	89 e5                	mov    %esp,%ebp
  800e4b:	83 ec 18             	sub    $0x18,%esp
	// LAB 4: Your code here.
	panic("fork not implemented");
  800e4e:	c7 44 24 08 1f 14 80 	movl   $0x80141f,0x8(%esp)
  800e55:	00 
  800e56:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
  800e5d:	00 
  800e5e:	c7 04 24 13 14 80 00 	movl   $0x801413,(%esp)
  800e65:	e8 22 00 00 00       	call   800e8c <_panic>

00800e6a <sfork>:
}

// Challenge!
int
sfork(void)
{
  800e6a:	55                   	push   %ebp
  800e6b:	89 e5                	mov    %esp,%ebp
  800e6d:	83 ec 18             	sub    $0x18,%esp
	panic("sfork not implemented");
  800e70:	c7 44 24 08 1e 14 80 	movl   $0x80141e,0x8(%esp)
  800e77:	00 
  800e78:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
  800e7f:	00 
  800e80:	c7 04 24 13 14 80 00 	movl   $0x801413,(%esp)
  800e87:	e8 00 00 00 00       	call   800e8c <_panic>

00800e8c <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800e8c:	55                   	push   %ebp
  800e8d:	89 e5                	mov    %esp,%ebp
  800e8f:	56                   	push   %esi
  800e90:	53                   	push   %ebx
  800e91:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800e94:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800e97:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800e9d:	e8 53 fd ff ff       	call   800bf5 <sys_getenvid>
  800ea2:	8b 55 0c             	mov    0xc(%ebp),%edx
  800ea5:	89 54 24 10          	mov    %edx,0x10(%esp)
  800ea9:	8b 55 08             	mov    0x8(%ebp),%edx
  800eac:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800eb0:	89 74 24 08          	mov    %esi,0x8(%esp)
  800eb4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800eb8:	c7 04 24 34 14 80 00 	movl   $0x801434,(%esp)
  800ebf:	e8 2e f3 ff ff       	call   8001f2 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800ec4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800ec8:	8b 45 10             	mov    0x10(%ebp),%eax
  800ecb:	89 04 24             	mov    %eax,(%esp)
  800ece:	e8 be f2 ff ff       	call   800191 <vcprintf>
	cprintf("\n");
  800ed3:	c7 04 24 8f 11 80 00 	movl   $0x80118f,(%esp)
  800eda:	e8 13 f3 ff ff       	call   8001f2 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800edf:	cc                   	int3   
  800ee0:	eb fd                	jmp    800edf <_panic+0x53>
  800ee2:	66 90                	xchg   %ax,%ax
  800ee4:	66 90                	xchg   %ax,%ax
  800ee6:	66 90                	xchg   %ax,%ax
  800ee8:	66 90                	xchg   %ax,%ax
  800eea:	66 90                	xchg   %ax,%ax
  800eec:	66 90                	xchg   %ax,%ax
  800eee:	66 90                	xchg   %ax,%ax

00800ef0 <__udivdi3>:
  800ef0:	55                   	push   %ebp
  800ef1:	57                   	push   %edi
  800ef2:	56                   	push   %esi
  800ef3:	83 ec 0c             	sub    $0xc,%esp
  800ef6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800efa:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800efe:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800f02:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800f06:	85 c0                	test   %eax,%eax
  800f08:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800f0c:	89 ea                	mov    %ebp,%edx
  800f0e:	89 0c 24             	mov    %ecx,(%esp)
  800f11:	75 2d                	jne    800f40 <__udivdi3+0x50>
  800f13:	39 e9                	cmp    %ebp,%ecx
  800f15:	77 61                	ja     800f78 <__udivdi3+0x88>
  800f17:	85 c9                	test   %ecx,%ecx
  800f19:	89 ce                	mov    %ecx,%esi
  800f1b:	75 0b                	jne    800f28 <__udivdi3+0x38>
  800f1d:	b8 01 00 00 00       	mov    $0x1,%eax
  800f22:	31 d2                	xor    %edx,%edx
  800f24:	f7 f1                	div    %ecx
  800f26:	89 c6                	mov    %eax,%esi
  800f28:	31 d2                	xor    %edx,%edx
  800f2a:	89 e8                	mov    %ebp,%eax
  800f2c:	f7 f6                	div    %esi
  800f2e:	89 c5                	mov    %eax,%ebp
  800f30:	89 f8                	mov    %edi,%eax
  800f32:	f7 f6                	div    %esi
  800f34:	89 ea                	mov    %ebp,%edx
  800f36:	83 c4 0c             	add    $0xc,%esp
  800f39:	5e                   	pop    %esi
  800f3a:	5f                   	pop    %edi
  800f3b:	5d                   	pop    %ebp
  800f3c:	c3                   	ret    
  800f3d:	8d 76 00             	lea    0x0(%esi),%esi
  800f40:	39 e8                	cmp    %ebp,%eax
  800f42:	77 24                	ja     800f68 <__udivdi3+0x78>
  800f44:	0f bd e8             	bsr    %eax,%ebp
  800f47:	83 f5 1f             	xor    $0x1f,%ebp
  800f4a:	75 3c                	jne    800f88 <__udivdi3+0x98>
  800f4c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800f50:	39 34 24             	cmp    %esi,(%esp)
  800f53:	0f 86 9f 00 00 00    	jbe    800ff8 <__udivdi3+0x108>
  800f59:	39 d0                	cmp    %edx,%eax
  800f5b:	0f 82 97 00 00 00    	jb     800ff8 <__udivdi3+0x108>
  800f61:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800f68:	31 d2                	xor    %edx,%edx
  800f6a:	31 c0                	xor    %eax,%eax
  800f6c:	83 c4 0c             	add    $0xc,%esp
  800f6f:	5e                   	pop    %esi
  800f70:	5f                   	pop    %edi
  800f71:	5d                   	pop    %ebp
  800f72:	c3                   	ret    
  800f73:	90                   	nop
  800f74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f78:	89 f8                	mov    %edi,%eax
  800f7a:	f7 f1                	div    %ecx
  800f7c:	31 d2                	xor    %edx,%edx
  800f7e:	83 c4 0c             	add    $0xc,%esp
  800f81:	5e                   	pop    %esi
  800f82:	5f                   	pop    %edi
  800f83:	5d                   	pop    %ebp
  800f84:	c3                   	ret    
  800f85:	8d 76 00             	lea    0x0(%esi),%esi
  800f88:	89 e9                	mov    %ebp,%ecx
  800f8a:	8b 3c 24             	mov    (%esp),%edi
  800f8d:	d3 e0                	shl    %cl,%eax
  800f8f:	89 c6                	mov    %eax,%esi
  800f91:	b8 20 00 00 00       	mov    $0x20,%eax
  800f96:	29 e8                	sub    %ebp,%eax
  800f98:	89 c1                	mov    %eax,%ecx
  800f9a:	d3 ef                	shr    %cl,%edi
  800f9c:	89 e9                	mov    %ebp,%ecx
  800f9e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800fa2:	8b 3c 24             	mov    (%esp),%edi
  800fa5:	09 74 24 08          	or     %esi,0x8(%esp)
  800fa9:	89 d6                	mov    %edx,%esi
  800fab:	d3 e7                	shl    %cl,%edi
  800fad:	89 c1                	mov    %eax,%ecx
  800faf:	89 3c 24             	mov    %edi,(%esp)
  800fb2:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800fb6:	d3 ee                	shr    %cl,%esi
  800fb8:	89 e9                	mov    %ebp,%ecx
  800fba:	d3 e2                	shl    %cl,%edx
  800fbc:	89 c1                	mov    %eax,%ecx
  800fbe:	d3 ef                	shr    %cl,%edi
  800fc0:	09 d7                	or     %edx,%edi
  800fc2:	89 f2                	mov    %esi,%edx
  800fc4:	89 f8                	mov    %edi,%eax
  800fc6:	f7 74 24 08          	divl   0x8(%esp)
  800fca:	89 d6                	mov    %edx,%esi
  800fcc:	89 c7                	mov    %eax,%edi
  800fce:	f7 24 24             	mull   (%esp)
  800fd1:	39 d6                	cmp    %edx,%esi
  800fd3:	89 14 24             	mov    %edx,(%esp)
  800fd6:	72 30                	jb     801008 <__udivdi3+0x118>
  800fd8:	8b 54 24 04          	mov    0x4(%esp),%edx
  800fdc:	89 e9                	mov    %ebp,%ecx
  800fde:	d3 e2                	shl    %cl,%edx
  800fe0:	39 c2                	cmp    %eax,%edx
  800fe2:	73 05                	jae    800fe9 <__udivdi3+0xf9>
  800fe4:	3b 34 24             	cmp    (%esp),%esi
  800fe7:	74 1f                	je     801008 <__udivdi3+0x118>
  800fe9:	89 f8                	mov    %edi,%eax
  800feb:	31 d2                	xor    %edx,%edx
  800fed:	e9 7a ff ff ff       	jmp    800f6c <__udivdi3+0x7c>
  800ff2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ff8:	31 d2                	xor    %edx,%edx
  800ffa:	b8 01 00 00 00       	mov    $0x1,%eax
  800fff:	e9 68 ff ff ff       	jmp    800f6c <__udivdi3+0x7c>
  801004:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801008:	8d 47 ff             	lea    -0x1(%edi),%eax
  80100b:	31 d2                	xor    %edx,%edx
  80100d:	83 c4 0c             	add    $0xc,%esp
  801010:	5e                   	pop    %esi
  801011:	5f                   	pop    %edi
  801012:	5d                   	pop    %ebp
  801013:	c3                   	ret    
  801014:	66 90                	xchg   %ax,%ax
  801016:	66 90                	xchg   %ax,%ax
  801018:	66 90                	xchg   %ax,%ax
  80101a:	66 90                	xchg   %ax,%ax
  80101c:	66 90                	xchg   %ax,%ax
  80101e:	66 90                	xchg   %ax,%ax

00801020 <__umoddi3>:
  801020:	55                   	push   %ebp
  801021:	57                   	push   %edi
  801022:	56                   	push   %esi
  801023:	83 ec 14             	sub    $0x14,%esp
  801026:	8b 44 24 28          	mov    0x28(%esp),%eax
  80102a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  80102e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  801032:	89 c7                	mov    %eax,%edi
  801034:	89 44 24 04          	mov    %eax,0x4(%esp)
  801038:	8b 44 24 30          	mov    0x30(%esp),%eax
  80103c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  801040:	89 34 24             	mov    %esi,(%esp)
  801043:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  801047:	85 c0                	test   %eax,%eax
  801049:	89 c2                	mov    %eax,%edx
  80104b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  80104f:	75 17                	jne    801068 <__umoddi3+0x48>
  801051:	39 fe                	cmp    %edi,%esi
  801053:	76 4b                	jbe    8010a0 <__umoddi3+0x80>
  801055:	89 c8                	mov    %ecx,%eax
  801057:	89 fa                	mov    %edi,%edx
  801059:	f7 f6                	div    %esi
  80105b:	89 d0                	mov    %edx,%eax
  80105d:	31 d2                	xor    %edx,%edx
  80105f:	83 c4 14             	add    $0x14,%esp
  801062:	5e                   	pop    %esi
  801063:	5f                   	pop    %edi
  801064:	5d                   	pop    %ebp
  801065:	c3                   	ret    
  801066:	66 90                	xchg   %ax,%ax
  801068:	39 f8                	cmp    %edi,%eax
  80106a:	77 54                	ja     8010c0 <__umoddi3+0xa0>
  80106c:	0f bd e8             	bsr    %eax,%ebp
  80106f:	83 f5 1f             	xor    $0x1f,%ebp
  801072:	75 5c                	jne    8010d0 <__umoddi3+0xb0>
  801074:	8b 7c 24 08          	mov    0x8(%esp),%edi
  801078:	39 3c 24             	cmp    %edi,(%esp)
  80107b:	0f 87 e7 00 00 00    	ja     801168 <__umoddi3+0x148>
  801081:	8b 7c 24 04          	mov    0x4(%esp),%edi
  801085:	29 f1                	sub    %esi,%ecx
  801087:	19 c7                	sbb    %eax,%edi
  801089:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80108d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801091:	8b 44 24 08          	mov    0x8(%esp),%eax
  801095:	8b 54 24 0c          	mov    0xc(%esp),%edx
  801099:	83 c4 14             	add    $0x14,%esp
  80109c:	5e                   	pop    %esi
  80109d:	5f                   	pop    %edi
  80109e:	5d                   	pop    %ebp
  80109f:	c3                   	ret    
  8010a0:	85 f6                	test   %esi,%esi
  8010a2:	89 f5                	mov    %esi,%ebp
  8010a4:	75 0b                	jne    8010b1 <__umoddi3+0x91>
  8010a6:	b8 01 00 00 00       	mov    $0x1,%eax
  8010ab:	31 d2                	xor    %edx,%edx
  8010ad:	f7 f6                	div    %esi
  8010af:	89 c5                	mov    %eax,%ebp
  8010b1:	8b 44 24 04          	mov    0x4(%esp),%eax
  8010b5:	31 d2                	xor    %edx,%edx
  8010b7:	f7 f5                	div    %ebp
  8010b9:	89 c8                	mov    %ecx,%eax
  8010bb:	f7 f5                	div    %ebp
  8010bd:	eb 9c                	jmp    80105b <__umoddi3+0x3b>
  8010bf:	90                   	nop
  8010c0:	89 c8                	mov    %ecx,%eax
  8010c2:	89 fa                	mov    %edi,%edx
  8010c4:	83 c4 14             	add    $0x14,%esp
  8010c7:	5e                   	pop    %esi
  8010c8:	5f                   	pop    %edi
  8010c9:	5d                   	pop    %ebp
  8010ca:	c3                   	ret    
  8010cb:	90                   	nop
  8010cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8010d0:	8b 04 24             	mov    (%esp),%eax
  8010d3:	be 20 00 00 00       	mov    $0x20,%esi
  8010d8:	89 e9                	mov    %ebp,%ecx
  8010da:	29 ee                	sub    %ebp,%esi
  8010dc:	d3 e2                	shl    %cl,%edx
  8010de:	89 f1                	mov    %esi,%ecx
  8010e0:	d3 e8                	shr    %cl,%eax
  8010e2:	89 e9                	mov    %ebp,%ecx
  8010e4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8010e8:	8b 04 24             	mov    (%esp),%eax
  8010eb:	09 54 24 04          	or     %edx,0x4(%esp)
  8010ef:	89 fa                	mov    %edi,%edx
  8010f1:	d3 e0                	shl    %cl,%eax
  8010f3:	89 f1                	mov    %esi,%ecx
  8010f5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8010f9:	8b 44 24 10          	mov    0x10(%esp),%eax
  8010fd:	d3 ea                	shr    %cl,%edx
  8010ff:	89 e9                	mov    %ebp,%ecx
  801101:	d3 e7                	shl    %cl,%edi
  801103:	89 f1                	mov    %esi,%ecx
  801105:	d3 e8                	shr    %cl,%eax
  801107:	89 e9                	mov    %ebp,%ecx
  801109:	09 f8                	or     %edi,%eax
  80110b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  80110f:	f7 74 24 04          	divl   0x4(%esp)
  801113:	d3 e7                	shl    %cl,%edi
  801115:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801119:	89 d7                	mov    %edx,%edi
  80111b:	f7 64 24 08          	mull   0x8(%esp)
  80111f:	39 d7                	cmp    %edx,%edi
  801121:	89 c1                	mov    %eax,%ecx
  801123:	89 14 24             	mov    %edx,(%esp)
  801126:	72 2c                	jb     801154 <__umoddi3+0x134>
  801128:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  80112c:	72 22                	jb     801150 <__umoddi3+0x130>
  80112e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801132:	29 c8                	sub    %ecx,%eax
  801134:	19 d7                	sbb    %edx,%edi
  801136:	89 e9                	mov    %ebp,%ecx
  801138:	89 fa                	mov    %edi,%edx
  80113a:	d3 e8                	shr    %cl,%eax
  80113c:	89 f1                	mov    %esi,%ecx
  80113e:	d3 e2                	shl    %cl,%edx
  801140:	89 e9                	mov    %ebp,%ecx
  801142:	d3 ef                	shr    %cl,%edi
  801144:	09 d0                	or     %edx,%eax
  801146:	89 fa                	mov    %edi,%edx
  801148:	83 c4 14             	add    $0x14,%esp
  80114b:	5e                   	pop    %esi
  80114c:	5f                   	pop    %edi
  80114d:	5d                   	pop    %ebp
  80114e:	c3                   	ret    
  80114f:	90                   	nop
  801150:	39 d7                	cmp    %edx,%edi
  801152:	75 da                	jne    80112e <__umoddi3+0x10e>
  801154:	8b 14 24             	mov    (%esp),%edx
  801157:	89 c1                	mov    %eax,%ecx
  801159:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  80115d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  801161:	eb cb                	jmp    80112e <__umoddi3+0x10e>
  801163:	90                   	nop
  801164:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801168:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  80116c:	0f 82 0f ff ff ff    	jb     801081 <__umoddi3+0x61>
  801172:	e9 1a ff ff ff       	jmp    801091 <__umoddi3+0x71>
