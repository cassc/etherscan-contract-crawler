// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";

import "CollectibleFees.sol";
import "ISCMinter.sol";
import "IGeminonOracle.sol";

import "TimeLocks.sol";
import "TradePausable.sol";


contract SCMinterMigration is Ownable, TradePausable, TimeLocks, CollectibleFees {
    
    uint64 public oracleAge;

    bool public isMigrationRequested;
    uint64 public timestampMigrationRequest;
    address public migrationMinter;



    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                         MINTER MIGRATION                           +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @dev Register a request to migrate the minter.
    /// Begins a timelock of 7 days before enabling the migration.
    /// requestAddressChange() had to be made in this contract and in the
    /// oracle contract 7 days before this request.
    function requestMigration(address newMinter) external onlyOwner {
        require(changeRequests[address(this)].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[address(this)].timestampRequest > 7 days); // dev: Time elapsed
        require(changeRequests[address(this)].newAddressRequested == newMinter); // dev: Address not zero
        require(oracleGeminon != address(0)); // dev: oracle is not set

        changeRequests[address(this)].changeRequested = false;
        changeRequests[address(this)].newAddressRequested = address(this);
        changeRequests[address(this)].timestampRequest = type(uint64).max;
        
        isMigrationRequested = true;
        migrationMinter = newMinter;
        timestampMigrationRequest = uint64(block.timestamp);

        IGeminonOracle(oracleGeminon).requestMigrateMinter(newMinter);
        _pauseMint();
    }

    /// @dev Transfer all GEX in the minter to the new minter.
    /// Removes the minter from the Geminon Oracle.
    function migrateMinter() external onlyOwner whenMintPaused {
        require(isMigrationRequested); // dev: migration not requested
        require(oracleGeminon != address(0)); // dev: oracle is not set
        require(IGeminonOracle(oracleGeminon).isMigratingMinter()); // dev: migration not requested
        require(block.timestamp - timestampMigrationRequest > 15 days); // dev: timelock
        
        uint256 amountGEX = IERC20(GEX).balanceOf(address(this)) - _balanceFees;
        
        isMigrationRequested = false;

        IERC20(GEX).approve(migrationMinter, amountGEX);

        ISCMinter(migrationMinter).receiveMigration(amountGEX);
        
        IGeminonOracle(oracleGeminon).setMinterMigrationDone();
    }

    /// @dev Receive the funds of the previous minter that is migrating.
    function receiveMigration(uint256 amountGEX) external {
        require(oracleGeminon != address(0)); // dev: oracle is not set
        require(IGeminonOracle(oracleGeminon).scMinter() == msg.sender); // dev: sender is not pool
        require(IGeminonOracle(oracleGeminon).isMigratingMinter()); // dev: migration not requested

        require(IERC20(GEX).transferFrom(msg.sender, address(this), amountGEX));
    }
}