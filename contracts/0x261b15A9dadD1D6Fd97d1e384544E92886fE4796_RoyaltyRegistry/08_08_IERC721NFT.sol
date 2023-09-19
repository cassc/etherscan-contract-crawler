// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721NFT {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function creatorOf(uint256 _tokenId) external view returns (address);

    function royalties(uint256 _tokenId) external view returns (uint256);

    function addItem(
        address creator,
        string memory _tokenURI,
        uint256 royalty
    ) external returns (uint256);
}