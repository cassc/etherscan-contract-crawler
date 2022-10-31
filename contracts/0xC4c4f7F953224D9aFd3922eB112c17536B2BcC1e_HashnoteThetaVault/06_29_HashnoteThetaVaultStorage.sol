// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

abstract contract HashnoteThetaVaultStorageV1 {
    // Current oToken premium
    uint256 public currentOtokenPremium;
    // Auction duration
    uint256 public auctionDuration;
    // Auction id of current option
    uint256 public optionAuctionID;
    // Amount locked for scheduled withdrawals last week;
    uint256 public lastQueuedWithdrawAmount;
    // Queued withdraw shares for the current round
    uint256 public currentQueuedWithdrawShares;
    // Vault Pauser Contract for the vault
    address public vaultPauser;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of HashnoteThetaVaultStorage
// e.g. HashnoteThetaVaultStorage<versionNumber>, so finally it would look like
// contract HashnoteThetaVaultStorage is HashnoteThetaVaultStorageV1, HashnoteThetaVaultStorageV2
abstract contract HashnoteThetaVaultStorage is
    HashnoteThetaVaultStorageV1
{

}