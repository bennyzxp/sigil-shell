-- Usage: lua palette.lua <image-or-video>
-- Prints a gothic palette (JSON) tinted by the wallpaper's colors.

local function shq(s) return "'" .. (s:gsub("'", "'\\''")) .. "'" end
local function sh(cmd)
  local p = io.popen(cmd)
  local out = p:read("a")
  p:close()
  return out
end

local path = (arg[1] or ""):gsub("^~", os.getenv("HOME") or "~")
local f = io.open(path, "r")
if not f then io.stderr:write("sigil palette: file not found: " .. path .. "\n") os.exit(1) end
f:close()

-- Video: grab one frame to analyze
local tmp
local ext = (path:lower():match("%.(%w+)$")) or ""
if ({ mp4 = 1, webm = 1, mkv = 1, mov = 1 })[ext] then
  tmp = os.tmpname() .. ".png"
  os.execute("ffmpeg -v error -y -ss 1 -i " .. shq(path) .. " -frames:v 1 " .. shq(tmp) .. " 2>/dev/null")
  local t = io.open(tmp, "r")
  if not t then
    os.execute("ffmpeg -v error -y -i " .. shq(path) .. " -frames:v 1 " .. shq(tmp) .. " 2>/dev/null")
    t = io.open(tmp, "r")
  end
  if not t then io.stderr:write("sigil palette: could not read a frame from the video (is ffmpeg installed?)\n") os.exit(1) end
  t:close()
  path = tmp
end

-- Get 8 dominant colors with ImageMagick (v7 = magick, v6 = convert)
local im = os.execute("command -v magick >/dev/null 2>&1") and "magick" or "convert"
local out = sh(im .. " " .. shq(path) .. " -alpha off -resize 128x128! -colors 8 -format %c histogram:info:- 2>&1")
if tmp then os.remove(tmp) end

local function rgb2hsl(r, g, b)
  r, g, b = r / 255, g / 255, b / 255
  local mx, mn = math.max(r, g, b), math.min(r, g, b)
  local l = (mx + mn) / 2
  if mx == mn then return 0, 0, l end
  local d = mx - mn
  local s = l > 0.5 and d / (2 - mx - mn) or d / (mx + mn)
  local h
  if mx == r then h = (g - b) / d + (g < b and 6 or 0)
  elseif mx == g then h = (b - r) / d + 2
  else h = (r - g) / d + 4 end
  return h / 6, s, l
end

local function hue2rgb(p, qq, t)
  if t < 0 then t = t + 1 end
  if t > 1 then t = t - 1 end
  if t < 1 / 6 then return p + (qq - p) * 6 * t end
  if t < 1 / 2 then return qq end
  if t < 2 / 3 then return p + (qq - p) * (2 / 3 - t) * 6 end
  return p
end

local function hsl2hex(h, s, l, a)
  local r, g, b
  if s == 0 then
    r, g, b = l, l, l
  else
    local qq = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - qq
    r, g, b = hue2rgb(p, qq, h + 1 / 3), hue2rgb(p, qq, h), hue2rgb(p, qq, h - 1 / 3)
  end
  return string.format("#%s%02x%02x%02x",
    a and string.format("%02x", a) or "",
    math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
end

local function clamp(x, lo, hi) return math.max(lo, math.min(hi, x)) end

-- Parse lines like "  1234: (12,13,20) #0C0D14 srgb(12,13,20)" using the hex code
local colors, total = {}, 0
for line in out:gmatch("[^\n]+") do
  local n, hr, hg, hb = line:match("^%s*(%d+):.-#(%x%x)(%x%x)(%x%x)")
  if n then
    n = tonumber(n)
    local h, s, l = rgb2hsl(tonumber(hr, 16), tonumber(hg, 16), tonumber(hb, 16))
    colors[#colors + 1] = { n = n, h = h, s = s, l = l }
    total = total + n
  end
end
if #colors == 0 then
  io.stderr:write("sigil palette: no colors read. ImageMagick said:\n" .. out:sub(1, 400) .. "\n")
  os.exit(1)
end

local best, bestScore = nil, -1
for _, c in ipairs(colors) do
  if c.l > 0.15 and c.l < 0.9 then
    local score = c.s * math.sqrt(c.n / total) * (1 - math.abs(c.l - 0.55))
    if score > bestScore then best, bestScore = c, score end
  end
end
best = best or colors[1]

local h = best.h
local as = best.s < 0.08 and best.s or clamp(best.s, 0.35, 0.75)

print(string.format(
  '{"surface":"%s","surfaceAlt":"%s","border":"%s","text":"%s","textDim":"%s","accent":"%s"}',
  hsl2hex(h, 0.25, 0.08, 0xe6),
  hsl2hex(h, 0.22, 0.12, 0xe6),
  hsl2hex(h, 0.15, 0.35, 0x55),
  hsl2hex(h, 0.35, 0.90),
  hsl2hex(h, 0.12, 0.68),
  hsl2hex(h, as, clamp(best.l, 0.60, 0.72))
))
