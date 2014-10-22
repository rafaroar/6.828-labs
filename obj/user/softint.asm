
obj/user/softint:     file format elf32-i386


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
  80002c:	e8 09 00 00 00       	call   80003a <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	asm volatile("int $14");	// page fault
  800036:	cd 0e                	int    $0xe
}
  800038:	5d                   	pop    %ebp
  800039:	c3                   	ret    

0080003a <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80003a:	55                   	push   %ebp
  80003b:	89 e5                	mov    %esp,%ebp
  80003d:	56                   	push   %esi
  80003e:	53                   	push   %ebx
  80003f:	83 ec 10             	sub    $0x10,%esp
  800042:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800045:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	
	thisenv = (struct Env *) envs + ENVX(sys_getenvid());
  800048:	e8 d8 00 00 00       	call   800125 <sys_getenvid>
  80004d:	25 ff 03 00 00       	and    $0x3ff,%eax
  800052:	6b c0 7c             	imul   $0x7c,%eax,%eax
  800055:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80005a:	a3 04 20 80 00       	mov    %eax,0x802004
	//UENVS array
	//thisenv->env_link
	//thisenv = 0;

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80005f:	85 db                	test   %ebx,%ebx
  800061:	7e 07                	jle    80006a <libmain+0x30>
		binaryname = argv[0];
  800063:	8b 06                	mov    (%esi),%eax
  800065:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80006a:	89 74 24 04          	mov    %esi,0x4(%esp)
  80006e:	89 1c 24             	mov    %ebx,(%esp)
  800071:	e8 bd ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800076:	e8 07 00 00 00       	call   800082 <exit>
}
  80007b:	83 c4 10             	add    $0x10,%esp
  80007e:	5b                   	pop    %ebx
  80007f:	5e                   	pop    %esi
  800080:	5d                   	pop    %ebp
  800081:	c3                   	ret    

00800082 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800082:	55                   	push   %ebp
  800083:	89 e5                	mov    %esp,%ebp
  800085:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800088:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80008f:	e8 3f 00 00 00       	call   8000d3 <sys_env_destroy>
}
  800094:	c9                   	leave  
  800095:	c3                   	ret    

00800096 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800096:	55                   	push   %ebp
  800097:	89 e5                	mov    %esp,%ebp
  800099:	57                   	push   %edi
  80009a:	56                   	push   %esi
  80009b:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80009c:	b8 00 00 00 00       	mov    $0x0,%eax
  8000a1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000a4:	8b 55 08             	mov    0x8(%ebp),%edx
  8000a7:	89 c3                	mov    %eax,%ebx
  8000a9:	89 c7                	mov    %eax,%edi
  8000ab:	89 c6                	mov    %eax,%esi
  8000ad:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000af:	5b                   	pop    %ebx
  8000b0:	5e                   	pop    %esi
  8000b1:	5f                   	pop    %edi
  8000b2:	5d                   	pop    %ebp
  8000b3:	c3                   	ret    

008000b4 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000b4:	55                   	push   %ebp
  8000b5:	89 e5                	mov    %esp,%ebp
  8000b7:	57                   	push   %edi
  8000b8:	56                   	push   %esi
  8000b9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000ba:	ba 00 00 00 00       	mov    $0x0,%edx
  8000bf:	b8 01 00 00 00       	mov    $0x1,%eax
  8000c4:	89 d1                	mov    %edx,%ecx
  8000c6:	89 d3                	mov    %edx,%ebx
  8000c8:	89 d7                	mov    %edx,%edi
  8000ca:	89 d6                	mov    %edx,%esi
  8000cc:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000ce:	5b                   	pop    %ebx
  8000cf:	5e                   	pop    %esi
  8000d0:	5f                   	pop    %edi
  8000d1:	5d                   	pop    %ebp
  8000d2:	c3                   	ret    

008000d3 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000d3:	55                   	push   %ebp
  8000d4:	89 e5                	mov    %esp,%ebp
  8000d6:	57                   	push   %edi
  8000d7:	56                   	push   %esi
  8000d8:	53                   	push   %ebx
  8000d9:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000dc:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000e1:	b8 03 00 00 00       	mov    $0x3,%eax
  8000e6:	8b 55 08             	mov    0x8(%ebp),%edx
  8000e9:	89 cb                	mov    %ecx,%ebx
  8000eb:	89 cf                	mov    %ecx,%edi
  8000ed:	89 ce                	mov    %ecx,%esi
  8000ef:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000f1:	85 c0                	test   %eax,%eax
  8000f3:	7e 28                	jle    80011d <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000f5:	89 44 24 10          	mov    %eax,0x10(%esp)
  8000f9:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800100:	00 
  800101:	c7 44 24 08 8a 10 80 	movl   $0x80108a,0x8(%esp)
  800108:	00 
  800109:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800110:	00 
  800111:	c7 04 24 a7 10 80 00 	movl   $0x8010a7,(%esp)
  800118:	e8 5b 02 00 00       	call   800378 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80011d:	83 c4 2c             	add    $0x2c,%esp
  800120:	5b                   	pop    %ebx
  800121:	5e                   	pop    %esi
  800122:	5f                   	pop    %edi
  800123:	5d                   	pop    %ebp
  800124:	c3                   	ret    

00800125 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800125:	55                   	push   %ebp
  800126:	89 e5                	mov    %esp,%ebp
  800128:	57                   	push   %edi
  800129:	56                   	push   %esi
  80012a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80012b:	ba 00 00 00 00       	mov    $0x0,%edx
  800130:	b8 02 00 00 00       	mov    $0x2,%eax
  800135:	89 d1                	mov    %edx,%ecx
  800137:	89 d3                	mov    %edx,%ebx
  800139:	89 d7                	mov    %edx,%edi
  80013b:	89 d6                	mov    %edx,%esi
  80013d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80013f:	5b                   	pop    %ebx
  800140:	5e                   	pop    %esi
  800141:	5f                   	pop    %edi
  800142:	5d                   	pop    %ebp
  800143:	c3                   	ret    

00800144 <sys_yield>:

