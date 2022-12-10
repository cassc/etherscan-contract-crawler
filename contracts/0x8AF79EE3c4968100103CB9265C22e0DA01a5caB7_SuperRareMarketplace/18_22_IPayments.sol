// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

/// @author koloz
/// @title IPayments
/// @notice Interface for the Payments contract used.
interface IPayments {
    function refund(address _payee, uint256 _amount) external payable;

    function payout(address[] calldata _splits, uint256[] calldata _amounts)
        external
        payable;
}