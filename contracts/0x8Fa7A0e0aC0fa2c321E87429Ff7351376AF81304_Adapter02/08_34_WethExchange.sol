// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IWETH.sol";
import "../Utils.sol";
import "../WethProvider.sol";

abstract contract WethExchange is WethProvider {
    function swapOnWETH(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    ) internal {
        _swapOnWeth(fromToken, toToken, fromAmount);
    }

    function buyOnWeth(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    ) internal {
        _swapOnWeth(fromToken, toToken, fromAmount);
    }

    function _swapOnWeth(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount
    ) private {
        address weth = WETH;

        if (address(fromToken) == weth) {
            require(address(toToken) == Utils.ethAddress(), "Destination token should be ETH");
            IWETH(weth).withdraw(fromAmount);
        } else if (address(fromToken) == Utils.ethAddress()) {
            require(address(toToken) == weth, "Destination token should be weth");
            IWETH(weth).deposit{ value: fromAmount }();
        } else {
            revert("Invalid fromToken");
        }
    }
}