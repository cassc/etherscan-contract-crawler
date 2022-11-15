// SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;


contract LockTOSv2Storage {

    mapping(uint256 => address) public proxyImplementation;
    mapping(address => bool) public aliveImplementation;
    mapping(bytes4 => address) public selectorImplementation;

    bool public lock_;
    address public staker;

    modifier onlyStaker {
        require(msg.sender == staker, "caller is not staker");
        _;
    }
}