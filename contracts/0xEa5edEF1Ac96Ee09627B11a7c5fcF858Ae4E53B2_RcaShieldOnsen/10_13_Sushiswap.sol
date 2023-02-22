// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IMasterChef {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, address indexed lpToken, address indexed rewarder);

    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function withdraw(uint256 pid, uint256 amount) external;

    function harvest(uint256 pid, address to) external;

    function withdrawAndHarvest(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function emergencyWithdraw(uint256 pid, address to) external;

    function poolInfo(uint256 pid)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accSushiPerShare
        );

    function lpToken(uint256 pid) external view returns (address);

    function poolLength() external view returns (uint256);
}