//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IChainLinkPriceOracle.sol";

struct OrderArgs {
    address maker; 
    uint256 amountIn; 
    uint256 amountOut; 
    address recipient; 
    uint256 startTime;
    uint256 endTime;
    uint256 stopPrice;
    IChainLinkPriceOracle oracleAddress;
    bytes oracleData;
    uint256 amountToFill;
    uint8 v; 
    bytes32 r;
    bytes32 s;
}
interface IStopLimitOrder {
    function fillOrder(
            OrderArgs memory order,
            address tokenIn,
            address tokenOut, 
            address receiver, 
            bytes calldata data) 
    external;
}