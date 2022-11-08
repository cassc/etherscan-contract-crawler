pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT License


interface ITeam {
    function stake(address account, uint256 amount) external;

    function unstake(address account, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}