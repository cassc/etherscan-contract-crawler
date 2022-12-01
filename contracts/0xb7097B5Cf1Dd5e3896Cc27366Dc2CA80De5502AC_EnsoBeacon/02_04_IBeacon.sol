// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IBeacon {
    function implementation() external view returns (address);
}