#import "@preview/diagraph:0.3.3": *
#import "util.typ": unumbered_heading, code_block

= Background on Intermediate Representations <chapter:background>

// This chapter has all the background needed to explain everything else...
// Remember your audience - you are writing for a first semester graduate student...

// This chapter first appeared as a journal publication in ACM Computing Surveys. #linebreak()
// J. Dahl, Q. Contaldi, and F. Harris, "A Systematic Review of Intermediate Representations for Optimizing and Generating Code," ACM Computing Surveys, vol. ??, no. ??, pp. ??, 2025, doi: ??.

// This chapter will serve as the basis for a publication which is in the process of being developed for submission.

#unumbered_heading(centered: true)[Abstract]

This survey investigates a broad spectrum of intermediate representations in compiler design, emphasizing alternatives to standard forms like Abstract Syntax Trees, Control Flow Graphs, and Static Single Assignment, which dominate mainstream imperative languages.
To support this exploration, we conducted a systematic review beginning with a curated set of obscure yet foundational seed papers, followed by multi-level citation snowballing using CrossRef, and a hybrid filtering pipeline combining exact keyword and fuzzy phrase matching across abstracts and full texts. 
Framed around three core research questions: identifying underexplored IRs, evaluating their potential for optimization, and assessing their suitability for code generation. 
We highlight representations such as Program Dependence Graphs, Program Expression Graphs, Lambda Calculus, and Interaction Nets. These IRs offer insights beyond the dominant Static Single Assignment paradigm.

== Introduction
// - Why do we care?
// - In the early days if you wanted to write a compiler for a target machine architecture you did so... then if you wanted to target another architecture or use the same architecture with a different source language you would need to write a new compiler.
// - If instead a robust, general intermediate representation is defined this process can be reduced.
// - Instead of writing a compiler for every language, architecture pair, you can instead write a compiler from every language to the intermediate representation and then separately write a compiler form the intermediate representation to every architecture.
// - This reduces the number of compilers that need to be written from $hash"SourceLanguages" times hash"TargetArchitectures"$ to $hash"SourceLanguages" + hash"TargetArchitectures"$.
// - Additionally general optimizations can be defined on the intermediate representation thus benefiting every compiler utilizing it.
// - In 2013 a survey of intermediate representations in imperative compilers was completed. #link("https://dl.acm.org/doi/abs/10.1145/2480741.2480743")
// - With the rise of functional and logic programming (or at least the more wide spread adoption of their ideas) an expansion is in order.

While studying compiler design, it is important to understand why Intermediate Representations (IRs) matter. 
Traditionally, if a developer wanted to write a compiler targeting a specific machine architecture, they would create one directly tailored for that combination of source language and hardware. 
However, this approach quickly becomes inefficient. 
For each new source language or target architecture, a new compiler had to be developed from scratch for each of the language pairs.

To address this, the introduction of a robust, general-purpose IR significantly reduces the complexity of compiler development. 
Instead of creating a unique compiler for every language-architecture pair, developers can write one compiler from each source language to the IR, and then separate compilers from the IR to each target architecture.
This modular approach drastically reduces the number of compilers that need to be written, from a number equal to the product of the number of source languages and target architectures, to a number equal to the sum of the two. 
In other words, rather than writing $"SourceLanguages" times "TargetArchitectures"$ compilers, one only needs to create $"SourceLanguages" + "TargetArchitectures"$ compilers.

Beyond simplification, this strategy enables the definition of general optimizations on the IR itself.
These optimizations can then be leveraged by all compilers that make use of the IR, leading to more efficient and consistent output across platforms.

In 2013, a survey was conducted on IRs in imperative language compilers~@Stanier2013. 
However, with the increasing popularity and influence of functional and logic programming paradigms, there is a growing need to expand this survey to accommodate a broader range of programming paradigms better.

// - According to the TIOBE index in July 2025 all 10 of the most searched for programming languages are imperative. #link("https://web.archive.org/web/20240607234340/https://tiobe.com/tiobe-index/")
// - Similarly in the first quarter of 2024 the top ten languages with most code pushed to github were all imperative #link("https://madnight.github.io/githut/#/pushes/2024/1")
// - All a majority of them use a 3AC based IR (except GCC family languages which uses an AST like representation (See section ?))
// - 3AC/SSA based IRs have "won" in the non-academic programming space
// - A major goal of this survey is to find useful IRs outside the mainstream imperative bent.

In July 2025, the TIOBE index reported that all ten of the most searched-for programming languages were imperative in nature~@tiobe2025. 
A similar trend was observed earlier, in the first quarter of 2024, where the top ten programming languages with the most code pushed to GitHub were also all imperative~@githut2024.
Most of these popular imperative languages rely on an IR based on Three-Address Code (3AC) (see~@2:sect:3ac), with the notable exception of the GCC family of languages, which use an Abstract Syntax Tree-like representation (see~@2:sect:ast). 
This prevalence indicates that 3AC and Static Single Assignment (see~@2:sect:ssa) forms have effectively become the dominant IRs in non-academic, production-level programming environments.

Given this mainstream dominance, a central goal of this survey is to explore and highlight IRs that break away from this imperative orientation, particularly those that might offer utility or innovation beyond the prevailing 3AC/SSA paradigm.
// - To that end we ask the following research questions:
// - RQ1: What IRs exist beyond the standard AST, CFG, and SSA found in almost every industrial compiler?
// - RQ2: What IRs provide the most support for beneficial optimizations?
//   - Global Value Numbering
//   - Automatic Parallelization
//   - Automatic Vectorization
//   - Dead Code Elimination
// - RQ2: What IRs lend themselves to code generation?
Towards that end, we propose a set of research questions aimed at better understanding the landscape of IRs, particularly beyond those traditionally used in imperative compilers.

+ What IRs exist beyond the standard Abstract Syntax Trees (ASTs), Control Flow Graphs (CFGs), and Static Single Assignment (SSA) forms that are found in almost every industrial compiler? While these conventional IRs have proven effective, they may not fully address the needs of modern programming paradigms, such as functional and logic programming, or support emerging hardware architectures and parallel execution models.
+ Which IRs provide the most support for enabling beneficial optimizations? Such as:
  - Global Value Numbering, which allows for the detection and elimination of redundant computations.
  - Automatic Parallelization, where the IR supports the analysis and transformation of code into forms that can be executed in parallel.
  - Automatic Vectorization, enabling efficient use of SIMD (Single Instruction, Multiple Data) instructions.
  - Dead Code Elimination, a fundamental optimization for removing code that has no impact on program behavior.
+ Which IRs are most amenable to code generation? That is, which IRs retain sufficient semantic detail and structural clarity to support the effective translation into target machine code, preferably across a wide range of architectures?

// - The next section discusses the methodology we used to conduct this review.
// - @2:sect:taxonomy breaks the IRs we discovered down into three distinct categories: Graphical, Linear, and Mathematical.
// - @2:sect:discussion Then considers the IRs through the lens of our research questions.
// - Finally, @2:sect:conclusion provides a summar of our conclusions.

The following section outlines the methodology used to conduct this review, detailing how we identified and analyzed a wide range of IRs.
In @2:sect:taxonomy, we categorize the IRs we discovered into three distinct groups: Graphical, Linear, and Mathematical.
Following this, @2:sect:discussion examines the identified IRs through the lens of our research questions, evaluating their capabilities in terms of optimization support and code generation potential.
Finally, @2:sect:conclusion presents a summary of our key findings and conclusions.

== Methodology <2:sect:method>

We began our study by manually searching for obscure seed papers relevant to IRs in compiler and systems research. 
During this process, we identified a preliminary list of DOIs:

// - Dragon Book // Can't be a seed! No DOI!
- #link("https://doi.org/10.1145/2480741.2480743") // Seed Survey (2back, 6forward)
- #link("https://doi.org/10.1515/9781400881932") // Should we try using all the chapters as seeds? // TODO: need to run
- #link("https://doi.org/10.1145/96709.96718")
- #link("https://doi.org/10.1109/CGO51591.2021.9370308")
- #link("https://doi.org/10.1006/inco.1994.1013")
- #link("https://doi.org/10.1007/978-3-540-24644-2_14")
// - #link("https://cds.cern.ch/record/162121/files/CM-P00069219.pdf")
- #link("https://doi.org/10.1016/0743-1066(92)90054-7") // TODO: Is there a better WAM seed?

Using these documents as seeds, we traced back two levels of references and forward six levels of citations. 
We limited this snowballing to artifacts with associated DOIs. 
This enabled the use of the CrossRef API~@crossref for automation and simultaneously filtered out most gray literature.
The intent of this process was to assemble a broad, yet relevant, candidate pool while remaining focused within the IR domain.

All collected DOIs from the snowballing process were consolidated into a single file. 
Duplicate entries across sources were removed, resulting in a clean list of unique DOIs, ready for the next phase of analysis.
// TODO: Add number of DOIs found
Each of these 1,685,170 DOIs underwent a basic bibliographic validation. 
Papers were excluded if they fell outside of acceptable parameters, such as:

+ Publication dates earlier than 1910,
+ Undesirable document types (anything other than journal articles, conference papers, book chapters, dissertations, technical reports, or reference entries),
+ Missing or mismatched bibliographic fields,
+ Papers focused on niche IR subfields which do not directly generate executable code, including disassembler-specific IRs~@sahasrabuddhe2007@liu2010@hasabnis2016@Kirchner2017 and IRs developed primarily for machine learning graphs~@cyphers2018@kunft2019@santhanam2021.
+ Papers focusing on IRs designed for non-classical (quantum) computing~@Cardama2025.

This filtering ensured that only academically valid and topically relevant literature would advance to the next stage.

Next, we evaluated the abstracts of the remaining papers using a thematic keyword model tailored to IR-related topics such as Static Single Assignment (SSA), code generation, and optimization. 
Keywords were grouped into thematic categories based on concepts commonly associated with compiler design and program analysis.
Each abstract was tokenized into lowercase words and scanned for exact matches against a set of curated single-word keywords. 
This step is computationally efficient and effective for capturing concise technical terms and acronyms. 
If an abstract did not meet the minimum group-match threshold during this fast check, it proceeded to a second-stage analysis.

The second stage used fuzzy matching via fuzz.partial_ratio from the RapidFuzz library~@rapidfuzz. 
Here, multi-word keyword phrases were compared against the abstract text, with a similarity threshold of 80% for acceptance. 
This step allowed for natural linguistic variation, paraphrasing, and formatting differences by identifying terms like "three-address code," "dead code elimination," and "program dependence graph."

The combination of both strategies (exact and fuzzy matching) ensures a balance between speed and semantic depth. 
Exact matching allows early exits for clearly relevant papers, while fuzzy matching prevents discarding borderline but valuable documents due to superficial differences in phrasing.
// TODO: Mention how many papers passed the abstract check

For papers passing the abstract check, we conducted full-text analysis. 
PDF documents were parsed, and their body text was extracted for evaluation using the same thematic keyword framework. 
This deeper level of filtering is particularly important for papers, such as those on optimization techniques, that introduce IR concepts more in the body, which may not be mentioned in the abstract.
// TODO: Mention how many papers passed the body check

Papers that successfully passed full-text evaluation were compiled for final manual review. Each entry was annotated with summary data, including relevance scores and matched thematic groups. These summaries were presented to human reviewers to ensure traceability, transparency, and accuracy. The goal of this stage was to finalize a high-quality, focused corpus for inclusion in the systematic review.
// TODO: Mention how many papers were included in the manual review

== Taxonomy <2:sect:taxonomy>

// Uncategorized
// - SUIF #link("https://dl.acm.org/doi/abs/10.1145/193209.193217")
// - INSPIRE #link("https://ieeexplore.ieee.org/abstract/document/6618799")
// - LLHD #link("https://dl.acm.org/doi/abs/10.1145/3385412.3386024")
// - Tapier #link("https://dl.acm.org/doi/abs/10.1145/3018743.3018758")
// 		(LLVM + Parrallel)
// - Pegasus #link("https://www.cs.cmu.edu/afs/cs/academic/class/15745-s07/www/papers/pegasus-tr02.pdf")
// - SPIRE #link("https://minesparis-psl.hal.science/hal-00823324/")
// 		Used for:
// 				- Parrallelizing LLVM #link("https://dl.acm.org/doi/abs/10.1145/2833157.2833158")
// - UNCOL #link("https://www.sciencedirect.com/science/article/abs/pii/B9781483197791500173")
// - SPIR #link("https://ieeexplore.ieee.org/abstract/document/4907665")
// - ??? #link("https://ieeexplore.ieee.org/abstract/document/9654240")
// - ??? SpireV Fuzzing #link("https://dl.acm.org/doi/abs/10.1145/3571253")
// - ??? #link("https://dl.acm.org/doi/abs/10.1145/2542142.2542143")
// - Graal #link("https://d1wqtxts1xzle7.cloudfront.net/76699729/APPLC-2013-paper_12-libre.pdf?1639772167=&response-content-disposition=inline%3B+filename%3DGraal_IR_An_extensible_declarative_inter.pdf&Expires=1718394620&Signature=dEesqLqbqOQRBbKKHZcOZtUm4SfzYM0KOTnOcKn2-C~ece9I98XxSaV~yJ8tOwaGncILgXz0AjR9sXKuLSO0lZxNbMH-zhofjtL~2H4IfZOHoqQU3cOrd1HI9LdrUYHj9TELRHPQepCeGfNw0HQjavlrhVDiaZtpgMfY5aT644jZGzOgWSC~HL8JZ-WThoiU48mw3BFBCMS250scaQvx8PbA4r6KRUtS4gvEStwIj4Q3KWDyNrHlV-2J~VALcBGdKWFHitdQztSj7r~X4HF8loh8sfItQtuRLbcG7gAqBH~7mnpUm1347o54Wb0Ei4dIimCW3bAX6V6ZK1ojd~uRbw__&Key-Pair-Id=APKAJLOHF5GGSLRBV4ZA")
// - HTG #link("https://link.springer.com/article/10.1007/BF02577777")
// - Kimble #link("https://researchgate.net/profile/Stephane-Louise/publication/266215350_Kimble_a_Hierarchical_Intermediate_Representation_for_Multi-Grain_Parallelism/links/54535bed0cf26d5090a3c6ea/Kimble-a-Hierarchical-Intermediate-Representation-for-Multi-Grain-Parallelism.pdf")
// - GCC GIMPLE #link("https://ftp.cygwin.com/pub/gcc/summit/2003/GENERIC%20and%20GIMPLE.pdf")
	// - GENERIC represents a function as a tree. As the name suggests, this conversion is independent of any language. 
	// - GIMPLE is a subset of GENERIC that is used for optimization. 
	// - A front-end can use the language-dependent tree codes in its GENERIC tree representation if it is able t provide a hook to convert it to GIMPLE form. 
	// - The parse tree structure is retained in GIMPLE. 
	// - The expressions are converted to three-address form where intermediate values are stored as temporary variables. 
	// - "Gimplifier" is the compiler pass that converts GENERIC to GIMPLE. 
	// - Complex statements are replaced by sequence of simple statements recursively by gimplifier.
	// Used for:
	//     Polyhedral Optimization: #link("https://www.researchgate.net/profile/Jan-Hubicka-2/publication/255615364_Interprocedural_optimization_on_function_local_SSA_form_in_GCC/links/5a85b0ab458515b8af88c576/Interprocedural-optimization-on-function-local-SSA-form-in-GCC.pdf#page=185")
// - XARK #link("https://ctuning.org/dissemination/grow10-proceedings.pdf#page=90")
// - ??? #link("https://dl.acm.org/doi/10.1145/3295500.3356173")
// - Theta Graph #link("https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=bcd58efdba831751d3b5ff2fe0bbd9e719034816")
// - Thinned Gated Single Assignment Form #link("https://link.springer.com/chapter/10.1007/3-540-57659-2_28")

// - We have broken down the IRs into three main categories:
// - Graphical: All IRs in this category are represented by a set of nodes connected by edges.
// - Linear: All IRs in this category can be represented as an array (note that strings are also technically arrays) which closely map to either a source or target language.
// - Mathematical: All IRs in this category use some form of mathematical substitution as the primary means to define and perform computations.
We have categorized the Intermediate Representations (IRs) into three main categories. 
The first is *Graphical*, which includes all IRs represented as a set of nodes connected by edges. 
The second is *Linear*, encompassing IRs that can be structured as arrays—this includes strings, which are technically arrays as well—and that closely correspond to either a source or target language. 
The third category is *Mathematical*, where IRs rely primarily on mathematical substitution to define and execute computations.

