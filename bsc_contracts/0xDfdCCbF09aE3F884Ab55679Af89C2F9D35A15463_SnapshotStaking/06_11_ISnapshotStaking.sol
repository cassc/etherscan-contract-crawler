// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISnapshotStaking {
    function poolLength() external view returns (uint256);
    function pendingReward(uint256 _pid, address _user) external view returns (uint256);
    function addPool(
        address _lpToken, 
        address _rewardToken, 
        uint256 _poolSize, 
        uint256 _startTime, 
        uint256 _endTime, 
        uint256 _apr
    ) external;
    function stake(uint256 _pid, uint256 _amount) external;
    function unStake(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;

    event AddPool(uint256 indexed pid, uint256 created);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
}