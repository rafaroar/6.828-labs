
obj/user/dumbfork:     file format elf32-i386


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
  80002c:	e8 1d 02 00 00       	call   80024e <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>
  800033:	66 90                	xchg   %ax,%ax
  800035:	66 90                	xchg   %ax,%ax
  800037:	66 90                	xchg   %ax,%ax
  800039:	66 90                	xchg   %ax,%ax
  80003b:	66 90                	xchg   %ax,%ax
  80003d:	66 90                	xchg   %ax,%ax
  80003f:	90                   	nop

00800040 <duppage>:
	}
}

void
duppage(envid_t dstenv, void *addr)
{
  800040:	55                   	push   %ebp
  800041:	89 e5                	mov    %esp,%ebp
  800043:	56                   	push   %esi
  800044:	53                   	push   %ebx
  800045:	83 ec 20             	sub    $0x20,%esp
  800048:	8b 75 08             	mov    0x8(%ebp),%esi
  80004b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	int r;

	// This is NOT what you should do in your fork.
	if ((r = sys_page_alloc(dstenv, addr, PTE_P|PTE_U|PTE_W)) < 0)
  80004e:	c7 44 24 08 07 00 00 	movl   $0x7,0x8(%esp)
  800055:	00 
  800056:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80005a:	89 34 24             	mov    %esi,(%esp)
  80005d:	e8 81 0d 00 00       	call   800de3 <sys_page_alloc>
  800062:	85 c0                	test   %eax,%eax
  800064:	79 20                	jns    800086 <duppage+0x46>
		panic("sys_page_alloc: %e", r);
  800066:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80006a:	c7 44 24 08 a0 12 80 	movl   $0x8012a0,0x8(%esp)
  800071:	00 
  800072:	c7 44 24 04 20 00 00 	movl   $0x20,0x4(%esp)
  800079:	00 
  80007a:	c7 04 24 b3 12 80 00 	movl   $0x8012b3,(%esp)
  800081:	e8 24 02 00 00       	call   8002aa <_panic>
	if ((r = sys_page_map(dstenv, addr, 0, UTEMP, PTE_P|PTE_U|PTE_W)) < 0)
  800086:	c7 44 24 10 07 00 00 	movl   $0x7,0x10(%esp)
  80008d:	00 
  80008e:	c7 44 24 0c 00 00 40 	movl   $0x400000,0xc(%esp)
  800095:	00 
  800096:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
  80009d:	00 
  80009e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8000a2:	89 34 24             	mov    %esi,(%esp)
  8000a5:	e8 8d 0d 00 00       	call   800e37 <sys_page_map>
  8000aa:	85 c0                	test   %eax,%eax
  8000ac:	79 20                	jns    8000ce <duppage+0x8e>
		panic("sys_page_map: %e", r);
  8000ae:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8000b2:	c7 44 24 08 c3 12 80 	movl   $0x8012c3,0x8(%esp)
  8000b9:	00 
  8000ba:	c7 44 24 04 22 00 00 	movl   $0x22,0x4(%esp)
  8000c1:	00 
  8000c2:	c7 04 24 b3 12 80 00 	movl   $0x8012b3,(%esp)
  8000c9:	e8 dc 01 00 00       	call   8002aa <_panic>
	memmove(UTEMP, addr, PGSIZE);
  8000ce:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
  8000d5:	00 
  8000d6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8000da:	c7 04 24 00 00 40 00 	movl   $0x400000,(%esp)
  8000e1:	e8 7e 0a 00 00       	call   800b64 <memmove>
	if ((r = sys_page_unmap(0, UTEMP)) < 0)
  8000e6:	c7 44 24 04 00 00 40 	movl   $0x400000,0x4(%esp)
  8000ed:	00 
  8000ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000f5:	e8 90 0d 00 00       	call   800e8a <sys_page_unmap>
  8000fa:	85 c0                	test   %eax,%eax
  8000fc:	79 20                	jns    80011e <duppage+0xde>
		panic("sys_page_unmap: %e", r);
  8000fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800102:	c7 44 24 08 d4 12 80 	movl   $0x8012d4,0x8(%esp)
  800109:	00 
  80010a:	c7 44 24 04 25 00 00 	movl   $0x25,0x4(%esp)
  800111:	00 
  800112:	c7 04 24 b3 12 80 00 	movl   $0x8012b3,(%esp)
  800119:	e8 8c 01 00 00       	call   8002aa <_panic>
}
  80011e:	83 c4 20             	add    $0x20,%esp
  800121:	5b                   	pop    %ebx
  800122:	5e                   	pop    %esi
  800123:	5d                   	pop    %ebp
  800124:	c3                   	ret    

00800125 <dumbfork>:

envid_t
dumbfork(void)
{
  800125:	55                   	push   %ebp
  800126:	89 e5                	mov    %esp,%ebp
  800128:	56                   	push   %esi
  800129:	53                   	push   %ebx
  80012a:	83 ec 20             	sub    $0x20,%esp
// This must be inlined.  Exercise for reader: why?
static __inline envid_t __attribute__((always_inline))
sys_exofork(void)
{
	envid_t ret;
	__asm __volatile("int %2"
  80012d:	b8 07 00 00 00       	mov    $0x7,%eax
  800132:	cd 30                	int    $0x30
  800134:	89 c6                	mov    %eax,%esi
	// The kernel will initialize it with a copy of our register state,
	// so that the child will appear to have called sys_exofork() too -
	// except that in the child, this "fake" call to sys_exofork()
	// will return 0 instead of the envid of the child.
	envid = sys_exofork();
	if (envid < 0)
  800136:	85 c0                	test   %eax,%eax
  800138:	79 20                	jns    80015a <dumbfork+0x35>
		panic("sys_exofork: %e", envid);
  80013a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80013e:	c7 44 24 08 e7 12 80 	movl   $0x8012e7,0x8(%esp)
  800145:	00 
  800146:	c7 44 24 04 37 00 00 	movl   $0x37,0x4(%esp)
  80014d:	00 
  80014e:	c7 04 24 b3 12 80 00 	movl   $0x8012b3,(%esp)
  800155:	e8 50 01 00 00       	call   8002aa <_panic>
  80015a:	89 c3                	mov    %eax,%ebx
	if (envid == 0) {
  80015c:	85 c0                	test   %eax,%eax
  80015e:	75 1e                	jne    80017e <dumbfork+0x59>
		// We're the child.
		// The copied value of the global variable 'thisenv'
		// is no longer valid (it refers to the parent!).
		// Fix it and return 0.
		thisenv = &envs[ENVX(sys_getenvid())];
  800160:	e8 40 0c 00 00       	call   800da5 <sys_getenvid>
  800165:	25 ff 03 00 00       	and    $0x3ff,%eax
  80016a:	6b c0 7c             	imul   $0x7c,%eax,%eax
  80016d:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800172:	a3 04 20 80 00       	mov    %eax,0x802004
		return 0;
  800177:	b8 00 00 00 00       	mov    $0x0,%eax
  80017c:	eb 71                	jmp    8001ef <dumbfork+0xca>
	}

	// We're the parent.
	// Eagerly copy our entire address space into the child.
	// This is NOT what you should do in your fork implementation.
	for (addr = (uint8_t*) UTEXT; addr < end; addr += PGSIZE)
  80017e:	c7 45 f4 00 00 80 00 	movl   $0x800000,-0xc(%ebp)
  800185:	eb 13                	jmp    80019a <dumbfork+0x75>
		duppage(envid, addr);
  800187:	89 54 24 04          	mov    %edx,0x4(%esp)
  80018b:	89 1c 24             	mov    %ebx,(%esp)
  80018e:	e8 ad fe ff ff       	call   800040 <duppage>
	}

	// We're the parent.
	// Eagerly copy our entire address space into the child.
	// This is NOT what you should do in your fork implementation.
	for (addr = (uint8_t*) UTEXT; addr < end; addr += PGSIZE)
  800193:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
  80019a:	8b 55 f4             	mov    -0xc(%ebp),%edx
  80019d:	81 fa 08 20 80 00    	cmp    $0x802008,%edx
  8001a3:	72 e2                	jb     800187 <dumbfork+0x62>
		duppage(envid, addr);

	// Also copy the stack we are currently running on.
	duppage(envid, ROUNDDOWN(&addr, PGSIZE));
  8001a5:	8d 45 f4             	lea    -0xc(%ebp),%eax
  8001a8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  8001ad:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001b1:	89 34 24             	mov    %esi,(%esp)
  8001b4:	e8 87 fe ff ff       	call   800040 <duppage>

	// Start the child environment running
	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0)
  8001b9:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
  8001c0:	00 
  8001c1:	89 34 24             	mov    %esi,(%esp)
  8001c4:	e8 14 0d 00 00       	call   800edd <sys_env_set_status>
  8001c9:	85 c0                	test   %eax,%eax
  8001cb:	79 20                	jns    8001ed <dumbfork+0xc8>
		panic("sys_env_set_status: %e", r);
  8001cd:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8001d1:	c7 44 24 08 f7 12 80 	movl   $0x8012f7,0x8(%esp)
  8001d8:	00 
  8001d9:	c7 44 24 04 4c 00 00 	movl   $0x4c,0x4(%esp)
  8001e0:	00 
  8001e1:	c7 04 24 b3 12 80 00 	movl   $0x8012b3,(%esp)
  8001e8:	e8 bd 00 00 00       	call   8002aa <_panic>

	return envid;
  8001ed:	89 f0                	mov    %esi,%eax
}
  8001ef:	83 c4 20             	add    $0x20,%esp
  8001f2:	5b                   	pop    %ebx
  8001f3:	5e                   	pop    %esi
  8001f4:	5d                   	pop    %ebp
  8001f5:	c3                   	ret    

008001f6 <umain>:

envid_t dumbfork(void);

