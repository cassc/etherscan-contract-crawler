// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IBentCVXRewarderV2 {
    function deposit(address _user, uint256 _amount) external;
    function withdraw(address _user, uint256 _amount) external;
    function claimAll(address _user) external returns (bool claimed);
    function claim(address _user, uint256[] memory pids) external returns (bool claimed);
}