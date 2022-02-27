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

--the rest of this needs urls from the repo so I'll publish it first