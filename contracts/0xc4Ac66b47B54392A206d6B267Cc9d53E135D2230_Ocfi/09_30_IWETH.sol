// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IWETH {
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}