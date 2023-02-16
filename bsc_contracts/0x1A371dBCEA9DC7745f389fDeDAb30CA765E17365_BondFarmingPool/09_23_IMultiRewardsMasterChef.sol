// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IMultiRewardsMasterChef {
    function depositForUser(
        uint256 _pid,
        uint256 _amount,
        address user_
    ) external;

    function withdrawForUser(
        uint256 _pid,
        uint256 _amount,
        address user_
    ) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;
}