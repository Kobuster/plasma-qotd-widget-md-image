# Creating Your Own Fortune File

This guide will walk you through creating a custom quotes file for the Note Shuffle widget. The widget uses the `fortune` file format, which is a simple text-based format for storing a collection of quotes.

## Basic File Format

A fortune file is a plain text file where individual quotes are separated by a line containing only a single percent sign (`%`).

**Key Rules:**

*   Each quote is separated from the next by a line that contains only `%`.
*   There should be no `%` at the very beginning or very end of the file.
*   Your file can contain as many quotes as you like.

### Example: Creating a new quote file

Let's create a new quote file with two quotes to start.

1.  Open a new text file in your favorite editor.
2.  Add your first quote.
3.  Add a `%` on a new line after your first quote.
4.  Add your second quote.

Here is what the content of the file should look like:

```
The only way to do great work is to love what you do.
- Steve Jobs
%
The future belongs to those who believe in the beauty of their dreams.
- Eleanor Roosevelt
```

### Adding More Quotes

To add another quote, simply add a `%` after the last quote and then add your new quote.

```
The only way to do great work is to love what you do.
- Steve Jobs
%
The future belongs to those who believe in the beauty of their dreams.
- Eleanor Roosevelt
%
It is not in the stars to hold our destiny but in ourselves.
- William Shakespeare
```

## Saving and Using Your Custom File

You can save this file anywhere on your system. For example, you could save it in your Documents folder as `~/Documents/Quotes/myquotes.txt`.

Once you have your file saved, right-click on the Note Shuffle widget on your desktop, select "Configure...", and in the "Content Settings", you can browse to and select your custom quotes file.

**Pro-Tip:** If you edit your quote file while the widget is running, you can right-click on the widget and select "Reload Quotes" to see your changes immediately.

## Publicly Available Fortune Files

Many fortune files are available online. You can find collections of quotes on various topics. A good example of a large fortune file is the `actualcookies` file from this GitHub repository: [https://github.com/JKirchartz/fortunes/blob/master/actualcookies](https://github.com/JKirchartz/fortunes/blob/master/actualcookies).

## More Details: The `fortune` Utility

The file format used by this widget is the same as the one used by the classic Unix command-line utility `fortune`. This program, when run in a terminal, displays a random message from a text file.

Many Linux and Unix users add the `fortune` command to their shell's startup script (like `.bashrc` or `.zshrc`) to see a new quote every time they open a new terminal window. It's a fun way to personalize your development environment.

You can typically install it on most Linux distributions using your package manager (e.g., `sudo apt-get install fortune-mod` on Debian/Ubuntu).

By creating your own fortune file, you are tapping into a long-standing tradition of customizable, fun, and informative messages in the Unix/Linux world!
