// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IPETHVaultForDAO {
    function deposit() external payable;

    function borrow(uint256 amount) external;

    function repay(uint256 amount) external;

    function withdraw(uint256 amount) external;
}