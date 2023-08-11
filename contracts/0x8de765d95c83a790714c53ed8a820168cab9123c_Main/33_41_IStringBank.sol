// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.19;

interface IStringBank {
    function getString(uint256 index) external view returns (bytes memory value);
}