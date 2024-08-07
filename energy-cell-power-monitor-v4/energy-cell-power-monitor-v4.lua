-- For 1.7.10 versions of Thermal Expansion, EnderIO and Immersive Engineering
-- Monitors TE3 Energy cells and EnderIO capacitor banks and output redstone signals once energy storage drops below set limits.
-- Will automatically detect direction of adjacent storage device and (optional) Advanced Monitors.
-- If chosen, monitor format should be 1 high and 2 wide. Now also with wired modem support for both storage and monitors.
-- Directly adjacent devices will take priority over any wired devices.
-- Redstone signal for the engines will be output out the back of the computer.
-- More details: http://forum.feed-the-beast.com/threads/rhns-1-6-monster-build-journal-and-guide-collection.42664/page-15#post-718973

-- Upper limit for computer to stop transmitting redstone signal. 0.90=90% full.
-- Default: 0.90
local upper = 0.90

-- Lower limit for computer to start transmitting redstone signal.
-- Default: 0.10
local lower = 0.10

-- Controls if we are generating power, Set to true/false to have power generation turned on or off at startup
-- Default: false
local PowerGenOn = false

-- function to dump a table
local function dump(o)
	if type(o) == 'table' then
		local s = '{ '
		for k, v in pairs(o) do
			if type(k) ~= 'number' then k = '"' .. k .. '"' end
			s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

local function detectDevices()
	local energyDeviceTypes = {
		{ pattern = "tile_thermalexpansion_cell",   desc = "TE Energy Cell",                  connection = "" },
		{ pattern = "tile_blockcapacitorbank_name", desc = "EnderIO Capacitor Bank",          connection = "" },
		{ pattern = "IE:[lmh]vCapacitor",           desc = "Immersive Engineering Capacitor", connection = "" },
		{ pattern = "monitor",                      desc = "Monitor",                         connection = "" }
	}
	local devices = { capacitorBank = nil, monitor = nil }

	local peripherals = peripheral.getNames()
	for _, peripheralName in pairs(peripherals) do
		local peripheralType = peripheral.getType(peripheralName)
		if peripheralType ~= "modem" then
			for _, device in pairs(energyDeviceTypes) do
				if string.find(peripheralType, device.pattern) then
					device.connection = peripheralName
					if peripheralType == "monitor" then
						devices.monitor = device
					else
						devices.capacitorBank = device
					end
				end
			end
		end
	end
	return devices
end

local function updatePowerGenerationState(powerOn, monitor)
	--Main code
	redstone.setOutput("back", powerOn)

	--If monitor is attached, write data on monitor
	if monitor ~= "none" then
		if powerOn then
			monitor.setBackgroundColour((colours.green))
		else
			monitor.setBackgroundColour((colours.grey))
		end
		monitor.setCursorPos(1, 3)
		monitor.write(" ON ")
		if powerOn then
			monitor.setBackgroundColour((colours.grey))
		else
			monitor.setBackgroundColour((colours.red))
		end
		monitor.setCursorPos(5, 3)
		monitor.write(" OFF ")
		monitor.setBackgroundColour((colours.black))
	end
end

local function formatNumber(n)
    local absoluteValue = math.abs(n)
	if absoluteValue < 1000 then
		return string.format("%5d", n)
	elseif absoluteValue < 1000000 then
		return string.format("%4d", n / 1000) .. "k"
	elseif absoluteValue < 1000000000 then
		return string.format("%4d", n / 1000000) .. "M"
	else
		return string.format("%4d", n / 1000000000) .. "G"
	end
end

-- Attach the devices
-- Last Energy Cell/Capacitor found will be used
local devices = detectDevices()

if not devices.capacitorBank then
	print("No Energy storage found. Halting script!")
	return
end

local monitor
if devices.monitor then
	monitor = peripheral.wrap(devices.monitor.connection)
	monitor.clear()
else
	print("Warning - No Monitor attached, continuing without.")
	monitor = "none"
end

local cell = peripheral.wrap(devices.capacitorBank.connection)
for _, device in pairs(devices) do
	if string.find(device.connection, "_") then
		print(device.desc .. " on wired modem: " .. device.connection .. " Connected.")
	else
		print(device.desc .. " on the " .. device.connection .. " Connected")
	end
end

--Main code
updatePowerGenerationState(PowerGenOn, monitor)
monitor.setCursorPos(1, 1)
monitor.write("Engines:")
monitor.setCursorPos(11, 1)
monitor.write("Storage:")
monitor.setCursorPos(11, 3)
monitor.write("Of:")
monitor.setCursorPos(1, 5)
monitor.write("Change: ")

--Main loop
local lastEnergy = 0
while true do
	--Get storage values
	local eNow = cell.getEnergyStored("unknown")
	local eMax = cell.getMaxEnergyStored("unknown")

	--Compute ratio
	local fill = (eNow / eMax)
	local energyChangePerTick = ((lastEnergy - eNow) * -1) / 20
	lastEnergy = eNow

	--If monitor is attached, write data on monitor
	if monitor ~= "none" then
		monitor.setCursorPos(12, 2)
		monitor.write(formatNumber(eNow) .. "RF")
		monitor.setCursorPos(12, 4)
		monitor.write(formatNumber(eMax) .. "RF")
		monitor.setCursorPos(10, 5)
		monitor.write(formatNumber(energyChangePerTick) .. "RF/t")
	end

	if fill > upper then
		PowerGenOn = false
	elseif fill < lower then
		PowerGenOn = true
	end
	updatePowerGenerationState(PowerGenOn, monitor)
	sleep(1)
end
