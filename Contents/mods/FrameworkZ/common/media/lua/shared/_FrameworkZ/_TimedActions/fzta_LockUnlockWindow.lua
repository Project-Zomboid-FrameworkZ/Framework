if not isClient() then return end

local ISBaseTimedAction = ISBaseTimedAction
local IsoFlagType = IsoFlagType

require "TimedActions/ISBaseTimedAction"

ISLockUnlockWindow = ISBaseTimedAction:derive("ISLockUnlockWindow");

function ISLockUnlockWindow:isValid()
	local keyId = self.window:getKeyId()
	if self.character:getInventory():haveThisKeyId(keyId) then return true end
	return FrameworkZ.Utilities:IsTrulyInterior(self.character:getSquare())
end

function ISLockUnlockWindow:update() end

function ISLockUnlockWindow:start()
	self.character:faceThisObject(self.window)
end

function ISLockUnlockWindow:stop()
	if not self:isValid() then
		self.character:faceThisObject(self.window)
		self.character:getEmitter():playSound("DoorIsLocked")
	end

    ISBaseTimedAction.stop(self)
end

if isServer() then
	function ISLockUnlockWindow.LockWindow(data, coordinates)
		local x, y, z = coordinates.x, coordinates.y, coordinates.z
		local window = getSquare(x, y, z) and getSquare(x, y, z).getWindow and getSquare(x, y, z):getWindow() or nil

		if window then
			window:setPermaLocked(true)
			window:setIsLocked(true)
		end
	end
	FrameworkZ.Foundation:Subscribe("ISLockUnlockWindow.LockWindow", ISLockUnlockWindow.LockWindow)

	function ISLockUnlockWindow.UnlockWindow(data, coordinates)
		local x, y, z = coordinates.x, coordinates.y, coordinates.z
		local window = getSquare(x, y, z) and getSquare(x, y, z).getWindow and getSquare(x, y, z):getWindow() or nil

		if window then
			window:setPermaLocked(false)
			window:setIsLocked(false)
		end
	end
	FrameworkZ.Foundation:Subscribe("ISLockUnlockWindow.UnlockWindow", ISLockUnlockWindow.UnlockWindow)
end

function ISLockUnlockWindow:perform()
	if self.shouldLock then
		FrameworkZ.Foundation:SendFire(self.character, "ISLockUnlockWindow.LockWindow", function()
			self.window:setPermaLocked(true)
			self.window:setIsLocked(true)
			self.character:getEmitter():playSound("WoodDoorLock")
		end, {self.window:getX(), self.window:getY(), self.window:getZ()})
	elseif not self.shouldLock then
		FrameworkZ.Foundation:SendFire(self.character, "ISLockUnlockWindow.LockWindow", function()
			self.window:setPermaLocked(false)
			self.window:setIsLocked(false)
			self.character:getEmitter():playSound("WoodDoorLock")
		end, {self.window:getX(), self.window:getY(), self.window:getZ()})
	end

	ISBaseTimedAction.perform(self)
end

function ISLockUnlockWindow:new(character, window, shouldLock)
	local o = {}

	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.window = window
    o.shouldLock = shouldLock
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = 0

	return o
end