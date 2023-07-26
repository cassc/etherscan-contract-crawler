// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/*
 * @dev A parameter object containing data for bridging funds and an  between chains
 */
struct LzBridgeData {
    uint120 _srcPoolId;
    uint120 _dstPoolId;
    uint16 _dstChainId;
    address _bridgeAddress;
    uint96 fee;
}

/*
 * @dev A parameter object containing token swap data and a payment transaction payload
 */
struct TokenData {
    uint256 amountIn;
    uint256 amountOut;
    address tokenIn;
    address tokenOut;
    bytes path;
    bytes payload;
}