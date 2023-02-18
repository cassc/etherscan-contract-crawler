// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IMintByUri {
    function mint(
        address to,
        string memory uri,
        bytes memory data
    ) external;
}

interface IMintEditions {
    function mint(
        address to,
        uint256 tokenId,
        string calldata uri,
        uint256 quantity,
        bytes calldata data
    ) external;

    function mint(
        address to,
        uint256 tokenId,
        uint256 quantity,
        bytes calldata data
    ) external;

    function setUri(uint256 tokenId, string memory newUri) external;
}

interface ICollectionSupplyDeprecated {
    function maxSupply() external view returns (uint256);

    function setSupply(uint256 _maxSupply) external;
}