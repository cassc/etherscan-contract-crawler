// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

/**
 * @dev Reflects types from "./Swap.sol"
 */

// prettier-ignore
string constant _TOKEN_CHECK_TYPE =
    "TokenCheck("
        "address token,"
        "uint256 minAmount,"
        "uint256 maxAmount"
    ")";

// prettier-ignore
string constant _TOKEN_USE_TYPE =
    "TokenUse("
        "address protocol,"
        "uint256 chain,"
        "address account,"
        "uint256[] inIndices,"
        "TokenCheck[] outs,"
        "bytes args"
    ")";

// prettier-ignore
string constant _SWAP_STEP_TYPE =
    "SwapStep("
        "uint256 chain,"
        "address swapper,"
        "address account,"
        "bool useDelegate,"
        "uint256 nonce,"
        "uint256 deadline,"
        "TokenCheck[] ins,"
        "TokenCheck[] outs,"
        "TokenUse[] uses"
    ")";

// prettier-ignore
string constant _SWAP_TYPE =
    "Swap("
        "SwapStep[] steps"
    ")";

// prettier-ignore
string constant _STEALTH_SWAP_TYPE =
    "StealthSwap("
        "uint256 chain,"
        "address swapper,"
        "address account,"
        "bytes32[] stepHashes"
    ")";

/**
 * @dev Hashes of the types above
 *
 * Remember that:
 * - Main hashed type goes first
 * - Subtypes go next in alphabetical order (specified in EIP-712)
 */

// prettier-ignore
bytes32 constant _TOKEN_CHECK_TYPE_HASH = keccak256(abi.encodePacked(
    _TOKEN_CHECK_TYPE
));

// prettier-ignore
bytes32 constant _TOKEN_USE_TYPE_HASH = keccak256(abi.encodePacked(
    _TOKEN_USE_TYPE,
    _TOKEN_CHECK_TYPE
));

// prettier-ignore
bytes32 constant _SWAP_STEP_TYPE_HASH = keccak256(abi.encodePacked(
    _SWAP_STEP_TYPE,
    _TOKEN_CHECK_TYPE,
    _TOKEN_USE_TYPE
));

// prettier-ignore
bytes32 constant _SWAP_TYPE_HASH = keccak256(abi.encodePacked(
    _SWAP_TYPE,
    _SWAP_STEP_TYPE,
    _TOKEN_CHECK_TYPE,
    _TOKEN_USE_TYPE
));

// prettier-ignore
bytes32 constant _STEALTH_SWAP_TYPE_HASH = keccak256(abi.encodePacked(
    _STEALTH_SWAP_TYPE
));

/**
 * @dev Hash values pre-calculated w/ `tools/hash` to reduce contract size
 */

// bytes32 constant TOKEN_CHECK_TYPE_HASH = _TOKEN_CHECK_TYPE_HASH;
bytes32 constant TOKEN_CHECK_TYPE_HASH = 0x382391664c9ae06333b02668b6d763ab547bd70c71636e236fdafaacf1e55bdd;

// bytes32 constant TOKEN_USE_TYPE_HASH = _TOKEN_USE_TYPE_HASH;
bytes32 constant TOKEN_USE_TYPE_HASH = 0x192f17c5e66907915b200bca0d866184770ff7faf25a0b4ccd2ef26ebd21725a;

// bytes32 constant SWAP_STEP_TYPE_HASH = _SWAP_STEP_TYPE_HASH;
bytes32 constant SWAP_STEP_TYPE_HASH = 0x973db6284d4ead3ce5e0ee0d446a483b1b5ff8cd93a2b86dbd0a9f03a6cefc8a;

// bytes32 constant SWAP_TYPE_HASH = _SWAP_TYPE_HASH;
bytes32 constant SWAP_TYPE_HASH = 0xba1e9d0b1bee57631ad5f99eac149c1229822508d3dfc4f8fa2c5089bb99c874;

// bytes32 constant STEALTH_SWAP_TYPE_HASH = _STEALTH_SWAP_TYPE_HASH;
bytes32 constant STEALTH_SWAP_TYPE_HASH = 0x0f2b1c8dae54aa1b96d626d678ec60a7c6d113b80ccaf635737a6f003d1cbaf5;