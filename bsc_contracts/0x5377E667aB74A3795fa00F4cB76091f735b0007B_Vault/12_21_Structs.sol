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
    address srcToken;
    uint256 amount;
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
}

struct MultiChainDescription {
    address srcToken;
    uint256 amount;
    address receiver;
    uint64 dstChainId;
    uint64 nonce;
    address router;
}

struct PolyBridgeDescription {
    address fromAsset;
    uint64 toChainId;
    bytes toAddress;
    uint256 amount;
    uint256 fee;
    uint256 id;
    uint64 nonce;
}


struct AnyMapping {
    address tokenAddress;
    address anyTokenAddress;
}