-------------------------------------------------------------------------------
-- Copyright (C) Hispidence 2013-2021
--
--
-- utils.lua
--
-- Misc utility functions
-------------------------------------------------------------------------------



local jlutil = {}



-------------------------------------------------------------------------------
-- unrequire
--
--
-------------------------------------------------------------------------------
function jlutil.unrequire(module)
	package.loaded[module] = nil
  _G[module] = nil
end



-------------------------------------------------------------------------------
-- jRound
--
-- Rounds a floating-point number to its nearest whole.
-------------------------------------------------------------------------------
function jlutil.jRound(n)
	if n >= 0 then return math.floor(n + 0.5)
	else return math.ceil(n - 0.5) end
end



-------------------------------------------------------------------------------
-- jlSplit
--
-- Splits the string into a table of values, using anything other than a
-- letter, number, underscore, or hyphen as a delimiter.
-------------------------------------------------------------------------------
function jlutil.jlSplit(str)
  local vals = {}
  for s in str:gmatch("[%w_-]+") do
    vals[#vals + 1] = s
  end
  return vals
end



-------------------------------------------------------------------------------
-- jlSplitKV
--
-- Splits the string into a table of values, using anything other than a
-- letter, number, underscore, or hyphen as a delimiter. Additionally, this
-- function returns a key-value table.
-------------------------------------------------------------------------------
function jlutil.jlSplitKV(str)
  local vals = jlutil.jlSplit(str)
  local kvVals = {}
  for i = 1, #vals, 2 do
    if nil == vals[i+1] then
      print("Warning! jlSplitKV mismatch; no value found for string \"" ..
        vals[i] .. "\".")
    end
    kvVals[vals[i]] = vals[i+1]
  end
  return kvVals
end

return jlutil
