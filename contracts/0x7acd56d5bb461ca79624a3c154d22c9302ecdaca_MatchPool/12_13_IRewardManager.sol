// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IRewardManager {
    function dlpUpdateReward(address _account) external;
    function lsdUpdateReward(address _account) external;
    function treasury() external view returns (address);
}