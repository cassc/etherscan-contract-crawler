// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface IRibbonLendFactory {
    function withdrawReward(address[] calldata pools) external;

    function setPoolRewardPerSecond(address pool, uint256 rewardPerSecond)
        external;
}