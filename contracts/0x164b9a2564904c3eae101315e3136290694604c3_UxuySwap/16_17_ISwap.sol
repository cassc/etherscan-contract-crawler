//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

import "./IProviderRegistry.sol";

interface ISwap is IProviderRegistry {
    struct SwapParams {
        bytes4 providerID;
        address[] path;
        uint256 amountIn;
        uint256 minAmountOut;
        address recipient;
        bytes data;
    }

    // @dev calculates the minimum tokens needed for the amountOut
    // @return swapData the data to be passed to the swap
    function getAmountIn(
        bytes4 providerID,
        address[] memory path,
        uint256 amountOut
    ) external returns (uint256 amountIn, bytes memory swapData);

    // @dev calculates the maximum tokens can be transferred for the amountIn
    // @return swapData the data to be passed to the swap
    function getAmountOut(
        bytes4 providerID,
        address[] memory path,
        uint256 amountIn
    ) external returns (uint256 amountOut, bytes memory swapData);

    // @dev view only version of getAmountIn
    function getAmountInView(
        bytes4 providerID,
        address[] memory path,
        uint256 amountOut
    ) external view returns (uint256 amountIn, bytes memory swapData);

    // @dev view only version of getAmountOut
    function getAmountOutView(
        bytes4 providerID,
        address[] memory path,
        uint256 amountIn
    ) external view returns (uint256 amountOut, bytes memory swapData);

    // @dev calls swap adapter to fulfill the exchange
    // @return amountOut the amount of tokens transferred out, guarantee amountOut >= params.minAmountOut
    function swap(SwapParams calldata params) external returns (uint256 amountOut);
}