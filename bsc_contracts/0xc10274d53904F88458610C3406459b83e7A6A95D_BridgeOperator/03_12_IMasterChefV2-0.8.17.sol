// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin-contracts-4.8/token/ERC20/IERC20.sol";

interface IMasterChefV2 {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 boostMultiplier;
    }

    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingCake(uint256 _pid, address _user) external view returns (uint256);

    function emergencyWithdraw(uint256 _pid) external;

    function lpToken(uint256 _pid) external view returns (IERC20);

    function updateBoostMultiplier(
        address _user,
        uint256 _pid,
        uint256 _newBoostMulti
    ) external;
}