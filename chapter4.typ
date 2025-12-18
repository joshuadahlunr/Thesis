#import "util.typ": unumbered_heading 
#import "@preview/cetz:0.3.4": canvas, draw, palette
#import "@preview/cetz-plot:0.1.1": chart

= An Embeddable Virtual Machine <chapter:mizu>

This chapter first appeared as a conference publication in SERA 2025~@dahl2025. #linebreak()
J. Dahl, Q. Contaldi, K. Partovi and F. C. Harris, Jr. "Mizu: A Lightweight Multi-Threaded Threaded-Code Interpreter that Can Run Almost Anywhere with a C++ Compiler" The 23rd IEEE/ACIS International Conference on Software Engineering, Management and Applications (SERA 2025) May 29-31, 2025 Las Vegas, NV.

#unumbered_heading(centered: true)[Abstract]

We present Mizu, a threaded-code interpreter for an assembly-like language designed to be embedded inside compilers. 
Mizu has three primary goals: to be lightweight, portable, and extensible. 
We explore Mizu’s lightweight core instruction set, along with several of its extensions and some of our methods for further extension, and the platforms it has been ported to. 
Additionally, we demonstrate how two high-level features—threading and foreign function interfaces—can be spelled at the level of an assembly language. 
Finally, we compare Mizu to several other popular interpreted languages and find that it's performance sits comfortably between JIT interpreters (approximately 4 times slower on a CPU straining task) and regular interpreters (approximately 8.5 times faster on the same task) all with only fourty-six core instructions.

== Introduction

Recently, compile-time execution has become an increasingly important goal for compilers targeting imperative languages. 
For example, since 2011, C++ has been expanding its support for the `constexpr` keyword~@constexpr, which encourages code to be executed at compile time rather than runtime.
Similarly, in 2016, Zig emerged as a language with `comptime`~@comptime as one of its central features. 
Consequently, compilers must now function as interpreters. While interpreters have been extensively researched, little work has focused on their role as ancillary components of a compiler.

_Mizu_~@mizu is designed to serve as a backend target for compilers, in a similar role to LLVM's Intermediate Representation (IR)~@llvm. 
While LLVM IR was designed to be paired with a compiler backend that reduces it to native machine code, _Mizu_ is intended to function in environments where compiling is difficult, such as microcontrollers where running code from certain regions of memory is sometimes explicitly blocked.

The system's name is derived from the Japanese word for water: 水 (Mizu), symbolizing its designed ability to adapt and fit into a wide variety of contexts. 
It is thus designed with three primary goals: to be lightweight, portable, and extensible.

In our effort to create a system that is both lightweight and extensible, we drew inspiration from RISC-V~@Cui2023, which offers several minimal instruction sets known as "extensions."
To ensure portability, we implemented these instructions as simple C++ functions, all sharing a single tail-call optimized signature. 
These functions are then chained together into a threaded-code interpreter. 
Instructions are essentially functions with a predefined signature. 
Thus, adding a new instruction is straightforward: first define a function that specifies the desired behavior; then add a special macro at the end to properly dispatch the next instruction. 
Adding new third-party instructions, such as manipulating a compiler's data structures, is easy with this design.
_Mizu_ supports loading and interfacing with shared libraries, also making integrations possible after the design phase.

In addition to these primary goals, _Mizu_ explores implementing features found in higher-level interpreters, such as threading and interfacing with foreign functions—all the way down to the assembly instruction level. 
@4:sect:related reviews alternative interpreters in the literature as well as some background on threaded-code, while @4:sect:design delves into the design of _Mizu_'s Instruction Set and Abstract Virtual Machine. 
@4:sect:benchmark provides a comparison of _Mizu_ to several popular peer interpreters and assesses its performance on its supported platforms. 
Finally, @4:sect:limitations discusses some of _Mizu_'s limitations and highlights areas for future exploration.

== Related Work <4:sect:related>

_Mizu_ is a threaded code interpreter based on the subroutine-threaded code model, developed by Curley~@curley1993 and explained by Berndl~@Berndl2005. 
In this architecture, each virtual instruction is a function that ends with a return statement.
The virtual program's instructions are loaded and translated into a sequence of call instructions, each targeting an instruction function. 
Calls are executed natively, threading the code through each function.