=== Graphical Intermediate Representations
	// #link("http://networksciencebook.com/")
		// - Graphical representations all rely on some basic concepts from graph theory.
		// - A graph, G, is denoted as G = (V, E) where V is a set of nodes (or vertices) which each represent some data.
		// - For instance every instruction a program should execute could be associated with a node.
		// - E is a set of edges (or links) each often represented as a pair $(V_1, V_2)$.
		// - $V_1$ and $V_2$ are called the endpoints of the edge, and are each nodes from V that the edge connects.
		// - For instance an instruction might be connected to the one immediately following it via an edge.
  Graphical representations are fundamentally based on core concepts from graph theory. 
  A graph, typically denoted as $G=(V, E)$, consists of two main components: a set of nodes (or vertices), $V$, and a set of edges (or links), $E$. Each node in $V$ represents some unit of data—for example, each node could correspond to a specific instruction that a program is meant to execute.
  
  The edges in $E$ are usually represented as pairs $(V_1, V_2)$, where $V_1$ and $V_2$ are elements from the set $V$. 
  These elements are referred to as the endpoints of the edge, and the edge itself signifies a connection between the two corresponding nodes. 
  For instance, one might model the relationship between sequential instructions in a program by connecting an instruction node to the one that follows it via an edge.
		#figure(
        placement: top,
			render("digraph {rankdir=LR; a->b->d; a->c->d; d->e->a;}"),
			caption: [A directed graph with arbitrarily named nodes.]
		) <basic-digraph>
		// - A subgraph represents a smaller graph $G prime = (V prime, E prime)$ where $V prime$ is a subset of V and $E'$ is a subset of E.
		// - For instance a subgraph of the graph presented in @fig:basic-digraph could be $G prime = ({a, b, c}, {(a, b), (a, c)})$ correlating to the leftmost three nodes and the two edges that flow between them as seen in @fig:basic-subgraph.
  A subgraph represents a smaller graph $G' = (V', E')$, where $V'$ is a subset of $V$ and $E'$ is a subset of $E$. 
  For example, a subgraph of the graph shown in @fig:basic-digraph could be $G' = (\{a, b, c\}, \{(a, b), (a, c)\})$, which corresponds to the leftmost three nodes and the two edges connecting them, as illustrated in @fig:basic-subgraph.

		#figure(
			render("digraph {rankdir=LR; a->b; a->c;}"),
			caption: [One possible subgraph of the graph in @fig:basic-digraph.]
		) <basic-subgraph>
		// - One may traverse a graph by picking a particular start node, and then traveling along one of its edges to another node.
		// - A traversal that only traverses one single edge is refereed to as a single-hop traversal.
    One can traverse a graph by selecting a specific starting node and then moving along one of its edges to reach another connected node. 
    When this traversal involves only a single edge, it is referred to as a single-hop traversal.
		
		// - Graphs can be Directed or Undirected, when Undirected the order of endpoints in an edge becomes irrelevant and it is possible to traverse from either endpoint to the other.
		// - In a Directed Graph edges become ordered pairs and the edges $(V_1, V_2)$ and $(V_2, V_1)$ each become two distinct edges with the left endpoint representing where a traversal can begin, and the right representing where it can end.
		// - Starting nodes (those on the left of an edge) in a directed graph are refereed to as predecessors of every paired endpoint in all of their edges.
		// - Likewise ending nodes (those on the right of an edge) are refereed to as successors of all their paired endpoints.
		// - For instance the nodes `b` and `c` in @fig:basic-digraph are successors of node `a`, which then means node `a` is their predecessor. Likewise `b` and `c` are predecessors to node d.
  Graphs can be classified as either directed or undirected. 
  In an undirected graph, the order of the endpoints in an edge is irrelevant, meaning it is possible to traverse from either endpoint to the other without restriction. 
  In contrast, a directed graph features edges as ordered pairs. In this case, the edges $(V_1, V_2)$ and $(V_2, V_1)$ are treated as two distinct edges, where the left endpoint indicates the starting point of a traversal and the right endpoint indicates its destination.

  In a directed graph, starting nodes—those that appear on the left side of an edge—are referred to as *predecessors* of the nodes they connect to. 
  Conversely, ending nodes—those on the right side of an edge—are known as *successors* of the nodes from which they are reached. 
  For example, in @fig:basic-digraph, nodes `b` and `c` are successors of node `a`, making `a` their predecessor. Similarly, nodes `b` and `c` serve as predecessors to node `d`.

		// - A path represents a sequence of single-hop traversals, for instance in @fig:basic-digraph the path represented by the edges `(a, b), (b, d), (d, e), (e, a)` is sequence of valid single hop traversals. 
		// - A path is only valid if all of its edges exist and, in a directed graph, paths always have to flow from predecessor nodes to successor nodes.
		// - Paths are often represented simply by listing the nodes passed through, with this scheme the previous path would be written as `(a, b, d, e, a)`.
		// - This particular type of path where the first and last nodes are the same is called a cycle.
  A path represents a sequence of single-hop traversals. For example, in @fig:basic-digraph, the path represented by the edges $(a, b)$, $(b, d)$, $(d, e)$, and $(e, a)$ is a sequence of valid single-hop traversals. 
  A path is only considered valid if all of its edges exist, and in a directed graph, the path must flow from predecessor nodes to successor nodes.
  Paths are often represented by simply listing the nodes they pass through. 
  Using this notation, the previous path would be written as $(a, b, d, e, a)$. 
 

		#figure(
        placement: top,
			render("digraph {rankdir=LR; f->g->i; f->h; i->j; a->b->d; a->c->d; d->e;}"),
			caption: [A directed acyclic graph (top) and a tree (bottom).]
		) <dag-and-tree>
  // 	- If a graph happens to contain no cycles it is refereed to as an acyclic graph, an example is show on the top of @fig:dag-and-tree.
		// - If an acyclic graph happens to contain no nodes with more than one predecessor it is instead refereed to as a tree, again an example is presented in @fig:dag-and-tree.
     When the first and last nodes of a path are the same, this particular type of path is called a cycle.
     If a graph contains no cycles, it is referred to as an acyclic graph. 
     An example of such a graph is shown at the top of @fig:dag-and-tree. 
     Furthermore, if an acyclic graph contains no nodes with more than one predecessor, it is referred to as a tree. 
     An example is also presented in @fig:dag-and-tree.
	

		// - According to Johnson~@johnson2004 DAGs and Trees have a well defined starting point (nodes a and f in @fig:dag-and-tree) these nodes are called roots
		// - A node `a` dominates another node `b` if every path from the root node to `b` passes through node `a`
		// - However this definition allows a node to dominate itself, if a node dominates another node ($a != b$) then `a` strictly dominates `b`
		// - Addtionally a node (`d` in @fig:dag-and-tree) immediately dominates another node (`e` in @fig:dag-and-tree) if there doesn't exist another node `r` such that `d` strictly dominates `r` and `r` strictly dominates `e`, in other words there is no node sitting between them
    According to Johnson~@johnson2004, Directed Acyclic Graphs and trees have a well-defined starting point, called the root node (such as nodes `a` and `f` in @fig:dag-and-tree). 
    A node `a` is said to dominate another node `b` if every path from the root node to `b` passes through `a`. 
    By this definition, a node dominates itself; however, if a node `a` dominates another node `b` where `a` is not equal to `b`, then `a` is said to strictly dominate `b`. 
    Additionally, a node `d` immediately dominates another node `e` (as shown in @fig:dag-and-tree) if there is no intermediate node `r` such that `d` strictly dominates `r` and `r` strictly dominates `e` — in other words, there is no node positioned between `d` and `e` in the dominance hierarchy.

		// TODO: Should I talk about how they are stored?

==== Abstract Syntax Tree/Parse Tree <2:sect:ast>
	// Basic Parsing Concepts
	// - To understand a parse tree, one must first understand a few basic concepts in parsing~@dragonbook.
	// - Parsing is usually split into two steps, a lexical analysis phase and a syntactic analysis phase.
	// - During the first an input string is segmented into "words" or more precisely the language's smallest meaningful units referred to as Tokens.
	// - For instance the string "-A + B" might be broken into the Tokens "-", "A", "+", and "B".
	// - This list of Tokens is then passed to the second syntactic analysis step where this flat list of Tokens is given structure.
	// - This structure can be represented using a Pase Tree or an Abstract Syntax Tree
  To understand a parse tree, one must first grasp a few basic concepts in parsing~@dragonbook. 
  Parsing is generally divided into two main phases: lexical analysis and syntactic analysis. 
  In the lexical analysis phase, an input string is segmented into its smallest meaningful units, known as tokens. 
  For example, the string "-A + B" would be broken down into the tokens "-", "A", "+", and "B". 
  These tokens are then passed on to the syntactic analysis phase, where this flat list is organized into a structured form. 
  This structure is typically represented by either a parse tree or an abstract syntax tree.

	// Why was it developed?
	// - Parse Trees represent the structure of a parse, and can be thought of as a record of grammar productions that were traversed while parsing.
	// - Many nodes in a Parse Tree (for instance a semicolon at the end of a statement in a C like language) are irrelevant to the meaning of a parse.
	// - Abstract Syntax Trees are a reduced subset of the Parse Tree with all of these irrelevant nodes removed, they can be constructed either by skipping "irrelevant" productions or by removing those nodes from an existing Parse Tree.
	// - @fig:parse-and-ast shows an example of a Parse Tree and two ASTs.
 Parse trees represent the structure of a parse and can be understood as a record of the grammar productions traversed during parsing. 
 However, many nodes in a parse tree (for example, a semicolon at the end of a statement in a C-like language) are irrelevant to the actual meaning of the parse. 
 Abstract Syntax Trees (ASTs) address this by being a reduced subset of the parse tree, with all such irrelevant nodes removed.
 ASTs can be constructed either by skipping these irrelevant productions during parsing or by pruning them from an existing parse tree. 
 @fig:parse-and-ast illustrates an example of a parse tree alongside two corresponding ASTs.
	#figure(
    placement: top,
			raw-render(```
			digraph {
				subgraph cluster_ParseTree {
					style=dashed
           Pstatement -> Pplus -> Pminus -> PminusOp
					Pminus -> PaIdent -> Pa
					Pplus -> Pws1
					Pplus -> PplusOp
					Pplus -> Pws2
					Pplus -> PbIdent -> Pb
					Pplus -> Psemi
           Pstatement [label="Statement Production", shape=box]
					Pplus [label="Binary Addition Production", shape=box]
					PplusOp [label="`+`"]
					Pminus [label="Unary Negation Production", shape=box]
					PminusOp [label="`-`"]
					Pa [label="`A`"]
					PaIdent [label="Identifier Production", shape=box]
					Pb [label="`B`"]
					PbIdent [label="Identifier Production", shape=box]
					Pws1 [label="Whitespace"]
					Pws2 [label="Whitespace"]
					Psemi [label="`;`"]
			}

			subgraph cluster_AST1 {
					style=dashed
					A1stmt -> A1plus -> A1minus -> A1a
					A1plus -> A1b
					A1stmt [label="Statement"]
					A1plus [label="Add"]
					A1minus [label="Negate"]
					A1a [label="Ident: A"]
					A1b [label="Ident: B"]
			}

			subgraph cluster_AST2 {
					style=dashed
					A2stmt -> A2minus -> A2plus -> A2a
					A2plus -> A2b
					A2stmt [label="Statement"]
					A2minus [label="Negate"]
					A2plus [label="Add"]
					A2a [label="Ident: A"]
					A2b [label="Ident: B"]
			}
		}
			```, width: 100%),
			caption: [
      A potential parse tree (left), an abstract syntax tree (AST) (center), and a mathematically incorrect AST (right)—resulting from an improper application of operator precedence—are shown for the expression "$-A + B;$" in a hypothetical C-like language. 
      Notice that the parse tree includes more irrelevant details and often fails to convey the meaning of specific nodes. 
      In contrast, AST nodes tend to carry more semantic information while eliminating unnecessary elements. 
      The label "Ident" is a shortened form of "Identifier."
     ]
		) <parse-and-ast>
	// - These two closely related representations are the simplest intermediate representation currently devised.
	// - Many simple systems which don't bother with more complex intermediate representations still utilize one of these trees.
	// - Additionally any parsing system more complicated than a regular expression will utilize one of these trees (at least implicitly).
 These two closely related representations are among the simplest intermediate representations currently in use. 
 Many straightforward systems that do not employ more complex intermediate forms still rely on one of these trees. 
 Furthermore, any parsing system more advanced than regular expressions will use one of these tree structures, at least implicitly.
	// What does it look like/formal definition?
	// - In general, an AST can be described as follows:
	// 	- Each node in the tree represents an operator or a programming construct.
	// 	- The children of each node represent the operands of the operator or the components of the programming construct.
	// 	- The structure of the tree reflects the hierarchical organization of the expression being represented.
	// 	- For instance the disambiguateing forms of the expression $-A + B$: $(-A) + B$ and $-(A + B)$ would get encoded into two separate trees as shown on the right of @fig:parse-and-ast.
 In general, an AST can be described as a tree structure where each node represents an operator or a programming construct. 
 The children of each node correspond to the operands of that operator or the components of the programming construct. 
 This hierarchical organization of nodes reflects the structure of the expression being represented. 
 For example, the two different interpretations of the expression $-A + B$ (namely $(-A) + B$ and $-(A + B)$) are encoded as two distinct trees, as illustrated on the right side of @fig:parse-and-ast.
	// How is it constructed?
 
	// Limitations?
	// - One limitation of Parse Trees is that a grammar can have more than one Parse Tree corresponding to a given string of terminals. 
	// - This means that there might be multiple ways to construct a parse tree for a particular input string, which can make it challenging to determine the correct parse tree.
	// - Common subexpressions like those found in: $(a + b) * -(a + b)$ wind up being explicitly processed separately. Potentially wasting space in memory and execution time (either in the running program or in future optimization steps to remove the redundancy).
	// Used for:
 One limitation of parse trees is that a single grammar can produce more than one parse tree for the same string of tokens. 
 This means there may be multiple possible parse trees for a given input, making it challenging to determine which parse tree is the correct one. 
 Additionally, common subexpressions—such as those found in the expression `(a + b) * -(a + b)`—are often processed separately in parse trees. 
 This can lead to redundant work, potentially wasting memory and execution time either during program runtime or in later optimization stages aimed at eliminating such redundancy.

// TODO: Is GIMPLE an example of an AST or an example of a LISP?
 // - GCC GIMPLE #link("https://ftp.cygwin.com/pub/gcc/summit/2003/GENERIC%20and%20GIMPLE.pdf")
 //  - The GCC family of compilers use GENERIC and GIMPLE as a common intermediate representation.
	// - GENERIC represents a function as a tree. As the name suggests, this conversion is independent of any language. 
	// - GIMPLE is a subset of GENERIC that is used for optimization. 
	// - A front-end can use the language-dependent tree codes in its GENERIC tree representation if it is able t provide a hook to convert it to GIMPLE form. 
	// - The parse tree structure is retained in GIMPLE. 
	// - The expressions are converted to three-address form where intermediate values are stored as temporary variables. 
	// - "Gimplifier" is the compiler pass that converts GENERIC to GIMPLE. 
	// - Complex statements are replaced by sequence of simple statements recursively by gimplifier.
	// Used for:
	// //     Polyhedral Optimization: #link("https://www.researchgate.net/profile/Jan-Hubicka-2/publication/255615364_Interprocedural_optimization_on_function_local_SSA_form_in_GCC/links/5a85b0ab458515b8af88c576/Interprocedural-optimization-on-function-local-SSA-form-in-GCC.pdf#page=185")

The GCC~@gcc family of compilers employs a two-level IR system consisting of *GENERIC* and *GIMPLE*, both of which are similar to an AST~@gimple.

GENERIC represents functions as abstract syntax trees in a language-independent manner. This means that code from any supported language is first translated into a standardized tree form, allowing the compiler to process it uniformly regardless of its source language.

GIMPLE is a simplified subset of GENERIC, explicitly designed for optimization. It retains the structure of the original parse tree but transforms complex expressions into a normalized three-address code form. In this form, intermediate values are assigned to temporary variables, making the code easier for optimization passes to analyze and manipulate.

Compiler front-ends may still use language-specific constructs in their GENERIC representations, provided they implement hooks to convert those constructs into GIMPLE. The transformation from GENERIC to GIMPLE is handled by a dedicated compiler pass known as the gimplifier. This pass recursively breaks down complex statements into sequences of simpler ones, preparing the IR for subsequent optimizations.

GIMPLE plays a foundational role in enabling advanced optimizations within GCC, including polyhedral optimization and interprocedural analyses on function-local SSA (Static Single Assignment) form. One example of such usage is detailed in Jan Hubička’s work on interprocedural optimization in GCC~@gcc.
 
