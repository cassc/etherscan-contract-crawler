// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IWETH {
    function withdraw(uint256 wad) external;

    function deposit() external payable;

    function balanceOf(address owner) external view returns (uint256);
}