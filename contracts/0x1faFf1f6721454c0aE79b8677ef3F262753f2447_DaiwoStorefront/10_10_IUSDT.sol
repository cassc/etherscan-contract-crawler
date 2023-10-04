// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface IUSDT {
    function transferFrom(address from, address to, uint256 amount) external;
    function transfer(address to, uint256 value) external;
}