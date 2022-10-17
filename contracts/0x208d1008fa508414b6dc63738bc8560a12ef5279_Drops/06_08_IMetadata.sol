// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IMetadata {
    function uri(uint256 id) external view returns (string memory);
}