/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}