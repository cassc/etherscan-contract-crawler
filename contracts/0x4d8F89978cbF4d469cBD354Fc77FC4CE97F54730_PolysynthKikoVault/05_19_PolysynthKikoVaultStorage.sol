// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;


abstract contract PolysynthKikoVaultStorageV1 {    
    // Amount locked for scheduled withdrawals last week;
    uint256 public lastQueuedWithdrawAmount;

    // Queued withdraw shares for the current round
    uint256 public currentQueuedWithdrawShares;
}

abstract contract PolysynthKikoVaultStorageV2 {
    // Auction time in seconds from 12AM UTC
    uint256 public auctionTime;
}

abstract contract PolysynthKikoVaultStorageV3 {
    // Role for observing the price from defender
    address public observer;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of RibbonDeltaVaultStorage
// e.g. RibbonDeltaVaultStorage<versionNumber>, so finally it would look like
// contract RibbonDeltaVaultStorage is RibbonDeltaVaultStorageV1, RibbonDeltaVaultStorageV2
abstract contract PolysynthKikoVaultStorage is
    PolysynthKikoVaultStorageV1,
    PolysynthKikoVaultStorageV2,
    PolysynthKikoVaultStorageV3
{

}