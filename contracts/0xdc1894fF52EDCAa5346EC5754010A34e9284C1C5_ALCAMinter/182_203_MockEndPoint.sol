// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IMockEndPoint {
    function addOne() external;

    function addTwo() external;

    function factory() external returns (address);

    function i() external view returns (uint256);
}

/// @custom:salt MockEndPoint
contract MockEndPoint is IMockEndPoint {
    address public immutable factory;
    address public owner;
    uint256 public i;

    event AddedOne(uint256 indexed i);
    event AddedTwo(uint256 indexed i);
    event UpgradeLock(bool indexed lock);

    constructor() {
        factory = msg.sender;
    }

    function addOne() public {
        i++;
        emit AddedOne(i);
    }

    function addTwo() public {
        i = i + 2;
        emit AddedTwo(i);
    }
}