//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../VaultStorage.sol";

interface V1MigrationTarget {
    /**
     * Call from current vault to migrate the state of the old vault to the new one. 
     */
    function migrationFromV1(VaultStorage.VaultMigrationV1 memory data) external;
}

interface V1Migrateable {

    event MigrationScheduled(address indexed newVault, uint afterTime);
    event MigrationCancelled(address indexed newVault);
    event VaultMigrated(address indexed newVault);

    function scheduleMigration(V1MigrationTarget target) external;

    function cancelMigration() external;

    function canMigrate() external view returns (bool);

    /**
     * Migrate the vault to a new vault address that implements the target interface
     * to receive this vault's state. This will transfer all fee token assets to the 
     * new vault. This can only be called after timelock is expired.
     */
    function migrateV1() external;
    
}