// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";

library UniswapV2Utils {
    using SafeERC20 for IERC20;

    error InsufficientAmountLP();

    function quote(
        address router,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256 amountOut) {
        if (path.length < 2) return amountIn;

        uint256[] memory amountsOut = IUniswapV2Router02(router).getAmountsOut(amountIn, path);
        return amountsOut[amountsOut.length - 1];
    }

    function addLiquidityWithSingleToken(
        address router,
        uint256 amount,
        address[] memory path0,
        address[] memory path1,
        uint256 deadline
    ) internal returns (uint256 amountLP) {
        uint256 amountOut0 = swap(router, amount / 2, path0, deadline);
        uint256 amountOut1 = swap(router, amount / 2, path1, deadline);

        (address token0, address token1) = (path0[path0.length - 1], path1[path1.length - 1]);
        (, , uint256 _amountLP) = IUniswapV2Router02(router).addLiquidity(
            token0,
            token1,
            amountOut0,
            amountOut1,
            0,
            0,
            address(this),
            deadline
        );

        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        if (balance0 > 0) {
            IERC20(token0).safeTransfer(msg.sender, balance0);
        }
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        if (balance1 > 0) {
            IERC20(token1).safeTransfer(msg.sender, balance1);
        }

        return _amountLP;
    }

    function swap(
        address router,
        uint256 amountIn,
        address[] memory path,
        uint256 deadline
    ) internal returns (uint256 amountOut) {
        if (path.length < 2) return amountIn;

        uint256[] memory amountsOut = IUniswapV2Router02(router).swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            deadline
        );
        return amountsOut[amountsOut.length - 1];
    }
}