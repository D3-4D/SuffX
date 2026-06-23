const Suffx = require(game.ServerStorage.Libs.S0S.SuffX)

const Main = Suffx.Main
const Operations = Suffx.Operations
const Settings = Suffx.Settings

const Abstract = Settings.AbstractMethods

if Settings.FlexRT then
	Operations[1] = "information_test"
end

print("Testing: info (", Operations[1], ").")
print(
	if Abstract
		then Main[Operations[1] ]()
		else Main(Operations[1])
)

print("Testing: tosuffix")
print(
	if Abstract
		then Main.tosuffix(1657000, true, 2, false)
		else Main("tosuffix", {1657000, true, 2, false})
)
print(
	if Abstract
		then Main.tosuffix(784572483.34, true, nil, true)
		else Main("tosuffix", {Number = 784572483.34, FullIdx = true, Complete = true})
)

print("Testing: tonumber")
print(
	if Abstract
		then Main.tonumber("1.5M")
		else Main("tonumber", "1.5M")
)
print(
	if Abstract
		then Main.tonumber("2million")
		else Main("tonumber", "2million")
)

print("Testing: getsuffixes")
print(
	if Abstract
		then Main.getsuffix(123, true)
		else Main("getsuffix", {123, true})
)
print(
	if Abstract
		then Main.getsuffix(1000000, true)
		else Main("getsuffix", {1000000, true})
)
print(
	if Abstract
		then Main.getsuffix(10000000, true, true)
		else Main("getsuffix", {10000000, true, true})
)
print(
	if Abstract
		then Main.getsuffix(8172900000, false, true)
		else Main("getsuffix", {8172900000, false, true})
)

print("Testing error calls")
if Abstract then
	warn(select(2, pcall(function() Main.nonexistent() end) ) )
else
	warn(select(2, pcall(Main, "QWERTY", {000000, false, false}) ) )
end
