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
  [0x00] = { mnc = "NOP", op = {} },

  [0x01] = { mnc = "LI",  op = { types.reg, types.imm } },
  [0x02] = { mnc = "MOV", op = { types.reg, types.reg } },
  [0x03] = { mnc = "XCH", op = { types.reg, types.reg } },

  [0x04] = { mnc = "LRI.B", op = { types.reg, types.imm } },
  [0x05] = { mnc = "LRI.I", op = { types.reg, types.imm } },
  [0x06] = { mnc = "LRI.L", op = { types.reg, types.imm } },

  [0x07] = { mnc = "SIR.B", op = { types.imm, types.reg } },
  [0x08] = { mnc = "SIR.I", op = { types.imm, types.reg } },
  [0x09] = { mnc = "SIR.L", op = { types.imm, types.reg } },

  [0x0A] = { mnc = "LRR.B", op = { types.reg, types.reg } },
  [0x0B] = { mnc = "LRR.I", op = { types.reg, types.reg } },
  [0x0C] = { mnc = "LRR.L", op = { types.reg, types.reg } },

  [0x0D] = { mnc = "SRR.B", op = { types.reg, types.reg } },
  [0x0E] = { mnc = "SRR.I", op = { types.reg, types.reg } },
  [0x0F] = { mnc = "SRR.L", op = { types.reg, types.reg } },

  [0x10] = { mnc = "SII.B", op = { types.imm, types.imm_b } },
  [0x11] = { mnc = "SII.I", op = { types.imm, types.imm_i } },
  [0x12] = { mnc = "SII.L", op = { types.imm, types.imm } },

  [0x13] = { mnc = "SRI.B", op = { types.reg, types.imm_b } },
  [0x14] = { mnc = "SRI.I", op = { types.reg, types.imm_i } },
  [0x15] = { mnc = "SRI.L", op = { types.reg, types.imm } },


  [0x16] = { mnc = "PUSH",  op = { types.reg } },
  [0x17] = { mnc = "PUSHI", op = { types.imm } },
  [0x18] = { mnc = "PUSHA", op = {} },
  [0x19] = { mnc = "POP",   op = { types.reg } },
  [0x1A] = { mnc = "POPA",  op = {} },

  [0x1B] = { mnc = "B",   op = { types.imm } },
  [0x1C] = { mnc = "BR",  op = { types.reg } },
  [0x1D] = { mnc = "BE",  op = { types.imm } },
  [0x1E] = { mnc = "BNE", op = { types.imm } },
  [0x1F] = { mnc = "BG",  op = { types.imm } },
  [0x20] = { mnc = "BL",  op = { types.imm } },
  [0x21] = { mnc = "BGE", op = { types.imm } },
  [0x22] = { mnc = "BLE", op = { types.imm } },

  [0x23] = { mnc = "CALL", op = { types.imm } },
  [0x24] = { mnc = "RET",  op = {} },

  [0x25] = { mnc = "CMP",  op = { types.reg, types.reg } },
  [0x26] = { mnc = "CMPI", op = { types.reg, types.imm } },


  [0x27] = { mnc = "ADD",  op = { types.reg, types.reg, types.reg } },
  [0x28] = { mnc = "ADDI", op = { types.reg, types.reg, types.imm } },

  [0x29] = { mnc = "SUB",  op = { types.reg, types.reg, types.reg } },
  [0x2A] = { mnc = "SUBI", op = { types.reg, types.reg, types.imm } },

  [0x2B] = { mnc = "MUL",  op = { types.reg, types.reg, types.reg } },
  [0x2C] = { mnc = "MULI", op = { types.reg, types.reg, types.imm } },

  [0x2D] = { mnc = "MUL",  op = { types.reg, types.reg, types.reg } },
  [0x2E] = { mnc = "MULI", op = { types.reg, types.reg, types.imm } },

  [0x2F] = { mnc = "MOD",  op = { types.reg, types.reg, types.reg } },
  [0x30] = { mnc = "MODI", op = { types.reg, types.reg, types.imm } },


  [0x31] = { mnc = "NOT",   op = { types.reg, types.reg } },

  [0x32] = { mnc = "IOR",   op = { types.reg, types.reg, types.reg } },
  [0x33] = { mnc = "IORI",  op = { types.reg, types.reg, types.imm } },

  [0x34] = { mnc = "NOR",   op = { types.reg, types.reg, types.reg } },
  [0x35] = { mnc = "NORI",  op = { types.reg, types.reg, types.imm } },

  [0x36] = { mnc = "EOR",   op = { types.reg, types.reg, types.reg } },
  [0x37] = { mnc = "EORI",  op = { types.reg, types.reg, types.imm } },

  [0x38] = { mnc = "AND",   op = { types.reg, types.reg, types.reg } },
  [0x39] = { mnc = "ANDI",  op = { types.reg, types.reg, types.imm } },

  [0x3A] = { mnc = "NAND",  op = { types.reg, types.reg, types.reg } },
  [0x3B] = { mnc = "NANDI", op = { types.reg, types.reg, types.imm } },

  [0x3C] = { mnc = "LSH",   op = { types.reg, types.reg, types.reg } },
  [0x3D] = { mnc = "LSHI",  op = { types.reg, types.reg, types.imm_b } },

  [0x3E] = { mnc = "RSH",   op = { types.reg, types.reg, types.reg } },
  [0x3F] = { mnc = "RSHI",  op = { types.reg, types.reg, types.imm_b } },

  [0x40] = { mnc = "BSET",  op = { types.reg, types.reg, types.reg } },
  [0x41] = { mnc = "BSETI", op = { types.reg, types.reg, types.imm_b } },

  [0x42] = { mnc = "BCLR",  op = { types.reg, types.reg, types.reg } },
  [0x43] = { mnc = "BCLRI", op = { types.reg, types.reg, types.imm_b } },


  [0x44] = { mnc = "SYS",   op = { types.imm } },

  [0x45] = { mnc = "CLI",   op = {} },
  [0x46] = { mnc = "BRK",   op = {} },
  [0x47] = { mnc = "HLT",   op = {} },
  [0x48] = { mnc = "IRET",  op = {} },

  [0x49] = { mnc = "BSWAP", op = { types.reg, types.reg } },

  [0x4A] = { mnc = "HTTL",  op = {} },
  [0x4B] = { mnc = "HTTS",  op = {} },

  [0x4C] = { mnc = "CPU",   op = {} },


  [0x4D] = { mnc = "RSP",   op = { types.reg } },
  [0x4E] = { mnc = "SSP",   op = { types.reg } },

  [0x4F] = { mnc = "PUSHV",  op = { types.reg, types.reg } },
  [0x50] = { mnc = "PUSHVI", op = { types.reg, types.imm } },
  [0x51] = { mnc = "POPV",   op = { types.reg, types.reg } },

  [0x52] = { mnc = "CMPS",   op = { types.reg, types.reg } },
  [0x53] = { mnc = "CMPSI",  op = { types.reg, types.imm } }
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
}

return {
  types = types,
  opcodes = {
    limn1k = limn1kOpcodes,
    pec = pecOpcodes
  }
}
