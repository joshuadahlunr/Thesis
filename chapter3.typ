#import "util.typ": unumbered_heading 
#import "@preview/diagraph:0.3.3": *
#import "@preview/cetz:0.3.4": canvas, draw, palette
#import "@preview/cetz-plot:0.1.1": chart, plot
#import "@preview/oxifmt:1.0.0": strfmt

= Entity Component Systems: Challenges and Benefits <chapter:motivation>

This chapter first appeared as a conference publication in ACM's SIGPLAN Onward!~@Dahl2025splash. #linebreak()
J. Dahl, and F. C. Harris Jr., "An Argument for the Practicality of Entity Component Systems as the Primary Data Structure for an Interpreter or Compiler," in Proceedings of the 2025 ACM SIGPLAN International Symposium on New Ideas, New Paradigms, and Reflections on Programming and Software, in Onward! '25. Singapore: Association for Computing Machinery, 2025.

#unumbered_heading(centered: true)[Abstract]
In this paper, we examine how Entity Component Systems, a data structure that has been gaining popularity in game engines, can benefit compiler and interpreter design.
It does not consistently provide the same performance benefits that games utilize it for; however, it does make writing optimization passes easier.
Additionally, its dogmatic focus on simple Plain-Old-Data structures makes serialization much easier.
These benefits do come at a memory cost, the severity of which we still need to compare against more mature language implementations.

== Introduction <sect:introduction>
Compiler construction is often considered one of the more challenging topics in computer science, frequently appearing near the top of lists that discuss the field's most difficult subjects~@carlton2011. 
This is somewhat surprising given the typical undergraduate curriculum: students are generally required to take courses in computer organization, assembly language programming, algorithms, and formal languages. 
In addition, many programs include a capstone project or a bachelor's thesis, which encourages students to synthesize and apply knowledge from all of these domains.

Given this solid foundation, it would seem that most computer science graduates possess the necessary tools to build a compiler. 
So why, then, does the prospect of actually constructing one feel so overwhelming?
We hypothesize that integrating a greater number of compiler development tools in a well-documented and user-friendly manner can help bridge the significant mental gap that would-be compiler developers often face. 
Toward this end, we examine how data-oriented design techniques can facilitate and simplify the process of compiler construction.

A significant source of inspiration for this project was a _CppNorth_ talk by Chandler Carruth~@carruth2023@carruth2023youtube, in which he discusses how Google is "modernizing" compiler development for their new _Carbon_ programming language~@carbon-lang. 
In particular, Google is attempting to leverage data-oriented programming techniques—approaches that have gained popularity in the video game industry for their performance benefits~@unity-dots@epic-mass@bevy—to improve compiler efficiency.
However, Google's implementation is tightly coupled with the specific syntactic structure of _Carbon_. 
In this work, we experiment with similar data-oriented techniques, but apply them across three languages in three different domains and of increasing complexity with differing syntactic characteristics: a basic expression calculator, JSON~@json, and a simplified imperative version of Lox~@nystrom2021.

For this preliminary analysis, we applied a strict design constraint: to implement all functionality using only a single generic data-oriented structure, an Entity Component System (ECS) supplemented by a single string containing the original input. 
// % The motivation behind this approach lies in the principles of data-oriented design, and more specifically, in how ECS structures aim to organize data for performance.
The core idea of data-oriented design is to decompose data into the smallest logical groupings that are frequently accessed or manipulated together. 
These groupings are then tightly packed into memory. 
This memory layout is particularly well-suited to the caching mechanisms of modern CPUs. 
When a program accesses a value in memory, the CPU typically loads not just the specific value, but also several surrounding bytes into the cache. 
These groups of nearby memory (commonly 64 bytes in size, known as cache lines~@igoro-cache) enable faster subsequent access to nearby data.
In practice, the data packed into ECS structures is usually composed of simple, Plain-Old-Data (POD) types~@pod-serialization (types which can be treated as binary blobs that can be moved using `memcpy`), which are not only efficient to store and manipulate but also straightforward to serialize and deserialize. 

Our goal was to explore whether an ECS is a useful data structure for compilers and interpreters. 
We began with the hypothesis that, much like in game development, an ECS could offer improved performance. 
Unfortunately, our evidence neither supports nor refutes this hypothesis;
So, we also present some benefits to usability that emerged from using an ECS and a slight tweak we made to treat Component arrays as hashtables.
Thus, this work has two primary research questions:
+ Does an ECS improve the performance of a compiler or interpreter?
+ Does an ECS make it "easier" to write compilers and interpreters?

@sect:background explores what exactly an ECS is, along with several other common interpreter architectures. 
@sect:design details the modifications we made to the ECS framework to enhance its utility as well as the design challenges we encountered while implementing interpreters for two simple languages and a more general-purpose (albeit still simple) language. 
Then, in @sect:benefits, we outline the benefits that emerged during the development of these interpreters, while @sect:limitations addresses some of the drawbacks we observed. 
Finally, @sect:conclusion offers a summary of our findings and enumerates why we believe ECS can be a valuable tool in this context.

== Background <sect:background>

Treewalk and bytecode interpreters are two foundational architectures used to implement programming language interpreters.
A treewalk interpreter operates directly on the abstract syntax tree (AST) parsed from source code. 
The interpreter traverses the tree recursively, executing code by evaluating nodes according to their syntactic roles. 
This method is often favored in the early stages of language development due to its simplicity and close alignment with the structure of the source language~@nystrom2021. 
While intuitive and easy to implement, treewalk interpreters typically suffer from performance inefficiencies, especially in large or compute-intensive programs, due to the overhead of recursive traversal.

// In contrast, bytecode interpreters transform the AST into a lower-level, often linear intermediate representation (IR) with instructions usually being one byte in size (hence the name), which is then executed by a language runtime, which is commonly referred to as a virtual machine. 
// This IR is generally more compact and easier to analyze and manipulate than raw ASTs, and it thus facilitates more advanced optimizations~@Fraser1995. 
// Bytecode interpreters strike a balance between the flexibility of high-level languages and the efficiency of lower-level execution models, making them a preferred choice for more production-grade language runtimes such as the Java Virtual Machine~@lindholm2013 and Python’s CPython interpreter~@cpython.
In contrast, bytecode interpreters convert the AST into a lower-level, often linear intermediate representation (IR), where instructions are typically one byte in size—hence the name. 
This IR is then executed by a language runtime, commonly referred to as a virtual machine.
Compared to raw ASTs, the IR is generally more compact and easier to analyze and manipulate, which enables more advanced optimizations~@fraser1995.
Bytecode interpreters strike a balance between the flexibility of high-level languages and the efficiency of lower-level execution models, making them a popular choice for production-grade language runtimes such as the Java Virtual Machine~@lindholm2013 and Python's CPython interpreter~@cpython.

// We utilize an ECS to design a new Attribute Bubble interpreter that sits halfway between a treewalk (we directly traverse an AST) and bytecode interpreter (the AST has been transformed into a more linear form).
// The ECS data structure is built around three primary concepts: Components, Systems, and Entities~@tuni2019.
// Components are stored in tightly packed arrays and contain minimal amounts of closely related data. 
// Traditionally, Components are purely data and do not include behavior, but it is not uncommon to see small helper methods attached to perform some simple computations.
// However, the majority (or all of it if you are being dogmatic) of the processing logic is handled externally by Systems. 
// Systems are functions that operate on specifiable subsets of Components, typically in bulk, and are responsible for implementing the behavior of the game or simulation. 
// These Systems receive a context object, which contains all relevant Component arrays. 

// Entities, on the other hand, serve as indices into the Component arrays and are used to represent unique objects. 
// They can be thought of like keys in a database~@cloutier2023, where each column is a Component array, and just as some database entries may lack values in certain columns, Entities may not be associated with every Component.
// @tbl:ecs-example provides an example of an ECS being used to store the necessary data to position, move, and accelerate several Entities in a simple Astroids-like game~@asteroids_recharged; while @fig:ecs-example-System provides some code for a System that implements a simple discrete approximation of the kinematics for such a  game.

