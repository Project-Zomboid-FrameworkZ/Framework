
---@diagnostic disable: undefined-global, deprecated
local Events = Events
local coroutine_create = coroutine.create
local coroutine_resume = coroutine.resume
local coroutine_running = coroutine.running
local coroutine_status = coroutine.status
local coroutine_yield = coroutine.yield
local getTimestamp = getTimestamp
local isClient = isClient
local isServer = isServer
local ipairs = ipairs
local pairs = pairs
local table_insert = table.insert
local tostring = tostring
local type = type

FrameworkZ = FrameworkZ or {}

--! \brief Await-style coroutine helpers for FrameworkZ network requests.
--! \library FrameworkZ.Awaits
FrameworkZ.Awaits = {}
FrameworkZ.Awaits = FrameworkZ.Foundation:NewModule(FrameworkZ.Awaits, "Awaits")
FrameworkZ.Awaits.DefaultTimeout = 30
FrameworkZ.Awaits.Pending = {}
FrameworkZ.Awaits.NextAwaitID = 0

local function unpackFrom(values, index)
	if not values then
		return nil
	end

	if not index or index <= 1 then
		return FrameworkZ.Utilities:Unpack(values)
	end

	local sliced = { n = 0 }

	for i = index, values.n do
		sliced.n = sliced.n + 1
		sliced[sliced.n] = values[i]
	end

	return FrameworkZ.Utilities:Unpack(sliced)
end

local function buildAwaitError(message, identifier)
	if not identifier then
		return tostring(message)
	end

	return tostring(message) .. " [" .. tostring(identifier) .. "]"
end

--! \brief Generate a unique local await ID.
--! \return \string A unique await identifier.
function FrameworkZ.Awaits:GenerateAwaitID()
	self.NextAwaitID = self.NextAwaitID + 1

	return "FZ_AWAIT_" .. tostring(getTimestamp()) .. "_" .. tostring(self.NextAwaitID)
end

--! \brief Resume a pending coroutine and clear its await state.
--! \param awaitID \string The await identifier to resolve.
--! \param success \boolean Whether the await completed successfully.
--! \param ... \multiple Values to pass back into the coroutine.
--! \return \boolean Whether the coroutine was resumed successfully.
function FrameworkZ.Awaits:ResumePending(awaitID, success, ...)
	local pending = self.Pending[awaitID]

	if not pending then
		return false
	end

	self.Pending[awaitID] = nil

	local thread = pending.Thread

	if not thread or coroutine_status(thread) == "dead" then
		return false
	end

	local resumed, err = coroutine_resume(thread, success, ...)

	if not resumed then
		print("[FZ] ERROR: Failed to resume await coroutine: " .. tostring(err))
		return false
	end

	return true
end

--! \brief Await a callback-style request from inside a coroutine.
--! \param requestStarter \function Function that accepts a callback as its first argument and starts the request.
--! \param timeout \number? Optional timeout in seconds. Uses FrameworkZ.Awaits.DefaultTimeout when nil.
--! \param ... \multiple Additional arguments forwarded to requestStarter.
--! \return \multiple Returns the callback arguments on success, or false and an error message on failure.
function FrameworkZ.Awaits:Await(requestStarter, timeout, ...)
	if type(requestStarter) ~= "function" then
		return false, "Invalid request starter supplied to FrameworkZ.Awaits:Await()."
	end

	local thread = coroutine_running()

	if not thread then
		return false, "FrameworkZ.Awaits:Await() must be called from a running coroutine."
	end

	local awaitID = self:GenerateAwaitID()
	-- NOTE: "timeout == 0 and nil or (...)" is broken on purpose-built Lua and/or ternaries --
	-- since the true-branch value (nil) is falsy, that pattern always evaluates the else-branch,
	-- so timeout=0 never actually disabled the deadline. Also, 0 is truthy in Lua, so
	-- "(timeout or self.DefaultTimeout)" returned 0 (not DefaultTimeout) anyway, producing an
	-- already-expired deadline instead of no deadline at all.
	local expiresAt = nil
	if timeout ~= 0 then
		expiresAt = getTimestamp() + (timeout or self.DefaultTimeout)
	end

	self.Pending[awaitID] = {
		Thread = thread,
		StartedAt = getTimestamp(),
		TimeoutAt = expiresAt,
		RequestID = nil,
		Description = nil
	}

	local resolved = false
	local resolvedValues = nil

	local function resolve(...)
		if not self.Pending[awaitID] then
			resolved = true
			resolvedValues = FrameworkZ.Utilities:Pack(...)
			return true
		end

		return self:ResumePending(awaitID, true, ...)
	end

	local started, requestID = pcall(requestStarter, resolve, ...)

	if not started then
		self.Pending[awaitID] = nil
		return false, buildAwaitError("Failed to start await request", requestID)
	end

	local pending = self.Pending[awaitID]

	if not pending then
		if resolved then
			return unpackFrom(resolvedValues, 1)
		end

		return false, "Await request resolved before it could be yielded."
	end

	pending.RequestID = requestID or awaitID
	pending.Description = requestID or awaitID

	if resolved then
		self.Pending[awaitID] = nil
		return unpackFrom(resolvedValues, 1)
	end

	local resumedValues = FrameworkZ.Utilities:Pack(coroutine_yield(awaitID))

	if not resumedValues[1] then
		return false, unpackFrom(resumedValues, 2)
	end

	return unpackFrom(resumedValues, 2)
