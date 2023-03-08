// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISwapRouterMaverick.sol";
import "../weth/IWETH.sol";
import "../WethProvider.sol";

abstract contract Maverick is WethProvider {
    struct MaverickData {
        address pool;
        uint256 deadline;
    }

    function swapOnMaverick(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        MaverickData memory data = abi.decode(payload, (MaverickData));

        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        Utils.approve(address(exchange), _fromToken, fromAmount);

        ISwapRouterMaverick(exchange).exactInputSingle(
            ISwapRouterMaverick.ExactInputSingleParams({
                tokenIn: _fromToken,
                tokenOut: _toToken,
                pool: data.pool,
                recipient: address(this),
                deadline: data.deadline,
                amountIn: fromAmount,
                amountOutMinimum: 1,
                sqrtPriceLimitD18: 0
            })
        );

        if (address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }

    function buyOnMaverick(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        MaverickData memory data = abi.decode(payload, (MaverickData));

        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        Utils.approve(address(exchange), _fromToken, fromAmount);

        ISwapRouterMaverick(exchange).exactOutputSingle(
            ISwapRouterMaverick.ExactOutputSingleParams({
                tokenIn: _fromToken,
                tokenOut: _toToken,
                pool: data.pool,
                recipient: address(this),
                deadline: data.deadline,
                amountOut: toAmount,
                amountInMaximum: fromAmount
            })
        );

        if (address(fromToken) == Utils.ethAddress() || address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }
}