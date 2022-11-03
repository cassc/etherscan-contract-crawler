// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ICSwapUniswapV2 {
    /** @notice Used to specify UniswapV2 specific parameters for CSwap.
        @dev The first address in 'path[]' must match 'tokenIn' and the last element must match 'tokenOut'
        @param router The address of the UniswapV2 router.
        @param path The path taken to perform the swap. For simple hops, this is an array with 2 elements [tokenIn,tokenOut].
            Where the user may wish to take an alternate route (such as a multi-hop), this will become an array with any number
            of elements. Eg: [tokenIn, WETH, tokenOut] to allow trading via WETH. This will be necessary for certain tokens where
            the available liquidity is concentrated within specific pairs and can be used to get the best price for users.
        @param receiver The address where the swapped tokens will be sent to. This is an optional argument, and users can enter
            the zero address instead. In this case, the tokens will be sent to the invoker and must then be sweeped back to the user.
        @param deadline The unix timestamp at which point the swap no longer becomes valid. This must be in seconds. If the
            order has no expiry, then use parameter 0.
     */
    struct UniswapV2SwapParams {
        address router;
        address[] path;
        address receiver;
        uint256 deadline;
    }
}