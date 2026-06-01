# SuffX Library

This library provides structural utility for encoding numerical values into formatted, short-scale suffixed strings and parsing them back into raw numbers. It is written in a statically typed Luau dialect, leveraging conditional compilation flags to balance execution speed, safety verification, and structural flexibility.

---

## Usage

The module returns an array containing the central execution wrapper, the active operations list, and the registered suffix data configuration.

```lua
local SuffXLib= require(path.to.module)
local Main = SuffXLib[1]
local Operations = SuffXLib[2]
local Suffixes = SuffXLib[3]

```

### Supported Operations

#### 1. `info`

Returns structural cache metadata utilized internally for suffix parsing.

* **Input**: `nil` or an optional whitelist table configuration.
* **Output**: A dictionary containing `KeyOrder`, `Indexes`, and `Powers` calculations.

#### 2. `getsuffix`

Retrieves positional suffix breakdown metadata from a numeric value.

* **Input array format**: `{Number, FullName?, Complete?}`
* **Input dictionary format**: `{Number = number, FullIdx = boolean?, Complete = boolean?}`

#### 3. `tosuffix`

Formats a raw numerical input into a string containing the appropriate abbreviated or full denomination suffix.

* **Input array format**: `{Number, FullName?, Decimals?, LeftIndex?}`
* **Input dictionary format**: `{Number = number, FullIdx = boolean?, Decimals = number?, LeftAttch = boolean?}`
* **Example Output**: `"1.50 Million"` or `"1.5 K"`

#### 4. `tonumber`

Parses a formatted string representation containing a valid numerical token and a suffix identifier back into a raw double-precision float.

* **Input**: `string`
* **Example Output**: `1500000`

---

## Compile Variables

These values are evaluated statically at module definition to establish memory performance baselines and structural behaviors.

| Variable | Type | Default | Description |
| --- | --- | --- | --- |
| `FlexRT` | `boolean` | `true` | Enables runtime flexibility. Wraps structural variables in localized proxy tables for hot-reloaded configuration synchronization. Adds minor execution overhead. |
| `HotPath` | `boolean` | `true` | Pre-computes structural index lookups (`KeyOrder`, `Indexes`, `Powers`) during initialization to accelerate operational response windows with minimal memory footprints. |
| `StrictRT` | `boolean` | `false` | Toggles runtime malformed string input corrections. Setting this to `true` disables automatic string case-lowering, strictly treating inputs as case-sensitive. |
| `StrictDB` | `boolean` | `true` | Enforces runtime type validation on parameters passed to operations. Intended for development environments to simplify data flow debugging. |

---

## Runtime Variables

These variables regulate localized parsing operations and lookups. If `FlexRT` is activated, alterations propagate dynamically through custom structural proxies.

* **`Suffixes`**: Map indexing structural groupings to arrays declaring `[1] = Short Abbreviation` and `[2] = Full Name`. Configured natively from 10^3 (`K`) through 10^36 (`Ud`). Maximum precision supports scales up to approximately 10^306.
* **`Operations`**: String collection declaring valid primary keywords intended for parameter routing inside the main logic. Includes `"info"`, `"getsuffix"`, `"tosuffix"`, and `"tonumber"`.

---

## Annotated Modification Instructions

### Extending Suffix Precision

To add higher order scales beyond Undecillion, insert entries into the `Suffixes` dictionary using the correct multiplier exponent power as the lookup key:

```lua
local Suffixes:{[number]:{string}} = {
    -- Existing configurations...
    [36] = {"Ud", "Undecillion"},
    -- Custom Addition: Duodecillion (10^39)
    [39] = {"Dd", "Duodecillion"} 
}

```

### Implementing Long-Scale or Custom Base Math

The library assumes standard western short-scale formatting optimized via pattern matches (`math.log10(Numb)` calculations). If altering the intervals of `Suffixes` to irregular numerical boundaries:

1. Locate the pattern optimization section within the local function `GetVal`.
2. Comment out the optimized log boundary block:
```lua
-- const Len = math.max(math.log10(Numb), 1)
-- return {Len-Len%3}
```
3. Uncomment the fallback iteration procedures immediately preceding it to verify dynamic scale groupings safely.

4. Repeat the procedure for the `getsuffix` handle.
---

## Technical Specifications and Constraints

> [!WARNING]
> Negative numerical input processing is temporarily restricted. Negative numbers passed into internal functions will clear to zero thresholds via math.max(Number, 0) evaluation lines. As a temporary workaround, apply math.abs and reprocess the resulting outputs.

> getsuffix and tosuffix indexed inputs handles are case-sensitive, regardless of StrictRT.

* **Type Constraints**: Parameterized dictionaries accept arguments under both positional arrays and typed string-key indexing structures defined by the type of thefirst argument (`Data.Number` vs `Data[1]`). Ensure argument structures strictly match execution signatures if running under `StrictDB = true`.
* **Data Integrity**: If `HotPath` or `FlexRT` variables are set to `false`, internal collection indexes on `Suffixes` freeze natively using `table.freeze()` for optimization purposes and to preserve initial data configurations safely across isolated scopes.
