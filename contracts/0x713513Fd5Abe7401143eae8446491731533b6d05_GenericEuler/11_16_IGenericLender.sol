// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IAccessControlAngle.sol";

/// @title IGenericLender
/// @author Yearn with slight modifications from Angle Core Team
/// @dev Interface for the `GenericLender` contract, the base interface for contracts interacting
/// with lending and yield farming platforms
interface IGenericLender is IAccessControlAngle {

    /// @notice Name of the lender on which funds are invested
    function lenderName() external view returns (string memory);

    /// @notice Helper function to get the current total of assets managed by the lender.
    function nav() external view returns (uint256);

    /// @notice Reference to the `Strategy` contract the lender interacts with
    function strategy() external view returns (address);

    /// @notice Returns an estimation of the current Annual Percentage Rate on the lender
    function apr() external view returns (uint256);

    /// @notice Returns an estimation of the current Annual Percentage Rate weighted by the assets under 
    /// management of the lender
    function weightedApr() external view returns (uint256);

    /// @notice Withdraws a given amount from lender
    /// @param amount The amount the caller wants to withdraw
    /// @return Amount actually withdrawn
    function withdraw(uint256 amount) external returns (uint256);

    /// @notice Withdraws as much as possible in case of emergency and sends it to the `PoolManager`
    /// @param amount Amount to withdraw
    /// @dev Does not check if any error occurs or if the amount withdrawn is correct
    function emergencyWithdraw(uint256 amount) external;

    /// @notice Deposits the current balance of the contract to the lending platform
    function deposit() external;

    /// @notice Withdraws as much as possible from the lending platform
    /// @return Whether everything was withdrawn or not
    function withdrawAll() external returns (bool);

    /// @notice Check if assets are currently managed by the lender
    /// @dev We're considering that the strategy has no assets if it has less than 10 of the
    /// underlying asset in total to avoid the case where there is dust remaining on the lending market
    /// and we cannot withdraw everything
    function hasAssets() external view returns (bool);

    /// @notice Returns an estimation of the current Annual Percentage Rate after a new deposit
    /// of `amount`
    /// @param amount Amount to add to the lending platform, and that we want to take into account
    /// in the apr computation
    function aprAfterDeposit(uint256 amount) external view returns (uint256);

    /// @notice
    /// Removes tokens from this Strategy that are not the type of tokens
    /// managed by this Strategy. This may be used in case of accidentally
    /// sending the wrong kind of token to this Strategy.
    ///
    /// Tokens will be sent to `governance()`.
    ///
    /// This will fail if an attempt is made to sweep `want`, or any tokens
    /// that are protected by this Strategy.
    ///
    /// This may only be called by governance.
    /// @param _token The token to transfer out of this poolManager.
    /// @param to Address to send the tokens to.
    /// @dev
    /// Implement `_protectedTokens()` to specify any additional tokens that
    /// should be protected from sweeping in addition to `want`.
    function sweep(address _token, address to) external;
}