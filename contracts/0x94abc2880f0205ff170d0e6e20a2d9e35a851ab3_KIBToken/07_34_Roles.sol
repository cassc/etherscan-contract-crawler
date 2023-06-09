// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

library Roles {
    bytes32 public constant KUMA_MANAGER_ROLE = keccak256("KUMA_MANAGER_ROLE");
    bytes32 public constant KUMA_MINT_ROLE = keccak256("KUMA_MINT_ROLE");
    bytes32 public constant KUMA_BURN_ROLE = keccak256("KUMA_BURN_ROLE");
    bytes32 public constant KUMA_SET_EPOCH_LENGTH_ROLE = keccak256("KUMA_SET_EPOCH_LENGTH_ROLE");
    bytes32 public constant KUMA_SWAP_CLAIM_ROLE = keccak256("KUMA_SWAP_CLAIM_ROLE");
    bytes32 public constant KUMA_SWAP_PAUSE_ROLE = keccak256("KUMA_SWAP_PAUSE_ROLE");
    bytes32 public constant KUMA_SWAP_UNPAUSE_ROLE = keccak256("KUMA_SWAP_UNPAUSE_ROLE");
    bytes32 public constant KUMA_SET_URI_ROLE = keccak256("KUMA_SET_URI_ROLE");

    function toGranularRole(bytes32 role, bytes32 riskCategory) internal pure returns (bytes32) {
        return keccak256(abi.encode(role, riskCategory));
    }
}