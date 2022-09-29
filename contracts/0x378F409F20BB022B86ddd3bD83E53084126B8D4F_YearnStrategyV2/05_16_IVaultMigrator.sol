// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IVaultMigrator {
    function migrateAll(address vaultFrom, address vaultTo) external;

    function migrateShares(
        address vaultFrom,
        address vaultTo,
        uint256 shares
    ) external;

    function migrateAllWithPermit(
        address vaultFrom,
        address vaultTo,
        uint256 deadline,
        bytes calldata signature
    ) external;

    function migrateSharesWithPermit(
        address vaultFrom,
        address vaultTo,
        uint256 shares,
        uint256 deadline,
        bytes calldata signature
    ) external;
}