We employ an ECS to design a new Attribute Bubble Interpreter that operates halfway between a traditional tree-walk interpreter (which directly traverses an Abstract Syntax Tree, or AST) and a bytecode interpreter (where the AST is transformed into a more linear representation).
The ECS data structure is centered around three primary concepts: Components, Systems, and Entities~@tuni2019. 
Components are stored in tightly packed arrays and consist of small, closely related pieces of data. 
Traditionally, Components are purely data-oriented and contain no behavior. 
However, it is not uncommon to include simple helper methods for lightweight computations.

The bulk of the processing logic—sometimes all of it, depending on how strictly one adheres to ECS principles—is handled by Systems. 
Systems are functions that operate on specified subsets of Components, usually in bulk, and are responsible for implementing the behavior of the game or simulation. 
Each System receives a context object that includes all relevant Component arrays, allowing it to process Entities efficiently.

Entities, by contrast, act as indices into these Component arrays and represent unique objects in the simulation. 
They function similarly to keys in a relational database~@cloutier2023, where each column corresponds to a Component array. 
Just as some database rows may lack values in specific columns, Entities in an ECS may not be associated with every possible Component.
@tbl:ecs-example presents a sample ECS setup that stores the data required to position, move, and accelerate multiple Entities in a simple Asteroids-like game~@asteroids_recharged. 
Meanwhile, @lst:ecs-example-System shows the implementation of a System that performs a discrete approximation of the kinematics necessary for such a game.

#figure(
  caption: [An example ECS storing several Entities (a player and three rocks) that each have a position and velocity. There are several additional Components which may ($checkmark$) or may not ($emptyset$) be present for a particular Entity. The `IsPlayer?` and `IsRock?` components are tags: valueless Components that encode some boolean property about the Entity.],
  [
    #set text(size: 9pt)
    #table(
      columns: 6,
      align: horizon,
      stroke: none,
      table.header(
        [Entity],[Position],[Velocity],[Acceleration],[IsPlayer?],[IsRock?]
      ),
      table.hline(),
      [1],[(0, 0, 0)],[(0, 0, 0)],[$emptyset$],[$checkmark$],[$emptyset$],
      [2],[(5, 0, 0)],[(0, 0, 0)],[(-1, 0, 0)],[$emptyset$],[$checkmark$],
      [3],[(0, 5, 5)],[(2, 0, 0)],[$emptyset$],[$emptyset$],[$checkmark$],
      [4],[(0, 2, 2)],[(0, 5, 0)],[$emptyset$],[$emptyset$],[$checkmark$],
    )
  ]
) <ecs-example>

#figure(
  placement: top,
  caption: [
    This System updates the ECS defined in @tbl:ecs-example. It processes all matching Entities in bulk within the module/context. 
    Note that only a subset of Entities—specifically those possessing both `Position` and `Velocity` components—are processed. 
    In this example, however, that subset happens to include all Entities.
  ],
```cpp
void kinematics_System(Context& ctx) {
  for(uint e = 0; e < ctx.entity_count(); ++e) {
    if(!ctx.has_component<Position>(e)) continue;
    if(!ctx.has_component<Velocity>(e)) continue;
    
    Position& p = ctx.get_component<Position>(e);
    Velocity& v = ctx.get_component<Velocity>(e);
    if(ctx.has_component<Acceleration>(e)) {
      auto& a = ctx.get_component<Acceleration>(e);
      v.x += a.x;
      v.y += a.y;
      v.z += a.z;
    }
    p += v; // Assuming there is an element-wise overload
  }
}
```
) <ecs-example-System>

#[
  #set par(first-line-indent: (amount: 1em, all: true))
  
  Each concept in an ECS corresponds neatly to familiar constructs in programming language design. 
  Components resemble attributes in an IR, and Systems mirror analysis or optimization passes. 
  Entities are analogous to parser tokens or AST nodes;
  and the Context that wraps the Component arrays is comparable to a Module.)
]

However, when working with an ECS, a common issue arises when Components are added to only a few Entities, as is the case for the `IsPlayer?` and `Acceleration` components in @tbl:ecs-example. 
In such cases, large arrays are often created that contain mostly "null" or unused data, leading to significant memory waste. 
The most widely adopted solution to this problem in games is the use of archetypes~@colson2020.

In this approach, each unique combination of Components defines an archetype. 
Whenever a Component is added to or removed from an Entity, the Entity is moved to a different archetype that matches its new Component set. 
All Entities sharing the same archetype—i.e., the same set of Components—have their Components stored together in tightly packed arrays. 
This organization eliminates the need to reserve space for absent Components, thereby avoiding the inefficiency of storing null data to maintain a fixed array structure.
When rewritten using archetypes, the example in @tbl:ecs-example instead is represented by a table per archetype as shown in @tbl:archetype-example.

#figure(
  placement: top,
  caption: [
    @tbl:ecs-example rewritten to use archetypes. 
    Notice that each archetype only stores a Component if all Entities within that archetype possess it, resulting in all Component arrays being densely packed. 
    Additionally, every System must now loop over all archetypes in a module before iterating through each Entity within those archetypes, which adds more boilerplate code to their definitions.
  ],
  [
    #set text(size: 9pt)
    #table(
      columns: 4,
      align: horizon,
      stroke: none,
      table.header(
        table.cell([*Archetype *1], colspan: 4)
      ),
      [Entity],[Position],[Velocity],[IsPlayer?],
      table.hline(),
      [1],[(0, 0, 0)],[(0, 0, 0)],[$checkmark$],
    )
    
    #table(
      columns: 5,
      align: horizon,
      stroke: none,
      table.header(
        table.cell([*Archetype 2*], colspan: 5)
      ),
      [Entity],[Position],[Velocity],[Acceleration],[IsRock?],
      table.hline(),
      [2],[(5, 0, 0)],[(0, 0, 0)],[(-1, 0, 0)],[$checkmark$],
    )
    
    #table(
      columns: 4,
      align: horizon,
      stroke: none,
      table.header(
        table.cell([*Archetype 3*], colspan: 4)
      ),
      [Entity],[Position],[Velocity],[IsRock?],
      table.hline(),
      [3],[(0, 5, 5)],[(2, 0, 0)],[$checkmark$],
      [4],[(0, 2, 2)],[(0, 5, 0)],[$checkmark$],
    )
  ]
) <archetype-example>

One alternative to archetypes is the use of Sparse Sets~@colson2020. 
In this approach, the data for each Component type is tightly packed, while a separate sparse array of indices maps Entities to their corresponding Component data. 
The key idea behind this method is to trade off a small amount of memory used to store indices (typically only 2 to 4 bytes each) instead of wasting significantly more memory on partially filled Component arrays, where each Component might occupy 10 bytes, 100, or even more.
An example of how this might be used to tightly pack the `Acceleration`s from @tbl:ecs-example is shown in @fig:acceleration-sparse-set.

#figure(
  placement: top,
  raw-render(```
digraph G {
	node  [shape=plain]
	Sparse [label=<
	<table border="0" cellborder="0">
	  <tr>  <td>Entity</td><td> Index in Dense </td>   </tr><hr/>
	  <tr>  <td>1</td><td port="1"> -1 </td></tr>
	  <tr>  <td>2</td><td port="2"> 0 </td></tr>
	  <tr>  <td>3</td><td port="3"> -1 </td></tr>
	  <tr>  <td>4</td><td port="4"> -1 </td></tr>
	</table>>];
	
	Dense [label=<
	<table border="0" cellborder="0">
	  <tr>  <td>Dense Index</td><td>Data</td></tr><hr/>
	  <tr>  <td port="1">0</td><td>(-1, 0, 0)</td></tr>
	</table>>];
	
	Sparse:2:e -> Dense:1:w;
}
  ```),
  caption: [
    A Sparse Set that maps sparse Entity data to tightly packed `Acceleration` values. 
    An index of -1 indicates that no data is associated with a given Entity. 
    Assuming 4-byte integers and 12-byte (three f32) `Acceleration` values, this approach reduces wasted memory from $3 times "sizeof(Acceleration)" = 36$ bytes down to $4 times "sizeof(int)" = 16$ bytes. 
    The factor of 4 (instead of 3 as in the first calculation) arises because the entire sparse array is considered wasted space, rather than just the extra null data. 
    The main drawback is that mostly filled Component arrays end up wasting an additional $"sizeof(int)"$ bytes for each Component.
  ]
) <acceleration-sparse-set>

== Design <sect:design>

