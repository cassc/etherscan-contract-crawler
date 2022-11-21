// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IOwnableERC721 is IERC721Metadata {
    /**
     * @dev Returns the token collection owner.
     */
    function owner() external view returns (address);
    /**
     * @dev Returns the token collection name.
     */
    function name() external override view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external override view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external override view returns (string memory);
}