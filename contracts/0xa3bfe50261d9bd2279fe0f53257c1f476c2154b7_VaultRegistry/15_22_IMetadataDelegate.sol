// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IMetadataDelegate {
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function contractURI() external view returns (string memory);
}