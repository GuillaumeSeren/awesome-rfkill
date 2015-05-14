-- ---------------------------------------------
-- RfKill Widget for Awesome WM
-- @author Guillaume Seren
-- source  https://github.com/GuillaumeSeren/rfkillWidget
-- file    init.lua
-- Licence GPLv3
--
-- Main RfKill widget lib.
-- ---------------------------------------------

-- Rfkill Widget Class
rfkillWidget = {}

-- This mute follow the default behavior of XF86WLAN,
-- but extend it to other capable devices.
function rfkillWidget.rfkillMute()
    local rfkillState = rfkillWidget.getRfkillBlockedState()
    local devices = rfkillWidget.getRfkillDevices()
    local excludedDevices = rfkillWidget.getExcludedDevices()
    -- filter devices list
    devices = rfkillWidget.getFilteredDevices(devices, excludedDevices)
    if rfkillState == 'OFF' then
        rfkillWidget.setRfkillUp(devices)
        -- awful.util.spawn("sudo rfkill unblock bluetooth")
        -- awful.util.spawn("sudo rfkill unblock wwan")
    else
        rfkillWidget.setRfkillDown(devices)
        -- awful.util.spawn("sudo rfkill block bluetooth")
        -- awful.util.spawn("sudo rfkill block wwan")
    end
    -- awful.util.spawn("sudo rfkill block all")
    -- alert('rfkillMute', 'RfKill: '..rfkillState)
end

function rfkillWidget.setRfkillUp(devices)
    -- The problem is simple:
    -- By default XF86WLAN MUTE/UNMUTE Wlan *only*
    -- I think it should be easier to have 1 global state based on wlan 
    -- after that we should display a menu to activate or not each de
    for id, device in ipairs(devices) do
        awful.util.spawn("sudo rfkill unblock "..device)
    end
    return nil
end

function rfkillWidget.setRfkillDown(devices)
    for id, device in ipairs(devices) do
        awful.util.spawn("sudo rfkill block "..device)
    end
    return nil
end

function rfkillWidget.getFilteredDevices(devices, excludedDevices)
    local filteredDevices = {}
    for id, device in ipairs(devices) do
        if rfkillWidget.notInTable(excludedDevices, device) then
            -- We don't want occurences from exclusion list
            -- alert('getFilteredDevices', device)
            table.insert(filteredDevices, device)
        end
    end
    return filteredDevices
end

function rfkillWidget.getExcludedDevices()
    local excludedDevices = {}
    -- May be usefull to control excluded
    table.insert(excludedDevices, 'wlan')
    return excludedDevices
end

function rfkillWidget.getRfkillDevices()
    local devices = {}
    local rfkillDevicesCmd = io.popen("sudo rfkill list all | grep -v 'blocked' | sed -e \"s/^.:.*: //g\"")
    for line in rfkillDevicesCmd:lines() do
        line = rfkillWidget.getRfkillDevicesTranslation(line)
        table.insert(devices, line)
        -- alert('getRfkillDevices', 'line:'..line)
    end
    rfkillDevicesCmd:close()
    return devices
end

-- function rfkillWidget.getRfkillWidget()
--     return '✈'
-- end

-- Return the actual needed name to block/unblock
function rfkillWidget.getRfkillDevicesTranslation(name)
    local devicesName = {}
    devicesName['Bluetooth']    = 'bluetooth'
    devicesName['Wireless WAN'] = 'wwan'
    devicesName['Wireless LAN'] = 'wlan'
    return devicesName[name]
end

function rfkillWidget.getRfkillBlockedState()
    local output = ''
    -- If something is blocked lets say everything is, *simpler is better*
    local rfkillStatusCmd = io.popen("sudo rfkill list wlan | grep 'Soft blocked'| sed -e \"s/^.*: //g\"")
    local rfkillStatusValue = rfkillStatusCmd:read()
    rfkillStatusCmd:close()
    if rfkillStatusValue == 'no' then
        output = 'OFF'
    else
        output = 'ON'
    end
    alert('rfkillStatus', 'RfKillBlockedStatus: '..rfkillStatusValue)
    return output
end

function rfkillWidget.inTable(table, item)
    for key, value in pairs(table) do
        if value == item then return key end
    end
    return false
end

function rfkillWidget.notInTable(table, item)
    for key, value in pairs(table) do
        if value ~= item then return key end
    end
    return false
end

