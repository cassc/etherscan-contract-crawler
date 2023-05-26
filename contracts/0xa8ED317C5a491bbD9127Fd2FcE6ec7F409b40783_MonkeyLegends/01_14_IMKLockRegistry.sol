// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMKLockRegistry {
    function isUnlocked(uint256 _id) external view returns (bool);

    function updateApprovedContracts(
        address[] calldata _contracts,
        bool[] calldata _values
    ) external;

    function lock(uint256 _id) external;

    function unlock(uint256 _id, uint256 pos) external;

    function findPos(uint256 _id, address addr) external view returns (uint256);

    function clearLockId(uint256 _id, uint256 pos) external;
}