void
sys_yield(void)
{
  800144:	55                   	push   %ebp
  800145:	89 e5                	mov    %esp,%ebp
  800147:	57                   	push   %edi
  800148:	56                   	push   %esi
  800149:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80014a:	ba 00 00 00 00       	mov    $0x0,%edx
  80014f:	b8 0a 00 00 00       	mov    $0xa,%eax
  800154:	89 d1                	mov    %edx,%ecx
  800156:	89 d3                	mov    %edx,%ebx
  800158:	89 d7                	mov    %edx,%edi
  80015a:	89 d6                	mov    %edx,%esi
  80015c:	cd 30                	int    $0x30

void
sys_yield(void)
{
	syscall(SYS_yield, 0, 0, 0, 0, 0, 0);
}
  80015e:	5b                   	pop    %ebx
  80015f:	5e                   	pop    %esi
  800160:	5f                   	pop    %edi
  800161:	5d                   	pop    %ebp
  800162:	c3                   	ret    

00800163 <sys_page_alloc>:

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
  800163:	55                   	push   %ebp
  800164:	89 e5                	mov    %esp,%ebp
  800166:	57                   	push   %edi
  800167:	56                   	push   %esi
  800168:	53                   	push   %ebx
  800169:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80016c:	be 00 00 00 00       	mov    $0x0,%esi
  800171:	b8 04 00 00 00       	mov    $0x4,%eax
  800176:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800179:	8b 55 08             	mov    0x8(%ebp),%edx
  80017c:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80017f:	89 f7                	mov    %esi,%edi
  800181:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800183:	85 c0                	test   %eax,%eax
  800185:	7e 28                	jle    8001af <sys_page_alloc+0x4c>
		panic("syscall %d returned %d (> 0)", num, ret);
  800187:	89 44 24 10          	mov    %eax,0x10(%esp)
  80018b:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
  800192:	00 
  800193:	c7 44 24 08 8a 10 80 	movl   $0x80108a,0x8(%esp)
  80019a:	00 
  80019b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8001a2:	00 
  8001a3:	c7 04 24 a7 10 80 00 	movl   $0x8010a7,(%esp)
  8001aa:	e8 c9 01 00 00       	call   800378 <_panic>

int
sys_page_alloc(envid_t envid, void *va, int perm)
{
	return syscall(SYS_page_alloc, 1, envid, (uint32_t) va, perm, 0, 0);
}
  8001af:	83 c4 2c             	add    $0x2c,%esp
  8001b2:	5b                   	pop    %ebx
  8001b3:	5e                   	pop    %esi
  8001b4:	5f                   	pop    %edi
  8001b5:	5d                   	pop    %ebp
  8001b6:	c3                   	ret    

008001b7 <sys_page_map>:

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
  8001b7:	55                   	push   %ebp
  8001b8:	89 e5                	mov    %esp,%ebp
  8001ba:	57                   	push   %edi
  8001bb:	56                   	push   %esi
  8001bc:	53                   	push   %ebx
  8001bd:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8001c0:	b8 05 00 00 00       	mov    $0x5,%eax
  8001c5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8001c8:	8b 55 08             	mov    0x8(%ebp),%edx
  8001cb:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8001ce:	8b 7d 14             	mov    0x14(%ebp),%edi
  8001d1:	8b 75 18             	mov    0x18(%ebp),%esi
  8001d4:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8001d6:	85 c0                	test   %eax,%eax
  8001d8:	7e 28                	jle    800202 <sys_page_map+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  8001da:	89 44 24 10          	mov    %eax,0x10(%esp)
  8001de:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
  8001e5:	00 
  8001e6:	c7 44 24 08 8a 10 80 	movl   $0x80108a,0x8(%esp)
  8001ed:	00 
  8001ee:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8001f5:	00 
  8001f6:	c7 04 24 a7 10 80 00 	movl   $0x8010a7,(%esp)
  8001fd:	e8 76 01 00 00       	call   800378 <_panic>

int
sys_page_map(envid_t srcenv, void *srcva, envid_t dstenv, void *dstva, int perm)
{
	return syscall(SYS_page_map, 1, srcenv, (uint32_t) srcva, dstenv, (uint32_t) dstva, perm);
}
  800202:	83 c4 2c             	add    $0x2c,%esp
  800205:	5b                   	pop    %ebx
  800206:	5e                   	pop    %esi
  800207:	5f                   	pop    %edi
  800208:	5d                   	pop    %ebp
  800209:	c3                   	ret    

0080020a <sys_page_unmap>:

int
sys_page_unmap(envid_t envid, void *va)
{
  80020a:	55                   	push   %ebp
  80020b:	89 e5                	mov    %esp,%ebp
  80020d:	57                   	push   %edi
  80020e:	56                   	push   %esi
  80020f:	53                   	push   %ebx
  800210:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800213:	bb 00 00 00 00       	mov    $0x0,%ebx
  800218:	b8 06 00 00 00       	mov    $0x6,%eax
  80021d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800220:	8b 55 08             	mov    0x8(%ebp),%edx
  800223:	89 df                	mov    %ebx,%edi
  800225:	89 de                	mov    %ebx,%esi
  800227:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800229:	85 c0                	test   %eax,%eax
  80022b:	7e 28                	jle    800255 <sys_page_unmap+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  80022d:	89 44 24 10          	mov    %eax,0x10(%esp)
  800231:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
  800238:	00 
  800239:	c7 44 24 08 8a 10 80 	movl   $0x80108a,0x8(%esp)
  800240:	00 
  800241:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800248:	00 
  800249:	c7 04 24 a7 10 80 00 	movl   $0x8010a7,(%esp)
  800250:	e8 23 01 00 00       	call   800378 <_panic>

int
sys_page_unmap(envid_t envid, void *va)
{
	return syscall(SYS_page_unmap, 1, envid, (uint32_t) va, 0, 0, 0);
}
  800255:	83 c4 2c             	add    $0x2c,%esp
  800258:	5b                   	pop    %ebx
  800259:	5e                   	pop    %esi
  80025a:	5f                   	pop    %edi
  80025b:	5d                   	pop    %ebp
  80025c:	c3                   	ret    

0080025d <sys_env_set_status>:

// sys_exofork is inlined in lib.h

int
sys_env_set_status(envid_t envid, int status)
{
  80025d:	55                   	push   %ebp
  80025e:	89 e5                	mov    %esp,%ebp
  800260:	57                   	push   %edi
  800261:	56                   	push   %esi
  800262:	53                   	push   %ebx
  800263:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800266:	bb 00 00 00 00       	mov    $0x0,%ebx
  80026b:	b8 08 00 00 00       	mov    $0x8,%eax
  800270:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800273:	8b 55 08             	mov    0x8(%ebp),%edx
  800276:	89 df                	mov    %ebx,%edi
  800278:	89 de                	mov    %ebx,%esi
  80027a:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  80027c:	85 c0                	test   %eax,%eax
  80027e:	7e 28                	jle    8002a8 <sys_env_set_status+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  800280:	89 44 24 10          	mov    %eax,0x10(%esp)
  800284:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
  80028b:	00 
  80028c:	c7 44 24 08 8a 10 80 	movl   $0x80108a,0x8(%esp)
  800293:	00 
  800294:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80029b:	00 
  80029c:	c7 04 24 a7 10 80 00 	movl   $0x8010a7,(%esp)
  8002a3:	e8 d0 00 00 00       	call   800378 <_panic>

int
sys_env_set_status(envid_t envid, int status)
{
	return syscall(SYS_env_set_status, 1, envid, status, 0, 0, 0);
}
  8002a8:	83 c4 2c             	add    $0x2c,%esp
  8002ab:	5b                   	pop    %ebx
  8002ac:	5e                   	pop    %esi
  8002ad:	5f                   	pop    %edi
  8002ae:	5d                   	pop    %ebp
  8002af:	c3                   	ret    

008002b0 <sys_env_set_pgfault_upcall>:

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
  8002b0:	55                   	push   %ebp
  8002b1:	89 e5                	mov    %esp,%ebp
  8002b3:	57                   	push   %edi
  8002b4:	56                   	push   %esi
  8002b5:	53                   	push   %ebx
  8002b6:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8002b9:	bb 00 00 00 00       	mov    $0x0,%ebx
  8002be:	b8 09 00 00 00       	mov    $0x9,%eax
  8002c3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8002c6:	8b 55 08             	mov    0x8(%ebp),%edx
  8002c9:	89 df                	mov    %ebx,%edi
  8002cb:	89 de                	mov    %ebx,%esi
  8002cd:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8002cf:	85 c0                	test   %eax,%eax
  8002d1:	7e 28                	jle    8002fb <sys_env_set_pgfault_upcall+0x4b>
		panic("syscall %d returned %d (> 0)", num, ret);
  8002d3:	89 44 24 10          	mov    %eax,0x10(%esp)
  8002d7:	c7 44 24 0c 09 00 00 	movl   $0x9,0xc(%esp)
  8002de:	00 
  8002df:	c7 44 24 08 8a 10 80 	movl   $0x80108a,0x8(%esp)
  8002e6:	00 
  8002e7:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  8002ee:	00 
  8002ef:	c7 04 24 a7 10 80 00 	movl   $0x8010a7,(%esp)
  8002f6:	e8 7d 00 00 00       	call   800378 <_panic>

int
sys_env_set_pgfault_upcall(envid_t envid, void *upcall)
{
	return syscall(SYS_env_set_pgfault_upcall, 1, envid, (uint32_t) upcall, 0, 0, 0);
}
  8002fb:	83 c4 2c             	add    $0x2c,%esp
  8002fe:	5b                   	pop    %ebx
  8002ff:	5e                   	pop    %esi
  800300:	5f                   	pop    %edi
  800301:	5d                   	pop    %ebp
  800302:	c3                   	ret    

00800303 <sys_ipc_try_send>:

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
  800303:	55                   	push   %ebp
  800304:	89 e5                	mov    %esp,%ebp
  800306:	57                   	push   %edi
  800307:	56                   	push   %esi
  800308:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800309:	be 00 00 00 00       	mov    $0x0,%esi
  80030e:	b8 0b 00 00 00       	mov    $0xb,%eax
  800313:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800316:	8b 55 08             	mov    0x8(%ebp),%edx
  800319:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80031c:	8b 7d 14             	mov    0x14(%ebp),%edi
  80031f:	cd 30                	int    $0x30

int
sys_ipc_try_send(envid_t envid, uint32_t value, void *srcva, int perm)
{
	return syscall(SYS_ipc_try_send, 0, envid, value, (uint32_t) srcva, perm, 0);
}
  800321:	5b                   	pop    %ebx
  800322:	5e                   	pop    %esi
  800323:	5f                   	pop    %edi
  800324:	5d                   	pop    %ebp
  800325:	c3                   	ret    

00800326 <sys_ipc_recv>:

int
sys_ipc_recv(void *dstva)
{
  800326:	55                   	push   %ebp
  800327:	89 e5                	mov    %esp,%ebp
  800329:	57                   	push   %edi
  80032a:	56                   	push   %esi
  80032b:	53                   	push   %ebx
  80032c:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80032f:	b9 00 00 00 00       	mov    $0x0,%ecx
  800334:	b8 0c 00 00 00       	mov    $0xc,%eax
  800339:	8b 55 08             	mov    0x8(%ebp),%edx
  80033c:	89 cb                	mov    %ecx,%ebx
  80033e:	89 cf                	mov    %ecx,%edi
  800340:	89 ce                	mov    %ecx,%esi
  800342:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800344:	85 c0                	test   %eax,%eax
  800346:	7e 28                	jle    800370 <sys_ipc_recv+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800348:	89 44 24 10          	mov    %eax,0x10(%esp)
  80034c:	c7 44 24 0c 0c 00 00 	movl   $0xc,0xc(%esp)
  800353:	00 
  800354:	c7 44 24 08 8a 10 80 	movl   $0x80108a,0x8(%esp)
  80035b:	00 
  80035c:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800363:	00 
  800364:	c7 04 24 a7 10 80 00 	movl   $0x8010a7,(%esp)
  80036b:	e8 08 00 00 00       	call   800378 <_panic>

int
sys_ipc_recv(void *dstva)
{
	return syscall(SYS_ipc_recv, 1, (uint32_t)dstva, 0, 0, 0, 0);
}
  800370:	83 c4 2c             	add    $0x2c,%esp
  800373:	5b                   	pop    %ebx
  800374:	5e                   	pop    %esi
  800375:	5f                   	pop    %edi
  800376:	5d                   	pop    %ebp
  800377:	c3                   	ret    

00800378 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800378:	55                   	push   %ebp
  800379:	89 e5                	mov    %esp,%ebp
  80037b:	56                   	push   %esi
  80037c:	53                   	push   %ebx
  80037d:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800380:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800383:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800389:	e8 97 fd ff ff       	call   800125 <sys_getenvid>
  80038e:	8b 55 0c             	mov    0xc(%ebp),%edx
  800391:	89 54 24 10          	mov    %edx,0x10(%esp)
  800395:	8b 55 08             	mov    0x8(%ebp),%edx
  800398:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80039c:	89 74 24 08          	mov    %esi,0x8(%esp)
  8003a0:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003a4:	c7 04 24 b8 10 80 00 	movl   $0x8010b8,(%esp)
  8003ab:	e8 c1 00 00 00       	call   800471 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  8003b0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  8003b4:	8b 45 10             	mov    0x10(%ebp),%eax
  8003b7:	89 04 24             	mov    %eax,(%esp)
  8003ba:	e8 51 00 00 00       	call   800410 <vcprintf>
	cprintf("\n");
  8003bf:	c7 04 24 dc 10 80 00 	movl   $0x8010dc,(%esp)
  8003c6:	e8 a6 00 00 00       	call   800471 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8003cb:	cc                   	int3   
  8003cc:	eb fd                	jmp    8003cb <_panic+0x53>

008003ce <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8003ce:	55                   	push   %ebp
  8003cf:	89 e5                	mov    %esp,%ebp
  8003d1:	53                   	push   %ebx
  8003d2:	83 ec 14             	sub    $0x14,%esp
  8003d5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8003d8:	8b 13                	mov    (%ebx),%edx
  8003da:	8d 42 01             	lea    0x1(%edx),%eax
  8003dd:	89 03                	mov    %eax,(%ebx)
  8003df:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8003e2:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8003e6:	3d ff 00 00 00       	cmp    $0xff,%eax
  8003eb:	75 19                	jne    800406 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8003ed:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8003f4:	00 
  8003f5:	8d 43 08             	lea    0x8(%ebx),%eax
  8003f8:	89 04 24             	mov    %eax,(%esp)
  8003fb:	e8 96 fc ff ff       	call   800096 <sys_cputs>
		b->idx = 0;
  800400:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  800406:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  80040a:	83 c4 14             	add    $0x14,%esp
  80040d:	5b                   	pop    %ebx
  80040e:	5d                   	pop    %ebp
  80040f:	c3                   	ret    

00800410 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800410:	55                   	push   %ebp
  800411:	89 e5                	mov    %esp,%ebp
  800413:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800419:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800420:	00 00 00 
	b.cnt = 0;
  800423:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80042a:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80042d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800430:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800434:	8b 45 08             	mov    0x8(%ebp),%eax
  800437:	89 44 24 08          	mov    %eax,0x8(%esp)
  80043b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800441:	89 44 24 04          	mov    %eax,0x4(%esp)
  800445:	c7 04 24 ce 03 80 00 	movl   $0x8003ce,(%esp)
  80044c:	e8 ad 01 00 00       	call   8005fe <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800451:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800457:	89 44 24 04          	mov    %eax,0x4(%esp)
  80045b:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800461:	89 04 24             	mov    %eax,(%esp)
  800464:	e8 2d fc ff ff       	call   800096 <sys_cputs>

	return b.cnt;
}
  800469:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80046f:	c9                   	leave  
  800470:	c3                   	ret    

00800471 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800471:	55                   	push   %ebp
  800472:	89 e5                	mov    %esp,%ebp
  800474:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800477:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80047a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80047e:	8b 45 08             	mov    0x8(%ebp),%eax
  800481:	89 04 24             	mov    %eax,(%esp)
  800484:	e8 87 ff ff ff       	call   800410 <vcprintf>
	va_end(ap);

	return cnt;
}
  800489:	c9                   	leave  
  80048a:	c3                   	ret    
  80048b:	66 90                	xchg   %ax,%ax
  80048d:	66 90                	xchg   %ax,%ax
  80048f:	90                   	nop

00800490 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800490:	55                   	push   %ebp
  800491:	89 e5                	mov    %esp,%ebp
  800493:	57                   	push   %edi
  800494:	56                   	push   %esi
  800495:	53                   	push   %ebx
  800496:	83 ec 3c             	sub    $0x3c,%esp
  800499:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80049c:	89 d7                	mov    %edx,%edi
  80049e:	8b 45 08             	mov    0x8(%ebp),%eax
  8004a1:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8004a4:	8b 45 0c             	mov    0xc(%ebp),%eax
  8004a7:	89 c3                	mov    %eax,%ebx
  8004a9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  8004ac:	8b 45 10             	mov    0x10(%ebp),%eax
  8004af:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8004b2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8004b7:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8004ba:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8004bd:	39 d9                	cmp    %ebx,%ecx
  8004bf:	72 05                	jb     8004c6 <printnum+0x36>
  8004c1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8004c4:	77 69                	ja     80052f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8004c6:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8004c9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8004cd:	83 ee 01             	sub    $0x1,%esi
  8004d0:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8004d4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8004d8:	8b 44 24 08          	mov    0x8(%esp),%eax
  8004dc:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8004e0:	89 c3                	mov    %eax,%ebx
  8004e2:	89 d6                	mov    %edx,%esi
  8004e4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8004e7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8004ea:	89 54 24 08          	mov    %edx,0x8(%esp)
  8004ee:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8004f2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8004f5:	89 04 24             	mov    %eax,(%esp)
  8004f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8004fb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8004ff:	e8 ec 08 00 00       	call   800df0 <__udivdi3>
  800504:	89 d9                	mov    %ebx,%ecx
  800506:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  80050a:	89 74 24 0c          	mov    %esi,0xc(%esp)
  80050e:	89 04 24             	mov    %eax,(%esp)
  800511:	89 54 24 04          	mov    %edx,0x4(%esp)
  800515:	89 fa                	mov    %edi,%edx
  800517:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80051a:	e8 71 ff ff ff       	call   800490 <printnum>
  80051f:	eb 1b                	jmp    80053c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800521:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800525:	8b 45 18             	mov    0x18(%ebp),%eax
  800528:	89 04 24             	mov    %eax,(%esp)
  80052b:	ff d3                	call   *%ebx
  80052d:	eb 03                	jmp    800532 <printnum+0xa2>
  80052f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800532:	83 ee 01             	sub    $0x1,%esi
  800535:	85 f6                	test   %esi,%esi
  800537:	7f e8                	jg     800521 <printnum+0x91>
  800539:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80053c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800540:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800544:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800547:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80054a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80054e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800552:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800555:	89 04 24             	mov    %eax,(%esp)
  800558:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80055b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80055f:	e8 bc 09 00 00       	call   800f20 <__umoddi3>
  800564:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800568:	0f be 80 de 10 80 00 	movsbl 0x8010de(%eax),%eax
  80056f:	89 04 24             	mov    %eax,(%esp)
  800572:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800575:	ff d0                	call   *%eax
}
  800577:	83 c4 3c             	add    $0x3c,%esp
  80057a:	5b                   	pop    %ebx
  80057b:	5e                   	pop    %esi
  80057c:	5f                   	pop    %edi
  80057d:	5d                   	pop    %ebp
  80057e:	c3                   	ret    

0080057f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80057f:	55                   	push   %ebp
  800580:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800582:	83 fa 01             	cmp    $0x1,%edx
  800585:	7e 0e                	jle    800595 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800587:	8b 10                	mov    (%eax),%edx
  800589:	8d 4a 08             	lea    0x8(%edx),%ecx
  80058c:	89 08                	mov    %ecx,(%eax)
  80058e:	8b 02                	mov    (%edx),%eax
  800590:	8b 52 04             	mov    0x4(%edx),%edx
  800593:	eb 22                	jmp    8005b7 <getuint+0x38>
	else if (lflag)
  800595:	85 d2                	test   %edx,%edx
  800597:	74 10                	je     8005a9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800599:	8b 10                	mov    (%eax),%edx
  80059b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80059e:	89 08                	mov    %ecx,(%eax)
  8005a0:	8b 02                	mov    (%edx),%eax
  8005a2:	ba 00 00 00 00       	mov    $0x0,%edx
  8005a7:	eb 0e                	jmp    8005b7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  8005a9:	8b 10                	mov    (%eax),%edx
  8005ab:	8d 4a 04             	lea    0x4(%edx),%ecx
  8005ae:	89 08                	mov    %ecx,(%eax)
  8005b0:	8b 02                	mov    (%edx),%eax
  8005b2:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8005b7:	5d                   	pop    %ebp
  8005b8:	c3                   	ret    

008005b9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8005b9:	55                   	push   %ebp
  8005ba:	89 e5                	mov    %esp,%ebp
  8005bc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8005bf:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8005c3:	8b 10                	mov    (%eax),%edx
  8005c5:	3b 50 04             	cmp    0x4(%eax),%edx
  8005c8:	73 0a                	jae    8005d4 <sprintputch+0x1b>
		*b->buf++ = ch;
  8005ca:	8d 4a 01             	lea    0x1(%edx),%ecx
  8005cd:	89 08                	mov    %ecx,(%eax)
  8005cf:	8b 45 08             	mov    0x8(%ebp),%eax
  8005d2:	88 02                	mov    %al,(%edx)
}
  8005d4:	5d                   	pop    %ebp
  8005d5:	c3                   	ret    

