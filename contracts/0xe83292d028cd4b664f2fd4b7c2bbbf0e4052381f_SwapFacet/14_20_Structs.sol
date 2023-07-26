// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct BridgeInfo {
    string bridge;
    address dstToken;
    uint64 chainId;
    uint256 amount;
    address user;
}

struct SwapData {
    address swapRouter;
    address user;
    address srcToken;
    address dstToken;
    uint256 amount;
    bytes callData;
}

struct Dex {
    mapping(address => bool) allowedDex;
    mapping(address => address) proxy;
}