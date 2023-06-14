// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ID4ADrb {
    event CheckpointSet(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbX18);

    function getCheckpointsLength() external view returns (uint256);

    function getStartBlock(uint256 drb) external view returns (uint256);

    function getDrb(uint256 blockNumber) external view returns (uint256);

    function currentRound() external view returns (uint256);

    function setNewCheckpoint(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbE18) external;

    function modifyLastCheckpoint(uint256 startDrb, uint256 startBlock, uint256 blocksPerDrbE18) external;
}