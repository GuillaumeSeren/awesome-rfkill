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
    else
        rfkillWidget.setRfkillDown(devices)
    end
end

-- Unblock given devices.
function rfkillWidget.setRfkillUp(devices)
    for id, device in ipairs(devices) do
        awful.util.spawn("sudo rfkill unblock "..device)
    end
    return nil
end

-- Block given devices.
function rfkillWidget.setRfkillDown(devices)
    for id, device in ipairs(devices) do
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
        table.insert(devices, line)
    end
    rfkillDevicesCmd:close()
    return devices
end

-- function rfkillWidget.getRfkillWidget()
--     return '✈'
-- end

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
        output = 'OFF'
    else
        output = 'ON'
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

return rfkillWidget
