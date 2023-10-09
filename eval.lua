require 'vis'

local eval_shell_map = {}
function evalmap(name, shell)
    eval_shell_map[name] = shell
end
vis:command_register('evalmap', function(argv)
    local name = table.remove(argv, 1)
    local shell = table.concat(argv, ' ')
    evalmap(name, shell)
end, 'Map interpreter commands `evalmap <language> <interpreter>`')

local evaltimeout = 2
vis:option_register('evaltimeout', 'number', function(value)
    evaltimeout = value
end, 'Code block evaluation timeout in seconds (default: 2)')

local function get_block(selection)
    local range, shell, resultpos = nil, nil, nil
    local cursor_line, cursor_col = selection.line, selection.col
    for i = selection.line, 0, -1 do
        if vis.win.file.lines[i]:match('^````*[^`]') then
            shell = vis.win.file.lines[i]:match('[^`]+')
            selection:to(i+1, 0)
            range = selection.range
            break
        end
    end
    for i = selection.line, #vis.win.file.lines, 1 do
        if vis.win.file.lines[i]:match('^```') then
            selection:to(i, 0)
            range.finish = selection.pos
            selection:to(i, #vis.win.file.lines[i])
            resultpos = selection.pos + 1
            break
        end
    end
    selection:to(cursor_line, cursor_col)
    return range, shell, resultpos
end

local function indent(str, indent)
    return indent .. string.gsub(
        string.gsub(str, '\n', '\n' .. indent),
        indent .. '$', '')
end
local function with_newline(str)
    if string.sub(str, -1, -1) == '\n' then
        return str
    else
        return str .. '\n'
    end
end

local function replace_output(window, resultpos, resultcode, new_output)
    local cursor_line, cursor_col = window.selection.line,
                                    window.selection.col
    local force_replace_cursor = false
    if window.selection.pos == resultpos then force_replace_cursor = true end
    if window.file:content(resultpos, 13) == '\n::: {.output' then
        local len = nil
        for i = resultpos + 13, window.file.size, 1 do
            if window.file:content(i, 5) == '\n:::\n' then
                len = i+5 - resultpos
                break
            end
        end
        if len ~= nil then window.file:delete(resultpos, len) end
    end
    if new_output == nil then new_output = ''
        else new_output = indent(with_newline(new_output), '    ') end
    window.file:insert(resultpos, string.format(
        '\n::: {.output exit_code="%i"}\n%s:::\n',
        resultcode, new_output))
    if force_replace_cursor then
        window.selection:to(cursor_line, cursor_col) end
    if window.selection.pos == nil then
        window.selection:to(cursor_line, cursor_col) end
    if window.selection.pos == nil then
        window.selection:to(#window.file.lines, cursor_col) end
    window:draw()
end

local function eval_block()
    local range, shell, resultpos = get_block(vis.win.selection)
    if range == nil then
        vis:info('Unable to locate any code block above cursor position')
        return false
    elseif shell == nil then
        vis:info('Unable to parse interpreter name on line ' .. from-1)
        return false
    end
    if eval_shell_map[shell] ~= nil then shell = eval_shell_map[shell] end
    local status, out, err = vis:pipe(vis.win.file, range, string.format(
        'timeout --verbose %i %s 2>&1',
        evaltimeout, shell))
    -- I have no idea why status is 256 times the actual exit status,
    -- but this division seems to fix it.
    replace_output(vis.win, resultpos, status/256, out)
    return true
end

vis:map(vis.modes.NORMAL, 'g<Enter>', eval_block,
    'Evaluate the next markdown code block above the primary cursor')
