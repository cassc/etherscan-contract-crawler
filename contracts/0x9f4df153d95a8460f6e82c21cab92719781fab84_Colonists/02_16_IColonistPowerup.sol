// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IColonistPowerup {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     */
    function burn(uint256 tokenId) external;

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external view returns (address);
}