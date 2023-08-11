// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IManageable {
    function manager() external view returns (address);
}