008005d6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8005d6:	55                   	push   %ebp
  8005d7:	89 e5                	mov    %esp,%ebp
  8005d9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8005dc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8005df:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8005e3:	8b 45 10             	mov    0x10(%ebp),%eax
  8005e6:	89 44 24 08          	mov    %eax,0x8(%esp)
  8005ea:	8b 45 0c             	mov    0xc(%ebp),%eax
  8005ed:	89 44 24 04          	mov    %eax,0x4(%esp)
  8005f1:	8b 45 08             	mov    0x8(%ebp),%eax
  8005f4:	89 04 24             	mov    %eax,(%esp)
  8005f7:	e8 02 00 00 00       	call   8005fe <vprintfmt>
	va_end(ap);
}
  8005fc:	c9                   	leave  
  8005fd:	c3                   	ret    

008005fe <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8005fe:	55                   	push   %ebp
  8005ff:	89 e5                	mov    %esp,%ebp
  800601:	57                   	push   %edi
  800602:	56                   	push   %esi
  800603:	53                   	push   %ebx
  800604:	83 ec 3c             	sub    $0x3c,%esp
  800607:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80060a:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80060d:	eb 14                	jmp    800623 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
  80060f:	85 c0                	test   %eax,%eax
  800611:	0f 84 b3 03 00 00    	je     8009ca <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
  800617:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80061b:	89 04 24             	mov    %eax,(%esp)
  80061e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
  800621:	89 f3                	mov    %esi,%ebx
  800623:	8d 73 01             	lea    0x1(%ebx),%esi
  800626:	0f b6 03             	movzbl (%ebx),%eax
  800629:	83 f8 25             	cmp    $0x25,%eax
  80062c:	75 e1                	jne    80060f <vprintfmt+0x11>
  80062e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800632:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800639:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
  800640:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800647:	ba 00 00 00 00       	mov    $0x0,%edx
  80064c:	eb 1d                	jmp    80066b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80064e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
  800650:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  800654:	eb 15                	jmp    80066b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  800656:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
  800658:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  80065c:	eb 0d                	jmp    80066b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
  80065e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  800661:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800664:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80066b:	8d 5e 01             	lea    0x1(%esi),%ebx
  80066e:	0f b6 0e             	movzbl (%esi),%ecx
  800671:	0f b6 c1             	movzbl %cl,%eax
  800674:	83 e9 23             	sub    $0x23,%ecx
  800677:	80 f9 55             	cmp    $0x55,%cl
  80067a:	0f 87 2a 03 00 00    	ja     8009aa <vprintfmt+0x3ac>
  800680:	0f b6 c9             	movzbl %cl,%ecx
  800683:	ff 24 8d a0 11 80 00 	jmp    *0x8011a0(,%ecx,4)
  80068a:	89 de                	mov    %ebx,%esi
  80068c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
  800691:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
  800694:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
  800698:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  80069b:	8d 58 d0             	lea    -0x30(%eax),%ebx
  80069e:	83 fb 09             	cmp    $0x9,%ebx
  8006a1:	77 36                	ja     8006d9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
  8006a3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  8006a6:	eb e9                	jmp    800691 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
  8006a8:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ab:	8d 48 04             	lea    0x4(%eax),%ecx
  8006ae:	89 4d 14             	mov    %ecx,0x14(%ebp)
  8006b1:	8b 00                	mov    (%eax),%eax
  8006b3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006b6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
  8006b8:	eb 22                	jmp    8006dc <vprintfmt+0xde>
  8006ba:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8006bd:	85 c9                	test   %ecx,%ecx
  8006bf:	b8 00 00 00 00       	mov    $0x0,%eax
  8006c4:	0f 49 c1             	cmovns %ecx,%eax
  8006c7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006ca:	89 de                	mov    %ebx,%esi
  8006cc:	eb 9d                	jmp    80066b <vprintfmt+0x6d>
  8006ce:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
  8006d0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  8006d7:	eb 92                	jmp    80066b <vprintfmt+0x6d>
  8006d9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
  8006dc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8006e0:	79 89                	jns    80066b <vprintfmt+0x6d>
  8006e2:	e9 77 ff ff ff       	jmp    80065e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
  8006e7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  8006ea:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
  8006ec:	e9 7a ff ff ff       	jmp    80066b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
  8006f1:	8b 45 14             	mov    0x14(%ebp),%eax
  8006f4:	8d 50 04             	lea    0x4(%eax),%edx
  8006f7:	89 55 14             	mov    %edx,0x14(%ebp)
  8006fa:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006fe:	8b 00                	mov    (%eax),%eax
  800700:	89 04 24             	mov    %eax,(%esp)
  800703:	ff 55 08             	call   *0x8(%ebp)
			break;
  800706:	e9 18 ff ff ff       	jmp    800623 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  80070b:	8b 45 14             	mov    0x14(%ebp),%eax
  80070e:	8d 50 04             	lea    0x4(%eax),%edx
  800711:	89 55 14             	mov    %edx,0x14(%ebp)
  800714:	8b 00                	mov    (%eax),%eax
  800716:	99                   	cltd   
  800717:	31 d0                	xor    %edx,%eax
  800719:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  80071b:	83 f8 09             	cmp    $0x9,%eax
  80071e:	7f 0b                	jg     80072b <vprintfmt+0x12d>
  800720:	8b 14 85 00 13 80 00 	mov    0x801300(,%eax,4),%edx
  800727:	85 d2                	test   %edx,%edx
  800729:	75 20                	jne    80074b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
  80072b:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80072f:	c7 44 24 08 f6 10 80 	movl   $0x8010f6,0x8(%esp)
  800736:	00 
  800737:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80073b:	8b 45 08             	mov    0x8(%ebp),%eax
  80073e:	89 04 24             	mov    %eax,(%esp)
  800741:	e8 90 fe ff ff       	call   8005d6 <printfmt>
  800746:	e9 d8 fe ff ff       	jmp    800623 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  80074b:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80074f:	c7 44 24 08 ff 10 80 	movl   $0x8010ff,0x8(%esp)
  800756:	00 
  800757:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80075b:	8b 45 08             	mov    0x8(%ebp),%eax
  80075e:	89 04 24             	mov    %eax,(%esp)
  800761:	e8 70 fe ff ff       	call   8005d6 <printfmt>
  800766:	e9 b8 fe ff ff       	jmp    800623 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
  80076b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  80076e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800771:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  800774:	8b 45 14             	mov    0x14(%ebp),%eax
  800777:	8d 50 04             	lea    0x4(%eax),%edx
  80077a:	89 55 14             	mov    %edx,0x14(%ebp)
  80077d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  80077f:	85 f6                	test   %esi,%esi
  800781:	b8 ef 10 80 00       	mov    $0x8010ef,%eax
  800786:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  800789:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  80078d:	0f 84 97 00 00 00    	je     80082a <vprintfmt+0x22c>
  800793:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
  800797:	0f 8e 9b 00 00 00    	jle    800838 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
  80079d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8007a1:	89 34 24             	mov    %esi,(%esp)
  8007a4:	e8 cf 02 00 00       	call   800a78 <strnlen>
  8007a9:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8007ac:	29 c2                	sub    %eax,%edx
  8007ae:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
  8007b1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  8007b5:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8007b8:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8007bb:	8b 75 08             	mov    0x8(%ebp),%esi
  8007be:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8007c1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8007c3:	eb 0f                	jmp    8007d4 <vprintfmt+0x1d6>
					putch(padc, putdat);
  8007c5:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8007c9:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8007cc:	89 04 24             	mov    %eax,(%esp)
  8007cf:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8007d1:	83 eb 01             	sub    $0x1,%ebx
  8007d4:	85 db                	test   %ebx,%ebx
  8007d6:	7f ed                	jg     8007c5 <vprintfmt+0x1c7>
  8007d8:	8b 75 d8             	mov    -0x28(%ebp),%esi
  8007db:	8b 55 d0             	mov    -0x30(%ebp),%edx
  8007de:	85 d2                	test   %edx,%edx
  8007e0:	b8 00 00 00 00       	mov    $0x0,%eax
  8007e5:	0f 49 c2             	cmovns %edx,%eax
  8007e8:	29 c2                	sub    %eax,%edx
  8007ea:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8007ed:	89 d7                	mov    %edx,%edi
  8007ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  8007f2:	eb 50                	jmp    800844 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8007f4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8007f8:	74 1e                	je     800818 <vprintfmt+0x21a>
  8007fa:	0f be d2             	movsbl %dl,%edx
  8007fd:	83 ea 20             	sub    $0x20,%edx
  800800:	83 fa 5e             	cmp    $0x5e,%edx
  800803:	76 13                	jbe    800818 <vprintfmt+0x21a>
					putch('?', putdat);
  800805:	8b 45 0c             	mov    0xc(%ebp),%eax
  800808:	89 44 24 04          	mov    %eax,0x4(%esp)
  80080c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  800813:	ff 55 08             	call   *0x8(%ebp)
  800816:	eb 0d                	jmp    800825 <vprintfmt+0x227>
				else
					putch(ch, putdat);
  800818:	8b 55 0c             	mov    0xc(%ebp),%edx
  80081b:	89 54 24 04          	mov    %edx,0x4(%esp)
  80081f:	89 04 24             	mov    %eax,(%esp)
  800822:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  800825:	83 ef 01             	sub    $0x1,%edi
  800828:	eb 1a                	jmp    800844 <vprintfmt+0x246>
  80082a:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80082d:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800830:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800833:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800836:	eb 0c                	jmp    800844 <vprintfmt+0x246>
  800838:	89 7d 0c             	mov    %edi,0xc(%ebp)
  80083b:	8b 7d dc             	mov    -0x24(%ebp),%edi
  80083e:	89 5d 10             	mov    %ebx,0x10(%ebp)
  800841:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
  800844:	83 c6 01             	add    $0x1,%esi
  800847:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  80084b:	0f be c2             	movsbl %dl,%eax
  80084e:	85 c0                	test   %eax,%eax
  800850:	74 27                	je     800879 <vprintfmt+0x27b>
  800852:	85 db                	test   %ebx,%ebx
  800854:	78 9e                	js     8007f4 <vprintfmt+0x1f6>
  800856:	83 eb 01             	sub    $0x1,%ebx
  800859:	79 99                	jns    8007f4 <vprintfmt+0x1f6>
  80085b:	89 f8                	mov    %edi,%eax
  80085d:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800860:	8b 75 08             	mov    0x8(%ebp),%esi
  800863:	89 c3                	mov    %eax,%ebx
  800865:	eb 1a                	jmp    800881 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800867:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80086b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  800872:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  800874:	83 eb 01             	sub    $0x1,%ebx
  800877:	eb 08                	jmp    800881 <vprintfmt+0x283>
  800879:	89 fb                	mov    %edi,%ebx
  80087b:	8b 75 08             	mov    0x8(%ebp),%esi
  80087e:	8b 7d 0c             	mov    0xc(%ebp),%edi
  800881:	85 db                	test   %ebx,%ebx
  800883:	7f e2                	jg     800867 <vprintfmt+0x269>
  800885:	89 75 08             	mov    %esi,0x8(%ebp)
  800888:	8b 5d 10             	mov    0x10(%ebp),%ebx
  80088b:	e9 93 fd ff ff       	jmp    800623 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  800890:	83 fa 01             	cmp    $0x1,%edx
  800893:	7e 16                	jle    8008ab <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
  800895:	8b 45 14             	mov    0x14(%ebp),%eax
  800898:	8d 50 08             	lea    0x8(%eax),%edx
  80089b:	89 55 14             	mov    %edx,0x14(%ebp)
  80089e:	8b 50 04             	mov    0x4(%eax),%edx
  8008a1:	8b 00                	mov    (%eax),%eax
  8008a3:	89 45 e0             	mov    %eax,-0x20(%ebp)
  8008a6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  8008a9:	eb 32                	jmp    8008dd <vprintfmt+0x2df>
	else if (lflag)
  8008ab:	85 d2                	test   %edx,%edx
  8008ad:	74 18                	je     8008c7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
  8008af:	8b 45 14             	mov    0x14(%ebp),%eax
  8008b2:	8d 50 04             	lea    0x4(%eax),%edx
  8008b5:	89 55 14             	mov    %edx,0x14(%ebp)
  8008b8:	8b 30                	mov    (%eax),%esi
  8008ba:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8008bd:	89 f0                	mov    %esi,%eax
  8008bf:	c1 f8 1f             	sar    $0x1f,%eax
  8008c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8008c5:	eb 16                	jmp    8008dd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
  8008c7:	8b 45 14             	mov    0x14(%ebp),%eax
  8008ca:	8d 50 04             	lea    0x4(%eax),%edx
  8008cd:	89 55 14             	mov    %edx,0x14(%ebp)
  8008d0:	8b 30                	mov    (%eax),%esi
  8008d2:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8008d5:	89 f0                	mov    %esi,%eax
  8008d7:	c1 f8 1f             	sar    $0x1f,%eax
  8008da:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8008dd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8008e0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8008e3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8008e8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8008ec:	0f 89 80 00 00 00    	jns    800972 <vprintfmt+0x374>
				putch('-', putdat);
  8008f2:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8008f6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8008fd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  800900:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800903:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  800906:	f7 d8                	neg    %eax
  800908:	83 d2 00             	adc    $0x0,%edx
  80090b:	f7 da                	neg    %edx
			}
			base = 10;
  80090d:	b9 0a 00 00 00       	mov    $0xa,%ecx
  800912:	eb 5e                	jmp    800972 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800914:	8d 45 14             	lea    0x14(%ebp),%eax
  800917:	e8 63 fc ff ff       	call   80057f <getuint>
			base = 10;
  80091c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800921:	eb 4f                	jmp    800972 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			num = getuint(&ap, lflag);
  800923:	8d 45 14             	lea    0x14(%ebp),%eax
  800926:	e8 54 fc ff ff       	call   80057f <getuint>
			base = 8;
  80092b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800930:	eb 40                	jmp    800972 <vprintfmt+0x374>

		// pointer
		case 'p':
			putch('0', putdat);
  800932:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800936:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80093d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800940:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800944:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80094b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80094e:	8b 45 14             	mov    0x14(%ebp),%eax
  800951:	8d 50 04             	lea    0x4(%eax),%edx
  800954:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800957:	8b 00                	mov    (%eax),%eax
  800959:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80095e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800963:	eb 0d                	jmp    800972 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800965:	8d 45 14             	lea    0x14(%ebp),%eax
  800968:	e8 12 fc ff ff       	call   80057f <getuint>
			base = 16;
  80096d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800972:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  800976:	89 74 24 10          	mov    %esi,0x10(%esp)
  80097a:	8b 75 dc             	mov    -0x24(%ebp),%esi
  80097d:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800981:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800985:	89 04 24             	mov    %eax,(%esp)
  800988:	89 54 24 04          	mov    %edx,0x4(%esp)
  80098c:	89 fa                	mov    %edi,%edx
  80098e:	8b 45 08             	mov    0x8(%ebp),%eax
  800991:	e8 fa fa ff ff       	call   800490 <printnum>
			break;
  800996:	e9 88 fc ff ff       	jmp    800623 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80099b:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80099f:	89 04 24             	mov    %eax,(%esp)
  8009a2:	ff 55 08             	call   *0x8(%ebp)
			break;
  8009a5:	e9 79 fc ff ff       	jmp    800623 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8009aa:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8009ae:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8009b5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8009b8:	89 f3                	mov    %esi,%ebx
  8009ba:	eb 03                	jmp    8009bf <vprintfmt+0x3c1>
  8009bc:	83 eb 01             	sub    $0x1,%ebx
  8009bf:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8009c3:	75 f7                	jne    8009bc <vprintfmt+0x3be>
  8009c5:	e9 59 fc ff ff       	jmp    800623 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8009ca:	83 c4 3c             	add    $0x3c,%esp
  8009cd:	5b                   	pop    %ebx
  8009ce:	5e                   	pop    %esi
  8009cf:	5f                   	pop    %edi
  8009d0:	5d                   	pop    %ebp
  8009d1:	c3                   	ret    

