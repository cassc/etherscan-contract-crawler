// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoomerToken {
    function burnFrom(address account, uint256 amount) external;
    function approve(address operator, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}