// Begin hard to follow
Our implementation introduces a subtle variation on the typical Sparse Set approach: 
Rather than storing sparse indices alongside each Component's storage, we instead associate sparse indices with each Entity, replacing the traditional use of an Entity bitmask, which is used to indicate which Components are associated with each Entity. 
This centralized sparse structure, visualized in @fig:sparse-Entities and @fig:sparse-Entities-shuffle, serves a dual purpose: 
It allows for efficient lookup of Component offsets and simultaneously indicates whether or not a Component exists for a given Entity. 
This tweak allows us to manipulate the order in which Components are stored at will.
We use this ability to "sort" some Component arrays into hashtables, a feature that would be difficult to reproduce if using archetypes.

#figure(
  placement: bottom,
  raw-render(```
digraph G {
	node  [shape=plain]
	Entity [label=<
	<table border="0" cellborder="0">
	  <tr>  <td>Entity</td><td>Pos. Idx </td><td>Vel. Idx</td><td>Acc. Idx</td><td>Plr. Idx</td><td>Rock Idx</td>   </tr><hr/>
	  <tr>  <td>1</td><td port="pos"> 0 </td><td port="vel"> 0 </td><td port="acc"> -1 </td><td port="plr"> 0 </td><td port="rock"> -1 </td></tr>
	</table>>];
	
	Pos [label=<
	<table border="0" cellborder="0">
	  <tr>  <td>Position Index</td><td>Data</td></tr><hr/>
	  <tr>  <td port="0">0</td><td>(0, 0, 0)</td></tr>
	  <tr>  <td port="1">1</td><td>(5, 0, 0)</td></tr>
	  <tr>  <td port="2">2</td><td>(0, 5, 5)</td></tr>
	  <tr>  <td port="3">3</td><td>(0, 2, 2)</td></tr>
	</table>>];

	Vel [label=<
	<table border="0" cellborder="0">
	  <tr>  <td>Velocity Index</td><td>Data</td></tr><hr/>
	  <tr>  <td port="0">0</td><td>(0, 0, 0)</td></tr>
	  <tr>  <td port="1">1</td><td>(0, 0, 0)</td></tr>
	  <tr>  <td port="2">2</td><td>(2, 0, 0)</td></tr>
	  <tr>  <td port="3">3</td><td>(0, 5, 0)</td></tr>
	</table>>];
	
	Entity:pos:s -> Pos:0:w;
	Entity:vel:s -> Vel:0:w;
}
  ```),
  caption: [
    Entity \#1 in @tbl:ecs-example shown with its per Entity indices as well as mappings to the dense `Position` and `Velocity` arrays. 
    Again, -1 indicates that a Component is not associated with the Entity. 
    Additionally, in this scheme, external storage for Tag Components is not necessary: we can represent their presence (0) and absence (-1) in the Sparse Entity Indices.]
) <sparse-Entities>

In general, the order in which Entities and Components are added will not necessarily be the same.
If they get far enough apart, they will wind up in different CPU cache lines, likely causing a cache miss and degrading the performance ECS was designed to improve.
It is entirely possible to add Entities first and then add the same Component to each one in a random order.
In such a situation, we lose all of our guarantees about associated data being close together, as shown in @fig:sparse-Entities-shuffle.
To address this issue, we provide a mechanism for sorting Components so they are in the same order as their Entities.
// End hard to follow

#figure(
  placement: bottom,
  raw-render(width: 100%,
```
digraph G {
	node  [shape=plain]
	Entity [label=<
	<table border="0" cellborder="0">
	  <tr>  <td>Entity</td><td>Pos. Idx </td><td>Vel. Idx</td><td>Acc. Idx</td><td>Plr. Idx</td><td>Rock Idx</td>   </tr><hr/>
	  <tr>  <td>1</td><td port="pos"> 1 </td><td port="vel"> 3 </td><td port="acc"> -1 </td><td port="plr"> 0 </td><td port="rock"> -1 </td></tr>
	</table>>];
	
	Pos [label=<
	<table border="0" cellborder="0">
	  <tr>  <td>Pos. Idx</td><td>"Sorted" Idx</td><td>Data</td></tr><hr/>
	  <tr>  <td port="3">0</td><td>3</td><td>(0, 2, 2)</td></tr>
	  <tr>  <td port="0">1</td><td>0</td><td>(0, 0, 0)</td></tr>
	  <tr>  <td port="1">2</td><td>1</td><td>(5, 0, 0)</td></tr>
	  <tr>  <td port="2">3</td><td>2</td><td>(0, 5, 5)</td></tr>
	  
	</table>>];

	Vel [label=<
	<table border="0" cellborder="0">
	  <tr>  <td>Vel. Idx</td><td>"Sorted" Idx</td><td>Data</td></tr><hr/>
	  <tr>  <td port="3">0</td><td>3</td><td>(0, 5, 0)</td></tr>
	  <tr>  <td port="1">1</td><td>1</td><td>(0, 0, 0)</td></tr>
	  <tr>  <td port="2">2</td><td>2</td><td>(2, 0, 0)</td></tr>
	  <tr>  <td port="0">3</td><td>0</td><td>(0, 0, 0)</td></tr>
	</table>>];
	
	Entity:pos:s -> Pos:0:w;
	Entity:vel:s -> Vel:0:w;
}
  ```),
  caption: [
    @fig:sparse-Entities with its `Position` and `Velocity` component arrays shuffled to simulate more random insertion. 
    In this example, if two `Position` or `Velocity` components fit within a single cache line, iterating through the shuffled `Position` and `Velocity` data would result in approximately 3 and 2 cache misses, respectively—compared to just one each if the data were sorted. 
    This difference is significant when you consider that the main operation performed in @lst:ecs-example-System (three additions) can ideally be completed in just 3 CPU cycles on an x86 machine, whereas a single cache miss to main memory can cost 100–200 CPU cycles—the equivalent processing time for roughly 33-66 entities.
  ]
) <sparse-Entities-shuffle>

However, to swap two Components, we must linearly scan the Entity Sparse Indices to determine which Entity each Component is associated with, resulting in an operation with time complexity $O(n^2 log n)$.
To address this, our approach first sorts a proxy array of indices—functionally similar to the previously described Sparse Sets, where an additional array maps indices back to the original data. 
This sorted proxy array is then transformed into a series of swap instructions.
This two-step process—sorting the proxy and executing the swaps—allows us to leverage fast sorting algorithms (Introsort~@std_sort@basili1997 in our case) without needing to consider the number of swaps the sorting algorithm will perform.

Despite our efforts to minimize the number of swaps, for Components that are expected to be sorted frequently, this process can quickly become prohibitively expensive. 
To mitigate this, we also provide a utility (enumerated in @lst:with-entry) for storing Entities along with Component data, eliminating the need to search for the associated Entity. 
This reduces the computational complexity of this $O(n^2 log n)$ operation to the usual $O(n log n)$ at the cost of increasing the memory consumed by each Component in that Component array.

#figure(
  caption: [A simple Component adapter that associates Entity information with a Component. We have template machinery in place to detect this wrapper and utilize the saved Entity instead of scanning for it.],
```cpp
template<typename T>
struct with_Entity {
  T value;
  entity_t Entity = invalid_entity;
  // Methods excluded for brevity
};
```
) <with-entry>

#[
  #set par(first-line-indent: (amount: 1em, all: true))
  In order to stress our ECS implementation, we have implemented three language processors of increasing complexity. The design of each presented us with several challenges, which we will now discuss and fix.
]

=== Calculator

The first language we implemented was a simple calculator interpreter, where users can type in basic math expressions to be evaluated. 
Additionally, variables can be defined and assigned values for use in future calculations.

A key challenge in this context was that, to maximize speed, memory allocations had to be minimized as much as possible. 
To address this, our System stores the original input string and produces views (pairs of position and length) into that input. 
This approach ensures that most strings are allocated only once, at the start of the program.
However, a downside to this method is that very large programs may not fit into memory.//; we have currently left a solution to this problem as future work, since we expect it not to occur often.

To provide some perspective, assuming a world record typing speed of 360 words (3,600 characters) per minute~@guinness_fastest_court_reporter, it would take about 193 days of continuous typing with no rest to input a one-gigabyte-sized program. 
Given that modern machines typically have sixteen to thirty-two gigabytes of available memory, it is likely that the vast majority of programs humans are likely to type can comfortably fit into memory.
For those programs that exceed this limit, solutions are still being considered as future work.

