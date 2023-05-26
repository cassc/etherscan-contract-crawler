// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../Interfaces/IUniswapV2Router.sol";
import "../Interfaces/IUniswapV2Pair.sol";
import "../Interfaces/IERC20.sol";

library MyobuLib {
    /**
     * @dev Calculates the percentage of a number
     * @param number: The number to calculate the percentage of
     * @param percentage: The percentage of the number to return
     * @return The percentage of a number
     */
    function percentageOf(uint256 number, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        return (number * percentage) / 100;
    }

    /**
     * @dev Swaps an amount of tokens for ETH
     * @param uniswapV2Router: The uniswap router to trade through
     * @param amount: The amount of tokens to swap
     * @param to: The address to send the recieved tokens to
     * @return The amount of ETH recieved
     */
    function swapForETH(
        IUniswapV2Router uniswapV2Router,
        uint256 amount,
        address to
    ) internal returns (uint256) {
        uint256 startingBalance = to.balance;
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            to,
            block.timestamp
        );

        return to.balance - startingBalance;
    }

    /**
     * @dev Adds liquidity for the token in ETH
     * @param uniswapV2Router: The uniswap router to add liquidity through
     * @param amountToken: The amount of tokens to add liquidity with
     * @param amountETH: The amount of ETH to add liquidity with
     * @param to: The address to send the recieved LP tokens to
     */
    function addLiquidityETH(
        IUniswapV2Router uniswapV2Router,
        uint256 amountToken,
        uint256 amountETH,
        address to
    ) internal {
        uniswapV2Router.addLiquidityETH{value: amountETH}(
            address(this),
            amountToken,
            0,
            0,
            to,
            block.timestamp
        );
    }

    /**
     * @param token: The address of the token to transfer
     * @param from: The sender of the tokens
     * @param to: The receiver of the tokens
     * @param amount: The amount of tokens to transfer
     */
    function transferTokens(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).transferFrom(from, to, amount);
    }

    /**
     * @dev Returns the token for a Uniswap V2 Pair
     */
    function tokenFor(address pair) internal view returns (address) {
        return IUniswapV2Pair(pair).token0();
    }
}