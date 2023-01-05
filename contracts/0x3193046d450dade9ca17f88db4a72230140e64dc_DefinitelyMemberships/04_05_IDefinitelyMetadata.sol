// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IDefinitelyMetadata {
    function tokenURI(uint256 id) external view returns (string memory);
}