// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IActivityERC721 {
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) external;

    function safeMint(address to) external returns (uint256 tokenId);

    function setURI(string memory newuri) external;

    function setName(string memory name) external;

    function setSymbol(string memory symbol) external;

    function setFactory(address factory) external;
}