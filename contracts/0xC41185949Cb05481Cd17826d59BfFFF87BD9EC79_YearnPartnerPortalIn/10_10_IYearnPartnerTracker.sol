/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IYearnPartnerTracker {
    /**
     * @notice Deposit into a vault the specified amount from depositer
     * @param vault The address of the vault
     * @param partnerId The address of the partner who has referred this deposit
     * @param amount The amount to deposit
     * @return The number of yVault tokens received
     */
    function deposit(
        address vault,
        address partnerId,
        uint256 amount
    ) external returns (uint256);
}