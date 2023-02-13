// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {Factory} from "@rainprotocol/rain-protocol/contracts/factory/Factory.sol";
import {Receipt, ReceiptFactory} from "../receipt/ReceiptFactory.sol";
import {ClonesUpgradeable as Clones} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./ReceiptVault.sol";

/// Thrown when the provided implementation is address zero.
error ZeroImplementation();

/// Thrown when the provided receipt factory is address zero.
error ZeroReceiptFactory();

/// All config required to construct the `ReceiptVaultFactory`.
/// @param implementation Template contract to clone for each child.
/// @param receiptFactory `ReceiptFactory` to produce receipts for each child.
struct ReceiptVaultFactoryConfig {
    address implementation;
    address receiptFactory;
}

/// @title ReceiptVaultFactory
/// @notice Extends `Factory` with affordances for deploying a receipt and
/// transferring ownership to a `ReceiptVault`. Marked as abstract so that
/// specific receipt vault factories can inherit this with concrete receipt vault
/// child types.
abstract contract ReceiptVaultFactory is Factory {
    /// Emitted when `ReceiptVaultFactory` is constructed with the immutable
    /// config shared for all children.
    /// @param sender `msg.sender` that constructed the factory.
    /// @param config All construction config for the `ReceiptVaultFactory`.
    event Construction(address sender, ReceiptVaultFactoryConfig config);

    /// Template contract to clone for each child.
    address public immutable implementation;
    /// Factory that produces receipts for the receipt vault.
    ReceiptFactory public immutable receiptFactory;

    /// Record the reference implementation to clone for each child and the
    /// `ReceiptFactory` to produce new receipts.
    /// @param config_ All construction config for the factory.
    constructor(ReceiptVaultFactoryConfig memory config_) {
        if (config_.implementation == address(0)) {
            revert ZeroImplementation();
        }
        if (config_.receiptFactory == address(0)) {
            revert ZeroReceiptFactory();
        }

        implementation = config_.implementation;
        receiptFactory = ReceiptFactory(config_.receiptFactory);

        // Implementation is inherited from `Factory`.
        emit Implementation(msg.sender, config_.implementation);
        emit Construction(msg.sender, config_);
    }

    /// Create the receipt for the vault and ensure ownership, then build the
    /// `ReceiptVaultConfig` from the `VaultConfig` with the new receipt merged
    /// in.
    /// @param receiptVault_ The address of the receipt vault the new receipt
    /// will be created for and owned by.
    /// @param config_ Vault config to be merged into the final
    /// `ReceiptVaultConfig`.
    /// @return The config merged with the newly created receipt.
    function _createReceipt(
        address receiptVault_,
        VaultConfig memory config_
    ) internal virtual returns (ReceiptVaultConfig memory) {
        Receipt receipt_ = Receipt(receiptFactory.createChild(""));
        receipt_.transferOwnership(receiptVault_);
        return ReceiptVaultConfig(address(receipt_), config_);
    }
}