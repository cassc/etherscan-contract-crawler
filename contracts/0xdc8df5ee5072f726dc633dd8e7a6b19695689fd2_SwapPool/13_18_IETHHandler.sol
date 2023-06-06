// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IETHHandler {
    event Received(uint256 amount, address sender);
    event Sent(uint256 amount, address receiver);

    function withdraw(address wbnb, uint256 amount) external;
}