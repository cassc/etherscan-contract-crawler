// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IStakedToken {
    function transfer(address to, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
    function balanceOf(address owner) external returns(uint256);
    function name() external returns(string memory);
    function symbol() external returns(string memory);

}