# Quote of the Day Plasmoid

A KDE Plasma widget that displays random quotes from a directory. Supports both Plasma 5 and Plasma 6.

I wanted something like this for a while, figured I'd just use an LLM to generate one - vibe coded with a bit of review of the shell scripts. Does what I need it to do. You can change the quotes file to any text file formatted as a `fortune` file.

![Quote of the Day Widget on Desktop](img/desktop_widget.png)

<details>
<summary>Installation from KDE Store</summary>

1.  Right-click on your desktop, and select "Enter Edit Mode".
    ![Enter Edit Mode](img/edit_desktop_context_menu.png)

2.  Click on "Add Widgets".
    ![Add Widgets](img/add_or_manage_widgets.png)

3.  Click on "Get New Widgets" and select "Download New Plasma Widgets".
    ![Get New Widgets](img/get_new_widget_button.png)
    ![Download New Widgets](img/get_new_widget_choices.png)

4.  Search for "Quote of the Day" and click "Install".
    ![Search for Widget](img/widget_search.png)

5. Now, you should be able to search for the widget locally and add it to your desktop.
    ![Install Widget](img/installed_qotd.png)

</details>

<details>
<summary>Manual Installation</summary>

```bash
./install.sh
```

The installer auto-detects your Plasma version and installs the widget.

**Note for Plasma 6 users**: If you're manually installing the `.plasmoid` file using `kpackagetool6`, you **must** specify the package type:
```bash
kpackagetool6 -t Plasma/Applet -i org.kde.prajjwal.quotewidget-plasma6.plasmoid
```
See [PLASMA6_INSTALLATION.md](PLASMA6_INSTALLATION.md) for more details.

</details>

## Usage

1.  **Add the Widget**: Right-click on your desktop and select "Add Widgets...". Search for "Quote of the Day" and drag it to your desired location on the desktop.
2.  **Resize and Place**: You can resize the widget by dragging its edges and move it to any position on your desktop.
3.  **Default Settings**: The widget comes with default settings, so you can start using it right away.

## Viewing Quotes in Context

The widget provides a full-featured context viewer for exploring your quotes file as a collection:

-   **View in Context**: Click the "View in Context" button (bottom-right of the widget) or select it from the right-click context menu to launch the full viewer. This displays the currently shown quote along with surrounding quotes from your file.

<details>
<summary>Context Viewer Features</summary>

The context viewer window includes several navigation and management tools:

-   **Navigation**: Use the First, Previous, Next, and Last buttons to browse through all quotes.
-   **Jump to Page**: Enter a page number in the "Page..." field and click "Go" to jump directly to any page.
-   **Bookmarks**: Mark your favorite quotes with custom notes (e.g., "Chapter 1", "Inspiring"), then access them anytime from the bookmarks menu. This is particularly useful when using the widget with structured content like poems or chapters rather than random quotes.
-   **Edit File**: If you're using a custom quotes file, click the "Edit" button to open it in your default text editor. This makes it easy to add new quotes or make updates without navigating your filesystem.

</details>

## Configuration

If you want to customize the widget, right-click on it and select "Configure...".

![Configure Widget](img/context_menu.png)

This will open the configuration window:

![Configuration Window](img/qotd_config.png)

<details>
<summary>Appearance Settings</summary>

-   **Background Opacity**: Adjust the transparency of the widget's background (0-100%).
-   **Font**: Change the font family, style, and size.
-   **Colors**: Customize the text, outline, and background colors.

</details>

<details>
<summary>Content Settings</summary>

-   **Quotes File**: You can use your own quotes file. The file must be in the `fortune` format. For detailed instructions, see [Creating Your Own Fortune File](creating_quotes.md). You can also download one from a public repository like [this one](https://github.com/JKirchartz/fortunes/blob/master/actualcookies).
-   **Rotation Interval**: Set the time between quote changes, from 10 seconds to 24 hours (default is 2 minutes).

</details>

## Uninstallation

To remove the widget, run the uninstallation script:

```bash
./uninstall.sh
```

## Debugging

If you encounter any issues, you can use the following scripts for debugging:

```bash
./debug.sh       # Show diagnostics
./test-widget.sh # Test in window
./watch-logs.sh  # Monitor logs
./validate.sh    # Validate package
```

## License

GPL v3
