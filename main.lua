local getgenv = getgenv or function()
	return getfenv(0)
end

local Typeof, Type = typeof, type
local newproxy, getmetatable, assert, next, pcall, tostring, rawget, error = newproxy, getmetatable, assert, next, pcall, tostring, rawget, error

local tinsert, tunpack, tfind, tmove = table.insert, table.unpack, table.find, table.move
local format, split, rep, sub, gsub = string.format, string.split, string.rep, string.sub, string.gsub

local Sandboxed, SandboxedData = {}, {}
local Signals = {}

local Options = {
	Hooks = {}, -- Format it like: DataModel = {{"OpenScreenshotsFolder", function() while true do end end}} ReplicatedStorage = {}
	Blocked = {
		DataModel = {
			"OpenScreenshotsFolder"
		},
		ScriptProfilerService = {
			"SaveScriptProfilingData"
		},
		ScriptContext = {
			"_ALL" -- fuck you script context burn
		},
		CaptureService = {
			"_ALL"
		}
	}
}

local function Sandbox()end;
local function RBXScriptSignal()end;

local function ReverseGet(Value, Table)
	Table = Table or Sandboxed
	for Key, Value1 in next, Table do
		if Value1 == Value then
			return Key
		end
	end
end

local function Secure(A, ...)
	if Typeof(A) == "table" then
		local Value2 = {};

		for i, v in next, A do
			Value2[i] = Secure(v, ...)
		end

		return Value2
	elseif Typeof(A) == "Instance" then
		return Sandbox(A)
	elseif Typeof(A) == "RBXScriptSignal" then
		return Signals[A] or RBXScriptSignal(A)
	elseif Typeof(A) == "function" then
		local Object, Key, AllowRealValues = tunpack({...})
		Object = Object

		return function(...)
			local Args = {...}
			Args[1] = ReverseGet(Args[1])
			
			if not AllowRealValues then
				return Secure(
					Object[Key](tunpack(Args))
				)
			else
				local Args2 = {}

				for a, b in next, Args do
					Args2[a] = ReverseGet(b) or b
				end

				return Secure(Object[Key](tunpack(Args2)))
			end
		end
	else
		return A
	end
end

RBXScriptSignal = function(Original: RBXScriptSignal)
	local function Call(f, ...)
		local Args = Secure({...})

		f(tunpack(Args))
	end

	local userdata = newproxy(true);	
	local self = getmetatable(userdata);

	self.__index = function(_, Key) -- self.__index(self, "Once")
		local Success, A = pcall(function()
			return Original[Key]
		end)
		assert(Success, A)
		return function(_, f)
			return Original[Key](Original, function(...)
				Call(f, ...)
			end)
		end
	end
	self.__metatable = "The metatable is locked"
	self.__tostring = function()
		return "RBXScriptSignal"
	end

	Signals[Original] = userdata

	return userdata
end

Sandbox = function(Object, Default, OpposeOnMethods)
	if Sandboxed[Object] or not Object then
		return Sandboxed[Object]
	end

	Default = Default or {}
	OpposeOnMethods = OpposeOnMethods or {}

	local userdata = newproxy(true)
	local mt = getmetatable(userdata)

	local Blocked = Options.Blocked[Object.ClassName] or {}
	local Hooks = Options.Hooks[Object.ClassName] or {}

	local BLOCK_ALL = tfind(Blocked, "_ALL")

	local e = function()error("[SANDBOX] Blocked Function", 2)end

	for a, b in next, Default do
		mt[a] = b
	end

	for _, b in next, Blocked do
		mt[b] = e
	end

	local function find(tbl, key, a)
		a = a or tbl
		for _, Value in next, tbl do
			if sub(key, 1, #Value) == Value then
				return a[Value]
			end
		end
	end

	mt.__index = function(_, key)
		local Block = find(Blocked, key, mt)

		for _, Method in next, Options.Hooks do
			local Name = Method[1]
			local Dotted = split(Name, ".") -- LocalPlayer.Kick -> {"LocalPlayer", "Kick"}
			local Piece = Dotted[#Dotted]

			if sub(key, 1, #Piece) == Piece then
				return Method[2]
			end
		end

		if Block then
			return Block
		elseif BLOCK_ALL and Typeof(Object[key]) == "function" then
			return e
		end

		return Secure(Object[key], Object, key, (
			not find(OpposeOnMethods, key) -- fxix
		))
	end

	mt.__newindex = function(_, k, v)
		Object[k] = ReverseGet(v) or v
	end

	mt.__metatable = "The metatable is protected"
	mt.__tostring = function()
		return tostring(Object) -- watafuck tostring(Object) is faster than Object.Name!!
	end

	Sandboxed[Object] = userdata

	return userdata
end

local function HookService(Service, Methods)
	Options.Hooks[Service] = Methods
end

local Instance_New = Instance.new

getgenv().Instance = table.freeze({
	new = function(Class, Parent)
		local Fake = Instance_New(Class);

		if Typeof(Parent) == "userdata" then
			Fake.Parent = ReverseGet(Parent);
		end

		return Sandbox(Fake)
	end,
	fromExisting = function(Fake)
		return Sandbox(ReverseGet(Fake) or Fake)
	end,
})

getgenv().typeof = function(a)
	if ReverseGet(a) then
		return "Instance"
	elseif ReverseGet(a, Signals) then
		return "RBXScriptSignal"
	end

	return Typeof(a)
end

--[[
Example usage of HookService:
HookService("Players", {
	"LocalPlayer.Kick", print
})
Prevents the localplayer from being kicked
]]

--[[ Do this to sandbox every instance.]]
getgenv().game = Sandbox(game)
getgenv().Game = game
getgenv().workspace = game.Workspace
getgenv().Workspace = game.Workspace
getgenv().script = Sandbox(script)