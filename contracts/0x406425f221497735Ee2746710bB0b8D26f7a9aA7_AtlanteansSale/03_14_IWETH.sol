// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

interface IWETH {
    function balanceOf(address account) external returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}