// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IMetadataGeneration {
    function render(uint256 _tokenId) external view returns (string memory);
}