// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IRewardPool {
    function deposit(uint256 _pid, uint256 _amount) external;

    function depositFor(address _account, uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function withdrawAll(uint256 _pid) external;

    function harvestAllRewards() external;

    function pendingReward(uint256 _pid, address _user) external view returns (uint256);

    function pendingAllRewards(address _user) external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function poolLength() external view returns (uint256);

    function getPoolInfo(uint256 _pid) external view returns (address _lp, uint256 _allocPoint);

    function getRewardPerSecond() external view returns (uint256);
}