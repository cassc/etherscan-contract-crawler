// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Shared interface for EarlySale + StaakeSale
interface ISale {
    /**
     * @notice view the minimum amountof ETH per call
     */
    function MIN_INVESTMENT() external view returns (uint256);

    /**
     * @notice view the maximum total amount of ETH per investor
     */
    function MAX_INVESTMENT() external view returns (uint256);

    /**
     * @notice view the amount of STK still available for sale
     */
    function availableToken() external view returns (uint256);

    /**
     * @notice Buy STK token
     */
    function buy() external payable;

    /**
     * @notice view the amount of STK token for a user
     * @param _user, address of the user
     */
    function balanceOf(address _user) external view returns (uint256);

    /**
     * @notice view the amount of ETH spent by a user
     * @param _user, address of the user
     */
    function getETHSpent(address _user) external view returns (uint256);
}