// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ILockRegistry {
    function isUnlocked(uint256 _id) external view returns (bool);

    function updateApprovedContracts(
        address[] calldata _contracts,
        bool[] calldata _values
    ) external;

    function emergencyUnlock(uint256 _id, uint256 pos, address addr) external;

    function lock(uint256 _id) external;

    function unlock(uint256 _id, uint256 pos) external;

    function findPos(uint256 _id, address addr) external view returns (uint256);
}