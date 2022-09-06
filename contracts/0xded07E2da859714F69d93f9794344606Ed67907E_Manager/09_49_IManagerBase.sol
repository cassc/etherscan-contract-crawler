// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IManagerBase {
    function WETH9() external view returns (address);

    function hub() external view returns (address);

    function muffinDepositCallback(
        address token,
        uint256 amount,
        bytes calldata data
    ) external;

    /// @notice             Deposit tokens into hub's internal account
    /// @dev                DO NOT deposit rebasing tokens or multiple-address tokens as it will cause loss of funds
    /// @param recipient    Recipient of the token deposit
    /// @param token        Token address
    /// @param amount       Amount to deposit
    function deposit(
        address recipient,
        address token,
        uint256 amount
    ) external payable;

    /// @notice             Withdraw tokens from hub's internal account to recipient
    /// @param recipient    Recipient of the withdrawn token
    /// @param token        Token address
    /// @param amount       Amount to withdraw
    function withdraw(
        address recipient,
        address token,
        uint256 amount
    ) external payable;

    /// @notice             Deposit tokens into hub's internal account managed by other address
    /// @dev                DO NOT deposit rebasing tokens or multiple-address tokens as it will cause loss of funds
    /// @param recipient    Recipient of the token deposit
    /// @param token        Token address
    /// @param amount       Amount to deposit
    function depositToExternal(
        address recipient,
        uint256 recipientAccRefId,
        address token,
        uint256 amount
    ) external payable;

    /// @notice Unwraps the contract's WETH balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH from users.
    /// @dev This function should be an intermediate function of an atomic transaction. Do not leave WETH inside this
    /// contract accross transactions.
    function unwrapWETH(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    /// @dev This function should be an intermediate function of an atomic transaction. Do not leave ETH inside this
    /// contract accross transactions.
    function refundETH() external payable;
}