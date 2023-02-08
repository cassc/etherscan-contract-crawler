// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IWETH {
    function balanceOf(address user) external view returns (uint256);

    function withdraw(uint256 wad) external;

    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);
}