// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IMasterChef {
    function sushi() external view returns (address);

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accSushiPerShare
        );

    function userInfo(uint256 _pid, address user) external view returns (uint256 amount, uint256 rewardDebt);

    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;
}