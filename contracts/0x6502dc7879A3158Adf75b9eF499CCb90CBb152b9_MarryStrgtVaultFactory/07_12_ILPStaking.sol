// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

interface ILPStaking {
    function deposit(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accEmissionPerShare
        );

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingStargate(uint256 _pid, address _user)
        external
        view
        returns (uint256);
}