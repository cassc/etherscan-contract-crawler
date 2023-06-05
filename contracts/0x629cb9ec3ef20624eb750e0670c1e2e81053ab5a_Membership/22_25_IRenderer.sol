// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IRenderer {
    event UpdatedBaseURI(string uri);
    event UpdatedCustomURI(address indexed collection, string uri);

    function baseURI() external returns (string memory);
    function updateBaseURI(string memory _baseURI) external;
    function tokenURI(uint256 tokenId) external view returns (string memory);
}