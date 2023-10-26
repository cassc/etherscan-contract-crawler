// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

interface IRangeOrder {
    struct RangeOrderParams {
        IUniswapV3Pool pool;
        bool zeroForOne;
        int24 tickThreshold;
        uint256 amountIn;
        uint256 minLiquidity;
        address payable receiver;
        uint256 maxFeeAmount;
    }

    function setRangeOrder(RangeOrderParams memory params_) external payable;
}