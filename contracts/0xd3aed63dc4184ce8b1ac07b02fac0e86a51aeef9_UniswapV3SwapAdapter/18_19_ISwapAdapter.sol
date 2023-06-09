//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;

interface ISwapAdapter {
    struct SwapParams {
        address[] path;
        uint256 amountIn;
        uint256 minAmountOut;
        address recipient;
        bytes data;
    }

    function getAmountIn(
        address[] memory path,
        uint256 amountOut
    ) external returns (uint256 amountIn, bytes memory swapData);

    function getAmountOut(
        address[] memory path,
        uint256 amountIn
    ) external returns (uint256 amountOut, bytes memory swapData);

    // @dev view only version of getAmountIn
    function getAmountInView(
        address[] memory path,
        uint256 amountOut
    ) external view returns (uint256 amountIn, bytes memory swapData);

    // @dev view only version of getAmountOut
    function getAmountOutView(
        address[] memory path,
        uint256 amountIn
    ) external view returns (uint256 amountOut, bytes memory swapData);

    // @dev calls swap router to fulfill the exchange
    // @return amountOut the amount of tokens transferred out, may be 0 if this can not be fetched
    function swap(SwapParams calldata params) external payable returns (uint256 amountOut);
}