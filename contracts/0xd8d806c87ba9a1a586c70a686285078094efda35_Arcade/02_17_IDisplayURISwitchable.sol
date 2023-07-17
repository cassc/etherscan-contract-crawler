// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IDisplayURISwitchable {
    function setDisplayMode(uint256 tokenId, bool mode) external;

    function tokenDisplayFullMode(uint256 tokenId) external view returns (bool);

    function originalTokenURI(uint256 tokenId) external view returns (string memory);

    function displayTokenURI(uint256 tokenId) external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}