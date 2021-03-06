local todofilepath = TODO_PATH or "/todo/todofile.todo"

local version = 0.2

local args = {...}

--config things
local config = fs.open("/todo/config.cfg", "r")
local config_data = config.readAll()
config.close()
local configarr
local printAfter, autoRemove, autoRemoveTime, autoRemoveComplete
local doneBorderL, doneBorderR, doneString
local colorprio3, colorprio2, colorprio1, colorprio0, colorprioDone, printWithColors
if config_data then
    configarr = textutils.unserialize(config_data) or {}
    printAfter = configarr.printAfter
    autoRemove = configarr.autoRemove
    autoRemoveTime = configarr.autoRemoveTime
    autoRemoveComplete = configarr.autoRemoveComplete
    doneBorderL = configarr.doneBorderL
    doneBorderR = configarr.doneBorderR
    doneString = configarr.doneString
    colorprio3 = configarr.priority3
    colorprio2 = configarr.priority2
    colorprio1 = configarr.priority1
    colorprio0 = configarr.priority0
    colorprioDone = configarr.priorityDone
    printWithColors = configarr.printWithColors
else
    error("Failed to load config file!")
end

if autoRemove then
    local todofile = fs.open(todofilepath, "r")
    local todofile_data = todofile.readAll()
    todofile.close()

    local todofilearr = textutils.unserialize(todofile_data) or {}
    local todofilearr_new = {}
    for i, v in pairs(todofilearr) do
        if os.time(os.date("!*t")) - v.created < autoRemoveTime then
            table.insert(todofilearr_new, v)
        end
    end

    local todofile_new = fs.open(todofilepath, "w")
    todofile_new.write(textutils.serialize(todofilearr_new))
    todofile_new.close()
end

-- Each todo item is a table with the following fields:
--  text: the text of the todo item
--  priority: the priority of the todo item
--    0: no priority
--    1: low priority
--    2: medium priority
--    3: high priority
--  done: whether the todo item is done
--  tags: a list of tags for the todo item
--    tags are case-insensitive
--    done items are automatically tagged "done"

local priorities = {
    none = 0,
    low = 1,
    medium = 2,
    high = 3,
    [0] = "none",
    [1] = "low",
    [2] = "medium",
    [3] = "high"
}

local prioritycolors = {
    none = colorprio0,
    low = colorprio1,
    medium = colorprio2,
    high = colorprio3,
    [0] = colorprio0,
    [1] = colorprio1,
    [2] = colorprio2,
    [3] = colorprio3
}

local function yesnochar(charone, chartwo, exact)
    local _, c = os.pullEvent("char")
    --case insensitive
    if c == charone or c == string.upper(charone) then
        return true
    elseif c == chartwo or c == string.upper(chartwo) then
        return false
    elseif exact then
        print("Please enter "..charone.." or "..chartwo)
        return yesnochar(charone, chartwo, exact)
    end
end

local function new()
    local file = fs.open(todofilepath, "w")
    file.write(textutils.serialize({}))
    file.close()
end

local function add(params)
    local file = fs.open(todofilepath, "r")
    local todos = textutils.unserialize(file.readAll())
    file.close()

    local todo = {
        text = params.text,
        priority = params.priority or 0,
        done = false,
        tags = {},
        created = os.time(os.date("!*t")) --for external scripting
    }

    table.insert(todos, todo)

    file = fs.open(todofilepath, "w")
    file.write(textutils.serialize(todos))
    file.close()
end

local function done(itemNum)
    local file = fs.open(todofilepath, "r")
    local todos = textutils.unserialize(file.readAll())
    file.close()

    if todos[itemNum] then
        if autoRemoveComplete then
            table.remove(todos, itemNum)
        else
            todos[itemNum].done = true
            table.insert(todos[itemNum].tags, "done")
        end
    else
        print("todo item " .. itemNum .. " does not exist")
    end

    file = fs.open(todofilepath, "w")
    file.write(textutils.serialize(todos))
    file.close()
end

local function undone(itemNum)
    local file = fs.open(todofilepath, "r")
    local todos = textutils.unserialize(file.readAll())
    file.close()

    if todos[itemNum] then
        todos[itemNum].done = false
        for i, tag in ipairs(todos[itemNum].tags) do
            if tag == "done" then
                table.remove(todos[itemNum].tags, i)
            end
        end
    else
        print("todo item " .. itemNum .. " does not exist")
    end

    file = fs.open(todofilepath, "w")
    file.write(textutils.serialize(todos))
    file.close()
