/*
    Copyright 2022 https://www.dzap.io
    SPDX-License-Identifier: MIT
*/
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../interfaces/IAggregationExecutor.sol";

enum FeeType {
    BATCH_SWAP,
    BATCH_SWAP_LP,
    BATCH_TRANSFER
}

struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address payable srcReceiver;
    address payable dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 flags;
    bytes permit;
}

struct LpSwapDetails {
    address router;
    address token;
    uint256 amount;
    bytes permit;
    address[] tokenAToPath;
    address[] tokenBToPath;
}

struct WNativeSwapDetails {
    address router;
    uint256 sizeBps; // weth %
    uint256 minReturnAmount;
    address[] nativeToOutputPath;
}

// erc + native
struct SwapDetails {
    IAggregationExecutor executor;
    SwapDescription desc;
    bytes routeData;
    bytes permit;
}

// for direct swap using uniswap v2 forks
// even for wNative refund is in native
// even if dstToken is wNative, native token is given
struct UnoSwapDetails {
    address router;
    uint256 amount;
    uint256 minReturnAmount;
    address[] path;
    bytes permit;
}

struct OutputLp {
    address router;
    address lpToken;
    uint256 minReturnAmount;
    address[] nativeToToken0;
    address[] nativeToToken1;
}

struct TransferDetails {
    address recipient;
    InputTokenData[] data;
}

struct Token {
    address token;
    uint256 amount;
}

struct InputTokenData {
    IERC20 token;
    uint256 amount;
    bytes permit;
}

// logs swapTokensToTokens unoSwapTokensToTokens
struct SwapInfo {
    IERC20 srcToken;
    IERC20 dstToken;
    uint256 amount;
    uint256 returnAmount;
}

// logs swapLpToTokens
struct LPSwapInfo {
    Token[] lpInput; // srcToken, amount
    Token[] lpOutput; // dstToken, returnAmount
}

// logs batchTransfer
struct TransferInfo {
    address recipient;
    Token[] data;
}

struct Router {
    bool isSupported;
    uint256 fees;
}

struct NftData {
    uint256 discountedFeeBps;
    uint256 expiry;
}