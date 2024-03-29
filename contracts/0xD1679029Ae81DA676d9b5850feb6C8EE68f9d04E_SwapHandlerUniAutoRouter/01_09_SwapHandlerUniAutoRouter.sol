// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./SwapHandlerCombinedBase.sol";

/// @notice Swap handler executing trades on Uniswap with a payload generated by auto-router
contract SwapHandlerUniAutoRouter is SwapHandlerCombinedBase {
    address immutable public uniSwapRouter02;

    constructor(address uniSwapRouter02_, address uniSwapRouterV2, address uniSwapRouterV3) SwapHandlerCombinedBase(uniSwapRouterV2, uniSwapRouterV3) {
        uniSwapRouter02 = uniSwapRouter02_;
    }

    function swapPrimary(SwapParams memory params) override internal returns (uint amountOut) {
        setMaxAllowance(params.underlyingIn, params.amountIn, uniSwapRouter02);

        if (params.mode == 0) {
            // for exact input return value is ignored
            swapInternal(params);
        } else {
            // exact output on SwapRouter02 routed through uniV2 is not exact, balance check is needed
            uint preBalance = IERC20(params.underlyingOut).balanceOf(msg.sender);

            swapInternal(params);

            uint postBalance = IERC20(params.underlyingOut).balanceOf(msg.sender);

            require(postBalance >= preBalance, "SwapHandlerUniAutoRouter: negative amount out");

            unchecked { amountOut = postBalance - preBalance; }
        }
    }

    function swapInternal(SwapParams memory params) private {
        (bool success, bytes memory result) = uniSwapRouter02.call(params.payload);
        if (!success) revertBytes(result);
    }
}