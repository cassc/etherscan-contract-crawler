// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC721UniqueBound {
    error MintZeroQuantity();
    error MintToZeroAddress();
    error MintToExistingOwnerAddress();
    error BalanceQueryForZeroAddress();
    error URIQueryForNonexistentToken();

    function totalSupply() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function tokenOf(address owner) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}