end

--! \brief Run a function inside a managed coroutine.
--! If already executing inside a coroutine, the existing coroutine is reused.
--! This allows nested Await-aware functions and nested Run() calls to remain
--! part of the same await chain.
--! \param callback \function The function to execute.
--! \param ... \multiple Arguments forwarded to the callback.
--! \return \mixed Returns the coroutine thread when suspended, or the callback return values.
function FrameworkZ.Awaits:Run(callback, ...)
	if type(callback) ~= "function" then
		return false, "Invalid callback supplied to FrameworkZ.Awaits:Run()."
	end

	local currentThread, isMain = coroutine_running()

	if currentThread and not isMain then
		return callback(...)
	end

	local thread = coroutine_create(callback)
	local results = FrameworkZ.Utilities:Pack(coroutine_resume(thread, ...))

	if not results[1] then
		print("[FZ] ERROR: Await coroutine failed: " .. tostring(results[2]))
		return false, results[2]
	end

	if coroutine_status(thread) == "dead" then
		return unpackFrom(results, 2)
	end

	return thread
end

--! \brief Await a FrameworkZ.Foundation:SendFire request.
--! \param isoPlayer \object The isoPlayer to route the request through. This must not be nil for awaited network requests.
--! \param subscriptionID \string The subscribed network request name.
--! \param ... \multiple Arguments forwarded to the network request.
--! \return \multiple Returns the SendFire callback arguments, or false and an error message.
function FrameworkZ.Awaits:SendFire(isoPlayer, subscriptionID, ...)
	if not isoPlayer then
		return false, "FrameworkZ.Awaits:SendFire() requires a valid isoPlayer for confirmation routing."
	end

	return self:Await(function(resolve, ...)
		-- ConfirmFire always calls back as (data, ...actualReturnValues) per the standard
		-- FrameworkZ.Foundation subscription convention. Strip the leading diagnostic "data"
		-- table here so awaited callers get exactly the subscriber's own return values (as
		-- documented above), instead of everything being shifted one position to the right.
		local function stripDiagnosticData(_data, ...)
			return resolve(...)
		end

		return FrameworkZ.Foundation:SendFire(isoPlayer, subscriptionID, stripDiagnosticData, ...)
	end, self.DefaultTimeout, ...)
end

--! \brief Await a FrameworkZ.Foundation:GetData request.
--! \param isoPlayer \object The player object used to route the request on the client.
--! \param namespace \string The namespace to retrieve from.
--! \param keys \string|\table The key or nested key path.
--! \param subscriptionID \string? Optional subscription fired server-side after retrieval.
--! \return \multiple Returns the GetData callback arguments, or false and an error message.
function FrameworkZ.Awaits:GetData(isoPlayer, namespace, keys, subscriptionID)
	if isServer() then
		local value = FrameworkZ.Foundation:GetData(isoPlayer, namespace, keys, subscriptionID)
		return isoPlayer, namespace, keys, value
	end

	if not isClient() then
		return false, "FrameworkZ.Awaits:GetData() is not available in this execution context."
	end

	return self:Await(function(resolve)
		FrameworkZ.Foundation:GetData(isoPlayer, namespace, keys, subscriptionID, resolve)
		return namespace
	end, self.DefaultTimeout)
