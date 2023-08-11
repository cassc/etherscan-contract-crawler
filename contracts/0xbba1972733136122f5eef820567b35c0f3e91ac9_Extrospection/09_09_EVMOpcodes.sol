// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

uint8 constant EVM_OP_STOP = 0x00;

uint8 constant EVM_OP_ADD = 0x01;
uint8 constant EVM_OP_MUL = 0x02;
uint8 constant EVM_OP_SUB = 0x03;
uint8 constant EVM_OP_DIV = 0x04;
uint8 constant EVM_OP_SDIV = 0x05;
uint8 constant EVM_OP_MOD = 0x06;
uint8 constant EVM_OP_SMOD = 0x07;
uint8 constant EVM_OP_ADDMOD = 0x08;
uint8 constant EVM_OP_MULMOD = 0x09;
uint8 constant EVM_OP_EXP = 0x0A;
uint8 constant EVM_OP_SIGNEXTEND = 0x0B;

uint8 constant EVM_OP_LT = 0x10;
uint8 constant EVM_OP_GT = 0x11;
uint8 constant EVM_OP_SLT = 0x12;
uint8 constant EVM_OP_SGT = 0x13;
uint8 constant EVM_OP_EQ = 0x14;
uint8 constant EVM_OP_ISZERO = 0x15;

uint8 constant EVM_OP_AND = 0x16;
uint8 constant EVM_OP_OR = 0x17;
uint8 constant EVM_OP_XOR = 0x18;
uint8 constant EVM_OP_NOT = 0x19;
uint8 constant EVM_OP_BYTE = 0x1A;
uint8 constant EVM_OP_SHL = 0x1B;
uint8 constant EVM_OP_SHR = 0x1C;
uint8 constant EVM_OP_SAR = 0x1D;

uint8 constant EVM_OP_SHA3 = 0x20;

uint8 constant EVM_OP_ADDRESS = 0x30;
uint8 constant EVM_OP_BALANCE = 0x31;

uint8 constant EVM_OP_ORIGIN = 0x32;
uint8 constant EVM_OP_CALLER = 0x33;
uint8 constant EVM_OP_CALLVALUE = 0x34;
uint8 constant EVM_OP_CALLDATALOAD = 0x35;
uint8 constant EVM_OP_CALLDATASIZE = 0x36;
uint8 constant EVM_OP_CALLDATACOPY = 0x37;

uint8 constant EVM_OP_CODESIZE = 0x38;
uint8 constant EVM_OP_CODECOPY = 0x39;

uint8 constant EVM_OP_GASPRICE = 0x3A;

uint8 constant EVM_OP_EXTCODESIZE = 0x3B;
uint8 constant EVM_OP_EXTCODECOPY = 0x3C;

uint8 constant EVM_OP_RETURNDATASIZE = 0x3D;
uint8 constant EVM_OP_RETURNDATACOPY = 0x3E;

uint8 constant EVM_OP_EXTCODEHASH = 0x3F;
uint8 constant EVM_OP_BLOCKHASH = 0x40;

uint8 constant EVM_OP_COINBASE = 0x41;
uint8 constant EVM_OP_TIMESTAMP = 0x42;
uint8 constant EVM_OP_NUMBER = 0x43;
uint8 constant EVM_OP_DIFFICULTY = 0x44;
uint8 constant EVM_OP_GASLIMIT = 0x45;
uint8 constant EVM_OP_CHAINID = 0x46;

uint8 constant EVM_OP_SELFBALANCE = 0x47;

uint8 constant EVM_OP_BASEFEE = 0x48;

uint8 constant EVM_OP_POP = 0x50;
uint8 constant EVM_OP_MLOAD = 0x51;
uint8 constant EVM_OP_MSTORE = 0x52;
uint8 constant EVM_OP_MSTORE8 = 0x53;

uint8 constant EVM_OP_SLOAD = 0x54;
uint8 constant EVM_OP_SSTORE = 0x55;

uint8 constant EVM_OP_JUMP = 0x56;
uint8 constant EVM_OP_JUMPI = 0x57;
uint8 constant EVM_OP_PC = 0x58;
uint8 constant EVM_OP_MSIZE = 0x59;
uint8 constant EVM_OP_GAS = 0x5A;
uint8 constant EVM_OP_JUMPDEST = 0x5B;