void
umain(int argc, char **argv)
{
  8001f6:	55                   	push   %ebp
  8001f7:	89 e5                	mov    %esp,%ebp
  8001f9:	56                   	push   %esi
  8001fa:	53                   	push   %ebx
  8001fb:	83 ec 10             	sub    $0x10,%esp
	envid_t who;
	int i;

	// fork a child process
	who = dumbfork();
  8001fe:	e8 22 ff ff ff       	call   800125 <dumbfork>
  800203:	89 c6                	mov    %eax,%esi

	// print a message and yield to the other a few times
	for (i = 0; i < (who ? 10 : 20); i++) {
  800205:	bb 00 00 00 00       	mov    $0x0,%ebx
  80020a:	eb 28                	jmp    800234 <umain+0x3e>
		cprintf("%d: I am the %s!\n", i, who ? "parent" : "child");
  80020c:	b8 15 13 80 00       	mov    $0x801315,%eax
  800211:	eb 05                	jmp    800218 <umain+0x22>
  800213:	b8 0e 13 80 00       	mov    $0x80130e,%eax
  800218:	89 44 24 08          	mov    %eax,0x8(%esp)
  80021c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800220:	c7 04 24 1b 13 80 00 	movl   $0x80131b,(%esp)
  800227:	e8 77 01 00 00       	call   8003a3 <cprintf>
		sys_yield();
  80022c:	e8 93 0b 00 00       	call   800dc4 <sys_yield>

	// fork a child process
	who = dumbfork();

	// print a message and yield to the other a few times
	for (i = 0; i < (who ? 10 : 20); i++) {
  800231:	83 c3 01             	add    $0x1,%ebx
  800234:	85 f6                	test   %esi,%esi
  800236:	75 0a                	jne    800242 <umain+0x4c>
  800238:	83 fb 13             	cmp    $0x13,%ebx
  80023b:	7e cf                	jle    80020c <umain+0x16>
  80023d:	8d 76 00             	lea    0x0(%esi),%esi
  800240:	eb 05                	jmp    800247 <umain+0x51>
  800242:	83 fb 09             	cmp    $0x9,%ebx
  800245:	7e cc                	jle    800213 <umain+0x1d>
		cprintf("%d: I am the %s!\n", i, who ? "parent" : "child");
		sys_yield();
	}
}
  800247:	83 c4 10             	add    $0x10,%esp
  80024a:	5b                   	pop    %ebx
  80024b:	5e                   	pop    %esi
  80024c:	5d                   	pop    %ebp
  80024d:	c3                   	ret    

0080024e <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80024e:	55                   	push   %ebp
  80024f:	89 e5                	mov    %esp,%ebp
  800251:	56                   	push   %esi
  800252:	53                   	push   %ebx
  800253:	83 ec 10             	sub    $0x10,%esp
  800256:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800259:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	
	thisenv = (struct Env *) envs + ENVX(sys_getenvid());
  80025c:	e8 44 0b 00 00       	call   800da5 <sys_getenvid>
  800261:	25 ff 03 00 00       	and    $0x3ff,%eax
  800266:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800269:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80026e:	a3 04 20 80 00       	mov    %eax,0x802004
	//UENVS array
	//thisenv->env_link
	//thisenv = 0;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800273:	85 db                	test   %ebx,%ebx
  800275:	7e 07                	jle    80027e <libmain+0x30>
		binaryname = argv[0];
  800277:	8b 06                	mov    (%esi),%eax
  800279:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80027e:	89 74 24 04          	mov    %esi,0x4(%esp)
  800282:	89 1c 24             	mov    %ebx,(%esp)
  800285:	e8 6c ff ff ff       	call   8001f6 <umain>

	// exit gracefully
	exit();
  80028a:	e8 07 00 00 00       	call   800296 <exit>
}
  80028f:	83 c4 10             	add    $0x10,%esp
  800292:	5b                   	pop    %ebx
  800293:	5e                   	pop    %esi
  800294:	5d                   	pop    %ebp
  800295:	c3                   	ret    

00800296 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800296:	55                   	push   %ebp
  800297:	89 e5                	mov    %esp,%ebp
  800299:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80029c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8002a3:	e8 ab 0a 00 00       	call   800d53 <sys_env_destroy>
}
  8002a8:	c9                   	leave  
  8002a9:	c3                   	ret    

008002aa <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  8002aa:	55                   	push   %ebp
  8002ab:	89 e5                	mov    %esp,%ebp
  8002ad:	56                   	push   %esi
  8002ae:	53                   	push   %ebx
  8002af:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  8002b2:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  8002b5:	8b 35 00 20 80 00    	mov    0x802000,%esi
  8002bb:	e8 e5 0a 00 00       	call   800da5 <sys_getenvid>
  8002c0:	8b 55 0c             	mov    0xc(%ebp),%edx
  8002c3:	89 54 24 10          	mov    %edx,0x10(%esp)
  8002c7:	8b 55 08             	mov    0x8(%ebp),%edx
  8002ca:	89 54 24 0c          	mov    %edx,0xc(%esp)
  8002ce:	89 74 24 08          	mov    %esi,0x8(%esp)
  8002d2:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002d6:	c7 04 24 38 13 80 00 	movl   $0x801338,(%esp)
  8002dd:	e8 c1 00 00 00       	call   8003a3 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8002e2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8002e6:	8b 45 10             	mov    0x10(%ebp),%eax
  8002e9:	89 04 24             	mov    %eax,(%esp)
  8002ec:	e8 51 00 00 00       	call   800342 <vcprintf>
	cprintf("\n");
  8002f1:	c7 04 24 2b 13 80 00 	movl   $0x80132b,(%esp)
  8002f8:	e8 a6 00 00 00       	call   8003a3 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8002fd:	cc                   	int3   
  8002fe:	eb fd                	jmp    8002fd <_panic+0x53>

00800300 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  800300:	55                   	push   %ebp
  800301:	89 e5                	mov    %esp,%ebp
  800303:	53                   	push   %ebx
  800304:	83 ec 14             	sub    $0x14,%esp
  800307:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  80030a:	8b 13                	mov    (%ebx),%edx
  80030c:	8d 42 01             	lea    0x1(%edx),%eax
  80030f:	89 03                	mov    %eax,(%ebx)
  800311:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800314:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  800318:	3d ff 00 00 00       	cmp    $0xff,%eax
  80031d:	75 19                	jne    800338 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  80031f:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  800326:	00 
  800327:	8d 43 08             	lea    0x8(%ebx),%eax
  80032a:	89 04 24             	mov    %eax,(%esp)
  80032d:	e8 e4 09 00 00       	call   800d16 <sys_cputs>
		b->idx = 0;
  800332:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800338:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80033c:	83 c4 14             	add    $0x14,%esp
  80033f:	5b                   	pop    %ebx
  800340:	5d                   	pop    %ebp
  800341:	c3                   	ret    

00800342 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800342:	55                   	push   %ebp
  800343:	89 e5                	mov    %esp,%ebp
  800345:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  80034b:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800352:	00 00 00 
	b.cnt = 0;
  800355:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80035c:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80035f:	8b 45 0c             	mov    0xc(%ebp),%eax
  800362:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800366:	8b 45 08             	mov    0x8(%ebp),%eax
  800369:	89 44 24 08          	mov    %eax,0x8(%esp)
  80036d:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800373:	89 44 24 04          	mov    %eax,0x4(%esp)
  800377:	c7 04 24 00 03 80 00 	movl   $0x800300,(%esp)
  80037e:	e8 ab 01 00 00       	call   80052e <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800383:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800389:	89 44 24 04          	mov    %eax,0x4(%esp)
  80038d:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800393:	89 04 24             	mov    %eax,(%esp)
  800396:	e8 7b 09 00 00       	call   800d16 <sys_cputs>

	return b.cnt;
}
  80039b:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  8003a1:	c9                   	leave  
  8003a2:	c3                   	ret    

008003a3 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  8003a3:	55                   	push   %ebp
  8003a4:	89 e5                	mov    %esp,%ebp
  8003a6:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  8003a9:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  8003ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003b0:	8b 45 08             	mov    0x8(%ebp),%eax
  8003b3:	89 04 24             	mov    %eax,(%esp)
  8003b6:	e8 87 ff ff ff       	call   800342 <vcprintf>
	va_end(ap);

	return cnt;
}
  8003bb:	c9                   	leave  
  8003bc:	c3                   	ret    
  8003bd:	66 90                	xchg   %ax,%ax
  8003bf:	90                   	nop

008003c0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  8003c0:	55                   	push   %ebp
  8003c1:	89 e5                	mov    %esp,%ebp
  8003c3:	57                   	push   %edi
  8003c4:	56                   	push   %esi
  8003c5:	53                   	push   %ebx
  8003c6:	83 ec 3c             	sub    $0x3c,%esp
  8003c9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8003cc:	89 d7                	mov    %edx,%edi
  8003ce:	8b 45 08             	mov    0x8(%ebp),%eax
  8003d1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8003d4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003d7:	89 c3                	mov    %eax,%ebx
  8003d9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8003dc:	8b 45 10             	mov    0x10(%ebp),%eax
  8003df:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8003e2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8003e7:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8003ea:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8003ed:	39 d9                	cmp    %ebx,%ecx
  8003ef:	72 05                	jb     8003f6 <printnum+0x36>
  8003f1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8003f4:	77 69                	ja     80045f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8003f6:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8003f9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8003fd:	83 ee 01             	sub    $0x1,%esi
  800400:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800404:	89 44 24 08          	mov    %eax,0x8(%esp)
  800408:	8b 44 24 08          	mov    0x8(%esp),%eax
  80040c:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800410:	89 c3                	mov    %eax,%ebx
  800412:	89 d6                	mov    %edx,%esi
  800414:	8b 55 d8             	mov    -0x28(%ebp),%edx
  800417:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  80041a:	89 54 24 08          	mov    %edx,0x8(%esp)
  80041e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  800422:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800425:	89 04 24             	mov    %eax,(%esp)
  800428:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80042b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80042f:	e8 cc 0b 00 00       	call   801000 <__udivdi3>
  800434:	89 d9                	mov    %ebx,%ecx
  800436:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80043a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80043e:	89 04 24             	mov    %eax,(%esp)
  800441:	89 54 24 04          	mov    %edx,0x4(%esp)
  800445:	89 fa                	mov    %edi,%edx
  800447:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80044a:	e8 71 ff ff ff       	call   8003c0 <printnum>
  80044f:	eb 1b                	jmp    80046c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800451:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800455:	8b 45 18             	mov    0x18(%ebp),%eax
  800458:	89 04 24             	mov    %eax,(%esp)
  80045b:	ff d3                	call   *%ebx
  80045d:	eb 03                	jmp    800462 <printnum+0xa2>
  80045f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800462:	83 ee 01             	sub    $0x1,%esi
  800465:	85 f6                	test   %esi,%esi
  800467:	7f e8                	jg     800451 <printnum+0x91>
  800469:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80046c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800470:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800474:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800477:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80047a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80047e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800482:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800485:	89 04 24             	mov    %eax,(%esp)
  800488:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80048b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80048f:	e8 9c 0c 00 00       	call   801130 <__umoddi3>
  800494:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800498:	0f be 80 5c 13 80 00 	movsbl 0x80135c(%eax),%eax
  80049f:	89 04 24             	mov    %eax,(%esp)
  8004a2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8004a5:	ff d0                	call   *%eax
}
  8004a7:	83 c4 3c             	add    $0x3c,%esp
  8004aa:	5b                   	pop    %ebx
  8004ab:	5e                   	pop    %esi
  8004ac:	5f                   	pop    %edi
  8004ad:	5d                   	pop    %ebp
  8004ae:	c3                   	ret    

008004af <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  8004af:	55                   	push   %ebp
  8004b0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  8004b2:	83 fa 01             	cmp    $0x1,%edx
  8004b5:	7e 0e                	jle    8004c5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  8004b7:	8b 10                	mov    (%eax),%edx
  8004b9:	8d 4a 08             	lea    0x8(%edx),%ecx
  8004bc:	89 08                	mov    %ecx,(%eax)
  8004be:	8b 02                	mov    (%edx),%eax
  8004c0:	8b 52 04             	mov    0x4(%edx),%edx
  8004c3:	eb 22                	jmp    8004e7 <getuint+0x38>
	else if (lflag)
  8004c5:	85 d2                	test   %edx,%edx
  8004c7:	74 10                	je     8004d9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  8004c9:	8b 10                	mov    (%eax),%edx
  8004cb:	8d 4a 04             	lea    0x4(%edx),%ecx
  8004ce:	89 08                	mov    %ecx,(%eax)
  8004d0:	8b 02                	mov    (%edx),%eax
  8004d2:	ba 00 00 00 00       	mov    $0x0,%edx
  8004d7:	eb 0e                	jmp    8004e7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8004d9:	8b 10                	mov    (%eax),%edx
  8004db:	8d 4a 04             	lea    0x4(%edx),%ecx
  8004de:	89 08                	mov    %ecx,(%eax)
  8004e0:	8b 02                	mov    (%edx),%eax
  8004e2:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8004e7:	5d                   	pop    %ebp
  8004e8:	c3                   	ret    

