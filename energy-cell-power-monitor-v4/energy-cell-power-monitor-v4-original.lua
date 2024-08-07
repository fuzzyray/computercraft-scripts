-- For 1.7.10 versions of Thermal Expansion and EnderIO
-- Monitors TE3 Energy cells and EnderIO capacitor banks and output redstone signals once energy storage drops below set limits.
-- Will automatically detect direction of adjacent storage device and (optional) Advanced Monitors. If chosen, monitor format should be 1 high and 2 wide. Now also with wired modem support for both storage and monitors. Directly adjacent devices will take priority over any wired devices.
-- Redstone signal for the engines will be output out the back of the computer.
--More details: http://forum.feed-the-beast.com/threads/rhns-1-6-monster-build-journal-and-guide-collection.42664/page-15#post-718973


local upper = 0.90 --Upper limit for computer to stop transmitting redstone signal. 0.90=90% full.
local lower = 0.10 --Lower limit for computer to start transmitting redstone signal.


--Device detection
isError=0

function detectDevice(DeviceName)
DeviceSide="none"
for k,v in pairs(redstone.getSides()) do
  if peripheral.getType(v) and string.find(peripheral.getType(v), DeviceName) then
 --if peripheral.getType(v)==DeviceName then
   --if string.find(peripheral.getType(v), DeviceName) then
      DeviceSide = v
      break
   --end
  end
end
  return(DeviceSide)
end


cell="none"
monitor="none"
local peripheralList = peripheral.getNames()

CellSide=detectDevice("tile_thermalexpansion_cell")

if CellSide~="none" then
   cell=peripheral.wrap(CellSide)
   print ("TE Energy cell on the " .. CellSide .. " connected.")
   else
	CellSide=detectDevice("tile_blockcapacitorbank_name")
	if CellSide~="none" then
		cell=peripheral.wrap(CellSide)
		print ("EnderIO capacitorbank on the " .. CellSide .. " connected.")
	else
			for Index = 1, #peripheralList do
				if string.find(peripheralList[Index], "tile_thermalexpansion_cell") then
					cell=peripheral.wrap(peripheralList[Index])
					print ("TE Energy cell on wired modem: "..peripheralList[Index].." connected.")
				elseif string.find(peripheralList[Index], "tile_blockcapacitorbank_name") then
					cell=peripheral.wrap(peripheralList[Index])
					print ("EnderIO capacitorbank on wired modem: "..peripheralList[Index].." connected.")
				end
			end --for
			if cell == "none" then
				print("No Energy storage found. Halting script!")
				return
			end

	end
end


MonitorSide=detectDevice("monitor")
 
if MonitorSide~="none" then
      monitor=peripheral.wrap(MonitorSide)
   print ("Monitor on the " .. MonitorSide .. " connected.")
   else
	for Index = 1, #peripheralList do
		if string.find(peripheralList[Index], "monitor") then
			monitor=peripheral.wrap(peripheralList[Index])
			print ("Monitor on wired modem: "..peripheralList[Index].." connected.")
		end
	end --for
	if monitor == "none" then
		print ("Warning - No Monitor attached, continuing without.")
	end
end

--Main code
redstone.setOutput("back", false) --Defaulting to off

--If monitor is attached, write data on monitor
if monitor ~= "none" then
	monitor.clear()
	monitor.setBackgroundColour((colours.grey))
	monitor.setCursorPos(1,4)
	monitor.write(" ON ")
	monitor.setBackgroundColour((colours.green))
	monitor.setCursorPos(5,4)
	monitor.write(" OFF ")
	monitor.setBackgroundColour((colours.black))
end

--Main loop
while true do
	--Get storage values
	eNow = cell.getEnergyStored("unknown")
	eMax = cell.getMaxEnergyStored("unknown")

	--Compute ratio
	fill = (eNow / eMax)

--If monitor is attached, write data on monitor
if monitor ~= "none" then

	if eMax >= 10000000 then
	monitor.setCursorPos(11,2)
	monitor.write("Storage:")
	monitor.setCursorPos(11,3)
	monitor.write(math.ceil(eNow/1000).."kRF")
	monitor.setCursorPos(11,4)
	monitor.write("Of:")
	monitor.setCursorPos(11,5)
	monitor.write(math.ceil(eMax/1000).."kRF")
	else	
	monitor.setCursorPos(11,2)
	monitor.write("Storage:")
	monitor.setCursorPos(11,3)
	monitor.write(math.ceil(eNow))
	monitor.setCursorPos(11,4)
	monitor.write("Of:")
	monitor.setCursorPos(11,5)
	monitor.write(math.ceil(eMax))
	end

	monitor.setCursorPos(1,2)
	monitor.write("Engines:")
end

	if fill > upper then
		--energylevel is over upper level, turning redstone signal off
		redstone.setOutput("back", false)

		if monitor ~= "none" then
			monitor.setBackgroundColour((colours.grey))
			monitor.setCursorPos(1,4)
			monitor.write(" ON ")
			monitor.setBackgroundColour((colours.green))
			monitor.setCursorPos(5,4)
			monitor.write(" OFF ")
			monitor.setBackgroundColour((colours.black))
		end

	elseif fill < lower then
		--energy level is below lower limit, turning redstone signal on
		redstone.setOutput("back", true)
		
		if monitor ~= "none" then
			monitor.setBackgroundColour((colours.green))
			monitor.setCursorPos(1,4)
			monitor.write(" ON ")
			monitor.setBackgroundColour((colours.grey))
			monitor.setCursorPos(5,4)
			monitor.write(" OFF ")
			monitor.setBackgroundColour((colours.black))
		end
	end

	
	sleep(1)
end --while