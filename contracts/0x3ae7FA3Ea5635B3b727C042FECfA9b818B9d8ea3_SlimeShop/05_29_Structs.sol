// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

struct RoyaltyInfo {
    address receiver;
    uint96 royaltyFraction;
}

struct ConstructorArgs {
    string name;
    string symbol;
    address vrfCoordinatorAddress;
    uint240 maxNumSets;
    uint8 numTokensPerSet;
    uint64 subscriptionId;
    address metadataContractAddress;
    uint256 firstComposedCutoff;
    uint8 exclusiveLayerId;
    uint64 startTime;
    bytes32 merkleRoot;
    address feeRecipient;
    uint16 feeBps;
    RoyaltyInfo royaltyInfo;
    uint64 publicMintPrice;
    uint64 maxSetsPerWallet;
    bytes32 keyHash;
}