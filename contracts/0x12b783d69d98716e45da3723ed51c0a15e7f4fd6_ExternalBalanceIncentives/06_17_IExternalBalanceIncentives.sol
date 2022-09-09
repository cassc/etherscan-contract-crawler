//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

/// @title IExternalBalanceIncentives allows other contract to update the users balance
///        in the incentives contract
interface IExternalBalanceIncentives {
    /// @notice Changes the users balance
    /// @param _account The users account to update
    /// @param balance The new balance of the users
    function updateBalance(address _account, uint256 balance) external;
}