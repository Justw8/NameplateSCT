# LibEasing
A World of Warcraft library addon for providing easing formulas and a convience function to apply them.

These functions were gotten from [EmmanuelOga](https://github.com/EmmanuelOga/easing/), and are an application of Robert Penner's Easing Equations, which are provided under the BSD License and © 2001 Robert Penner.

## Usage
As with any LibStub based libary, get a library access object first

`local LibEasing = LibStub("LibEasing-1.0");`

### LibEasing:Ease(func, beginValue, endValue, duration\[, easingFunc\], \[callback\])
Calls `func(number)` once a frame starting at `beginValue` and going to `endValue` over `duration` using the provided `easingFunc` or `InOutQuad` if not provided, and calling the optional `callback` once done

Returns a handle that can be used to cancel the process

```
local function setShoulderOffset(offset)
    SetCVar("test_cameraOverShoulder", offset)
end

-- sets the shoulder offset to 5 from where ever it was before over a second using InOutQuad as the easing function
-- this will call setShoulderOffset every frame
local easeShoulderOffsetHandle = LibEasing:Ease(setShoulderOffset, tonumber(GetCVar("test_cameraOverShoulder")), 5, 1, LibEasing.InOutQuad);
```

### LibEasing:StopEasing(handle)
Stop the easing on a handle provided by the original `LibEasing:Ease(...)` call

### Provided Easing Formulas
Each provided easing function is provided under the `LibEasing` table, i.e. `LibEasing.MyEasingFunction`. Here are a list of provided functions:

t = elapsed time

b = begin

c = change == ending - beginning

d = duration (total time)

* LibEasing.Linear(t, b, c, d)
* LibEasing.InQuad(t, b, c, d)
* LibEasing.OutQuad(t, b, c, d)
* LibEasing.InOutQuad(t, b, c, d)
* LibEasing.OutInQuad(t, b, c, d)
* LibEasing.InCubic(t, b, c, d)
* LibEasing.OutCubic(t, b, c, d)
* LibEasing.InOutCubic(t, b, c, d)
* LibEasing.OutInCubic(t, b, c, d)
* LibEasing.InQuart(t, b, c, d)
* LibEasing.OutQuart(t, b, c, d)
* LibEasing.InOutQuart(t, b, c, d)
* LibEasing.OutInQuart(t, b, c, d)
* LibEasing.InQuint(t, b, c, d)
* LibEasing.OutQuint(t, b, c, d)
* LibEasing.InOutQuint(t, b, c, d)
* LibEasing.OutInQuint(t, b, c, d)
* LibEasing.InSine(t, b, c, d)
* LibEasing.OutSine(t, b, c, d)
* LibEasing.InOutSine(t, b, c, d)
* LibEasing.OutInSine(t, b, c, d)
* LibEasing.InExpo(t, b, c, d)
* LibEasing.OutExpo(t, b, c, d)
* LibEasing.InOutExpo(t, b, c, d)
* LibEasing.OutInExpo(t, b, c, d)
* LibEasing.InCirc(t, b, c, d)
* LibEasing.OutCirc(t, b, c, d)
* LibEasing.InOutCirc(t, b, c, d)
* LibEasing.OutInCirc(t, b, c, d)
* LibEasing.InElastic(t, b, c, d, a, p)
* LibEasing.OutElastic(t, b, c, d, a, p)
* LibEasing.InOutElastic(t, b, c, d, a, p)
* LibEasing.OutInElastic(t, b, c, d, a, p)
* LibEasing.InBack(t, b, c, d, s)
* LibEasing.OutBack(t, b, c, d, s)
* LibEasing.InOutBack(t, b, c, d, s)
* LibEasing.OutInBack(t, b, c, d, s)
* LibEasing.InBounce(t, b, c, d)
* LibEasing.OutBounce(t, b, c, d)
* LibEasing.InOutBounce(t, b, c, d)
* LibEasing.OutInBounce(t, b, c, d)