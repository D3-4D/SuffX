const FlexRT: boolean = false -- Runtime flexibility setting, slight processing overhead
const HotPath: boolean = true -- Runtime optimization measures, slight memory overhead
const StrictRT:boolean = false -- Runtime malformatted input error correction toggle (true = off)
const StrictDB:boolean = true -- Enforces correct parameter types for debugging

-- Runtime fixed variables
----
-- Runtime modifiable variables

local Suffixes:{[number]:{string}} = { -- [zeros] = {"abbreviation", "full"}
	[3] = {"K", "Thousand"},
	[6] = {"M", "Million"},
	[9] = {"B", "Billion"},
	[12] = {"T", "Trillion"},
	[15] = {"Qa", "Quadrillion"},
	[18] = {"Qi", "Quintillion"},
	[21] = {"Sx", "Sextillion"},
	[24] = {"Sp", "Septillion"},
	[27] = {"Oc", "Octillion"},
	[30] = {"No", "Nonillion"},
	[33] = {"Dc", "Decillion"},
	[36] = {"Ud", "Undecillion"}
} -- Max precision = 308

local Operations:{string} = {
	"info",
	"getsuffix",
	"tosuffix",
	"tonumber"
}--[[
[1] = Returns structural processing information for the suffixes

Inputs: {[WhitelistKey(strict("K"|"I"|"P") )] (boolean)}?
Outputs: {["KeyOrder"] (table?), ["Indexes"] (table?), ["Powers"] (table?)}

[2] Returns all (numerical) input correspondent suffixes
...
[3] = Returns transformed (suffixed) input into it's numerical form
...
[4] = Returs transformed (numerical) input into it's suffixed form
...

]]

-- Safe to change
----
-- Unsafe to change

const CommonErrs:{[number]:string}? = StrictDB and table.freeze({
	"Invalid arguments. Expected %s, got %s."
}) or nil

if StrictDB then
	--[[
	for _, Obj in {FlexRT, HotPath, StrictDB, StrictRT} do
		assert(type(Obj)=="boolean")
	end
	--]]
	assert(type(FlexRT) == "boolean", CommonErrs[1]:format("boolean", type(FlexRT) ) )
	assert(type(HotPath) == "boolean", CommonErrs[1]:format("boolean", type(HotPath) ) )
	assert(type(StrictDB) == "boolean", CommonErrs[1]:format("boolean", type(StrictDB) ) )
	assert(type(StrictRT) == "boolean", CommonErrs[1]:format("boolean", type(StrictRT) ) )
	
	assert(type(Suffixes) == "table", CommonErrs[1]:format("table", type(Suffixes) ) )
	assert(type(Operations) == "table", CommonErrs[1]:format("table", type(Operations) ) )
end

local KeyOrder:{[number]: number}? = HotPath and {} or nil -- Iterable ordered 'Suffixes' indexes
local Indexes:{[number]: string}? = HotPath and {} or nil -- Indexes all denominations to it's respective 'Suffixes' index
local Powers:{[number]: number}? = HotPath and {} or nil -- Preregisters 'Suffixes' indexes in it's respective (log10) numerical format

-- Adds overhead
const CustProxyTab = FlexRT and function(Tab, OnWrite:()->any?, OnRead:()->any?, RawProxy:boolean?)
	if StrictDB then
		assert(type(Tab) == "table", CommonErrs[1]:format("table", type(Tab) ) )
		assert(type(OnRead) == "function" or (OnRead == nil and OnWrite), CommonErrs[1]:format("function?", type(OnRead) ) )
		assert(type(OnWrite) == "function" or (OnWrite == nil and OnRead), CommonErrs[1]:format("function?", type(OnWrite) ) )
		assert(type(RawProxy) == "boolean" or RawProxy == nil, CommonErrs[1]:format("boolean?", type(RawProxy) ) )
	end

	return setmetatable({}, {
		__newindex = (not OnWrite and not RawProxy) and Tab or function(Self, Idx, Value)
			const Exists = rawget(Tab, Idx)

			if OnWrite then
				pcall(OnWrite, Idx, Exists, true) -- Prefer adding "task.defer" layer, if not procedural logic
			end

			if RawProxy then
				rawset(Tab, Idx, Value)
			else
				Tab[Idx] = Value
			end

			rawset(Self, Idx, nil)
		end,
		__index = (not OnRead and not RawProxy) and Tab or function(_, Idx)
			const Exists = rawget(Tab, Idx)

			if OnRead then
				pcall(OnRead, Idx, Exists, true) -- Prefer adding "task.defer" layer, if not procedural logic
			end
		end,
		__iter = function()
			return next, Tab
		end,
		__len = function()
			return RawProxy and rawlen(Tab) or #Tab
		end,
	})
