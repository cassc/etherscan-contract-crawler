// SPDX-License-Identifier: MIT
pragma solidity >0.8.8;

interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address dst, uint256 wad) external returns (bool);
}