008004e9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8004e9:	55                   	push   %ebp
  8004ea:	89 e5                	mov    %esp,%ebp
  8004ec:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8004ef:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8004f3:	8b 10                	mov    (%eax),%edx
  8004f5:	3b 50 04             	cmp    0x4(%eax),%edx
  8004f8:	73 0a                	jae    800504 <sprintputch+0x1b>
		*b->buf++ = ch;
  8004fa:	8d 4a 01             	lea    0x1(%edx),%ecx
  8004fd:	89 08                	mov    %ecx,(%eax)
  8004ff:	8b 45 08             	mov    0x8(%ebp),%eax
  800502:	88 02                	mov    %al,(%edx)
}
  800504:	5d                   	pop    %ebp
  800505:	c3                   	ret    

00800506 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  800506:	55                   	push   %ebp
  800507:	89 e5                	mov    %esp,%ebp
  800509:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  80050c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  80050f:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800513:	8b 45 10             	mov    0x10(%ebp),%eax
  800516:	89 44 24 08          	mov    %eax,0x8(%esp)
  80051a:	8b 45 0c             	mov    0xc(%ebp),%eax
  80051d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800521:	8b 45 08             	mov    0x8(%ebp),%eax
  800524:	89 04 24             	mov    %eax,(%esp)
  800527:	e8 02 00 00 00       	call   80052e <vprintfmt>
	va_end(ap);
}
  80052c:	c9                   	leave  
  80052d:	c3                   	ret    

0080052e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  80052e:	55                   	push   %ebp
  80052f:	89 e5                	mov    %esp,%ebp
  800531:	57                   	push   %edi
  800532:	56                   	push   %esi
  800533:	53                   	push   %ebx
  800534:	83 ec 3c             	sub    $0x3c,%esp
  800537:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80053a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80053d:	eb 14                	jmp    800553 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80053f:	85 c0                	test   %eax,%eax
  800541:	0f 84 b3 03 00 00    	je     8008fa <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  800547:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80054b:	89 04 24             	mov    %eax,(%esp)
  80054e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800551:	89 f3                	mov    %esi,%ebx
  800553:	8d 73 01             	lea    0x1(%ebx),%esi
  800556:	0f b6 03             	movzbl (%ebx),%eax
  800559:	83 f8 25             	cmp    $0x25,%eax
  80055c:	75 e1                	jne    80053f <vprintfmt+0x11>
  80055e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800562:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800569:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800570:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800577:	ba 00 00 00 00       	mov    $0x0,%edx
  80057c:	eb 1d                	jmp    80059b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80057e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  800580:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800584:	eb 15                	jmp    80059b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800586:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800588:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80058c:	eb 0d                	jmp    80059b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80058e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800591:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800594:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80059b:	8d 5e 01             	lea    0x1(%esi),%ebx
  80059e:	0f b6 0e             	movzbl (%esi),%ecx
  8005a1:	0f b6 c1             	movzbl %cl,%eax
  8005a4:	83 e9 23             	sub    $0x23,%ecx
  8005a7:	80 f9 55             	cmp    $0x55,%cl
  8005aa:	0f 87 2a 03 00 00    	ja     8008da <vprintfmt+0x3ac>
  8005b0:	0f b6 c9             	movzbl %cl,%ecx
  8005b3:	ff 24 8d 20 14 80 00 	jmp    *0x801420(,%ecx,4)
  8005ba:	89 de                	mov    %ebx,%esi
  8005bc:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  8005c1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  8005c4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  8005c8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  8005cb:	8d 58 d0             	lea    -0x30(%eax),%ebx
  8005ce:	83 fb 09             	cmp    $0x9,%ebx
  8005d1:	77 36                	ja     800609 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8005d3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8005d6:	eb e9                	jmp    8005c1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8005d8:	8b 45 14             	mov    0x14(%ebp),%eax
  8005db:	8d 48 04             	lea    0x4(%eax),%ecx
  8005de:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8005e1:	8b 00                	mov    (%eax),%eax
  8005e3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005e6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8005e8:	eb 22                	jmp    80060c <vprintfmt+0xde>
  8005ea:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8005ed:	85 c9                	test   %ecx,%ecx
  8005ef:	b8 00 00 00 00       	mov    $0x0,%eax
  8005f4:	0f 49 c1             	cmovns %ecx,%eax
  8005f7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8005fa:	89 de                	mov    %ebx,%esi
  8005fc:	eb 9d                	jmp    80059b <vprintfmt+0x6d>
  8005fe:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  800600:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  800607:	eb 92                	jmp    80059b <vprintfmt+0x6d>
  800609:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  80060c:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  800610:	79 89                	jns    80059b <vprintfmt+0x6d>
  800612:	e9 77 ff ff ff       	jmp    80058e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  800617:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80061a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  80061c:	e9 7a ff ff ff       	jmp    80059b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  800621:	8b 45 14             	mov    0x14(%ebp),%eax
  800624:	8d 50 04             	lea    0x4(%eax),%edx
  800627:	89 55 14             	mov    %edx,0x14(%ebp)
  80062a:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80062e:	8b 00                	mov    (%eax),%eax
  800630:	89 04 24             	mov    %eax,(%esp)
  800633:	ff 55 08             	call   *0x8(%ebp)
			break;
  800636:	e9 18 ff ff ff       	jmp    800553 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80063b:	8b 45 14             	mov    0x14(%ebp),%eax
  80063e:	8d 50 04             	lea    0x4(%eax),%edx
  800641:	89 55 14             	mov    %edx,0x14(%ebp)
  800644:	8b 00                	mov    (%eax),%eax
  800646:	99                   	cltd   
  800647:	31 d0                	xor    %edx,%eax
  800649:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80064b:	83 f8 09             	cmp    $0x9,%eax
  80064e:	7f 0b                	jg     80065b <vprintfmt+0x12d>
  800650:	8b 14 85 80 15 80 00 	mov    0x801580(,%eax,4),%edx
  800657:	85 d2                	test   %edx,%edx
  800659:	75 20                	jne    80067b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  80065b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80065f:	c7 44 24 08 74 13 80 	movl   $0x801374,0x8(%esp)
  800666:	00 
  800667:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80066b:	8b 45 08             	mov    0x8(%ebp),%eax
  80066e:	89 04 24             	mov    %eax,(%esp)
  800671:	e8 90 fe ff ff       	call   800506 <printfmt>
  800676:	e9 d8 fe ff ff       	jmp    800553 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80067b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80067f:	c7 44 24 08 7d 13 80 	movl   $0x80137d,0x8(%esp)
  800686:	00 
  800687:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80068b:	8b 45 08             	mov    0x8(%ebp),%eax
  80068e:	89 04 24             	mov    %eax,(%esp)
  800691:	e8 70 fe ff ff       	call   800506 <printfmt>
  800696:	e9 b8 fe ff ff       	jmp    800553 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80069b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  80069e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8006a1:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  8006a4:	8b 45 14             	mov    0x14(%ebp),%eax
  8006a7:	8d 50 04             	lea    0x4(%eax),%edx
  8006aa:	89 55 14             	mov    %edx,0x14(%ebp)
  8006ad:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  8006af:	85 f6                	test   %esi,%esi
  8006b1:	b8 6d 13 80 00       	mov    $0x80136d,%eax
  8006b6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  8006b9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  8006bd:	0f 84 97 00 00 00    	je     80075a <vprintfmt+0x22c>
  8006c3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  8006c7:	0f 8e 9b 00 00 00    	jle    800768 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  8006cd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8006d1:	89 34 24             	mov    %esi,(%esp)
  8006d4:	e8 cf 02 00 00       	call   8009a8 <strnlen>
  8006d9:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8006dc:	29 c2                	sub    %eax,%edx
  8006de:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  8006e1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8006e5:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8006e8:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8006eb:	8b 75 08             	mov    0x8(%ebp),%esi
  8006ee:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8006f1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8006f3:	eb 0f                	jmp    800704 <vprintfmt+0x1d6>
					putch(padc, putdat);
  8006f5:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006f9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8006fc:	89 04 24             	mov    %eax,(%esp)
  8006ff:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  800701:	83 eb 01             	sub    $0x1,%ebx
  800704:	85 db                	test   %ebx,%ebx
  800706:	7f ed                	jg     8006f5 <vprintfmt+0x1c7>
  800708:	8b 75 d8             	mov    -0x28(%ebp),%esi
  80070b:	8b 55 d0             	mov    -0x30(%ebp),%edx
  80070e:	85 d2                	test   %edx,%edx
  800710:	b8 00 00 00 00       	mov    $0x0,%eax
  800715:	0f 49 c2             	cmovns %edx,%eax
  800718:	29 c2                	sub    %eax,%edx
  80071a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80071d:	89 d7                	mov    %edx,%edi
  80071f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800722:	eb 50                	jmp    800774 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  800724:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  800728:	74 1e                	je     800748 <vprintfmt+0x21a>
  80072a:	0f be d2             	movsbl %dl,%edx
  80072d:	83 ea 20             	sub    $0x20,%edx
  800730:	83 fa 5e             	cmp    $0x5e,%edx
  800733:	76 13                	jbe    800748 <vprintfmt+0x21a>
					putch('?', putdat);
  800735:	8b 45 0c             	mov    0xc(%ebp),%eax
  800738:	89 44 24 04          	mov    %eax,0x4(%esp)
  80073c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800743:	ff 55 08             	call   *0x8(%ebp)
  800746:	eb 0d                	jmp    800755 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  800748:	8b 55 0c             	mov    0xc(%ebp),%edx
  80074b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80074f:	89 04 24             	mov    %eax,(%esp)
  800752:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800755:	83 ef 01             	sub    $0x1,%edi
  800758:	eb 1a                	jmp    800774 <vprintfmt+0x246>
  80075a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80075d:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800760:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800763:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800766:	eb 0c                	jmp    800774 <vprintfmt+0x246>
  800768:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80076b:	8b 7d dc             	mov    -0x24(%ebp),%edi
  80076e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800771:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800774:	83 c6 01             	add    $0x1,%esi
  800777:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  80077b:	0f be c2             	movsbl %dl,%eax
  80077e:	85 c0                	test   %eax,%eax
  800780:	74 27                	je     8007a9 <vprintfmt+0x27b>
  800782:	85 db                	test   %ebx,%ebx
  800784:	78 9e                	js     800724 <vprintfmt+0x1f6>
  800786:	83 eb 01             	sub    $0x1,%ebx
  800789:	79 99                	jns    800724 <vprintfmt+0x1f6>
  80078b:	89 f8                	mov    %edi,%eax
  80078d:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800790:	8b 75 08             	mov    0x8(%ebp),%esi
  800793:	89 c3                	mov    %eax,%ebx
  800795:	eb 1a                	jmp    8007b1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800797:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80079b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  8007a2:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  8007a4:	83 eb 01             	sub    $0x1,%ebx
  8007a7:	eb 08                	jmp    8007b1 <vprintfmt+0x283>
  8007a9:	89 fb                	mov    %edi,%ebx
  8007ab:	8b 75 08             	mov    0x8(%ebp),%esi
  8007ae:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8007b1:	85 db                	test   %ebx,%ebx
  8007b3:	7f e2                	jg     800797 <vprintfmt+0x269>
  8007b5:	89 75 08             	mov    %esi,0x8(%ebp)
  8007b8:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8007bb:	e9 93 fd ff ff       	jmp    800553 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  8007c0:	83 fa 01             	cmp    $0x1,%edx
  8007c3:	7e 16                	jle    8007db <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  8007c5:	8b 45 14             	mov    0x14(%ebp),%eax
  8007c8:	8d 50 08             	lea    0x8(%eax),%edx
  8007cb:	89 55 14             	mov    %edx,0x14(%ebp)
  8007ce:	8b 50 04             	mov    0x4(%eax),%edx
  8007d1:	8b 00                	mov    (%eax),%eax
  8007d3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8007d6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8007d9:	eb 32                	jmp    80080d <vprintfmt+0x2df>
	else if (lflag)
  8007db:	85 d2                	test   %edx,%edx
  8007dd:	74 18                	je     8007f7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  8007df:	8b 45 14             	mov    0x14(%ebp),%eax
  8007e2:	8d 50 04             	lea    0x4(%eax),%edx
  8007e5:	89 55 14             	mov    %edx,0x14(%ebp)
  8007e8:	8b 30                	mov    (%eax),%esi
  8007ea:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8007ed:	89 f0                	mov    %esi,%eax
  8007ef:	c1 f8 1f             	sar    $0x1f,%eax
  8007f2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8007f5:	eb 16                	jmp    80080d <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  8007f7:	8b 45 14             	mov    0x14(%ebp),%eax
  8007fa:	8d 50 04             	lea    0x4(%eax),%edx
  8007fd:	89 55 14             	mov    %edx,0x14(%ebp)
  800800:	8b 30                	mov    (%eax),%esi
  800802:	89 75 e0             	mov    %esi,-0x20(%ebp)
  800805:	89 f0                	mov    %esi,%eax
  800807:	c1 f8 1f             	sar    $0x1f,%eax
  80080a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  80080d:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800810:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  800813:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  800818:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  80081c:	0f 89 80 00 00 00    	jns    8008a2 <vprintfmt+0x374>
				putch('-', putdat);
  800822:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800826:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  80082d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  800830:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800833:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800836:	f7 d8                	neg    %eax
  800838:	83 d2 00             	adc    $0x0,%edx
  80083b:	f7 da                	neg    %edx
			}
			base = 10;
  80083d:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800842:	eb 5e                	jmp    8008a2 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800844:	8d 45 14             	lea    0x14(%ebp),%eax
  800847:	e8 63 fc ff ff       	call   8004af <getuint>
			base = 10;
  80084c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800851:	eb 4f                	jmp    8008a2 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800853:	8d 45 14             	lea    0x14(%ebp),%eax
  800856:	e8 54 fc ff ff       	call   8004af <getuint>
			base = 8;
  80085b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800860:	eb 40                	jmp    8008a2 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
  800862:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800866:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80086d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800870:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800874:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80087b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80087e:	8b 45 14             	mov    0x14(%ebp),%eax
  800881:	8d 50 04             	lea    0x4(%eax),%edx
  800884:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800887:	8b 00                	mov    (%eax),%eax
  800889:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80088e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800893:	eb 0d                	jmp    8008a2 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800895:	8d 45 14             	lea    0x14(%ebp),%eax
  800898:	e8 12 fc ff ff       	call   8004af <getuint>
			base = 16;
  80089d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  8008a2:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  8008a6:	89 74 24 10          	mov    %esi,0x10(%esp)
  8008aa:	8b 75 dc             	mov    -0x24(%ebp),%esi
  8008ad:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8008b1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8008b5:	89 04 24             	mov    %eax,(%esp)
  8008b8:	89 54 24 04          	mov    %edx,0x4(%esp)
  8008bc:	89 fa                	mov    %edi,%edx
  8008be:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c1:	e8 fa fa ff ff       	call   8003c0 <printnum>
			break;
  8008c6:	e9 88 fc ff ff       	jmp    800553 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  8008cb:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8008cf:	89 04 24             	mov    %eax,(%esp)
  8008d2:	ff 55 08             	call   *0x8(%ebp)
			break;
  8008d5:	e9 79 fc ff ff       	jmp    800553 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8008da:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8008de:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8008e5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8008e8:	89 f3                	mov    %esi,%ebx
  8008ea:	eb 03                	jmp    8008ef <vprintfmt+0x3c1>
  8008ec:	83 eb 01             	sub    $0x1,%ebx
  8008ef:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8008f3:	75 f7                	jne    8008ec <vprintfmt+0x3be>
  8008f5:	e9 59 fc ff ff       	jmp    800553 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8008fa:	83 c4 3c             	add    $0x3c,%esp
  8008fd:	5b                   	pop    %ebx
  8008fe:	5e                   	pop    %esi
  8008ff:	5f                   	pop    %edi
  800900:	5d                   	pop    %ebp
  800901:	c3                   	ret    

