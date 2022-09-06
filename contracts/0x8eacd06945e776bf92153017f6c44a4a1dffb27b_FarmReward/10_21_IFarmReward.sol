// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../Model.sol";

interface IFarmReward {
    function getCheckpoints(address userAddr, uint256 stakingIndex) external view returns(Model.Checkpoint[] memory);
    function calcRewardAmount(address userAddr, uint256 stakingIndex) external view returns(uint256);
    function calcRewardAmount(address userAddr) external view returns(uint256);
    function proxyClaim(address userAddr, uint256 index) external;
}