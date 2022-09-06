// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/// @title Common interface for Silo Incentive Contract
interface INotificationReceiver {
    /// @dev Informs the contract about token transfer
    /// @param _token address of the token that was transferred
    /// @param _from sender
    /// @param _to receiver
    /// @param _amount amount that was transferred
    function onAfterTransfer(address _token, address _from, address _to, uint256 _amount) external;

    /// @dev Sanity check function
    /// @return always true
    function notificationReceiverPing() external pure returns (bytes4);
}