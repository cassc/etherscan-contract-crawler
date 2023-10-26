// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct BridgeInfo {
    string bridge;
    address dstToken;
    uint64 chainId;
    uint256 amount;
    address user;
}

struct InputToken {
    address srcToken;
    uint256 amount;
}

struct OutputToken {
    address dstToken;
}

struct SwapData {
    address router;
    address user;
    InputToken[] input;
    OutputToken[] output;
    DupToken[] dup;
    bytes callData;
    address feeToken;
    bytes plexusData;
}

struct DupToken {
    address token;
    uint256 amount;
}

struct RelaySwapData {
    SwapData swapData;
    address feeTokenAddress;
}

struct Dex {
    mapping(address => bool) allowedDex;
    mapping(address => address) proxy;
}