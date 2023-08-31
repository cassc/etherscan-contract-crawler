// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

interface IDistributor {
    function distribute() external;

    function nextRewardAt(uint256 _rate) external view returns (uint256);

    function nextReward() external view returns (uint256);
}