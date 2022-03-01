# todo

A simple to-do list manager for ComputerCraft, based off the amazing work by sioodmy: https://github.com/sioodmy/todo/

![2022-02-28_20 00 19](https://user-images.githubusercontent.com/45747191/156102630-68fe288c-c738-49da-8a03-4b7a285db13d.gif)

Create and complete tasks easily from the command line.

# Features
- Simple CLI interface
- Set the priority of tasks, so the most important ones come first
- Tag tasks to quickly find what you need from the list

# Commands
*Items are indexed by number, not by name.*
- add <item/s>

    Add any number of items to the to-do list.

- rm <item/s>

    Remove any number of items from the to-do list.

- sort

    Sort the items in the list, those uncomplete and with high priority at the top, those complete and low priority at the bottom.

- priority <item/s> <priority>

    Set a priority from 0 (no priority) to 3 (high priority) to show the most important tasks in the list first when sorted.

- raw

    Output a serialized table of the todo list, allowing external programs to easily work with the program

- list <tag/s> [prios]

    List all the items in the to-do list. If prios is included as a tag, the priorities of the items will be shown next to their names.

- clear

    Empty the to-do list.

- done <item/s>

    Mark any number of items as complete.

- tag <tag> <item/s>

    Tag any number of items with <tag>.

- rmtag <tag> <item/s>

    Remove the tag <tag> from any number of items.

- help [command]

    Display a help message, including some more detailed info on the above commands, when their name is entered.
