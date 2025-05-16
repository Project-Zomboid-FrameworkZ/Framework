FrameworkZ = FrameworkZ or {}

--! \brief Timers module for FrameworkZ. Allows for the creation of timers for delaying code executions.
--! \class FrameworkZ.Timers
FrameworkZ.Timers = {}
--FrameworkZ.Timers.__index = FrameworkZ.Timers
FrameworkZ.Timers = FrameworkZ.Foundation:NewModule(FrameworkZ.Timers, "Timers")
FrameworkZ.Timers.AdvancedTimers = {}
FrameworkZ.Timers.SimpleTimers = {}

local os_time = os.time
local table_insert = table.insert
local table_remove = table.remove
local assert = assert
local type = type
local pairs = pairs

--! \brief Creates a simple timer that executes a function after a delay.
--! \param \integer delay The delay in seconds before the function is executed.
--! \param \function func The function to execute after the delay.
function FrameworkZ.Timers:Simple(delay, func)
	assert(type(delay) == "number", "Delay of timer should be a number type")
	assert(type(func) == "function", "Func of timer should be a function type (lol)")

	table_insert(self.SimpleTimers, {
		EndTime = os_time() + delay,
		Func = func
	})
end

function FrameworkZ.Timers:Create(name, delay, repetitions, func)

	assert(type(name) == "string", "ID of timer should be a string type")
	assert(type(delay) == "number", "Delay of timer should be a number type")
	assert(type(repetitions) == "number", "Repetitions of timer should be a number type")
	assert(type(func) == "function", "Func of timer should be a function type (lol)")

	self.AdvancedTimers[name] = {
		Delay = delay,
		StartRepetitions = repetitions,
		Repetitions = repetitions,
		Infinity = repetitions == 0,
		LastFuncTime = os_time(),
		Func = func,
		Paused = false,
	}

end

local function timerUpdate()

	local cur_time = os_time()

	local advanced_timers = FrameworkZ.Timers.AdvancedTimers

	for k, v in pairs(advanced_timers) do

		if not v.Paused then

			if cur_time >= v.LastFuncTime + v.Delay then

				v.Func()

				v.LastFuncTime = cur_time

				if not v.Infinity then

					v.Repetitions = v.Repetitions - 1

					if v.Repetitions <= 0 then

						FrameworkZ.Timers.AdvancedTimers[k] = nil

					end

				end

			end

		end

	end

	local simple_timers = FrameworkZ.Timers.SimpleTimers

	for i = #simple_timers, 1, -1 do

		local t = simple_timers[i]

		if t.EndTime <= cur_time then

			t.Func()

			table_remove(simple_timers, i)

		end

	end

end
Events.OnTickEvenPaused.Add(timerUpdate)

function FrameworkZ.Timers:Remove(name)

	local t = self.AdvancedTimers[name]

	if not t then return false end

	self.AdvancedTimers[name] = nil

	return true

end

function FrameworkZ.Timers:Exists(name)

	return self.AdvancedTimers[name] and true or false

end

function FrameworkZ.Timers:Start(name)

	local t = self.AdvancedTimers[name]

	if not t then return false end

	t.Repetitions = t.StartRepetitions
	t.LastFuncTime = os_time()
	t.Paused = false
	t.PausedTime = nil

	return true

end

function FrameworkZ.Timers:Pause(name)

	local t = self.AdvancedTimers[name]

	if not t then return false end

	if t.Paused then return false end

	t.Paused = true
	t.PausedTime = os_time()

	return true

end

function FrameworkZ.Timers:UnPause(name)

	local t = self.AdvancedTimers[name]

	if not t then return false end

	if not t.Paused then return false end

	t.Paused = false

	return true

end
FrameworkZ.Timers.Resume = FrameworkZ.Timers.UnPause

function FrameworkZ.Timers:Toggle(name)

	local t = self.AdvancedTimers[name]

	if not t then return false end

	t.Paused = not t.Paused

	return true

end

function FrameworkZ.Timers:TimeLeft(name)

	local t = self.AdvancedTimers[name]

	if not t then return end

	if t.Paused then

		return (t.Repetitions - 1) * t.Delay + (t.LastFuncTime + t.Delay - t.PausedTime)

	else

		return (t.Repetitions - 1) * t.Delay + (t.LastFuncTime + t.Delay - os_time())

	end

end

function FrameworkZ.Timers:NextTimeLeft(name)

	local t = self.AdvancedTimers[name]

	if not t then return end

	if t.Paused then

		return t.LastFuncTime + t.Delay - t.PausedTime

	else

		return t.LastFuncTime + t.Delay - os_time()

	end

end

function FrameworkZ.Timers:RepsLeft(name)

	local t = self.AdvancedTimers[name]

	return t and t.Repetitions

end