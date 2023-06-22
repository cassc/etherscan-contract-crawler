// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

struct Staker {
    address addr;
    uint256 oldRewards;
}

interface ITornadoStakingRewards {
    function setReward(address account, uint256 amount) external;

    function checkReward(address account) external view returns (uint256);

    function accumulatedRewards(address account) external view returns (uint256);

    function accumulatedRewardPerTorn() external view returns (uint256);

    function addBurnRewards(uint256 amount) external;
}