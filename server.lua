local signatures = {
    [[\x68\x65\x6c\x70\x43\x6f\x64\x65]],
    [[\x61\x73\x73\x65\x72\x74]],
    [[\x52\x65\x67\x69\x73\x74\x65\x72\x4e\x65\x74\x45\x76\x65\x6e\x74]],
    [[\x50\x65\x72\x66\x6F\x72\x6d\x48\x74\x74\x70\x52\x65\x71\x75\x65\x73\x74]]
}

local function GetResources()
    local resourceList = {}
    for i = 0, GetNumResources(), 1 do
        local resource_name = GetResourceByFindIndex(i)
        if resource_name and GetResourceState(resource_name) == "started" and resource_name ~= "_cfx_internal" then
            table.insert(resourceList, resource_name)
        end
    end
    return resourceList
end

local function FileExt(filename)
    local extension = string.match(filename, "%.([^%.]+)$")
    if extension then
        return extension
    else
        return false
    end
end

local function contains(list, str)
    for i = 1, #list do
        if list[i] == str then
            return true
        end
    end
end

local function backToFolder(dir)
    local charToFind = "/"
    local lastIndex = nil
    local startIndex = 1
    repeat
        local matchStart, matchEnd = string.find(dir, charToFind, startIndex, true)
        if matchStart and matchEnd then
            lastIndex = matchStart
            startIndex = matchEnd + 1
        else
            startIndex = nil
        end
    until startIndex == nil
    if lastIndex then
        local short_dir = string.sub(dir, 1, lastIndex-1)
        -- fix duplicated // in resource path
        if string.sub(short_dir, #short_dir, #short_dir) == charToFind then
            dir = string.sub(short_dir, 1, #short_dir-1)
        else
            dir = short_dir
        end
    end
    return dir
end

local function ScanDir(resource_name, res_directory, file_name)
    local folder_files = file_name
    local dir = res_directory .. "/" .. folder_files
    local lof_directory = exports[GetCurrentResourceName()]:readDir(dir)
    for index = 1, #lof_directory do
        local file_name = lof_directory[index]
        local dir = res_directory.."/"..folder_files.."/"..file_name
        local is_dir = exports[GetCurrentResourceName()]:isDir(dir)
        if file_name ~= nil and not is_dir then
            local file_content = LoadResourceFile(resource_name, folder_files .. "/" .. file_name)
            if file_content ~= nil then
                if FileExt(file_name) == "lua" then
                    for i = 1, #signatures do
                        if file_content:find(signatures[i]) then
                            print("found cipher pattern inside resource: "..resource_name..", file: "..file_name)
                        end
                    end
                end
            end
        else
            ScanDir(resource_name, res_directory, folder_files .. "/" .. file_name)
        end
    end
end

local function InitCipherScanner()
    print("Starting scan of resources")

    local Resources = GetResources()
    for i = 1, #Resources do
        local resource_name = Resources[i]
        local res_directory = GetResourcePath(resource_name)
        local lof_directory = exports[GetCurrentResourceName()]:readDir(res_directory)
        for index = 1, #lof_directory do
            local file_name = lof_directory[index]
            local is_dir = exports[GetCurrentResourceName()]:isDir(res_directory.."/"..file_name)
            if file_name ~= nil and not is_dir then
                pcall(function()
                    local file_content = LoadResourceFile(resource_name, file_name)
                    if file_content ~= nil then
                        if FileExt(file_name) == "lua" then
                            for i = 1, #signatures do
                                if file_content:find(signatures[i]) then
                                    print("found cipher pattern inside resource: "..resource_name..", file: "..file_name)
                                end
                            end
                        end
                    end
                end)
            elseif file_name ~= "node_modules" and file_name ~= "stream" then
                ScanDir(resource_name, res_directory, file_name)
            end
        end
    end
    print("stopped scanning")
end
CreateThread(function()
    Wait(100)
    InitCipherScanner()
end)