end or nil

const function GetStruct(Whitelist:{string}?): {[string]:{[number]:{(number|string)?} }? }
	if StrictDB then
		assert(type(Whitelist) == "table" or Whitelist == nil, CommonErrs[1]:format("table?", type(Whitelist) ) )
	end

	local nw = not Whitelist

	const KOn = nw and true or Whitelist["K"] or not StrictRT and Whitelist["k"]
	const IOn = nw and true or Whitelist["I"] or not StrictRT and Whitelist["i"]
	const POn = nw and true or Whitelist["P"] or not StrictRT and Whitelist["p"]

	if nw and not (KOn and IOn and POn) then
		return {}
	end

	nw = nil

	const Ret = {KeyOrder=KOn and {} or nil, Indexes=IOn and {} or nil, Powers=POn and {} or nil}

	for Idx, Val in Suffixes do
		if KOn then
			table.insert(Ret.KeyOrder, Idx)
		end
		if IOn then
			Ret.Indexes[StrictRT and Val[1] or Val[1]:lower()] = Idx
			Ret.Indexes[StrictRT and Val[2] or Val[2]:lower()] = Idx
		end
		if POn then
			Ret.Powers[Idx] = 10^Idx
		end
	end

	if KOn then
		table.sort(Ret.KeyOrder)
	end

	return Ret
end

const function GetVal(Numb:string|number): number?|{number?}
	if StrictDB then
		assert(type(Numb) == "string" or type(Numb) == "number", CommonErrs[1]:format("number|string", type(Numb) ) )
	end

	if type(Numb) == "string" and not tonumber(Numb) then
		const Hit = Numb:gsub("[%d%.%s]+", "")

		if HotPath then
			return Indexes[Hit]
		end

		const SrchIdx = Hit:len() < 5 and 1 or 2 -- Abbreviation or prolonged
		
		for Idx, Obj in Suffixes do
			if Obj[SrchIdx] == Hit then
				return Idx
			end
		end

		return nil
	else
		Numb = tonumber(Numb)
		
		--[[
		--
		local Proc = HotPath and {KeyOrder = KeyOrder, Powers = Powers} or GetStruct({["K"] = true, ["P"] = true})

		const Order = Proc.KeyOrder
		const Pow = Proc.Powers
		
		Proc = nil
		if (Numb < Pow[Order[1] ] ) then
			return nil
		end
		
		const Ret = {}
	
		for Idx, Val in Order do
			if Pow[Val] > Numb then
				break
			else
				table.insert(Ret, Val)
			end
		end

		return Ret
		--
		--]]

		-- [WARNING]: Pattern-based optimization! Only keep implementation if you intend to use the short-scale naming system.
		-- | Otherwise, uncomment preceding procedure and remove the following statement.
		-- | Also check "getsuffix" handle.
		
		--
		const Len = math.max(math.log10(Numb), 1)
		return {Len-Len%3}
		--
	end
end

