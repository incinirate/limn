local helpString = [[
Usage: lua disas.lua ([MODE] <FILE>)...
Disassembles or otherwise dumps information from LIMN arch binaries/object files.
Supports both 'limn1k' and 'PEC' object types. Flat (Binary) files are *technically*
supported but accuracy of disassembly is not guaranteed.

  -d            Set to Disassemble mode
  -s            Set to Dump Symbol Table mode
  -r            Set to Dump Relocation Table mode
  -f            Set to Dump Fixup Table mode

  -h, --help    Print this help string
]]

local function printUsage()
  print(helpString)
  os.exit()
end

local getopt = require("getopt")
local args = { ... }

if #args == 0 then
  printUsage()
end

local opLib = require("opcodes")
local types = opLib.types
local magic = "0XEL"

local opcodes

if not string.gfind then
  function string:gfind(pattern)
    local rest, lpos = self, 0
    return function()
      local p1, p2 = rest:find(pattern)
      if not p1 then
        return nil
      end

      local value = rest:sub(p1, p2)
      local xpos = lpos

      rest = rest:sub(p2 + 2)
      lpos = lpos + p2 + 1

      return value, p1 + xpos, p2 + xpos
    end
  end
end

function strReadByte(str)
  return string.byte(str)
end

function strReadInt(str)
  local p1 = string.byte(str:sub(1, 1))
  local p2 = string.byte(str:sub(2, 2))

  return p2 * 256 + p1
end

function strReadLong(str)
  local p1 = string.byte(str:sub(1, 1))
  local p2 = string.byte(str:sub(2, 2))
  local p3 = string.byte(str:sub(3, 3))
  local p4 = string.byte(str:sub(4, 4))

  return p4 * (256 * 256 * 256) +
         p3 * (256 * 256) +
         p2 * (256) +
         p1
end

function strReadSize(str, size)
  if     size == 4 then return strReadLong(str)
  elseif size == 2 then return strReadInt(str)
  elseif size == 1 then return strReadByte(str)
  else error("Unsupported size " .. size, 2) end
end


