// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
* @title ISCMinterMigration
* @author Geminon Protocol
* @notice Interface for SCMinter migration
*/
interface ISCMinterMigration {
    
    function oracleAge() external view returns(uint64);
    function isMigrationRequested() external view returns(bool);
    function timestampMigrationRequest() external view returns(uint64);
    function migrationMinter() external view returns(address);

    function requestMigration(address newMinter) external;
    function migrateMinter() external;
    function receiveMigration(uint256 amountGEX) external;
}