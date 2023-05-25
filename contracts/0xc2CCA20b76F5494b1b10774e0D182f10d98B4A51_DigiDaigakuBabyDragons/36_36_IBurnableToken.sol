// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

pragma solidity ^0.8.0;

/**
 * @title Interface for a Burnable ERC721 Token
 */
interface IBurnableToken is IERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external;
}