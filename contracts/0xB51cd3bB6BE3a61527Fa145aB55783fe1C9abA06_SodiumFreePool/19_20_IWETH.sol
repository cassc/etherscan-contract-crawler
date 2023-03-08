// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IWETH {
    function deposit() external payable;

    function balanceOf(address) external returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function withdraw(uint256 wad) external;
}