uint8 constant EVM_OP_PUSH0 = 0x5F;
uint8 constant EVM_OP_PUSH1 = 0x60;
uint8 constant EVM_OP_PUSH2 = 0x61;
uint8 constant EVM_OP_PUSH3 = 0x62;
uint8 constant EVM_OP_PUSH4 = 0x63;
uint8 constant EVM_OP_PUSH5 = 0x64;
uint8 constant EVM_OP_PUSH6 = 0x65;
uint8 constant EVM_OP_PUSH7 = 0x66;
uint8 constant EVM_OP_PUSH8 = 0x67;
uint8 constant EVM_OP_PUSH9 = 0x68;
uint8 constant EVM_OP_PUSH10 = 0x69;
uint8 constant EVM_OP_PUSH11 = 0x6A;
uint8 constant EVM_OP_PUSH12 = 0x6B;
uint8 constant EVM_OP_PUSH13 = 0x6C;
uint8 constant EVM_OP_PUSH14 = 0x6D;
uint8 constant EVM_OP_PUSH15 = 0x6E;
uint8 constant EVM_OP_PUSH16 = 0x6F;
uint8 constant EVM_OP_PUSH17 = 0x70;
uint8 constant EVM_OP_PUSH18 = 0x71;
uint8 constant EVM_OP_PUSH19 = 0x72;
uint8 constant EVM_OP_PUSH20 = 0x73;
uint8 constant EVM_OP_PUSH21 = 0x74;
uint8 constant EVM_OP_PUSH22 = 0x75;
uint8 constant EVM_OP_PUSH23 = 0x76;
uint8 constant EVM_OP_PUSH24 = 0x77;
uint8 constant EVM_OP_PUSH25 = 0x78;
uint8 constant EVM_OP_PUSH26 = 0x79;
uint8 constant EVM_OP_PUSH27 = 0x7A;
uint8 constant EVM_OP_PUSH28 = 0x7B;
uint8 constant EVM_OP_PUSH29 = 0x7C;
uint8 constant EVM_OP_PUSH30 = 0x7D;
uint8 constant EVM_OP_PUSH31 = 0x7E;
uint8 constant EVM_OP_PUSH32 = 0x7F;

uint8 constant EVM_OP_DUP1 = 0x80;
uint8 constant EVM_OP_DUP2 = 0x81;
uint8 constant EVM_OP_DUP3 = 0x82;
uint8 constant EVM_OP_DUP4 = 0x83;
uint8 constant EVM_OP_DUP5 = 0x84;
uint8 constant EVM_OP_DUP6 = 0x85;
uint8 constant EVM_OP_DUP7 = 0x86;
uint8 constant EVM_OP_DUP8 = 0x87;
uint8 constant EVM_OP_DUP9 = 0x88;
uint8 constant EVM_OP_DUP10 = 0x89;
uint8 constant EVM_OP_DUP11 = 0x8A;
uint8 constant EVM_OP_DUP12 = 0x8B;
uint8 constant EVM_OP_DUP13 = 0x8C;
uint8 constant EVM_OP_DUP14 = 0x8D;
uint8 constant EVM_OP_DUP15 = 0x8E;
uint8 constant EVM_OP_DUP16 = 0x8F;

uint8 constant EVM_OP_SWAP1 = 0x90;
uint8 constant EVM_OP_SWAP2 = 0x91;
uint8 constant EVM_OP_SWAP3 = 0x92;
uint8 constant EVM_OP_SWAP4 = 0x93;
uint8 constant EVM_OP_SWAP5 = 0x94;
uint8 constant EVM_OP_SWAP6 = 0x95;
uint8 constant EVM_OP_SWAP7 = 0x96;
uint8 constant EVM_OP_SWAP8 = 0x97;
uint8 constant EVM_OP_SWAP9 = 0x98;
uint8 constant EVM_OP_SWAP10 = 0x99;
uint8 constant EVM_OP_SWAP11 = 0x9A;
uint8 constant EVM_OP_SWAP12 = 0x9B;
uint8 constant EVM_OP_SWAP13 = 0x9C;
uint8 constant EVM_OP_SWAP14 = 0x9D;
uint8 constant EVM_OP_SWAP15 = 0x9E;
uint8 constant EVM_OP_SWAP16 = 0x9F;

uint8 constant EVM_OP_LOG0 = 0xA0;
uint8 constant EVM_OP_LOG1 = 0xA1;
uint8 constant EVM_OP_LOG2 = 0xA2;
uint8 constant EVM_OP_LOG3 = 0xA3;
uint8 constant EVM_OP_LOG4 = 0xA4;

uint8 constant EVM_OP_CREATE = 0xF0;
uint8 constant EVM_OP_CALL = 0xF1;
uint8 constant EVM_OP_CALLCODE = 0xF2;
uint8 constant EVM_OP_RETURN = 0xF3;
uint8 constant EVM_OP_DELEGATECALL = 0xF4;
uint8 constant EVM_OP_CREATE2 = 0xF5;
uint8 constant EVM_OP_STATICCALL = 0xFA;
uint8 constant EVM_OP_REVERT = 0xFD;
uint8 constant EVM_OP_INVALID = 0xFE;
uint8 constant EVM_OP_SELFDESTRUCT = 0xFF;

uint256 constant HALTING_BITMAP = (1 << EVM_OP_STOP) | (1 << EVM_OP_RETURN) | (1 << EVM_OP_REVERT)
    | (1 << EVM_OP_INVALID) | (1 << EVM_OP_SELFDESTRUCT);