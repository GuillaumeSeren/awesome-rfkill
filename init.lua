-- ---------------------------------------------
-- RfKill Widget for Awesome WM
-- @author Guillaume Seren
-- source  https://github.com/GuillaumeSeren/rfkillWidget
-- file    init.lua
-- Licence GPLv3
--
-- Main RfKill widget lib.
-- This widget display the status of the rfkill lock.
-- ---------------------------------------------

-- Rfkill Widget Class
rfkillWidget = {}

-- member variables {{{1
-- Tooltip instance
local rfkillTooltip = nil
local rfkillDebug = false

-- Rfkill global switch {{{1
-- This mute follow the default behavior of XF86WLAN,
-- but extend it to other capable devices.
function rfkillWidget.rfkillMute()
    local rfkillState = rfkillWidget.getRfkillBlockedState()
    local devices = rfkillWidget.getRfkillDevices()
    local excludedDevices = rfkillWidget.getExcludedDevices()
    -- filter devices list
    local devicesFiltered = rfkillWidget.getFilteredDevices(devices, excludedDevices)
    if rfkillState == 'OFF' then
        rfkillWidget.setRfkillUp(devicesFiltered)
    else
        rfkillWidget.setRfkillDown(devicesFiltered)
    end
end

-- Unblock given devices {{{1
function rfkillWidget.setRfkillUp(devices)
    for id, device in ipairs(devices) do
        if rfkillDebug == true then
            alert('setRfkillUp', 'setRfkillUp '..device)
        end
        awful.util.spawn("sudo rfkill unblock "..device)
    end
    return nil
end

-- Block given devices {{{1
function rfkillWidget.setRfkillDown(devices)
    for id, device in ipairs(devices) do
        if rfkillDebug == true then
            alert('setRfkillDown', 'setRfkillDown '..device)
        end
        awful.util.spawn("sudo rfkill block "..device)
    end
    return nil
end

-- Return the devices list without excluded devices {{{1
-- (wlan most of the time)
function rfkillWidget.getFilteredDevices(devices, excludedDevices)
    local filteredDevices = {}
    for id, device in ipairs(devices) do
        if rfkillWidget.notInTable(excludedDevices, device) then
            -- Only return device *NOT* excluded
            table.insert(filteredDevices, device)
        end
    end
    return filteredDevices
end

-- Return the list of excluded devices {{{1
function rfkillWidget.getExcludedDevices()
    local excludedDevices = {}
    -- @FIXME: Export the list in member and add method to update it.
    -- May be useful to control excluded
    table.insert(excludedDevices, 'wlan')
    return excludedDevices
end

-- Return rfkill capable devices {{{1
function rfkillWidget.getRfkillDevices()
    local devices = {}
    local rfkillDevicesCmd = io.popen("sudo rfkill list all | grep -v 'blocked' | sed -e \"s/^.:.*: //g\"")
    for line in rfkillDevicesCmd:lines() do
        line = rfkillWidget.getRfkillDevicesTranslation(line)
        if rfkillDebug == true then
            alert('getRfkillDevices', 'getRfkillDevice '..line)
        end
        table.insert(devices, line)
    end
    rfkillDevicesCmd:close()
    return devices
end

-- Return global rfkill state {{{1
function getRfkillState()
    local output = awful.util.pread('sudo rfkill list all')
    return output
end

-- Remove the toolTip {{{1
function rfkillWidget.rfkillTooltipRemove()
    if rfkillTooltip ~= nil then
        naughty.destroy(rfkillTooltip)
        rfkillTooltip = nil
    end
end

-- Return the text content for tooltip {{{1
function rfkillWidget.getTooltipContent()
    output = '| #ID | DEVICE | SOFTBLOCK | HARDBLOCK |\n'
    local rfkillState = rfkillWidget.getRfkillBlockedState()
    local devices = rfkillWidget.getRfkillDevices()
    -- Detail Array:
    for id, device in ipairs(devices) do
        -- @FIXME: The list start on 0 and the array on 1 
        id = (id-1)
        deviceStatus = rfkillWidget.getRfkillDeviceStatus(id)
        -- @FIXME: Refactor the display to draw a nice ascii art array
        output = output ..'| #'..id..' | '..device ..' | '..deviceStatus['soft'] ..' | '..deviceStatus['hard']..' |'.. '\n'
    end
    return output
end

-- Return rfkill global status of a given device {{{1
function rfkillWidget.getRfkillDeviceStatus(deviceId)
    local output = {}
        if rfkillDebug == true then
            alert('', 'deviceId:::'..deviceId)
        end
    softStatus = rfkillWidget.getRfkillDeviceSoftStatus(deviceId)
    if softStatus == nil then
        if rfkillDebug == true then
            alert('', 'SoftStatus is NIL !!! (device:'..deviceId..')')
        end
        softStatus = '--'
    end
    hardStatus = rfkillWidget.getRfkillDeviceHardStatus(deviceId)
    if hardStatus == nil then
        if rfkillDebug == true then
            alert('', 'HardStatus is NIL !!! (device:'..deviceId..')')
        end
        hardStatus = '--'
    end
    output['soft'] = softStatus
    output['hard'] = hardStatus
    return output
end

-- Return rfkill soft status of a given device {{{1
function rfkillWidget.getRfkillDeviceSoftStatus(deviceId)
    local output = ''
    -- If wlan is blocked lets say everything is, *simpler is better*
    local rfkillStatusCmd = io.popen("sudo rfkill list "..deviceId.." | grep 'Soft' | sed \"s/.\\+: //g\"")
    local rfkillStatusValue = rfkillStatusCmd:read()
    rfkillStatusCmd:close()
        if rfkillDebug == true then
            alert('softStatus', 'soft ::'..rfkillStatusValue)
        end
    output = rfkillStatusValue
    return output
end

-- Return rfkill hard status of a given device {{{1
function rfkillWidget.getRfkillDeviceHardStatus(deviceId)
    local output = ''
    -- If wlan is blocked lets say everything is, *simpler is better*
    local rfkillStatusCmd = io.popen("sudo rfkill list "..deviceId.." | grep 'Hard' | sed \"s/.\\+: //g\"")
    local rfkillStatusValue = rfkillStatusCmd:read()
    rfkillStatusCmd:close()
        if rfkillDebug == true then
            alert('softStatus', 'hard ::'..rfkillStatusValue)
        end
    -- output = rfkillWidgetValue
    output = rfkillStatusValue
    return output
end

-- Add the tooltip {{{1
function rfkillWidget.rfkillTooltipAdd()
    rfkillWidget.rfkillTooltipRemove()
    local rfkillCapi = {
        mouse = mouse,
        screen = screen
    }
    local state = rfkillWidget.getTooltipContent()
    -- local state = 'test'

    rfkillTooltip = naughty.notify({
        text = string.format(
            '<span font_desc="%s">%s</span>',
            "Terminus",
            state),
        timeout = 0,
        position = "top_right",
        margin = 10,
        height = 170,
        width = 585,
        screen = rfkillCapi.mouse.screen
    })
end

-- Return the translated name to block/unblock {{{1
-- @FIXME: We may better use id if we can
function rfkillWidget.getRfkillDevicesTranslation(name)
    local devicesName = {}
    devicesName['Bluetooth']    = 'bluetooth'
    devicesName['Wireless WAN'] = 'wwan'
    devicesName['Wireless LAN'] = 'wlan'
    return devicesName[name]
end

-- Return the global *state* {{{1
-- most of the time wlan status
function rfkillWidget.getRfkillBlockedState()
    -- @TODO: Add a param to test an other device.
    local output = ''
    -- If wlan is blocked lets say everything is, *simpler is better*
    local rfkillStatusCmd = io.popen("sudo rfkill list wlan | grep 'Soft blocked'| sed -e \"s/^.*: //g\"")
    local rfkillStatusValue = rfkillStatusCmd:read()
    rfkillStatusCmd:close()
    if rfkillStatusValue == 'no' then
        -- Unlocked
        output = 'OFF'
        if rfkillDebug == true then
            alert('getRfkillBlockedState', 'getRfkillState off')
        end
    else
        -- Locked
        output = 'ON'
        if rfkillDebug == true then
            alert('getRfkillBlockedState', 'getRfkillState on')
        end
    end
    return output
end

-- Return the rfkillBlockedState for display {{{1
function rfkillWidget.getRfkillBlockedStateDisplay()
    local rfkillBlockedState = rfkillWidget.getRfkillBlockedState()
    local output = nil
    if rfkillBlockedState == 'OFF' then
        output = green..'📶 🔓'..coldef
    else
        -- output = red..'📶 🔒'..coldef
        output = red..'📶 ✈'..coldef
    end
    return output
end

-- Return true/value if item is in array {{{1
function rfkillWidget.inTable(table, item)
    --@TODO: Export that to an other lib
    for key, value in pairs(table) do
        if value == item then return key end
    end
    return false
end

-- Return true/value if item is not in array {{{1
function rfkillWidget.notInTable(table, item)
    for key, value in pairs(table) do
        if value ~= item then return key end
    end
    return false
end

-- Return nil if rfkill is not valid {{{1
-- (need rfkill command)
function rfkillWidget.getRfkillWidgetValid()
    -- We need notmuch command
    local output = nil
    -- @FIXME: rfkill need root, find a way to avoid that
    local rfkillStatusCmd = os.execute("sudo which rfkill")
    if rfkillStatusCmd ~= 0 then
        output = nil
    else
        output = rfkillStatusCmd
    end
    return output
end
-- }}}

return rfkillWidget
