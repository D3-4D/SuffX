--[[

Copyright [2026] [S0Studios]

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

--]]


const FlexRT:boolean = false -- Runtime flexibility setting, moderate processing overhead
const AbstractMethods:boolean = true -- Return simplified main call wrapper with abstracted methods, negligible processing overhead
const StrictDB:boolean = true -- Enforces correct parameter types for debugging, negligible processing overhead
const StrictRT:boolean = false -- Runtime malformatted input error correction toggle (true = off.) When off, negligible processing overhead
const HotPath:boolean = true -- Runtime optimization measures, negligible memory overhead


-- Runtime fixed variables
----
-- Runtime modifiable variables

const Suffixes:{[number]:{[number]: string} } = { -- [zeros] = {"abbreviation", "full"}
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
} -- Max precision = 306-308 (~= 10^3 centillion)

const Operations:{[number]: string} = {
	"info",
	"getsuffix",
	"tosuffix",
	"tonumber"
} -- Parameter and output guidance available in abstraction mode
-- For alterations made, check type declaration at line 421 for manual correction

--[[

- Functions

[1] = Returns structural processing information for the suffixes

[2] Returns the (numerical) input's correspondent suffix(es)

[3] = Returns the transformed (numerical) inputs as it's suffixed format

[4] = Returns transformed (suffixed) input as it's numerical format

]]

-- Safe to change
----
-- Unsafe to change

const CommonErrs:{[number]:string}? = StrictDB and table.freeze({
	"Invalid arguments. Expected %s, got %s."
}) or nil

if StrictDB then
	for _, Obj in {FlexRT, HotPath, StrictDB, StrictRT} do
		assert(type(Obj)=="boolean", CommonErrs[1]:format("boolean", type(Obj) ) )
	end
end

local KeyOrder:{[number]: number}? = HotPath and {} or nil -- Iterable ordered 'Suffixes' indexes
local Indexes:{[number]: string}? = HotPath and {} or nil -- Indexes all denominations to it's respective 'Suffixes' index
local Powers:{[number]: number}? = HotPath and {} or nil -- Preregisters 'Suffixes' indexes in it's respective numerical format (in powers of 10)

-- Adds overhead
const CustProxyTab = FlexRT and function(Tab, OnWrite:(MetaMethod:boolean, Idx:number, Value:any)->any?, OnRead:(MetaMethod:boolean, Idx:number)->any?, RawProxy:boolean?)
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
				pcall(OnWrite, true, Idx, Value) -- Prefer adding "task.defer" layer, if not procedural logic
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
				pcall(OnRead, true, Idx) -- Prefer adding "task.defer" layer, if not procedural logic
			end
			return Exists
		end,
		__iter = function()
			return next, Tab
		end,
		__len = function()
			return RawProxy and rawlen(Tab) or #Tab
		end,
	})
end or nil

const function GetStruct(Whitelist:{[keyof<typeof({K=true,I=true,P=true})>]: boolean}?): {[string]:{[number]:{(number|string)?} }? }
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
		const Hit = Numb:gsub("[%d%.%s%-]+", "") -- Only include string (suffix)
			
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
		-- | Also check the "getsuffix" handle.

		--
		const Len = math.max(math.log10(Numb), 1)
		return {Len-Len%3}
		--
	end
end


