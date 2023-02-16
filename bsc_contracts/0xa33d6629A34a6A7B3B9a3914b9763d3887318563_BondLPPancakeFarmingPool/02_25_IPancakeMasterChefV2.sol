// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IPancakeMasterChefV2 {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingCake(uint256 _pid, address _user) external;
}