008009d2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8009d2:	55                   	push   %ebp
  8009d3:	89 e5                	mov    %esp,%ebp
  8009d5:	83 ec 28             	sub    $0x28,%esp
  8009d8:	8b 45 08             	mov    0x8(%ebp),%eax
  8009db:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8009de:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8009e1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8009e5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8009e8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8009ef:	85 c0                	test   %eax,%eax
  8009f1:	74 30                	je     800a23 <vsnprintf+0x51>
  8009f3:	85 d2                	test   %edx,%edx
  8009f5:	7e 2c                	jle    800a23 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8009f7:	8b 45 14             	mov    0x14(%ebp),%eax
  8009fa:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8009fe:	8b 45 10             	mov    0x10(%ebp),%eax
  800a01:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a05:	8d 45 ec             	lea    -0x14(%ebp),%eax
  800a08:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a0c:	c7 04 24 b9 05 80 00 	movl   $0x8005b9,(%esp)
  800a13:	e8 e6 fb ff ff       	call   8005fe <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  800a18:	8b 45 ec             	mov    -0x14(%ebp),%eax
  800a1b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800a1e:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800a21:	eb 05                	jmp    800a28 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800a23:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  800a28:	c9                   	leave  
  800a29:	c3                   	ret    

00800a2a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  800a2a:	55                   	push   %ebp
  800a2b:	89 e5                	mov    %esp,%ebp
  800a2d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800a30:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800a33:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800a37:	8b 45 10             	mov    0x10(%ebp),%eax
  800a3a:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a3e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a41:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a45:	8b 45 08             	mov    0x8(%ebp),%eax
  800a48:	89 04 24             	mov    %eax,(%esp)
  800a4b:	e8 82 ff ff ff       	call   8009d2 <vsnprintf>
	va_end(ap);

	return rc;
}
  800a50:	c9                   	leave  
  800a51:	c3                   	ret    
  800a52:	66 90                	xchg   %ax,%ax
  800a54:	66 90                	xchg   %ax,%ax
  800a56:	66 90                	xchg   %ax,%ax
  800a58:	66 90                	xchg   %ax,%ax
  800a5a:	66 90                	xchg   %ax,%ax
  800a5c:	66 90                	xchg   %ax,%ax
  800a5e:	66 90                	xchg   %ax,%ax

