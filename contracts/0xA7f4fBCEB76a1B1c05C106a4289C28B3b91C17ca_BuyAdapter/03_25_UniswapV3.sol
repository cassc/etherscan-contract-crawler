// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISwapRouterUniV3.sol";
import "../weth/IWETH.sol";
import "../WethProvider.sol";

abstract contract UniswapV3 is WethProvider {
    struct UniswapV3Data {
        bytes path;
        uint256 deadline;
    }

    function swapOnUniswapV3(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        UniswapV3Data memory data = abi.decode(payload, (UniswapV3Data));

        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        Utils.approve(address(exchange), _fromToken, fromAmount);

        ISwapRouterUniV3(exchange).exactInput(
            ISwapRouterUniV3.ExactInputParams({
                path: data.path,
                recipient: address(this),
                deadline: data.deadline,
                amountIn: fromAmount,
                amountOutMinimum: 1
            })
        );

        if (address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }

    function buyOnUniswapV3(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        UniswapV3Data memory data = abi.decode(payload, (UniswapV3Data));

        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        Utils.approve(address(exchange), _fromToken, fromAmount);

        ISwapRouterUniV3(exchange).exactOutput(
            ISwapRouterUniV3.ExactOutputParams({
                path: data.path,
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