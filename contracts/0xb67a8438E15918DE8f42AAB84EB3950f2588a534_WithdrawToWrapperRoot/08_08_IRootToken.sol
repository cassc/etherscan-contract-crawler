//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

interface IRootToken {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}