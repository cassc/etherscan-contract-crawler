//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IArtERC721 {
    function initialize(string memory name, string memory symbol) external;

    function mintItem(
        address owner,
        string memory tokenURI
    ) external returns (uint256);

    function burnItem(uint256 tokenId) external;

    function transferOwnership(address newOwner) external;
}