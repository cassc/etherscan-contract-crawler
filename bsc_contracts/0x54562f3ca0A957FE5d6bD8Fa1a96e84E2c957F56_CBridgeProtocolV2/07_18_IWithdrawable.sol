// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

struct Withdraw {
    address token;
    uint256 amount;
    address to;
}

interface IWithdrawable {
    event Withdrawn(address token, uint256 amount, address to);

    function withdraw(Withdraw[] calldata withdraws) external;
}