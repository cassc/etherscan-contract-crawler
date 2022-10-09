// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
abstract contract RoleConstant {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BLACKLIST_ROLE = keccak256("BLACKLIST_ROLE");
    bytes32 public constant VIP_ROLE = keccak256("VIP_ROLE");
    bytes32 public constant AIRDROP_ROLE = keccak256("AIRDROP_ROLE");
    bytes32 public constant MOD_ROLE = keccak256("MOD_ROLE");
    bytes32 public constant HOLDER_ROLE = keccak256("HOLDER_ROLE");
}