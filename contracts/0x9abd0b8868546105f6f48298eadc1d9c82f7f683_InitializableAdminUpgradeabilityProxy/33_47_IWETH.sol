pragma solidity >=0.5.0;

// SPDX-License-Identifier: GPL-3.0-only


interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint wad) external returns (bool);
}