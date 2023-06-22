// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Additional storage added to avoid changing the storage layout during upgrades.
contract StakefishTransactionStorageV3Additional {
    // Added in January 2023 update to support tip collection for NFT validators.
    address internal nftManagerAddress;
    // Total commission accumulated since the beginning of the lifetime of the contract.
    uint256 internal accLifetimeStakefishCommission;
}