// I think this space was better used to better explain the ECS-style.

Another challenge we encounter is that when creating trees (or other types of graphs), the memory associated with the nodes is often scattered, which results in poor cache locality.
If different types of Components are created for each graph node, they will be clustered into separate memory groups. 
As a result, when traversing the graph, the program would need to jump between these different clusters of node types, which leads to a reduction in cache locality.
Our solution to this issue is to ensure that all Components associated with a specific graph or tree element are of the same type. 
This allows them to be packed closely together in memory, improving cache locality.

To optimize this, it makes sense to minimize the number of "structure Components." 
We thus construct an AST for the parsed language using two primary (classes of) Components. 
One of these is an `operation` component, which stores a four-tuple that the AST relies on to build most of its trees. 
For expression nodes, the first and second elements of the tuple (or just the first in the case of unary operators) are used to represent the child nodes. 
In contrast, control flow nodes in more advanced languages (see @sect:lox) use all four slots, with the first slot being the condition and the remaining slots used for the block(s) of code to be executed and a marker to indicate the end of each block. 

`operation` components represent one of the primary sources of conflicting pressures in this design. 
On one hand, smaller Components allow more of them to fit within a single cache line, reducing the likelihood of cache misses. 
On the other hand, having many different Component types means that each type is stored in a separate memory segment. 
Switching between these segments increases the chances of cache misses—unless the access pattern involves just a few types of Components.

This creates a tension: we want many small Components to minimize cache misses due to size, but we also want fewer, larger Components to minimize cache misses due to memory fragmentation. 
Designers must strike a balance between these competing factors. 
In our case, we introduced a third consideration: ease of implementation. 
We found that consolidating everything into a single operation structure made writing Systems significantly easier. 
Exploring this trade-off in greater depth is part of our planned future work.

The second class of Components in our AST design are Tag Components: Components that store no data but serve to indicate the specific type of tree node being represented, such as a variable, an addition expression, an if-statement, and so on. 
These Tag Components offer a more dynamic and flexible alternative to using `std::variants` (C++'s tagged unions) when representing different kinds of tree nodes. 
The definitions both for `operation` and several of the most pertinent tags are provided in @lst:operation-structure.

#figure(
  caption: [Definitions for the `operation` component (both for the Calculator and Lox (see @sect:lox)) as well as the tags used to differentiate `operation`s in the calculator.],
```cpp
// The operation Component utilized by the Calculator
struct operation {
  entity_t left, right; // entity_t is a pointer sized uint
};

// The operation Component utilized by Lox
struct operation { 
  // Condition, Then, Else, Marker
  Entity a = 0, b = 0, c = 0, d = 0; // Wrapper class
};

struct add {}; // Recall that tags store no data!
struct subtract {};
struct multiply {};
struct divide {};
struct power {};
struct assignment {};
```
) <operation-structure>

#[
  #set par(first-line-indent: (amount: 1em, all: true))
  It might seem that this approach shifts the problem of accessing different memory clusters in a cache-unfriendly manner to the Tag Components. 
  However, we have a trick up our sleeve:
  Checking if a Component is present only requires looking at the Entity Sparse Indices. 
  This means that the only thing that needs to be loaded from memory are the Entity Sparse Indices, which are the most heavily accessed element in an ECS and thus very likely to already be loaded into the cache.
]

//  Reading the example, I would really wish that there was some data type definitions accompanying it; to show the packed layout.

As a side note, the variant alternativeness of Tag Components also proves beneficial when writing a parser. 
Instead of having to define a rigid `std::variant` containing all the possible types that can flow through the parse, you only need to worry about passing around Entities.

=== JSON

Building on the lessons we learned from implementing a simple calculator interpreter, we moved on to a language that requires deeper levels of nested structure: JSON~@json. 
While not a programming language, JSON's ability to nest alternating types of structures was precisely the kind of additional structure we needed to ensure our system could support.

The first challenge we encountered was that JSON arrays need to store a collection of child elements.
However, to maintain convenient serializability (which we will argue is a primary benefit of this system in @sect:serialize) we had to ensure that all data stored in the ECS is represented as POD types without any pointers to external memory.

Fortunately, these POD types can still store Entities (which are represented simply as integers). 
With this constraint in mind, we implemented two core Components: `list` and `list_entry`. 
The `list_entry` component is responsible for storing the Entities that represent the next and previous elements in a linked list. 
Meanwhile, the `list` component is attached to the list head (the Entity representing a JSON array or object) and manages the overall structure of the linked list built out of `list_entry` components. 
This structure, including `list` components as well as how they are used to derive arrays and objects, is illustrated in @lst:list-Components. 
These Components are designed to be generic and inheritable since attempting to use a single list type for both arrays and objects could potentially introduce conflicts when these elements are nested.

#figure(
  // placement: top,
  caption: [
	Generic `list` and `list_entry` components. 
	Followed by how they are used to implement the JSON `array` and `object` components. 
	Two separate versions are necessary so that they can each be checked for using `has_component` and `get_component`.
  ],
```cpp
struct list_entry {
	Entity next = invalid_entity, previous = invalid_entity;
	// Helper methods excluded for brevity
};
template<std::derived_from<list_entry> T>
struct list {
	T children = {}; 
	Entity children_end = invalid_entity;
	// Methods excluded for brevity
};

struct array_entry : public list_entry {};
struct array : public list<array_entry> {};

struct object_entry : public list_entry {};
struct object : public list<object_entry> {};
```
) <list-Components>

#[
  #set par(first-line-indent: (amount: 1em, all: true))
  While it is well known that linked lists are generally less efficient than contiguous arrays~@Mrena2022, our approach demonstrates that it is still possible to represent nested structures using only an ECS (by building additional "graphs" on top of each other). 
  Even in scenarios where our strict design constraints do not apply, a conversion from a more efficient `std::vector`-based implementation to this ECS-linked-list model could still prove useful for serialization purposes.
]

With JSON arrays and objects now knowing about their children, we had another obstacle to overcome: 
Objects connected to identifiers (such as variables, functions, and types), or in the case of JSON, object members, needed to be efficiently looked up. 
In a standard ECS, this kind of lookup requires a linear scan. 
However, for large numbers of Entities, linear scans become prohibitively expensive. 
To address this, we leveraged our existing capability to reorder (sort) component arrays, enabling us to organize a Component's storage into a hashtable.

After analyzing a performance benchmark for modern hashing algorithms~@leitner2016, we chose to implement Hopscotch Hashing~@Herlihy2008 due to its consistently fast lookup times, and the fact that it is an open addressing (no extra list) method, so it can be implemented by simply reordering a Component array.
For the hashing algorithm itself, we selected the FNV-1A algorithm~@fnv_hash, which is specifically designed to be fast while maintaining a low collision rate: both critical characteristics for a high-performance implementation with a bounded maximum number of collisions (Hopscotch Hashing stores a fixed size number of neighbors in a bitmask and thus does not support more collisions than the size of said bitmask).

// Hopscotch hashing is an open-addressing (no extra list) hashing algorithm that uses an additional bitmask attached to each Component array element, where each bit indicates whether any of the subsequent Components contain values that originally hashed to the current element holding the bitmask. It also needs a boolean flag to mark whether a cell is occupied. To optimize space and performance, we merged these two fields into a single 32-bit unsigned integer: the lower 31 bits are used for the bitmask, and the highest-order bit indicates occupancy. This field is integrated with our existing infrastructure for associating Entities with Components, but ensures that Entities tied to unoccupied cells are marked as invalid, the definitions for these hash wrapping Components are provided in @fig:hash-entry.

// #figure(
//   caption: [Adapter Component that adds hopscotch hashing information to a Component. There is an overload for the common case where `Tvalue` is `void`.],
// ```cpp
// template<typename Tkey, typename Tvalue = void>
// struct hash_entry {
//   // Bitmask to track neighbors (ocupancy in highest bit)
//   uint32_t hopInfo = 0;  

//   Tkey key;
//   Tvalue value;

//   bool is_occupied() const {
//	 return hopInfo & (1 << 31);
//   }
//   void set_occupied(bool value) {
//	 if(value) hopInfo |= (1 << 31);
//	 else hopInfo &= ~(1 << 31);
//   }
// }
// ```
// ) <hash-entry>

