// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IAdam721 is IERC721Metadata {
    event ChangeTokenURI(address indexed operator, uint256 indexed tokenId, string newValue);
    function burn(uint256 tokenId) external;
    function gracefulOwnerOf(uint256 tokenId) external view returns (address);
    function safeMint(address to, uint256 tokenId, bytes calldata data) external;
    function setTokenURI(uint256 tokenId, string calldata newValue) external;
}