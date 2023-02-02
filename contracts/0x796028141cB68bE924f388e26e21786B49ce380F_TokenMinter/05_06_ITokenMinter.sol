// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ITokenMinter {
    /// @notice triggers whenever a withdrawaladdress gets changed
    /// @param txSender the address that initiated the address change
    /// @param to the new withdrawaladress
    /// @param changedAddress name of adress that is changed
    event WithdrawalAddressSet(
        address indexed txSender,
        address indexed to,
        string changedAddress
    );
    /// @notice triggers whenever a withdrawaladdress gets changed
    /// @param txSender the address that initiated the dev share change
    /// @param oldValue the dev share before
    /// @param newValue the dev share after 
    event devShareSet(
        address indexed txSender,
        uint256 oldValue,
        uint256 newValue
    );
    /// @notice triggers whenever a shareholder receives their share of a withdrawal
    /// @param txSender the address that initiated the withdrawal
    /// @param to the address of the shareholder receiving this part of the withdrawal
    /// @param amount the amount of eth received by `to`
    event PaidOut(address indexed txSender, address indexed to, uint256 amount);
    /// @notice triggers whenever funds are withdrawn
    /// @param txSender the sender of the transaction
    /// @param amount the amount of eth withdrawn
    event Withdrawn(address indexed txSender, uint256 amount);
}