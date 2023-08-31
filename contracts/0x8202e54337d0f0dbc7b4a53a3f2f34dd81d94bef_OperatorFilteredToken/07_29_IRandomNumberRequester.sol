// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IRandomNumberRequester {
    function process(uint256 rand, uint256 requestId) external;
}