==== Directed Acyclic Graphs <2:sect:dag>
	// // Why was it developed?
	// - Directed Acylic Graphs help solve this common subexpression problem~@cooper2022. 
	// - For expressions without assignment or other forms of state manipulation, textually identical expressions must produce identical values. 
	// - Thus nodes for duplicated textually identical expressions can be collapsed.
	// #figure(
	// 		raw-render(```
	// 		digraph {
	// 			subgraph cluster_AST {
	// 				style=dashed
	// 				Atimes -> Aplus1
	// 				Atimes -> Anegate
	// 				subgraph cluster_1 {
	// 						style=invis
	// 						Aplus1 -> Aa1
	// 						Aplus1 -> Ab0
	// 				}
	// 				subgraph cluster_2 {
	// 						style=invis
	// 						Anegate -> Aplus2 -> Aa2
	// 						Aplus2 -> Ab1
	// 				}
	// 				Atimes [label="Multiply"]
	// 				Anegate [label="Negate"]
	// 				Aplus1 [label="Add"]
	// 				Aplus2 [label="Add"]
	// 				Aa1 [label="Ident: A"]
	// 				Aa2 [label="Ident: A"]
	// 				Ab0 [label="Ident: B"]
	// 				Ab1 [label="Ident: B"]
	// 			}

	// 			subgraph cluster_DAG {
	// 				style=dashed
	// 				Dtimes -> Dplus
	// 				Dtimes -> Dnegate
	// 				subgraph cluster_3 {
	// 						style=invis
	// 						Dplus-> Da
	// 						Dplus -> Db
	// 						Dnegate -> Dplus
	// 				}
	// 				Dtimes [label="Multiply"]
	// 				Dnegate [label="Negate"]
	// 				Dplus [label="Add"]
	// 				Da [label="Ident: A"]
	// 				Db [label="Ident: B"]
	// 			}                 
	// 		}
	// 		```, width: 100%),
	// 		caption: [A potential AST (left) and DAG (right) for the expression "$(A + B) * -(A + B)$" in a hypothetical C-like language. Notice how the nodes for "A + B" only appear once in the DAG whilst appearing twice in the AST.]
	// 	) <dag-and-ast>
	// // What does it look like/formal definition?
	// - Internally they are very similar to an AST... however equivalent subgraphs are collapsed to a single copy as can be see in @fig:dag-and-ast.
	// -  If the value of A and B does not change between the uses of A + B, then the compiler can generate code that evaluates the subgraph once and uses the result twice.
	// // How is it constructed?
	// - DAG's can be constructed by using the same techniques that construct ASTs.
	// - The difference being that when a new node is "added to the graph", instead of immediately creating it and adding it, instead a search is performed for a similar node and if one is found it is returned instead. 
	// // Limitations?
	// - Care must be taken when constructing a DAG to ensure that the values of variables in collapsed subgraphs must not change between their uses.
	// Used for:
	// 	- A DAG is used as the IR in the lcc compiler. lcc generates only the necessary fragments of the DAG as it parses the program, processes them, then deletes them before continuing. #link("https://dl.acm.org/doi/abs/10.1145/122616.122621") #link("https://dl.acm.org/doi/abs/10.5555/555424")
	// 	- Exposing/removing redundant code #link("Engineering a Compiler") 
  Directed Acyclic Graphs (DAGs) were developed as a solution to the problem of identifying and eliminating common subexpressions in programs~@cooper2022. 
  In expressions where there is no assignment or other state-manipulating operation, any textually identical subexpressions are guaranteed to yield the same result (at least in many older languages). 
  This property allows a compiler to collapse such duplicate subexpressions into a single node in the graph, thereby avoiding redundant computation.

  This transformation can be illustrated through the contrast between an AST and a DAG. 
  In an AST, the subexpression (A + B) is represented multiple times if it appears more than once in the source code. 
  However, in a DAG, such repeated subexpressions are represented by a single node, as shown in @fig:dag-and-ast. 
  The figure presents both an AST and a corresponding DAG for the expression $(A + B) * -(A + B)$. 
  In the AST (left), the expression $A + B$ appears twice, while in the DAG (right), it appears only once. 
  This consolidation enables the compiler to evaluate the subexpression a single time and reuse the result, provided the values of A and B do not change between uses.

  	#figure(
      placement: top,
			raw-render(```
			digraph {
				subgraph cluster_AST {
					style=dashed
					Atimes -> Aplus1
					Atimes -> Anegate
					subgraph cluster_1 {
							style=invis
							Aplus1 -> Aa1
							Aplus1 -> Ab0
					}
					subgraph cluster_2 {
							style=invis
							Anegate -> Aplus2 -> Aa2
							Aplus2 -> Ab1
					}
					Atimes [label="Multiply"]
					Anegate [label="Negate"]
					Aplus1 [label="Add"]
					Aplus2 [label="Add"]
					Aa1 [label="Ident: A"]
					Aa2 [label="Ident: A"]
					Ab0 [label="Ident: B"]
					Ab1 [label="Ident: B"]
				}

				subgraph cluster_DAG {
					style=dashed
					Dtimes -> Dplus
					Dtimes -> Dnegate
					subgraph cluster_3 {
							style=invis
							Dplus-> Da
							Dplus -> Db
							Dnegate -> Dplus
					}
					Dtimes [label="Multiply"]
					Dnegate [label="Negate"]
					Dplus [label="Add"]
					Da [label="Ident: A"]
					Db [label="Ident: B"]
				}                 
			}
			```, width: 100%),
			caption: [A potential AST (left) and DAG (right) for the expression "$(A + B) * -(A + B)$" in a hypothetical C-like language. Notice how the nodes for "A + B" only appear once in the DAG, whilst appearing twice in the AST.]
		) <dag-and-ast>
  
  Formally, DAGs are structurally similar to ASTs, but they differ in that they collapse equivalent subgraphs into a single representative node. 
  This transformation preserves semantic correctness under the assumption of referential transparency—i.e., that the values involved in the subexpression are not modified between evaluations.
  
  DAGs are typically constructed using the same parsing techniques employed for building ASTs. 
  However, during DAG construction, each time a new node is to be added, the compiler first searches the existing graph for an equivalent node. 
  If a match is found, that existing node is reused rather than creating a new one. 
  This process ensures that identical subexpressions are not redundantly represented.
  
  Despite their utility, DAGs have limitations. 
  Care must be taken to ensure that the variables involved in collapsed subgraphs remain unchanged between uses. 
  If the value of a variable changes, say in another thread, collapsing expressions that reference it could result in incorrect behavior.
  
  DAGs find practical application in several compilers. 
  For instance, the _lcc_ compiler~@fraser1991 uses a DAG-based intermediate representation. 
  Rather than constructing the entire DAG upfront, _lcc_ incrementally generates only the required fragments during parsing, processes them, and then discards them before continuing with the rest of the program~@fraser1995. 
  Additionally, DAGs are instrumental in detecting and removing redundant computations, making them a valuable tool in optimizing compilers~@cooper2022.



==== Control Flow Graph <2:sect:cfg> //#link("https://dl.acm.org/doi/abs/10.1145/390013.808479") #link("https://dl.acm.org/doi/abs/10.1145/800028.808480")
		// Year: 1970
		// Citations: 1418
		// Why was it developed?
	// - The main purpose of control flow graphs is to facilitate determining what the flow relationships are and answering questions like: "Is this an inner loop?", "If an expression is removed from the loop where can it be correctly and profitably placed?", or "Which variable definitions can affect this use?" #link("https://dl.acm.org/doi/abs/10.1145/390013.808479")
	// - Control flow graphs were developed to provide a visual representation of the program's control flow, allowing for easier analysis and understanding of the program's behavior.
	// // What does it look like/formal definition?
	// // How is it constructed?
	// - First Basic Blocks need to be identified.
	// - #link("Dragon Book") defines a Basic Block as a sequence of instructions that have a single entry point and no branches anywhere within it (except for the very end).
	// - They identify basic blocks by first identifying the "leaders" in the code. 
	// 		- Leaders are instructions that come under any of the following 3 categories:
	// 				- It is the first instruction in the program.
	// 				- It is the target of a conditional or an unconditional jump instruction or an exception handling instruction. #link("https://link.springer.com/chapter/10.1007/978-3-642-33826-7_3")
	// 				- It is an instruction that immediately follows a conditional or an unconditional jump instruction or an exception throwing instruction.
	// 		- Thus the statements on lines 2, 4, 5, 7, 8, 10, 12, and 15 of @fig:cfg-code are leaders.
	// 		- Starting from a leader, the set of all following instructions until and not including the next leader is the basic block corresponding to the starting leader.
	// - Once identified Basic Block are then treated as nodes in the control flow graph
	// - Edges are added to represent the control flow between basic blocks. There are three types of edges:
	// 	- Edge from a node to itself: This represents a loop, where the program jumps back to the same block.
	// 	- Edge from one node to another: This represents a jump or branch instruction that transfers control to another block.
	// 	- Edge from a node to an exit node: This represents the end of the program, and all paths converge to this exit node.
	// 		#figure(
	// 			raw-render(```
	// 			digraph {
	// 				rankdir=LR;
	// 				start -> b0 -> b1 -> b2 -> b1
	// 					b1 -> b3 -> b4 -> b6 -> Exit
	// 					b3-> b5 -> b7 -> Exit

	// 					start [style=invis]
	// 					b0 [shape=box,label="b0: a = b + c; x = 0;"]
	// 					b1 [shape=box,label="b1: if(x < a) goto b2; else goto b3;"]
	// 					b2 [shape=box,label="b2: x = a * d; goto b1;"]
	// 					b3 [shape=box,label="b2: if(x == y) goto b4; else goto b5;"]
	// 					b4 [shape=box,label="b4: z = e; goto b6;"]
	// 					b5 [shape=box,label="b5: throw exception();"]
	// 					b6 [shape=box,label="b6: y = z + 1; return y;"]
	// 					b7 [shape=box,label="b7 (exception_handler): return 0;"]          
	// 			}```, width: 100%),
	// 			caption: [A Control Flow Graph derived from the code in @fig:cfg-code. Notice that this graph is not minimal, the Basic Blocks labeled "b4" and "b6" could potentially be combined with further optimization; similarly for the Basic Blocks labeled "b5" and "b7". Also notice that the optimizations necessary for these combinations (moving lines 12 and 13 (b6) inside the if on line 7, and removing the exception handling mechanism) are not always valid in a general sense. For instance Basic Block "b6" would have to remain separate if the the else branch simply assigned a value to "z" rather than throwing an exception.]
	// 		) <cfg>
	// 	- Once finished these nodes and edges form a complete control flow graph, an example derived from the code in @fig:cfg-code is depicted in @fig:cfg.
	// // Limitations?
	// - Data Dependence Analysis: A CFG only captures control flow dependencies and does not consider data dependences between statements. This can lead to incorrect results if there are data dependences between statements that are not captured by the graph.
	// - Scalability: As programs become larger and more complex, constructing a CFG can be computationally expensive and may not be feasible for very large programs.
	// - Irrelevant Information: A CFG contains information about both relevant and irrelevant dependencies. For example, if two statements do not depend on each other but are executed in the same loop, they will still be connected by an edge in the graph.
	// - Lack of Context: A CFG does not provide any context about the program's semantics or behavior. It only shows the possible execution paths and dependencies between statements.
	// Used for:
	// 	- Constructing SSA form
	// 	// What else?
 

  The primary purpose of Control Flow Graphs (CFGs) is to facilitate the analysis of a program's execution flow by explicitly representing flow relationships between different parts of the code. 
  They help answer important questions such as: "Is this an inner loop?", "If an expression is removed from a loop, where can it be correctly and profitably placed?", or "Which variable definitions can affect this use?"~@allen1970.
  Control flow graphs were developed to provide a visual and structural representation of the program's control flow, enabling easier analysis and understanding of the program's runtime behavior.
  
  To construct a CFG, one begins by identifying Basic Blocks: the foundational units of the graph. 
  The Dragon Book~@dragonbook defines a basic block as a sequence of instructions with a single entry point and no branching, except at the end. 
  Identifying basic blocks begins with identifying leaders: special instructions that mark the beginning of a new block.
  Leaders are instructions that meet one of the following criteria:
  
  - They are the first instruction of the program.
  - They are the target of a conditional or unconditional jump, or an exception-handling instruction~@amighi2012.
  - They immediately follow a conditional or unconditional jump or an exception throw.
  
  For example, in the code snippet enumerated in @lst:cfg-code, the statements on lines 2, 4, 5, 7, 8, 10, 12, and 15 are leaders. A basic block consists of a leader and all subsequent instructions up to, but not including, the next leader.
  
  		#figure(code_block(numbers: true, width: 35%)[```cpp
