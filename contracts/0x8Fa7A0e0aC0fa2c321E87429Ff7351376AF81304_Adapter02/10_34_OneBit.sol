// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Utils.sol";
import "./ISwapRouterOneBit.sol";
import "../weth/IWETH.sol";
import "../WethProvider.sol";

abstract contract OneBit is WethProvider {
    function swapOnOneBit(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address exchange,
        bytes calldata payload
    ) internal {
        address _fromToken = address(fromToken) == Utils.ethAddress() ? WETH : address(fromToken);
        address _toToken = address(toToken) == Utils.ethAddress() ? WETH : address(toToken);

        if (address(fromToken) == Utils.ethAddress()) {
            IWETH(WETH).deposit{ value: fromAmount }();
        }

        Utils.approve(address(exchange), _fromToken, fromAmount);

        ISwapRouterOneBit(exchange).swapTokensWithTrust(
            IERC20(_fromToken),
            IERC20(_toToken),
            fromAmount,
            1,
            address(this)
        );

        if (address(toToken) == Utils.ethAddress()) {
            IWETH(WETH).withdraw(IERC20(WETH).balanceOf(address(this)));
        }
    }
}