// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


interface IUSDT {
    function allowance(address owner, address spender) external returns (uint);
    function balanceOf(address who) external returns (uint);
    function transfer(address to, uint value) external;
    function transferFrom(address from, address to, uint value) external;
}