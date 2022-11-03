// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

interface ICLPUniswapV2 {
    /** @notice Used to specify UniswapV2 specific parameters for CLP.
        @param router The address of the UniswapV2 router.
        @param amountAMin The minimum amount of token0 to deposit.
        @param amountBMin The minimum amount of token1 to deposit.
        @param receiver The address where the LP tokens will be sent to. This is an optional argument, and users can enter
            the zero address instead. In this case, the token will be sent to the invoker and must then be sweeped back to the user.
        @param deadline The unix timestamp at which point the transaction no longer becomes valid. This must be in seconds. If the
            order has no expiry, then use parameter 0.
     */
    struct UniswapV2LPDepositParams {
        address router;
        uint256 amountAMin;
        uint256 amountBMin;
        address receiver;
        uint256 deadline;
    }

    /** @notice Used to specify UniswapV2 specific parameters for CLP.
        @param amountAMin The minimum amount of token0 to receive.
        @param amountBMin The minimum amount of token1 to receive.
        @param receiver The address where the underlying tokens will be sent to. This is an optional argument, and users can enter
            the zero address instead. In this case, the tokens will be sent to the invoker and must then be sweeped back to the user.
        @param deadline The unix timestamp at which point the transaction no longer becomes valid. This must be in seconds. If the
            order has no expiry, then use parameter 0.
     */
    struct UniswapV2LPWithdrawParams {
        uint256 amountAMin;
        uint256 amountBMin;
        address receiver;
        uint256 deadline;
    }
}