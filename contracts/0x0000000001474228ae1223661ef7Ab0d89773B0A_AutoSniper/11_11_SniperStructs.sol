// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import "./SniperEnums.sol";

struct SniperOrder {
    address to;
    address marketplace;
    uint256 value;
    uint256 autosniperTip;
    uint256 validatorTip;
    ItemType tokenType;
    bytes data;
    address tokenAddress;
    uint256 tokenId;
}

struct Claim {
    ItemType tokenType;
    address tokenAddress;
    uint256 tokenId;
    bytes claimData;
}

struct SniperGuardrails {
    bool marketplaceGuardEnabled;
    bool nftContractGuardEnabled;
    mapping(address => bool) allowedMarketplaces;
    mapping(address => bool) allowedNftContracts;
    uint256 maxTip;
}