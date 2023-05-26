// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INameValidator {
    function valid(string calldata name) external view returns (bool);
}