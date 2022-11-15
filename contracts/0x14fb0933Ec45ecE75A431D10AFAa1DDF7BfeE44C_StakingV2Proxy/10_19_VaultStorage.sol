//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract VaultStorage  {

    bool public pauseProxy;

    mapping(uint256 => address) public proxyImplementation;
    mapping(address => bool) public aliveImplementation;
    mapping(bytes4 => address) public selectorImplementation;

}