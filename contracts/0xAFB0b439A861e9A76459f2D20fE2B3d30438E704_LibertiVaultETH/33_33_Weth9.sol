//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract Weth9 {
    function deposit() public payable virtual;

    function withdraw(uint256 wad) public virtual;

    function approve(address guy, uint256 wad) public virtual;
}