# Low-Level I/O Procedures (Project 6)

## Overview

This project implements low-level input and output procedures in **x86 Assembly (MASM)** to replace standard high-level I/O routines. The program prompts the user to enter **ten signed decimal integers**, validates and converts the raw ASCII input into numeric values, stores them in an array, and then displays the numbers along with their **sum** and **truncated average**.

All numeric input and output is handled manually through custom procedures that perform **ASCII-to-integer** and **integer-to-ASCII** conversions without using built-in helpers such as `ReadInt` or `WriteInt`.

---

## Components

### Included Files

- **Proj6_horne.asm**  
  Main assembly source file containing macros, procedures, and program logic.

- **Irvine32.inc**  
  Provided support library used only for basic string I/O (`ReadString`, `WriteString`) and program termination.

---

## Core Functionality

The program demonstrates how low-level systems handle numeric input and output by:

- Reading user input as raw ASCII strings  
- Validating signed integer input (`+` / `-`)  
- Converting ASCII strings into 32-bit signed integers  
- Performing arithmetic operations on stored values  
- Converting integers back into ASCII strings for display  

All parameters are passed via the **stack**, and all procedures manage their own stack frames.

---

## Key Procedures

### ReadVal

**Purpose:**  
Converts a user-entered ASCII string into a signed 32-bit integer (`SDWORD`).

**Features:**
- Accepts optional `+` or `-` prefixes  
- Ensures all characters are valid digits (`0–9`)  
- Detects numeric overflow beyond 32-bit limits  
- Re-prompts the user on invalid input  

---

### WriteVal

**Purpose:**  
Converts a signed 32-bit integer into an ASCII string and prints it.

**Implementation Details:**
- Uses repeated division by 10 to extract digits  
- Stores digits in reverse using string instructions  
- Handles negative values by adding a `-` prefix  
- Outputs the formatted string using `WriteString`  

---

### fillArray

**Purpose:**  
Prompts the user for ten integers and stores them in an array.

**Additional Features (Extra Credit):**
- Numbers each input line  
- Displays a running subtotal after each valid entry  

---

### printArray

**Purpose:**  
Displays the list of entered integers in a comma-separated format.

---

### sumAvgArray

**Purpose:**  
Calculates and displays:
- The total sum of the array values  
- The truncated average (integer division)  

---

## Requirements Fulfilled

- Manual ASCII-to-integer and integer-to-ASCII conversion  
- Stack-based parameter passing for all procedures  
- Robust input validation and overflow detection  
- Correct handling of signed integers  
- Use of string instructions (`LODSB`, `STOSB`)  
- No reliance on high-level numeric I/O routines  

### Extra Credit Implemented

- Line numbering for user input  
- Running subtotal displayed after each entry  

---

## Implementation Strategy

### Phase 1 – Macro Design

Created reusable macros for string input and output (`mGetString`, `mDisplayString`) to isolate system calls.

### Phase 2 – Conversion Logic

Implemented `ReadVal` and `WriteVal` using arithmetic-based conversion algorithms:
- Multiply-by-10 accumulation for reading  
- Divide-by-10 digit extraction for writing  

### Phase 3 – Array and Math Operations

Developed procedures to store values, compute sums, and calculate truncated averages using signed arithmetic.

---

## Output Behavior

1. Displays an introduction and instructions  
2. Prompts the user to enter 10 signed integers  
3. Rejects invalid or out-of-range input with an error message  
4. Displays a running subtotal after each valid entry  
5. Prints all entered numbers  
6. Displays the total sum and truncated average  
7. Terminates cleanly  

---

## Personal Contribution

All procedures and logic in the `.code` section were implemented from scratch, including:

- Stack-frame management using `EBP`  
- Overflow detection using CPU flags  
- Signed arithmetic handling  
- Manual string parsing and formatting  
- Extra credit functionality for enhanced output  

This project provided hands-on experience with **low-level I/O**, **stack-based calling conventions**, and the internal mechanics behind high-level language abstractions.

---

## License

This project was completed as part of **CS271 at Oregon State University** and is intended for educational use only.

---

## Acknowledgments

Portions of this README were developed with the assistance of ChatGPT by OpenAI.