00800902 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  800902:	55                   	push   %ebp
  800903:	89 e5                	mov    %esp,%ebp
  800905:	83 ec 28             	sub    $0x28,%esp
  800908:	8b 45 08             	mov    0x8(%ebp),%eax
  80090b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  80090e:	89 45 ec             	mov    %eax,-0x14(%ebp)
  800911:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  800915:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  800918:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  80091f:	85 c0                	test   %eax,%eax
  800921:	74 30                	je     800953 <vsnprintf+0x51>
  800923:	85 d2                	test   %edx,%edx
  800925:	7e 2c                	jle    800953 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  800927:	8b 45 14             	mov    0x14(%ebp),%eax
  80092a:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80092e:	8b 45 10             	mov    0x10(%ebp),%eax
  800931:	89 44 24 08          	mov    %eax,0x8(%esp)
  800935:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800938:	89 44 24 04          	mov    %eax,0x4(%esp)
  80093c:	c7 04 24 e9 04 80 00 	movl   $0x8004e9,(%esp)
  800943:	e8 e6 fb ff ff       	call   80052e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800948:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80094b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  80094e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800951:	eb 05                	jmp    800958 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800953:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800958:	c9                   	leave  
  800959:	c3                   	ret    

0080095a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80095a:	55                   	push   %ebp
  80095b:	89 e5                	mov    %esp,%ebp
  80095d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800960:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800963:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800967:	8b 45 10             	mov    0x10(%ebp),%eax
  80096a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80096e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800971:	89 44 24 04          	mov    %eax,0x4(%esp)
  800975:	8b 45 08             	mov    0x8(%ebp),%eax
  800978:	89 04 24             	mov    %eax,(%esp)
  80097b:	e8 82 ff ff ff       	call   800902 <vsnprintf>
	va_end(ap);

	return rc;
}
  800980:	c9                   	leave  
  800981:	c3                   	ret    
  800982:	66 90                	xchg   %ax,%ax
  800984:	66 90                	xchg   %ax,%ax
  800986:	66 90                	xchg   %ax,%ax
  800988:	66 90                	xchg   %ax,%ax
  80098a:	66 90                	xchg   %ax,%ax
  80098c:	66 90                	xchg   %ax,%ax
  80098e:	66 90                	xchg   %ax,%ax

00800990 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800990:	55                   	push   %ebp
  800991:	89 e5                	mov    %esp,%ebp
  800993:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800996:	b8 00 00 00 00       	mov    $0x0,%eax
  80099b:	eb 03                	jmp    8009a0 <strlen+0x10>
		n++;
  80099d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  8009a0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  8009a4:	75 f7                	jne    80099d <strlen+0xd>
		n++;
	return n;
}
  8009a6:	5d                   	pop    %ebp
  8009a7:	c3                   	ret    

008009a8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  8009a8:	55                   	push   %ebp
  8009a9:	89 e5                	mov    %esp,%ebp
  8009ab:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8009ae:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8009b1:	b8 00 00 00 00       	mov    $0x0,%eax
  8009b6:	eb 03                	jmp    8009bb <strnlen+0x13>
		n++;
  8009b8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  8009bb:	39 d0                	cmp    %edx,%eax
  8009bd:	74 06                	je     8009c5 <strnlen+0x1d>
  8009bf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  8009c3:	75 f3                	jne    8009b8 <strnlen+0x10>
		n++;
	return n;
}
  8009c5:	5d                   	pop    %ebp
  8009c6:	c3                   	ret    

008009c7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  8009c7:	55                   	push   %ebp
  8009c8:	89 e5                	mov    %esp,%ebp
  8009ca:	53                   	push   %ebx
  8009cb:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ce:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8009d1:	89 c2                	mov    %eax,%edx
  8009d3:	83 c2 01             	add    $0x1,%edx
  8009d6:	83 c1 01             	add    $0x1,%ecx
  8009d9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8009dd:	88 5a ff             	mov    %bl,-0x1(%edx)
  8009e0:	84 db                	test   %bl,%bl
  8009e2:	75 ef                	jne    8009d3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8009e4:	5b                   	pop    %ebx
  8009e5:	5d                   	pop    %ebp
  8009e6:	c3                   	ret    

008009e7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8009e7:	55                   	push   %ebp
  8009e8:	89 e5                	mov    %esp,%ebp
  8009ea:	53                   	push   %ebx
  8009eb:	83 ec 08             	sub    $0x8,%esp
  8009ee:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8009f1:	89 1c 24             	mov    %ebx,(%esp)
  8009f4:	e8 97 ff ff ff       	call   800990 <strlen>
	strcpy(dst + len, src);
  8009f9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8009fc:	89 54 24 04          	mov    %edx,0x4(%esp)
  800a00:	01 d8                	add    %ebx,%eax
  800a02:	89 04 24             	mov    %eax,(%esp)
  800a05:	e8 bd ff ff ff       	call   8009c7 <strcpy>
	return dst;
}
  800a0a:	89 d8                	mov    %ebx,%eax
  800a0c:	83 c4 08             	add    $0x8,%esp
  800a0f:	5b                   	pop    %ebx
  800a10:	5d                   	pop    %ebp
  800a11:	c3                   	ret    

00800a12 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800a12:	55                   	push   %ebp
  800a13:	89 e5                	mov    %esp,%ebp
  800a15:	56                   	push   %esi
  800a16:	53                   	push   %ebx
  800a17:	8b 75 08             	mov    0x8(%ebp),%esi
  800a1a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800a1d:	89 f3                	mov    %esi,%ebx
  800a1f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800a22:	89 f2                	mov    %esi,%edx
  800a24:	eb 0f                	jmp    800a35 <strncpy+0x23>
		*dst++ = *src;
  800a26:	83 c2 01             	add    $0x1,%edx
  800a29:	0f b6 01             	movzbl (%ecx),%eax
  800a2c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800a2f:	80 39 01             	cmpb   $0x1,(%ecx)
  800a32:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800a35:	39 da                	cmp    %ebx,%edx
  800a37:	75 ed                	jne    800a26 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800a39:	89 f0                	mov    %esi,%eax
  800a3b:	5b                   	pop    %ebx
  800a3c:	5e                   	pop    %esi
  800a3d:	5d                   	pop    %ebp
  800a3e:	c3                   	ret    