00800a60 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800a60:	55                   	push   %ebp
  800a61:	89 e5                	mov    %esp,%ebp
  800a63:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800a66:	b8 00 00 00 00       	mov    $0x0,%eax
  800a6b:	eb 03                	jmp    800a70 <strlen+0x10>
		n++;
  800a6d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800a70:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800a74:	75 f7                	jne    800a6d <strlen+0xd>
		n++;
	return n;
}
  800a76:	5d                   	pop    %ebp
  800a77:	c3                   	ret    

00800a78 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800a78:	55                   	push   %ebp
  800a79:	89 e5                	mov    %esp,%ebp
  800a7b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800a7e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800a81:	b8 00 00 00 00       	mov    $0x0,%eax
  800a86:	eb 03                	jmp    800a8b <strnlen+0x13>
		n++;
  800a88:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800a8b:	39 d0                	cmp    %edx,%eax
  800a8d:	74 06                	je     800a95 <strnlen+0x1d>
  800a8f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800a93:	75 f3                	jne    800a88 <strnlen+0x10>
		n++;
	return n;
}
  800a95:	5d                   	pop    %ebp
  800a96:	c3                   	ret    

00800a97 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800a97:	55                   	push   %ebp
  800a98:	89 e5                	mov    %esp,%ebp
  800a9a:	53                   	push   %ebx
  800a9b:	8b 45 08             	mov    0x8(%ebp),%eax
  800a9e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800aa1:	89 c2                	mov    %eax,%edx
  800aa3:	83 c2 01             	add    $0x1,%edx
  800aa6:	83 c1 01             	add    $0x1,%ecx
  800aa9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  800aad:	88 5a ff             	mov    %bl,-0x1(%edx)
  800ab0:	84 db                	test   %bl,%bl
  800ab2:	75 ef                	jne    800aa3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800ab4:	5b                   	pop    %ebx
  800ab5:	5d                   	pop    %ebp
  800ab6:	c3                   	ret    

00800ab7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800ab7:	55                   	push   %ebp
  800ab8:	89 e5                	mov    %esp,%ebp
  800aba:	53                   	push   %ebx
  800abb:	83 ec 08             	sub    $0x8,%esp
  800abe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  800ac1:	89 1c 24             	mov    %ebx,(%esp)
  800ac4:	e8 97 ff ff ff       	call   800a60 <strlen>
	strcpy(dst + len, src);
  800ac9:	8b 55 0c             	mov    0xc(%ebp),%edx
  800acc:	89 54 24 04          	mov    %edx,0x4(%esp)
  800ad0:	01 d8                	add    %ebx,%eax
  800ad2:	89 04 24             	mov    %eax,(%esp)
  800ad5:	e8 bd ff ff ff       	call   800a97 <strcpy>
	return dst;
}
  800ada:	89 d8                	mov    %ebx,%eax
  800adc:	83 c4 08             	add    $0x8,%esp
  800adf:	5b                   	pop    %ebx
  800ae0:	5d                   	pop    %ebp
  800ae1:	c3                   	ret    

00800ae2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  800ae2:	55                   	push   %ebp
  800ae3:	89 e5                	mov    %esp,%ebp
  800ae5:	56                   	push   %esi
  800ae6:	53                   	push   %ebx
  800ae7:	8b 75 08             	mov    0x8(%ebp),%esi
  800aea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800aed:	89 f3                	mov    %esi,%ebx
  800aef:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800af2:	89 f2                	mov    %esi,%edx
  800af4:	eb 0f                	jmp    800b05 <strncpy+0x23>
		*dst++ = *src;
  800af6:	83 c2 01             	add    $0x1,%edx
  800af9:	0f b6 01             	movzbl (%ecx),%eax
  800afc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  800aff:	80 39 01             	cmpb   $0x1,(%ecx)
  800b02:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800b05:	39 da                	cmp    %ebx,%edx
  800b07:	75 ed                	jne    800af6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800b09:	89 f0                	mov    %esi,%eax
  800b0b:	5b                   	pop    %ebx
  800b0c:	5e                   	pop    %esi
  800b0d:	5d                   	pop    %ebp
  800b0e:	c3                   	ret    

