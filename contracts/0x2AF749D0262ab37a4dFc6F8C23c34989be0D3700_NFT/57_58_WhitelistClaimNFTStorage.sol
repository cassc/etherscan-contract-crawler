// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../base/BaseClaimNFTStorage.sol";

abstract contract WhitelistClaimNFTStorage is BaseClaimNFTStorage {
    bytes32 internal _whitelistMerkleRoot;
}