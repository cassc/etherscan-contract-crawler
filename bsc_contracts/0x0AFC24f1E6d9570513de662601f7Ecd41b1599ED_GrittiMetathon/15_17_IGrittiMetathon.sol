// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title The interface for a Gritti Metathon Event
interface IGrittiMetathon is IERC721Enumerable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /// @notice The contract that deployed the pool, which must adhere to the IGrittiMetathonFactory interface
    /// @return The contract address
    function factory() external view returns (address);

    /**
     * @dev Returns the max amount of tokens stored by the contract.
     */
    function maxSupply() external view returns (uint256);

    /**
     * @dev Returns the token collection event slug.
     */
    function eventSlug() external view returns (string memory);

    /**
     * @dev Returns the token collection event name.
     */
    function eventName() external view returns (string memory);

    /**
     * @dev Returns the token collection MerkleRoot Hash.
     */
    function rootHash() external view returns (string memory);

    /**
     * @dev Base URI for computing {tokenURI}. each token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function baseURI() external view returns (string memory);

    /**
     * @dev Returns the minter of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function minterOf(uint256 tokenId) external view returns (address);

    /**
     * @dev Returns the number of tokens in ``minter``'s account.
     */
    function countOfMinter(address minter) external view returns (uint256 count);

    /**
     * @dev Returns a token ID mint to `minter` at a given `index` of its token list.
     * Use along with {countOfMinter} to enumerate all of ``minter``'s tokens.
     */
    function tokenOfMinterByIndex(address minter, uint256 index) external view returns (uint256);
}