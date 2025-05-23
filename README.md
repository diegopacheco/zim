# ZIM

A simple text editor implemented in Zig, inspired by the functionality of Vim. This project serves as a learning exercise in building a text editor from scratch using the Zig programming language.

<img src="zim.png" width="200" alt="ZIM">

## Features

- **Normal Mode**: Navigate and manipulate text without inserting characters.
- **Insert Mode**: Type and edit text directly.
- **Command Mode**: Execute commands for saving and quitting (:q, :w :i)
- **Text Buffer Management**: Efficiently manage the text being edited.
- **Terminal UI**: Render the text buffer and handle user input in the terminal.

## Build

To build the text editor, navigate to the project directory and run:

```
zig build
```

## Running

After building, you can run the text editor with:
```
 ./zig-out/bin/zim
```
or just do:
```
zig build run
```