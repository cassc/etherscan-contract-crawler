// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITarget {
    function poolAddress(uint256) external view returns(address);
}