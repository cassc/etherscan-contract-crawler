// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.6;

/// @title   Interface of CashManager contract
/// @author  Primitive
interface ICashManager {
    /// ERRORS ///

    /// @notice  Thrown when the sender is not WETH
    error OnlyWETHError();

    /// @notice                Thrown when the amount required is above balance
    /// @param balance         Actual ETH or token balance of the contract
    /// @param requiredAmount  ETH or token amount required by the user
    error BalanceTooLowError(uint256 balance, uint256 requiredAmount);

    /// EFFECT FUNCTIONS ///

    /// @notice       Wraps ETH into WETH and transfers to the msg.sender
    /// @param value  Amount of ETH to wrap
    function wrap(uint256 value) external payable;

    /// @notice           Unwraps WETH to ETH and transfers to a recipient
    /// @param amountMin  Minimum amount to unwrap
    /// @param recipient  Address of the recipient
    function unwrap(uint256 amountMin, address recipient) external payable;

    /// @notice           Transfers the tokens in the contract to a recipient
    /// @param token      Address of the token to sweep
    /// @param amountMin  Minimum amount to transfer
    /// @param recipient  Recipient of the tokens
    function sweepToken(
        address token,
        uint256 amountMin,
        address recipient
    ) external payable;

    /// @notice  Transfers the ETH balance of the contract to the caller
    function refundETH() external payable;
}