--[[ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

                         TODO INSTALLER
                          VERSION 0.1

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -]]

local function download(url, file, noerr)
    local content = http.get(url)
    if not content then
        if not noerr then
            error("Failed to access resource " .. url)
        else
            return false
        end
    end
    content = content.readAll()
    local fi = fs.open(file, "w")
    fi.write(content)
    fi.close()
end

local function toArr(filePath)
    local fileHandle = fs.open(filePath, "r")
    local log
    if fileHandle then
        log = {}
        local line = fileHandle.readLine()
        while line do
            table.insert(log, line)
            line = fileHandle.readLine()
        end
        fileHandle.close()
        return log
    else
        return false
    end
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function yesnochar(charone, chartwo)
    local _, c = os.pullEvent("char")
    --case insensitive
    if c == charone or c == string.upper(charone) then
        return true
    elseif c == chartwo or c == string.upper(chartwo) then
        return false
    else
        print("Please enter "..charone.." or "..chartwo)
        return yesnochar()
    end
end

while true do
    term.clear()
    term.setCursorPos(1, 1)
    print("TODO Installer v0.1")
    print("")
    print("1. Install todo")
    print("2. Update todo")
    print("3. Exit")

    local _, option = os.pullEvent("char")

    if option == "1" then
        local installdir = "/todo/"
        print("Downloading todo to "..installdir.."...")
        download("https://raw.githubusercontent.com/Minater247/todo/master/todo.lua", installdir.."todo.lua")
        download("https://raw.githubusercontent.com/Minater247/todo/master/.version", installdir..".version", true)
        print("Done.")
        print("Add todo to universal path? (y/n)")
        if yesnochar("y", "n") then
            print("Adding todo to universal path...")
            local file = fs.open("/startup", "a")
            file.writeLine("shell.setPath(shell.path()..\":/todo/\")")
            file.close()
            print("Added to path.")
        end
        print("Do you want a custom todofile path? (y/n)")
        local todofile = "/todo/todofile.todo"
        local validpath = false
        if yesnochar("y", "n") then
            while not validpath do
                print("Please enter the path to the todofile:")
                todofile = read()
                if fs.exists(todofile) then
                    print("File already exists. Overwrite? (y/n)")
                    if yesnochar("y", "n") then
                        validpath = true
                    else
                        validpath = false
                    end
                else
                    validpath = true
                end
            end
            local file = fs.open("/startup", "a")
            file.writeLine("TODO_PATH = \""..todofile.."\"")
            file.close()
        end
        print("Done.")

        print("Installation complete.")
        print("Enjoy!")
    elseif option == "2" then
        print("Fetching current version...")
        local con = true
        local f
        local todover
        local instver
        local nf
        local nft
        local ntodover
        local ninstver
        if not fs.isDir("/todo/") then
            con = false 
        end
        if fs.exists("/todo/.version") and con then
            f = toArr("/todo/.version")
            todover = tonumber(f[1])
            instver = tonumber(f[2])
            nf = http.get("https://raw.githubusercontent.com/Minater247/todo/master/.version").readAll()
            nft = split(nf, "\n")
            ntodover = tonumber(nft[1])
            ninstver = tonumber(nft[2])
            if ninstver > instver then
                print("This version of the installer is outdated. Please download a new version to continue.")
                print("Download now? [y/n]")
                local _,inp = os.pullEvent("char")
                if inp == "y" then
                    download("https://raw.githubusercontent.com/Minater247/todo/master/todo_installer.lua", "/todo/installer")
                    fs.delete("/todo/todo_installer.lua")
                    fs.move("/todo/installer", "/todo/todo_installer.lua")
                    print("Updated installer downloaded. Local path is at /todo/todo.lua")
                    print("Updating local version file...")
                    local filelines = toArr("/todo/.version")
                    filelines[2] = ninstver
                    local ff = fs.open("/todo/.version", "w")
                    for i=1,#filelines,1 do
                        ff.writeLine(filelines[i])
                    end
                    print("Updated local version.")
                    if ntodover > todover then
                        print("Please restart the installer to complete the update.")
                    end
                    ff.close()
                    print("Exiting.")
                    print("Press any key to continue...")
                    os.pullEvent("char")
                    error() --not an actual error, displays nothing to user. Just used to quit.
                end
            else
                print("Installer version is current.")
                if ntodover > todover then
                    print("An update is available! "..todover.." -> "..ntodover)
                    print("Downloading files from github...")
                    download("https://raw.githubusercontent.com/Minater247/todo/master/todo.lua", "/todo/todo.lua")
                    print("Update complete.")
                    print("Updating local version info...")
                    local filelines = toArr("/todo/.version")
                    filelines[1] = ntodover
                    local ff = fs.open("/todo/.version", "w")
                    for i=1,#filelines,1 do
                        ff.writeLine(filelines[i])
                    end
                    print("Updated local version.")
                    ff.close()
                    print("Wrapping up...")
                    --used to be code here
                    print("Done.")
                    print("Press any key to continue")
                    os.pullEvent("key")
                else
                    print("todo version is current.")
                    print("Press any key to continue...")
                    os.pullEvent("key")
                end
            end
        else
            print("Failed to check version.")
            print("Press any key to continue.")
            os.pullEvent("key")
        end
    elseif option == "3" then
        return
    end
end