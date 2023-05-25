// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev ERC1271's magic value (bytes4(keccak256("isValidSignature(bytes32,bytes)"))
 */
bytes4 constant ERC1271_MAGIC_VALUE = 0x1626ba7e;