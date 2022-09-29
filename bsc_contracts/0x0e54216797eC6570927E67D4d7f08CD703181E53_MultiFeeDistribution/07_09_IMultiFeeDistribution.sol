// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IMultiFeeDistribution {

    function addReward(address rewardsToken) external;
    function mint(address user, uint256 amount, bool withPenalty) external;
    function exit() external;
    function withdrawExpiredLocks() external;
    function getReward() external;

}