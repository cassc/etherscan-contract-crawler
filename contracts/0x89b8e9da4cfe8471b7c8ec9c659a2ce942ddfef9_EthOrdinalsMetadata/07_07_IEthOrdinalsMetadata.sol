// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IEthOrdinalsMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function baseURI() external view returns (string memory);
}