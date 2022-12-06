// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";

import "SCMinterMigration.sol";
import "IGeminonOracle.sol";
import "TimeLocks.sol";



contract GeminonInfrastructure is Ownable, TimeLocks, SCMinterMigration {
    
    address public arbitrageur;


    /// @dev Set the address of the arbitrage operator.
    function setArbitrageur(address arbitrageur_) external onlyOwner {
        arbitrageur = arbitrageur_;
    }


    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +             SMART CONTRACTS INFRASTRUCTURE CHANGES                 +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    /// @dev Apply the change in the GEX oracle address proposed using
    /// the requestAddressChange() function. This function can only be called
    /// 30 days after the request of the change.
    function applyOracleChange() external onlyOwner {
        require(!isMigrationRequested); // dev: migration requested
        require(changeRequests[oracleGeminon].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[oracleGeminon].timestampRequest > 30 days); // dev: Time elapsed
        require(changeRequests[oracleGeminon].newAddressRequested != address(0)); // dev: Address zero

        changeRequests[oracleGeminon].changeRequested = false;
        oracleGeminon = changeRequests[oracleGeminon].newAddressRequested;
        oracleAge = uint64(block.timestamp);
    }
    

    /// @notice Cancels any pending request for changes in the smart contract
    function cancelChangeRequests() external onlyOwner {
        
        if (changeRequests[address(0)].changeRequested)
            changeRequests[address(0)].changeRequested = false;
        
        if (changeRequests[oracleGeminon].changeRequested)
            changeRequests[oracleGeminon].changeRequested = false;
        
        if (isMigrationRequested) {
            isMigrationRequested = false;
            IGeminonOracle(oracleGeminon).cancelMigration();
        }        
    }
}