Shifting focus, Anderson and Matson~@Anderson2021 aimed to bypass Python's Global Interpreter Lock (GIL) by integrating OpenMP support into Numba~@numba, a JIT compiler for Python enabling multi-threaded execution, thereby allowing parallel execution of Python code.
Numba generated multi-threaded code using LLVM, improving performance to match C code. 
However, this approach adds complexity, requiring developers to learn both OpenMP directives and Numba’s JIT compilation process.
We illustrate a simpler method of implementing multi-threading into an interpreter.

Wihuri~@wihuri2023 investigates parallelism and multithreading in a JavaScript Web Application for meteorological visualization. 
Motivated by the growing complexity of web apps and the need to improve performance, the study identifies bottlenecks such as slow weather animation updates, high XML parsing times, and rendering delays. 
Proof-of-concept parallelism techniques using Web Workers and parallel JavaScript APIs were implemented. 
Parallelism improved some areas, namely parsing XML in separate threads. 
However, JavaScript’s architectural constraints limited its efficiency. 
The study highlights JavaScript’s limitations for multithreading and offers practical insights.
Conversely, the findings are specific to a single application and do not explore redesigns of JavaScript's event loop for better parallelism.

Maintaining a focus on "web" technologies, the design of _Mizu_ is inspired by WASM3~@wasm3, a threaded-code interpreter for WebAssembly. 
WASM3 employs a subroutine threaded-code model, which links together an array of function pointers that are then recursively executed, with each function calling the next in the array. 
To efficiently implement this using C, the instruction functions are designed so their invocations can be tail-call optimized; 
otherwise, the interpreter will quickly fill the physical stack with "useless" function frames.
Similarly, _Mizu_ is an interpreter designed to emulate a custom instruction set inspired by RISC-V.

== Design <4:sect:design>

Programs in _Mizu_ are stored as an array of `opcode`s. Each `opcode` contains a function pointer to a _Mizu_ instruction, as well as three 16-bit register values: `out`, `a`, and `b`. 
These values represent the indices of the registers used for saving to or loading from. 
@lst:add_instruction shows the full implementation of the add instruction, which shows how register saving and loading is performed.

#figure(
  caption: [
    A demonstrative example of a _Mizu_ instruction which takes a program counter (`pc`), array of `registers`, `stack_boundary`, and a pointer to the bottom (top in theoretical terms) of the stack (`sp`). 
    Every instruction is expected to share this signature and to end with the `MIZU_NEXT` macro, which handles dispatching to the next instruction in the program.
  ],
```cpp
void* mizu::instructions::add(
    mizu::opcode* pc, 
    uint64_t* registers, 
    uint8_t* stack_boundary, 
    uint8_t* sp) 
{
    registers[pc->out] = registers[pc->a] 
        + registers[pc->b];
    MIZU_NEXT();
}
```
) <add_instruction>

_Mizu_ targets a theoretical emulated 64-bit register machine, that is deeply influenced by `rv64im` architecture~@Cui2023. 
There are two main distinctions between this machine and other typical abstract machines:

1. First, _Mizu_ does not provide a mechanism for a "data segment." Since _Mizu_ is designed to be embedded in other applications, it assumes that these applications will supply pointers to already-allocated memory for it to manipulate.
2. Second, _Mizu_ does not distinguish between register types. Rather than providing different types of registers for integers, floats, vectors, etc., all registers are treated as raw 64-bit blobs that instructions can interpret as necessary.

As a result, _Mizu_ provides a huge 256 registers. 
It is currently assumed that pointers to raw data or function pointers within the executing program will be placed in higher-numbered registers, while temporary data and function arguments are placed in the lower-numbered registers. 
In addition to the registers, _Mizu_ provides a stack with a configurable static size that functions can use. 
Both the registers and the stack are stored in the same "region" in memory, with registers counting upwards and the stack counting downwards. 
A pointer is used to mark the boundary for bounds-checking purposes.

=== Calling Convention