local Stream = {}
function Stream.new(data, title)
  local self = { data = data, len = #data, pos = 0, title = title or "???" }
  return setmetatable(self, { __index = Stream })
end

function Stream:eat()
  local char = self.data:sub(1, 1)
  self.data = self.data:sub(2)
  self.len = self.len - 1
  self.pos = self.pos + 1
  self.eaten = (self.eaten or "") .. char
  if (self.len < 0) then
    -- error("Stream was over-eaten, corrupted data most likely")
    return 0
  end

  return char
end

function Stream:readByte()
  return string.byte(self:eat()), self.pos
end

function Stream:readInt()
  local str = self:eat() .. self:eat()
  return strReadInt(str), self.pos
end

function Stream:readLong()
  local str = self:eat() .. self:eat() .. self:eat() .. self:eat()
  return strReadLong(str), self.pos
end

function Stream:readSize(size)
  if     size == 4 then return self:readLong()
  elseif size == 2 then return self:readInt()
  elseif size == 1 then return self:readByte()
  else error("Unsupported size " .. size, 2) end
end

function Stream:empty()
  return self.len <= 0
end

function Stream:skip(n)
  for i = 1, n or 1 do
    self:eat()
  end

  return self.pos
end

function Stream:mark()
  self.eaten = ""

  return self.pos
end

function Stream:check()
  return self.eaten, self.pos
end


local function disassemble(stream, symbols, fixups, relocations)
  local result = {}
  local processedRelocations = {}
  local mode = "code"

  -- Make sure that the symbols are in ascending order
  -- (They should be anyways, but doesn't hurt to make sure)
  table.sort(symbols, function(a, b)
    return a.pos < b.pos
  end)

  while not stream:empty() do
    local position = stream.pos
    stream:mark()

    -- First check if this spot is marked by a symbol
    if symbols.cp[stream.pos] then
      result[#result + 1] = {
        type = "sym",
        sym = symbols.cp[stream.pos],
        pos = position
      }

      mode = "code"
    end

    -- Or maybe it's just unmarked data? (detected by unlabeled relocation)
    if processedRelocations[stream.pos] then
      if mode == "code" and not symbols.cp[stream.pos] then
        result[#result + 1] = {
          type = "data",
          pos = position
        }

        mode = "data"
      end
    end

    if mode == "code" then
      local opcode = stream:readByte()
      local instr = opcodes[opcode]

      local args = {}
      for i = 1, #instr.op do
        local op = instr.op[i]
        if relocations[stream.pos] then
          -- Relocation should be related to a symbol
          local val = stream:readSize(op.size)
          local sym = symbols.cp[val] or "unlabeled relocation"
          processedRelocations[val] = true

          args[#args + 1] = { type = "ref", val = ("0x%x <%s>"):format(val, sym) }
        elseif fixups[stream.pos] then
          local val = fixups[stream.pos]

          args[#args + 1] = { type = "ref", val = val }
          stream:skip(op.size)
        else
          args[#args + 1] = { type = op, val = stream:readSize(op.size) }
        end
      end

      result[#result + 1] = {
        type = "instr",
        proto = instr,
        args = args,
        pos = position,
        data = stream:check()
      }
    elseif mode == "data" then
      if stream.data:match("^[\32-\126]+\0") then
        -- Probably a string
        local str = stream.data:match("^([\32-\126]+)\0")
        stream:skip(#str + 1)

        result[#result + 1] = {
          type = "str",
          val = str,
          pos = position,
          data = stream:check()
        }
      else
        result[#result + 1] = {
          type = "byte",
          val = stream:readByte(),
          pos = position,
          data = stream:check()
        }
      end
    end
  end

  local externs = {}
  for _, v in pairs(fixups) do
    if not externs[v] then
      externs[v] = true
      externs[#externs + 1] = v
    end
  end

  return {
    title = stream.title,
    externs = externs,
    result = result
  }
end

local function printHeader(header)
  print()
  print(header)
  print()
end

local function prettyPrint(program)
  printHeader(("Disassembly of %s:"):format(program.title))

  do -- List all the external symbols
    table.sort(program.externs)
    for i = 1, #program.externs do
      print((".extern %s"):format(program.externs[i]))
    end

    print()
  end

  local program = program.result
  for i = 1, #program do
    local piece = program[i]

    local function getBytes(split)
      local bytes, ln = {}, 1
      for i = 1, #piece.data do
        bytes[ln] = bytes[ln] or {}
        bytes[ln][(i - 1) % split + 1] = ("%02x"):format(piece.data:byte(i))

        if i % split == 0 then
          ln = ln + 1
        end
      end

      for i = 1, #bytes do
        bytes[i] = table.concat(bytes[i], " ")
      end

      return bytes
    end

    local function printWithContext(data)
      local builder = {}

      local bytes = getBytes(8)
      for i = 1, #bytes do
        if i == 1 then
          builder[i] = ("%4x: %-26s %s"):format(piece.pos, bytes[i], data)
        else
          builder[i] = ("%4x: %-26s"):format(piece.pos + (i - 1) * 8, bytes[i])
        end
      end

      print(table.concat(builder, "\n"))
    end

    if piece.type == "sym" then
      print(("\n0x%08x <%s>:"):format(piece.pos, piece.sym))
    elseif piece.type == "data" then
      print(("\n0x%08x [DATA]:"):format(piece.pos))
    elseif piece.type == "instr" then
      local mneumonic = piece.proto.mnc

      local args = {}
      for j = 1, #piece.args do
        local value = "???"

        local arg = piece.args[j]
        if arg.type == types.reg then
          value = ("r%d"):format(arg.val)
        elseif arg.type == "ref" then
          value = arg.val
        else
          value = ("0x%x"):format(arg.val)
        end

        args[#args + 1] = value
      end

      printWithContext(("%-8s %s"):format(mneumonic, table.concat(args, ", ")))
    elseif piece.type == "str" then
      printWithContext((".ds %s"):format(piece.val))
    elseif piece.type == "byte" then
      printWithContext((".db %02x"):format(piece.val))
    end
  end
end


local function processFile(filename, data)
  local hstream = Stream.new(data, filename)

  if data:sub(1, 4) == magic then
    hstream:readSize(4) -- Discard the magic

    -- Extract the header
    local symTabOff = hstream:readLong()
    local symCount = hstream:readLong()

    local strTabOff = hstream:readLong()
    local strTabSize = hstream:readLong()

    local relocTabOff = hstream:readLong()
    local relocCount = hstream:readLong()

    local fixupTabOff = hstream:readLong()
    local fixupCount = hstream:readLong()

    local codeOff = hstream:readLong()
    local codeSize = hstream:readLong()

    local fileType = hstream:readByte()
    if fileType == 1 then
      opcodes = opLib.opcodes.limn1k
    elseif fileType == 2 then
      opcodes = opLib.opcodes.pec
    else
      -- Default to link1 opcodes
      opcodes = opLib.opcodes.limn1k
    end


    local strings = {}
    do
      local strTab = data:sub(strTabOff + 1, strTabOff + strTabSize)
      for str, p1, p2 in strTab:gfind("[^\0]+") do
        strings[p1] = str
      end
    end

    local symbols = {cp = {}}
    for i = 1, symCount do
      local strPos = symTabOff + (8 * (i - 1))
      local symEntry = data:sub(strPos + 1, strPos + 8)

      local nameOff = strReadLong(symEntry:sub(1, 4))
      local symCodePos = strReadLong(symEntry:sub(5, 8))

      local name = strings[nameOff + 1] -- data:sub(strTabOff + nameOff + 1):match("[^\0]+")
      symbols[i] = { name = name, pos = symCodePos }
      symbols.cp[symCodePos] = name
    end

    local fixups = {}
    for i = 1, fixupCount do
      local strPos = fixupTabOff + (8 * (i - 1))
      local fixupEntry = data:sub(strPos + 1, strPos + 8)

      local nameOff = strReadLong(fixupEntry:sub(1, 4))
      local fixupCodePos = strReadLong(fixupEntry:sub(5, 8))

      local name = strings[nameOff + 1] -- data:sub(strTabOff + nameOff + 1):match("[^\0]+")
      fixups[fixupCodePos] = name
    end

    local relocations = {}
    for i = 1, relocCount do
      local strPos = relocTabOff + (4 * (i - 1))
      local relocEntry = data:sub(strPos + 1, strPos + 4)

      local relocCodePos = strReadLong(relocEntry)
      relocations[relocCodePos] = true
    end

    local codeStream = Stream.new(data:sub(codeOff + 1, codeOff + codeSize), filename)

    return codeStream, symbols, fixups, relocations
  else
    -- Flat Binary
    print("!!WARNING!! Given Binary is *flat*, disassembly may include strings or other data that appear as instructions")

    local symbols = {
      { name = "Main", pos = 0 },
      cp = { [0] = "Main" }
    }

    return hstream, symbols, {}, {}
  end
end

local function printSymbols(title, symbols)
  printHeader(("Symbol Table of %s:"):format(title))

  local maxNameSize = 6
  for i = 1, #symbols do
    local size = #symbols[i].name
    if size > maxNameSize then
      maxNameSize = size
    end
  end

  maxNameSize = maxNameSize + 1

  print(("%" .. maxNameSize .. "s  %s"):format("NAME", "POSITION"))
  for i = 1, #symbols do
    local sym = symbols[i]
    print(("%" .. maxNameSize .. "s  0x%08x"):format(sym.name, sym.pos))
  end
end

local function printRelocations(title, relocations)
  printHeader(("Relocation Table of %s:"):format(title))

  print("POSITION")
  for k, v in pairs(relocations) do
    print(("0x%08x"):format(k))
  end
end

local function printFixups(title, fixups)
  printHeader(("Fixup Table of %s:"):format(title))

  local maxNameSize = 6
  for p, name in pairs(fixups) do
    local size = #name
    if size > maxNameSize then
      maxNameSize = size
    end
  end

  maxNameSize = maxNameSize + 1


  print(("%" .. maxNameSize .. "s  %s"):format("NAME", "POSITION"))
  for pos, name in pairs(fixups) do
    print(("%" .. maxNameSize .. "s  0x%08x"):format(name, pos))
  end
end

local mode = "d"

getopt(args, "-dsrfh", {
  help = { hasArg = getopt.noArgument, val = "h" }
}) {
  [1] = function(val) -- non-option
    -- Treat it as an input file
    local handle = io.open(val, "rb")
    local data = handle:read("*a")
    handle:close()

    local codeStream, symbols, fixups, relocations = processFile(val, data)

    if mode == "d" then
      local program = disassemble(codeStream, symbols, fixups, relocations)
      prettyPrint(program)
    elseif mode == "s" then
      printSymbols(codeStream.title, symbols)
    elseif mode == "r" then
      printRelocations(codeStream.title, relocations)
    elseif mode == "f" then
      printFixups(codeStream.title, fixups)
    end
  end,
  d = function() mode = "d" end,
  s = function() mode = "s" end,
  r = function() mode = "r" end,
  f = function() mode = "f" end,
  h = printUsage
}
