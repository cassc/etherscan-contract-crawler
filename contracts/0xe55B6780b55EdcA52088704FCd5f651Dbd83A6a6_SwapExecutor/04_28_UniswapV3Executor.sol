// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title UniswapV3Executor
 * @notice Base contract that contains Uniswap V3 specific logic.
 * Uniswap V3 requires specific interface to be implemented so we have to provide a compliant implementation
 */
abstract contract UniswapV3Executor is IUniswapV3SwapCallback {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata /* data */
    ) external override {
        if (amount0Delta > 0) {
            IERC20 token0 = IERC20(IUniswapV3Pool(msg.sender).token0());
            token0.safeTransfer(msg.sender, uint256(amount0Delta));
        }
        if (amount1Delta > 0) {
            IERC20 token1 = IERC20(IUniswapV3Pool(msg.sender).token1());
            token1.safeTransfer(msg.sender, uint256(amount1Delta));
        }
    }
}