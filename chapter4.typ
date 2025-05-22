= An Embeddable Virtual Machine <chapter:chapter4>

This chapter first appeared as a conference publication in SERA 2025. #linebreak()
J. Dahl, Q. Contaldi, K. Partovi and F. C. Harris, Jr."Mizu: A Lightweight Multi-Threaded Threaded-Code Interpreter that Can Run Almost Anywhere with a C++ Compile" The 23rd IEEE/ACIS International Conference on Software Engineering, Management and Applications (SERA 2025) May 29-31, 2025 Las Vegas, NV.

== Abstract

We present Mizu, a threaded-code interpreter for an assembly-like language designed to be embedded inside compilers. 
Mizu has three primary goals: to be lightweight, portable, and extensible. 
We explore Mizu’s lightweight core instruction set, along with several of its extensions and some of our methods for further extension, and the platforms it has been ported to. 
Additionally, we demonstrate how two high-level features—threading and foreign function interfaces—can be spelled at the level of an assembly language. 
Finally, we compare Mizu to several other popular interpreted languages and find that it's performance sits comfortably between JIT interpreters (approximately 4 times slower on a CPU straining task) and regular interpreters (approximately 8.5 times faster on the same task) all with only fourty-six core instructions.