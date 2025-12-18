#import "util.typ": unumbered_heading 

= Conclusions & Future Work <chapter:conclusions>

// - @chapter:verification presented a methodology for verifying compiler features, however we identified several major scalability issues.
// - Thus I am currently collaborating with a PhD student in our lab (Vinh Lee) whose dissertation is focused on creating a framework for conducting Human Computer Interaction focused user studies.
// - I am providing feedback on his design and helping develop some features that would allow us to embed compilers and IDEs into his web-based framework.
// - The goal is thus to extend our methodology to include recruitment (from places such as Reddit) and data filtering methodology (since pre-screening will be difficult) for studies run entirely online.
// - This is the only way I foresee being able to run a statistically significant number of participants (200).

// In @chapter:verification, we presented a methodology for verifying compiler features. However, we encountered several significant scalability challenges that limit its broader applicability. 
// To address these issues, I am currently collaborating with a PhD student in our lab, Vinh Le, whose dissertation focuses on developing a framework for conducting user studies in the context of Human-Computer Interaction.

// As part of this collaboration, I am providing feedback on his design and contributing to the development of features that enable the integration of compilers and other language tools into his web-based framework. 
// The overarching goal is to extend our verification methodology to support online studies, including participant recruitment from platforms such as Reddit and the development of data filtering strategies to compensate for the lack of traditional pre-screening methods.
// This online approach is essential, as it represents what we believe to be the only viable path to achieving a statistically significant sample size—approximately 200 participants based on a power analysis performed on the results of @chapter:verification.

// - Similarly, in addition to the material published about Mizu (see @chapter:mizu), we have developed a portable binary format for it which combines a program with raw binary data intended to be copied to the bottom of the program's stack.
// - We additionally added several instructions designed to interact with and take pointers to the bottom of Mizu's stack.
// - This addresses the biggest issue we identified with Mizu, making its immaturity and untested nature our current biggest priorities.
In addition to the material published about _Mizu_ (see @chapter:mizu), we have developed a portable binary format that combines a _Mizu_ program with raw binary data intended to be copied to the bottom of the program's stack. 
To support this functionality, we also introduced several new instructions that allow interaction with and referencing of pointers to the bottom of _Mizu_'s stack.
These additions address what @chapter:mizu identified as the most significant limitation of Mizu (the lack of usability as a compiler target). 
With this improvement in place, the primary challenges now lie in its overall immaturity and the lack of thorough testing.

// - Both of these issues would be greatly alleviated by a case study integrating Mizu into a compiler.
// - Thus the rest of this chapter will present our plans for the Data Oriented Intermediate Representation (DOIR), a multilevel intermediate representation with in-built compile time evaluation.
// - DOIR will target the Mizu abstract machine, with a functional language slant.
// - Each line will represent a single assignment to a virtual register using one of seven forms: constants, blocks (which can contain nested operations and yield values), aliases, namespaces, types, and undefined field declarations (used only inside types); a basic example of each of these forms is presented in @fig:doir-syntax. 
// - Registers may be explicitly numbered or named, and source location metadata can be attached to each assignment. 
// - Functions are first-class and constructed similarly to blocks, with explicit return types and argument types, and can capture registers from the enclosing scope.

Both of these issues could be significantly mitigated through a case study that integrates Mizu into a working compiler. 
To that end, the remainder of this chapter outlines our plans for the Data-Oriented Intermediate Representation (DOIR), a multilevel intermediate representation designed with built-in compile-time evaluation capabilities.

DOIR is intended to target the Mizu abstract machine and adopts a functional programming perspective. 
In DOIR, each line corresponds to a single assignment to a virtual register, using one of seven distinct forms: constants, blocks (which may contain nested operations and yield values), aliases, namespaces, types, and undefined field declarations. 
A basic example of each of these forms is illustrated in @lst:doir-syntax.

#figure(
  placement: bottom,
  caption: [A basic example of the seven forms DOIR will support.],
