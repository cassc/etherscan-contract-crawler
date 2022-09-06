// SPDX-License-Identifier: GPL-3
pragma solidity >=0.8.9;

// Author: Angry Wasp
// [email protected]

interface IWETH9 {
    function balanceOf(address user) external returns (uint256);
    function deposit() external payable;
    function withdraw(uint256 wad) external payable;
    function totalSupply() external view;
    function approve(address guy, uint256 wad) external returns (bool);
    function transfer(address dst, uint256 wad) external returns (bool);
    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}