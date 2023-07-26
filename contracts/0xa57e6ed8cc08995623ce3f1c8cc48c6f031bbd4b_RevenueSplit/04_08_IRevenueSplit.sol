// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRevenueSplit {
    function initialize(
        string memory,
        address[] calldata,
        uint256[] calldata
    ) external;
}