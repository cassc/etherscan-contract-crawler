// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "./SniperEnums.sol";

struct SniperOrder {
    address to;
    address marketplace;
    uint256 value;
    uint256 tip;
    ItemType tokenType;
    bytes data;
    address tokenAddress;
    uint256 tokenId;
}

struct SniperGuardrails {
    bool marketplaceGuardEnabled;
    bool nftContractGuardEnabled;
    mapping(address => bool) allowedMarketplaces;
    mapping(address => bool) allowedNftContracts;
    uint256 maxTip;
}