```rust
%1 : i32 = 5 // #1 Constant assignment (name : type = value)
%2 : block = { // #2 Block assignment (%2 stores "quoted" information about the contents of the block)
	%1 : i32 = 6
	_ : _ = yield(%1) // #3 Function execution (_ in a name will use the next numbered register, _ in a type will request inference)
}
%3 : alias = %2 // #4 Alias assignment (%3 is resolved to %2)
math : namespace = { // #5 Namespace assignment (note that registers can be named, not just numbered)
	vec2 : type = { // #6 Type assignment
		x : f32 // #7 Undefined assignment (invalid outside of types)
		y : f32
	}
}
```) <doir-syntax>

Registers in DOIR may be explicitly numbered or named, and each assignment can include source location metadata. 
Functions are treated as first-class entities and are constructed in a manner similar to blocks. 
Their types combine explicit return and argument types, and they are capable of capturing registers from their enclosing scope.

// - The entire system seeks to be as minimal as possible, it current draft grammar is even small enough to fit on a single page (and is provided in @fig:doir-grammar).
// - This IR is designed for flexibility in code generation and transformation, with a focus on explicit control over scope, visibility, and function semantics. 
// - It borrows ideas from SSA (Static Single Assignment) form and functional programming (with first-class blocks/functions).

The entire system is designed with minimalism in mind; in fact, the current draft of DOIR's grammar is compact enough to fit on a single page, as shown in @lst:doir-grammar. 
This intermediate representation is built for flexibility in both code generation and transformation, emphasizing explicit control over scope, visibility, and the semantics of functions.
// DOIR draws inspiration from Static Single Assignment (SSA) form as well as functional programming principles, particularly through its use of first-class blocks and functions.

#figure(
  placement: top,
  caption: [
    The current draft Parsing Expression Grammar (PEG)~@ford2004 for DOIR. PEGs are similar to other standard grammar notations, such as BNF, except that they define a scanner (tokens) in addition to grammar productions, which are marked by a trailing arrow (`<-`), alternatives are delimited with a forward slash (`/`), and quoted strings or regular expressions define tokens. Additionally, they are inherently unambiguous: each alternative of a production is tried, and if it fails, the next one is tried, or in other words, ambiguity resolution is defined by which production is listed first.
  ],
```c
program <- - assignment*
assignment <- Identifier- ':'- Type- '='- (Constant wsc / Block wsc / function_call)? (SourceInfo wsc)? Terminator-

deducible_type <- Type- / 'deduced'- 'type'-
identifier_type_pair <- Identifier- ':'- deducible_type
FunctionType <- Identifier- '('- (identifier_type_pair ','-)* ')'
Type <- (FunctionType / Identifier)

Block <- '{'- assignment* '}'
function_call <- ('inline'-/'tail'-/'flatten'-)? Identifier- '('- (FunctionType- / Identifier- / Block-)* ')'wsc

Terminator <- ';' / '\n' / '\n\r'
Identifier <- !Keywords [%a-zA-Z_][a-zA-Z0-9_.]*
Keywords <- 'deduced' / 'flatten' / 'inline' / 'tail'
SourceInfo <- '<' ((!':' .)* ':')? IntegerConstant ('-' IntegerConstant)? ':' IntegerConstant ('-' IntegerConstant)? '>'

- <- ([ \n\r\t] / LongComment / LineComment)*
wsc <- ([ \t] / LongComment / LineComment)*
LongComment <- '/*' (!'*/'.)* '*/'
LineComment <- '//' (!'\n' .)*

```) <doir-grammar>

// - The plan is for DOIR to have a system analogous to $beta$-reduction, where function calls are replaced with their bodies until we have reduced all the way to a level where the functions correspond 1-to-1 with machine language instructions.
// - Which we will then assemble into executable binaries.
// - Thus, DOIR can be thought of as a "better assembler."
// - We of course plan to conduct several user studies to quantify this idea of better.

The plan for DOIR includes a mechanism analogous to $beta$-reduction (see @2:sect:lambda), in which function calls are progressively replaced with their corresponding bodies. 
This reduction continues until the program is transformed to a level where each function corresponds directly to a single machine language instruction. 
At that point, the result can be assembled into an executable binary.

