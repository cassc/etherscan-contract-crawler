// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import "./SniperEnums.sol";

struct SniperOrder {
    ItemType tokenType;
    uint72 value;
    uint72 autosniperTip;
    uint72 validatorTip;
    address to;
    address marketplace;
    address tokenAddress;
    uint256 tokenId;
    bytes data;
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
    bool isPaused;
    uint72 maxTip;
    mapping(address => bool) allowedMarketplaces;
    mapping(address => bool) allowedNftContracts;
}