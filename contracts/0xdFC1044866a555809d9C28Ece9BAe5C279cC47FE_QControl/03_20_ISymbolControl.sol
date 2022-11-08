// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ISymbolControl {
    function isValid(string memory emoji) external view returns (bool valid);
}