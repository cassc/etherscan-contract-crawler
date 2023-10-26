//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Deposit Contract Interface
/// @notice This interface exposes methods to perform validator deposits
interface IDepositContract {
    /// @notice Official deposit method to activate a validator on the consensus layer
    /// @param pubkey The 48 bytes long BLS Public key representing the validator
    /// @param withdrawalCredentials The 32 bytes long withdrawal credentials, configures the withdrawal recipient
    /// @param signature The 96 bytes long BLS Signature performed by the pubkey's private key
    /// @param depositDataRoot The root hash of the whole deposit data structure
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawalCredentials,
        bytes calldata signature,
        bytes32 depositDataRoot
    ) external payable;
}