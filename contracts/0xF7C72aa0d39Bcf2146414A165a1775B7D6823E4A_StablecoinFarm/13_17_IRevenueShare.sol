// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/**
 * @title IRevenueShare
 * @notice Revenue share interface
 */
interface IRevenueShare {
    /**
     * @notice Withdraws tokens
     */
    function withdraw() external;

    /**
     * @notice Locks tokens
     * @param _amount The number of tokens to lock
     */
    function lock(uint256 _amount) external;

    /**
     * @notice Locks tokens on behalf of the user
     * @param _amount The number of tokens to lock
     * @param _user The address of the user
     */
    function lock(uint256 _amount, address _user) external;
}