try {
	a = b + c;
	x = 0;
	while(x < a)
		x = a * d;
		
	if(x == y)
		z = e;
	else 
		throw exception();
		
	y = z + 1;
	return y;
} catch(exception) {
	return 0;
}```],
		caption: [Some example code written in a hypothetical C(++)-like language containing a while loop, if statement, and throw-try-catch trifecta. Assume all variables are integers that have been previously defined.],
    kind: raw
	) <cfg-code>
  
  Once the basic blocks have been identified, each block becomes a node in the control flow graph. 
  Edges are then added to represent possible transitions between blocks. There are typically three types of edges:
  
  1. An edge from a node to itself, representing loops where the program control returns to the same block.
  2. An edge from one node to another, representing conditional or unconditional jumps.
  3. An edge from a node to an exit node, indicating the end of execution paths.
  
  A visual example of a full CFG constructed from the code in @lst:cfg-code is shown in @fig:cfg.
  
#figure(
				raw-render(```
				digraph {
					// rankdir=LR;
					start -> b0 -> b1 -> b2 -> b1
						b1 -> b3 -> b4 -> b6 -> Exit
						b3-> b5 -> b7 -> Exit

						start [style=invis]
              
						b0 [shape=box,label="b0: a = b + c; x = 0;"]
						b1 [shape=box,label="b1: if(x < a) goto b2; else goto b3;"]
						b2 [shape=box,label="b2: x = a * d; goto b1;"]
						b3 [shape=box,label="b2: if(x == y) goto b4; else goto b5;"]
						b4 [shape=box,label="b4: z = e; goto b6;"]
						b5 [shape=box,label="b5: throw exception();"]
						b6 [shape=box,label="b6: y = z + 1; return y;"]
						b7 [shape=box,label="b7 (exception_handler): return 0;"]          
				}```, width: 50%),
				caption: [The Control Flow Graph, which is derived from the code shown in @lst:cfg-code, is not minimal. Certain Basic Blocks—specifically those labeled "b4" and "b6"—could potentially be merged through further optimization; the same applies to Basic Blocks "b5" and "b7". However, the optimizations required to enable these combinations are not universally applicable. For example, merging "b6" with another block would require moving lines 12 and 13 inside the conditional statement on line 7 and eliminating the exception handling mechanism. These changes are not always valid. In particular, if the else branch assigned a value to the variable "z" instead of throwing an exception, Basic Block "b6" would need to remain separate.],
      placement: top
			) <cfg>
  
  // Once the nodes (basic blocks) and edges (control transitions) are assembled, the resulting structure constitutes the complete control flow graph for the program.
  
  Despite their usefulness, CFGs have several limitations. 
  One major drawback is their ignorance of data dependencies. 
  While CFGs effectively capture control dependencies, they do not represent data dependencies. 
  This can lead to incorrect results—particularly when one statement depends on the result of another that is not directly connected in the graph.

  Another limitation is scalability. 
  Constructing CFGs for large or complex programs can be computationally expensive, and as program size grows, these graphs may become unwieldy and difficult to manage effectively.
  
  CFGs also tend to be overinclusive. They often represent both relevant and irrelevant dependencies. 
  For instance, statements located within the same loop may appear connected in the graph even if they do not depend on each other in practice.
  On the flip side, CFGs lack semantic context. 
  While they show the paths that control might follow during execution, they do not capture the actual meaning or runtime behavior of the code.
  
  Despite these limitations, CFGs are practically valuable in specific contexts. One prominent example is in the construction of Static Single Assignment form (see~@2:sect:ssa).
  In this setting, CFGs help in placing $phi$-functions correctly and enable efficient analysis of definition-use chains.

==== Dataflow Graph <2:sect:dfg> //#link("https://www.cs.ucf.edu/courses/cop4020/sum2010/Lecture10.pdf")
	// Year: 1980
	// Citations: 1184 + 1013
	// Why was it developed?
	// - Dataflow Graphs were developed to help extract more performance from "supercomputers" with more than one processor, otherwise known as a modern consumer grade CPU.
	// - Dataflow is designed to more easily support concurrency.
	// - Today Dataflow graphs are used as the foundation for Machine Learning runtimes, at least all of them capable of interfacing with ONNX standard~#link("https://onnx.ai/about.html"), in order to achieve high concurency.
	// // What does it look like/formal definition?
	// - Dataflow Graphs are very similar in structure to the previously mentioned DAGs.
	// - The primary difference is in interpretation, in a DFG we add "tokens" to the edges of a DAG.
	// - These tokens carry values and once an operation has a token at each of its inputs it can produce a corresponding token at its output.
	// - This trickling of tokens through the network is analogous to the trickling of voltages through an electric circuit or water through a plumbing system.
	// - In implementations #link("https://link.springer.com/chapter/10.1007/3-540-06859-7_145") propose an alternative structure they call Activity Templates for the nodes in a DFG.
	// - In this structure a node becomes a tuple storing an operation code and array of outputs.
	// - Each output is represented by a tuple storing the address of another Activity Template and an input index the output should be wired to.
	// // How is it constructed?
	// - The literature is full of examples of special languages designed specifically to support Dataflow Graphs #link("http://csg.csail.mit.edu/pubs/memos/Memo-181/Memo-181.pdf") #link("https://link.springer.com/chapter/10.1007/3-540-06859-7_145")
	// - The current authors fail to see why a technique similar to that used to construct a DAG could not be used, assuming the source language has a few specific constraints.
	// // Limitations?
	// - Global variables and unstructured control flow (eg. goto, switch) do not map to this system and need to be removed.
	// #figure(
	// 	raw-render(```
	// 		digraph {
	// 			subgraph {
	// 				start -> merge:F [label="X"]
	// 				three -> subtract -> merge:T
	// 				merge -> subtract [style=invis]
	// 				merge:M -> split1 [weight=10,arrowhead=none]
	// 				split1 -> switch:M [weight=10]
	// 				switch -> fake [style=invis, weight=10]
	// 				switch:F -> exit [label="X"]
	// 				switch:T -> subtract 
	// 				split1 -> greater
	// 				greater -> split2 [arrowhead=none]
	// 				split2 -> switch:C
	// 				split2 -> merge:C [label="Initial: false"]

	// 				start [style="invis"]
	// 				exit [style="invis"]
	// 				fake [style="invis",label=""]
	// 				split1 [shape=point,label=""]
	// 				split2 [shape=point,label=""]
	// 				merge [label="<T> True |<M> Merge |<F> False |<C> Control", shape=record]
	// 				switch [label="<T> True |<M> Switch |<F> False|<C> Control", shape=record]
	// 				greater [label="> 0?"]
	// 				subtract [label="Top - Bot"]
	// 				three [label="3"]

	// 				{rank=same; subtract; split1; greater; split2}
	// 			}        
	// 		}
	// 	```, width: 100%),
	// 	caption: [A Dataflow Graph for the expression ``while(X $>$ 0) X -= 3". Two special types of nodes are required for control flow: Merge nodes which forwards the token on one of their inputs depending on if a control parameter is true or false, and switch nodes which forwards its input token to one of its outputs depending on if its control parameter is true or false.]
	// ) <dfg>
	// - Other types of control flow are still possible, for instance Figure~\ref{fig:dfg} shows a Dataflow Graph for a while expression.
	// - However, since we are only dealing with values, the idea of a resultless statement disappears and every expression (include control flow) needs to result in a value.
	// - For these constraints to be removed some preprocessing to eliminate the offending structures would be necessary. #link("https://kuscholarworks.ku.edu/handle/1808/11547") #link("https://dl.acm.org/doi/abs/10.1145/3547621") #link("https://ieeexplore.ieee.org/abstract/document/288377")

  Dataflow Graphs (DFGs) were initially developed as a strategy to extract greater performance from "supercomputers" with multiple processors~@dennis1980—what we now consider standard, consumer-grade CPUs.
  The key design principle behind Dataflow is its ability to more naturally express concurrency, allowing multiple operations to proceed simultaneously without requiring explicit coordination by the programmer.

  In modern computing, DFGs are foundational to the execution models of many machine learning runtimes, especially those compatible with the ONNX standard~@onnx. These graphs help maximize concurrency during model execution, making them well-suited to the parallel processing requirements of modern ML workloads.
  
  Structurally, Dataflow Graphs closely resemble DAGs, but with a crucial difference in interpretation. 
  In a DFG, tokens—which represent values—are added to the edges of the graph. 
  An operation (node) can only execute once a token is present at each of its input edges. 
  Upon execution, the node produces a new token at each of its output edges. 
  This "trickling" of tokens through the graph is analogous to the way electricity flows through a circuit or water through a plumbing system.
  
  Some implementations of Dataflow Graphs refine the structure of nodes by using Activity Templates~@dennis1974. 
  In this representation, each node is a tuple consisting of an operation code and an array of outputs. 
  Each output is itself a tuple indicating the destination Activity Template and the index of the input to which the output should be wired.
  
  // Specialized programming languages have historically been developed to generate Dataflow Graphs~@dennis1974@brock1979. However, we can't come up with a reason it wouldn't be plausible to construct DFGs using methods similar to those used for DAGs, provided the source language adheres to certain constraints.

  Not all programming constructs translate cleanly into the Dataflow paradigm. 
  In particular, global variables and unstructured control flow (such as goto and switch statements) are incompatible and must be eliminated during preprocessing~@ramsey2022@erosa1994.
  
  Nonetheless, structured control flow can be supported using special node types. For example, @fig:dfg shows a Dataflow Graph for the expression "while (X > 0) X -= 3". This requires two additional constructs:

	#figure(
      placement: bottom,
		raw-render(```
			digraph {
				subgraph {
					start -> merge:F [label="X"]
					three -> subtract -> merge:T
					merge -> subtract [style=invis]
					merge:M -> split1 [weight=10,arrowhead=none]
					split1 -> switch:M [weight=10]
					switch -> fake [style=invis, weight=10]
					switch:F -> exit [label="X"]
					switch:T -> subtract 
					split1 -> greater
					greater -> split2 [arrowhead=none]
					split2 -> switch:C
					split2 -> merge:C [label="Initial: false"]

					start [style="invis"]
					exit [style="invis"]
					fake [style="invis",label=""]
					split1 [shape=point,label=""]
					split2 [shape=point,label=""]
					merge [label="<T> True |<M> Merge |<F> False |<C> Control", shape=record]
					switch [label="<T> True |<M> Switch |<F> False|<C> Control", shape=record]
					greater [label="> 0?"]
					subtract [label="Top - Bot"]
					three [label="3"]

					{rank=same; subtract; split1; greater; split2}
				}        
			}
		```, width: 50%),
		caption: [A Dataflow Graph for the expression ``while(X $>$ 0) X -= 3". Two special types of nodes are required for control flow: Merge nodes, which forward the token along from one of their inputs depending on whether a control parameter is true or false, and switch nodes, which forward their input token to one of their outputs depending on whether their control parameter is true or false.]
	) <dfg>
  
  - Merge nodes, which forward a token from one of their inputs based on a control condition.
  - Switch nodes, which direct an input token to one of multiple outputs depending on a control value.
  
  One consequence of the Dataflow model is that every part of a program—including control flow—must be expressible as a value-producing expression. 
  As a result, statements that do not yield values must either be transformed or eliminated, often requiring pre-compilation or rewriting of the source program.

 // - Implementations of Dataflow:
 //  - Value Dependence Graph #link("https://dl.acm.org/doi/abs/10.1145/174675.177907")
	// // Just Dataflow?
	// // Year: 1994
	// // Citations: 194
	// // Why was it developed?
 //    - VDGs were created to overcome the limitations of traditional dependence analysis techniques when dealing with complex, data-dependent programs, enabling more effective parallelization and optimization. 
 //    - They provide a more accurate and flexible representation of data dependencies, leading to improved program performance.
	// // How does it differ from dataflow?
 //    - VDGs are similar to dataflow graphs with the distinction of being a bipartite graph where every edge connects to node (primitive operations, $gamma$-node (if statements), function calls,and $lambda$-nodes (closures)) and a port (value).
 //    - They are an extension of the IR utilized by the Fuse partial evaluator #link("https://link.springer.com/chapter/10.1007/3540543961_9") extended to support some additional imperative concepts like store and load nodes to update variables.
 //    - Due to the functional basis of this IR loops are converted to tail recursive function calls
	// // How is it constructed?
 //    - They are constructed by starting with a CFG (See Section /*@2:sect:cfg*/) which they then replace the control flow edges of with $gamma$ and $lambda$ nodes, then the basic blocks are expanded into VDG nodes through a process they call Symbolic Execution.
	// // Limitations?
 //    - This representation does not elegantly handle loop and function termination dependencies
  ===== Value Dependence Graph <2:sect:VDG>
  One notable implementation of dataflow is the Value Dependence Graph (VDG)~@weise1994. 
  VDGs were developed to address the limitations of traditional dependence analysis techniques, particularly when analyzing complex, data-dependent programs. These traditional techniques often struggled to capture the nuances required for effective parallelization and optimization. In contrast, VDGs provide a more accurate and flexible representation of data dependencies, leading to improved program performance.

  Structurally, VDGs are similar to DFGs but introduce a key distinction: they are bipartite graphs, in which every edge connects a node (representing primitive operations, control structures like $gamma$-nodes for conditional branches, function calls, and $lambda$-nodes for closures) to a port (representing values). This bipartite design allows for more granular dependency tracking between computations and values. VDGs can be seen as an extension of the intermediate representation (IR) used by the Fuse partial evaluator~@weise1991, expanded to support imperative features such as store and load operations for variable updates. Notably, because of the IR’s functional roots, traditional loops are transformed into tail-recursive function calls.
  
  The construction of a VDG begins with a CFG (see~@2:sect:cfg),
  which is then transformed by replacing control flow edges with $gamma$- and $lambda$-nodes. The contents of each basic block are expanded into corresponding VDG nodes using a process referred to as symbolic execution.
  
  Despite their strengths, VDGs are not without limitations. In particular, they do not handle loop and function termination dependencies elegantly or comprehensively, which can affect their applicability in specific analyses or optimizations.
   // Implementations
      // - To remedy this 
      //  - VSDG #link("https://link.springer.com/chapter/10.1007/3-540-36579-6_1") #link("https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-607.html")
    			// Just a PDW?
    			// Year: 2004
    			// Citations: 39
    			// Why was it developed?
       //     - The Value State Dependence Graph (VSDG) was developed to address some of the limitations and issues present in other program graph representations, specifically the Value Dependence Graph (VDG). 
       //     - Specifically, the VDG has problems with preserving the terminating properties of a program and generating target code from the graph; the process of converting the VDG into a demand-based Program Dependence Graph (dPDG) and then to a traditional control flow graph (CFG) before generating target code can be complex.
    			// // What does it look like/formal definition?
       //     - The VSDG is a form of VDG extended by the addition of state-dependence edges to model sequential computation
       //     - state-dependency edges can be added incrementally until the VSDG corresponds to a unique CFG
    			// // How is it constructed?
    			// // Limitations?
	      //   Used for:      
       //        - #link("https://sussex.figshare.com/articles/thesis/Removing_and_restoring_control_flow_with_the_Value_State_Dependence_Graph/23317190") constructs the VSDG after performing an interval analysis technique called structural analysis #link("https://www.sciencedirect.com/science/article/abs/pii/0096055180900077"), which allows irreducible control flow to be transformed into reducible control flow.
       //        - Register allocation and code motion simultaniously #link("https://link.springer.com/chapter/10.1007/3-540-36579-6_1")
       //        - Conversion to PDG using functional like laze evaluation #link("https://arxiv.org/abs/1912.05036")
       //        - Reducing code size (using multiple memory instructions) #link("https://link.springer.com/chapter/10.1007/978-3-540-24723-4_18")

    The Value State Dependence Graph (VSDG)~@johnson2003 was developed to address several limitations found in the VDG; One of the main being VDG's difficulty in preserving a program's terminating properties and in supporting target code generation. 
    The standard process—converting a VDG into a demand-based Program Dependence Graph (see~@2:sect:pdg),
    then into a traditional CFG, and finally generating code, which can be both complex and indirect.

    Formally, the VSDG can be understood as an extension of the VDG, augmented with state-dependence edges that explicitly model sequential computation. 
    These edges ensure that execution order is respected, making the graph suitable for representing imperative constructs. 
    Significantly, state-dependence edges can be added incrementally until the VSDG corresponds to a unique CFG, which helps in maintaining control flow integrity throughout compilation or analysis.
    
    The construction of the VSDG often begins with structural analysis~@sharir1980, a form of interval analysis that transforms irreducible control flow into reducible forms. 
    This transformation is essential because many compiler optimizations and code generation techniques work more effectively on reducible control flow~@stanier2023.
    
    VSDGs have a wide range of applications:
    One key use is in simultaneous register allocation and code motion~@johnson2003. 
    Additionally, VSDGs contribute to code size reduction, particularly by utilizing multiple memory instructions~@johnson2004multiple. Despite these strengths, VSDGs have some limitations, including the complexity involved in correctly constructing state-dependence edges and the challenges they pose for visualization and reasoning compared to more traditional representations like CFGs.
    
  ===== Program Expression Graph <2:sect:peg>
  // - Program Expression Graph #link("https://dl.acm.org/doi/abs/10.1145/1480881.1480915")
  //   - A Program Expression Graphs (PEGs) are a dataflow based representation of a program's expression-level structure, where nodes correspond to operations (like addition or subtraction) or data values (like variables or constants), and edges represent the flow of data between them. 
  //   - They are constructed by grouping parts of the CFG into PEG-like sub-CFGs based on $Phi$-nodes (branching conditions) and $theta$-nodes (loop conditions), and then recursively converting these sub-CFGs into PEGs. 
  //   - This construction process involves identifying equal conditions for branch fusion and loop fusion, which makes it easy to implement; a similar process is then performed in reverse to reconstruct a CFG once optimization has been performed.
    
  //   - An E-PEG, or Equality PEG, extends this model by grouping nodes into equivalence classes when they are proven equal. 
  //   - Unlike traditional PEGs, E-PEGs support equality-based reasoning through a system of trigger patterns and callbacks, managed by a saturation engine that monitors and applies optimizations dynamically. 
  //   - This enables the E-PEG to explore and represent multiple optimization paths simultaneously as a single "blob" of programs//, allowing 
  //   - This allows all optimizations to be applied to the "blob" and then the best program is extracted from the "blob" using some global heuristic; thus compilers to make more globally informed decisions, such as selectively inlining functions based on broader optimization effects. 
  //   Used for:
  //     - Translation validation #link("https://link.springer.com/chapter/10.1007/978-3-642-22110-1_59") #link("https://dl.acm.org/doi/abs/10.1145/1993498.1993533")

  A Program Expression Graph (PEG)~@tate2009 is a dataflow-based representation of a program's expression-level structure, where nodes correspond to operations, such as addition or subtraction, or data values like variables or constants, and edges represent the flow of data between these nodes. 
  PEGs are constructed by grouping parts of the CFG (see~@2:sect:cfg) into PEG-like sub-CFGs based on special nodes called $Phi$-nodes (which represent branching conditions) and $theta$-nodes (which represent loop conditions).
  These sub-CFGs are then recursively converted into PEGs; this construction process includes identifying equal conditions for branch fusion and loop fusion, making the approach straightforward to implement. 
  After optimization, a similar reverse process is used to reconstruct the CFG from the PEG.

  An extension of this model, called the Equality PEG (E-PEG), groups nodes into equivalence classes. 
  Unlike traditional PEGs, E-PEGs support equality-based reasoning through a system of trigger patterns and callbacks managed by a "saturation engine" that dynamically monitors and applies optimizations.
  This mechanism allows the E-PEG to simultaneously explore and represent multiple optimization paths as a single "blob" of programs. 
  All optimizations can be applied to this "blob," after which the best program is extracted using a global heuristic. 
  This approach enables compilers to make more globally informed decisions, such as selectively inlining functions based on broader optimization effects.

  PEGs and E-PEGs have been used for applications like translation validation~@stepp2011@tristan2011, providing formal assurance that program transformations preserve correctness.

==== Control Flow/Dataflow Hybrids

// - Control flow and Dataflow are both extremely useful when trying to apply optimizations to a program.
// - Thus the majority of Graphical IRs combine these two techniques together.
// - We already saw one IR in this category... the Value State Dependence Graph presented in @2:sect:VDG.
Control flow and dataflow analyses are both instrumental when applying optimizations to a program. Consequently, the majority of Graphical IRs combine these two techniques to leverage their combined strengths. 
One such IR that exemplifies this combination is the Value State Dependence Graph, as previously presented in @2:sect:VDG.

===== Program Dependence Graph <2:sect:pdg>//#link("https://dl.acm.org/doi/abs/10.1145/24039.24041")
	// Year: 1987
	// Citations: 3871
	// // Why was it developed?
	// - A PDG, combines both control flow and data dependencies into a single graph. 
	// - A PDG represents the dependencies between variables in a program, including both control flow and dataflow information. 
	// - The PDG was developed to create a program representation useful in an optimizing compiler for a vector or parallel machine. 
	// - Such a compiler must perform both conventional optimizations as well as new transformations for the detection of parallelism.
	// // What does it look like/formal definition?
	// - There are two types of control dependencies:
	// 		- Data Dependence: A dependence exists when the value of one statement depends on the value produced by another statement. 
	// 		- Control Dependence: A dependence exists between a statement and the predicate (a true or false value) whose value immediately controls the execution of the statement. For example, in the sequence $"if"(A) "then" B=C*D; "endif"$, the statement $B=C*D$ depends on the control flow graph.
	// - The original paper discusses several variations of the PDG.
	// - Nodes can represent statements and predicate expressions, or they can represent individual operators and operands. 
	// - They also discuss a more functional version which they describe as a Dataflow Graph with a few extra links.
	// // How is it constructed?
	// - Construction of a PDG begins with an existing Control Flow Graph
	// - For the data dependencies step, the original paper assumes that each basic block in the CFG is represented as a DAG
	// - The PDG is constructed by identifying common control dependence subsets, which are then factored out using region nodes. 
	// - Region nodes are created for common control dependence subsets that are factored out of the set of control dependencies for a particular node. 
	// - This is done by considering the set CD of control dependence predecessors of each non-region node that has other than a single unlabeled control dependence predecessor. 
	// - A region node R is created for CD, and each node in the graph whose set of control dependence predecessors is CD is made to have only the single control dependence predecessor R. 
	// - Finally, R replaces CD as the control dependency set for its successor nodes.
	// - #link("https://dl.acm.org/doi/10.1145/178243.178258") have adjusted this process to take linear time.
	
	// - Then all of the leaf nodes in DAGs representing each basic block are marked "merge" nodes.
	// - Every variable is assigned the value "undefined" at the beginning of the program.
	// - The set of assignments or initializations (often refereed to as Reaching Definitions) that can affect the value of a variable at a given location is determined for each variable 
	// - Edges are added between definitions and these merge nodes, thus making chains of usages to definitions explicit in the graph.
	// - While adding edges I/O operations are treated as operations on an implicit file object so that the sequencing of operations is correctly represented.
	// - Subscripted array accesses are represented by a select operator having two inputs, an array and an offset, and one output, the selected element.
	// - Subscripted array assignments are represented by an update operator having three inputs: an array, an offset, and a replacement value. The output of an update operator is a modified array.
	// 		- Thus a definition of an element of an array is considered a definition for the entire array 
	// - For loops becomes a single operator which has as operands the initial, final, and increment values. It has two outputs: one an index value stream and the other a predicate value stream.
	// - Additionally loop variables are affine mapped to run from 1 to N in steps of 1
	// // Limitations?
	// - The paper mentions that a PDG may take around 50\% more memory than linear representations discussed in the next section, however in the modern day this is more of an inconvenience than a limitation.
	// - Data dependence is most easily determined when there are no side-effects due to pointers, shared variables, or procedure calls with semantics other than pass by value.
	// - Aliasing (when two array-like structures reference overlapping memory) and side-effects present obvious problems in accurately representing dependences in the PDG. 
	// - To detect implicit aliasing induced by procedure parameter binding, interprocedural dataflow analysis must be performed, which is also used to detect side effects.
	// - Pointers in a language such as C can preclude PDG construction altogether since they can point to anything (although principled C programs may still be analyzed)
 
A Program Dependence Graph (PDG)~@ferrante1987 integrates both control flow and data dependencies into a single graph, providing a comprehensive representation of the dependencies between variables in a program. 
The PDG was initially developed to serve as a helpful program representation for optimizing compilers targeting vector or parallel machines. 
Such compilers need to perform not only traditional optimizations but also transformations to detect and exploit parallelism effectively.

