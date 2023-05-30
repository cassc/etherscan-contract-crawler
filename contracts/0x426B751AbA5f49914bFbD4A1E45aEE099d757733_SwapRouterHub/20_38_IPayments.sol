// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any native token(e.g. ETH) balance held by this contract to the `msg.sender`
    /// @dev This method is suitable for the following 2 scenarios:
    /// 1. When using exactInput, the inputted Ether is not fully consumed due to insufficient liquidity so,
    ///    remaining Ether can be withdrawn through this method
    /// 2. When using exactOutput, the inputted Ether is not fully consumed because the slippage settings
    /// are too high, henceforth, the remaining Ether can be withdrawn through this method
    function refundNativeToken() external payable;

    /// @notice Transfers the full amount of a token held by this contract to a recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the tokens which will be transferred to the `recipient`
    /// @param amountMinimum The minimum amount of tokens required for a transfer
    /// @param recipient The destination address of the tokens
    function sweepToken(address token, uint256 amountMinimum, address recipient) external payable;
}