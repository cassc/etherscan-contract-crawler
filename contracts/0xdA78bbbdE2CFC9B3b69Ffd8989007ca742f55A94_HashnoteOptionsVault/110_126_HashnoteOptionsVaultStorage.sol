// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

abstract contract HashnoteOptionsVaultStorageV1 {
    // BATCH_AUCTION
    address public auction;
    // Auction duration
    uint256 public auctionDuration;
    // Auction id of current option
    uint256 public auctionId;
    // Percentage of lockedAmount used to determine how many structures to mint
    uint256 public leverageRatio;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of HashnoteOptionsVaultStorage
// e.g. HashnoteOptionsVaultStorage<versionNumber>, so finally it would look like
// contract HashnoteOptionsVaultStorage is HashnoteOptionsVaultStorageV1, HashnoteOptionsVaultStorageV2
abstract contract HashnoteOptionsVaultStorage is HashnoteOptionsVaultStorageV1 { }