There are two main types of control dependencies in a PDG: 
First, data dependence occurs when the value computed by one statement depends on the value produced by another. 
Second, control dependence exists between a statement and the predicate that directly controls its execution. 
For instance, in the conditional statement `if(A) B = C * D;`, the execution of $B = C * D$ is controlled by the outcome of the condition A. 
Ferrante, Ottenstein, and Warren~@ferrante1987 describe several variations of the graph. 
Nodes within the PDG can represent entire statements or predicate expressions, or more granularly, individual operators and operands. 
The authors also discuss a more functional style of PDG, which they refer to as a Dataflow Graph augmented with a few additional links.

The construction process begins with an existing CFG (see~@2:sect:cfg).
For handling data dependencies, the original approach assumes each basic block within the CFG is represented as a DAG (see~@2:sect:dag).
The PDG is then built by identifying common subsets of control dependencies, which are factored out by introducing region nodes. 
Specifically, for each non-region node with multiple control dependence predecessors, a region node is created representing this set of predecessors. 
All nodes sharing this same set of control dependence predecessors are then linked to the region node, which replaces the original multiple dependencies as their single control dependence (which can run in linear time~@johnson1994).

Next, the leaf nodes of the DAGs corresponding to each basic block are marked as "merge" nodes.
Initially, every variable in the program is assigned the value "undefined." 
The algorithm determines the set of assignments or initializations—commonly known as Reaching Definitions—that may affect a variable's value at any program point. 
Edges are added between these definitions and the merge nodes, making explicit the chains of usage-to-definition relationships in the graph. 
Input/output operations are treated as operations on an implicit file object to maintain correct sequencing. 
Subscripted array accesses are represented using a "select" operator with inputs for the array and offset, and one output for the selected element. 
Similarly, subscripted array assignments use an "update" operator with inputs for the array, offset, and replacement value, producing a modified array output. 
Loops are represented as single operators with operands for initial, final, and increment values, producing two outputs: an index value stream and a predicate value stream. 
Loop variables are remapped to run from 1 to N in steps of 1.

Ferrante, Ottenstein, and Warren~@ferrante1987 note that the PDG representation may require roughly 50% more memory than simpler linear representations. However, with modern hardware, this overhead is often acceptable rather than a strict limitation. 
Data dependence is most straightforward to determine when pointers, shared variables, or procedure calls with non-pass-by-value semantics cause no side effects. 
Aliasing (when two array-like structures refer to overlapping memory) and side effects introduce significant challenges in accurately modeling dependencies in the PDG. 
To handle implicit aliasing arising from procedure parameter bindings, interprocedural dataflow analysis must be performed. 
This analysis is also used to detect side effects. 
In languages like C, pointers can complicate or even preclude PDG construction because pointers may reference arbitrary memory locations. 
However, principled use of pointers in well-structured C programs may still allow for practical PDG analysis.

PDGs have also proven valuable in code generation~@steensgaard1993 and vectorization~@baxter1989@sarkar1991. The process often involves linearizing the PDG and then interpreting or scheduling its operations to generate executable code~@ferrante1985.

 // - Implementaions 
	//   - Click's IR #link("https://dl.acm.org/doi/abs/10.1145/202530.202534")
	//     - #link("https://dl.acm.org/doi/abs/10.1145/202530.202534") presents a graph-based intermediate representation (IR) with simple semantics and a low-memory C++ implementation, using a directed graph where vertices (labeled with opcodes) have ordered inputs and unordered outputs, and edges are unlabeled. 
	//     - They directly mention their similarity to PDGs however, a key difference is the region node, which merges control values from predecessor blocks into a single output, functioning like a hub or switch to manage control flow. 
	//     - Basic blocks are replaced by region nodes, and the virtual registers are assigned to following Single Static Assignment (see Section ??) form.
	//     - Primitive nodes like IF and PHI receive control inputs to denote their basic block membership. 
	//     - Compared to the PDG this IR is more compact, imposes fewer restrictions on evaluation order, and includes control information at merge points necessary for executable models.

 ====== Click's IR <2:sect:click-ir>
One notable implementation influenced by PDG concepts is Click's IR~@click1995. 
This graph-based IR is designed with simple semantics and implemented in a memory-efficient C++ style.
It employs a directed graph structure in which vertices—labeled with opcodes—have ordered inputs and unordered outputs, while edges remain unlabeled. 
While the authors acknowledge the similarity to PDGs, a key point of divergence lies in their use of region nodes. 
These nodes consolidate control values from predecessor blocks into a single output, effectively acting as switches to manage control flow and replace conventional basic blocks. 
Additionally, the IR follows Single Static Assignment form (see~@2:sect:ssa),
with virtual registers defined accordingly. 
Primitive nodes such as `IF` and `PHI` carry control inputs that explicitly indicate their basic block membership.
Compared to the PDG, this IR is more compact, imposes fewer restrictions on evaluation order, and includes just enough control information at merge points to support executable semantics.

====== Program Dependence Web <2:sect:pdw>

The Program Dependence Web (PDW)~@ottenstein1990 was developed to enable flexible interpretations of programs in control-driven, data-driven, and demand-driven styles. By integrating both control and data dependencies, the PDW allows imperative programs to be mapped onto dataflow architectures and demand-driven graph reducers. It also supports specific optimizations more effectively than SSA-form, as it incorporates control dependence information absent in SSA. This makes the PDW particularly suitable for converting traditional imperative code into representations aligned with modern computational paradigms.

A PDW is constructed by augmenting a Program Dependence Graph (PDG) with elements of SSA, beginning with the replacement of merge nodes with $phi$-functions and renaming variables to enforce single assignment. These $phi$-functions are classified into gating functions: $gamma$ (if-then-else), $mu$ (loop iteration), and $eta$ (loop result). Switch nodes are then introduced to manage value flow into control regions, enabling data-driven interpretation. Switch placement is guided by a breadth-first traversal of the PDG's control dependence subgraph, ensuring definitions entering a region are properly gated. Data operator nodes spanning regions receive additional switch networks representing conditional execution paths.

The PDW enables multiple execution modes: control-driven using original PDG control edges, data-driven via switches, and demand-driven through gating functions. In dataflow extraction, control dependencies and $gamma$-functions are removed after being subsumed by switches. Demand-driven interpretation works in reverse—starting at outputs and querying inputs—allowing gating functions to select inputs based on predicate evaluation dynamically. Despite its versatility, the PDW's complexity and construction overhead, with an $O(N^3)$ time cost, limit its general applicability~@Stanier2013.



===== Dependence Flow Graph <2:sect:dependence-flow-graph>//#link("https://dl.acm.org/doi/pdf/10.1145/99583.99595") #link("https://dl.acm.org/doi/abs/10.1145/155090.155098")
	// Year: 1991
	// Citations: 139 + 192
	// // Why was it developed?
	// - When using dataflow graphs
	// 		- Information is propagated throughout the graph without regard for control flow, not just to where it is needed for optimization. 
	// 		- When the graph at some point in the program is updated, the entire control flow graph below that point (or above it, in backward analysis) may be reanylized, even if there are few points in that region affected by the update.
	// - Def-use chains provide a partial solution to these problems. They permit information to flow directly between definitions and uses without going through unrelated statements; However, def-use chains suffer from three drawbacks. 
	// 		- First, def-use chains cannot be used for backward dataflow problems, such as the elimination of redundant computations, because they do not incorporate sufficient information about the control structure of the program. 
	// 		- Second, this lack of control flow information in def-use chains affects the precision of analysis even in forward dataflow problems such as constant propagation 
	// 		- They also mention size but acknowledge that SSA form resolves this problem.
	// // - \^ #link("https://dl.acm.org/doi/abs/10.1145/155090.155098}
	// - DFG provides more precise structural properties that can be used in correctness proofs.
	// - DFG algorithm performs work only for the relevant dependence at each node, which results in an asymptotic complexity of O(EV), whereas the PDG algorithm would perform O(V) work each time a node is processed.
	// // What does it look like/formal definition?
	// - DFGs extend a relatively standard dataflow graph (including the idea of tokens flowing along edges) with a ``global" storage along with load and store operations to manipulate it. 
	// - These operations emit a secondary ``imperative" token in addition to their value signaling that their execution has finished.
	// - Control flow is accomplished with switch and merge nodes where a switch node takes an imperative token and a boolean, and produces an imperative token along one of two outputs based on the boolean, while a merge takes two input imperative inputs and doesn't require both of its inputs to be filled before forwarding its tokens, thus merging the two possible paths into one.
	// - The authors comment that loops can be represented using recursion, but for optimization purposes instead represent loops using special nodes loop (which has the same semantics as merge) and until (which has the same semantics as switch).
	// - However, the semantics of a standard dataflow graph are flipped: edges in the graph are viewed as single assignment registers, and producing a token on an edge is analogous to storing a value in its associated register.
	// // How is it constructed?
	// // Limitations?
	// Used for:

The development of the Dependence Flow Graph (DFG)~@pingali1991 was motivated by certain limitations encountered when using traditional dataflow graphs. 
In these graphs, information propagates throughout the entire graph without regard for the control flow, rather than being restricted to where the information is actually needed for optimization. 
This leads to inefficiencies. 
For instance, when a part of the graph is updated at some point in a program, the entire control flow graph below that point (or above it, in backward analyses) may need to be reanalyzed, even if only a few points within that region are affected by the update.

Def-use chains were introduced as a partial solution to these problems. 
By allowing information to flow directly between definitions and their uses without passing through unrelated statements, def-use chains improve the flow of information. 
However, def-use chains come with their own set of drawbacks. 
Firstly, they are not suitable for backward dataflow problems, such as the elimination of redundant computations, because they lack sufficient information about the program's control structure. 
Secondly, the absence of control flow information affects the precision of analysis even in forward dataflow problems, like constant propagation. 
Although def-use chains can become large, the adoption of Static Single Assignment (SSA) form helps to alleviate this issue~@johnson1993.

The DFG addresses these shortcomings by providing more precise structural properties, which can be leveraged in formal correctness proofs. 
Furthermore, the DFG algorithm is more efficient; it performs work only for relevant dependencies at each node, resulting in an asymptotic complexity of O(EV), where E and V represent edges and vertices, respectively. This contrasts with the PDG algorithm, which performs O(V) work each time a node is processed.

Formally, DFGs extend a standard dataflow graph by incorporating a concept of "global" storage, along with load and store operations that manipulate this storage. 
These operations emit a secondary "imperative" token in addition to their computed value, signaling that their execution has completed. 
Control flow is implemented through special switch and merge nodes. 
A switch node takes an imperative token and a boolean input, producing an imperative token along one of two outputs depending on the boolean value. 
A merge node takes two input imperative tokens but does not require both to be ready before forwarding a token, effectively merging two possible execution paths into one.

While loops can theoretically be represented using recursion, for optimization purposes, the authors introduce special loop nodes—loop nodes, which behave like merges, and until nodes, which behave like switches. 
It is also notable that the semantics of a standard dataflow graph are inverted in the DFG: edges are viewed as single assignment registers, and producing a token on an edge is analogous to storing a value in the corresponding register.


// - Connection Graphs #link("https://dl.acm.org/doi/pdf/10.1145/319838.319868")




// - Superblocks #link("https://link.springer.com/chapter/10.1007/978-1-4615-3200-2_7} #link("https://dl.acm.org/doi/pdf/10.1145/144965.144998}
// 	// Year: 2011 (hyperblocks 1992)
// 	// Citations: 881 + 918
// 	// Why was it developed?
// 	// What does it look like/formal definition?
// 	// How is it constructed?
// 	// Limitations?
// 	Used for:

// - RVSDG #link("https://dl.acm.org/doi/abs/10.1145/3391902}
// 	// Year: ???
// 	// Citations: ???
// 	// Why was it developed?
// 	// What does it look like/formal definition?
// 	// How is it constructed?
// 	// Limitations?
// 	Used for:
// 			Parallelization
// - Polyhedral #link("https://doi.org/10.1007/978-3-540-24644-2_14}
// #link("https://dl.acm.org/doi/10.1145/1375581.1375595}
// 	// Year: ???
// 	// Citations: ???
// 	// Why was it developed?
// 	// What does it look like/formal definition?
// 	// How is it constructed?
// 	// Limitations?
// 	Used for:
// 			Parallelization

=== Linear Intermediate Representations
	// - Linear IRs are represented by some linear array.
	// - Sometimes it is composed of tokens, sometimes it is composed of tuples storing more abstract ideas, sometimes it is even represented as some textual langage.
	// - Regardless they can be read starting form the beginning and linearly stepping through (just like the source langugaes they are derived from).
	// - Also like those source languages it is entirely possible that a computer executing a linear IR might not step through it linearly, jump and branch operations mimicing those found in assembly languages are common in this type of IR.
	// - It is also not uncommon to see nodes in Graphical IRs be represented as some type of linear IR (the Basic Blocks in a CFG (see Section \ref{sec:cfg}) are often a prime example).
Linear IRs are typically represented as some form of linear array. 
This array can take various forms: 
Sometimes it consists of tokens, other times it comprises tuples that encapsulate more abstract concepts, and occasionally it is represented as a textual language (a primary example being Assembly languages, which act as a human-readable intermediary to machine code). 
Regardless of the specific format, linear IRs can be read sequentially from the beginning, stepping through one element at a time—much like the source languages from which they are derived. 
However, similar to those source languages, it is entirely possible for a computer executing a linear IR to deviate from a strictly linear progression. 
Jump and branch operations, which mimic those found in assembly languages, are common in this type of IR. 
Additionally, it is not unusual for nodes within graphical IRs to be represented as some form of linear IR; 
For example, the Basic Blocks in a Control Flow Graph (see~@2:sect:cfg) serve as a prime example of this practice.

==== Polish Notation <2:sect:polish> // #link("https://philpapers.org/rec/UKAASF")
	// Year: ???
	// Citations: ???
	// // Why was it developed?
	// - One of the earliest intermediate representations, Polish Notation, wasn't intended to be an intermediate representation at all.
	// - When you write math there is often ambiguity that must be clarified with parentheses, for instance in: $2x \/ 3y-1$ #link("https://people.math.harvard.edu/~knill/pedagogy/ambiguity/index.html") when $x = 5$ and $y = 6$, some readers will calculate the answer as 19 while others will find $-0. overline(44)$ and thus parenthesis are needed to clarify which of the two interpretations $((2x) \/ 3)y-1$ or $(2x)\/(3y)-1$ is meant.
	// // What does it look like/formal definition?
	// - Reverse Polish Notation is a postfix form (Normal Polish Notation is prefix) that removes the ambiguity from math and thus the need for parentheses. 
	// - The two above expressions would be written $2 space x space * space 3 space \/ space y space * space 1 space -$ and $2 space x space * space 3 space y space * space \/ space 1 space -$ respectively.
	// - it turns out that these expressions correspond nicely to the operations a stack-based computer would follow to compute these expressions, ie first push operands then pop them and push the computed result on the stack.
	// // How is it constructed?
	// - It is also simple to construct from an Abstract Syntax Tree (Section~\ref{sect:ast")) by simply running a post-order traversal of the tree.
	// // Limitations
	// - Unfortunately, neither form of Polish Notation has any concept of control flow primitives like loops or conditionals, thus Extended Polish Notation~#link("https://www.osti.gov/biblio/6758481") was developed to include them.
	// - However, stack-based computing architectures have been largely replaced by register-based machines, thus Polish Notations are not commonly used by compilers targeting native machine code.
	// - But, more complex versions of Polish Notations (commonly known as bytecodes) often show up in interpreted runtimes; the most notable being Java's JVM Bytecode~#link("https://dl.acm.org/doi/abs/10.1145/202529.202541")
	// Used for:
Polish Notation~@dragonbook, one of the earliest forms of intermediate representations in computing, was not initially designed to serve that role. 
Instead, it emerged as a way to eliminate the ambiguity often found in standard mathematical notation. 
For example, the expression $2x \/ 3y - 1$ is ambiguous without parentheses—depending on how it is interpreted, it can yield vastly different results~@knill2014. 
When $x = 5$ and $y = 6$, some might calculate the result as 19, while others arrive at $-0.overline(44)$. 
This discrepancy arises from two possible interpretations: either $((2x)\/3)y - 1$ or $(2x)\/(3y) - 1$. 

Reverse Polish Notation (RPN), also known as postfix notation (in contrast to the original prefix Polish Notation), addresses this issue by eliminating the need for parentheses. 
It does so by placing operators after their operands. The two aforementioned expressions, when written in RPN, become:

- $2 space x space * space 3 space \/ space y space * space 1 space -$
- $2 space x space * space 3 space y space * space \/ space 1 space -$

This postfix structure not only resolves ambiguity but also aligns neatly with the operations performed by stack-based computers. 
In such systems, operands are pushed onto a stack, and operations are performed by popping values off the stack and pushing the result back on. 
RPN mirrors this computational model perfectly.

RPN is straightforward to derive from an AST (see @2:sect:polish); by performing a post-order traversal of the AST—visiting the children nodes before the parent node—the corresponding RPN expression is naturally produced.

Despite its advantages, Polish Notation has its shortcomings. Neither prefix nor postfix variants support control flow constructs such as loops or conditionals. 
To address this, Extended Polish Notation~@stauffer1978 was introduced, incorporating control structures and making it more suitable for complex program representation.

However, as computing evolved, stack-based architectures gave way to register-based machines, leading to a decline in the use of Polish Notation in modern compilers targeting native machine code.
Nevertheless, more sophisticated descendants of Polish Notation, often referred to as bytecodes, continue to be widely used in interpreted environments. 
A prominent example is the Java Virtual Machine's Bytecode~@gosling1995.

