// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.20;

import {AccountMetadata, Drips, SplitsReceiver} from "./Drips.sol";
import {Managed} from "./Managed.sol";
import {StorageSlot} from "openzeppelin-contracts/utils/StorageSlot.sol";

/// @notice A Drips driver implementing immutable splits configurations.
/// Anybody can create a new account ID and configure its splits configuration,
/// but nobody can update its configuration afterwards, it's immutable.
/// This driver doesn't allow collecting funds for account IDs it manages, but anybody
/// can receive streams and split for them on Drips, which is enough because the splits
/// configurations always give away 100% funds, so there's never anything left to collect.
contract ImmutableSplitsDriver is Managed {
    /// @notice The Drips address used by this driver.
    Drips public immutable drips;
    /// @notice The driver ID which this driver uses when calling Drips.
    uint32 public immutable driverId;
    /// @notice The required total splits weight of each splits configuration
    uint32 public immutable totalSplitsWeight;
    /// @notice The ERC-1967 storage slot holding a single `uint256` counter of created identities.
    bytes32 private immutable _counterSlot = _erc1967Slot("eip1967.immutableSplitsDriver.storage");

    /// @notice Emitted when an immutable splits configuration is created.
    /// @param accountId The account ID.
    /// @param receiversHash The splits receivers list hash
    event CreatedSplits(uint256 indexed accountId, bytes32 indexed receiversHash);

    /// @param _drips The Drips contract to use.
    /// @param _driverId The driver ID to use when calling Drips.
    constructor(Drips _drips, uint32 _driverId) {
        drips = _drips;
        driverId = _driverId;
        totalSplitsWeight = _drips.TOTAL_SPLITS_WEIGHT();
    }

    /// @notice The ID of the next account to be created.
    /// Every account ID is a 256-bit integer constructed by concatenating:
    /// `driverId (32 bits) | accountIdsCounter (224 bits)`.
    /// @return accountId The account ID.
    function nextAccountId() public view returns (uint256 accountId) {
        // By assignment we get `accountId` value:
        // `zeros (224 bits) | driverId (32 bits)`
        accountId = driverId;
        // By bit shifting we get `accountId` value:
        // `driverId (32 bits) | zeros (224 bits)`
        // By bit masking we get `accountId` value:
        // `driverId (32 bits) | accountIdsCounter (224 bits)`
        // We can treat that the counter is a 224 bit value without explicit casting
        // because there will never be 2^224 account IDs registered.
        accountId = (accountId << 224) | StorageSlot.getUint256Slot(_counterSlot).value;
    }

    /// @notice Creates a new account ID, configures its
    /// splits configuration and emits its metadata.
    /// The configuration is immutable and nobody can control the account ID after its creation.
    /// Calling this function is the only way and the only chance to emit metadata for that account.
    /// @param receivers The list of the account's splits receivers to be set.
    /// Must be sorted by the splits receivers' addresses, deduplicated and without 0 weights.
    /// Each splits receiver will be getting `weight / totalSplitsWeight`
    /// share of the funds collected by the account.
    /// The sum of the receivers' weights must be equal to `totalSplitsWeight`,
    /// or in other words the configuration must be splitting 100% of received funds.
    /// @param accountMetadata The list of account metadata to emit for the created account.
    /// The keys and the values are not standardized by the protocol, it's up to the users
    /// to establish and follow conventions to ensure compatibility with the consumers.
    /// @return accountId The new account ID with `receivers` configured.
    function createSplits(
        SplitsReceiver[] calldata receivers,
        AccountMetadata[] calldata accountMetadata
    ) public whenNotPaused returns (uint256 accountId) {
        accountId = nextAccountId();
        StorageSlot.getUint256Slot(_counterSlot).value++;
        uint256 weightSum = 0;
        unchecked {
            for (uint256 i = 0; i < receivers.length; i++) {
                weightSum += receivers[i].weight;
            }
        }
        require(weightSum == totalSplitsWeight, "Invalid total receivers weight");
        emit CreatedSplits(accountId, drips.hashSplits(receivers));
        drips.setSplits(accountId, receivers);
        if (accountMetadata.length > 0) drips.emitAccountMetadata(accountId, accountMetadata);
    }
}