// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRedistributor {
    function requestRedistribution(uint256 nominal) external;
}