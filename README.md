# MetaSheets

MetaSheets is a language workbench for spreadsheet-based domain-specific languages (DSLs).
It enables language designers to define the syntax, semantics, and validation rules of a DSL directly within a spreadsheet, and automatically generates abstract syntax trees (ASTs), real-time validation, and editor feedback inside the spreadsheet environment.

MetaSheets combines the familiarity of spreadsheets with the structure of formal language engineering, allowing domain experts to create models without requiring traditional programming skills.

## Features

* Spreadsheet-based DSL definition using the Meta Grammar Language (MGL)
* Grammar-driven parsing of cell data into typed ASTs
* Real-time error checking and feedback using Rascal meta-programming
* Extensible type system and semantic analysis hooks

## Architecture

MetaSheets integrates three main components:

* **Rascal** – used for grammar definitions, parsing, and AST construction
* **Salix** – provides reactive communication between the Rascal backend and the spreadsheet interface
* **Handsontable** – serves as the interactive spreadsheet grid

Together, these components create a reactive, grammar-driven spreadsheet environment in which each cell edit triggers parsing and validation in real time.

## Example Use Cases 

* Form languages (e.g., questionnaire DSLs)
* Logic sheets (e.g., PLC or control system logic)
* Constraint-based puzzles (e.g., Sudoku models)
* 
Example DSLs and demonstration sheets can be found under:
MetaSheets/src/sheetdsl/demo/

---
Created as part of the master's thesis *“MetaSheets: Language Workbench Support for Spreadsheet-Based DSLs.”*
