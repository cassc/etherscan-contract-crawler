// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct DropData {
    bytes32 merkleroot;
    bool mintbossAllowed; 
    uint256 mintbossMintPrice;
    uint256 mintbossAllowListMintPrice;
    uint256 mintbossReferralFee; // The amount sent to the referrer on each mint
    uint256 mintPhase; // 0 = closed, 1 = WL sale, 2 = public sale
    uint256 publicMintPrice; // Public mint price
    uint256 maxPublicMintCount; // The maximum number of tokens any one address can mint
    uint256 maxWLMintCount; 
    uint256 allowlistMintPrice;
    //uint256 maxTotalSupply;
}