Our hashtable component arrays diverge from the conventional hashtable model in that elements are added in the same manner as any other Components (typically via a list append). 
Thus, the table must be rehashed before a search can occur since its properties are invalidated after each addition. 
In typical usage, the hashtable is populated during a parse, rehashed once parsing is complete, and then used like a standard table. 
However, Component lookup operations return the associated Entity (as opposed to the Component data itself), enabling other Components tied to that Entity to be queried in the usual ECS fashion.

=== Imperative Lox <sect:lox>

With our ability to perform calculations and look up references now prepared, all the necessary parts were in place to implement a more general-purpose programming language.

In his book _Crafting Interpreters_~@nystrom2021, Robert Nystrom introduces Lox, a simple, dynamically typed, object-oriented programming language. In addition to the two implementations of Lox included in the book, the language has inspired a large number of third-party implementations across a variety of programming languages. 
Nystrom also provides a suite of benchmark programs, making Lox an ideal candidate for performance benchmarking.

==== Attribute Bubble Interpretation

One of the most apparent advantages of using an ECS is the ease with which new types of structures can be dynamically attached to Entities. 
For example, during interpretation, it is convenient to attach runtime-type information to AST nodes as they are processed. 
@lst:runtime-type illustrates how our implementation is capable of querying this runtime-type information efficiently. 
The ECS facilitates this kind of dynamic attachment through a single function call, making the process both straightforward and flexible. 
Consequently, we treat the ECS itself as the primary data store for running programs.

#figure(
  placement: top,
  caption: [
	Code used to determine the runtime-type of an Entity in an Attribute Bubble interpreter.
  ],
```cpp
runtime_type determine_runtime_type(Entity e) {
	if(e.has_component<runtime_type>())
		return e.get_component<runtime_type>();
	else if(e.has_component<Lox::null>())
		return runtime_type::Null;
	else if(e.has_component<double>())
		return runtime_type::Number;
	else if(e.has_component<bool>())
		return runtime_type::Boolean;
	else if(e.has_component<Lox::string>())
		return runtime_type::String;
	else return runtime_type::Invalid;
}
```
) <runtime-type>

Since Components in our ECS are stored in flat component arrays, topologically sorting the AST into a specific traversal order transforms the traversal process into a simple linear iteration. 
By arranging the elements in reverse order, as shown in @lst:reverse-itteration, we gain a slight efficiency boost, as comparisons against zero can take advantage of specialized instructions provided by some CPU instruction set architectures.

#figure(
  // placement: top,
  caption: [x86 provides special instructions for checking if an integer is equal to zero. Thus, the top loop will run slightly faster than the bottom loop.],
```cpp
// This loop will run slightly faster...
for(uint i = N - 1; --i; ) { /* useful code*/ }

// Than this loop
for(uint i = 0; i < N; ++i) { /* useful code*/ }
```
) <reverse-itteration>

#[
  #set par(first-line-indent: (amount: 1em, all: true))
  Among the various reversed traversal schemes we could use to sort our programs topologically, we chose reverse post-order, ensuring that each child node appears after its parent. 
  This ordering is beneficial when searching for a containing block.
  Rather than requiring every Component type to store a reference to its parent explicitly, we can rely on the assumption that a backward linear scan, as depicted in @lst:current-block, will eventually locate the relevant parent block in the rare occasions when they are needed. 
  Moreover, with this ordering in place, a backward linear scan becomes a depth-first search.
]

#figure(
  placement: bottom,
  scope: "parent",
  caption: [
	The code we use to find the block of code an Entity belongs to. Notice how the code is little more than a reverse linear scan.
  ],
```cpp
Entity current_block(Module& module, entity_t root) {
  entity_t target = root;
  do {
	// Decrement until we find a block or run out of Entities
	while((root - 1) > 0 && !module.has_component<block>(--root));
  // If target is larger than the number of children in the root... it can not be root's child
  } while(root > 0 && root + module.get_component<children>(root).total < target);
  return root;
}
```
) <current-block>

However, to ensure that reverse iteration aligns with a valid execution sequence, the Entities (not just their Components) must be sorted. 
To accomplish this, we employ a sorting scheme for Entities that mirrors the one used for Components. 
Entities themselves can be easily reordered through simple swaps; however, any Components that store Entities must be made aware of the change. 

// The ordering itself is established by performing a post-order traversal of the AST, during which we collect the Entity associated with each node into a list. Once the traversal is complete, we reverse the list to achieve the desired reverse post-order. This guarantees the useful property that every node appears after its parent in the ordering, with the root of the program corresponding to the first Entity in the final sequence.

// We also account for Entities that may exist outside the AST, such as those created during backtracking in the parsing phase, by maintaining a set of Entities not yet discovered by the traversal. As each Entity is encountered, it is removed from this set. Any remaining "missing" Entities at the end of the traversal are simply appended to the end of the final ordering.

// A problem then arose in our AST storage scheme: it did not differentiate between regular code blocks and functions. As a result, functions are executed not only when they are explicitly called but also once during the reverse traversal of the AST.

// To address this, we inserted a special marker at the beginning of each block. This marker holds a reference to the block’s Entity. After sorting the AST, this marker becomes associated with the last Entity of the corresponding block. During reverse iteration, if we encounter a marker that does not belong to the block of code currently being executed, we skip to the beginning of the relevant block using the stored Entity.

// This applies not just to functions but other control structures as well: markers are added to the beginning (which becomes the sorted end) of loop bodies, as well as to both the "then" and "else" blocks of if statements. This ensures that these constructs are handled correctly during traversals.
To resolve an issue in our AST storage scheme—where functions and regular code blocks were not distinguished, causing unintended execution during reverse traversal—we introduced a special marker at the start of each block. 
This marker references the block's Entity and, after sorting the AST, becomes the block's last Entity numerically. During reverse iteration, if a marker does not match the currently executing block, we skip to the correct block using the stored reference. 
This mechanism applies not only to functions but also to control structures like loops and if-statements, with markers added to loop bodies and the latter branch of conditionals to ensure correct traversal behavior.

A related issue arises on the other end of a function call: when invoking a function, we do not initially know where to begin the reverse iteration. 
To resolve this, we perform a recursive traversal of the AST, during which we calculate and store the number of child Entities associated with each Entity. 
This preprocessing step enables us to determine the exact size of each function's body.
Then, when a function is called, we can consult this stored child count to know how many Entities to skip forward.

Once the AST has been topologically sorted (and child counts identified), we can carry out all further semantic analysis as linear iterations over the ECS. 
In our Lox implementation, we perform three additional semantic analysis passes:

+ The first is a lookup pass, which resolves lexeme references to their corresponding Entities. For example, when a variable `X` is used, this pass identifies where `X` is defined in the program and stores a reference to that Entity.
+ The second pass is reference verification, which checks the results of the lookup pass and reports errors for any unresolved variables or functions. This function is provided in full in @lst:verify-references.
+ The third is a function arity pass, which ensures that each function call has the correct number of arguments as defined in its declaration, while reporting errors when mismatches are detected.

#figure(
  placement: top,
  scope: "parent",
  caption: [
	The complete code for the semantic analysis pass that is responsible for determining if variables and functions exist. 
	Notice how the System uses the AST's root's (Entity \#1) child count to determine where to begin reverse iteration.
	Also, notice how easily a Component (AST node type) can be checked for and then accessed.
  ],
```cpp
bool verify_references(Module& module) {
	bool valid = true;
	for(Entity e = module.get_component<children>(1).reverse_iteration_start(1); e--; ) {
		if(e.has_component<call>()) {
			auto& call = e.get_component<call>();
			auto& ref = call.parent.get_component<Entity_reference>();
			if(!ref.looked_up()) {
				ERROR("Failed to find function.");
				valid = false;
			}
		} else if(e.has_component<assign>()) {
			auto& op = e.get_component<operation>();
			auto& ref = op.a.get_component<Entity_reference>();
			if(!ref.looked_up()) {
				ERROR("Failed to find variable.");
				valid = false;
			}
		} else if(e.has_component<variable>()) {
			auto& ref = e.get_component<Entity_reference>();
			if(!ref.looked_up()) {
				ERROR("Failed to find variable.");
				valid = false;
			}
		}
	}
	return valid;
}
```
) <verify-references>