In the _Mizu_ calling convention, registers do not differ based on the data stored in them, but they are assigned specific meanings. 
Register zero always holds the value zero, and its value is reset by the instruction dispatch machinery placed in a macro at the end of every instruction. 
Registers one through ten are designated as temporary registers, while registers twelve and above are used for passing arguments and storing host resources.
Register eleven is reserved specifically as the return address register. 
Additionally, all registers are caller-saved, meaning that callee functions are free to modify any of the registers without the risk of overwriting important data.

=== Core Instruction Set

_Mizu_'s Core Instruction Set handles jumps, branching, and integer operations.
All forty-six of _Mizu_'s core instructions are summarized in @tbl:core.
Typically, an instruction loads the values from its `a` and `b` registers and then stores the result of some computation in its `out` register.

#figure(
  placement: top,
  caption: [The Core _Mizu_ Instructions.],
  table(
    columns: 2,
		align: left,
		stroke: none,
    table.header(
      [*Instruction*], [*Description (C++)*]
    ),
    table.hline(),
      [label], [```cpp; // noop``` #footnote[`a` and `b` treated as a single integer immediate value] <fn:int-imediate>],
      [find_label], [```cpp out = &matching_label```@fn:int-imediate],
      [halt], [```cpp std::exit(0)```],
      [debug_print(\_binary)], [```cpp printf("%\n", a)``` #footnote[Prints the register in several formats, including binary if the instruction is used.]],
      [load_immediate], [```cpp out = immediate``` @fn:int-imediate ],
      [load_upper_immediate], [```cpp out = immediate << 32```@fn:int-imediate #footnote[Since immediates are only 32 bits, two instructions are needed to load a 64-bit immediate.]],
      [convert_to_u8|16|32|64], [```cpp out = (uint8|16|32|64_t)a``` #footnote[The values are cast to the provided types. Stack accesses are bounds-checked in debug mode.] <fn:cast>],
      [stack_load_u8|16|32|64], [```cpp out = (uint8|16|32|64_t)``` stack_pointer[a] @fn:cast],
      [stack_store_u8|16|32|64], [```cpp stack_pointer[b] = (uint8|16|32|64_t) a``` @fn:cast],
      [stack_push(\_immediate)], [```cpp stack_pointer -= a|immediate```#footnote[Either `a` as a register or `a` and `b` treated as a single integer immediate value.] <fn:optional-int-imediate>],
      [stack_pop(\_immediate)], [```cpp stack_pointer += a|immediate```@fn:optional-int-imediate],
      [jump_relative(\_immediate)], [```cpp out = pc + 1; pc += a|immediate```@fn:optional-int-imediate],
      [jump_to], [```cpp out = pc + 1; pc = a```],
      [branch_relative(\_immediate)], [```cpp out = pc + 1; if(a) pc += b``` #footnote[Or a signed immediate stored in place of `b`.]],
      [branch_to], [```cpp out = pc + 1; if(a) pc = b```],
      [set_if_equal], [```cpp out = a == b```],
      [set_if_not_equal], [```cpp out = a != b```],
      [set_if_less(\_signed)], [```cpp out = a < b```],
      [set_if_greater_equal(\_signed)], [```cpp out = a >= b```],
      [add], [```cpp out = a + b```],
      [subtract], [```cpp out = a - b```],
      [multiply], [```cpp out = a * b```],
      [divide], [```cpp out = a / b```],
      [modulus], [```cpp out = a % b```],
      [shift_left], [```cpp out = a << b```],
      [shift_right(\_arithmetic)], [```cpp out = a >> b``` #footnote[The arithmetic version sign-extends the result.]],
      [bitwise_xor], [```cpp out = a ^ b```],
      [bitwise_and], [```cpp out = a & b```],
      [bitwise_or], [```cpp out = a | b```],
  )
) <core>

Two instructions that deviate from the typical pattern are `label` and `find_label`. 
Because _Mizu_ programs are simple arrays, there is no guarantee that they will be located at a stable address in memory, especially if they are loaded from disk. 
Therefore, we cannot assume where in memory a specific jump location will be stored. 
To address this, the `label` instruction acts as a no-op target for the `find_label` instruction to locate. 
The `a` and `b` operands of both instructions are treated as a single 32-bit immediate integer. 
The `find_label` instruction searches through the program, scanning a configurable "maximum label search distance" number of instructions. 
If no label is found with matching `a` and `b` operands, it then performs a linear scan upwards, storing the address of the found `label` in `out`. 
Due to the runtime cost, these instructions should be invoked as infrequently as possible. 
In our example code, `find_label` instructions are placed at the start of the program. Following this pattern is not always possible; 
however, it's strongly recommended to avoid placing `find_label` inside loops (direct iteration or recursive).

Jumps and branches are also notable deviations. 
Jump instructions can take one of three types of operands: a register storing an offset, an immediate value (which is the combination of the `a` and `b` registers into a 32-bit integer), or a register holding the memory address of an instruction to jump to (obtained via the `find_label` instruction for example).
These instructions then update the program counter, which points to the current `opcode`. 
These three jump instructions are respectively named `jump_relative`, `jump_relative_immediate`, and `jump_to`, depending on the type of operand they use. For relative jump instructions, offsets are given as relative values.
A zero re-executes the current instruction, negative one re-executes the previous, and positive two skips over one instruction and executes the next.

Jump-like instructions store a pointer to the next instruction in their `out` register. 
Function calls are thus easy, since they can be represented using the `jump_to` instruction, which jumps to the function and stores the next instruction in the `return_address` register, which can then be `jump_to`ed when the function should return.

There are three corresponding branch instructions that take a register storing a condition. 
This condition is directly passed into a C++ `if`-statement: if the condition register holds zero, the branch is not followed, but if it contains one or greater, the branch is followed. 
These branch instructions differ from RISC-V, which compares two registers before potentially jumping; instead, they behave more similarly to x86, where separate comparison instructions (such as `set_if_<something>` in _Mizu_) are used, and the result of these comparisons are then considered by the branch instructions. 
This design eliminates the need for jump instructions by using branch instructions with a non-zero condition register. 
Yet, we retained jump instructions to avoid the overhead of an `if`-statement and maintaining a non-zero register value.

=== Floating Point Extension Instructions

_Mizu_'s built-in extensions include several instructions for floating-point operations and unsafe or host memory manipulation. 
The floating-point instructions have two variants: one for 32-bit IEEE 754 single-precision floating-point numbers~@ieee754, and another for 64-bit IEEE 754 double-precision floating-point numbers. 

Note that all floating-point instructions assume both operands are represented using the same type. 
If the operands are of different types, the conversion instructions, such as `convert_f32|64_to_f64|32` or `convert(_signed)_to_f32|64`, can correct the discrepancy. 
The instruction summary can be found in @tbl:float.

#figure(
  caption: [The Floating Point _Mizu_ Instructions.],
  table(
    columns: 2,
		align: left,
		stroke: none,
    table.header(
      [*Instruction*], [*Description (C++)*]
    ),
    table.hline(),
      [stack_load_f32|64], [```cpp out = (float) stack_pointer[a]```],
      [stack_store_f32|64], [```cpp stack_pointer[a] = (float) b```],
      [convert(_signed)_to_f32|64], [```cpp out = (float) a```],
      [convert(_signed)_from_f32|64], [```cpp out = (uint64_t|int64_t) a```],
      [convert_f32|64_to_f64|32], [```cpp
(float)out = (double)a
(double)out = (float)a
    ```],
      [add_f32|64], [```cpp out = a + b```],
      [subtract_f32|64], [```cpp out = a - b```],
      [multiply_f32|64], [```cpp out = a * b```],
      [divide_f32|64], [```cpp out = a / b```],
      [max_f32|64], [```cpp out = std::max(a, b)```],
      [min_f32|64], [```cpp out = std::min(a, b)```],
      [sqrt_f32|64], [```cpp out = std::sqrt(a)```],
      [set_if_equal_f32|64], [```cpp out = a == b```],
      [set_if_not_equal_f32|64], [```cpp out = a != b```],
      [set_if_less_f32|64], [```cpp out = a < b```],
      [set_if_greater_equal_f32|64], [```cpp out = a >= b```],
      [set_if_negative_f32|64], [```cpp out = std::signbit(a)```],
      [set_if_positive_f32|64], [```cpp out = !std::signbit(a)```],
      [set_if_infinity_f32|64], [```cpp out = std::isinf(a)```],
      [set_if_nan_f32|64], [```cpp out = std::isnan(a)```],
  )
) <float>

=== Unsafe Extension Instructions

_Mizu_ integrates with a host application and assumes it will manipulate memory blocks provided by the host. 
It supports a small set of "unsafe" operations for direct memory manipulation, but a lack of checks leaves proper usage to the programmer.

The simplest of these instructions is `unsafe::allocate`, which creates a block of memory with a size specified in register `a` and stores a pointer to this memory in the `out` register. 
This allocated memory may be freed using the `unsafe::free_allocated` instruction, which also sets the register containing the freed pointer to the value stored in register `b`. 

By default, `opcode` values are set to zero, so register `b` defaults to register zero, which always stores zero. 
This results in the freed pointer being swapped with null by default.

Before a pointer is freed, data can be copied into it using the `unsafe::copy_memory` instruction. 
This instruction takes a pointer to the destination memory (`out`), a pointer to the source memory (`a`), and the number of bytes to copy (`b`).

Copying host memory is only useful if it can be moved into a _Mizu_ register or _Mizu_'s stack, which is why the `unsafe::pointer_to_stack` and `unsafe::pointer_to_register` instructions exist. 
These allow for the creation of a pointer that can be used with `unsafe::copy_memory`.

An example program snippet showing these operations in action—where one hundred 64-bit integers are copied from host memory to _Mizu_ stack memory—can be found in @lst:pointer_copy. 
A summary of all these instructions is provided in @tbl:unsafe.

#figure(
  caption: [Snippet from a _Mizu_ program which reserves space on _Mizu_'s stack for 100 64-bit integers and then copies them from an arbitrary host pointer.],
```cpp
// x204 = sizeof(uint64_t)
opcode{load_immediate, 204}.set_immediate(sizeof(uint64_t)), // type size constant
// a0 (size) = 100
opcode{load_immediate, registers::a(0)}.set_immediate(100),
// t0 = sizeof(uint64_t[100])
opcode{multiply, registers::t(0), 204, registers::a(0)}, // 204 == sizeof(uint64_t)
opcode{stack_push, 0, registers::t(0)},
// t1 = stack
opcode{unsafe::pointer_to_stack, registers::t(1)}, 
// t2 = host
opcode{load_immediate, registers::t(2)}.set_host_pointer_lower_immediate(host_ptr),
opcode{load_upper_immediate, registers::t(2)}.set_host_pointer_upper_immediate(host_ptr),
// std::memcpy(stack, host, sizeof(uint64_t[100]))
opcode{unsafe::copy_memory, registers::t(1), registers::t(2), registers::t(0)},
```
) <pointer_copy>

#figure(
  caption: [The Unsafe _Mizu_ Instructions.],
  table(
    columns: 2,
		align: left,
		stroke: none,
    table.header(
      [*Instruction*], [*Description (C++)*]
    ),
    table.hline(),
      [unsafe::allocate], [```cpp out = malloc(a)```],
      [unsafe::free_allocated], [```cpp free(a); a = b```],
      // [allocate_fat_pointer], [out = fp_alloc(a, b)],
      // [free_fat_pointer], [fp_free(a); a = b],
      [unsafe::pointer_to_stack], [```cpp out = &stack_pointer[a]```],
      [unsafe::pointer_to_register], [```cpp out = &a```],
      [unsafe::copy_memory], [```cpp std::memcpy(out, a, b)```],
  )
) <unsafe>

=== Parallel Extension Instructions

_Mizu_ offers instructions for creating and coordinating program threads. 
It supports two primary methods: C++11 threading for cross-platform portability—a key reason _Mizu_ uses C++ over more universally portable languages like C—and a custom coroutine-based emulation layer for platforms without hardware thread support. On resource-constrained platforms without hardware threading, the coroutine fallback uses a simple algorithm that runs one operation from each active thread before moving to the next.

When a new thread is forked, it inherits a copy of the parent thread’s registers and stack, enabling inter-thread communication immediately. 
Each of the three types of fork instructions follows the same semantics as the corresponding jump instructions. The key difference is that the forked thread "jumps" to a new instruction while the parent continues to the next one.

When threads need to communicate post-creation, _Mizu_ provides instructions to create and manipulate a communication channel. 
The channel must be created before the forked thread, ensuring that it is present in a register for both parent and child threads.

Channels support sending and receiving register-sized data blobs. When created, they allow specifying a maximum queue size. 
Threads attempting to send to a full channel or receive from an empty one will be blocked until another thread changes the channel’s state.

For synchronization instructions, the coroutine fallback checks whether the necessary state is available. 
If not, it moves the waiting thread’s program counter back by one instruction, causing the blocking operation to retry on the next activation.

A summary of these instructions is shown in @tbl:parallel.

#figure(
  caption: [The Parallel _Mizu_ Instructions.],
  table(
    columns: 2,
		align: left,
		stroke: none,
    table.header(
      [*Instruction*], [*Description (C++)*]
    ),
    table.hline(),
      [fork_relative(\_immediate)], [```cpp
std::thread([env]{ 
  env = env.clone(); 
  start(env, pc + a | immediate); 
})
    ```],
      [fork_to], [```cpp
std::thread([env]{ 
  env = env.clone(); 
  start(env, a); 
})
    ```],
      [join_thread], [```cpp a.join(); a = b```],
      [sleep_microseconds], [```cpp std::thread::sleep_for(a)```],
      [channel_create], [```cpp out = channel({.capacity = a})```],
      [channel_close], [```cpp a.close(); a = b```],
      [channel_receive], [```cpp out = a.receive()```],
      [channel_send], [```cpp a.send(b)```],
  )
) <parallel>

=== Foreign Function Extension Instructions

The final set of extensions in _Mizu_ is focused on extensibility, though it introduces greater potential for unsafe behavior. 
Rather than embedding all features as instructions in the host application, _Mizu_ enables dynamic loading of shared libraries and direct function calls.

Shared library loading is handled through a wrapper over platform-specific system calls. 
Function calls are executed using either _libffi_~@libffi or a custom trampoline system that supports up to four arguments. 
The trampoline fallback is used only when _libffi_ is unavailable for a platform, making this extension the least portable among _Mizu_'s features.

Shared objects can be loaded using the `ffi::load_library` instruction or through `mizu::loader::load_library`. 
After loading, function pointers are retrieved via `ffi::load_library_function` or `mizu::loader::lookup`.

Function pointers are invoked similarly to _Mizu_'s internal calls: arguments are placed into registers, but instead of jumping to a code block, `ffi::call` or `ffi::call_with_return` is used. 
These instructions read the function address from register `a`, the interface description from register `b`, and call the function using the underlying ABI (via _libffi_ or trampoline). 
If `ffi::call_with_return` is used, the return value is stored in `out`.

To prepare for a call, the function signature must first be defined using a sequence of `ffi::push_type_*` instructions. 
These define the return type (beginning with `ffi::push_type_void` for void) followed by the parameter types. 
After all types are specified, the `ffi::create_interface` instruction builds the interface object and places a pointer to it in `out`, clearing the temporary type stack.

A summary of these foreign function instructions is shown in @tbl:ffi.

#figure(
  caption: [The Foreign Function _Mizu_ Instructions.],
  table(
    columns: 2,
		align: left,
		stroke: none,
    table.header(
      [*Instruction*], [*Description (C++)*]
    ),
    table.hline(),
    [ffi::push_type_void], [```cpp interface.push_back(void)```],
    [ffi::push_type_pointer], [```cpp interface.push_back(void*)```],
    [ffi::push_type_i32], [```cpp interface.push_back(int32_t)```],
    [ffi::push_type_u32], [```cpp interface.push_back(uint32_t)```],
    [ffi::push_type_i64], [```cpp interface.push_back(int64_t)```],
    [ffi::push_type_u64], [```cpp interface.push_back(uint64_t)```],
    [ffi::push_type_f32], [```cpp interface.push_back(float)```],
    [ffi::push_type_f64], [```cpp interface.push_back(double)```],
    [ffi::create_interface], [```cpp out = std::move(interface.create())```],
    [ffi::call], [```cpp ((b) a)(a0, a1, a2, ...)```],
    [ffi::call_with_return], [```cpp out = ((b) a)(a0, a1, a2, ...)```],
    [ffi::load_library], [```cpp out = dlopen(a)```#footnote[The last parameter must store a pointer to a null-terminated C string.] <fn:c-string>],
    [ffi::load_library_function], [```cpp out = dlsym(a, b)```@fn:c-string]
  )
) <ffi>

== Benchmark Results <4:sect:benchmark>

Designing a new interpreter is useful, but its effectiveness is limited without support for multiple platforms. 
To prove this, we conducted two benchmarks: one to compare the performance of _Mizu_ against several other popular interpreters, and another to assess _Mizu_'s performance across all of its supported platforms.

For both tests, we used a custom-built x86 machine (Intel i7-13700K, 32GB DDR5-6400 RAM, Samsung 980 Pro 1TB SSD) running Ubuntu Linux. 
For the platform-specific test, we also utilized the same x86 machine running Windows and an M2 Pro 32GB Mac Mini.

To benchmark, we used Nanobench~@nanobench, a C++ library that runs a code snippet multiple times and averages the execution time. 
_Mizu_ was linked into the runner code, while test programs—one recursively calculating the 40th Fibonacci number to strain a single CPU core, and another using bubble-sort to sort 1100 random integers, stressing memory access—were loaded from disk. 
This setup allowed for a fair comparison with other languages, which were also benchmarked using Nanobench via C's `system` function. 
The code for the benchmarks, along with additional detailed results that we do not have space to include here, are available on our GitHub~@benchmark.

The first benchmark's results are presented in @fig:4:lang-bench. 
_Mizu_ runs an average of 4× slower than JIT interpreters; 
however, it outperforms regular interpreters by an average of 8.5× on the Recursive Fibonacci problem. In comparison to native code, _Mizu_ is at least an order of magnitude slower. 
_Mizu_ may even outperform JIT interpreters in bulk processing tasks involving large amounts of memory accesses (although the sample size is small). 
Overall, the results align closely with our expectations for a low-level, assembly-like interpreter.

#figure(
  placement: bottom,
  caption: [
    Comparison of the execution time, in seconds (lower is better), for _Mizu_ (compiled with GCC and Clang) compared to a Native Executable, NodeJS~@nodejs, C\# (DotNet8)~@dotnet, LuaJIT~@luajit, Lua~@lua, Python~@cpython, Numba~@numba, and WASM3~@wasm3.
  ],
  [
    #let fibData1 = (
      ([Mizu/GCC], 1.934022423),
      ([Mizu/Clang], 1.937856961),
      ([Native], 0.0065961223),
      ([NodeJS], 0.394396350),
      ([C\#], 0.245554699),
      ([LuaJIT], 0.565252299),
      ([Lua], 3.311031864),
      ([Python], 3.414371980),
      ([Numba], 3.599891078),
      ([WASM3], 9.744831833),
    )
    #let sortData1 = (
      ([Mizu/GCC], 0.00865246956),
      ([Mizu/Clang], 0.00868745657),
      ([Native], 0.00204536301),
      ([NodeJS], 0.05102572966),
      ([C\#], 0.02386589532),
      ([LuaJIT], 0.01624379376),
      ([Lua], 0.02135530702),
      ([Python], 0.07880222860),
      ([Numba], 0.25598121839),
      ([WASM3], 0.02106771954),
    )
    #canvas({
      draw.content((6, 6.25), [Fibonacci(40)])
      chart.barchart(fibData1, x-label: [Time (seconds)], size: (12, 6), orientation: "horizontal", title: [Fibonacci(40)], bar-style: palette.blue)
    })
    #colbreak()
    #canvas({
      draw.content((6, 6.25), [Bubble-Sort(1100)])
      chart.barchart(sortData1, x-label: [Time (seconds)], size: (12, 6), orientation: "horizontal", title: [Bubble-Sort(1100)])
    })
  ]
) <4:lang-bench>

