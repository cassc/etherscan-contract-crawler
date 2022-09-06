// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGeyser {
    function totalStakedFor(address owner) external view returns (uint256);
}