// We deliberately separate the lookup and reference verification passes to support future expansion. As the project evolves, we anticipate the need to support multiple modules. This separation allows us to perform lookup on individual submodules and defer reference verification until after the modules have been linked together. This design provides flexibility and lays the groundwork for modular compilation.

When all of these features are combined, they result in what we refer to as an Attribute Bubble Interpreter. 
In an Attribute Bubble Interpreter, all data is stored in preallocated memory locations corresponding to AST nodes within the ECS, and values (attributes) bubble down through the AST (starting at the last Entity and ending at the first). 
@lst:attribute-bubble details a snippet of the interpreter code showing how attributes bubble through the multiply instruction.

#figure(
  placement: top,
  scope: "parent",
  caption: [
	The main interpret function used to bubble attributes, along with the multiply instruction. 
	Notice that a `runtime_type` and `double` are directly attached to the Entity representing the AST node for the multiply instruction.
	Attaching values to AST nodes is the primary mechanism utilized by an Attribute Bubble interpreter.
  ],
  [
#set text(size: 9.5pt)
```cpp
bool interpret_multiply(Module& module, Entity target) {
  auto& op = target.get_component<operation>();
  if(
    determine_runtime_type(module, op.a) == runtime_type::Number 
    && determine_runtime_type(module, op.b) == runtime_type::Number
  ) {
    target.get_or_add_component<runtime_type>() = runtime_type::Number;
    target.get_or_add_component<double>() = op.a.get_component<double>() * op.b.get_component<double>();
    return true;
  }
  // Error handling omitted for brevity
}

std::pair<bool, bool> interpret(TrivialModule& module, entity_t root, Entity returnTo = 0) {
  bool valid = true;
  bool should_return = false;
  
  for(
    Entity e = module.get_component<children>(root).reverse_iteration_start(root); 
    (e--).Entity > root && valid && !should_return; 
  ) {
    // Many branches omitted for brevity...
    else if(e.has_component<multiply>())
      valid &= interpret_multiply(module, e);
    // Many branches omitted for brevity...
  }
  
  // If this is a function call... mark that we returned null
  if(returnTo.Entity > 0) returnTo.get_or_add_component<runtime_type>() = runtime_type::Null;
  return {valid, should_return};
}
```
]
) <attribute-bubble>

This architecture eliminates the need for a traditional call stack, while function calls still operate correctly because each function has dedicated memory reserved in the ECS. 
However, recursion is not supported (with the exception of tail recursion).
This limitation arises because each function call clears the previously allocated memory, preventing nested invocations from preserving state.

Similarly, this approach restricts classes to a single instance each. 
Just like function bodies, class bodies rely on preallocated memory, which prevents multiple instances from existing simultaneously.

This "pure" ECS-based model works reasonably well for simple imperative languages. 
However, implementing slightly more complex language features—even those found in minimally complex languages like C—would require additional side structures. 
As a result, this interpreter does not fully implement the Lox language as initially designed. 
Instead, it supports a simplified subset we call "Imperative Lox," where most of the functional and object-oriented features from the original language are either ignored or treated as errors.

==== Performance <sect:benchmark>

To evaluate the performance of our Attribute Bubble Interpreter, we used Nanobench~@nanobench, a C++ benchmarking library that repeatedly runs a code snippet and averages the execution time. 
We used it to test our Lox implementation against the C (bytecode) and Java (tree-walk) implementations from _Crafting Interpreters_~@nystrom2021.

// TODO: Rewrite
// We benchmarked two Lox programs:  
// The first is an example that executes some simple math and prints the results, which appears throughout the later sections and is enumerated in @fig:precidence-example.  
// The rest are a selection from the few benchmarks provided by Nystrom~@nystrom2025tests that does not rely on functional or object-oriented features, which our interpreter architecture does not support. `benchmark/equality.lox` runs several loops ten million times, performing a series of largely redundant constant creations and equality comparisons. `logical_operator/and.lox` performs several short circuit evaluations while `operator/comparison.lox` performs several logical comparisons, however most of the time time in both these benchmarks is spent on print instructions. Finally `if/truth.lox` tests several if statements.
We benchmarked two types of Lox programs:
The first is a simple example that performs basic arithmetic operations and prints the results. 
This program is referenced throughout the later sections and shown in detail in @lst:precedence-example.
#figure(
  caption: [
	A simple Lox program that performs a simple computation and prints the result.
  ],
```JS
var x = 5; var y = 6; var z = 7;
print x + y * z / (z - y);
```
) <precedence-example>

The second group consists of benchmarks selected from those provided by Nystrom~@nystrom2025tests. 
We chose only those that do not rely on functional or object-oriented features, as Attribute Bubble interpretation does not support them.
`benchmark/equality.lox` runs several loops ten million times, repeatedly creating constants and performing equality comparisons, many of which are redundant.
`logical_operator/and.lox` performs several short-circuit evaluations, while `operator/comparison.lox` executes multiple logical comparisons. 
However, in both of these benchmarks, the majority of execution time is spent on print instructions.
Finally, `if/truth.lox` evaluates a series of if statements.

// All benchmarks were executed on a custom-built machine featuring an Intel i7-13700K processor, 32GB of DDR5-6400 RAM, and a 1TB Samsung 980 Pro SSD, running Ubuntu 24.04. 
// The code used to implement and run these benchmarks was compiled using GCC 13.3.0 using CMake's default `Release` flags and is publicly available in our GitHub repository~@dahl2025benchmarklox.
// We ran an additional benchmark~@dahl2025startupcost that checks the startup time of a program with an empty `main` function and added the extra 1,098,828.17 ns it found on average to each ECS run to compensate for fact that those tests run in the benchmark executable and don't themselves have a startup time.
All benchmarks were executed on an Intel i7-13700K processor, running on a MAG Z790 Tomahawk Wifi with 32 GB of DDR5-6400 RAM, and a 1 TB Samsung 980 Pro SSD, running Ubuntu 24.04. 
The code used to implement and run these benchmarks was compiled with GCC 13.3.0 using CMake's default Release flags and is publicly available in our GitHub repository~@dahl2025benchmarklox.
We also ran an additional benchmark~@dahl2025startupcost to measure the startup time of a program with an empty main function. 
The average startup time of 1,098,828.17 ns was added to each ECS benchmark result to account for the fact that these tests run within the benchmark executable and therefore do not incur their own startup overhead.

The results of these benchmarks are presented in @fig:lang-bench.  
For simple programs, the Attribute Bubble Interpreter outperforms both the treewalk and bytecode interpreters, showing significantly better performance.  
However, as programs become less linear, their performance degrades considerably.  
These findings thus do not support our hypothesis that using an ECS improves execution performance. 
In fact, the performance of the non-linear test (`benchmark/equality.lox`) undermines what is often considered the primary advantage of ECS in the context of game development.

// #let data1 = (
//   ([ECS], 0.027912),
//   ([C], 1.797699),
//   ([Java], 39.746378),
// )

// #let data2 = (
//   ([ECS], 23.904980011),
//   ([C], 2.027889601),
//   ([Java], 2.027889601),
// )

// #figure(
//   placement: top,
//   caption: [Comparison in time (lower is better) of our Lox interpreter (ECS) compared against Nystrom's C and Java implementations of Lox running the example code in @fig:precidence-example (top) and a benchmark taken from the Lox test set~@nystrom2025equalitylox (bottom).],
//   [
//	 #canvas({
//	   draw.content((3.5, 3.25), [@fig:precidence-example])
//	   chart.barchart(data1, size: (7, 3), x-label: [Time (milliseconds)])
//	 })
//	 #canvas({
//	   draw.content((3.5, 3.25), [@fig:precidence-example])
//	   chart.barchart(data2, size: (7, 3), x-label: [Time (seconds)])
//	 })
//   ]
// ) <lang-bench>
// #figure(
//   placement: bottom,
//   scope: "parent",
//   caption: [Comparison in time of our Lox interpreter (ECS) compared against Nystrom's C and Java implementations of Lox running the example code in @fig:precedence-example and several benchmarks taken from the Lox test set~@nystrom2025tests.],
  
