// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBlurPool {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function initialize() external;
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address user) external view returns (uint256);
    function deposit() external payable;
    function deposit(address user) external payable;
    function withdraw(uint256 amount) external;
    function withdrawFrom(address from, address to, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}