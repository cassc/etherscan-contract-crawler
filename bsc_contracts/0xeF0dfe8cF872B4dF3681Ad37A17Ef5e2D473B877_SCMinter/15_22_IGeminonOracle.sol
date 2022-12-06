// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IGeminonOracle {

    // +++++++++++++++++++  PUBLIC STATE VARIABLES  +++++++++++++++++++++++++

    function isAnyPoolMigrating() external view returns(bool);
    function isAnyPoolRemoving() external view returns(bool);
    
    function scMinter() external view returns(address);
    function bridge() external view returns(address);
    function treasuryLender() external view returns(address);
    function feesCollector() external view returns(address);
    function pools(uint) external view returns(address);

    function ageSCMinter() external view returns(uint64);
    function ageBridge() external view returns(uint64);
    function ageTreasuryLender() external view returns(uint64);
    function ageFeesCollector() external view returns(uint64);
    
    function isMigratingMinter() external view returns(bool);
    function newMinter() external view returns(address);

    function isPool(address) external view returns(bool);
    function isMigratingPool(address) external view returns(bool);
    function isRemovingPool(address) external view returns(bool);
    function poolAge(address) external view returns(uint64);


    // ++++++++++++++++++++++++  INITIALIZATION  ++++++++++++++++++++++++++++

    function setSCMinter(address scMinter_) external;
    function setBridge(address bridge_) external;
    function setTreasuryLender(address lender) external;
    function setCollector(address feesCollector_) external;

    
    // ++++++++++++++++++++++++++  MIGRATIONS  ++++++++++++++++++++++++++++++

    function addPool(address newPool) external;
    function removePool(address pool) external;

    function requestMigratePool(address newPool) external;
    function setMigrationDone() external;
    function cancelMigration() external;

    function requestRemovePool() external;
    function setRemoveDone() external;
    function cancelRemove() external;
    
    function requestMigrateMinter(address newMinter) external;
    function setMinterMigrationDone() external;
    function cancelMinterMigration() external;


    // ++++++++++++++++++++  INFORMATIVE FUNCTIONS  +++++++++++++++++++++++++

    function getTotalCollatValue() external view returns(uint256);
    function getPoolCollatWeight(address pool) external view returns(uint256);
    
    function getSafePrice() external view returns(uint256);
    function getLastPrice() external view returns(uint256);
    
    function getMeanVolume() external view returns(uint256);
    function getLastVolume() external view returns(uint256);

    function getTotalMintedGEX() external view returns(uint256);
    function getExternalMintedGEX() external view returns(uint256);
    function getLockedAmountGEX() external view returns(uint256);
    function getHighestGEXPool() external view returns(address);
}