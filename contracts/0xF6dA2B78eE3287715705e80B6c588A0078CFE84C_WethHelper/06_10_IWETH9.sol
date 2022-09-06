// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

interface IWETH9 {
    function deposit() external payable;

    function approve(address guy, uint256 wad) external returns (bool);
}