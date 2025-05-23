# zig-text-editor

A simple text editor implemented in Zig, inspired by the functionality of Vim. This project serves as a learning exercise in building a text editor from scratch using the Zig programming language.

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

## Building the Project

To build the text editor, navigate to the project directory and run:

```
zig build
```

## Running the Editor

After building, you can run the text editor with:

```
./zig-text-editor
```

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any enhancements or bug fixes.

## License

This project is licensed under the MIT License. See the LICENSE file for details.