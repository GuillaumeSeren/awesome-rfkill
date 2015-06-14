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
    local devicesFiltered = rfkillWidget.getFilteredDevices(devices, excludedDevices)
    if rfkillState == 'OFF' then
        rfkillWidget.setRfkillUp(devicesFiltered)
    else
        rfkillWidget.setRfkillDown(devicesFiltered)
    end
end

-- Unblock given devices.
function rfkillWidget.setRfkillUp(devices)
    for id, device in ipairs(devices) do
        -- alert('setRfkillUp', 'setRfkillUp '..device)
        awful.util.spawn("sudo rfkill unblock "..device)
    end
    return nil
end

-- Block given devices.
function rfkillWidget.setRfkillDown(devices)
    for id, device in ipairs(devices) do
        -- alert('setRfkillDown', 'setRfkillDown '..device)
        awful.util.spawn("sudo rfkill block "..device)
    end
    return nil
end

-- Return the devices list without excluded devices (wlan most of the time)
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

-- Return the list of excluded devices
function rfkillWidget.getExcludedDevices()
    local excludedDevices = {}
    -- May be useful to control excluded
    table.insert(excludedDevices, 'wlan')
    return excludedDevices
end

-- Return rfkill capable devices
function rfkillWidget.getRfkillDevices()
    local devices = {}
    local rfkillDevicesCmd = io.popen("sudo rfkill list all | grep -v 'blocked' | sed -e \"s/^.:.*: //g\"")
    for line in rfkillDevicesCmd:lines() do
        line = rfkillWidget.getRfkillDevicesTranslation(line)
        -- alert('getRfkillDevices', 'getRfkillDevice '..line)
        table.insert(devices, line)
    end
    rfkillDevicesCmd:close()
    return devices
end

-- function rfkillWidget.getRfkillWidget()
--     return '✈'
-- end

-- Return global rfkill state
function getRfkillState()
    local output = awful.util.pread('sudo rfkill list all')
    return output
end

-- Tooltip instance
local rfkillTooltip = nil

-- Remove the toolTip.
function rfkillWidget.rfkillTooltipRemove()
    if rfkillTooltip ~= nil then
        naughty.destroy(rfkillTooltip)
        rfkillTooltip = nil
    end
end

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

function rfkillWidget.getRfkillDeviceStatus(deviceId)
    local output = {}
    -- alert('', 'deviceId:::'..deviceId)
    softStatus = rfkillWidget.getRfkillDeviceSoftStatus(deviceId)
    if softStatus == nil then
        alert('', 'SoftStatus is NIL !!! (device:'..deviceId..')')
        softStatus = '--'
    end
    hardStatus = rfkillWidget.getRfkillDeviceHardStatus(deviceId)
    if hardStatus == nil then
        alert('', 'HardStatus is NIL !!! (device:'..deviceId..')')
        hardStatus = '--'
    end
    output['soft'] = softStatus
    output['hard'] = hardStatus
    return output
end

function rfkillWidget.getRfkillDeviceSoftStatus(deviceId)
    local output = ''
    -- If wlan is blocked lets say everything is, *simpler is better*
    local rfkillStatusCmd = io.popen("sudo rfkill list "..deviceId.." | grep 'Soft' | sed \"s/.\\+: //g\"")
    local rfkillStatusValue = rfkillStatusCmd:read()
    rfkillStatusCmd:close()
    -- alert('softStatus', 'soft ::'..rfkillStatusValue)
    output = rfkillStatusValue
    return output
end

function rfkillWidget.getRfkillDeviceHardStatus(deviceId)
    local output = ''
    -- If wlan is blocked lets say everything is, *simpler is better*
    local rfkillStatusCmd = io.popen("sudo rfkill list "..deviceId.." | grep 'Hard' | sed \"s/.\\+: //g\"")
    local rfkillStatusValue = rfkillStatusCmd:read()
    rfkillStatusCmd:close()
    -- alert('softStatus', 'hard ::'..rfkillStatusValue)
    -- output = rfkillWidgetValue
    output = rfkillStatusValue
    return output
end

-- Add the tooltip.
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

-- Return the translated  name to block/unblock
function rfkillWidget.getRfkillDevicesTranslation(name)
    local devicesName = {}
    devicesName['Bluetooth']    = 'bluetooth'
    devicesName['Wireless WAN'] = 'wwan'
    devicesName['Wireless LAN'] = 'wlan'
    return devicesName[name]
end

-- Return the global *state*, most of the time wlan status
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
        -- alert('getRfkillBlockedState', 'getRfkillState off')
    else
        -- Locked
        output = 'ON'
        -- alert('getRfkillBlockedState', 'getRfkillState on')
    end
    return output
end

-- Return the rfkillBlockedState for display
function rfkillWidget.getRfkillBlockedStateDisplay()
    local rfkillBlockedState = rfkillWidget.getRfkillBlockedState()
    local output = nil
    if rfkillBlockedState == 'OFF' then
        output = green..'📶 🔓'..coldef
    else
        output = red..'📶 🔒'..coldef
    end
    return output
end

-- Return true/value if item is in array
function rfkillWidget.inTable(table, item)
    --@TODO: Export that to an other lib
    for key, value in pairs(table) do
        if value == item then return key end
    end
    return false
end

-- Return true/value if item is not in array
function rfkillWidget.notInTable(table, item)
    for key, value in pairs(table) do
        if value ~= item then return key end
    end
    return false
end

-- Return nil if rfkill is not valid (need rfkill command)
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

return rfkillWidget
