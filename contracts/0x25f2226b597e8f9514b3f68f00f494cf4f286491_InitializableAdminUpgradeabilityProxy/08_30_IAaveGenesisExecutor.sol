// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IAaveGenesisExecutor {
    event MigrationProgrammedForBlock(uint256 blockNumber);
    event MigrationStarted();

    function setActivationBlock(uint256 blockNumber) external;
    function startMigration() external;
    function returnAdminsToGovernance() external;
}