end

local function rm(itemNum)
    local file = fs.open(todofilepath, "r")
    local todos = textutils.unserialize(file.readAll())
    file.close()

    if not todos[itemNum] then
        print("todo item " .. itemNum .. " does not exist")
        return
    end

    table.remove(todos, itemNum)

    file = fs.open(todofilepath, "w")
    file.write(textutils.serialize(todos))
    file.close()
end

local function sort(inputtable)
    --[[
        The sections are organized as such:

        {
            unfinished: {
                priority: {
                    text
                }
            },
            finished: {
                priority: {
                    text
                }
            }
        }
    ]]
    local file = fs.open(todofilepath, "r")
    local todos = inputtable or textutils.unserialize(file.readAll())
    file.close()

    local unfinished = {}
    local finished = {}

    for _, todo in ipairs(todos) do
        if not todo.done then
            table.insert(unfinished, todo)
        else
            table.insert(finished, todo)
        end
    end

    table.sort(unfinished, function(a, b)
        if a.priority == b.priority then
            return a.text < b.text
        else
            return a.priority > b.priority
        end
    end)

    table.sort(finished, function(a, b)
        if a.priority == b.priority then
            return a.text < b.text
        else
            return a.priority > b.priority
        end
    end)

    --add the items in unfinished, then the finished items
    todos = {}
    for _, todo in ipairs(unfinished) do
        table.insert(todos, todo)
    end
    for _, todo in ipairs(finished) do
        table.insert(todos, todo)
    end
    if inputtable then
        return todos
    end
    --write the new todo file
    file = fs.open(todofilepath, "w")
    file.write(textutils.serialize(todos))
    file.close()
end

local function priority(itemNum, priority)
    local file = fs.open(todofilepath, "r")
    local todos = textutils.unserialize(file.readAll())
    file.close()

    if todos[itemNum] then
        todos[itemNum].priority = priority
    else
        print("todo item " .. itemNum .. " does not exist")
    end

    file = fs.open(todofilepath, "w")
    file.write(textutils.serialize(todos))
    file.close()
end

local function raw()
    local file = fs.open(todofilepath, "r")
    local todos = textutils.unserialize(file.readAll())
    file.close()
    print(textutils.serialize(todos))
end

local function tablecontains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

--takes a list of tags and returns a list of todo items that match, sorted in the same way as sort()
--may also take no arguments, in which case it returns all todo items
local function list(tags, prios)
    term.setTextColor(colors.white)
    local file = fs.open(todofilepath, "r")
    local todos = textutils.unserialize(file.readAll())
    file.close()
    if #todos == 0 then
        print("Your todo list is empty!")
        print("Try adding an item with `todo add`.")
        return
    end
    if tags then
        local matching = {}
        for num, todo in ipairs(todos) do
            local matches = true
            for _, tag in ipairs(tags) do
                if not tablecontains(todo.tags, tag) then
                    matches = false
                    break
                end
            end
            if matches then
                todo.mynum = num
                table.insert(matching, todo)
            end
        end

        todos = matching
    end

    for i = 1, #todos do
        term.setTextColor(colors.white)
        local tickbox = doneBorderL
        if todos[i].done then
            tickbox = tickbox .. doneString
        else
            tickbox = tickbox .. " "
        end
        tickbox = tickbox .. doneBorderR .. " "
        local prio = ""
        if prios then
            prio = "  ["..priorities[todos[i].priority].."]"
        end
        if prios then
            if printWithColors then
                if todos[i].done then
                    term.setTextColor(colorprioDone)
                else
                    term.setTextColor(prioritycolors[todos[i].priority])
                end
            end
            term.write(tickbox..(todos[i].mynum or i) .. ": " .. todos[i].text)
            term.setTextColor(prioritycolors[todos[i].priority])
            print(prio)
        else
            if printWithColors then
                if todos[i].done then
                    term.setTextColor(colorprioDone)
                else
                    term.setTextColor(prioritycolors[todos[i].priority])
                end
            end
            print(tickbox..(todos[i].mynum or i) .. ": " .. todos[i].text)
        end
    end
    term.setTextColor(colors.white)
end

--add a tag to an item
local function tag(itemNum, tag)
    local file = fs.open(todofilepath, "r")
    local todos = textutils.unserialize(file.readAll())
    file.close()

    if todos[itemNum] then
        table.insert(todos[itemNum].tags, tag)
    else
        print("todo item " .. itemNum .. " does not exist")
    end

    file = fs.open(todofilepath, "w")
    file.write(textutils.serialize(todos))
    file.close()
