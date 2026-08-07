--! \page AwaitsExamples Await Usage Examples
--! \section AwaitsOverview Coroutine-Based Network Requests
--! FrameworkZ.Awaits wraps FrameworkZ's existing callback-based request flow so you can write sequential coroutine code for networked requests.
--! Use `FrameworkZ.Awaits:Run()` to enter a managed coroutine, then call `FrameworkZ.Awaits:SendFire()`, `FrameworkZ.Awaits:GetData()`, or `FrameworkZ.Awaits:SetData()` from inside it.
--!
--! \code lua
--! if isServer() then
--!     FrameworkZ.Foundation:Subscribe("MyPlugin.GetGreeting", function(data, targetName)
--!         if not data.isoPlayer then return false, "Missing player." end
--!
--!         return true, "Hello, " .. tostring(targetName) .. "."
--!     end)
--! end
--!
--! if isClient() then
--!     FrameworkZ.Awaits:Run(function()
--!         local success, message = FrameworkZ.Awaits:SendFire(getPlayer(), "MyPlugin.GetGreeting", "Citizen")
--!
--!         if not success then
--!             print("[MyPlugin] Request failed: " .. tostring(message))
--!             return
--!         end
--!
--!         print("[MyPlugin] Server replied: " .. tostring(message))
--!     end)
--! end
--! \endcode
--!
--! \section AwaitsPersistence Awaiting Persistence Requests
--! Await helpers also work with FrameworkZ.Foundation data access wrappers.
--!
--! \code lua
--! if isClient() then
--!     FrameworkZ.Awaits:Run(function()
--!         local _, namespace, keys, value = FrameworkZ.Awaits:GetData(getPlayer(), "Players", getPlayer():getUsername())
--!
--!         if not value then
--!             print("[MyPlugin] No player data returned.")
--!             return
--!         end
--!
--!         value.LastGreeting = "Welcome back"
--!         local ok, err = FrameworkZ.Awaits:SetData(getPlayer(), "Players", getPlayer():getUsername(), value)
--!
--!         if not ok then
--!             print("[MyPlugin] Failed to save player data: " .. tostring(err))
--!         end
--!     end)
--! end
--! \endcode
--!
--! Awaited requests must run inside `FrameworkZ.Awaits:Run()` and require a valid player object when a server confirmation is expected.
--!
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
	local expiresAt = timeout == 0 and nil or (getTimestamp() + (timeout or self.DefaultTimeout))

	self.Pending[awaitID] = {
		Thread = thread,
		StartedAt = getTimestamp(),
		TimeoutAt = expiresAt,
		RequestID = nil,
		Description = nil
	}

	local function resolve(...)
		return self:ResumePending(awaitID, true, ...)
	end

	local started, requestID = pcall(requestStarter, resolve, ...)

	if not started then
		self.Pending[awaitID] = nil
		return false, buildAwaitError("Failed to start await request", requestID)
	end

	local pending = self.Pending[awaitID]

	if not pending then
		return false, "Await request resolved before it could be yielded."
	end

	pending.RequestID = requestID or awaitID
	pending.Description = requestID or awaitID

	local resumedValues = FrameworkZ.Utilities:Pack(coroutine_yield(awaitID))

	if not resumedValues[1] then
		return false, unpackFrom(resumedValues, 2)
	end

	return unpackFrom(resumedValues, 2)
end

--! \brief Run a function inside a managed coroutine.
--! \param callback \function The function to execute inside the coroutine.
--! \param ... \multiple Arguments forwarded to the callback.
--! \return \mixed Returns the coroutine thread when suspended, or the callback return values if it completed immediately.
function FrameworkZ.Awaits:Run(callback, ...)
	if type(callback) ~= "function" then
		return false, "Invalid callback supplied to FrameworkZ.Awaits:Run()."
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
		return FrameworkZ.Foundation:SendFire(isoPlayer, subscriptionID, resolve, ...)
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
