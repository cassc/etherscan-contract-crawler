//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface IDepositManager {
    function depositERC20ForUser(
        address token,
        address user,
        uint256 amount
    ) external;
}