const function Main(Operation:string, Data)
	Operation = StrictRT and Operation or Operation:lower()

	if Operation == Operations[1] then -- info
		return HotPath and {KeyOrder=KeyOrder, Indexes=Indexes, Powers=Powers} or GetStruct(Data)
	elseif Operation == Operations[2] or Operation == Operations[3] then -- getsuffix / tossufix
		if StrictDB then
			assert(type(Data) == "table", CommonErrs[1]:format("table", type(Data) ) )
		end

		local Indexed = Data.Number ~= nil
		local Number:number|string = Indexed and Data.Number or Data[1]

		if StrictDB then
			assert(type(Number) == "number" or type(Number) == "string", CommonErrs[1]:format("number", type(Number) ) )
		end
	
		const Sign = tonumber(Number) < 0 and "-" or ""
		Number = tostring(math.abs(math.floor(Number) ) )
		
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
				Ret[1] = SFX
				
				Ret[SFX] = true -- Alternative
				--Ret[SFX] = Number:sub(NumIdx-((Itt[next(Itt, Idx)] or NumIdx)-1), NumIdx-Curr) -- Optional
			end
			--
			
			--]]

			--
			--const Order = HotPath and KeyOrder or GetStruct({["K"] = true}).KeyOrder -- Optional
			if Complete then
				const Order = HotPath and KeyOrder or GetStruct({["K"] = true}).KeyOrder
				for Idx, Val in Order do
					const SFX = Suffixes[Order[Idx]][FullName and 2 or 1]

					Ret[SFX] = Sign .. Number:sub(math.max(1, NumIdx-( (Order[next(Order, Idx)] or NumIdx)-1) ), NumIdx-Val)
					if Val == Curr then
						break
					end
				end
			else
				const SFX = Suffixes[Curr][FullName and 2 or 1]
				Ret[1] = SFX
				
				Ret[SFX] = true -- Alternative
				--Ret[SFX] = Number:sub(NumIdx-((Order[next(Order, Idx)] or NumIdx)-1), NumIdx-Val) -- Optional
			end
			--

			return Ret
		else -- tosuffix
			local Decimals:number = Data[Indexed and "Decimals" or 3]
			Decimals = Decimals and math.max(Decimals, 1)

			const LeftIndex:boolean = Data[Indexed and "LeftAttch" or 4]
			local Idx = GetVal(Number)
			Idx = Idx[#Idx]

			const Sf = Suffixes[Idx]

			if Sf then
				const ParsedNum = Decimals and
					Sign .. Number:sub(1, NumIdx-Idx) .. "." .. Number:sub(NumIdx-Idx+1, Decimals+1) or
					Number:sub(1, NumIdx-Idx)

				return (LeftIndex and Sf[FullName and 2 or 1] or ParsedNum) .. " " .. (LeftIndex and ParsedNum or Sf[FullName and 2 or 1])
			else
				return nil
			end	
		end
	elseif Operation == Operations[4] then -- tonumber
		assert(type(Data) == "string", "Invalid conversion type. Expected string, got " .. type(Data) .. ".")

		if not StrictRT then
			Data = Data:lower()
		end
		
		const DecimalSplit = Data:gsub("[^%d%.]+", ""):split(".")
		const Decimal = DecimalSplit[2]

		const Idx = GetVal(Data)
		
		return
			(Data:find("-") and -1 or 1) * (tonumber(DecimalSplit[1]) * (HotPath and Powers[Idx] or 10^Idx) +
			(Decimal and ((HotPath and Powers[Idx-#Decimal] or 10^(Idx-#Decimal) ) * Decimal) or 0) )
	else
		error(StrictDB and CommonErrs[1]:format(string.format("Strict(\"%s\")", table.concat(Operations, "\"|\"")), Operation) or "Invalid operation: '" .. Operation .. "'.")
	end
end


local RetOp
if FlexRT then
	const Upd = FlexRT and function(ProxyMeta, Idx, Val)
		if ProxyMeta then
			rawset(Operations, Idx, Val)
		else
			Operations[Idx] = Val and (StrictRT and Val:lower() or Val) or nil
		end
	end or nil

	if StrictRT then
		for Idx, Val in Operations do
			Upd(false, Idx, Val)
		end
	end

	RetOp = CustProxyTab(Operations, Upd, nil, true)
else
	RetOp = table.freeze(Operations)
end

local RetSfx = Suffixes
if HotPath then
	const function Upd()
		const Struct = GetStruct()
		KeyOrder, Indexes, Powers = table.freeze(Struct.KeyOrder), table.freeze(Struct.Indexes), table.freeze(Struct.Powers)
	end

	Upd()

	RetSfx = FlexRT and CustProxyTab(Suffixes, Upd, nil, true) or table.freeze(Suffixes)
else
	RetSfx = FlexRT and Suffixes or table.freeze(Suffixes)
end

const Settings:{
	FlexRT: boolean,
	AbstractMethods:boolean,
	StrictDB:boolean,
	StrictRT:boolean,
	HotPath:boolean
} = table.freeze({
	FlexRT = FlexRT,
	AbstractMethods = AbstractMethods,
	StrictDB = StrictDB,
	StrictRT = StrictRT,
	HotPath = HotPath
})

if AbstractMethods then
	const Methods = table.freeze(setmetatable({
		-- Redundant declaration for reading ease

		[1] = function(Whitelist:{[keyof<typeof({K=true,I=true,P=true})>]: boolean}?) : {KeyOrder: {number}?, Indexes:{string}?, Powers:{number}?}
			return Main(Operations[1], Whitelist)
		end,

		[2] = function(Number: number|string, Unabbreviated: boolean?, Verbose: boolean?): {[string]: number?} | {(string & boolean)?}
			return Main(Operations[2], {Number, Unabbreviated, Verbose})
		end,

		[3] = function(Number: number|string, Unabbreviated: boolean?, DecimalCount: number?, LeftSidedSuffix:boolean?): string
			return Main(Operations[3], {Number, Unabbreviated, DecimalCount, LeftSidedSuffix})
		end,

		[4] = function(SuffixedNumber: string): string
			return Main(Operations[4], SuffixedNumber)
		end
	}, {__index = function(Self, Idx)
			return Idx and Self[table.find(Operations, StrictRT and Idx or Idx:lower())] or error("Invalid index.")
		end
	}))::{ -- EDIT MANUALLY
		["info"]: (Whitelist:{[keyof<typeof({K=true,I=true,P=true})>]: boolean}?) -> {KeyOrder: {number}?, Indexes:{string}?, Powers:{number}?},
		["getsuffix"]: (Number: number|string, Unabbreviated: boolean?, Verbose: boolean?) -> {[string]: number?} | {(string & boolean)?},
		["tosuffix"]: (Number: number|string, Unabbreviated: boolean?, DecimalCount: number?, LeftSidedSuffix:boolean?) -> string,
		["tonumber"]: (SuffixedNumber: string) -> string
	}
	
	return  {Main=Methods, Operations=RetOp, Suffixes=RetSfx, Settings=Settings}::{
		Main:typeof(Methods),
		Operations:string,
		Suffixes:string,
		Settings:typeof(Settings)
	}
else
	return {Main=Main, Operations=RetOp, Suffixes=RetSfx, Settings=Settings}::{
		Main:typeof(Main),
		Operations:string,
		Suffixes:string,
		Settings:typeof(Settings)
	}
end