==== Three Address Codes <2:sect:3ac>//#link("(Compilers Principles, Techniques & Tools) Dragon Book")
	// Why was it developed?
	// - So, how can one capture the simplicity of a Polish Notation in a register-based world?
	// // What does it look like/formal definition?
	// - Three Address Codes (3ACs) define a linear array of 4-tuples, the first element represents an operation to perform, while the last three elements represent registers or addresses (or immediate values) to operate on.
	// - For instance, our Polish example might be written in a 3AC as:
	// #math.equation($
	// 	&("load", "r0", 2, emptyset)\
	// 	&("load", "r1", x, emptyset)\
	// 	&(*, "r2", "r0", "r1")\
	// 	&("load", "r3", 3, emptyset)\
	// 	&(\/, "r4", "r2", "r3")\
	// 	&("load", "r5", y, emptyset)\
	// 	&(*, "r6", "r4", "r5")\
	// 	&("load", "r7", 1, emptyset)\
	// 	&(-, "r8", "r6", "r7")\
	// $, block: true) <eq:inefficient-3ac>
 //  - This form of the computation looks suspiciously similar to the assembly language implementation.
 //  - In fact that similarity is one of 3AC's biggest strengths.
  
	// - However, notice that registers can be reused to reduce the number of registers needed:
	// #math.equation($
	// 	&("load", "r0", 2, emptyset)\
	// 	&("load", "r1", x, emptyset)\
	// 	&(*, "r0", "r0", "r1")\
	// 	&("load", "r1", 3, emptyset)\
	// 	&("load", "r2", y, emptyset)\
	// 	&(*, "r1", "r1", "r2")\
	// 	&(\/, "r0", "r0", "r1")\
	// 	&("load", "r1", 0, emptyset)\
	// 	&(-, "r0", "r0", "r1")\
	// $, block: true) <eq:efficient-3ac>
	// - Aho et al. #link("(Compilers Principles, Techniques & Tools) Dragon Book") specify a 3AC form that supports assignments, operations, jumps, procedure calls, array indexing, and pointer assignments. 
	// // How is it constructed?
	// - 3AC can be generated from a linear inorder walk of an AST.
	// - But is it possible to transition automatically from a less register-efficient form of 3AC such as in @eq:inefficient-3ac to a more efficient form such as in @eq:efficient-3ac

How can we capture the elegance and simplicity of Polish Notation in the context of a register-based computing model? 
Three Address Codes (3ACs)~@dragonbook define computations as a linear sequence of 4-tuples. 
Each tuple consists of an operation followed by three elements that typically refer to registers, memory addresses, or immediate values. 
This structure is well-suited to expressing computations in a way that's both readable and amenable to translation into low-level code.

For example, consider the following translation of an expression originally written in Polish Notation. 
Using a naïve approach, we might represent it in 3AC as:

```cpp
  (load, r0, 2, ∅)
  (load, r1, x, ∅)
  (*, r2, r0, r1)
  (load, r3, 3, ∅)
  (/, r4, r2, r3)
  (load, r5, y, ∅)
  (*, r6, r4, r5)
  (load, r7, 1, ∅)
  (-, r8, r6, r7)
```

This representation is quite close in structure to what one might write in an actual assembly language, and this resemblance is one of 3AC's key advantages. 
It bridges high-level structure and low-level implementability, making it ideal for compiler backends.

3AC representations are typically generated by performing a linear inorder traversal of an AST (see~@2:sect:ast). 
This process naturally produces the required sequence of instructions in a way that respects the structure of the original expression.

However, this initial version is not particularly efficient in its use of registers. 
With a small quantity of care, we can rewrite the same computation to reuse registers and reduce the total number needed:

```cpp
  (load, r0, 2, ∅)
  (load, r1, x, ∅)
  (*, r0, r0, r1)
  (load, r1, 3, ∅)
  (load, r2, y, ∅)
  (*, r1, r1, r2)
  (/, r0, r0, r1)
  (load, r1, 1, ∅)
  (-, r0, r0, r1)
```

This optimized form produces the same result but uses fewer registers by overwriting temporary values as soon as they are no longer needed. An intriguing question arises: can we automatically transform a less efficient form of 3AC (as shown in the first example) into a more efficient version (as shown in the second)? 
Single Static Assignment form.

==== Single Static Assignment Form <2:sect:ssa>//#link("https://dl.acm.org/doi/10.1145/512644.512651")
		// #link("https://dl.acm.org/doi/abs/10.1145/115372.115320") shows how to efficiently compute
		
		// Year: 1991
		// Citations: 3505
		// // Why was it developed?
		// - SSA form was developed to provide a more efficient and optimized representation of programs.
		// - By providing a more structured representation of programs, SSA form enables the application of powerful analysis and transformation techniques, ultimately leading to better-optimized object code.
		// // What does it look like/formal definition?
		// - In SSA form, each variable has at most one assignment, making it easier to analyze and optimize the program. 
		// - This is achieved by replacing mentions of a variable V in the original program with a new variable $V_i$.
		// - However an issue occurs when control flow forks and rejoins, if the same variable is modified (creating new $V_i$s) inside the control flow construct, which $V_i$ should be used going forward?
		// - $phi$-functions are thus inserted after control flow branches and represent special assignments 
  //     // TODO: Include an example of SSA
		// // How is it constructed?
		// - Requires a Control Flow Graph (which stores information about how control flow forks and joins) to have already been constructed.
		// - Translating a program naively into SSA form is a two-step process. 
		// 		- In the first step, some trivial $phi$-functions $V_i <- phi(V_j, V_k, ...)$ are inserted at some of the join nodes in the program's control flow graph.
		// 		- In the second step, new variables $V_i$ (for i = 0,1,2,...) are generated. Each mention of a variable V in the program is replaced by a mention of one of the new variables $V_i$, where a mention may be in a branch expression or on either side of an assignment statement.
		// - $phi$-functions can be placed for every variable at every "join" node in a CFG, however this naive algorithm often places more $phi$-functions than are necessary, degrading the performance of optimizations.
		// - #link("https://dl.acm.org/doi/abs/10.1145/115372.115320") presents an algorithm based on dominating nodes in the CFG and ``dominance frontiers" which places an optimal number of $phi$-functions
		// - Dominance refers to the relationship between nodes in a graph where one node dominates another if all paths from the dominated node must go through the dominating node.
		// - The Dominance Frontier for a node X is the set of nodes with a predecessor dominated by X but which are themselves not dominated by X.
		// - Translation to minimal SSA form is done in then three steps:
		// 		- 1) The dominance frontier mapping is constructed from the control flow graph.
		// 		- 2) Using the dominance frontiers, the locations of the $phi$-functions for each variable in the original program are determined.
		// 		- 3) The variables are renamed by replacing each mention of an original variable V by an appropriate mention of a new variable $V_i$.
		// // Limitations?
      
		// - In the absolute worst case scenario finding dominance frontiers take $O(R^2)$ and full translation to SSA form can take $O(R^3)$ where R is the maximum from the number of nodes, edges, variable assignments, or variable mentions.
		// - Can't be directly interpreted
		// 		- Instead a destructuring process must be followed #link("https://ieeexplore.ieee.org/abstract/document/4907656")
		// Used for:
		// 		Code Motion #link("https://dl.acm.org/doi/abs/10.1145/512644.512651")
		// 		Detecting program equivalence #link("https://dl.acm.org/doi/pdf/10.1145/73560.73561")#link("https://minds.wisconsin.edu/handle/1793/59110")
		// 		Elimination of partial redundancies #link("https://dl.acm.org/doi/pdf/10.1145/73560.73562")
		// 		Global Value Numbering: #link("https://dl.acm.org/doi/pdf/10.1145/73560.73562")
		// 		Constant Propagation: #link("https://dl.acm.org/doi/abs/10.1145/103135.103136")
		// 			increasing parallelism in imperative programs [21] // Can't find: CYTRON, R., AND FERRANTE, J. What's in a name? In Proceedings of the 1987 International Conference on Parallel Processing (Aug. 1987), pp. 19-27.

Static Single Assignment (SSA) form~@cytron1986 was developed to provide a more efficient and optimized representation of programs; by imposing a more structured form on a program's variables and assignments, SSA enables the use of advanced analysis and transformation techniques that significantly improve the quality of the generated object code.

In SSA form, each variable is assigned exactly once. 
To achieve this, each occurrence of a variable from the original program is replaced with a new, uniquely named version (e.g., $V_1, V_2, ...$). 
This single-assignment rule simplifies data flow analysis and facilitates various optimizations.

However, complications arise when control flow diverges and then rejoins—such as in `if` statements or loops.
If different versions of a variable are assigned in each branch, the program must reconcile which version to use after the branches rejoin. 
SSA handles this by inserting $phi$-functions, which act as special assignments that choose between different variable versions depending on the control path taken. 
For example, a phi-function might look like: $V_3 = phi(V_1, V_2)$, indicating that $V_3$ should take the value of $V_1$ if control came from one path, and $V_2$ otherwise.

The translation of a program into SSA form requires the prior construction of a CFG (see~@2:sect:cfg),
which captures how execution paths in the program split and merge.
A basic method for constructing SSA form involves two primary steps. 
First, trivial $phi$-functions are inserted at join points within the CFG. 
These functions have the form $V_i = phi(V_j, V_k, ...)$ and are used to merge different variable definitions coming from multiple control paths. 
Second, all variables are renamed so that each assignment and use refers to a uniquely identified version. 
This step ensures that every occurrence of a variable—whether in an expression or an assignment—is replaced with a distinct version $V_i$, corresponding to a specific definition.

However, this straightforward method often introduces more $phi$-functions than necessary, which can hinder the effectiveness of later optimization stages. 
A more sophisticated approach leverages the concept of dominance in the CFG~@cytron1991.
Using dominance frontiers, the translation to minimal SSA form is performed in three steps. 
First, the dominance frontier mapping of the control flow graph is constructed. 
Next, this mapping is used to accurately determine where $phi$-functions are actually needed for each variable. 
Finally, variable renaming is carried out, where each use of a variable is replaced with the appropriate version $V_i$, ensuring that every assignment is unique and each use refers to the correct definition.

Despite its advantages, SSA form has limitations. 
In the worst-case scenario, computing dominance frontiers can take $O(R^2)$ time, and the complete conversion to SSA form may take $O(R^3)$, where $R$ is the maximum among the number of nodes, edges, variable assignments, or variable mentions in the program.
Moreover, SSA form cannot be directly executed or interpreted. 
Programs in SSA form must be destructured—converted back to a form where multiple assignments to the same variable are permitted—before they can be run~@boissinot2009

Despite its limitations, the SSA form has proven to be highly valuable in enabling a range of powerful compiler optimizations and analyses. 
One such optimization is code motion, which improves program efficiency by relocating computations to more optimal positions within the code~@cytron1986. 
It has also been used to facilitate automatic parallelization~@stoltz1994.
SSA also facilitates the detection of program equivalence, an important capability for both optimization and program verification~@yang1989.

Another significant benefit of SSA is its support for the elimination of partial redundancies, where redundant computations that are not present on all execution paths are identified and removed, streamlining code execution~@rosen1988. 
Moreover, SSA enhances constant propagation, which involves replacing variables with known constant values throughout the code, improving execution speed and reducing runtime complexity~@wegman1991.

// // Implementations:


===== SSA Graph <2:sect:ssa-graph>

// 		- SSA Graph #link("https://dl.acm.org/doi/abs/10.1145/143103.143131") #link("https://dl.acm.org/doi/abs/10.1145/200994.201003")
// 				- Extended SSA form to a graph with edges flowing from each operand of an operation to its source operation.
// 				Used for:
// 						- Instruction selection #link("https://dl.acm.org/doi/abs/10.1145/1375657.1375663") #link("https://dl.acm.org/doi/abs/10.1145/1269843.1269857")
// 						- Operator Strength Reduction #link("https://dl.acm.org/doi/abs/10.1145/504709.504710")
// 						- Rematerialization #link("https://dl.acm.org/doi/abs/10.1145/143095.143143")

The SSA Graph~@wolfe1992@gerlek1995 extends the traditional SSA form to a graph structure where edges flow from each operand of an operation to its source operation. This representation has been used in several important compiler optimizations, including instruction selection~@schafer2007@ebner2008, operator strength reduction (reformulating certain costly computations in terms of less expensive ones)~@cooper2001, and rematerialization (recognizing when it is cheaper to recompute a value that does not fit into physical registers than to store and reload it)~@briggs1992. For example, instruction selection benefits from this approach by leveraging the detailed operand-to-operation connections to improve code generation efficiency.

// 		- GSA #link("https://dl.acm.org/doi/abs/10.1145/93542.93578") #link("https://dl.acm.org/doi/abs/10.1145/207110.207115")
// 		Modification of SSA which can be directly interpreted 
// 			// Year: 1990
// 			// Citations: 372 + 94
// 			// Why was it developed?
// 			- #link("https://dl.acm.org/doi/abs/10.1145/93542.93578") originally created Gated Single Assignment (GSA) form to support interpretation of a program dependence graph (Section~\ref{sect:pdg"))
// 			// What does it look like/formal definition?
// 			- In gated single-assignment form, the $phi$-functions are replaced by gating functions. 
// 			- The $gamma$ function, attaches a condition in addition to the two arguments of $phi$-functions, this is used to represent the end of if-else branches
// 			- The $mu$ function, which only appears at loop headers, selects between thee initial and loop-carried values and a matching $eta$ function determines the value of a variable at the the end of the loop
// 			// How is it constructed?
// 			- GSA is constructed by first constructing SSA form. 
// 			- We then collect the control dependence of the definitions reaching a $phi$–function and transforms the $phi$–function into a gating function.
// 			- The algorithm proposed by #link("https://dl.acm.org/doi/abs/10.1145/207110.207115") constructs and places the gating functions from scratch, aiming for a more efficient approach than that of #link("https://dl.acm.org/doi/abs/10.1145/93542.93578"). 
// 			It involves building a gating path expression~#link("https://dl.acm.org/doi/10.1145/322261.322272") for each node in the CFG; it treats any path in the CFG as a string of edges and uses path expressions (simple regular expressions over the edges) to represent these paths.
// 			- Both algorithms traverse the Control Flow Graph to find the gating conditions for each reaching definition. 
// 			- However, the time complexity of the existing algorithms is O(E x N), where E is the number of edges and N is the number of nodes, while the new algorithm aims for a more efficient approach (almost linear time).
// 			- They accomplish this by utilizing path compression~#link("https://dl.acm.org/doi/abs/10.1145/322154.322161"), where the parent pointers of all the nodes visited along the way are updated to point directly to the root; thus flattening the tree, so future find operations reach the root more quickly.
// 			// Limitations?
// 			// Is the fact that we need three types of a $phi$-functions a limitation?
// 			Used for:
// 					Used as an intermediate step in the construction of a PDW
// 					(more compact version) Value Numbering: #link("https://link.springer.com/chapter/10.1007/3-540-57659-2_28")
// 					Validate LLVM compilation passes: #link("https://dl.acm.org/doi/abs/10.1145/1993498.1993533")
===== Gated Single Assignment <2:sect:gsa>

Another notable SSA variant is the Gated Single Assignment (GSA) form~@ottenstein1990; GSA modifies SSA by replacing the classic $phi$-functions with gating functions, which enables direct interpretation of program dependence graphs. This form introduces specialized functions: the $gamma$-function, which attaches a condition along with the two arguments of a $phi$-function to represent the end of if-else branches; the $mu$-function, appearing at loop headers to select between initial and loop-carried values; and the $eta$-function, which determines a variable's value at the end of a loop.

The construction of GSA begins by first building the SSA form~@tu1995. Then, the control dependencies of definitions reaching a $phi$-function are gathered and transformed into gating functions. An improved algorithm constructs these gating functions from scratch by building gating path expressions~@tarjan1981 for each node in the CFG (see~@2:sect:cfg).
This approach treats any path in the CFG as a string of edges, using path expressions—simple regular expressions over edges—to represent these paths. Both this new algorithm and earlier ones traverse the CFG to identify gating conditions for each reaching definition. However, the original algorithms have a time complexity of $O(E × N)$, where $E$ is the number of edges and $N$ is the number of nodes. In contrast, the newer algorithm aims to be more efficient, approaching linear time. It achieves this by using path compression~@tarjan1979, which flattens the traversal trees to speed up subsequent operations.

GSA serves multiple purposes: it acts as an intermediate step in constructing PDGs (see~@2:sect:pdg), 
offers a more compact form for value numbering~@havlak1994, and is also used to validate LLVM compilation passes~@tristan2011. Despite its advantages, GSA introduces complexity by requiring three types of $phi$-like functions, which may be seen as a limitation depending on the context.

===== LLVM <2:sect:llvm> //#link("https://ieeexplore.ieee.org/abstract/document/1281665")
				// Year: 2004
				// Citations: 7494
The Low Level Virtual Machine (LLVM)~@llvm, provides the infrastructure most modern programming languages are built on, including:
  - Python #link("https://github.com/exaloop/codon") #link("https://github.com/numba/numba") #link("https://www.modular.com/max/mojo")
  - (Objective)C(++) #link("https://clang.llvm.org/")
  - Fortran #link("https://flang.llvm.org/docs/")
  - D #link("https://github.com/ldc-developers/ldc")
  - Swift #link("https://developer.apple.com/swift/")
  - GHC Haskell #link("https://www.haskell.org/ghc/")
  - Rust #link("https://www.rust-lang.org/")
  - Zig #link("https://ziglang.org/")
  - Julia #link("https://julialang.org/")
  - Solidity #link("https://github.com/hyperledger/solang")
