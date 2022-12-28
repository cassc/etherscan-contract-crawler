// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @title Defines the function used to interact with Vesting from Token.
 */
interface ITokenVesting {
    /**
     * @notice Starts vesting.
     */
    function setStartAt() external;
}