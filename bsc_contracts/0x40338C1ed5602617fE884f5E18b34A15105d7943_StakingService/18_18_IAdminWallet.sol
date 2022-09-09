// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

/**
 * @title AdminWallet Interface
 * @author Tim Loh
 * @notice Interface for AdminWallet where funds will be withdrawn to
 */
interface IAdminWallet {
    /**
     * @notice Emitted when admin wallet has been changed from `oldWallet` to `newWallet`
     * @param oldWallet The wallet before the wallet was changed
     * @param newWallet The wallet after the wallet was changed
     * @param sender The address that changes the admin wallet
     */
    event AdminWalletChanged(
        address indexed oldWallet,
        address indexed newWallet,
        address indexed sender
    );

    /**
     * @notice Returns the admin wallet address where funds will be withdrawn to
     * @return Admin wallet address
     */
    function adminWallet() external view returns (address);
}