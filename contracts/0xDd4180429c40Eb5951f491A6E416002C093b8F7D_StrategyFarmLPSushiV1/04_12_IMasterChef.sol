//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function enterStaking(uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function lpToken(uint256 _pid) external view returns (address);

    function userInfo(uint256 _pid, address _user) external view returns (
        // amount, rewardDebt
        uint256, uint256
    );

    function poolInfo(uint256 _pid) external view returns (
        // lpToken, allocPoint, lastRewardBlock, accTokensPerShare
        address, uint256, uint256, uint256
    );
}