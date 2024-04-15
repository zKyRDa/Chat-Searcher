script_name("Chat Searcher")
script_author("KyRDa")
script_version('1.0.0')

require 'lib.moonloader'
local inicfg = require 'inicfg'

local cfg = inicfg.load({
    settings = {
        reminder = true,
        command = "search",
        path = os.getenv("USERPROFILE") .. "\\Documents\\GTA San Andreas User Files\\SAMP\\chatlog.txt",
        page_border = 30
    }
}, 'Chat Searcher')
inicfg.save(cfg, 'Chat Searcher.ini')


function main()
    while not isSampAvailable() do wait(0) end

    sampRegisterChatCommand(cfg.settings.command, Search)
    sampRegisterChatCommand("searchset", Settings)

    if cfg.settings.reminder then sampAddChatMessage('{62C58D}[Chat Searcher]{FFFFFF}: /searchset /'..cfg.settings.command..' {param}', -1) end

    wait(-1)
end


function string.nlower(s) -- from Strings.lua
	for i = 192, 223 do
		s = s:gsub(string.char(i), string.char(i + 32))
	end
	s = s:gsub(string.char(168), string.char(184))
	return string.lower(s)
end

function Search(arg)
    arg = string.nlower(arg):gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") -- regex character escaping and lowering cirillic

    local search_result = {}

    for line in io.lines(cfg.settings.path) do
        if string.nlower(line):find(arg) then
            table.insert(search_result, line)
        end
    end

    if next(search_result) == nil then
        table.insert(search_result, 'Nothing found :(')
    end


    lua_thread.create(function()
        local page = 1
        local limit_page = math.ceil(#search_result / 30)
        
        
        ::ShowDialog::
        sampShowDialog(
            558630,
            'Search result, page ¹'..page ,
            table.concat(search_result, '\n{FFFFFF}', (page - 1) * cfg.settings.page_border + 1, math.min(page * cfg.settings.page_border, #search_result)),
            page <= 1 and "Close" or 'page '.. page - 1 .. ' <<',
            page >= limit_page and "Close" or ">> page ".. page + 1,
            0
        )

        while sampIsDialogActive() do wait(0)
            if wasKeyPressed(0x1B) then
                return
            end
        end

        local button = select(2, sampHasDialogRespond(558630))
        
        if button == 1 and page ~= 1 then
            page = page - 1
            goto ShowDialog
        elseif button == 0 and page < limit_page then
            page = page + 1
            goto ShowDialog
        end
    end)
end

function Settings()
    lua_thread.create(function()
        ::ShowDialog::

        local settings = {"Reminder of commands\t", cfg.settings.reminder and '{008000}' or '{ff0000}', tostring(cfg.settings.reminder),
            "\nSearch command\t{ffa500}", cfg.settings.command, "\nPath to chatlog\t{62C58D}chatlog.txt", 
            "\nItem limit in search result\t{ff4c5b}", cfg.settings.page_border, '\n{8b0000}Reset settings'}
        
        sampShowDialog(
            558631,
            'Chat Searcher settings',
            table.concat(settings),
            'Close',
            'Select',
            4
        )

        while sampIsDialogActive() do wait(100) end

        local _, button, list, _ = sampHasDialogRespond(558631)
        local values = {"command", "path", "page_border"}

        if button == 1 then
            if list == 0  then
                cfg.settings.reminder = not cfg.settings.reminder
            elseif list == 4 then
                cfg.settings = {
                    reminder = true,
                    command = "search",
                    path = os.getenv("USERPROFILE") .. "\\Documents\\GTA San Andreas User Files\\SAMP\\chatlog.txt",
                    page_border = 30
                }
                inicfg.save(cfg, 'Chat Searcher.ini')
            else
                sampShowDialog(
                    558632,
                    'Chat Searcher setting',
                    "{FFFFFF}Current value:\t{62C58D}"..cfg.settings[values[list]].."\n {808080}Set new values",
                    'Close',
                    'Change',
                    1
                )

                while sampIsDialogActive() do wait(100) end

                local _, button, _, input = sampHasDialogRespond(558632)
                
                if button == 1 then
                    cfg.settings[values[list]] = input

                    inicfg.save(cfg, 'Chat Searcher.ini')

                    if list == 1 then
                        sampRegisterChatCommand(cfg.settings.command, Search)
                    end
                end
            end
            goto ShowDialog
        end
    end)
end