The results from the second benchmark, shown in @fig:platformm-bench, display a similar pattern across each platform for the two test programs, though the magnitude of the results differ. 
This suggests that _Mizu_’s performance is stable and not subject to significant fluctuations. 
It also demonstrates that _Mizu_ runs on the web, though its performance there is not impressive.

#figure(
  caption: [
    Comparison of the execution time, in seconds, for _Mizu_ running on (from bottom to top) Linux (compiled with GCC), Linux (compiled with Clang), Windows (compiled with GCC), M2 Mac (compiled with Apple-Clang), Chrome on Linux (compiled with Emscripten~@emscripten), Firefox on Linux (compiled with Emscripten), and NodeJS on Linux (compiled with WASI-SDK~@wasisdk).
  ],
  [
    #let fibData2 = (
      ([Linux/GCC], 1.934022423),
      ([Linux/Clang], 1.937856961),
      ([Windows/GCC], 1.881302200),
      ([Mac/Clang], 2.964114500),
      ([Chrome/Em], 20.178235000),
      ([Firefox/Em], 45.185000000),
      ([NodeJS/WASI], 13.429288639),
    )
    #let sortData2 = (
      ([Linux/GCC], 0.00865246956),
      ([Linux/Clang], 0.00868745657),
      ([Windows/GCC], 0.00075370000), // TODO: Correct?
      ([Mac/Clang], 0.01231161076),
      ([Chrome/Em], 0.08124059524),
      ([Firefox/Em], 0.20778232143),
      ([NodeJS/WASI], 0.05743489781),
    )
    #canvas({
      draw.content((6, 5.25), [Fibonacci(40)])
      chart.barchart(fibData2, x-label: [Time (seconds)], size: (12, 5), orientation: "horizontal", title: [Fibonacci(40)], bar-style: palette.blue)
    })
    #colbreak()
    #canvas({
      draw.content((6, 5.25), [Bubble-Sort(1100)])
      chart.barchart(sortData2, x-label: [Time (seconds)], size: (12, 5), orientation: "horizontal", title: [Bubble-Sort(1100)])
    })
  ]
) <platformm-bench>

