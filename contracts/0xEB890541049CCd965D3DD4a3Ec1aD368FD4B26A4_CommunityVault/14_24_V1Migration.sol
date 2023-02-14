//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../interfaces/V1Migrateable.sol";
import "hardhat/console.sol";

interface IDexibleUpdate {

    function setCommunityVault(address vault) external;
}

abstract contract V1Migration is V1Migrateable {

    modifier onlyAdmin() {
        VaultStorage.VaultData storage vs = VaultStorage.load();
        require(msg.sender == vs.adminMultiSig, "Unauthorized");
        _;
    }

    function scheduleMigration(V1MigrationTarget newVault) public onlyAdmin {
        VaultStorage.VaultData storage vs = VaultStorage.load();
        vs.migrateAfterTime = block.timestamp + vs.timelockSeconds;
        vs.pendingMigrationTarget = address(newVault);
        emit MigrationScheduled(address(newVault), vs.migrateAfterTime);
    }

    function cancelMigration() public onlyAdmin {
        VaultStorage.VaultData storage vs = VaultStorage.load();
        delete vs.migrateAfterTime;
        address addr = vs.pendingMigrationTarget;
        delete vs.pendingMigrationTarget;
        emit MigrationCancelled(addr);
    }

    function canMigrate() public view returns (bool) {
         VaultStorage.VaultData storage vs = VaultStorage.load();
         return vs.pendingMigrationTarget != address(0) &&
                vs.migrateAfterTime > 0 &&
                vs.migrateAfterTime < block.timestamp;
    }

    /**
     * Migrate the state of the vault to a new version. This will transfer all current state
     * and transfer fee token balances as well. Note that 
     */
    function migrateV1() external {
        require(this.canMigrate(), "Cannot migrate yet");

        VaultStorage.VaultData storage vs = VaultStorage.load();
        V1MigrationTarget target = V1MigrationTarget(vs.pendingMigrationTarget);
        //console.log("Migrating to", vs.pendingMigrationTarget);

        //pause all operations
        vs.paused = true;

        //transfer token balances
        IERC20[] storage tokens = vs.feeTokens;
        //console.log("Transferring balances for", tokens.length, "fee tokens");
        for(uint i=0;i<tokens.length;++i) {
            uint b = tokens[i].balanceOf(address(this));
            if(b > 0) {
                tokens[i].transfer(address(target), b);
            }
        }

        //tell DXBL that there is a new minter
        //console.log("Setting DXBL token new minter", vs.pendingMigrationTarget);
        vs.dxbl.setNewMinter(address(target));

        //tell Dexible there is a new vault
        IDexibleUpdate(vs.dexible).setCommunityVault(address(target));

        //create transfer info
        VaultStorage.VaultMigrationV1 memory v1 = VaultStorage.VaultMigrationV1({
            //current daily volume adjusted each hour
            currentVolume: vs.currentVolume,

            //last time traded in this vault
            lastTradeTimestamp: vs.lastTradeTimestamp,

            //hourly volume totals accumulated in last 24 hrs. 
            hourlyVolume: vs.hourlyVolume,

            currentMintRate: vs.currentMintRate
        });
        
        //ask target to migrate from this vault state
        //console.log("Calling migration target...");
        target.migrationFromV1(v1);

        emit VaultMigrated(address(target));

        //then tear down this version
        //console.log("Self-destructing to new target");
        address payable addr = payable(address(target));
        selfdestruct(addr);
    }
}