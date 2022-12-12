// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../base/BaseClaimNFTStorage.sol";

abstract contract DiscountClaimNFTStorage is BaseClaimNFTStorage {
    bytes32 internal _discountMerkleRoot;

    mapping(address => bool) internal _discountClaimedTokens;
}