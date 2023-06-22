// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IUSDT {
    function transfer(address to, uint256 value) external ;
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}