These results imply that a low-level interpreter like _Mizu_ can perform well compared to higher-level interpreters. 
More work is needed to further solidify this hypothesis.

== Limitations & Future Work <4:sect:limitations>

_Mizu_ relies on a threaded-code architecture, depending on compilers supporting tail call optimization. 
We added "almost" to the title of this paper because Microsoft's Visual C++ compiler does not seem to support tail call optimization. 
As a result, any non-trivial _Mizu_ program running on that platform will quickly run out of stack space, causing a segmentation fault. 
This doesn't limit Windows support, as alternate compilers exist; however, we planned to demonstrate support for several microcontrollers, but discovered that `avr-gcc` (compiling for Arduino) also does not support tail-call optimization. 
This seems to be a well-known issue~@wasm3mcu. 
Similar problems on a RISC-V microcontroller are still being investigated.

_Mizu_ does not provide an arbitrary program loader or define a portable file format. 
This limitation is acceptable for its intended use as an embedded submodule within a compiler. 
But if _Mizu_ were to become an export target for these same compilers, providing such a loader and portable file format would become a core necessity. 
Because `opcode`s store a pointer, the binary representation of a _Mizu_ program lacks portability across machines with different pointer sizes. 
While the foundation exists to address this, it is not robust beyond dumping test programs to a file and reloading them from disk.

== Conclusion <4:sect:conclusion>

In conclusion, _Mizu_ has been designed as a lightweight, portable, and extendible interpreter that can be embedded within larger projects. 
We have demonstrated the simplicity of its instructions, the ease with which they can be extended, and the overall performance of the technique. 
Work needs to be done before _Mizu_ can be considered fully mature (especially in regard to its binary interface), but it is already performing comparably to its peers. 
We have also shown that it is possible to reduce higher-level concepts, such as threading and foreign function interfacing, to the level of an assembly language.

#unumbered_heading[Acknowledgments]

This material is based in part upon work supported by the National Science Foundation under grant numbers OIA-2019609 and OIA-2148788. 
Any opinions, findings, and conclusions or recommendations expressed in this material are those of the authors and do not necessarily reflect the views of the National Science Foundation.


