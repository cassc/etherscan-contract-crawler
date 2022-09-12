// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./OrderLib.sol";

/**
 * Adapter between TWAP and exchange implementations
 */
interface IExchange {
    /**
     * Returns actual output amount after fees and price impact
     */
    function getAmountOut(uint256 amountIn, bytes calldata data) external view returns (uint256 amountOut);

    /**
     * Swaps amountIn to amount out using abi encoded data (can either be path or more complex data)
     */
    function swap(
        uint256 amountIn,
        uint256 amountOutMin,
        bytes calldata data
    ) external;
}