// ) <lang-bench>
#figure(
  placement: top,
  scope: "parent",
  kind: image,
  caption: [Comparison in time (lower is better) presented as a table (top) and graphically (bottom) of our Lox interpreter (ECS/Gray) compared against Nystrom's C (Blue) and Java (Orange) implementations of Lox running the example code in @lst:precedence-example as well as several benchmarks taken from the Lox test set~@nystrom2025tests. `benchmark/equality.lox` took substantially longer than the others and is thus separated; also note its different timescale.],
  [
    #let raw_data = (
      (26395.05 + 1098828.17, 1571765.18, 39512506.15),
      (24841864718.30 + 1098828.17, 2051955993.50, 2888242399.18),
      (51256.57 + 1098828.17, 1474295.20, 39171295.03),
      (92678.30 + 1098828.17, 1423657.73, 39471836.07),
      (39615.52 + 1098828.17, 1556280.62, 39162924.04),
    )
    #let table_format = "{:.3} ms"
    #let ns_to_ms(ns) = ns / 1000000
    #let ns_to_s(ns) = ns_to_ms(ns) / 1000
    #table(
    columns: 4,
    align: (left, horizon, horizon, horizon),
    stroke: none,
    table.header(
      [*Benchmark*], [*ECS*], [*C*], [*Java*],
    ),
    table.hline(),
    [@lst:precedence-example], [#strfmt(table_format, ns_to_ms(raw_data.at(0).at(0)))], [#strfmt(table_format, ns_to_ms(raw_data.at(0).at(1)))], [#strfmt(table_format, ns_to_ms(raw_data.at(0).at(2)))],
    [#link("https://github.com/munificent/craftinginterpreters/blob/master/test/logical_operator/and.lox")[logical_operator/and.lox]], [#strfmt(table_format, ns_to_ms(raw_data.at(2).at(0)))], [#strfmt(table_format, ns_to_ms(raw_data.at(2).at(1)))], [#strfmt(table_format, ns_to_ms(raw_data.at(2).at(2)))],
    [#link("https://github.com/munificent/craftinginterpreters/blob/master/test/operator/comparison.lox")[operator/comparison.lox]], [#strfmt(table_format, ns_to_ms(raw_data.at(3).at(0)))], [#strfmt(table_format, ns_to_ms(raw_data.at(3).at(1)))], [#strfmt(table_format, ns_to_ms(raw_data.at(3).at(2)))],
    [#link("https://github.com/munificent/craftinginterpreters/blob/master/test/if/truth.lox")[if/truth.lox]], [#strfmt(table_format, ns_to_ms(raw_data.at(4).at(0)))], [#strfmt(table_format, ns_to_ms(raw_data.at(4).at(1)))], [#strfmt(table_format, ns_to_ms(raw_data.at(4).at(2)))],
    [#link("https://github.com/munificent/craftinginterpreters/blob/master/test/benchmark/equality.lox")[benchmark/equality.lox]], [#strfmt(table_format, ns_to_ms(raw_data.at(1).at(0)))], [#strfmt(table_format, ns_to_ms(raw_data.at(1).at(1)))], [#strfmt(table_format, ns_to_ms(raw_data.at(1).at(2)))],
  )
	#let data = (
	  ([@lst:precedence-example], raw_data.at(0).map(ns_to_ms)),
	  ([#link("https://github.com/munificent/craftinginterpreters/blob/master/test/logical_operator/and.lox")[logical_operator/and.lox]], raw_data.at(2).map(ns_to_ms)),
	  ([#link("https://github.com/munificent/craftinginterpreters/blob/master/test/operator/comparison.lox")[operator/comparison.lox]], raw_data.at(3).map(ns_to_ms)),
	  ([#link("https://github.com/munificent/craftinginterpreters/blob/master/test/if/truth.lox")[if/truth.lox]], raw_data.at(4).map(ns_to_ms)),
	)
	#let data2 = (
	  ([#link("https://github.com/munificent/craftinginterpreters/blob/master/test/benchmark/equality.lox")[benchmark/equality.lox]], raw_data.at(1).map(ns_to_s)),
	)
	#let lang_palette = palette.new(colors: (rgb("#708090"), rgb("#6AA0CC"), rgb("#CE7505")))
	#canvas({
	  chart.barchart(
		mode: "clustered",
		size: (9, 4), 
		x-label: [Time (milliseconds)], 
		label-key: 0,
		value-key: (1, 2, 3), 
		data, 
		labels: ([ECS], [C], [Java]),
		bar-style: lang_palette
	  )
	})
	#canvas({
	  chart.barchart(
		mode: "clustered",
		size: (9, 1.5), 
		x-label: [Time (seconds)], 
		label-key: 0,
		value-key: (1, 2, 3), 
		data2, 
		labels: ([ECS], [C], [Java]),
		bar-style: lang_palette
	  )
	})
  ]
) <lang-bench>
// What about startup overhead? The JVM is known for being slow to start.

We believe this performance gap arises from a fundamental difference in access patterns: games typically involve straightforward linear iteration over Entities, whereas compilers require much more random access to data.
While interpretation still involves a good deal of direct iteration, it also frequently requires jumping to other parts of the ECS—for example, when a function is invoked or a loop is iterated.  
Similarly, following variable references or other indirections often breaks the sequential access pattern.
Each of these jumps and indirections invalidates the cache locality that the games industry heavily focuses on.
However, in compilers, we have plenty of operations that do not march straight through the data without stopping.

With all the focus on the poor results of the `benchmark/equality.lox` test case, it is easy to overlook that the more linear test cases (where the ECS was allowed to "march straight through") outperformed the competition, averaging 1.3 times faster than C and 34 times faster than Java. 
While performance may not always be the primary reason to choose an ECS, it remains a significant consideration, especially since we believe many optimization passes will find themselves in this "march straight through" scenario. 
Additionally, we discovered several notable usability benefits, particularly if some of our stricter constraints are relaxed, which we believe make ECS appealing even for cases that do not find themselves on the linear "happy path."

// What about programs that have good locality? Do you think there could be real-world programs which would perform better with your bubble interpreter? Physics simulations? Matrix computations? etc?
// Is there data that supports this explanation? It would also be interesting to show a breakdown of the slowdown sources.

== Additional Benefits <sect:benefits>

Combined with the lack of support for object-oriented and functional programming paradigms, the Attribute Bubble Interpreter ultimately serves more as a proof of concept than a practical tool.  
It demonstrates that interpretation is possible within the strict limitations we imposed (a single ECS and a single string), but realistically offers little outside of academic novelty.
That said, the ECS architecture itself still provides several notable benefits outside the scope of performance, which warrant further consideration.

=== Storing Multiple Intermediate Representations Attached Together

The Attribute Bubble Interpreter highlights the power of dynamically adding Components within an ECS-based System.  
We have demonstrated that it is possible to topologically sort a tree in such a way that a simple linear iteration over the structure effectively simulates a traditional traversal.  
Once the AST is in this linearized form, we can attach Three Address Code (3AC) tuples to each node—using the node's ID as the result and the first two fields of the operation as operands—effectively embedding linear code directly within the tree.  
Because we can perform linear iterations over this structure, executing the code becomes as straightforward as iterating to traverse the tree, skipping over any nodes that do not contain associated 3AC instructions.

Our 3AC generation function is slightly more complex than a basic implementation, as it also does some basic variable assignment optimization.  
Due to the structure of our AST, directly generating 3AC can produce multiple layers of redundant assignments, an issue illustrated in @lst:redundant-copies.  
To address this, we apply a simple substitution pass, provided in full in @lst:substitute-3ac, that analyzes how many times each AST node is assigned a value.  
Any assignment to a node that only receives a single value throughout the program is considered redundant and is removed.

#figure(
  placement: top,
  caption: [
    An example of the 3AC we generate before (left) and after (right) removing redundant assignments for the Lox code in @lst:precedence-example. 
    The numbers represent Entity IDs; in both cases, the value attached to Entity \#4 would be printed (if using an Attribute Bubble interpreter).
  ],
  columns(2, [
	```js
	// Before
	23 <- 5 immediate
	24 <- 23
	19 <- 6 immediate
	20 <- 19
	15 <- 7 immediate
	16 <- 15
	12 <- 20
	11 <- 16
	10 <- 11 - 12
	9 <- 16
	8 <- 20
	7 <- 8 * 9
	6 <- 7 / 10
	5 <- 24
	4 <- 5 + 6
	```
	#colbreak()
	#v(7%)
	```js
	// After
	23 <- 5 immediate
	19 <- 6 immediate
	15 <- 7 immediate
	10 <- 15 - 19
	7 <- 19 * 15
	6 <- 7 / 10
	4 <- 23 + 6
	```
  ])
) <redundant-copies>

#figure(
  placement: bottom,
  scope: "parent",
  caption: [
    A snippet of the code responsible for building a 3AC representation that optimizes away redundant assignments. 
    It removes 3AC entries when there is only one assignment to the result, and the entry does not represent loading an immediate value.
  ],
```cpp
std::unordered_map<entity_t, entity_t> substitutions;
for(Entity e = module.get_component<children>(1).reverse_iteration_start(1); e--; ){
	if(!e.has_component<addresses>(module)) continue;

	auto& addresses = e.get_component<addresses>(module);
	if(substitutions.contains(addresses.a)) addresses.a = substitutions[addresses.a];
	if(substitutions.contains(addresses.b)) addresses.b = substitutions[addresses.b];

	auto assignments = addresses.res.get_component<assignment_counter>().count;
	if(assignments == 1 && addresses.b == 0 && addresses.a != 0) {
		substitutions[addresses.res] = addresses.a;
		e.remove_component<addresses>(module);
	}
}

module.release_storage<assignment_counter>();```
) <substitute-3ac>

#[
  #set par(first-line-indent: (amount: 1em, all: true))
  To perform this substitution, we first count the number of assignments associated with each node.  
  Notably, the counters used for this process can be efficiently discarded with a single function call (the last line of @lst:substitute-3ac), allowing us to reclaim memory with minimal overhead.
]

For reference, @sect:full-tree contains the complete AST, including all attached 3AC instructions, corresponding to the example presented in @lst:redundant-copies.

=== Simple Serialization for Simple Intermediate Representations <sect:serialize>

A keen reader may have noticed that we did not address control flow in the previous section.  
While our current implementation omits them, we have conducted some preliminary experiments involving the construction of a Control Flow Graph (CFG) to support the construction of Single Static Assignment (SSA) form.  
Although our ECS structure is capable of representing graphs, implementing a CFG in practice requires allocating additional side structures, such as `std::vectors` to track predecessor and successor blocks.

// Up to this point, arrays of block children and parameters have been stored using a linked list approach, where `list_entry` components are attached directly to the relevant child Entities.  
// However, extending this approach to support arbitrary graph structures—where a single node may have multiple parents—is significantly more complex, as it involves duplicating Component types (an example is presented in @fig:need-one-more-Component), dynamically managing which unique copy to use, and hoping that no node has more parent connections than the fixed number of supported list chains.
Until now, arrays of block children and parameters have been managed using a linked list approach, with `list_entry` components attached directly to the relevant child Entities.
However, extending this method to support arbitrary graph structures—where a single node can have multiple parents—introduces significant complexity. 
This would require duplicating component types (as illustrated in @fig:need-one-more-Component), dynamically managing which unique copy to use, and relying on the assumption that no node exceeds the fixed number of supported list chains for parent connections.

#figure(
  placement: top,
  raw-render(```
digraph G {
  times -> plus
  times -> negate
  subgraph cluster_3 {
	  style=invis
	  plus-> a
	  plus -> b
	  negate -> plus
  }
  times [label="1: Multiply"]
  negate [label="2: Negate"]
  plus [label="3: Add"]
  a [label="4: A"]
  b [label="5: B"]
}
  ```, width: 50%),
  caption: [
    Consider Entity \#2: we can easily create a `parent` component referencing Entity \#1. 
    But with Entity \#3, things get more complex. 
    Should we update the `parent` component to store both Entity \#1 and Entity \#2, or introduce a new `parent_2` Component? 
    A similar issue arises for children: Entity \#3 needs a `list_entry` for both parents. 
    While we could define a `list_entry_2`, the core problem remains—no matter how many Component types exist, a program can always be generated that requires one more. 
    This is not an issue if heap allocation is allowed, but that introduces non-ECS or string structures, complicating serialization.
  ]
) <need-one-more-Component>

This issue would be trivial to resolve if we allowed parent nodes to store a `std::vector` of their children.  
However, our current ECS design is intended to serialize directly to disk, which precludes the use of such dynamic memory facilities.

As long as each Component stores only plain data—replacing all pointers to dynamic memory with Entity IDs and attaching other flat Components—the entire structure can be easily moved from memory to disk.  
Our entire serialization code~@dahl2025serialize for ASTs and 3AC (neither of which has this duplicate list chain problem) is concise, comprising less than 50 lines of code in each direction.  
Additionally, most of the data is transferred efficiently using large `memcpy` operations, making the process both fast and straightforward.

=== Linear Traversals with Dynamic Polymorphism

Earlier, we discussed the semantic analysis performed by the Attribute Bubble Interpreter.  
@lst:verify-references presented the complete code used to verify whether references to variables and functions are valid.  
We also mentioned a simple optimization applied during the construction of our 3AC, with the relevant code provided in @lst:substitute-3ac.

Both of these common operations (reference verification and optimization) would typically require some form of tree traversal and likely a complex visitor pattern.  
However, in our implementation, they are handled as straightforward ECS-style Systems.  
These Systems consist of functions that apply bulk processing to every Entity matching a specific set of Components.  
We believe that this simplicity in writing analysis and optimization passes is one of the greatest strengths of using an ECS.

Additionally, these ECS-style Systems can easily constrain which types of Entities they should run on.  
An Entity takes a role similar to a void pointer, but we can cheaply ask if the Entity has specific Components (say a call, assignment, or variable declaration tag).  
This allows for cheap and dynamic polymorphism where new Components can be attached to an Entity at will.

== Limitations and Future Work <sect:limitations>

Throughout this paper, we have mentioned some of the limitations our strict requirements produced. 
However, while the ECS architecture in general provides some notable benefits, it also has some notable weaknesses. 
One of the key drawbacks is the memory overhead associated with Component storage. 
In our implementation, each Component requires an additional eight bytes to store Entity index information, which gets allocated for every single Entity. 
Thus, there are dueling pressures to minimize the number of Component types to reduce memory overhead while also being able to attach arbitrary information to solve specific problems, which inflates the Component count.

Furthermore, we attach source information to every Entity.
While this approach simplifies access, it could potentially be optimized using a hashtable.
However, in scenarios where every source entry is unique, a hashtable might actually introduce more overhead than it eliminates.

These issues tie into one of the more holistic limitations of this paper: 
The narrow scope of the programs we analyzed. 
Our longest test program spans only twenty lines of code. 
Given this limited scale, we have not been able to thoroughly evaluate how certain costly operations, such as the tree-sorting step, scale with increased code size. 
This raises an important question: Does the performance gain from linear iteration and the simplicity it brings to implementing optimization passes outweigh the cost of tree canonicalization?

To properly address these questions, we need to develop implementations for larger, more complex languages and run them through more comprehensive benchmark suites. 
An implementation of the C programming language is already in development, which should provide more insights into how well our ECS-based System scales. 
We hypothesize that our linear iteration optimization passes will scale more favorably with program length than traditional tree traversal methods.
However, to validate the performance and memory efficiency of our System, it will be necessary to compare it against established compilers like Clang or GCC.

== Conclusion <sect:conclusion>

In conclusion, we have explored how Entity Component Systems (ECSs)—a data structure commonly used in game engines—can be applied in the context of compiler and interpreter design. 
While ECS does not offer the same consistent performance advantages to languages as it does to games, primarily due to the inherently more random access patterns found in programming languages, it still presents meaningful benefits. 
Notably, it simplifies the implementation of optimization passes and enhances the overall serializability of the System.
Although our findings are preliminary and based on relatively small programs, they remain promising.
We are eager to continue this work and evaluate the approach more thoroughly on larger, more complex codebases.

#unumbered_heading[Acknowledgement]
This material is based in part upon work supported by the National Science Foundation under grant numbers 
// \#\#\#-\#\#\#\#\#\#\#.
OIA-2019609 // T2 Tic % I'm guessing this number is no longer relevant?
 and OIA-2148788. // T1 Fire
Any opinions, findings, and conclusions or recommendations expressed in this material are those of the authors and do not necessarily reflect the views of the National Science Foundation.