end

local function rmtag(itemNum, tag)
    local file = fs.open(todofilepath, "r")
    local todos = textutils.unserialize(file.readAll())
    file.close()

    if todos[itemNum] then
        if not tablecontains(todos[itemNum].tags, tag) then
            print("todo item " .. itemNum .. " does not have tag " .. tag)
            return
        end
        for i = 1, #todos[itemNum].tags do
            if todos[itemNum].tags[i] == tag then
                table.remove(todos[itemNum].tags, i)
                break
            end
        end
    else
        print("todo item " .. itemNum .. " does not exist")
    end

    file = fs.open(todofilepath, "w")
    file.write(textutils.serialize(todos))
    file.close()
end

local function verify(tt)
    if tt then
        for i=1, #tt do
            if type(tt[i].text) ~= "string" or type(tt[i].tags) ~= "table" or type(tt[i].priority) ~= "number" or type(tt[i].done) ~= "boolean" then
                return false, i
            end
        end
        return true
    end
end

local file = fs.open(todofilepath, "r")
if file then
    local todos = textutils.unserialize(file.readAll())
    file.close()
    if not todos or type(todos) ~= "table" then
        print("Your todo file is in the wrong format. It should be a serialized table.\n")
        print("Path: " .. todofilepath)
        print("Clear file? (y/n)")
        if input == yesnochar("y", "n") then
            new()
            print("Cleared file.")
            return
        else
            print("Todo cannot work with an invalid file. Exiting.")
            return
        end
    else
        local verified, erritem = verify(todos)
        if not verified then
            print("Your todo file contains invalid entries: "..erritem)
            print("Would you like to remove or try to fix this entry? (r/f)")
            if yesnochar("r", "f", true) then
                table.remove(todos, erritem)
                file = fs.open(todofilepath, "w")
                file.write(textutils.serialize(todos))
                file.close()
                print("Removed invalid entry.")
            else
                if tostring(todos[erritem].text) == "nil" then
                    todos[erritem].text = "Invalid item name"
                else
                    todos[erritem].text = tostring(todos[erritem].text)
                end
                todos[erritem].priority = tonumber(todos.priority) or 0
                todos[erritem].done = (todos.done == true)
                if type(todos[erritem].tags) ~= "table" then
                    todos[erritem].tags = {}
                else
                    --if it is a table, make sure it's only strings
                    for i = 1, #todos[erritem].tags do
                        if type(todos[erritem].tags[i]) ~= "string" then
                            todos[erritem].tags[i] = "Invalid tag"
                        end
                    end
                end
                file = fs.open(todofilepath, "w")
                file.write(textutils.serialize(todos))
                file.close()
                print("Fixed invalid entry.")
            end
            return
        end
    end
    todos = nil
else
    new()
end


if args[1] == "add" then
    for i=2, #args do
        add{text = args[i]}
    end
    if #args == 1 then
        print("`add` takes at least 1 argument")
    end
elseif args[1] == "rm" then
    for i=2, #args do
        if tonumber(args[i]) then
            rm(tonumber(args[i]))
        else
            print("invalid argument for `rm`: "..args[i].." (number expected, got "..type(args[i])..")")
        end
    end
    if #args == 1 then
        print("`rm` takes at least 1 argument")
    end
elseif args[1] == "sort" then
    sort()
