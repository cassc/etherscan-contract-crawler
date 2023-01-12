// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libraries/SafeERC20.sol";

using SafeERC20 for IERC20;

struct BridgeInfo {
    string bridge;
    address dstToken;
    uint64 chainId;
    uint256 amount;
    address user;
    uint64 nonce;
}

struct BridgeDescription {
    address receiver;
    uint64 dstChainId;
    uint64 nonce;
    uint32 maxSlippage;
}

struct SwapData {
    address user;
    address srcToken;
    address dstToken;
    uint256 amount;
    bytes callData;
    bool fee;
}

struct MultiChainDescription {
    address receiver;
    uint64 dstChainId;
    uint64 nonce;
    address router;
}

struct AnyMapping {
    address tokenAddress;
    address anyTokenAddress;
}