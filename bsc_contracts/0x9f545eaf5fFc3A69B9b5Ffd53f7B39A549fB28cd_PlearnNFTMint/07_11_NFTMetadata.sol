// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../interfaces/IPlearnNFT.sol";

struct NFTMetadata {
    IPlearnNFT collection;
    uint256 reservedRangeId;
    uint256 baseTokenId;
}