elseif args[1] == "priority" then
    for i=2, #args - 1 do
        priority(tonumber(args[i]), tonumber(args[#args]))
    end
elseif args[1] == "raw" then
    raw()
elseif args[1] == "list" or not args[1] then
    --make all the other arguments a table
    local tags = {}
    local prios = false
    for i=2, #args do
        if args[i] == "prios" then
            prios = true
        else
            table.insert(tags, args[i])
        end
    end
    list(tags, prios)
elseif args[1] == "clear" then
    new()
elseif args[1] == "done" then
    for i=2, #args do
        if tonumber(args[i]) then
            done(tonumber(args[i]))
        else
            print("invalid argument for `done`: "..args[i].." (number expected, got "..type(args[i])..")")
        end
    end
elseif args[1] == "undone" then
    for i=2, #args do
        if tonumber(args[i]) then
            undone(tonumber(args[i]))
        else
            print("invalid argument for `undone`: "..args[i].." (number expected, got "..type(args[i])..")")
        end
    end
elseif args[1] == "tag" then
    if #args > 2 then
        for i=3, #args do
            if tonumber(args[i]) then
                tag(tonumber(args[i]), args[2])
            else
                print("invalid argument for `tag`: "..args[1].." (number expected, got "..type(args[1])..")")
            end
        end
    else
        print("`tag` takes at least 2 arguments")
    end
elseif args[1] == "rmtag" then
    if #args > 2 then
        for i=3, #args do
            if tonumber(args[i]) then
                rmtag(tonumber(args[i]), args[2])
            else
                print("invalid argument for `rmtag`: "..args[1].." (number expected, got "..type(args[1])..")")
            end
        end
    else
        print("`rmtag` takes at least 2 arguments")
    end
elseif args[1] == "help" then
    if not args[2] then
        print("todo: a simple todo list manager")
        print("usage:")
        print("  todo add <item/s>")
        print("  todo rm <item/s>")
        print("  todo sort")
        print("  todo priority <item/s> <priority>")
        print("  todo raw")
        print("  todo list <tag/s> [prios]")
        print("  todo clear")
        print("  todo done <item/s>")
        print("  todo undone <item/s>")
        print("  todo tag <tag> <item/s>")
        print("  todo rmtag <tag> <item/s>")
        print("  todo help [command]")
        print("\nAdd any command after `help` for more information on that command.")
    else
        if args[2] == "add" then
            print("  todo add <item/s>")
            print("\n  Adds any number of items to the todo list.")
            print("\n Example:")
            print("  todo add \"Buy milk\" \"Buy bread\" Homework")
        elseif args[2] == "rm" then
            print("  todo rm <item/s>")
            print("\n  Removes any number of items from the todo list.")
            print("  Indexed by number, not by text.")
            print("\n Example:")
            print("  todo rm 1 2")
        elseif args[2] == "sort" then
            print("  todo sort")
            print("\n  Sorts the todo list by priority and completeness.")
        elseif args[2] == "priority" then
            print("  todo priority <item/s> <priority>")
            print("\n  Sets the priority of any number of items.")
            print("  Indexed by number, not by text.")
            print("\n Example:")
            print("  todo priority 1 2 3")
            print(" (sets the priority of items 1 and 2 to 3.")
        elseif args[2] == "raw" then
            print("  todo raw")
            print("\n  Prints the todo list in raw format.")
        elseif args[2] == "list" then
            print("  todo list <tag/s> [prios]")
            print("\n  Lists all items in the todo list. If a tag is specified, only items with that tag will be listed.")
            print("  If `done` is specified, only completed items will be listed.")
            print("  If `prios` is specified, items will be listed alongside with their priority.")
            print("\n Examples:")
            print("  todo list")
            print("  todo list done")
            print("  todo list prios")
            print("  todo list tag1 tag2")
        elseif args[2] == "clear" then
            print("  todo clear")
            print("\n  Clears the todo list.")
        elseif args[2] == "done" then
            print("  todo done <item/s>")
            print("\n  Marks any number of items as completed.")
            print("  Indexed by number, not by text.")
            print("\n Example:")
            print("  todo done 1 2")
        elseif args[2] == "undone" then
            print("  todo undone <item/s>")
            print("\n  Marks any number of items as incomplete.")
            print("  Indexed by number, not by text.")
            print("\n Example:")
            print("  todo undone 1 2")
        elseif args[2] == "tag" then
            print("  todo tag <tag> <item/s>")
            print("\n  Adds a tag to any number of items.")
            print("  Indexed by number, not by text.")
            print("\n Example:")
            print("  todo tag \"home\" 1 2")
        elseif args[2] == "rmtag" then
            print("  todo rmtag <tag> <item/s>")
            print("\n  Removes a tag from any number of items.")
            print("  Indexed by number, not by text.")
            print("\n Example:")
            print("  todo rmtag \"home\" 1 2")
        elseif args[2] == "help" then
            print("  todo help [command]")
            print("\n  Prints this help message.")
            print("  If a command is specified, prints help for that command.")
            print("\n Example:")
            print("  todo help")
            print("  todo help add")
        else
            print("unknown command: "..args[2])
        end
    end
elseif args[1] == "version" then
    print("todo v"..version)
else
    print("invalid command: "..args[1])
    print("Try `todo help` for a list of commands.")
end

if printAfter and args[1] ~= "raw" and args[1] ~= "list" and #args > 0 then
    list({}, false)
end