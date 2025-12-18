= A Full Tree Representation <sect:full-tree>

Below is the AST generated for the Lox code in @lst:redundant-copies.
Child nodes are indented one level beneath their parents.
Each node ends with two numbers in parentheses: the first is the node's Entity ID, and the second is the total number of children it has (both direct and indirect).
Some nodes also include three numbers in square brackets after the parentheses. These represent the attached 3AC: the result and two operands of the operation (a 0 indicates the absence of an operand).
Nodes are stored in memory in ascending order of their Entity IDs.
Notice that a reverse iteration starting at Entity #24 corresponds to the execution of the program. Similarly, a reverse iteration that skips nodes without attached 3AC also corresponds to an execution.

```c
{ (1, 23)
	declare:var:x (24, 0)
		assign: (21, 2)
				var:x -> 24 (22, 0)
		=
				5 (23, 0) [23, 0, 0]
		declare:var:y (20, 0)
		assign: (17, 2)
				var:y -> 20 (18, 0)
		=
				6 (19, 0) [19, 0, 0]
		declare:var:z (16, 0)
		assign: (13, 2)
				var:z -> 16 (14, 0)
		=
				7 (15, 0) [15, 0, 0]
		print (3, 9)
				+ [add] (4, 8) [4, 23, 6]
						var:x -> 24 (5, 0)
						/ [divide] (6, 6) [6, 7, 10]
								* [multiply] (7, 2) [7, 19, 15]
										var:y -> 20 (8, 0)
										var:z -> 16 (9, 0)
								- [subtract] (10, 2) [10, 15, 19]
										var:z -> 16 (11, 0)
										var:y -> 20 (12, 0)

		declare:fun:clock (2, 0) {} // A builtin function
}```

