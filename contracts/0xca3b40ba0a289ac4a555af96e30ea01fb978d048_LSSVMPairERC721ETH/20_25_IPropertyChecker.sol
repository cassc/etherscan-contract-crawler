// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IPropertyChecker {
    function hasProperties(uint256[] calldata ids, bytes calldata params) external returns (bool);
}