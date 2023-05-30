// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IMgc {
    function principle() external view returns (address);

    function mvd() external view returns (address);

    function totalStaked() external view returns (uint256);

    function updateDeposit(uint256 value) external;

    function updateWithdraw(uint256 value) external;

    function sendReward(
        address receiver,
        address user,
        uint256 amount
    ) external;
}