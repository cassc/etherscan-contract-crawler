//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ICSwapUniswapV3 {
    /** @notice Used to specify UniswapV3 specific parameters for CSwap.
        @param router The address of the UniswapV3 router.
        @param path The path taken to perform the swap. This is encoded according to specification by Uniswap V3. This can be 
            obtained by performing abi.encodePacked(tokenIn, fee, intermediateToken, fee, outputToken). Examples for how to perform
            this off-chain can be found within the github repository.
        @param receiver The address where the swapped tokens will be sent to. This is an optional argument, and users can enter
            the zero address instead. In this case, the tokens will be sent to the invoker and must then be sweeped back to the user.
        @param deadline The unix timestamp at which point the swap no longer becomes valid. This must be in seconds. If the
            order has no expiry, then use parameter 0.
     */
    struct UniswapV3SwapParams {
        address router;
        bytes path;
        address receiver;
        uint256 deadline;
    }
}