00800b0f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  800b0f:	55                   	push   %ebp
  800b10:	89 e5                	mov    %esp,%ebp
  800b12:	56                   	push   %esi
  800b13:	53                   	push   %ebx
  800b14:	8b 75 08             	mov    0x8(%ebp),%esi
  800b17:	8b 55 0c             	mov    0xc(%ebp),%edx
  800b1a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  800b1d:	89 f0                	mov    %esi,%eax
  800b1f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800b23:	85 c9                	test   %ecx,%ecx
  800b25:	75 0b                	jne    800b32 <strlcpy+0x23>
  800b27:	eb 1d                	jmp    800b46 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800b29:	83 c0 01             	add    $0x1,%eax
  800b2c:	83 c2 01             	add    $0x1,%edx
  800b2f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800b32:	39 d8                	cmp    %ebx,%eax
  800b34:	74 0b                	je     800b41 <strlcpy+0x32>
  800b36:	0f b6 0a             	movzbl (%edx),%ecx
  800b39:	84 c9                	test   %cl,%cl
  800b3b:	75 ec                	jne    800b29 <strlcpy+0x1a>
  800b3d:	89 c2                	mov    %eax,%edx
  800b3f:	eb 02                	jmp    800b43 <strlcpy+0x34>
  800b41:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800b43:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800b46:	29 f0                	sub    %esi,%eax
}
  800b48:	5b                   	pop    %ebx
  800b49:	5e                   	pop    %esi
  800b4a:	5d                   	pop    %ebp
  800b4b:	c3                   	ret    

00800b4c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  800b4c:	55                   	push   %ebp
  800b4d:	89 e5                	mov    %esp,%ebp
  800b4f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800b52:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800b55:	eb 06                	jmp    800b5d <strcmp+0x11>
		p++, q++;
  800b57:	83 c1 01             	add    $0x1,%ecx
  800b5a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  800b5d:	0f b6 01             	movzbl (%ecx),%eax
  800b60:	84 c0                	test   %al,%al
  800b62:	74 04                	je     800b68 <strcmp+0x1c>
  800b64:	3a 02                	cmp    (%edx),%al
  800b66:	74 ef                	je     800b57 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800b68:	0f b6 c0             	movzbl %al,%eax
  800b6b:	0f b6 12             	movzbl (%edx),%edx
  800b6e:	29 d0                	sub    %edx,%eax
}
  800b70:	5d                   	pop    %ebp
  800b71:	c3                   	ret    

00800b72 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800b72:	55                   	push   %ebp
  800b73:	89 e5                	mov    %esp,%ebp
  800b75:	53                   	push   %ebx
  800b76:	8b 45 08             	mov    0x8(%ebp),%eax
  800b79:	8b 55 0c             	mov    0xc(%ebp),%edx
  800b7c:	89 c3                	mov    %eax,%ebx
  800b7e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800b81:	eb 06                	jmp    800b89 <strncmp+0x17>
		n--, p++, q++;
  800b83:	83 c0 01             	add    $0x1,%eax
  800b86:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800b89:	39 d8                	cmp    %ebx,%eax
  800b8b:	74 15                	je     800ba2 <strncmp+0x30>
  800b8d:	0f b6 08             	movzbl (%eax),%ecx
  800b90:	84 c9                	test   %cl,%cl
  800b92:	74 04                	je     800b98 <strncmp+0x26>
  800b94:	3a 0a                	cmp    (%edx),%cl
  800b96:	74 eb                	je     800b83 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800b98:	0f b6 00             	movzbl (%eax),%eax
  800b9b:	0f b6 12             	movzbl (%edx),%edx
  800b9e:	29 d0                	sub    %edx,%eax
  800ba0:	eb 05                	jmp    800ba7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800ba2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800ba7:	5b                   	pop    %ebx
  800ba8:	5d                   	pop    %ebp
  800ba9:	c3                   	ret    

00800baa <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  800baa:	55                   	push   %ebp
  800bab:	89 e5                	mov    %esp,%ebp
  800bad:	8b 45 08             	mov    0x8(%ebp),%eax
  800bb0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800bb4:	eb 07                	jmp    800bbd <strchr+0x13>
		if (*s == c)
  800bb6:	38 ca                	cmp    %cl,%dl
  800bb8:	74 0f                	je     800bc9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  800bba:	83 c0 01             	add    $0x1,%eax
  800bbd:	0f b6 10             	movzbl (%eax),%edx
  800bc0:	84 d2                	test   %dl,%dl
  800bc2:	75 f2                	jne    800bb6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  800bc4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800bc9:	5d                   	pop    %ebp
  800bca:	c3                   	ret    

00800bcb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  800bcb:	55                   	push   %ebp
  800bcc:	89 e5                	mov    %esp,%ebp
  800bce:	8b 45 08             	mov    0x8(%ebp),%eax
  800bd1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800bd5:	eb 07                	jmp    800bde <strfind+0x13>
		if (*s == c)
  800bd7:	38 ca                	cmp    %cl,%dl
  800bd9:	74 0a                	je     800be5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  800bdb:	83 c0 01             	add    $0x1,%eax
  800bde:	0f b6 10             	movzbl (%eax),%edx
  800be1:	84 d2                	test   %dl,%dl
  800be3:	75 f2                	jne    800bd7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  800be5:	5d                   	pop    %ebp
  800be6:	c3                   	ret    

00800be7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  800be7:	55                   	push   %ebp
  800be8:	89 e5                	mov    %esp,%ebp
  800bea:	57                   	push   %edi
  800beb:	56                   	push   %esi
  800bec:	53                   	push   %ebx
  800bed:	8b 7d 08             	mov    0x8(%ebp),%edi
  800bf0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  800bf3:	85 c9                	test   %ecx,%ecx
  800bf5:	74 36                	je     800c2d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  800bf7:	f7 c7 03 00 00 00    	test   $0x3,%edi
  800bfd:	75 28                	jne    800c27 <memset+0x40>
  800bff:	f6 c1 03             	test   $0x3,%cl
  800c02:	75 23                	jne    800c27 <memset+0x40>
		c &= 0xFF;
  800c04:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800c08:	89 d3                	mov    %edx,%ebx
  800c0a:	c1 e3 08             	shl    $0x8,%ebx
  800c0d:	89 d6                	mov    %edx,%esi
  800c0f:	c1 e6 18             	shl    $0x18,%esi
  800c12:	89 d0                	mov    %edx,%eax
  800c14:	c1 e0 10             	shl    $0x10,%eax
  800c17:	09 f0                	or     %esi,%eax
  800c19:	09 c2                	or     %eax,%edx
  800c1b:	89 d0                	mov    %edx,%eax
  800c1d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800c1f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800c22:	fc                   	cld    
  800c23:	f3 ab                	rep stos %eax,%es:(%edi)
  800c25:	eb 06                	jmp    800c2d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800c27:	8b 45 0c             	mov    0xc(%ebp),%eax
  800c2a:	fc                   	cld    
  800c2b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800c2d:	89 f8                	mov    %edi,%eax
  800c2f:	5b                   	pop    %ebx
  800c30:	5e                   	pop    %esi
  800c31:	5f                   	pop    %edi
  800c32:	5d                   	pop    %ebp
  800c33:	c3                   	ret    

00800c34 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800c34:	55                   	push   %ebp
  800c35:	89 e5                	mov    %esp,%ebp
  800c37:	57                   	push   %edi
  800c38:	56                   	push   %esi
  800c39:	8b 45 08             	mov    0x8(%ebp),%eax
  800c3c:	8b 75 0c             	mov    0xc(%ebp),%esi
  800c3f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800c42:	39 c6                	cmp    %eax,%esi
  800c44:	73 35                	jae    800c7b <memmove+0x47>
  800c46:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800c49:	39 d0                	cmp    %edx,%eax
  800c4b:	73 2e                	jae    800c7b <memmove+0x47>
		s += n;
		d += n;
  800c4d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800c50:	89 d6                	mov    %edx,%esi
  800c52:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800c54:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800c5a:	75 13                	jne    800c6f <memmove+0x3b>
  800c5c:	f6 c1 03             	test   $0x3,%cl
  800c5f:	75 0e                	jne    800c6f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800c61:	83 ef 04             	sub    $0x4,%edi
  800c64:	8d 72 fc             	lea    -0x4(%edx),%esi
  800c67:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800c6a:	fd                   	std    
  800c6b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800c6d:	eb 09                	jmp    800c78 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800c6f:	83 ef 01             	sub    $0x1,%edi
  800c72:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800c75:	fd                   	std    
  800c76:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800c78:	fc                   	cld    
  800c79:	eb 1d                	jmp    800c98 <memmove+0x64>
  800c7b:	89 f2                	mov    %esi,%edx
  800c7d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800c7f:	f6 c2 03             	test   $0x3,%dl
  800c82:	75 0f                	jne    800c93 <memmove+0x5f>
  800c84:	f6 c1 03             	test   $0x3,%cl
  800c87:	75 0a                	jne    800c93 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800c89:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800c8c:	89 c7                	mov    %eax,%edi
  800c8e:	fc                   	cld    
  800c8f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800c91:	eb 05                	jmp    800c98 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800c93:	89 c7                	mov    %eax,%edi
  800c95:	fc                   	cld    
  800c96:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800c98:	5e                   	pop    %esi
  800c99:	5f                   	pop    %edi
  800c9a:	5d                   	pop    %ebp
  800c9b:	c3                   	ret    

00800c9c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800c9c:	55                   	push   %ebp
  800c9d:	89 e5                	mov    %esp,%ebp
  800c9f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800ca2:	8b 45 10             	mov    0x10(%ebp),%eax
  800ca5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ca9:	8b 45 0c             	mov    0xc(%ebp),%eax
  800cac:	89 44 24 04          	mov    %eax,0x4(%esp)
  800cb0:	8b 45 08             	mov    0x8(%ebp),%eax
  800cb3:	89 04 24             	mov    %eax,(%esp)
  800cb6:	e8 79 ff ff ff       	call   800c34 <memmove>
}
  800cbb:	c9                   	leave  
  800cbc:	c3                   	ret    

00800cbd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800cbd:	55                   	push   %ebp
  800cbe:	89 e5                	mov    %esp,%ebp
  800cc0:	56                   	push   %esi
  800cc1:	53                   	push   %ebx
  800cc2:	8b 55 08             	mov    0x8(%ebp),%edx
  800cc5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800cc8:	89 d6                	mov    %edx,%esi
  800cca:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ccd:	eb 1a                	jmp    800ce9 <memcmp+0x2c>
		if (*s1 != *s2)
  800ccf:	0f b6 02             	movzbl (%edx),%eax
  800cd2:	0f b6 19             	movzbl (%ecx),%ebx
  800cd5:	38 d8                	cmp    %bl,%al
  800cd7:	74 0a                	je     800ce3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800cd9:	0f b6 c0             	movzbl %al,%eax
  800cdc:	0f b6 db             	movzbl %bl,%ebx
  800cdf:	29 d8                	sub    %ebx,%eax
  800ce1:	eb 0f                	jmp    800cf2 <memcmp+0x35>
		s1++, s2++;
  800ce3:	83 c2 01             	add    $0x1,%edx
  800ce6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ce9:	39 f2                	cmp    %esi,%edx
  800ceb:	75 e2                	jne    800ccf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800ced:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800cf2:	5b                   	pop    %ebx
  800cf3:	5e                   	pop    %esi
  800cf4:	5d                   	pop    %ebp
  800cf5:	c3                   	ret    

