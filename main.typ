#import "@preview/muchpdf:0.1.0": muchpdf

// Define conditional content
#let draft = true

// set document settings
#let default_margin(body) = page(margin: (
  top: 1in,
  bottom: 1.25in,
  left: 1.5in,
  right: 1in,
), body)
#set page(
  paper: "us-letter",
  header: context [ 
    #if draft { "Draft "; datetime.today().display("[month repr:long] [day], [year]")  } else { "" }
  ]
)
#set par(
  first-line-indent: (amount: 8mm, all: true),
  spacing: 22pt,
)
#set text(size: 12pt)
#show: default_margin

// Helper functions/macros
#let note(body) = if draft { 
  markup("†", body, fill: green) 
}
#let fix(body) = if draft { 
  rect[fill: red][body] 
}
#let code(body) = text(tt, body)

#let embed_pdf(path) = {
  set page(
    margin: (
      top: 0in,
      bottom: 0in,
      left: 0in,
      right: 0in,
    )
  )
  pagebreak()
  muchpdf(read(path, encoding: none), width: 100%)
  show: default_margin
}




// Title and front matter
#include "titlePage.typ"
#include "copyright.typ"

#if draft {
  // Optional ToDo list
  include "todo.typ"
}

// Committee page as embedded PDF
#embed_pdf("figures/committee.pdf")

#set page(
  margin: (
    top: 1in,
    bottom: 1.25in,
    left: 1.5in,
    right: 1in,
  ),
  header: context [ 
    #if draft { "Draft "; datetime.today().display("[month repr:long] [day], [year]") } else { "" }
    #h(1fr)
    #counter(page).display("i")
  ]
)
// Abstract, dedication, acknowledgments
#include "abstract.typ"
#include "dedication.typ"
#include "acknowledgements.typ"

// TOC, List of Tables, List of Figures
#pagebreak()
#{
  show heading: none
  heading(numbering: none)[Contents]
}
#outline(depth: 2)

#pagebreak()
#{
  show heading: none
  heading(numbering: none)[List of Tables]
}
#outline(
  title: [List of Tables],
  target: figure.where(kind: table),
)

#pagebreak()
#{
  show heading: none
  heading(numbering: none)[List of Figures]
}
#outline(
  title: [List of Figures],
  target: figure.where(kind: image),
)

// Main matter
#set page(
  header: context [ 
    #if draft { "Draft "; datetime.today().display("[month repr:long] [day], [year]") } else { "" }
    #h(1fr)
    #counter(page).display("1")
  ]
)

#let chapter_include(name) = {
  pagebreak()
  include name
}
#let chapters(body) = {
  set heading(numbering: "1.1", 
    supplement: {
      level => if level == 1 { "Chapter" } else { "Section" }
    }
  )
  body
}
#show: chapters

#chapter_include("chapter1.typ")
#chapter_include("chapter2.typ")
#chapter_include("chapter3.typ")
#chapter_include("chapter4.typ")
#chapter_include("chapter5.typ")
#chapter_include("chapter6.typ")

// Bibliography
#pagebreak()
#bibliography("bib.bib", title: "References")

// Appendices
#pagebreak()
#set heading(numbering: none)
= Appendices
#let appendix(body) = {
  set heading(numbering: "A", supplement: [Appendix])
  counter(heading).update(0)
  body
}
#show: appendix

#include "appendixA.typ"