const function Main(Operation:string, Data)
	Operation = StrictRT and Operation or Operation:lower()

	if Operation == Operations[1] then -- info
		return HotPath and {KeyOrder=KeyOrder, Indexes=Indexes, Powers=Powers} or GetStruct()
	elseif Operation == Operations[2] or Operation == Operations[3] then -- getsuffix / tossufix
		if StrictDB then
			assert(type(Data) == "table", CommonErrs[1]:format("table", type(Data) ) )
		end
		
		local Indexed = Data.Number ~= nil
		local Number:number|string = Indexed and Data.Number or Data[1]

		if StrictDB then
			assert(type(Number) == "number" or type(Number) == "string", CommonErrs[1]:format("number", type(Number) ) )
		end
			
		Number = tostring(math.floor(math.max(Number, 0) ) )-- removed support for negatives (temp)

		const FullName:boolean = Data[Indexed and "FullIdx" or 2]
		const NumIdx = #Number

		if Operation == Operations[2] then -- getsuffix
			Indexed = nil
			
			const Complete = Data[Indexed and "Complete" or 3]
			
			if NumIdx < (HotPath and KeyOrder[1] or next(Suffixes)) then
				return {}
			end

			const Ret = {}
			const Itt = GetVal(Number)
			const Curr = Itt[#Itt]
			
			if not Suffixes[Curr] then
				return {}
			end
			
			--[[ Uncheck this for unpatterned mode!!
			-- (and remove the subsequent statements)
			-- (check "GetVal")
			
			--
			if Complete then
				for Idx, Val in Itt do
					Ret[Suffixes[Val][FullName and 2 or 1] ] = Number:sub(NumIdx-((Itt[next(Itt, Idx)] or NumIdx)-1), NumIdx-Val)
				end
			else
				Ret[Suffixes[Curr][FullName and 2 or 1] ] = true--Number:sub(NumIdx-((Itt[next(Itt, Idx)] or NumIdx)-1), NumIdx-Curr)
			end
			--
			
			--]]
			
			--
			--const Order = HotPath and KeyOrder or GetStruct({["K"] = true}).KeyOrder
			if Complete then
				const Order = HotPath and KeyOrder or GetStruct({["K"] = true}).KeyOrder
				for Idx, Val in Order do
					Ret[Suffixes[Val][FullName and 2 or 1] ] = Number:sub(NumIdx-((Order[next(Order, Idx)] or NumIdx)-1), NumIdx-Val)
					if Val == Curr then
						break
					end
				end
			else
				Ret[Suffixes[Curr][FullName and 2 or 1] ] = true
				--Ret[Suffixes[Curr][FullName and 2 or 1] ] = Number:sub(NumIdx-((Order[next(Order, Idx)] or NumIdx)-1), NumIdx-Val)
			end
			--
			
			return Ret
		else -- tosuffix
			local Decimals:number = Data[Indexed and "Decimals" or 3]
			Decimals = Decimals and math.max(Decimals, 1)
			
			const LeftIndex:boolean = Data[Indexed and "LeftAttch" or 4]
			local S = GetVal(Number)

			S = S[#S]
			const Sf = Suffixes[S]
			
			const Pn = Decimals and Number:sub(1, NumIdx-S).."."..Number:sub(NumIdx-S+1, Decimals+1) or
				Number:sub(1, NumIdx-S)

			return (LeftIndex and Sf[FullName and 2 or 1] or Pn).." "..(LeftIndex and Pn or Sf[FullName and 2 or 1])
		end
	elseif Operation == Operations[4] then -- tonumber
		assert(type(Data) == "string", "Invalid conversion type. Expected string, got "..type(Data)..".")

		if not StrictRT then
			Data = Data:lower()
		end

		const S = GetVal(Data)

		Data = Data:gsub("[^%d%.]+", "")

		const DecimalSplit = Data:split(".")

		const Unit = (HotPath and Powers[S] or 10^S) or 1

		DecimalSplit[2] = DecimalSplit[2] or "0"

		return 
			tonumber(DecimalSplit[1]) * Unit +
			(HotPath and Powers[S-#DecimalSplit[2]] or 10^(S-#DecimalSplit[2]))* DecimalSplit[2]
	else
		error("Invalid operation: '"..Operation.."'.")
	end
end

if not StrictRT then
	const function Upd(Idx)
		Operations[Idx] = Operations[Idx] and Operations[Idx]:lower() or nil
	end
	
	for Idx,_ in Operations do
		Upd(Idx)
	end

	Operations = FlexRT and CustProxyTab(Operations, Upd, nil, true) or table.freeze(Operations)
end

if HotPath then
	const function Upd()
		const Temp = GetStruct()
		KeyOrder, Indexes, Powers = table.freeze(Temp.KeyOrder), table.freeze(Temp.Indexes), table.freeze(Temp.Powers)
	end

	Upd()

	if not FlexRT then
		table.freeze(Suffixes)
		Suffixes = Suffixes
	else
		Suffixes = CustProxyTab(Suffixes, Upd, nil, true)
	end
end

const R = {Main, Operations, Suffixes}
return R
