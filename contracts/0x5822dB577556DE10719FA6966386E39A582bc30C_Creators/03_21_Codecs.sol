// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

uint256 constant ONE_BYTE = 0x8;
uint256 constant ONE_BYTE_MASK = type(uint8).max;

uint256 constant TWO_BYTES = 0x10;

uint256 constant FOUR_BYTES = 0x20;
uint256 constant FOUR_BYTE_MASK = type(uint32).max;

uint256 constant THIRTY_BYTES = 0xf0;
uint256 constant THIRTY_BYTE_MASK = type(uint240).max;