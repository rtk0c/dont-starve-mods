#!/usr/bin/lua

-- https://forums.kleientertainment.com/forums/topic/28369-reading-save-files/

local i_fname, o_fname = ...

local zlib = require "zlib"
local inflate = zlib.inflate()
local basexx = require "basexx"

local ifh = i_fname and i_fname ~= "-" and io.open(i_fname, "rb") or io.stdin
local ofh = o_fname and o_fname ~= "-" and io.open(o_fname, "wb") or io.stdout

-- Compressed
local c = ifh:read("*a")
-- Decompressed
local d
if c:sub(11, 11) == "D" then
	-- 11 bytes of Klei persistent string header
	local decoded = basexx.from_base64(c:sub(12))
	-- 16 bytes of some kind of compressed stream header
	local inflated, eof, bytes_in, bytes_out = inflate(decoded:sub(17))
	d = inflated
else
	d = c:sub(12)
end

ofh:write(d)
