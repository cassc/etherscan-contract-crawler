// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWNative {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}