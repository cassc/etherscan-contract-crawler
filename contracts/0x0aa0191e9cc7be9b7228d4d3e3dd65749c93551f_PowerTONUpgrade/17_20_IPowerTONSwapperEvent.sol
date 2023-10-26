// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IPowerTONSwapperEvent {
    event OnDeposit(address layer2, address indexed account, uint256 amount);
    event OnWithdraw(address layer2, address indexed account, uint256 amount);

    event Swapped(
        uint256 amount
    );

    event Distributed(address token, uint256 amount);
}