00800cf6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800cf6:	55                   	push   %ebp
  800cf7:	89 e5                	mov    %esp,%ebp
  800cf9:	8b 45 08             	mov    0x8(%ebp),%eax
  800cfc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800cff:	89 c2                	mov    %eax,%edx
  800d01:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800d04:	eb 07                	jmp    800d0d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800d06:	38 08                	cmp    %cl,(%eax)
  800d08:	74 07                	je     800d11 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800d0a:	83 c0 01             	add    $0x1,%eax
  800d0d:	39 d0                	cmp    %edx,%eax
  800d0f:	72 f5                	jb     800d06 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800d11:	5d                   	pop    %ebp
  800d12:	c3                   	ret    

00800d13 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800d13:	55                   	push   %ebp
  800d14:	89 e5                	mov    %esp,%ebp
  800d16:	57                   	push   %edi
  800d17:	56                   	push   %esi
  800d18:	53                   	push   %ebx
  800d19:	8b 55 08             	mov    0x8(%ebp),%edx
  800d1c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800d1f:	eb 03                	jmp    800d24 <strtol+0x11>
		s++;
  800d21:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800d24:	0f b6 0a             	movzbl (%edx),%ecx
  800d27:	80 f9 09             	cmp    $0x9,%cl
  800d2a:	74 f5                	je     800d21 <strtol+0xe>
  800d2c:	80 f9 20             	cmp    $0x20,%cl
  800d2f:	74 f0                	je     800d21 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800d31:	80 f9 2b             	cmp    $0x2b,%cl
  800d34:	75 0a                	jne    800d40 <strtol+0x2d>
		s++;
  800d36:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800d39:	bf 00 00 00 00       	mov    $0x0,%edi
  800d3e:	eb 11                	jmp    800d51 <strtol+0x3e>
  800d40:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800d45:	80 f9 2d             	cmp    $0x2d,%cl
  800d48:	75 07                	jne    800d51 <strtol+0x3e>
		s++, neg = 1;
  800d4a:	8d 52 01             	lea    0x1(%edx),%edx
  800d4d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800d51:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800d56:	75 15                	jne    800d6d <strtol+0x5a>
  800d58:	80 3a 30             	cmpb   $0x30,(%edx)
  800d5b:	75 10                	jne    800d6d <strtol+0x5a>
  800d5d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800d61:	75 0a                	jne    800d6d <strtol+0x5a>
		s += 2, base = 16;
  800d63:	83 c2 02             	add    $0x2,%edx
  800d66:	b8 10 00 00 00       	mov    $0x10,%eax
  800d6b:	eb 10                	jmp    800d7d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800d6d:	85 c0                	test   %eax,%eax
  800d6f:	75 0c                	jne    800d7d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800d71:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800d73:	80 3a 30             	cmpb   $0x30,(%edx)
  800d76:	75 05                	jne    800d7d <strtol+0x6a>
		s++, base = 8;
  800d78:	83 c2 01             	add    $0x1,%edx
  800d7b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800d7d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800d82:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800d85:	0f b6 0a             	movzbl (%edx),%ecx
  800d88:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800d8b:	89 f0                	mov    %esi,%eax
  800d8d:	3c 09                	cmp    $0x9,%al
  800d8f:	77 08                	ja     800d99 <strtol+0x86>
			dig = *s - '0';
  800d91:	0f be c9             	movsbl %cl,%ecx
  800d94:	83 e9 30             	sub    $0x30,%ecx
  800d97:	eb 20                	jmp    800db9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800d99:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800d9c:	89 f0                	mov    %esi,%eax
  800d9e:	3c 19                	cmp    $0x19,%al
  800da0:	77 08                	ja     800daa <strtol+0x97>
			dig = *s - 'a' + 10;
  800da2:	0f be c9             	movsbl %cl,%ecx
  800da5:	83 e9 57             	sub    $0x57,%ecx
  800da8:	eb 0f                	jmp    800db9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800daa:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800dad:	89 f0                	mov    %esi,%eax
  800daf:	3c 19                	cmp    $0x19,%al
  800db1:	77 16                	ja     800dc9 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800db3:	0f be c9             	movsbl %cl,%ecx
  800db6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800db9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800dbc:	7d 0f                	jge    800dcd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800dbe:	83 c2 01             	add    $0x1,%edx
  800dc1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800dc5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800dc7:	eb bc                	jmp    800d85 <strtol+0x72>
  800dc9:	89 d8                	mov    %ebx,%eax
  800dcb:	eb 02                	jmp    800dcf <strtol+0xbc>
  800dcd:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800dcf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800dd3:	74 05                	je     800dda <strtol+0xc7>
		*endptr = (char *) s;
  800dd5:	8b 75 0c             	mov    0xc(%ebp),%esi
  800dd8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800dda:	f7 d8                	neg    %eax
  800ddc:	85 ff                	test   %edi,%edi
  800dde:	0f 44 c3             	cmove  %ebx,%eax
}
  800de1:	5b                   	pop    %ebx
  800de2:	5e                   	pop    %esi
  800de3:	5f                   	pop    %edi
  800de4:	5d                   	pop    %ebp
  800de5:	c3                   	ret    
  800de6:	66 90                	xchg   %ax,%ax
  800de8:	66 90                	xchg   %ax,%ax
  800dea:	66 90                	xchg   %ax,%ax
  800dec:	66 90                	xchg   %ax,%ax
  800dee:	66 90                	xchg   %ax,%ax

00800df0 <__udivdi3>:
  800df0:	55                   	push   %ebp
  800df1:	57                   	push   %edi
  800df2:	56                   	push   %esi
  800df3:	83 ec 0c             	sub    $0xc,%esp
  800df6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800dfa:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800dfe:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800e02:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800e06:	85 c0                	test   %eax,%eax
  800e08:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800e0c:	89 ea                	mov    %ebp,%edx
  800e0e:	89 0c 24             	mov    %ecx,(%esp)
  800e11:	75 2d                	jne    800e40 <__udivdi3+0x50>
  800e13:	39 e9                	cmp    %ebp,%ecx
  800e15:	77 61                	ja     800e78 <__udivdi3+0x88>
  800e17:	85 c9                	test   %ecx,%ecx
  800e19:	89 ce                	mov    %ecx,%esi
  800e1b:	75 0b                	jne    800e28 <__udivdi3+0x38>
  800e1d:	b8 01 00 00 00       	mov    $0x1,%eax
  800e22:	31 d2                	xor    %edx,%edx
  800e24:	f7 f1                	div    %ecx
  800e26:	89 c6                	mov    %eax,%esi
  800e28:	31 d2                	xor    %edx,%edx
  800e2a:	89 e8                	mov    %ebp,%eax
  800e2c:	f7 f6                	div    %esi
  800e2e:	89 c5                	mov    %eax,%ebp
  800e30:	89 f8                	mov    %edi,%eax
  800e32:	f7 f6                	div    %esi
  800e34:	89 ea                	mov    %ebp,%edx
  800e36:	83 c4 0c             	add    $0xc,%esp
  800e39:	5e                   	pop    %esi
  800e3a:	5f                   	pop    %edi
  800e3b:	5d                   	pop    %ebp
  800e3c:	c3                   	ret    
  800e3d:	8d 76 00             	lea    0x0(%esi),%esi
  800e40:	39 e8                	cmp    %ebp,%eax
  800e42:	77 24                	ja     800e68 <__udivdi3+0x78>
  800e44:	0f bd e8             	bsr    %eax,%ebp
  800e47:	83 f5 1f             	xor    $0x1f,%ebp
  800e4a:	75 3c                	jne    800e88 <__udivdi3+0x98>
  800e4c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800e50:	39 34 24             	cmp    %esi,(%esp)
  800e53:	0f 86 9f 00 00 00    	jbe    800ef8 <__udivdi3+0x108>
  800e59:	39 d0                	cmp    %edx,%eax
  800e5b:	0f 82 97 00 00 00    	jb     800ef8 <__udivdi3+0x108>
  800e61:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800e68:	31 d2                	xor    %edx,%edx
  800e6a:	31 c0                	xor    %eax,%eax
  800e6c:	83 c4 0c             	add    $0xc,%esp
  800e6f:	5e                   	pop    %esi
  800e70:	5f                   	pop    %edi
  800e71:	5d                   	pop    %ebp
  800e72:	c3                   	ret    
  800e73:	90                   	nop
  800e74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e78:	89 f8                	mov    %edi,%eax
  800e7a:	f7 f1                	div    %ecx
  800e7c:	31 d2                	xor    %edx,%edx
  800e7e:	83 c4 0c             	add    $0xc,%esp
  800e81:	5e                   	pop    %esi
  800e82:	5f                   	pop    %edi
  800e83:	5d                   	pop    %ebp
  800e84:	c3                   	ret    
  800e85:	8d 76 00             	lea    0x0(%esi),%esi
  800e88:	89 e9                	mov    %ebp,%ecx
  800e8a:	8b 3c 24             	mov    (%esp),%edi
  800e8d:	d3 e0                	shl    %cl,%eax
  800e8f:	89 c6                	mov    %eax,%esi
  800e91:	b8 20 00 00 00       	mov    $0x20,%eax
  800e96:	29 e8                	sub    %ebp,%eax
  800e98:	89 c1                	mov    %eax,%ecx
  800e9a:	d3 ef                	shr    %cl,%edi
  800e9c:	89 e9                	mov    %ebp,%ecx
  800e9e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800ea2:	8b 3c 24             	mov    (%esp),%edi
  800ea5:	09 74 24 08          	or     %esi,0x8(%esp)
  800ea9:	89 d6                	mov    %edx,%esi
  800eab:	d3 e7                	shl    %cl,%edi
  800ead:	89 c1                	mov    %eax,%ecx
  800eaf:	89 3c 24             	mov    %edi,(%esp)
  800eb2:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800eb6:	d3 ee                	shr    %cl,%esi
  800eb8:	89 e9                	mov    %ebp,%ecx
  800eba:	d3 e2                	shl    %cl,%edx
  800ebc:	89 c1                	mov    %eax,%ecx
  800ebe:	d3 ef                	shr    %cl,%edi
  800ec0:	09 d7                	or     %edx,%edi
  800ec2:	89 f2                	mov    %esi,%edx
  800ec4:	89 f8                	mov    %edi,%eax
  800ec6:	f7 74 24 08          	divl   0x8(%esp)
  800eca:	89 d6                	mov    %edx,%esi
  800ecc:	89 c7                	mov    %eax,%edi
  800ece:	f7 24 24             	mull   (%esp)
  800ed1:	39 d6                	cmp    %edx,%esi
  800ed3:	89 14 24             	mov    %edx,(%esp)
  800ed6:	72 30                	jb     800f08 <__udivdi3+0x118>
  800ed8:	8b 54 24 04          	mov    0x4(%esp),%edx
  800edc:	89 e9                	mov    %ebp,%ecx
  800ede:	d3 e2                	shl    %cl,%edx
  800ee0:	39 c2                	cmp    %eax,%edx
  800ee2:	73 05                	jae    800ee9 <__udivdi3+0xf9>
  800ee4:	3b 34 24             	cmp    (%esp),%esi
  800ee7:	74 1f                	je     800f08 <__udivdi3+0x118>
  800ee9:	89 f8                	mov    %edi,%eax
  800eeb:	31 d2                	xor    %edx,%edx
  800eed:	e9 7a ff ff ff       	jmp    800e6c <__udivdi3+0x7c>
  800ef2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ef8:	31 d2                	xor    %edx,%edx
  800efa:	b8 01 00 00 00       	mov    $0x1,%eax
  800eff:	e9 68 ff ff ff       	jmp    800e6c <__udivdi3+0x7c>
  800f04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800f08:	8d 47 ff             	lea    -0x1(%edi),%eax
  800f0b:	31 d2                	xor    %edx,%edx
  800f0d:	83 c4 0c             	add    $0xc,%esp
  800f10:	5e                   	pop    %esi
  800f11:	5f                   	pop    %edi
  800f12:	5d                   	pop    %ebp
  800f13:	c3                   	ret    
  800f14:	66 90                	xchg   %ax,%ax
  800f16:	66 90                	xchg   %ax,%ax
  800f18:	66 90                	xchg   %ax,%ax
  800f1a:	66 90                	xchg   %ax,%ax
  800f1c:	66 90                	xchg   %ax,%ax
  800f1e:	66 90                	xchg   %ax,%ax

