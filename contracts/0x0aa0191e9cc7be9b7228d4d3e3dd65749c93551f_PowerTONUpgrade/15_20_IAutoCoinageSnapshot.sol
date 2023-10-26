// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAutoCoinageSnapshot {

    function snapshot() external returns (uint256);
    function snapshot(address layer2) external returns (uint256) ;

    function sync(address layer2) external returns (uint256);
    function sync(address layer2, address account) external returns (uint256);
    function syncBatch(address layer2,  address[] memory accounts) external returns (uint256);
    function addSync(address layer2, address account) external returns (uint256);

    function getLayer2TotalSupplyInTokamak(address layer2) external view
        returns (
                uint256 totalSupplyLayer2,
                uint256 balance,
                uint256 refactoredCount,
                uint256 remain
        );

    function getLayer2BalanceOfInTokamak(address layer2, address user) external view
        returns (
                uint256 balanceOfLayer2Amount,
                uint256 balance,
                uint256 refactoredCount,
                uint256 remain
        );

    function getBalanceOfInTokamak(address account) external view
        returns (
                uint256 accountAmount
        );

    function getTotalStakedInTokamak() external view
        returns (
                uint256 accountAmount
        );

    function currentAccountBalanceSnapshots(address layer2, address account) external view
        returns (
                bool snapshotted,
                uint256 snapShotBalance,
                uint256 snapShotRefactoredCount,
                uint256 snapShotRemain,
                uint256 currentBalanceOf,
                uint256 curBalances,
                uint256 curRefactoredCounts,
                uint256 curRemains
        );

    function currentTotalSupplySnapshots(address layer2) external view
        returns (
                bool snapshotted,
                uint256 snapShotBalance,
                uint256 snapShotRefactoredCount,
                uint256 snapShotRemain,
                uint256 currentTotalSupply,
                uint256 curBalances,
                uint256 curRefactoredCounts,
                uint256 curRemains
        );

    function currentFactorSnapshots(address layer2) external view
        returns (
                bool snapshotted,
                uint256 snapShotFactor,
                uint256 snapShotRefactorCount,
                uint256 curFactorValue,
                uint256 curFactor,
                uint256 curRefactorCount
        );

    function getCurrentLayer2SnapshotId(address layer2) external view returns (uint256) ;

    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);

    function balanceOf(address layer2, address account) external view returns (uint256);
    function balanceOfAt(address account, uint256 snashotAggregatorId) external view returns (uint256);
    function balanceOfAt(address layer2, address account, uint256 snapshotId) external view returns (uint256);
    function totalSupply(address layer2) external view returns (uint256);
    function totalSupplyAt(uint256 snashotAggregatorId) external view returns (uint256 totalStaked);
    function totalSupplyAt(address layer2, uint256 snapshotId) external view returns (uint256);

}