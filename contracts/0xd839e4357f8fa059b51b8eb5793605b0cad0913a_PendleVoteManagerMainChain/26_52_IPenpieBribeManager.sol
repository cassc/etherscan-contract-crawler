// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface IPenpieBribeManager {
    function exactCurrentEpoch() external view returns(uint256);
    function getEpochEndTime(uint256 _epoch) external view returns(uint256 endTime);
}