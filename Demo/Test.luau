const Main, Operations, Suffixes = unpack(require(game.ServerStorage.Libs.Suffixes))

Operations[1] = "inf"
print("Testing: info")
print(Main("inf"))

print("\nTesting: tosuffix")
print(Main("tosuffix", {1657000, true, 2, false}))
print(Main("tosuffix", {Number = 784572483.34, FullIdx = true, Complete = true}))

print("\nTesting: tonumber")
print(Main("tonumber", "1.5M"))
print(Main("tonumber", "2million"))

print("\nTesting: getsuffixes")
print(Main("getsuffix", {123, true}))
print(Main("getsuffix", {1000000, true}))
print(Main("getsuffix", {10000000, true, true}))
print(Main("getsuffix", {81729000, false, true}))
warn(select(2, pcall(Main, "QWERTY", {000000, false, false})))