00800a3f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800a3f:	55                   	push   %ebp
  800a40:	89 e5                	mov    %esp,%ebp
  800a42:	56                   	push   %esi
  800a43:	53                   	push   %ebx
  800a44:	8b 75 08             	mov    0x8(%ebp),%esi
  800a47:	8b 55 0c             	mov    0xc(%ebp),%edx
  800a4a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800a4d:	89 f0                	mov    %esi,%eax
  800a4f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800a53:	85 c9                	test   %ecx,%ecx
  800a55:	75 0b                	jne    800a62 <strlcpy+0x23>
  800a57:	eb 1d                	jmp    800a76 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800a59:	83 c0 01             	add    $0x1,%eax
  800a5c:	83 c2 01             	add    $0x1,%edx
  800a5f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800a62:	39 d8                	cmp    %ebx,%eax
  800a64:	74 0b                	je     800a71 <strlcpy+0x32>
  800a66:	0f b6 0a             	movzbl (%edx),%ecx
  800a69:	84 c9                	test   %cl,%cl
  800a6b:	75 ec                	jne    800a59 <strlcpy+0x1a>
  800a6d:	89 c2                	mov    %eax,%edx
  800a6f:	eb 02                	jmp    800a73 <strlcpy+0x34>
  800a71:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800a73:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800a76:	29 f0                	sub    %esi,%eax
}
  800a78:	5b                   	pop    %ebx
  800a79:	5e                   	pop    %esi
  800a7a:	5d                   	pop    %ebp
  800a7b:	c3                   	ret    

00800a7c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800a7c:	55                   	push   %ebp
  800a7d:	89 e5                	mov    %esp,%ebp
  800a7f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a82:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800a85:	eb 06                	jmp    800a8d <strcmp+0x11>
		p++, q++;
  800a87:	83 c1 01             	add    $0x1,%ecx
  800a8a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800a8d:	0f b6 01             	movzbl (%ecx),%eax
  800a90:	84 c0                	test   %al,%al
  800a92:	74 04                	je     800a98 <strcmp+0x1c>
  800a94:	3a 02                	cmp    (%edx),%al
  800a96:	74 ef                	je     800a87 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800a98:	0f b6 c0             	movzbl %al,%eax
  800a9b:	0f b6 12             	movzbl (%edx),%edx
  800a9e:	29 d0                	sub    %edx,%eax
}
  800aa0:	5d                   	pop    %ebp
  800aa1:	c3                   	ret    

00800aa2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800aa2:	55                   	push   %ebp
  800aa3:	89 e5                	mov    %esp,%ebp
  800aa5:	53                   	push   %ebx
  800aa6:	8b 45 08             	mov    0x8(%ebp),%eax
  800aa9:	8b 55 0c             	mov    0xc(%ebp),%edx
  800aac:	89 c3                	mov    %eax,%ebx
  800aae:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800ab1:	eb 06                	jmp    800ab9 <strncmp+0x17>
		n--, p++, q++;
  800ab3:	83 c0 01             	add    $0x1,%eax
  800ab6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800ab9:	39 d8                	cmp    %ebx,%eax
  800abb:	74 15                	je     800ad2 <strncmp+0x30>
  800abd:	0f b6 08             	movzbl (%eax),%ecx
  800ac0:	84 c9                	test   %cl,%cl
  800ac2:	74 04                	je     800ac8 <strncmp+0x26>
  800ac4:	3a 0a                	cmp    (%edx),%cl
  800ac6:	74 eb                	je     800ab3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800ac8:	0f b6 00             	movzbl (%eax),%eax
  800acb:	0f b6 12             	movzbl (%edx),%edx
  800ace:	29 d0                	sub    %edx,%eax
  800ad0:	eb 05                	jmp    800ad7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800ad2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800ad7:	5b                   	pop    %ebx
  800ad8:	5d                   	pop    %ebp
  800ad9:	c3                   	ret    

00800ada <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800ada:	55                   	push   %ebp
  800adb:	89 e5                	mov    %esp,%ebp
  800add:	8b 45 08             	mov    0x8(%ebp),%eax
  800ae0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800ae4:	eb 07                	jmp    800aed <strchr+0x13>
		if (*s == c)
  800ae6:	38 ca                	cmp    %cl,%dl
  800ae8:	74 0f                	je     800af9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800aea:	83 c0 01             	add    $0x1,%eax
  800aed:	0f b6 10             	movzbl (%eax),%edx
  800af0:	84 d2                	test   %dl,%dl
  800af2:	75 f2                	jne    800ae6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800af4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800af9:	5d                   	pop    %ebp
  800afa:	c3                   	ret    

00800afb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800afb:	55                   	push   %ebp
  800afc:	89 e5                	mov    %esp,%ebp
  800afe:	8b 45 08             	mov    0x8(%ebp),%eax
  800b01:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800b05:	eb 07                	jmp    800b0e <strfind+0x13>
		if (*s == c)
  800b07:	38 ca                	cmp    %cl,%dl
  800b09:	74 0a                	je     800b15 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800b0b:	83 c0 01             	add    $0x1,%eax
  800b0e:	0f b6 10             	movzbl (%eax),%edx
  800b11:	84 d2                	test   %dl,%dl
  800b13:	75 f2                	jne    800b07 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800b15:	5d                   	pop    %ebp
  800b16:	c3                   	ret    

00800b17 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800b17:	55                   	push   %ebp
  800b18:	89 e5                	mov    %esp,%ebp
  800b1a:	57                   	push   %edi
  800b1b:	56                   	push   %esi
  800b1c:	53                   	push   %ebx
  800b1d:	8b 7d 08             	mov    0x8(%ebp),%edi
  800b20:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800b23:	85 c9                	test   %ecx,%ecx
  800b25:	74 36                	je     800b5d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800b27:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800b2d:	75 28                	jne    800b57 <memset+0x40>
  800b2f:	f6 c1 03             	test   $0x3,%cl
  800b32:	75 23                	jne    800b57 <memset+0x40>
		c &= 0xFF;
  800b34:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800b38:	89 d3                	mov    %edx,%ebx
  800b3a:	c1 e3 08             	shl    $0x8,%ebx
  800b3d:	89 d6                	mov    %edx,%esi
  800b3f:	c1 e6 18             	shl    $0x18,%esi
  800b42:	89 d0                	mov    %edx,%eax
  800b44:	c1 e0 10             	shl    $0x10,%eax
  800b47:	09 f0                	or     %esi,%eax
  800b49:	09 c2                	or     %eax,%edx
  800b4b:	89 d0                	mov    %edx,%eax
  800b4d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800b4f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800b52:	fc                   	cld    
  800b53:	f3 ab                	rep stos %eax,%es:(%edi)
  800b55:	eb 06                	jmp    800b5d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800b57:	8b 45 0c             	mov    0xc(%ebp),%eax
  800b5a:	fc                   	cld    
  800b5b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800b5d:	89 f8                	mov    %edi,%eax
  800b5f:	5b                   	pop    %ebx
  800b60:	5e                   	pop    %esi
  800b61:	5f                   	pop    %edi
  800b62:	5d                   	pop    %ebp
  800b63:	c3                   	ret    

00800b64 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800b64:	55                   	push   %ebp
  800b65:	89 e5                	mov    %esp,%ebp
  800b67:	57                   	push   %edi
  800b68:	56                   	push   %esi
  800b69:	8b 45 08             	mov    0x8(%ebp),%eax
  800b6c:	8b 75 0c             	mov    0xc(%ebp),%esi
  800b6f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800b72:	39 c6                	cmp    %eax,%esi
  800b74:	73 35                	jae    800bab <memmove+0x47>
  800b76:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800b79:	39 d0                	cmp    %edx,%eax
  800b7b:	73 2e                	jae    800bab <memmove+0x47>
		s += n;
		d += n;
  800b7d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800b80:	89 d6                	mov    %edx,%esi
  800b82:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800b84:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800b8a:	75 13                	jne    800b9f <memmove+0x3b>
  800b8c:	f6 c1 03             	test   $0x3,%cl
  800b8f:	75 0e                	jne    800b9f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800b91:	83 ef 04             	sub    $0x4,%edi
  800b94:	8d 72 fc             	lea    -0x4(%edx),%esi
  800b97:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800b9a:	fd                   	std    
  800b9b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800b9d:	eb 09                	jmp    800ba8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800b9f:	83 ef 01             	sub    $0x1,%edi
  800ba2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800ba5:	fd                   	std    
  800ba6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800ba8:	fc                   	cld    
  800ba9:	eb 1d                	jmp    800bc8 <memmove+0x64>
  800bab:	89 f2                	mov    %esi,%edx
  800bad:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800baf:	f6 c2 03             	test   $0x3,%dl
  800bb2:	75 0f                	jne    800bc3 <memmove+0x5f>
  800bb4:	f6 c1 03             	test   $0x3,%cl
  800bb7:	75 0a                	jne    800bc3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800bb9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800bbc:	89 c7                	mov    %eax,%edi
  800bbe:	fc                   	cld    
  800bbf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800bc1:	eb 05                	jmp    800bc8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800bc3:	89 c7                	mov    %eax,%edi
  800bc5:	fc                   	cld    
  800bc6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800bc8:	5e                   	pop    %esi
  800bc9:	5f                   	pop    %edi
  800bca:	5d                   	pop    %ebp
  800bcb:	c3                   	ret    

00800bcc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800bcc:	55                   	push   %ebp
  800bcd:	89 e5                	mov    %esp,%ebp
  800bcf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800bd2:	8b 45 10             	mov    0x10(%ebp),%eax
  800bd5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800bd9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800bdc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800be0:	8b 45 08             	mov    0x8(%ebp),%eax
  800be3:	89 04 24             	mov    %eax,(%esp)
  800be6:	e8 79 ff ff ff       	call   800b64 <memmove>
}
  800beb:	c9                   	leave  
  800bec:	c3                   	ret    

00800bed <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800bed:	55                   	push   %ebp
  800bee:	89 e5                	mov    %esp,%ebp
  800bf0:	56                   	push   %esi
  800bf1:	53                   	push   %ebx
  800bf2:	8b 55 08             	mov    0x8(%ebp),%edx
  800bf5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800bf8:	89 d6                	mov    %edx,%esi
  800bfa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800bfd:	eb 1a                	jmp    800c19 <memcmp+0x2c>
		if (*s1 != *s2)
  800bff:	0f b6 02             	movzbl (%edx),%eax
  800c02:	0f b6 19             	movzbl (%ecx),%ebx
  800c05:	38 d8                	cmp    %bl,%al
  800c07:	74 0a                	je     800c13 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800c09:	0f b6 c0             	movzbl %al,%eax
  800c0c:	0f b6 db             	movzbl %bl,%ebx
  800c0f:	29 d8                	sub    %ebx,%eax
  800c11:	eb 0f                	jmp    800c22 <memcmp+0x35>
		s1++, s2++;
  800c13:	83 c2 01             	add    $0x1,%edx
  800c16:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800c19:	39 f2                	cmp    %esi,%edx
  800c1b:	75 e2                	jne    800bff <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800c1d:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800c22:	5b                   	pop    %ebx
  800c23:	5e                   	pop    %esi
  800c24:	5d                   	pop    %ebp
  800c25:	c3                   	ret    

00800c26 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800c26:	55                   	push   %ebp
  800c27:	89 e5                	mov    %esp,%ebp
  800c29:	8b 45 08             	mov    0x8(%ebp),%eax
  800c2c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800c2f:	89 c2                	mov    %eax,%edx
  800c31:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800c34:	eb 07                	jmp    800c3d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800c36:	38 08                	cmp    %cl,(%eax)
  800c38:	74 07                	je     800c41 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800c3a:	83 c0 01             	add    $0x1,%eax
  800c3d:	39 d0                	cmp    %edx,%eax
  800c3f:	72 f5                	jb     800c36 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800c41:	5d                   	pop    %ebp
  800c42:	c3                   	ret    