LLVM is currently used as the intermediate representation (IR) for at least five of the ten most popular programming languages, demonstrating its centrality to contemporary language development. 
Beyond language implementation, LLVM also plays a crucial role in advanced compiler optimization techniques, including polyhedral optimizations @grosser2012, making it a powerful tool not only for generating efficient machine code but also for enabling high-level program analysis and transformation.
		// - Utilized as an intermediate representation for 5 of the 10 most popular languages.
		// - Parellelization #link("https://ieeexplore.ieee.org/abstract/document/323280")
		// Used for:
		// 		POLYHEDRAL OPTIMIZATIONS #link("https://www.worldscientific.com/doi/abs/10.1142/S0129626412500107")


		
// - SSI #link("https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-660.html")
==== MLIR <2:sect:mlir> //~#link("https://ieeexplore.ieee.org/abstract/document/9370308")
// // 		Year: 2020
// // 		Citations: 279 + 388
// // 		// Why was it developed?
//       - MLIR began with a realization that modern machine learning frameworks are composed of many different compilers, graph technologies, and runtime systems that did not share a common infrastructure or design principles. 
//       - This led to poor error abstraction and difficulties across application domains, hardware targets, and execution environments.
//       - The creators of MLIR aimed to address these challenges by building a generalized infrastructure that reduces the cost of building compilers, with diverse domain specific use-cases.
// // 		// What does it look like/formal definition?
//       - MLIR is hosted in the same GitHub repository as LLVM, so it is obvious to ask how they differ: MLIR differs from LLVM in its approach to modeling data structures and algorithms. 
//       - While LLVM is primarily focused on scalar optimizations and homogeneous compilation, MLIR aims to model a rich set of data structures and algorithms as first-class values and operations, all in a customizable way so that additional operations can be added later.
//       - MLIR is composed of several main features:
//         + Types: Structured multi-dimensional types for accessing memory, which are injective by construction to prevent aliasing.
//         + Operations: Basic building blocks of the MLIR IR, including arithmetic, logical, and control flow operations.
//         + Regions: Which group operations together very similarly to blocks in a C-like language and can be attached to control flow operations, the author's cite Click's IR (see Section ??) as the inspiration for Regions.
//         + Attributes: Additional information associated with operations, such as metadata or control flow information.
//         + Dialects: A logical grouping of operations, attributes, and types that provide a common namespace and functionality. They provide several built in dialects range from one which closely maps to LLVM IR to those containing high level tensor manipulating primitives

//       - Unlike most other implementations of SSA, MLIR is "functional" #link("https://doi.org/10.1145/278283.278285") forcing regions to end with a terminating operation which defines a value for the region (and thus its controlling operation) to evaluate to.
//       - This makes $phi$-operations mostly implicit

Multi-Level Intermediate Representation (MLIR)~@lattner2021 was created in response to the recognition that modern machine learning frameworks consist of numerous compilers, graph technologies, and runtime systems that lacked a shared infrastructure or consistent design principles. 
This fragmentation resulted in poor error abstraction and made it challenging to work effectively across different application domains, hardware targets, and execution environments. 
However, unlike most other eliminated machine learning IRs, the creators of MLIR sought to develop a generalized infrastructure that would lower the cost of building compilers while supporting a wide variety of domain-specific use cases.

MLIR is hosted in the same GitHub repository as LLVM, prompting a natural question about how it differs from LLVM itself. 
The key distinction lies in their approaches to modeling data structures and algorithms. 
While LLVM primarily focuses on scalar optimizations and homogeneous compilation, MLIR aims to represent a rich set of data structures and algorithms as first-class values and operations.
It is designed to be highly customizable, allowing new operations to be added over time.

MLIR's core features include several important components. 
Types in MLIR are structured, multi-dimensional, and designed to access memory in a way that is injective by construction, helping to prevent aliasing issues. 
Operations serve as the basic building blocks of MLIR's intermediate representation (IR), encompassing arithmetic, logical, and control flow operations. 
Regions group operations together similarly to blocks in C-like languages and can be attached to control flow operations; their design was inspired by Click's IR (see~@2:sect:click-ir).
Attributes provide additional information linked to operations, such as metadata or control flow details. 
Dialects logically group operations, attributes, and types to establish common namespaces and functionalities. 
MLIR includes several built-in dialects, ranging from those that closely map to LLVM IR to others that support high-level tensor manipulation primitives.

Unlike most other Static Single Assignment (SSA) implementations, MLIR is "functional," which means that regions must end with a terminating operation that defines a value for the region, and consequently for its controlling operation, to evaluate to. 
This functional approach makes $phi$-functions mostly implicit within the system.
// 		// How is it constructed?
// 		// Limitations?
// 		Used for:
// 				Hardware design #link("https://dl.acm.org/doi/abs/10.1145/3623278.3624767")


=== Mathematical Intermediate Representations //Functional

The final set of intermediate representations rely on mathematical substitution as the foundational mechanism for defining and executing computations. 
However, directly compiling mathematical substitution is inefficient, so most real-world systems transform it into more practical forms. 
One common technique is the use of closures, which package function code together with an environment that captures any free variables. 
Another approach is to convert to Continuation-Passing Style (see @2:sect:cps), which restructures functions to receive an explicit continuation, making control flow and substitution more manageable. 
Alternatively, compilers may apply Lambda Lifting~@johnsson1985, converting lambdas into global functions by making free variables explicit parameters, which allows them to be more easily represented in Linear or Graphical Intermediate Representations.
// - TODO: Does are there any term rewrite systems worth mentioning here?

==== Lambda Calculus <2:sect:lambda>//#link("https://compcalc.github.io/public/church/church_calculi_1941.pdf") #link("https://dspace.mit.edu/handle/1721.1/149376")
			// % Year: ~1930
			// // % Why was it developed?
			// - Just like basic graph theory is important to understand graphical IRs, a basic understanding of the Lambda Calculus is import to understand mathematical IRs.
			// - The primary motivation for developing Lambda Calculus was to provide a formal system for expressing functions and performing computations.
			// - The development of Lambda Calculus was also influenced by the desire to provide a formal foundation for combinatorial logic, which is a system of logic that emphasizes constructive proofs rather than classical logical operators.
			// // % What does it look like/formal definition?
			// - In Lambda Calculus, functions are represented as anonymous expressions called "lambda terms" or "lambda abstractions." 
			// - These terms consist of variables, parentheses, and the Greek letter lambda ($lambda$). 
			//   - The lambda symbol is used to introduce a function that takes one argument. 
			//   - For instance, the term $lambda x.x$ (inputs and outputs are separated with a dot) represents a function that takes an input x and returns x itself.
			//   - Only taking one input seems like a major limitation until you realize that a function can produce another function as output thus allowing constructs such as: $lambda x.lambda y. x+y$ which represents the "two parameter" add function
			// // % How is it constructed?
			// - From just these constructs it is possible to define any sort of computation, for instance if true is defined to be $lambda x.lambda y.x$ and false as $lambda x.lambda y.y$ then ifelse can be defined as $lambda b.lambda x.lambda y.b space x space y$ #link("https://www.youtube.com/watch?v=ViPNHMSUcog").   
			// - Functions are called by simply writing their arguments after them
			// - Then computing a result is as simple as substituting each input in the lambda term with an example being: $
   //      "ifelse" "true" M space N \
   //      "becomes" (lambda b.lambda x.lambda y.b space x space y) space (lambda x.lambda y.x) space M space N \
   //      "// Notice how every instance of b is replaced with (λx.λy.x)"\
   //      "becomes" (lambda x.lambda y.(lambda x.lambda y.x) space x space y) space M space N \
   //      "becomes" (lambda y.(lambda x.lambda y.x) space M space y) space N \
   //      "becomes"  (lambda x.lambda y.x) space M space N \
   //      "becomes" (lambda y.M) space N \
   //      "becomes" M \
   // $
			// - Church called this repeated process of substituting in inputs $beta$-reduction.
			// // % Limitations?
			// - Lambda Calculus has no built-in support for numbers, booleans (note we had to define true and false in terms of functions), lists, or other data structures. Everything must be encoded using functions (e.g., Church numerals), which can be: Inefficient and Hard to understand
			// - $beta$-reduction doesn't map nicely to modern machine code, thus Lambda Calculus is much easier to implement as an IR for an interpreter rather than a compiler. 
			// Used for:

The primary motivation behind Lambda Calculus's~@church1941 development was to create a formal system for expressing functions and performing computations. 
Additionally, it aimed to establish a formal foundation for combinatorial logic—a type of logic that focuses on constructive proofs rather than classical logical operators.

In Lambda Calculus, functions are expressed as anonymous expressions known as lambda terms or lambda abstractions. 
These terms are built using variables, parentheses, and the Greek letter lambda ($lambda$). 
The $lambda$ symbol introduces a function that takes a single argument. For example, the expression $lambda x.x$ defines a function that takes an input $x$ and returns $x$ itself. 

Although lambda terms take only one input at a time, this is not a limitation. 
A function can return another function, which makes it possible to construct multi-parameter functions such as $lambda x.lambda y.x + y$, effectively defining a two-parameter addition function.

With just these basic constructs, it is possible to represent any computation. 
For instance, one can define Boolean logic purely in terms of functions:

- $"true" = lambda x.lambda y.x$
- $"false" = lambda x.lambda y.y$

Using these definitions, an `if-else` construct can be encoded as:

- $"if-else" = lambda b.lambda x.lambda y.b x y$

Function application in Lambda Calculus is straightforward:
An argument is applied simply by writing it next to the function.
Evaluating the result involves substituting the function's parameter with the given argument—a process known as beta reduction ($\beta$-reduction). For example, applying the `ifelse` function to the inputs True, $M$, and $N$:
$
  "if-else" "true" M space N \
  "becomes" (lambda b.lambda x.lambda y.b space x space y) space (lambda x.lambda y.x) space M space N \
  "// Notice how every instance of b is replaced with (λx.λy.x)"\
  "becomes" (lambda x.lambda y.(lambda x.lambda y.x) space x space y) space M space N \
  "becomes" (lambda y.(lambda x.lambda y.x) space M space y) space N \
  "becomes"  (lambda x.lambda y.x) space M space N \
  "becomes" (lambda y.M) space N \
  "becomes" M \
$
This process demonstrates how the function selects and returns the appropriate value based on the input boolean.

However, Lambda Calculus also has its limitations. 
It lacks built-in support for basic data types such as numbers, booleans, and lists. 
These must all be encoded using functions—like Church numerals for representing numbers—which can be both inefficient and difficult to read. 
Additionally, $\beta$-reduction does not translate well to modern machine code, making Lambda Calculus more suitable as an intermediate representation for interpreters rather than compilers.

	// %\item A - calculus
	// \item Continuation Passing Style #link("https://link.springer.com/article/10.1023/A:1010035624696") #link("https://dspace.mit.edu/handle/1721.1/6913") %#link("https://dl.acm.org/doi/abs/10.1145/75277.75303")
	// 		% Year: 1978
	// 		% Citations: 579 + 602
	// 		% Why was it developed?
	// 		% What does it look like/formal definition?
	// 		% How is it constructed?
	// 		% Limitations?
	// 		Used for:
	// \item A-normal form #link("https://link.springer.com/article/10.1007/BF01019462")
	// 		% Year: 1993
	// 		% Citations: 383
	// 		% Why was it developed?
	// 		% What does it look like/formal definition?
	// 		% How is it constructed?
	// 		% Limitations?
	// \item System F #link("https://www.sciencedirect.com/science/article/pii/S0890540184710133?via%3Dihub")
	// % Martin Sulzmann, Manuel MT Chakravarty, Simon Peyton Jones, and Kevin Donnelly. 2007. System F with type equality coercions. In Proceedings of the 2007 ACM SIGPLAN International Workshop on Types in Language Design and Implementation (TLDI), pages 53ś66.
	// % Simon L. Peyton Jones. 1992 (April). Implementing lazy functional languages on stock hardware: The spineless tagless G-machine. Journal of Functional Programming, 2(2):127ś202.
	// % https://www.researchgate.net/profile/Heba-Mohsen-2/publication/323556918_Comparative_Study_of_Intelligent_Classification_Techniques_for_Brain_Magnetic_Resonance_Imaging/links/5a9d4480a6fdcc3cbacdf21b/Comparative-Study-of-Intelligent-Classification-Techniques-for-Brain-Magnetic-Resonance-Imaging.pdf#page=91
	// \item Thorin #link("https://ieeexplore.ieee.org/abstract/document/7054200")

==== Continuation Passing Style <2:sect:cps> //#link("https://doi.org/10.1023%2FA%3A1010035624696")
  	// 		% Year: 1978
	// 		% Citations: 579 + 602
	// 		% Why was it developed?
 //    - Continuation-Passing Style (CPS) was created as a way to make the flow of control in programs explicit, particularly in the context of programming language theory, compiler design, and functional programming. 
	// // 		% What does it look like/formal definition?
 //    - CPS is a form of programming in which functions take an extra argument called a continuation—a function representing "the rest of the computation"—instead of returning results directly. 
 //    - In CPS, a function performs its computation and then calls the continuation with the result, thus "returning" becomes a call to the next function. 
 //    - This style eliminates traditional returns, ensures that all function calls are tail calls, and provides a uniform way to represent advanced control features like exceptions, coroutines, and backtracking. 
	// // 		% How is it constructed?
 //    - CPS can be constructed in Lambda Calculus by transforming expressions into functions that take explicit continuations and apply them to the result. 
 //    - #link("https://matt.might.net/articles/cps-conversion/") outlines this process using three main functions: T-c, T-k, and M.
 //    - T-c performs a basic CPS transform under the assumption that the continuation is already known. It rewrites expressions to directly apply this continuation to the result.
 //    - T-k, by contrast, is higher-order: instead of taking a continuation expression, it takes a function that generates a CPS expression when given an atomic CPS value. This makes it better suited for composing nested or complex expressions.
 //    - M handles atomic expressions like variables and lambdas, transforming them into CPS-compatible forms. It ensures lambdas are rewritten to accept and pass results to continuations.
 //    - The transformation process chooses between T-c and T-k based on context: T-c is used when a continuation is already available (e.g., at the top level), while T-k is used for building up more complex or nested expressions.
    
 //    - CPS and SSA (see Section ?) share a deep structural similarity that allows one to be transformed into the other through syntactic means. 
 //    - The transformation from CPS to SSA, defined by #link("https://dl.acm.org/doi/pdf/10.1145/202530.202532"), leverages the fact that in CPS, each variable is bound exactly once, and continuations can be interpreted as SSA blocks or return points, depending on their role.
 //    - Continuations marked as `jump` in CPS (The transformation requires that each $lambda$ (function) in CPS be labeled as `proc`, `cont`, and `jump`; which respectively distinguish full procedures, return-point continuations, and local continuations used for control flow like conditionals and loops.) correspond to labeled blocks in SSA with $phi$-functions collecting control-flow paths.
 //    - The transformation process involves translating CPS bindings and expressions directly into SSA assignments and control-flow structures. 
 //    - Tail calls to continuations become jumps (gotos in C parlance), and conditional branches in CPS map directly to if statements in SSA. 
 //    - For CPS functions where recursion expresses loops, these are converted into SSA loops using recursive blocks and $phi$-functions to merge values across iterations. 
	// // 		% Limitations?
 //    - While most CPS programs that arise from standard transformations can be handled this way, CPS programs involving non-local continuations (like those from `call-with-current-continuation` in Scheme) cannot be cleanly expressed in SSA, since SSA lacks the flexibility to represent such complex control flow.
 //    - Similarly Irreducible Control Flow causes issues in transformations from SSA to CPS.
Continuation-Passing Style (CPS)~@sussman1998 was developed to make the control flow of programs explicit, especially in the contexts of programming language theory, compiler design, and functional programming. 
By transforming the way functions return results, CPS provides a robust framework for reasoning about program execution and implementing advanced control structures.

In CPS, functions do not return results in the conventional sense. 
Instead, each function takes an additional argument called a continuation—a function that represents the rest of the computation to perform after the current function completes. 
When a function finishes its computation, it does not return the result; instead, it calls the continuation function with the result as an argument. 
This means all function calls in CPS are tail calls, which eliminates the need for traditional return mechanisms and creates a uniform structure ideal for expressing advanced control features such as exceptions, coroutines, and backtracking.

The CPS transformation can be formally constructed in the Lambda Calculus by rewriting expressions so that they explicitly take and apply continuations. 
Might~@might2011 presents this process in terms of three functions: the T-c transformation assumes that a continuation is already available and rewrites expressions so that the result is passed directly to this continuation. 
In contrast, T-k is more flexible: it takes a function that, given a CPS-compatible value, returns a CPS expression. 
This makes T-k particularly useful for composing nested or complex expressions. 
The M transformation handles atomic expressions such as variables and lambda abstractions, converting them into forms that are compatible with CPS. 
Specifically, M rewrites lambdas so they accept continuations and pass their results to them. 
The transformation process uses T-c when the context provides an existing continuation (such as at the top level) and resorts to T-k for constructing more intricate or nested CPS structures.

There is a deep structural similarity between CPS and Static Single Assignment form (see @2:sect:ssa), allowing for translation between the two. 
Kelsey~@kelsey1995 shows that the one-to-one binding of variables in CPS and the precise control flow through continuations align closely with SSA's approach of unique variable assignment and block-structured control flow. 
In his transformation, CPS continuations are treated as SSA blocks. 
Those labeled as jump—which in CPS distinguish control-flow branches such as conditionals and loops—correspond to SSA's labeled blocks containing $phi$-functions to reconcile incoming control paths. 
CPS bindings and function applications map directly to SSA variable assignments and control-flow structures. 
Tail calls to continuations become jumps, akin to gotos in imperative languages, while CPS's conditional structures translate directly to SSA's if-statements. 
Furthermore, loops expressed via recursion in CPS are transformed into SSA loops using recursive blocks and $phi$-functions to merge values across iterations.

