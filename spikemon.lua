_addon = _addon or {}
_addon.name = 'spikemon'
_addon.version = '1.0'
_addon.author = 'InoUno'
_addon.command = 'sc'

spikemon = spikemon or {}

local startData = {
    hits = 0,
    spike_sum = 0,
    spike_count = {},
    spike_dmg = {}
}

spikemon.data = spikemon.data or startData

spikemon.msg_types = {
    [1] = {
        [1] = { 'Melee Attack', 1 },
        -- [15] = { '(Miss) Melee Attack', 0 },
        [67] = { 'Melee Attack (Crit)', 1 },
    },
}

spikemon.spike_type = {
    [1] = "Blaze Spikes",
    [2] = "Ice Spikes",
    [3] = "Dread Spikes",
    [4] = "Curse Spikes",
    [5] = "Shock Spikes",
    [6] = "Reprisal",
}

function spikemon.print_data()
    local data = spikemon.data

    windower.add_to_chat(7,
        string.format(
            '[spikemon] Hits: %u --- Spikes: %u --- Rate: %.1f%%',
            data.hits, data.spike_sum, data.spike_sum / data.hits * 100
        )
    )

    for spike_type, spike_count in pairs(data.spike_count) do
        local dmg_string = ""
        local spike_dmg_table = data.spike_dmg[spike_type]
        for dmg, dmg_count in pairs(spike_dmg_table) do
            dmg_string = dmg_string .. string.format(
                "[%ux %u] ",
                dmg_count,
                dmg
            )
        end

        windower.add_to_chat(7,
            string.format(
                '[spikemon] %s: %u (%.1f%%) --- %s',
                spikemon.spike_type[spike_type],
                spike_count,
                spike_count / data.hits * 100.0,
                dmg_string
            )
        )
    end
end

function spikemon.action_handler(action)
    -- Check if it's an action we should examine
    if not spikemon.msg_types[action.category] then
        if spikemon.debug then
            -- Debug missing effect handler
            for _, target in pairs(action.targets) do
                for _, effect in pairs(target.actions) do
                    windower.add_to_chat(7,
                        '[spikemon] Skipped effect category ' ..
                        action.category .. ' / ' .. effect.message .. ' with ' .. effect.param)
                end
            end
        end
        return
    end

    -- Handle each target of the action
    local data = spikemon.data

    local player_id = windower.ffxi.get_player().id
    for _, target in pairs(action.targets) do
        if target.id == player_id then
            for _, effect in pairs(target.actions) do
                local msg = spikemon.msg_types[action.category][effect.message]
                if msg then
                    -- Add hit
                    data.hits = data.hits + 1

                    local spike_effect = effect.spike_effect_animation or 0
                    if spike_effect > 0 then
                        data.spike_sum = data.spike_sum + 1
                        data.spike_count[spike_effect] = (data.spike_count[spike_effect] or 0) + 1

                        local spike_dmg_table = data.spike_dmg[spike_effect] or {}
                        spike_dmg_table[effect.spike_effect_param] = (spike_dmg_table[effect.spike_effect_param] or 0) +
                        1
                        data.spike_dmg[spike_effect] = spike_dmg_table

                        spikemon.print_data()
                    end
                elseif spikemon.debug then
                    -- Debug missing effect handler
                    windower.add_to_chat(7,
                        '[spikemon] Skipped effect ' ..
                        action.category .. ' / ' .. effect.message .. ' with ' .. effect.param)
                end
            end
        end
    end
end

windower.register_event('action', spikemon.action_handler)

windower.register_event('addon command', function(command, ...)
    command = command and command:lower()
    if command == 'reset' or command == 'r' then
        spikemon.data = startData
    elseif command == 'print' or command == 'p' or command == 'show' or command == 's' then
        spikemon.print_data()
    elseif command == 'debug' then
        spikemon.debug = not spikemon.debug
        print("[spikemon] Debug is now " .. (spikemon.debug and 'ON' or 'OFF'))
    end
end)