00800f20 <__umoddi3>:
  800f20:	55                   	push   %ebp
  800f21:	57                   	push   %edi
  800f22:	56                   	push   %esi
  800f23:	83 ec 14             	sub    $0x14,%esp
  800f26:	8b 44 24 28          	mov    0x28(%esp),%eax
  800f2a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800f2e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800f32:	89 c7                	mov    %eax,%edi
  800f34:	89 44 24 04          	mov    %eax,0x4(%esp)
  800f38:	8b 44 24 30          	mov    0x30(%esp),%eax
  800f3c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800f40:	89 34 24             	mov    %esi,(%esp)
  800f43:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800f47:	85 c0                	test   %eax,%eax
  800f49:	89 c2                	mov    %eax,%edx
  800f4b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800f4f:	75 17                	jne    800f68 <__umoddi3+0x48>
  800f51:	39 fe                	cmp    %edi,%esi
  800f53:	76 4b                	jbe    800fa0 <__umoddi3+0x80>
  800f55:	89 c8                	mov    %ecx,%eax
  800f57:	89 fa                	mov    %edi,%edx
  800f59:	f7 f6                	div    %esi
  800f5b:	89 d0                	mov    %edx,%eax
  800f5d:	31 d2                	xor    %edx,%edx
  800f5f:	83 c4 14             	add    $0x14,%esp
  800f62:	5e                   	pop    %esi
  800f63:	5f                   	pop    %edi
  800f64:	5d                   	pop    %ebp
  800f65:	c3                   	ret    
  800f66:	66 90                	xchg   %ax,%ax
  800f68:	39 f8                	cmp    %edi,%eax
  800f6a:	77 54                	ja     800fc0 <__umoddi3+0xa0>
  800f6c:	0f bd e8             	bsr    %eax,%ebp
  800f6f:	83 f5 1f             	xor    $0x1f,%ebp
  800f72:	75 5c                	jne    800fd0 <__umoddi3+0xb0>
  800f74:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800f78:	39 3c 24             	cmp    %edi,(%esp)
  800f7b:	0f 87 e7 00 00 00    	ja     801068 <__umoddi3+0x148>
  800f81:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800f85:	29 f1                	sub    %esi,%ecx
  800f87:	19 c7                	sbb    %eax,%edi
  800f89:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800f8d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800f91:	8b 44 24 08          	mov    0x8(%esp),%eax
  800f95:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800f99:	83 c4 14             	add    $0x14,%esp
  800f9c:	5e                   	pop    %esi
  800f9d:	5f                   	pop    %edi
  800f9e:	5d                   	pop    %ebp
  800f9f:	c3                   	ret    
  800fa0:	85 f6                	test   %esi,%esi
  800fa2:	89 f5                	mov    %esi,%ebp
  800fa4:	75 0b                	jne    800fb1 <__umoddi3+0x91>
  800fa6:	b8 01 00 00 00       	mov    $0x1,%eax
  800fab:	31 d2                	xor    %edx,%edx
  800fad:	f7 f6                	div    %esi
  800faf:	89 c5                	mov    %eax,%ebp
  800fb1:	8b 44 24 04          	mov    0x4(%esp),%eax
  800fb5:	31 d2                	xor    %edx,%edx
  800fb7:	f7 f5                	div    %ebp
  800fb9:	89 c8                	mov    %ecx,%eax
  800fbb:	f7 f5                	div    %ebp
  800fbd:	eb 9c                	jmp    800f5b <__umoddi3+0x3b>
  800fbf:	90                   	nop
  800fc0:	89 c8                	mov    %ecx,%eax
  800fc2:	89 fa                	mov    %edi,%edx
  800fc4:	83 c4 14             	add    $0x14,%esp
  800fc7:	5e                   	pop    %esi
  800fc8:	5f                   	pop    %edi
  800fc9:	5d                   	pop    %ebp
  800fca:	c3                   	ret    
  800fcb:	90                   	nop
  800fcc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800fd0:	8b 04 24             	mov    (%esp),%eax
  800fd3:	be 20 00 00 00       	mov    $0x20,%esi
  800fd8:	89 e9                	mov    %ebp,%ecx
  800fda:	29 ee                	sub    %ebp,%esi
  800fdc:	d3 e2                	shl    %cl,%edx
  800fde:	89 f1                	mov    %esi,%ecx
  800fe0:	d3 e8                	shr    %cl,%eax
  800fe2:	89 e9                	mov    %ebp,%ecx
  800fe4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800fe8:	8b 04 24             	mov    (%esp),%eax
  800feb:	09 54 24 04          	or     %edx,0x4(%esp)
  800fef:	89 fa                	mov    %edi,%edx
  800ff1:	d3 e0                	shl    %cl,%eax
  800ff3:	89 f1                	mov    %esi,%ecx
  800ff5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800ff9:	8b 44 24 10          	mov    0x10(%esp),%eax
  800ffd:	d3 ea                	shr    %cl,%edx
  800fff:	89 e9                	mov    %ebp,%ecx
  801001:	d3 e7                	shl    %cl,%edi
  801003:	89 f1                	mov    %esi,%ecx
  801005:	d3 e8                	shr    %cl,%eax
  801007:	89 e9                	mov    %ebp,%ecx
  801009:	09 f8                	or     %edi,%eax
  80100b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  80100f:	f7 74 24 04          	divl   0x4(%esp)
  801013:	d3 e7                	shl    %cl,%edi
  801015:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  801019:	89 d7                	mov    %edx,%edi
  80101b:	f7 64 24 08          	mull   0x8(%esp)
  80101f:	39 d7                	cmp    %edx,%edi
  801021:	89 c1                	mov    %eax,%ecx
  801023:	89 14 24             	mov    %edx,(%esp)
  801026:	72 2c                	jb     801054 <__umoddi3+0x134>
  801028:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  80102c:	72 22                	jb     801050 <__umoddi3+0x130>
  80102e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  801032:	29 c8                	sub    %ecx,%eax
  801034:	19 d7                	sbb    %edx,%edi
  801036:	89 e9                	mov    %ebp,%ecx
  801038:	89 fa                	mov    %edi,%edx
  80103a:	d3 e8                	shr    %cl,%eax
  80103c:	89 f1                	mov    %esi,%ecx
  80103e:	d3 e2                	shl    %cl,%edx
  801040:	89 e9                	mov    %ebp,%ecx
  801042:	d3 ef                	shr    %cl,%edi
  801044:	09 d0                	or     %edx,%eax
  801046:	89 fa                	mov    %edi,%edx
  801048:	83 c4 14             	add    $0x14,%esp
  80104b:	5e                   	pop    %esi
  80104c:	5f                   	pop    %edi
  80104d:	5d                   	pop    %ebp
  80104e:	c3                   	ret    
  80104f:	90                   	nop
  801050:	39 d7                	cmp    %edx,%edi
  801052:	75 da                	jne    80102e <__umoddi3+0x10e>
  801054:	8b 14 24             	mov    (%esp),%edx
  801057:	89 c1                	mov    %eax,%ecx
  801059:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  80105d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  801061:	eb cb                	jmp    80102e <__umoddi3+0x10e>
  801063:	90                   	nop
  801064:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  801068:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  80106c:	0f 82 0f ff ff ff    	jb     800f81 <__umoddi3+0x61>
  801072:	e9 1a ff ff ff       	jmp    800f91 <__umoddi3+0x71>