00800c43 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800c43:	55                   	push   %ebp
  800c44:	89 e5                	mov    %esp,%ebp
  800c46:	57                   	push   %edi
  800c47:	56                   	push   %esi
  800c48:	53                   	push   %ebx
  800c49:	8b 55 08             	mov    0x8(%ebp),%edx
  800c4c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c4f:	eb 03                	jmp    800c54 <strtol+0x11>
		s++;
  800c51:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800c54:	0f b6 0a             	movzbl (%edx),%ecx
  800c57:	80 f9 09             	cmp    $0x9,%cl
  800c5a:	74 f5                	je     800c51 <strtol+0xe>
  800c5c:	80 f9 20             	cmp    $0x20,%cl
  800c5f:	74 f0                	je     800c51 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800c61:	80 f9 2b             	cmp    $0x2b,%cl
  800c64:	75 0a                	jne    800c70 <strtol+0x2d>
		s++;
  800c66:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800c69:	bf 00 00 00 00       	mov    $0x0,%edi
  800c6e:	eb 11                	jmp    800c81 <strtol+0x3e>
  800c70:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800c75:	80 f9 2d             	cmp    $0x2d,%cl
  800c78:	75 07                	jne    800c81 <strtol+0x3e>
		s++, neg = 1;
  800c7a:	8d 52 01             	lea    0x1(%edx),%edx
  800c7d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800c81:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800c86:	75 15                	jne    800c9d <strtol+0x5a>
  800c88:	80 3a 30             	cmpb   $0x30,(%edx)
  800c8b:	75 10                	jne    800c9d <strtol+0x5a>
  800c8d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800c91:	75 0a                	jne    800c9d <strtol+0x5a>
		s += 2, base = 16;
  800c93:	83 c2 02             	add    $0x2,%edx
  800c96:	b8 10 00 00 00       	mov    $0x10,%eax
  800c9b:	eb 10                	jmp    800cad <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800c9d:	85 c0                	test   %eax,%eax
  800c9f:	75 0c                	jne    800cad <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800ca1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800ca3:	80 3a 30             	cmpb   $0x30,(%edx)
  800ca6:	75 05                	jne    800cad <strtol+0x6a>
		s++, base = 8;
  800ca8:	83 c2 01             	add    $0x1,%edx
  800cab:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800cad:	bb 00 00 00 00       	mov    $0x0,%ebx
  800cb2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800cb5:	0f b6 0a             	movzbl (%edx),%ecx
  800cb8:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800cbb:	89 f0                	mov    %esi,%eax
  800cbd:	3c 09                	cmp    $0x9,%al
  800cbf:	77 08                	ja     800cc9 <strtol+0x86>
			dig = *s - '0';
  800cc1:	0f be c9             	movsbl %cl,%ecx
  800cc4:	83 e9 30             	sub    $0x30,%ecx
  800cc7:	eb 20                	jmp    800ce9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800cc9:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800ccc:	89 f0                	mov    %esi,%eax
  800cce:	3c 19                	cmp    $0x19,%al
  800cd0:	77 08                	ja     800cda <strtol+0x97>
			dig = *s - 'a' + 10;
  800cd2:	0f be c9             	movsbl %cl,%ecx
  800cd5:	83 e9 57             	sub    $0x57,%ecx
  800cd8:	eb 0f                	jmp    800ce9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800cda:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800cdd:	89 f0                	mov    %esi,%eax
  800cdf:	3c 19                	cmp    $0x19,%al
  800ce1:	77 16                	ja     800cf9 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800ce3:	0f be c9             	movsbl %cl,%ecx
  800ce6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800ce9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800cec:	7d 0f                	jge    800cfd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800cee:	83 c2 01             	add    $0x1,%edx
  800cf1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800cf5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800cf7:	eb bc                	jmp    800cb5 <strtol+0x72>
  800cf9:	89 d8                	mov    %ebx,%eax
  800cfb:	eb 02                	jmp    800cff <strtol+0xbc>
  800cfd:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800cff:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800d03:	74 05                	je     800d0a <strtol+0xc7>
		*endptr = (char *) s;
  800d05:	8b 75 0c             	mov    0xc(%ebp),%esi
  800d08:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800d0a:	f7 d8                	neg    %eax
  800d0c:	85 ff                	test   %edi,%edi
  800d0e:	0f 44 c3             	cmove  %ebx,%eax
}
  800d11:	5b                   	pop    %ebx
  800d12:	5e                   	pop    %esi
  800d13:	5f                   	pop    %edi
  800d14:	5d                   	pop    %ebp
  800d15:	c3                   	ret    

00800d16 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800d16:	55                   	push   %ebp
  800d17:	89 e5                	mov    %esp,%ebp
  800d19:	57                   	push   %edi
  800d1a:	56                   	push   %esi
  800d1b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d1c:	b8 00 00 00 00       	mov    $0x0,%eax
  800d21:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800d24:	8b 55 08             	mov    0x8(%ebp),%edx
  800d27:	89 c3                	mov    %eax,%ebx
  800d29:	89 c7                	mov    %eax,%edi
  800d2b:	89 c6                	mov    %eax,%esi
  800d2d:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800d2f:	5b                   	pop    %ebx
  800d30:	5e                   	pop    %esi
  800d31:	5f                   	pop    %edi
  800d32:	5d                   	pop    %ebp
  800d33:	c3                   	ret    

00800d34 <sys_cgetc>:

