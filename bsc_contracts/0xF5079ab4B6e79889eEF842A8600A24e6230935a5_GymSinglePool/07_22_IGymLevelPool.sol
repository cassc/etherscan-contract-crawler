// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IGymLevelPool {
    function updateUserQualification(address _wallet, uint256 _level) external;
}