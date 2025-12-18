# Foundations for a Data Oriented Compiler Infrastructure

This repository contains the source code for the Master of Science thesis titled **"Foundations for a Data Oriented Compiler Infrastructure"** by Joshua Aaron Dahl, submitted to the University of Nevada, Reno in August 2025.

## 📖 Publication

The complete thesis is available on ProQuest: [View Publication](https://www.proquest.com/docview/3247618211/abstract/AE7F1866861F4EC1PQ/1?accountid=452&sourcetype=Dissertations%20&%20Theses)

## 📝 Abstract

Despite the fact that most college graduates possess the necessary skills to assemble a compiler, few actually take on the task. One major barrier is the lack of an accessible and well-designed Intermediate Representation (IR) that can support and guide new compiler authors. A thoughtfully constructed IR could significantly reduce the difficulty of compiler development and encourage more individuals to engage with this domain.

To address this issue, this thesis conducts a survey of existing compiler IR, paying particular attention to lesser-known or obscure designs that may offer untapped potential. In addition, it explores the feasibility of employing Entity Component Systems (ECS) to improve both performance and usability within compiler architecture.

By combining insights from these analyses with a system capable of running code across a wide range of platforms, this work lays the groundwork for a new IR; specifically aimed at lowering the barrier to entry into compiler design and empowering more developers to participate in this domain.

## 📚 Thesis Structure

The thesis is organized into the following chapters:

1. **Introduction** - Outlines the challenges in compiler construction and proposes strategies to make it more accessible
2. **Background** - Surveys existing compiler intermediate representations, identifying promising ideas to combine
3. **Motivation** - Introduces Entity Component Systems in detail and examines their application in reducing compiler complexity
4. **Mizu** - Presents Mizu, a lightweight, low-level virtual machine designed for broad portability
5. **Conclusions & Future Work** - Summarizes the work and outlines plans for the Data-Oriented Intermediate Representation (DOIR)

## 🔧 Building the Thesis

This thesis is written in [Typst](https://typst.app/), a modern markup-based typesetting system.

### Prerequisites

- Install Typst: https://github.com/typst/typst#installation

### Compiling

To compile the thesis to PDF:

```bash
typst compile main.typ
```

To watch for changes and automatically recompile:

```bash
typst watch main.typ
```

The compiled PDF will be generated as `main.pdf`.

## 🎯 Key Contributions

This thesis presents several key contributions to the field of compiler infrastructure:

1. **Survey of Compiler IRs** - A comprehensive analysis of existing intermediate representations, including lesser-known designs with untapped potential
2. **ECS-Based Compiler Architecture** - Investigation into using Entity Component Systems as an alternative to traditional visitor patterns and inheritance hierarchies
3. **Mizu Virtual Machine** - A lightweight, portable abstract machine that provides foundation for compile-time evaluation
4. **DOIR Design** - Foundations for a Data-Oriented Intermediate Representation with multilevel support and built-in compile-time evaluation

## 👤 Author

**Joshua Aaron Dahl**  
Master of Science in Computer Science and Engineering  
University of Nevada, Reno  
Advisor: Dr. Frederick C. Harris Jr.

## 📄 License

This work is subject to standard academic copyright provisions. Please cite appropriately if using or referencing this work.

## 📖 Citation

If you use or reference this work, please cite:

```bibtex
@mastersthesis{dahl2025foundations,
  author  = {Dahl, Joshua Aaron},
  title   = {Foundations for a Data Oriented Compiler Infrastructure},
  school  = {University of Nevada, Reno},
  year    = {2025},
  month   = {August},
  type    = {Master's Thesis},
  url     = {https://www.proquest.com/docview/3247618211/abstract/AE7F1866861F4EC1PQ/1?accountid=452&sourcetype=Dissertations%20&%20Theses}
}
```

## 🔗 Related Work

- **MLIR** - Multi-Level Intermediate Representation by LLVM
- **Entity Component Systems** - Data-oriented design pattern for flexible system architecture
- **Mizu** - The lightweight virtual machine presented in Chapter 4

## 📧 Contact

For questions or further information about this research, please refer to the published thesis or contact through the University of Nevada, Reno's Computer Science and Engineering department.
