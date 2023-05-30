// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.5.0;

interface IRandomizer {
    function returnValue() external view returns (bytes32);
}