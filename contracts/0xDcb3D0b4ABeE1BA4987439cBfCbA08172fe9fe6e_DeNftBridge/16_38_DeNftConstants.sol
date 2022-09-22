// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library DeNftConstants {
    /* ========== CONSTANTS ========== */

    // Third party ERC721-compatible NFT collection
    uint8 public constant DENFT_TYPE_THIRDPARTY = 1;
    // Cross-chain compatible collection deployed thru DeNftBridge
    uint8 public constant DENFT_TYPE_BASIC = 2;
    // Cross-chain compatible collection deployed thru DeNftBridge
    // uint8 public constant DENFT_TYPE_VOTES = 3;
}