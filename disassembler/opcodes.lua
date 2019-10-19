local function new(size)
  return { size = size }
end

local types = {
  reg = new(1),
  imm = new(4),
  imm_b = new(1),
  imm_i = new(2)
}


local limn1kOpcodes = {
  [0x00] = { mnc = "nop", op = {} },

  [0x01] = { mnc = "li",  op = { types.reg, types.imm } },
  [0x02] = { mnc = "mov", op = { types.reg, types.reg } },
  [0x03] = { mnc = "xch", op = { types.reg, types.reg } },

  [0x04] = { mnc = "lri.b", op = { types.reg, types.imm } },
  [0x05] = { mnc = "lri.i", op = { types.reg, types.imm } },
  [0x06] = { mnc = "lri.l", op = { types.reg, types.imm } },

  [0x07] = { mnc = "sir.b", op = { types.imm, types.reg } },
  [0x08] = { mnc = "sir.i", op = { types.imm, types.reg } },
  [0x09] = { mnc = "sir.l", op = { types.imm, types.reg } },

  [0x0A] = { mnc = "lrr.b", op = { types.reg, types.reg } },
  [0x0B] = { mnc = "lrr.i", op = { types.reg, types.reg } },
  [0x0C] = { mnc = "lrr.l", op = { types.reg, types.reg } },

  [0x0D] = { mnc = "srr.b", op = { types.reg, types.reg } },
  [0x0E] = { mnc = "srr.i", op = { types.reg, types.reg } },
  [0x0F] = { mnc = "srr.l", op = { types.reg, types.reg } },

  [0x10] = { mnc = "sii.b", op = { types.imm, types.imm_b } },
  [0x11] = { mnc = "sii.i", op = { types.imm, types.imm_i } },
  [0x12] = { mnc = "sii.l", op = { types.imm, types.imm } },

  [0x13] = { mnc = "sri.b", op = { types.reg, types.imm_b } },
  [0x14] = { mnc = "sri.i", op = { types.reg, types.imm_i } },
  [0x15] = { mnc = "sri.l", op = { types.reg, types.imm } },


  [0x16] = { mnc = "push",  op = { types.reg } },
  [0x17] = { mnc = "pushi", op = { types.imm } },
  [0x18] = { mnc = "pusha", op = {} },
  [0x19] = { mnc = "pop",   op = { types.reg } },
  [0x1A] = { mnc = "popa",  op = {} },

  [0x1B] = { mnc = "b",   op = { types.imm } },
  [0x1C] = { mnc = "br",  op = { types.reg } },
  [0x1D] = { mnc = "be",  op = { types.imm } },
  [0x1E] = { mnc = "bne", op = { types.imm } },
  [0x1F] = { mnc = "bg",  op = { types.imm } },
  [0x20] = { mnc = "bl",  op = { types.imm } },
  [0x21] = { mnc = "bge", op = { types.imm } },
  [0x22] = { mnc = "ble", op = { types.imm } },

  [0x23] = { mnc = "call", op = { types.imm } },
  [0x24] = { mnc = "ret",  op = {} },

  [0x25] = { mnc = "cmp",  op = { types.reg, types.reg } },
  [0x26] = { mnc = "cmpi", op = { types.reg, types.imm } },


  [0x27] = { mnc = "add",  op = { types.reg, types.reg, types.reg } },
  [0x28] = { mnc = "addi", op = { types.reg, types.reg, types.imm } },

  [0x29] = { mnc = "sub",  op = { types.reg, types.reg, types.reg } },
  [0x2A] = { mnc = "subi", op = { types.reg, types.reg, types.imm } },

  [0x2B] = { mnc = "mul",  op = { types.reg, types.reg, types.reg } },
  [0x2C] = { mnc = "muli", op = { types.reg, types.reg, types.imm } },

  [0x2D] = { mnc = "mul",  op = { types.reg, types.reg, types.reg } },
  [0x2E] = { mnc = "muli", op = { types.reg, types.reg, types.imm } },

  [0x2F] = { mnc = "mod",  op = { types.reg, types.reg, types.reg } },
  [0x30] = { mnc = "modi", op = { types.reg, types.reg, types.imm } },


  [0x31] = { mnc = "not",   op = { types.reg, types.reg } },

  [0x32] = { mnc = "ior",   op = { types.reg, types.reg, types.reg } },
  [0x33] = { mnc = "iori",  op = { types.reg, types.reg, types.imm } },

  [0x34] = { mnc = "nor",   op = { types.reg, types.reg, types.reg } },
  [0x35] = { mnc = "nori",  op = { types.reg, types.reg, types.imm } },

  [0x36] = { mnc = "eor",   op = { types.reg, types.reg, types.reg } },
  [0x37] = { mnc = "eori",  op = { types.reg, types.reg, types.imm } },

  [0x38] = { mnc = "and",   op = { types.reg, types.reg, types.reg } },
  [0x39] = { mnc = "andi",  op = { types.reg, types.reg, types.imm } },

  [0x3A] = { mnc = "nand",  op = { types.reg, types.reg, types.reg } },
  [0x3B] = { mnc = "nandi", op = { types.reg, types.reg, types.imm } },

  [0x3C] = { mnc = "lsh",   op = { types.reg, types.reg, types.reg } },
  [0x3D] = { mnc = "lshi",  op = { types.reg, types.reg, types.imm_b } },

  [0x3E] = { mnc = "rsh",   op = { types.reg, types.reg, types.reg } },
  [0x3F] = { mnc = "rshi",  op = { types.reg, types.reg, types.imm_b } },

  [0x40] = { mnc = "bset",  op = { types.reg, types.reg, types.reg } },
  [0x41] = { mnc = "bseti", op = { types.reg, types.reg, types.imm_b } },

  [0x42] = { mnc = "bclr",  op = { types.reg, types.reg, types.reg } },
  [0x43] = { mnc = "bclri", op = { types.reg, types.reg, types.imm_b } },


  [0x44] = { mnc = "sys",   op = { types.imm } },

  [0x45] = { mnc = "cli",   op = {} },
  [0x46] = { mnc = "brk",   op = {} },
  [0x47] = { mnc = "hlt",   op = {} },
  [0x48] = { mnc = "iret",  op = {} },

  [0x49] = { mnc = "bswap", op = { types.reg, types.reg } },

  [0x4A] = { mnc = "httl",  op = {} },
  [0x4B] = { mnc = "htts",  op = {} },

  [0x4C] = { mnc = "cpu",   op = {} },


  [0x4D] = { mnc = "rsp",   op = { types.reg } },
  [0x4E] = { mnc = "ssp",   op = { types.reg } },

  [0x4F] = { mnc = "pushv",  op = { types.reg, types.reg } },
  [0x50] = { mnc = "pushvi", op = { types.reg, types.imm } },
  [0x51] = { mnc = "popv",   op = { types.reg, types.reg } },

  [0x52] = { mnc = "cmps",   op = { types.reg, types.reg } },
  [0x53] = { mnc = "cmpsi",  op = { types.reg, types.imm } }
}

