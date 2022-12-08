// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface ILiquidityProvider {
    /**
     * Allows LPs to deposit into the pool.
     */
    function deposit(uint256 amount) external;

    /** 
     * Allows the pool owner and EA to make required initial deposit before turning on the pool
     */
    function makeInitialDeposit(uint256 amount) external;

    /**
     * Allows LPs to withdraw from the pool
     */
    function withdraw(uint256 amount) external;

    /**
     * Allows an LP to withdraw all their shares from the pool
     */
    function withdrawAll() external;
}