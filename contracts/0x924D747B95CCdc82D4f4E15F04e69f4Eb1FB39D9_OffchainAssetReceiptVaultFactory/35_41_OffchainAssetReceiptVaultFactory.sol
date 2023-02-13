// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "../receipt/ReceiptVaultFactory.sol";
import {OffchainAssetReceiptVault, OffchainAssetReceiptVaultConfig, OffchainAssetVaultConfig, ReceiptVaultConfig} from "./OffchainAssetReceiptVault.sol";
import {Receipt, ReceiptFactory} from "../receipt/ReceiptFactory.sol";
import {ClonesUpgradeable as Clones} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

/// @title OffchainAssetReceiptVaultFactory
/// @notice Factory for creating and deploying `OffchainAssetReceiptVault`.
contract OffchainAssetReceiptVaultFactory is ReceiptVaultFactory {
    constructor(
        ReceiptVaultFactoryConfig memory config_
    )
        ReceiptVaultFactory(config_) //solhint-disable-next-line no-empty-blocks
    {}

    /// @inheritdoc Factory
    function _createChild(
        bytes memory data_
    ) internal virtual override returns (address) {
        OffchainAssetVaultConfig memory offchainAssetVaultConfig_ = abi.decode(
            data_,
            (OffchainAssetVaultConfig)
        );

        address clone_ = Clones.clone(implementation);
        OffchainAssetReceiptVault(clone_).initialize(
            OffchainAssetReceiptVaultConfig(
                offchainAssetVaultConfig_.admin,
                _createReceipt(clone_, offchainAssetVaultConfig_.vaultConfig)
            )
        );
        return clone_;
    }

    /// Typed wrapper for `createChild`.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param offchainAssetVaultConfig_ Config for the
    /// `OffchainAssetReceiptVault`.
    /// @return New `OffchainAssetReceiptVault` child contract address.
    function createChildTyped(
        OffchainAssetVaultConfig memory offchainAssetVaultConfig_
    ) external returns (OffchainAssetReceiptVault) {
        return
            OffchainAssetReceiptVault(
                createChild(abi.encode(offchainAssetVaultConfig_))
            );
    }
}