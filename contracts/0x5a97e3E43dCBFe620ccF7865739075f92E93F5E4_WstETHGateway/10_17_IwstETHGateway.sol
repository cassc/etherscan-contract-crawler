// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IwstETHGateWay {
    error NonRegisterPoolException();

    /**
     * @dev Adds stETH liquidity to wstETH pool
     * - transfers the underlying to the pool
     * - mints Diesel (LP) tokens to onBehalfOf
     * @param amount Amount of tokens to be deposited
     * @param onBehalfOf The address that will receive the dToken
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without a facilitator.
     */
    function addLiquidity(
        uint256 amount,
        address onBehalfOf,
        uint256 referralCode
    ) external;

    /// @dev Removes liquidity from pool
    ///  - burns LP's Diesel (LP) tokens
    ///  - returns the equivalent amount of underlying to 'to'
    /// @param amount Amount of Diesel tokens to burn
    /// @param to Address to transfer the underlying to
    function removeLiquidity(uint256 amount, address to)
        external
        returns (uint256 amountGet);
}