setmetatable(limn1kOpcodes, {
  __index = function(t, k)
    -- if k == nil then
    --   return { mnc = "???", op = setmetatable({}, {__index = function() return types.imm end}) }
    -- else
      return { mnc = (".db 0x%x"):format(k), op = {} }
    -- end
  end
})

local pecOpcodes = {
  [0x00] = { mnc = "nop",   op = {} },

  [0x01] = { mnc = "push",  op = { types.imm } },
  [0x02] = { mnc = "add",   op = {} },
  [0x03] = { mnc = "sub",   op = {} },
  [0x04] = { mnc = "mul",   op = {} },
  [0x05] = { mnc = "div",   op = {} },
  [0x06] = { mnc = "mod",   op = {} },
  [0x07] = { mnc = "drop",  op = {} },

  [0x08] = { mnc = "eq",    op = {} },
  [0x09] = { mnc = "neq",   op = {} },
  [0x0A] = { mnc = "gt",    op = {} },
  [0x0B] = { mnc = "lt",    op = {} },

  [0x0C] = { mnc = "b",     op = {} },
  [0x0D] = { mnc = "bt",    op = {} },
  [0x0E] = { mnc = "bf",    op = {} },

  [0x0F] = { mnc = "load",  op = {} },
  [0x10] = { mnc = "store", op = {} },

  [0x11] = { mnc = "swap",  op = {} },

  [0x12] = { mnc = "call",  op = {} },
  [0x13] = { mnc = "callt", op = {} },
  [0x14] = { mnc = "callf", op = {} },

  [0x15] = { mnc = "ret",   op = {} },
  [0x16] = { mnc = "rett",  op = {} },
  [0x17] = { mnc = "retf",  op = {} },

  [0x18] = { mnc = "popd",  op = {} },
  [0x19] = { mnc = "pushd", op = {} },

  [0x1A] = { mnc = "ncall", op = { types.imm } },

  [0x1B] = { mnc = "base",  op = {} },

  [0x1C] = { mnc = "slot",  op = {} },

  [0x1D] = { mnc = "xor",   op = {} },
  [0x1E] = { mnc = "or",    op = {} },
  [0x1F] = { mnc = "not",   op = {} },
  [0x20] = { mnc = "ans",   op = {} },
}

return {
  types = types,
  opcodes = {
    limn1k = limn1kOpcodes,
    pec = pecOpcodes
  }
}
