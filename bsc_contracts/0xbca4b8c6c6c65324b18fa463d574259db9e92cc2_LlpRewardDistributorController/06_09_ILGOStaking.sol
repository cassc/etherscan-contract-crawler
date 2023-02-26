// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ILGOStaking {
    function userInfo(address _user) external view returns (uint256 _amount, uint256 _rewardDebt);
    function updateRewards() external;
}