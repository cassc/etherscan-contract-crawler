// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IBaseRewardPool {
    function pid() external view returns(uint);
    function extraRewards(uint index) external view returns(address);
    function extraRewardsLength() external view returns(uint);
    function totalAssets() external view returns(uint);
    function balanceOf(address account) external view returns(uint);
    function earned(address account) external view returns(uint);
    function getReward() external returns(bool);
    function withdrawAndUnwrap(uint amount, bool claim) external returns(bool);
}