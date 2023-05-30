// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IWETHMinimum {
    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function balanceOf(address dst) external view returns (uint256);
}