In this sense, DOIR can be viewed as a kind of "better assembler"—one that offers higher-level abstractions without sacrificing control or efficiency. 
To evaluate and quantify what "better" truly means in this context, we intend to conduct a series of user studies.


// - This thesis presents the majority of the component parts we plan to use to implement DOIR.
// - The ECS framework is the backbone of the system.
// - Mizu is the first "assembly" language we plan to target, and will provide some compile-time evaluation functionality.
// - And we have developed a methodology for measuring our claims.
// - The next step is to create a parser for the designed language and then integrate it with Mizu.

This thesis presents the majority of the core components we intend to use in the implementation of DOIR. 
At the heart of the system is the Entity-Component-System defined in @chapter:motivation, which serves as its structural and, to a lesser extent, performance backbone. 
Mizu (see @chapter:mizu), the first "assembly" language we plan to target, will play a key role by providing a foundation for low-level execution along with some support for compile-time evaluation.
// In addition, we have developed a methodology for empirically measuring the effectiveness of our approach to prove that our design is evidence-based and identified useful features of other intermediate representations to use as inspiration. 
The next phase of the project involves building a parser for the designed language and integrating it with a Mizu-targeting backend.

// - We plan to focus on a single function version of DOIR for starters, really nail down the "better assembly" syntax, before implementing the $beta$-reduction.
// - We then plan to add support for RISC-V assembly, which should be simple compared to the previous step, especially since Mizu was modeled after RISC-V.
// - From there the project will shift towards building several layers of reductions that eventually map closely to C, and then adding a system to write whole program optimization passes.
// - Once DOIR can support (at least the most common features) of C, we have access to all of the benchmarks developed for C and can test our system against other more mature compiler tool-chains like GCC /* citation needed*/ and LLVM /* citation needed*/.

Our initial focus will be on developing a single-function version of DOIR to refine the "better assembly" syntax and ensure a solid foundation before implementing $beta$-reduction. 
Once that core functionality is in place, we plan to add support for RISC-V assembly. 
This step should be relatively straightforward, particularly because Mizu was designed with RISC-V as a reference model.

Following that, the project will progress toward building multiple layers of reductions that incrementally map representations closely aligned with C down to lower-level constructs. 
// This will pave the way for implementing a system capable of performing whole-program optimization passes.
Once DOIR can support the most common features of C, we will gain access to the rich ecosystem of benchmarks developed for the C language. 
This will allow us to rigorously evaluate our system by comparing it against established compiler toolchains such as GCC~@gcc and LLVM~@llvm.

// - This is where the current plan stops, and ideas become a lot more vague.
// - It would be nice to support additional machine architectures (namely x86 and ARM) as well as some text transpilation to C or WebAssembly.
// - A previous version of the DOIR design included several parallelism primitives defined by Verse /* citation needed */.
// - Since DOIR is functional, can we define some optimization passes to convert side effects to argument manipulations and then gain access to the research that has been done on automatically parallelizing functional languages?
// - Could we build extra layers on top of our C layer that support additional languages like Go, Haskell, or Datalog?
This is the limit of the current development plan, and thus, future directions become more speculative. 
One possible avenue for future development would be to support additional machine architectures, such as x86 (which is likely a necessity for any future adoption) and Arm, as well as provide options for transpiling DOIR code to higher-level targets like C or WebAssembly~@wasm3.

The end goal of this phase is a small, lightweight compiler infrastructure with a stable, fixed API that defers many implementation details to compile time. This lightweight core should be capable of consuming backends as libraries, and significant design work is being put towards ensuring these "backend libraries" are as easy to write as possible.

An earlier iteration of the DOIR design incorporated several parallelism primitives inspired by those found in Verse~@verse. 
Given DOIR's functional nature, an intriguing possibility is the development of optimization passes that transform side effects into pure argument-based manipulation. 
This could potentially allow us to leverage existing research on the automatic parallelization of functional languages.

Looking further ahead, it may be feasible to build additional abstraction layers stacked on top of the C layer, enabling support for other programming languages such as Go, Haskell, or even Datalog (hopefully all also delivered as libraries). 
These ideas remain exploratory, but they are all promising directions for future work.










