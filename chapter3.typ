= Challenges and Motivations <chapter:motivation>

// This chapter has all the background needed to explain everything else...
// Remember your audience - you are writing for a first semester graduate student...

This chapter first appeared as a conference publication in ACM's SIGPLAN Onward!~@Dahl2025splash. #linebreak()
J. Dahl, Q. Contaldi, and F. C. Harris Jr., "A Systematic Review of Intermediate Representations for Optimizing and Generating Code," in Proceedings of the 2025 ACM SIGPLAN International Symposium on New Ideas, New Paradigms, and Reflections on Programming and Software, in Onward! '25. Singapore: Association for Computing Machinery, 2025, p. ??. doi: ??/??.

== Abstract

In this paper we examine how Entity Component Systems, a data structure that has been gaining popularity in game engines, can benefit compiler and interpreter design.
It does not provide the same performance benefits that games utilize it for; however, it does make writing optimization passes easier.
Additionally, its dogmatic focus on simple Plain-Old-Data structures makes serialization much easier.
These benefits do come at a memory cost, the severity of which we still need to compare against more mature language implementations.