However, this transformation is not without limitations. 
Some CPS programs, particularly those involving non-local continuations (such as those constructed using call-with-current-continuation in Scheme), cannot be faithfully represented in SSA form. 
SSA's structure lacks the flexibility to model such arbitrary control transfers. 
Likewise, specific patterns in SSA, particularly irreducible control flow, pose challenges when converting from SSA back to CPS. 
These edge cases highlight fundamental differences between the models and show that while the two Intermediate Representations are very similar, they are not equivalent.

====  Interaction Nets <2:sect:interaction-nets> //#link("https://dl.acm.org/doi/pdf/10.1145/96709.96718") 
// 	// Year: 1997
// 	// Citations: 138
// // 	// Why was it developed?
// 	- Interaction nets were created as a new kind of programming language with the following features:
// 	  - A simple graph rewriting semantics
// 	  - A complete symmetry between constructors and destructors
// 	  - A type system for deterministic and deadlock-free (microscopic) parallelism.
// 	- Their parallizability seems to be one of their main selling points and the primary reason they have seen a small modern resurgence #link("https://github.com/HigherOrderCO/HVM") .
// // 	// What does it look like/formal definition?
// 	- Interaction nets are an extension of proof nets to the field of programming languages.
// 	- In this system, a principal port is a specific port assigned to each symbol (or agent) in a net. 
// 	- It's used for interaction between agents and is distinguished from auxiliary ports.
// 	- Then there is a reduction rule for each matching pair of symbols when they interact via their principal ports.

// 	- They then introduce a type system, which restricts the interactions between agents based on their types.
// 	- Specifically, the language defines constant types such as atom, list, nat, d-list, stream, and tree, and requires that ports be typed as input (T-) or output (T+). 
// 	- A rule is well-typed if its left member's symbols have opposite types and the right member is well-typed.
// // 	// How is it constructed?
// 	- Construction is one of the major limitations, they don't mention a method of constructing Interaction Nets and implementations #link("https://github.com/HigherOrderCO/HVM") #link("https://arxiv.org/abs/1505.07164") construct their own languages which map rather closely to interaction nets.
// 	- Thus we tentatively infer that it is difficult to map existing languages to Interaction Nets
// 	  - Interaction Combinators #link("https://www.sciencedirect.com/science/article/pii/S0890540197926432?via%3Dihub")
// 	  - Interaction combinators are simplification of interaction nets.
// 	  - While the original paper defined symbols for a LISP like list processing language, this system defines only three Symbols: $gamma$ (constructor), $delta$ (duplicator), and $epsilon$ (eraser) and six interaction rules that are presented in @fig:interaction-net-replacements. #link("https://github.com/HigherOrderCO/HVM") have implemented this system

Interaction Nets~@lafont1989 were created as a new kind of programming language characterized by several distinct features. 
They are based on a simple graph rewriting semantics, which provides a clear and intuitive foundation for computation. 
A notable aspect of interaction nets is the complete symmetry between constructors and destructors, ensuring a balanced and elegant structure. 
Additionally, they incorporate a type system designed to enable deterministic and deadlock-free microscopic parallelism, making them particularly well-suited for concurrent computations. 
One of the main selling points of interaction nets is their inherent parallelizability, which has contributed to a modest modern resurgence in interest, as evidenced by ongoing projects such as the HVM~@HVM implementation.

Interaction Nets can be understood as an extension of Proof Nets~@girard1995 applied to the domain of programming languages. Each symbol—or agent—in the net is assigned a specific port known as the principal port, which is distinguished from the auxiliary ports. Interaction occurs when agents connect through their principal ports, and each matching pair of symbols has an associated reduction rule that defines their interaction. The system also introduces a type system that restricts agent interactions based on their types. The language defines several constant types, including atom, list, nat, d-list, stream, and tree. Moreover, each port is typed as either input (denoted T-) or output (T+). For a reduction rule to be well-typed, the symbols on the left side of the rule must have opposite port types, and the resulting right side must also be well-typed.

One of the significant challenges with interaction nets lies in their construction. There is no widely established method for constructing interaction nets directly, and existing implementations~@HVM@hassan2015, typically build custom languages that map closely—but not trivially—to interaction nets. This suggests that mapping existing programming languages onto interaction nets can be difficult. A related concept, interaction combinators~@lafont1997, serves as a simplified model of interaction nets. While the original formulation of interaction nets included symbols tailored to a Lisp-like list processing language, interaction combinators reduce the system to just three symbols: $gamma$ (constructor), $delta$ (duplicator), and $epsilon$ (eraser). These are governed by six interaction rules that define their behavior which are presented in @fig:interaction-net-replacements.

   #figure(
     placement: top,
		raw-render(```
digraph G {
    edge [arrowhead=none]
    

  subgraph _1a {
    _1atl -> _1ag 
    _1atr -> _1ag
    _1ag -> _1ad
    _1ad -> _1abl
    _1ad -> _1abr
    _1ag [shape=invtriangle, label="𝛾"]
    _1ad [shape=triangle, label="δ"]
    _1atl [shape=none, label=""]
    _1atr [shape=none, label=""]
    _1abl [shape=none, label=""]
    _1abr [shape=none, label=""]
  }

  subgraph _1b {
    _1btl -> _1bdl
    _1btr -> _1bdr
    _1bdl -> _1bgl
    _1bdl -> _1bgr
    {rank=same _1bgl -> _1bgr [style=invis]}
    _1bdr -> _1bgr
    _1bdr -> _1bgl
    _1bgl -> _1bbl
    _1bgr -> _1bbr
    _1bdl [shape=triangle, label="δ"]
    _1bdr [shape=triangle, label="δ"]
    _1bgl [shape=invtriangle, label="𝛾"]
    _1bgr [shape=invtriangle, label="𝛾"]
    _1btl [shape=none, label=""]
    _1btr [shape=none, label=""]
    _1bbl [shape=none, label=""]
    _1bbr [shape=none, label=""]
  }
  
  {rank=same _1ag _1bdl _1bdr }
  {rank=same _1ad _1bgl _1bgr }
  
  _1ad -> _1bgl [ltail=_1a,lhead=_1b,arrowhead=normal, label="𝛾δ"]
  
  
  subgraph _2a {
    _2atl -> _2ag 
    _2atr -> _2ag
    _2ag -> _2ae
    _2ag [shape=invtriangle, label="𝛾"]
    _2ae [label="ε"]
    _2atl [shape=none, label=""]
    _2atr [shape=none, label=""]
  }
  
  subgraph _2b {
    _2btl -> _2bel [minlen=2]
    _2btr -> _2ber [minlen=2]
    _2bel [label="ε"]
    _2ber [label="ε"]
    _2btl [shape=none, label=""]
    _2btr [shape=none, label=""]
  }
  
  {rank=same _2ae _2bel _2ber }
  _2ae -> _2bel [ltail=_2a,lhead=_2b,arrowhead=normal, label="𝛾ε"]
  
  
  subgraph _3a {
    _3atl -> _3ag 
    _3atr -> _3ag
    _3ag -> _3ae
    _3ag [shape=invtriangle, label="δ"]
    _3ae [label="ε"]
    _3atl [shape=none, label=""]
    _3atr [shape=none, label=""]
  }
  
  subgraph _3b {
    _3btl -> _3bel [minlen=2]
    _3btr -> _3ber [minlen=2]
    _3bel [label="ε"]
    _3ber [label="ε"]
    _3btl [shape=none, label=""]
    _3btr [shape=none, label=""]
  }
  
  {rank=same _3ae _3bel _3ber }
  _3ae -> _3bel [ltail=_3a,lhead=_3b,arrowhead=normal, label="δε"]
  
  
  subgraph _4a {
    _4atl -> _4ag 
    _4atr -> _4ag
    _4ag -> _4ad
    {rank=same _4abl -> _4abr [style=invis]}
    _4ad -> _4abl
    _4ad -> _4abr
    _4ag [shape=invtriangle, label="𝛾"]
    _4ad [shape=triangle, label="𝛾"]
    _4atl [shape=none, label=""]
    _4atr [shape=none, label=""]
    _4abl [shape=none, label=""]
    _4abr [shape=none, label=""]
  }
  
  subgraph _4b {
    _4btl -> _4bbl [minlen=3]
    _4btr -> _4bbr [minlen=3]
    _4btl [shape=none, label=""]
    _4btr [shape=none, label=""]
    _4bbl [shape=none, label=""]
    _4bbr [shape=none, label=""]
  }
  
  {rank=same _4abl _4abr _4bbl _4bbr }
  _4abr -> _4bbl [ltail=_4a,lhead=_4b,arrowhead=normal, label="𝛾𝛾"]
  
  
  subgraph _5a {
    _5atl -> _5ag 
    _5atr -> _5ag
    _5ag -> _5ad
    {rank=same _5abl -> _5abr [style=invis]}
    _5ad -> _5abl
    _5ad -> _5abr
    _5ag [shape=invtriangle, label="δ"]
    _5ad [shape=triangle, label="δ"]
    _5atl [shape=none, label=""]
    _5atr [shape=none, label=""]
    _5abl [shape=none, label=""]
    _5abr [shape=none, label=""]
  }
  
  subgraph _5b {
    {rank=same _5btl -> _5btr [style=invis]}
    {rank=same _5bbl -> _5bbr [style=invis]}
    _5btl -> _5bbl [minlen=3, style=invis]
    _5btr -> _5bbr [minlen=3, style=invis]
    
    _5btl -> _5bbr 
    _5btr -> _5bbl
    _5btl [shape=none, label=""]
    _5btr [shape=none, label=""]
    _5bbl [shape=none, label=""]
    _5bbr [shape=none, label=""]
  }
  
  {rank=same _5abl _5abr _5bbl _5bbr }
  _5abr -> _5bbl [ltail=_5a,lhead=_5b,arrowhead=normal, label="δδ"]
  
 
  
  
  {rank=same _4ag _5ag }
  {rank=same _4ad _5ad }
  {rank=same _4bbl _4bbr _5abl _5abr }
  
  _1bbl -> _4atl [style=invis]
  _4bbr -> _5abl [style=invis]
}
		```, width: 100%),
		caption: [Five of the six interaction net substitution rules, $gamma delta$-interaction (top left), $gamma epsilon$-interaction (top center), $delta epsilon$-interaction (top right), $gamma gamma$-interaction (bottom left), and $delta delta$-interaction (bottom right). The sixth is $epsilon epsilon$-interaction in which both symbols are erased.]
	) <interaction-net-replacements>
// 	Used for:

// == Logical
    // \item WAM? #link("https://cds.cern.ch/record/162121/files/CM-P00069219.pdf")
		// \item Verse Calculus #link("https://simon.peytonjones.org/assets/pdfs/verse-conf.pdf")
		// %https://scholar.google.com/scholar?hl=en&as_sdt=0%2C29&q=prolog&btnG= ???

== Discussion <2:sect:discussion>

Intermediate representations (IRs) in compilers serve as critical abstractions for analyzing, transforming, and optimizing programs. Graph-based IRs like Graphical Intermediate Representations, Directed Acyclic Graphs (DAGs), and Program Dependence Graphs (PDGs) visually model computations through nodes and edges, emphasizing structural and semantic relationships between operations. Variants such as Control Flow Graphs (CFGs) and Dataflow Graphs (DFGs) specialize in capturing execution paths and data dependencies, respectively. At the same time, hybrids and extensions like Value Dependence Graphs, Program Dependence Webs (PDWs), and Dependence Flow Graphs offer enriched semantic modeling for research and parallelism.

Linear IRs, including Three-Address Code (TAC) and Polish Notation, represent computations sequentially, making them easier to serialize and map directly to machine code. Single Static Assignment (SSA) form, and its extensions like Gated Single Assignment (GSA) and SSA Graphs, underpin many modern compiler optimizations by simplifying variable tracking and data flow. Popular frameworks like LLVM IR and MLIR build upon SSA to enable modular, multi-target compilation and support for domain-specific representations across multiple abstraction levels.

Functional and mathematical IRs, such as Lambda Calculus, Mathematical IRs, and Interaction Nets, abstract away control flow in favor of expression evaluation and substitution. These representations, while less common in imperative language compilers, are foundational in the functional programming ecosystem, enabling formal reasoning, parallelism, and verification. Though many IRs vary in complexity and domain focus, from industry standards like LLVM to research-oriented models like Click's IR or Program Expression Graphs, their collective role is to bridge the gap between source code and efficient executable programs.

=== Optimization

IRs in compilers play a crucial role in enabling various forms of program optimization. Graph-based IRs like Control Flow Graphs (CFG), Dataflow Graphs (DFG), Program Dependence Graphs (PDG), and Directed Acyclic Graphs (DAG) make control and data dependencies explicit, allowing for optimizations such as dead code elimination, instruction reordering, and parallelization. Hybrid models that combine control and data aspects, like Control Flow/Dataflow Hybrids and the Dependence Flow Graph, enhance capabilities like branch prediction and instruction-level parallelism. These representations also support advanced analyses such as speculative execution and memory disambiguation.

Several specialized IRs further refine optimization potential. SSA (Single Static Assignment) and its variants, like SSA Graph and Gated SSA, simplify dataflow analysis and register allocation by making variable versions and dependencies clear. Representations like Click's IR, LLVM, MLIR, and PEG are designed for aggressive or domain-specific optimizations, supporting techniques like loop unrolling, superoptimization, and fusion. Others, such as Three-Address Code and Linear IRs, offer efficient paths to low-level machine code, supporting local optimizations and strength reduction.

Functional and mathematical representations, including Lambda Calculus, Mathematical IRs, and Interaction Nets, are well-suited for transformations like $beta$-reduction, inlining, and partial evaluation. These IRs emphasize referential transparency and algebraic simplification, making them ideal for compilers targeting functional languages or high-performance computing contexts. While traditional forms like ASTs and Polish Notation offer limited optimization potential, they still serve as foundational structures for parsing and initial program analysis.
As the compilation process advances from analysis and transformation toward code generation, the role of intermediate representations shifts accordingly.

=== Code Generation

IRs serve various roles in the code generation pipeline, ranging from abstract syntax trees (ASTs) to highly optimized low-level forms. High-level representations like ASTs or Program Expression Graphs (PEGs) must first be transformed into lower-level IRs due to their lack of machine semantics. Graph-based IRs, such as Control Flow Graphs (CFGs), Dataflow Graphs (DFGs), and Control/Dataflow hybrids, are valuable for structuring computation and scheduling, often aligning well with hardware targets, particularly in parallel and SIMD/SIMT environments. Some specialized forms, like the Program Dependence Graph (PDG) and Program Dependence Web (PDW), are more relevant for transformations and speculative execution strategies than direct code generation.

Linearized IRs, such as Three-Address Code, SSA form, and its variants (SSA Graph, Gated SSA), are more suitable for direct code generation due to their close mapping to machine instructions and ease of register allocation and instruction scheduling. While SSA form requires conversion (e.g., φ-node elimination) before final codegen, it remains a backbone in modern compiler infrastructures like LLVM and GCC. Similarly, representations like Polish Notation and Click's IR can be interpreted or directly lowered into machine code in production environments. Linear IRs often represent the final stage before generating assembly code.

Modern compiler frameworks like LLVM and MLIR further abstract and streamline the code generation process. LLVM provides direct support for multiple architectures through a unified IR, offering robust optimization and instruction selection backends. MLIR, though not a final codegen IR itself, acts as a flexible intermediate layer supporting heterogeneous targets such as CPUs, GPUs, and FPGAs. Functional IRs, including Mathematical IRs and Lambda Calculus, typically undergo transformations (e.g., to continuation-passing style) before reaching low-level forms. Experimental models like Interaction Nets, though not mainstream, offer potential for highly parallel execution through runtime-managed rewrites.

== Conclusion <2:sect:conclusion>

This review explores a wide array of intermediate representations (IRs) beyond standard forms like ASTs, CFGs, and SSA, directly addressing our three research questions. For RQ1, we identify lesser-known or advanced IRs such as Program Dependence Graphs (PDGs), Dependence Flow Graphs, Program Dependence Webs (PDWs), Program Expression Graphs (PEGs), Click's IR, and mathematical or functional IRs like Lambda Calculus and Interaction Nets—each offering unique structural or semantic insights not found in conventional IRs. 

Regarding RQ2, IRs like SSA (and its variants), PDGs, and hybrid control/data flow models prove most beneficial for optimizations, enabling techniques such as instruction-level parallelism, loop unrolling, memory disambiguation, and superoptimization. Functional IRs support algebraic simplifications and β-reduction, aiding optimizations in functional or high-performance computing domains. 

In response to RQ3, linear IRs such as Three-Address Code, SSA, and even Polish Notation show strong suitability for code generation due to their machine-level alignment and straightforward mapping to assembly. Frameworks like LLVM and MLIR exemplify how modern infrastructures leverage these IRs to support robust codegen pipelines across diverse hardware targets.

#unumbered_heading[Acknowledgement]
This material is based in part upon work supported by the National Science Foundation under grant numbers 
// %\#\#\#-\#\#\#\#\#\#\#.
OIA-2019609 // T2 Tic % I'm guessing this number is no longer relevant?
 and OIA-2148788. // T1 Fire
Any opinions, findings, and conclusions or recommendations expressed in this material are those of the authors and do not necessarily reflect the views of the National Science Foundation.