end

--! \brief Await a FrameworkZ.Foundation:SetData request.
--! \param isoPlayer \object The player object used to route the request on the client.
--! \param namespace \string The namespace to store in.
--! \param keys \string|\table The key or nested key path.
--! \param value \any The value to set.
--! \param subscriptionID \string? Optional subscription fired server-side after the set.
--! \param broadcast \boolean? Whether to broadcast the change to clients.
--! \return \multiple Returns the SetData callback arguments, or false and an error message.
function FrameworkZ.Awaits:SetData(isoPlayer, namespace, keys, value, subscriptionID, broadcast)
	if isServer() then
		local success = FrameworkZ.Foundation:SetData(isoPlayer, namespace, keys, value, subscriptionID, broadcast)

		if not success then
			return false, "Failed to set data for namespace '" .. tostring(namespace) .. "'."
		end

		return isoPlayer, namespace, keys, value
	end

	if not isClient() then
		return false, "FrameworkZ.Awaits:SetData() is not available in this execution context."
	end

	return self:Await(function(resolve)
		FrameworkZ.Foundation:SetData(isoPlayer, namespace, keys, value, subscriptionID, broadcast, resolve)
		return namespace
	end, self.DefaultTimeout)
end

--! \brief Poll a predicate once per tick until it returns a truthy value or maxTicks elapse.
--! \details Useful for bridging the gap between a server-authoritative action (e.g. creating and
--! networking an item) and the client-side engine sync that delivers it, which does not complete
--! within the same network round trip used to confirm the action itself.
--! \param predicate \function Called with no arguments; return a truthy value to resolve the wait.
--! \param maxTicks \number? Maximum ticks to poll before giving up (default 180).
--! \return \multiple The predicate's own return value(s) on success, or false and a timeout message.
function FrameworkZ.Awaits:WaitUntil(predicate, maxTicks)
	if type(predicate) ~= "function" then
		return false, "Invalid predicate supplied to FrameworkZ.Awaits:WaitUntil()."
	end

	local immediate = FrameworkZ.Utilities:Pack(predicate())

	if immediate[1] then
		return unpackFrom(immediate, 1)
	end

	if not coroutine_running() then
		print("[FZ] WaitUntil: bailing out, not called from a running coroutine.")
		return false, "FrameworkZ.Awaits:WaitUntil() must be called from a running coroutine."
	end

	local ticksRemaining = maxTicks or 180
	local startedTicks = ticksRemaining

	-- Counts ticks rather than comparing getTimestamp() against a deadline: getTimestamp()'s
	-- units are not seconds here, so "+ timeout" previously expired on the very first re-check.
	local result, message = self:Await(function(resolve)
		local tickCallback

		tickCallback = function()
			local results = FrameworkZ.Utilities:Pack(predicate())

			if results[1] then
				Events.OnTick.Remove(tickCallback)
				resolve(unpackFrom(results, 1))
				return
			end

			ticksRemaining = ticksRemaining - 1

			if ticksRemaining <= 0 then
				Events.OnTick.Remove(tickCallback)
				resolve(false, "FrameworkZ.Awaits:WaitUntil() timed out after " .. tostring(startedTicks) .. " ticks.")
			end
		end

		Events.OnTick.Add(tickCallback)

		return "WaitUntil"
	end, 0)

	if not result then
		print("[FZ] WaitUntil: " .. tostring(message))
	end

	return result, message
end

--! \brief Update pending awaits and fail any that have timed out.
function FrameworkZ.Awaits:OnTick()
	local now = getTimestamp()
	local expired = {}

	for awaitID, pending in pairs(self.Pending) do
		if not pending.Thread or coroutine_status(pending.Thread) == "dead" then
			self.Pending[awaitID] = nil
		elseif pending.TimeoutAt and now >= pending.TimeoutAt then
			table_insert(expired, {
				AwaitID = awaitID,
				Message = buildAwaitError("Await request timed out", pending.Description or pending.RequestID)
			})
		end
	end

	for _, entry in ipairs(expired) do
		self:ResumePending(entry.AwaitID, false, entry.Message)
	end
end

Events.OnTick.Add(function()
	FrameworkZ.Awaits:OnTick()
end)
