// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

enum PhaseType {
    Whitelist,
    Public
}

struct Phase {
    PhaseType phaseType;
    uint256 maxPerWallet;
    uint256 maxPerMint;
    bytes32 root;
    uint256 maxPerPhase;
    uint256 price;
    uint256 minAmount; // after min amount is reached, the public phase becomes time-gated
    bool isMinEnabled; // enables min amount validation
    uint256 phaseStart;
    uint256 phaseEnd;
}

struct PhaseState {
    uint256 totalMinted;
    mapping(address => uint256) userMinted;
}