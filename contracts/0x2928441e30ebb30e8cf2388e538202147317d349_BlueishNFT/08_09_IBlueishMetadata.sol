// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IBlueishMetadata {
    function contractURI() external view returns (string memory);
    function tokenURI(uint256 id) external view returns (string memory);
}