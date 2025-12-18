#import "util.typ": unumbered_heading 

= Introduction <chapter:introduction>

// This chapter is typically an Extended Abstract with More Detail followed by a map Paragraph...

// - Designing compilers is hard!
// - When asked what the hardest subject in computer science is, most forums have at least one person mentioning a compiler. // TODO: Citation needed

// - But why? 
// - The undergraduate curriculum here at UNR teaches computer architecture/assembly, algorithms, automata theory, and design elements of programming language design.
// - If our undergraduates are equipped with knowledge of all the components needed to build a compiler, why has only one team in the history of our Senior Capstone class combined them into one?

// - We believe that the answer is scale, assembling a compiler even for a simple language is a daunting task, so what can be done to make constructing a compiler easier?
// 1. Multilevel Intermediate Representations: As seen in MLIR /*citation needed*/ and Rust /*citation needed*/ allow compiler authors to build Intermediate Representations (IRs) that very closely match the constructs of their target language by composing operations defined in lower-level IRs, which then get substituted in for the higher-level constructs.
// 2. Compile Time Evaluation: As seen in Zig's `comptime` /*citation needed*/ and to a lesser extent C++'s `constexpr/consteval` allows arbitrary code to be run at compile time. When built into a compiler's Intermediate Representation and combined with Multilevel IRs this allows programming language designers to add optimization passes as code sitting beside their IR constructs.
// 3. Entity Component Systems: Provide a performant Data-Oriented structure that can replace complex visitor patterns or inflexible virtual inheritance hirearchies with simple ad-hoc optimization and analysis passes that are (hopefully) simple enough to write in an IR.
// 4. Evidence-Based Design: As seen in Quorum /*citation needed*/ ensures that the building blocks provided for the previous three items are actually useful.

Designing compilers is notoriously tricky. 
It is a sentiment echoed frequently across programming forums—when users are asked to name the most complex subject in computer science, someone inevitably brings up compilers~@carlton2011.
However, what makes compiler construction so challenging?

The typical undergraduate curriculum covers many of the foundational topics necessary for building a compiler: computer architecture and assembly, algorithms, automata theory, and the design principles behind programming languages.
In theory, this gives students all the pieces they need. 
Yet, despite this preparation, only one team in the history of the University of Nevada, Reno's Senior Capstone class has ever attempted to assemble those components into a complete compiler. 
Why is that?
//In the Undergraduate/Graduate Compiler Construction course they actually build a fully functional C compiler.

We believe the key issue is scale. 
Even a simple compiler requires integrating many complex systems, making the task feel overwhelming. 
To make compiler construction more approachable, we propose a few strategies and supporting technologies that can significantly reduce the complexity:

1. Multilevel Intermediate Representations (IRs): Technologies like MLIR~@lattner2021 and Rust's compiler architecture~@rustMultiLevel offer the ability to define IRs that closely resemble the source language's constructs. 
  These high-level IRs are composed of operations defined in lower-level IRs, making it easier to express language semantics naturally. 
  The lower-level representations can then be substituted for higher-level ones, modularizing the compilation process in a similar way that Lego modularizes building.
2. Compile-Time Evaluation: Features such as Zig's comptime~@comptime and C++'s constexpr/consteval~@constexpr allow for running code during compilation. 
  When this capability is built directly into a compiler's IR—and combined with multilevel IRs—it enables language designers to embed optimization logic as part of the language definition itself, treating optimizations as first-class constructs rather than separate compiler passes.
3. Entity-Component Systems (ECS): ECS frameworks offer a data-oriented design pattern that can be a compelling alternative to traditional object-oriented techniques like visitor patterns or rigid inheritance hierarchies. 
  By using ECS, developers can write ad-hoc analysis and optimization passes that are more modular and easier to reason about, fitting naturally into an IR-driven compiler structure.
// 4. Evidence-Based Design: As exemplified by the Quorum programming language~@stefik2017, evidence-based design ensures that language features and compiler infrastructure are grounded in usability and developer needs. 
  // This principle can help validate that the tools and abstractions being introduced actually aid in compiler construction, rather than adding unnecessary complexity.

// Add explanation of ECS
// - So why not just extend LLVM or GCC?
// - Our major goal is to reduce the barrier to entry in compilers.
// - However existing system's architecture and APIs can be complex and poorly documented in places, making it hard for new users to get started or contribute.
// - Additionally many parts of these system (especially advanced or less commonly used components) still lack clear, complete, or up-to-date documentation.
// - Finally these platforms evolves quickly, and internal APIs or components can change frequently, breaking dependent projects.
// - Instead our goal is a tiny lightweight compiler with a fixed API that defers these implementation details to compile time; paired with a fixed standard for implementing many core features.

Although platforms like LLVM~\cite{lattner2004} and GCC~\cite{gcc} are robust and widely used, we chose not to extend these existing compiler toolchains. Instead, our primary objective is to lower the barrier to entry in compiler development.
Unfortunately, the architecture and APIs of these existing systems are often complex and, in many cases, poorly documented. 
This complexity can make it difficult for newcomers to get started or to meaningfully contribute.
These systems also evolve rapidly, with internal APIs and components changing frequently. 
Such changes can easily break dependent projects, making long-term maintenance a challenge.

In contrast, our approach is to build a small, lightweight compiler infrastructure with a stable, fixed API that defers many implementation details to compile time and is paired with a consistent standard for implementing essential core features, making it straightforward and more approachable for less experienced developers or those seeking to integrate a compiler into a larger application.

// Map Paragraph
The remainder of this thesis explores our preliminary investigations into these topics through the following chapters, all of which are either published or structured for submission as publications:
@chapter:background surveys existing compiler intermediate representations, identifying the most promising ideas to combine.
@chapter:motivation introduces Entity Component Systems in greater detail and examines how they can be used to reduce compiler complexity.
@chapter:mizu presents Mizu, a lightweight, low-level virtual machine designed for broad portability; Mizu provides a foundation for compile-time evaluation within our IR and serves as a simple abstract machine for compilers.
// @chapter:verification outlines our initial attempt to develop a methodology for qualitatively evaluating compiler features, ensuring our designs are evidence-based.
Finally, @chapter:conclusions summarizes the work and outlines a plan to unify these features into a cohesive compiler infrastructure, which will form the basis for my PhD dissertation.