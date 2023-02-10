// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBlockalizer is IERC721 {
    function currentTokenId() external returns (uint256 tokenId);

    function incrementTokenId() external;

    function setTokenURI(uint256 tokenId, string memory _uri) external;

    function safeMint(address to, uint256 tokenId) external;
}