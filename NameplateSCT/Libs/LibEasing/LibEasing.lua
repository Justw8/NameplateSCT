---------------
-- LIBEASING --
---------------

local MAJOR, MINOR = "LibEasing-1.0", 1;
local LibEasing = LibStub:NewLibrary(MAJOR, MINOR);

if (not LibEasing) then
    return;
end

LibEasing.frame = LibEasing.frame or CreateFrame("Frame");

--
-- Original Lua implementations
-- from 'EmmanuelOga'
-- https://github.com/EmmanuelOga/easing/
--
-- Adapted from
-- Tweener's easing functions (Penner's Easing Equations)
-- and http://code.google.com/p/tweener/ (jstweener javascript version)
--

--[[
Disclaimer for Robert Penner's Easing Equations license:

TERMS OF USE - EASING EQUATIONS

Open source under the BSD License.

Copyright © 2001 Robert Penner
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

-- For all easing functions:
-- t = elapsed time
-- b = begin
-- c = change == ending - beginning
-- d = duration (total time)

local pow = math.pow
local sin = math.sin
local cos = math.cos
local pi = math.pi
local sqrt = math.sqrt
local abs = math.abs
local asin  = math.asin

local function linear(t, b, c, d)
  return c * t / d + b
end

local function inQuad(t, b, c, d)
  t = t / d
  return c * pow(t, 2) + b
end

local function outQuad(t, b, c, d)
  t = t / d
  return -c * t * (t - 2) + b
end

local function inOutQuad(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * pow(t, 2) + b
  else
    return -c / 2 * ((t - 1) * (t - 3) - 1) + b
  end
end

local function outInQuad(t, b, c, d)
  if t < d / 2 then
    return outQuad (t * 2, b, c / 2, d)
  else
    return inQuad((t * 2) - d, b + c / 2, c / 2, d)
  end
end

local function inCubic(t, b, c, d)
  t = t / d
  return c * pow(t, 3) + b
end

local function outCubic(t, b, c, d)
  t = t / d - 1
  return c * (pow(t, 3) + 1) + b
end

local function inOutCubic(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * t * t * t + b
  else
    t = t - 2
    return c / 2 * (t * t * t + 2) + b
  end
end

local function outInCubic(t, b, c, d)
  if t < d / 2 then
    return outCubic(t * 2, b, c / 2, d)
  else
    return inCubic((t * 2) - d, b + c / 2, c / 2, d)
  end
end

local function inQuart(t, b, c, d)
  t = t / d
  return c * pow(t, 4) + b
end

local function outQuart(t, b, c, d)
  t = t / d - 1
  return -c * (pow(t, 4) - 1) + b
end

local function inOutQuart(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * pow(t, 4) + b
  else
    t = t - 2
    return -c / 2 * (pow(t, 4) - 2) + b
  end
end

local function outInQuart(t, b, c, d)
  if t < d / 2 then
    return outQuart(t * 2, b, c / 2, d)
  else
    return inQuart((t * 2) - d, b + c / 2, c / 2, d)
  end
end

local function inQuint(t, b, c, d)
  t = t / d
  return c * pow(t, 5) + b
end

local function outQuint(t, b, c, d)
  t = t / d - 1
  return c * (pow(t, 5) + 1) + b
end

local function inOutQuint(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return c / 2 * pow(t, 5) + b
  else
    t = t - 2
    return c / 2 * (pow(t, 5) + 2) + b
  end
end

local function outInQuint(t, b, c, d)
  if t < d / 2 then
    return outQuint(t * 2, b, c / 2, d)
  else
    return inQuint((t * 2) - d, b + c / 2, c / 2, d)
  end
end

local function inSine(t, b, c, d)
  return -c * cos(t / d * (pi / 2)) + c + b
end

local function outSine(t, b, c, d)
  return c * sin(t / d * (pi / 2)) + b
end

local function inOutSine(t, b, c, d)
  return -c / 2 * (cos(pi * t / d) - 1) + b
end

local function outInSine(t, b, c, d)
  if t < d / 2 then
    return outSine(t * 2, b, c / 2, d)
  else
    return inSine((t * 2) -d, b + c / 2, c / 2, d)
  end
end

local function inExpo(t, b, c, d)
  if t == 0 then
    return b
  else
    return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
  end
end

local function outExpo(t, b, c, d)
  if t == d then
    return b + c
  else
    return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
  end
end

local function inOutExpo(t, b, c, d)
  if t == 0 then return b end
  if t == d then return b + c end
  t = t / d * 2
  if t < 1 then
    return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005
  else
    t = t - 1
    return c / 2 * 1.0005 * (-pow(2, -10 * t) + 2) + b
  end
end

local function outInExpo(t, b, c, d)
  if t < d / 2 then
    return outExpo(t * 2, b, c / 2, d)
  else
    return inExpo((t * 2) - d, b + c / 2, c / 2, d)
  end
end

local function inCirc(t, b, c, d)
  t = t / d
  return(-c * (sqrt(1 - pow(t, 2)) - 1) + b)
end

local function outCirc(t, b, c, d)
  t = t / d - 1
  return(c * sqrt(1 - pow(t, 2)) + b)
end

local function inOutCirc(t, b, c, d)
  t = t / d * 2
  if t < 1 then
    return -c / 2 * (sqrt(1 - t * t) - 1) + b
  else
    t = t - 2
    return c / 2 * (sqrt(1 - t * t) + 1) + b
  end
end

local function outInCirc(t, b, c, d)
  if t < d / 2 then
    return outCirc(t * 2, b, c / 2, d)
  else
    return inCirc((t * 2) - d, b + c / 2, c / 2, d)
  end
end

local function inElastic(t, b, c, d, a, p)
  if t == 0 then return b end

  t = t / d

  if t == 1  then return b + c end

  if not p then p = d * 0.3 end

  local s

  if not a or a < abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * pi) * asin(c/a)
  end

  t = t - 1

  return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
end

-- a: amplitud
-- p: period
local function outElastic(t, b, c, d, a, p)
  if t == 0 then return b end

  t = t / d

  if t == 1 then return b + c end

  if not p then p = d * 0.3 end

  local s

  if not a or a < abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * pi) * asin(c/a)
  end

  return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
end

-- p = period
-- a = amplitud
local function inOutElastic(t, b, c, d, a, p)
  if t == 0 then return b end

  t = t / d * 2

  if t == 2 then return b + c end

  if not p then p = d * (0.3 * 1.5) end
  if not a then a = 0 end

  local s

  if not a or a < abs(c) then
    a = c
    s = p / 4
  else
    s = p / (2 * pi) * asin(c / a)
  end

  if t < 1 then
    t = t - 1
    return -0.5 * (a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
  else
    t = t - 1
    return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p ) * 0.5 + c + b
  end
end

-- a: amplitud
-- p: period
local function outInElastic(t, b, c, d, a, p)
  if t < d / 2 then
    return outElastic(t * 2, b, c / 2, d, a, p)
  else
    return inElastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
  end
end

local function inBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  t = t / d
  return c * t * t * ((s + 1) * t - s) + b
end

local function outBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  t = t / d - 1
  return c * (t * t * ((s + 1) * t + s) + 1) + b
end

local function inOutBack(t, b, c, d, s)
  if not s then s = 1.70158 end
  s = s * 1.525
  t = t / d * 2
  if t < 1 then
    return c / 2 * (t * t * ((s + 1) * t - s)) + b
  else
    t = t - 2
    return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
  end
end

local function outInBack(t, b, c, d, s)
  if t < d / 2 then
    return outBack(t * 2, b, c / 2, d, s)
  else
    return inBack((t * 2) - d, b + c / 2, c / 2, d, s)
  end
end

local function outBounce(t, b, c, d)
  t = t / d
  if t < 1 / 2.75 then
    return c * (7.5625 * t * t) + b
  elseif t < 2 / 2.75 then
    t = t - (1.5 / 2.75)
    return c * (7.5625 * t * t + 0.75) + b
  elseif t < 2.5 / 2.75 then
    t = t - (2.25 / 2.75)
    return c * (7.5625 * t * t + 0.9375) + b
  else
    t = t - (2.625 / 2.75)
    return c * (7.5625 * t * t + 0.984375) + b
  end
end

local function inBounce(t, b, c, d)
  return c - outBounce(d - t, 0, c, d) + b
end

local function inOutBounce(t, b, c, d)
  if t < d / 2 then
    return inBounce(t * 2, 0, c, d) * 0.5 + b
  else
    return outBounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
  end
end

local function outInBounce(t, b, c, d)
  if t < d / 2 then
    return outBounce(t * 2, b, c / 2, d)
  else
    return inBounce((t * 2) - d, b + c / 2, c / 2, d)
  end
end

-- expose the functions into the library
LibEasing.Linear = linear;
LibEasing.InQuad = inQuad;
LibEasing.OutQuad = outQuad;
LibEasing.InOutQuad = inOutQuad;
LibEasing.OutInQuad = outInQuad;
LibEasing.InCubic  = inCubic;
LibEasing.OutCubic = outCubic;
LibEasing.InOutCubic = inOutCubic;
LibEasing.OutInCubic = outInCubic;
LibEasing.InQuart = inQuart;
LibEasing.OutQuart = outQuart;
LibEasing.InOutQuart = inOutQuart;
LibEasing.OutInQuart = outInQuart;
LibEasing.InQuint = inQuint;
LibEasing.OutQuint = outQuint;
LibEasing.InOutQuint = inOutQuint;
LibEasing.OutInQuint = outInQuint;
LibEasing.InSine = inSine;
LibEasing.OutSine = outSine;
LibEasing.InOutSine = inOutSine;
LibEasing.OutInSine = outInSine;
LibEasing.InExpo = inExpo;
LibEasing.OutExpo = outExpo;
LibEasing.InOutExpo = inOutExpo;
LibEasing.OutInExpo = outInExpo;
LibEasing.InCirc = inCirc;
LibEasing.OutCirc = outCirc;
LibEasing.InOutCirc = inOutCirc;
LibEasing.OutInCirc = outInCirc;
LibEasing.InElastic = inElastic;
LibEasing.OutElastic = outElastic;
LibEasing.InOutElastic = inOutElastic;
LibEasing.OutInElastic = outInElastic;
LibEasing.InBack = inBack;
LibEasing.OutBack = outBack;
LibEasing.InOutBack = inOutBack;
LibEasing.OutInBack = outInBack;
LibEasing.InBounce = inBounce;
LibEasing.OutBounce = outBounce;
LibEasing.InOutBounce = inOutBounce;
LibEasing.OutInBounce = outInBounce;


--------------
-- ONUPDATE --
--------------
local onUpdateFunc = {};
local lastUpdate;
local MAX_UPDATE_TIME = 1.0/120.0;
local function FrameOnUpdate(self, time)
    if (not lastUpdate or (lastUpdate + MAX_UPDATE_TIME) < GetTime()) then
        for k,func in pairs(onUpdateFunc) do
            -- run the function, if it returns nil, remove it
            if (func() == nil) then
                onUpdateFunc[k] = nil;
            end
        end

        lastUpdate = GetTime();
    end

    -- remove onupdate if there isn't anything to check
    if (next(onUpdateFunc) == nil) then
        LibEasing.frame:SetScript("OnUpdate", nil);
    end
end

local function SetupOnUpdate()
    -- if we have checks to do and there isn't an OnUpdate on the frame, set it up
    if (next(onUpdateFunc) ~= nil and LibEasing.frame:GetScript("OnUpdate") == nil) then
        LibEasing.frame:SetScript("OnUpdate", FrameOnUpdate);

        -- force the next update to happen on the NEXT frame
        lastUpdate = GetTime();
    end
end

local function RegisterOnUpdateFunc(func)
    -- add to the list
    onUpdateFunc[func] = func;

    -- make sure that an OnUpdate script is on our frame
    SetupOnUpdate();
end

local function CancelOnUpdateFunc(func)
    if (onUpdateFunc[func]) then
        -- remove from the list
        onUpdateFunc[func] = nil;
    end
end


------------------------
-- EASING CONVIENENCE --
------------------------
local handleCounter = 1;
local currentlyEasing = {};
function LibEasing:Ease(func, beginValue, endValue, duration, easingFunc, callback)
    -- assume inOutQuad if not provided
    if (not easingFunc) then
        easingFunc = inOutQuad;
    end

    -- get a handle
    local handle = handleCounter;
    handleCounter = handleCounter + 1;

    local change = endValue - beginValue;
    local beginTime = GetTime();

    local closure = function()
        local currentTime = GetTime();

        if (beginTime + duration > currentTime) then
            func(easingFunc(currentTime - beginTime, beginValue, change, duration));
            return true;
        else
            func(endValue);
            currentlyEasing[handle] = nil;

            -- call the callback if provided
            if (callback) then callback() end;

            return nil;
        end
    end

    -- register OnUpdate, to call every frame until done
    RegisterOnUpdateFunc(closure);
    currentlyEasing[handle] = closure;
    return handle;
end

function LibEasing:StopEasing(handle)
    -- need to cancel easing this particular handle
    if (handle and currentlyEasing[handle]) then
        CancelOnUpdateFunc(currentlyEasing[handle]);
        currentlyEasing[handle] = nil;
        return true;
    end

    return false;
end