int
sys_cgetc(void)
{
  800d34:	55                   	push   %ebp
  800d35:	89 e5                	mov    %esp,%ebp
  800d37:	57                   	push   %edi
  800d38:	56                   	push   %esi
  800d39:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d3a:	ba 00 00 00 00       	mov    $0x0,%edx
  800d3f:	b8 01 00 00 00       	mov    $0x1,%eax
  800d44:	89 d1                	mov    %edx,%ecx
  800d46:	89 d3                	mov    %edx,%ebx
  800d48:	89 d7                	mov    %edx,%edi
  800d4a:	89 d6                	mov    %edx,%esi
  800d4c:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800d4e:	5b                   	pop    %ebx
  800d4f:	5e                   	pop    %esi
  800d50:	5f                   	pop    %edi
  800d51:	5d                   	pop    %ebp
  800d52:	c3                   	ret    

00800d53 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800d53:	55                   	push   %ebp
  800d54:	89 e5                	mov    %esp,%ebp
  800d56:	57                   	push   %edi
  800d57:	56                   	push   %esi
  800d58:	53                   	push   %ebx
  800d59:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800d5c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800d61:	b8 03 00 00 00       	mov    $0x3,%eax
  800d66:	8b 55 08             	mov    0x8(%ebp),%edx
  800d69:	89 cb                	mov    %ecx,%ebx
  800d6b:	89 cf                	mov    %ecx,%edi
  800d6d:	89 ce                	mov    %ecx,%esi
  800d6f:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800d71:	85 c0                	test   %eax,%eax
  800d73:	7e 28                	jle    800d9d <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800d75:	89 44 24 10          	mov    %eax,0x10(%esp)
  800d79:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800d80:	00 
  800d81:	c7 44 24 08 a8 15 80 	movl   $0x8015a8,0x8(%esp)
  800d88:	00 
  800d89:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800d90:	00 
  800d91:	c7 04 24 c5 15 80 00 	movl   $0x8015c5,(%esp)
  800d98:	e8 0d f5 ff ff       	call   8002aa <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800d9d:	83 c4 2c             	add    $0x2c,%esp
  800da0:	5b                   	pop    %ebx
  800da1:	5e                   	pop    %esi
  800da2:	5f                   	pop    %edi
  800da3:	5d                   	pop    %ebp
  800da4:	c3                   	ret    

00800da5 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800da5:	55                   	push   %ebp
  800da6:	89 e5                	mov    %esp,%ebp
  800da8:	57                   	push   %edi
  800da9:	56                   	push   %esi
  800daa:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dab:	ba 00 00 00 00       	mov    $0x0,%edx
  800db0:	b8 02 00 00 00       	mov    $0x2,%eax
  800db5:	89 d1                	mov    %edx,%ecx
  800db7:	89 d3                	mov    %edx,%ebx
  800db9:	89 d7                	mov    %edx,%edi
  800dbb:	89 d6                	mov    %edx,%esi
  800dbd:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800dbf:	5b                   	pop    %ebx
  800dc0:	5e                   	pop    %esi
  800dc1:	5f                   	pop    %edi
  800dc2:	5d                   	pop    %ebp
  800dc3:	c3                   	ret    

00800dc4 <sys_yield>:

void
sys_yield(void)
{
  800dc4:	55                   	push   %ebp
  800dc5:	89 e5                	mov    %esp,%ebp
  800dc7:	57                   	push   %edi
  800dc8:	56                   	push   %esi
  800dc9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dca:	ba 00 00 00 00       	mov    $0x0,%edx
  800dcf:	b8 0a 00 00 00       	mov    $0xa,%eax
  800dd4:	89 d1                	mov    %edx,%ecx
  800dd6:	89 d3                	mov    %edx,%ebx
  800dd8:	89 d7                	mov    %edx,%edi
  800dda:	89 d6                	mov    %edx,%esi
  800ddc:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  800dde:	5b                   	pop    %ebx
  800ddf:	5e                   	pop    %esi
  800de0:	5f                   	pop    %edi
  800de1:	5d                   	pop    %ebp
  800de2:	c3                   	ret    

00800de3 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800de3:	55                   	push   %ebp
  800de4:	89 e5                	mov    %esp,%ebp
  800de6:	57                   	push   %edi
  800de7:	56                   	push   %esi
  800de8:	53                   	push   %ebx
  800de9:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800dec:	be 00 00 00 00       	mov    $0x0,%esi
  800df1:	b8 04 00 00 00       	mov    $0x4,%eax
  800df6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800df9:	8b 55 08             	mov    0x8(%ebp),%edx
  800dfc:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800dff:	89 f7                	mov    %esi,%edi
  800e01:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e03:	85 c0                	test   %eax,%eax
  800e05:	7e 28                	jle    800e2f <sys_page_alloc+0x4c>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e07:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e0b:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800e12:	00 
  800e13:	c7 44 24 08 a8 15 80 	movl   $0x8015a8,0x8(%esp)
  800e1a:	00 
  800e1b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e22:	00 
  800e23:	c7 04 24 c5 15 80 00 	movl   $0x8015c5,(%esp)
  800e2a:	e8 7b f4 ff ff       	call   8002aa <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  800e2f:	83 c4 2c             	add    $0x2c,%esp
  800e32:	5b                   	pop    %ebx
  800e33:	5e                   	pop    %esi
  800e34:	5f                   	pop    %edi
  800e35:	5d                   	pop    %ebp
  800e36:	c3                   	ret    

00800e37 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  800e37:	55                   	push   %ebp
  800e38:	89 e5                	mov    %esp,%ebp
  800e3a:	57                   	push   %edi
  800e3b:	56                   	push   %esi
  800e3c:	53                   	push   %ebx
  800e3d:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e40:	b8 05 00 00 00       	mov    $0x5,%eax
  800e45:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800e48:	8b 55 08             	mov    0x8(%ebp),%edx
  800e4b:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800e4e:	8b 7d 14             	mov    0x14(%ebp),%edi
  800e51:	8b 75 18             	mov    0x18(%ebp),%esi
  800e54:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800e56:	85 c0                	test   %eax,%eax
  800e58:	7e 28                	jle    800e82 <sys_page_map+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800e5a:	89 44 24 10          	mov    %eax,0x10(%esp)
  800e5e:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  800e65:	00 
  800e66:	c7 44 24 08 a8 15 80 	movl   $0x8015a8,0x8(%esp)
  800e6d:	00 
  800e6e:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800e75:	00 
  800e76:	c7 04 24 c5 15 80 00 	movl   $0x8015c5,(%esp)
  800e7d:	e8 28 f4 ff ff       	call   8002aa <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800e82:	83 c4 2c             	add    $0x2c,%esp
  800e85:	5b                   	pop    %ebx
  800e86:	5e                   	pop    %esi
  800e87:	5f                   	pop    %edi
  800e88:	5d                   	pop    %ebp
  800e89:	c3                   	ret    

00800e8a <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  800e8a:	55                   	push   %ebp
  800e8b:	89 e5                	mov    %esp,%ebp
  800e8d:	57                   	push   %edi
  800e8e:	56                   	push   %esi
  800e8f:	53                   	push   %ebx
  800e90:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800e93:	bb 00 00 00 00       	mov    $0x0,%ebx
  800e98:	b8 06 00 00 00       	mov    $0x6,%eax
  800e9d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ea0:	8b 55 08             	mov    0x8(%ebp),%edx
  800ea3:	89 df                	mov    %ebx,%edi
  800ea5:	89 de                	mov    %ebx,%esi
  800ea7:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800ea9:	85 c0                	test   %eax,%eax
  800eab:	7e 28                	jle    800ed5 <sys_page_unmap+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800ead:	89 44 24 10          	mov    %eax,0x10(%esp)
  800eb1:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800eb8:	00 
  800eb9:	c7 44 24 08 a8 15 80 	movl   $0x8015a8,0x8(%esp)
  800ec0:	00 
  800ec1:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800ec8:	00 
  800ec9:	c7 04 24 c5 15 80 00 	movl   $0x8015c5,(%esp)
  800ed0:	e8 d5 f3 ff ff       	call   8002aa <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800ed5:	83 c4 2c             	add    $0x2c,%esp
  800ed8:	5b                   	pop    %ebx
  800ed9:	5e                   	pop    %esi
  800eda:	5f                   	pop    %edi
  800edb:	5d                   	pop    %ebp
  800edc:	c3                   	ret    

00800edd <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  800edd:	55                   	push   %ebp
  800ede:	89 e5                	mov    %esp,%ebp
  800ee0:	57                   	push   %edi
  800ee1:	56                   	push   %esi
  800ee2:	53                   	push   %ebx
  800ee3:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800ee6:	bb 00 00 00 00       	mov    $0x0,%ebx
  800eeb:	b8 08 00 00 00       	mov    $0x8,%eax
  800ef0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ef3:	8b 55 08             	mov    0x8(%ebp),%edx
  800ef6:	89 df                	mov    %ebx,%edi
  800ef8:	89 de                	mov    %ebx,%esi
  800efa:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800efc:	85 c0                	test   %eax,%eax
  800efe:	7e 28                	jle    800f28 <sys_env_set_status+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f00:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f04:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  800f0b:	00 
  800f0c:	c7 44 24 08 a8 15 80 	movl   $0x8015a8,0x8(%esp)
  800f13:	00 
  800f14:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f1b:	00 
  800f1c:	c7 04 24 c5 15 80 00 	movl   $0x8015c5,(%esp)
  800f23:	e8 82 f3 ff ff       	call   8002aa <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  800f28:	83 c4 2c             	add    $0x2c,%esp
  800f2b:	5b                   	pop    %ebx
  800f2c:	5e                   	pop    %esi
  800f2d:	5f                   	pop    %edi
  800f2e:	5d                   	pop    %ebp
  800f2f:	c3                   	ret    

00800f30 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  800f30:	55                   	push   %ebp
  800f31:	89 e5                	mov    %esp,%ebp
  800f33:	57                   	push   %edi
  800f34:	56                   	push   %esi
  800f35:	53                   	push   %ebx
  800f36:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f39:	bb 00 00 00 00       	mov    $0x0,%ebx
  800f3e:	b8 09 00 00 00       	mov    $0x9,%eax
  800f43:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800f46:	8b 55 08             	mov    0x8(%ebp),%edx
  800f49:	89 df                	mov    %ebx,%edi
  800f4b:	89 de                	mov    %ebx,%esi
  800f4d:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800f4f:	85 c0                	test   %eax,%eax
  800f51:	7e 28                	jle    800f7b <sys_env_set_pgfault_upcall+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800f53:	89 44 24 10          	mov    %eax,0x10(%esp)
  800f57:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  800f5e:	00 
  800f5f:	c7 44 24 08 a8 15 80 	movl   $0x8015a8,0x8(%esp)
  800f66:	00 
  800f67:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800f6e:	00 
  800f6f:	c7 04 24 c5 15 80 00 	movl   $0x8015c5,(%esp)
  800f76:	e8 2f f3 ff ff       	call   8002aa <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  800f7b:	83 c4 2c             	add    $0x2c,%esp
  800f7e:	5b                   	pop    %ebx
  800f7f:	5e                   	pop    %esi
  800f80:	5f                   	pop    %edi
  800f81:	5d                   	pop    %ebp
  800f82:	c3                   	ret    

00800f83 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800f83:	55                   	push   %ebp
  800f84:	89 e5                	mov    %esp,%ebp
  800f86:	57                   	push   %edi
  800f87:	56                   	push   %esi
  800f88:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800f89:	be 00 00 00 00       	mov    $0x0,%esi
  800f8e:	b8 0b 00 00 00       	mov    $0xb,%eax
  800f93:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800f96:	8b 55 08             	mov    0x8(%ebp),%edx
  800f99:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800f9c:	8b 7d 14             	mov    0x14(%ebp),%edi
  800f9f:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800fa1:	5b                   	pop    %ebx
  800fa2:	5e                   	pop    %esi
  800fa3:	5f                   	pop    %edi
  800fa4:	5d                   	pop    %ebp
  800fa5:	c3                   	ret    

00800fa6 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800fa6:	55                   	push   %ebp
  800fa7:	89 e5                	mov    %esp,%ebp
  800fa9:	57                   	push   %edi
  800faa:	56                   	push   %esi
  800fab:	53                   	push   %ebx
  800fac:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800faf:	b9 00 00 00 00       	mov    $0x0,%ecx
  800fb4:	b8 0c 00 00 00       	mov    $0xc,%eax
  800fb9:	8b 55 08             	mov    0x8(%ebp),%edx
  800fbc:	89 cb                	mov    %ecx,%ebx
  800fbe:	89 cf                	mov    %ecx,%edi
  800fc0:	89 ce                	mov    %ecx,%esi
  800fc2:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800fc4:	85 c0                	test   %eax,%eax
  800fc6:	7e 28                	jle    800ff0 <sys_ipc_recv+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800fc8:	89 44 24 10          	mov    %eax,0x10(%esp)
  800fcc:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800fd3:	00 
  800fd4:	c7 44 24 08 a8 15 80 	movl   $0x8015a8,0x8(%esp)
  800fdb:	00 
  800fdc:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800fe3:	00 
  800fe4:	c7 04 24 c5 15 80 00 	movl   $0x8015c5,(%esp)
  800feb:	e8 ba f2 ff ff       	call   8002aa <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800ff0:	83 c4 2c             	add    $0x2c,%esp
  800ff3:	5b                   	pop    %ebx
  800ff4:	5e                   	pop    %esi
  800ff5:	5f                   	pop    %edi
  800ff6:	5d                   	pop    %ebp
  800ff7:	c3                   	ret    
  800ff8:	66 90                	xchg   %ax,%ax
  800ffa:	66 90                	xchg   %ax,%ax
  800ffc:	66 90                	xchg   %ax,%ax
  800ffe:	66 90                	xchg   %ax,%ax

00801000 <__udivdi3>:
  801000:	55                   	push   %ebp
  801001:	57                   	push   %edi
  801002:	56                   	push   %esi
  801003:	83 ec 0c             	sub    $0xc,%esp
  801006:	8b 44 24 28          	mov    0x28(%esp),%eax
  80100a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  80100e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  801012:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  801016:	85 c0                	test   %eax,%eax
  801018:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80101c:	89 ea                	mov    %ebp,%edx
  80101e:	89 0c 24             	mov    %ecx,(%esp)
  801021:	75 2d                	jne    801050 <__udivdi3+0x50>
  801023:	39 e9                	cmp    %ebp,%ecx
  801025:	77 61                	ja     801088 <__udivdi3+0x88>
  801027:	85 c9                	test   %ecx,%ecx
  801029:	89 ce                	mov    %ecx,%esi
  80102b:	75 0b                	jne    801038 <__udivdi3+0x38>
  80102d:	b8 01 00 00 00       	mov    $0x1,%eax
  801032:	31 d2                	xor    %edx,%edx
  801034:	f7 f1                	div    %ecx
  801036:	89 c6                	mov    %eax,%esi
  801038:	31 d2                	xor    %edx,%edx
  80103a:	89 e8                	mov    %ebp,%eax
  80103c:	f7 f6                	div    %esi
  80103e:	89 c5                	mov    %eax,%ebp
  801040:	89 f8                	mov    %edi,%eax
  801042:	f7 f6                	div    %esi
  801044:	89 ea                	mov    %ebp,%edx
  801046:	83 c4 0c             	add    $0xc,%esp
  801049:	5e                   	pop    %esi
  80104a:	5f                   	pop    %edi
  80104b:	5d                   	pop    %ebp
  80104c:	c3                   	ret    
  80104d:	8d 76 00             	lea    0x0(%esi),%esi
  801050:	39 e8                	cmp    %ebp,%eax
  801052:	77 24                	ja     801078 <__udivdi3+0x78>
  801054:	0f bd e8             	bsr    %eax,%ebp
  801057:	83 f5 1f             	xor    $0x1f,%ebp
  80105a:	75 3c                	jne    801098 <__udivdi3+0x98>
  80105c:	8b 74 24 04          	mov    0x4(%esp),%esi
  801060:	39 34 24             	cmp    %esi,(%esp)
  801063:	0f 86 9f 00 00 00    	jbe    801108 <__udivdi3+0x108>
  801069:	39 d0                	cmp    %edx,%eax
  80106b:	0f 82 97 00 00 00    	jb     801108 <__udivdi3+0x108>
  801071:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  801078:	31 d2                	xor    %edx,%edx
  80107a:	31 c0                	xor    %eax,%eax
  80107c:	83 c4 0c             	add    $0xc,%esp
  80107f:	5e                   	pop    %esi
  801080:	5f                   	pop    %edi
  801081:	5d                   	pop    %ebp
  801082:	c3                   	ret    
  801083:	90                   	nop
  801084:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801088:	89 f8                	mov    %edi,%eax
  80108a:	f7 f1                	div    %ecx
  80108c:	31 d2                	xor    %edx,%edx
  80108e:	83 c4 0c             	add    $0xc,%esp
  801091:	5e                   	pop    %esi
  801092:	5f                   	pop    %edi
  801093:	5d                   	pop    %ebp
  801094:	c3                   	ret    
  801095:	8d 76 00             	lea    0x0(%esi),%esi
  801098:	89 e9                	mov    %ebp,%ecx
  80109a:	8b 3c 24             	mov    (%esp),%edi
  80109d:	d3 e0                	shl    %cl,%eax
  80109f:	89 c6                	mov    %eax,%esi
  8010a1:	b8 20 00 00 00       	mov    $0x20,%eax
  8010a6:	29 e8                	sub    %ebp,%eax
  8010a8:	89 c1                	mov    %eax,%ecx
  8010aa:	d3 ef                	shr    %cl,%edi
  8010ac:	89 e9                	mov    %ebp,%ecx
  8010ae:	89 7c 24 08          	mov    %edi,0x8(%esp)
  8010b2:	8b 3c 24             	mov    (%esp),%edi
  8010b5:	09 74 24 08          	or     %esi,0x8(%esp)
  8010b9:	89 d6                	mov    %edx,%esi
  8010bb:	d3 e7                	shl    %cl,%edi
  8010bd:	89 c1                	mov    %eax,%ecx
  8010bf:	89 3c 24             	mov    %edi,(%esp)
  8010c2:	8b 7c 24 04          	mov    0x4(%esp),%edi
  8010c6:	d3 ee                	shr    %cl,%esi
  8010c8:	89 e9                	mov    %ebp,%ecx
  8010ca:	d3 e2                	shl    %cl,%edx
  8010cc:	89 c1                	mov    %eax,%ecx
  8010ce:	d3 ef                	shr    %cl,%edi
  8010d0:	09 d7                	or     %edx,%edi
  8010d2:	89 f2                	mov    %esi,%edx
  8010d4:	89 f8                	mov    %edi,%eax
  8010d6:	f7 74 24 08          	divl   0x8(%esp)
  8010da:	89 d6                	mov    %edx,%esi
  8010dc:	89 c7                	mov    %eax,%edi
  8010de:	f7 24 24             	mull   (%esp)
  8010e1:	39 d6                	cmp    %edx,%esi
  8010e3:	89 14 24             	mov    %edx,(%esp)
  8010e6:	72 30                	jb     801118 <__udivdi3+0x118>
  8010e8:	8b 54 24 04          	mov    0x4(%esp),%edx
  8010ec:	89 e9                	mov    %ebp,%ecx
  8010ee:	d3 e2                	shl    %cl,%edx
  8010f0:	39 c2                	cmp    %eax,%edx
  8010f2:	73 05                	jae    8010f9 <__udivdi3+0xf9>
  8010f4:	3b 34 24             	cmp    (%esp),%esi
  8010f7:	74 1f                	je     801118 <__udivdi3+0x118>
  8010f9:	89 f8                	mov    %edi,%eax
  8010fb:	31 d2                	xor    %edx,%edx
  8010fd:	e9 7a ff ff ff       	jmp    80107c <__udivdi3+0x7c>
  801102:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  801108:	31 d2                	xor    %edx,%edx
  80110a:	b8 01 00 00 00       	mov    $0x1,%eax
  80110f:	e9 68 ff ff ff       	jmp    80107c <__udivdi3+0x7c>
  801114:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801118:	8d 47 ff             	lea    -0x1(%edi),%eax
  80111b:	31 d2                	xor    %edx,%edx
  80111d:	83 c4 0c             	add    $0xc,%esp
  801120:	5e                   	pop    %esi
  801121:	5f                   	pop    %edi
  801122:	5d                   	pop    %ebp
  801123:	c3                   	ret    
  801124:	66 90                	xchg   %ax,%ax
  801126:	66 90                	xchg   %ax,%ax
  801128:	66 90                	xchg   %ax,%ax
  80112a:	66 90                	xchg   %ax,%ax
  80112c:	66 90                	xchg   %ax,%ax
  80112e:	66 90                	xchg   %ax,%ax

00801130 <__umoddi3>:
  801130:	55                   	push   %ebp
  801131:	57                   	push   %edi
  801132:	56                   	push   %esi
  801133:	83 ec 14             	sub    $0x14,%esp
  801136:	8b 44 24 28          	mov    0x28(%esp),%eax
  80113a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  80113e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  801142:	89 c7                	mov    %eax,%edi
  801144:	89 44 24 04          	mov    %eax,0x4(%esp)
  801148:	8b 44 24 30          	mov    0x30(%esp),%eax
  80114c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  801150:	89 34 24             	mov    %esi,(%esp)
  801153:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  801157:	85 c0                	test   %eax,%eax
  801159:	89 c2                	mov    %eax,%edx
  80115b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  80115f:	75 17                	jne    801178 <__umoddi3+0x48>
  801161:	39 fe                	cmp    %edi,%esi
  801163:	76 4b                	jbe    8011b0 <__umoddi3+0x80>
  801165:	89 c8                	mov    %ecx,%eax
  801167:	89 fa                	mov    %edi,%edx
  801169:	f7 f6                	div    %esi
  80116b:	89 d0                	mov    %edx,%eax
  80116d:	31 d2                	xor    %edx,%edx
  80116f:	83 c4 14             	add    $0x14,%esp
  801172:	5e                   	pop    %esi
  801173:	5f                   	pop    %edi
  801174:	5d                   	pop    %ebp
  801175:	c3                   	ret    
  801176:	66 90                	xchg   %ax,%ax
  801178:	39 f8                	cmp    %edi,%eax
  80117a:	77 54                	ja     8011d0 <__umoddi3+0xa0>
  80117c:	0f bd e8             	bsr    %eax,%ebp
  80117f:	83 f5 1f             	xor    $0x1f,%ebp
  801182:	75 5c                	jne    8011e0 <__umoddi3+0xb0>
  801184:	8b 7c 24 08          	mov    0x8(%esp),%edi
  801188:	39 3c 24             	cmp    %edi,(%esp)
  80118b:	0f 87 e7 00 00 00    	ja     801278 <__umoddi3+0x148>
  801191:	8b 7c 24 04          	mov    0x4(%esp),%edi
  801195:	29 f1                	sub    %esi,%ecx
  801197:	19 c7                	sbb    %eax,%edi
  801199:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80119d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  8011a1:	8b 44 24 08          	mov    0x8(%esp),%eax
  8011a5:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8011a9:	83 c4 14             	add    $0x14,%esp
  8011ac:	5e                   	pop    %esi
  8011ad:	5f                   	pop    %edi
  8011ae:	5d                   	pop    %ebp
  8011af:	c3                   	ret    
  8011b0:	85 f6                	test   %esi,%esi
  8011b2:	89 f5                	mov    %esi,%ebp
  8011b4:	75 0b                	jne    8011c1 <__umoddi3+0x91>
  8011b6:	b8 01 00 00 00       	mov    $0x1,%eax
  8011bb:	31 d2                	xor    %edx,%edx
  8011bd:	f7 f6                	div    %esi
  8011bf:	89 c5                	mov    %eax,%ebp
  8011c1:	8b 44 24 04          	mov    0x4(%esp),%eax
  8011c5:	31 d2                	xor    %edx,%edx
  8011c7:	f7 f5                	div    %ebp
  8011c9:	89 c8                	mov    %ecx,%eax
  8011cb:	f7 f5                	div    %ebp
  8011cd:	eb 9c                	jmp    80116b <__umoddi3+0x3b>
  8011cf:	90                   	nop
  8011d0:	89 c8                	mov    %ecx,%eax
  8011d2:	89 fa                	mov    %edi,%edx
  8011d4:	83 c4 14             	add    $0x14,%esp
  8011d7:	5e                   	pop    %esi
  8011d8:	5f                   	pop    %edi
  8011d9:	5d                   	pop    %ebp
  8011da:	c3                   	ret    
  8011db:	90                   	nop
  8011dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  8011e0:	8b 04 24             	mov    (%esp),%eax
  8011e3:	be 20 00 00 00       	mov    $0x20,%esi
  8011e8:	89 e9                	mov    %ebp,%ecx
  8011ea:	29 ee                	sub    %ebp,%esi
  8011ec:	d3 e2                	shl    %cl,%edx
  8011ee:	89 f1                	mov    %esi,%ecx
  8011f0:	d3 e8                	shr    %cl,%eax
  8011f2:	89 e9                	mov    %ebp,%ecx
  8011f4:	89 44 24 04          	mov    %eax,0x4(%esp)
  8011f8:	8b 04 24             	mov    (%esp),%eax
  8011fb:	09 54 24 04          	or     %edx,0x4(%esp)
  8011ff:	89 fa                	mov    %edi,%edx
  801201:	d3 e0                	shl    %cl,%eax
  801203:	89 f1                	mov    %esi,%ecx
  801205:	89 44 24 08          	mov    %eax,0x8(%esp)
  801209:	8b 44 24 10          	mov    0x10(%esp),%eax
  80120d:	d3 ea                	shr    %cl,%edx
  80120f:	89 e9                	mov    %ebp,%ecx
  801211:	d3 e7                	shl    %cl,%edi
  801213:	89 f1                	mov    %esi,%ecx
  801215:	d3 e8                	shr    %cl,%eax
  801217:	89 e9                	mov    %ebp,%ecx
  801219:	09 f8                	or     %edi,%eax
  80121b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  80121f:	f7 74 24 04          	divl   0x4(%esp)
  801223:	d3 e7                	shl    %cl,%edi
  801225:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801229:	89 d7                	mov    %edx,%edi
  80122b:	f7 64 24 08          	mull   0x8(%esp)
  80122f:	39 d7                	cmp    %edx,%edi
  801231:	89 c1                	mov    %eax,%ecx
  801233:	89 14 24             	mov    %edx,(%esp)
  801236:	72 2c                	jb     801264 <__umoddi3+0x134>
  801238:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  80123c:	72 22                	jb     801260 <__umoddi3+0x130>
  80123e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801242:	29 c8                	sub    %ecx,%eax
  801244:	19 d7                	sbb    %edx,%edi
  801246:	89 e9                	mov    %ebp,%ecx
  801248:	89 fa                	mov    %edi,%edx
  80124a:	d3 e8                	shr    %cl,%eax
  80124c:	89 f1                	mov    %esi,%ecx
  80124e:	d3 e2                	shl    %cl,%edx
  801250:	89 e9                	mov    %ebp,%ecx
  801252:	d3 ef                	shr    %cl,%edi
  801254:	09 d0                	or     %edx,%eax
  801256:	89 fa                	mov    %edi,%edx
  801258:	83 c4 14             	add    $0x14,%esp
  80125b:	5e                   	pop    %esi
  80125c:	5f                   	pop    %edi
  80125d:	5d                   	pop    %ebp
  80125e:	c3                   	ret    
  80125f:	90                   	nop
  801260:	39 d7                	cmp    %edx,%edi
  801262:	75 da                	jne    80123e <__umoddi3+0x10e>
  801264:	8b 14 24             	mov    (%esp),%edx
  801267:	89 c1                	mov    %eax,%ecx
  801269:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  80126d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  801271:	eb cb                	jmp    80123e <__umoddi3+0x10e>
  801273:	90                   	nop
  801274:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801278:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  80127c:	0f 82 0f ff ff ff    	jb     801191 <__umoddi3+0x61>
  801282:	e9 1a ff ff ff       	jmp    8011a1 <__umoddi3+0x71>
