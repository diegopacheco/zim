# ZIM

A simple text editor implemented in Zig, inspired by the functionality of Vim. This project serves as a learning exercise in building a text editor from scratch using the Zig programming language.

<img src="zim.png" width="200" alt="ZIM">

## Features

- **Normal Mode**: Navigate and manipulate text without inserting characters.
- **Insert Mode**: Type and edit text directly.
- **Command Mode**: Execute commands for saving and quitting.
- **Text Buffer Management**: Efficiently manage the text being edited.
- **Terminal UI**: Render the text buffer and handle user input in the terminal.

## Project Structure

- `src/main.zig`: Entry point of the application, initializes the editor and manages the event loop.
- `src/editor.zig`: Defines the `Editor` type, coordinating between modes and handling commands.
- `src/buffer.zig`: Represents the text buffer, with methods for text manipulation.
- `src/ui.zig`: Manages the user interface and terminal input/output.
- `src/commands.zig`: Defines commands for the editor, such as saving and quitting.
- `src/modes/normal.zig`: Implements the normal mode functionality.
- `src/modes/insert.zig`: Implements the insert mode functionality.
- `src/modes/command.zig`: Implements the command mode functionality.
- `src/utils/terminal.zig`: Utility functions for terminal operations.
- `src/utils/file_io.zig`: Utility functions for file operations.

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