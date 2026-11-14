-- Load Genie only if it has been built for this compositor.
local geniePath = os.getenv('HOME') .. '/.local/share/macshell-plugins/hyprglass.so'
local genieFile = io.open(geniePath, 'r')
if genieFile then
    genieFile:close()
    hl.plugin.load(geniePath)
    if hl.plugin.hyprglass then hl.plugin.hyprglass.config({ enabled = false }) end
end
-- Mackintosh Rice window shortcuts. No monitor or GPU settings are changed.
local hidden = {}
hl.on('window.move_to_workspace', function(w, ws)
    if w and ws and ws.name == 'special:minimized' then table.insert(hidden, w.address) end
end)
local function minimize()
    local w = hl.get_active_window()
    if not w or not w.workspace then return end
    table.insert(hidden, w.address)
    if hl.plugin.hyprglass and hl.plugin.hyprglass.minimize('address:' .. w.address) == 'ok' then return end
    hl.dispatch(hl.dsp.window.move({ window = w, workspace = 'special:minimized', follow = false }))
end
local function restore()
    if hl.plugin.hyprglass and hl.plugin.hyprglass.restore() == 'ok' then return end
    while #hidden > 0 do
        local addr = table.remove(hidden)
        local w = hl.get_window('address:' .. addr)
        if w and w.mapped and w.workspace and w.workspace.name == 'special:minimized' then
            hl.dispatch(hl.dsp.window.move({ window = w, workspace = hl.get_active_workspace(), follow = true }))
            return
        end
    end
end
pcall(hl.unbind, 'SUPER + M')
pcall(hl.unbind, 'SUPER + TAB')
hl.bind('SUPER + M', minimize)
hl.bind('SUPER + TAB', hl.dsp.exec_cmd('qs -c MacShell ipc call switcher next'))
hl.bind('SUPER + code:43', minimize)
hl.bind('SUPER + SHIFT + code:43', restore)
