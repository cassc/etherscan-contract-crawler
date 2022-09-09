// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

interface IStrings {
    function getString(uint8 key) external view returns (string memory);
}