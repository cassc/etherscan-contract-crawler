// SPDX-License-Identifier: LICENSED
pragma solidity ^0.7.0;

interface ILevelManager {
    function getUserLevel(address userAddr) external view returns (uint256);

    function getLevel(uint256 _okseAmount) external view returns (uint256);

    function updateUserLevel(
        address userAddr,
        uint256 beforeAmount
    ) external returns (bool);
}