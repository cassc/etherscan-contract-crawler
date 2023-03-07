// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

struct TokenCheck {
    address token;
    uint256 minAmount;
    uint256 maxAmount;
}

struct TokenUse {
    address protocol;
    uint256 chain;
    address account;
    uint256[] inIndices;
    TokenCheck[] outs;
    bytes args; // Example of reserved value: 0x44796E616D6963 ("Dynamic")
}

struct SwapStep {
    uint256 chain;
    address swapper;
    address sponsor;
    uint256 nonce;
    uint256 deadline;
    TokenCheck[] ins;
    TokenCheck[] outs;
    TokenUse[] uses;
}

struct Swap {
    address account;
    SwapStep[] steps;
}

struct StealthSwap {
    uint256 chain;
    address swapper;
    address account;
    bytes32[] stepHashes;
}

struct UseParams {
    uint256 chain;
    address account;
    TokenCheck[] ins;
    uint256[] inAmounts;
    TokenCheck[] outs;
    bytes args;
    address msgSender;
    bytes msgData;
}

interface IUseProtocol {
    function use(UseParams calldata params) external payable;
}