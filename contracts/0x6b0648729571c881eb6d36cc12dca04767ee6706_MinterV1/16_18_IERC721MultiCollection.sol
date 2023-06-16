// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title ERC721Multi collection interface
/// @author Particle Collection - valdi.eth
/// @notice Adds public facing and multi collection balanceOf and collectionId to tokenId functions
/// @dev This implements an optional extension of {ERC721} that adds
/// support for multiple collections and enumerability of all the
/// token ids in the contract as well as all token ids owned by each account per collection.
interface IERC721MultiCollection is IERC721 {
    /// @notice Collection ID `_collectionId` added
    event CollectionAdded(uint256 indexed collectionId);

    /// @notice New collections forbidden
    event NewCollectionsForbidden();

    // @dev Determine if a collection exists.
    function collectionExists(uint256 collectionId) external view returns (bool);

    /// @notice Balance for `owner` in `collectionId`
    function balanceOf(address owner, uint256 collectionId) external view returns (uint256);

    /// @notice Get the collection ID for a given token ID
    function tokenIdToCollectionId(uint256 tokenId) external view returns (uint256 collectionId);

    /// @notice returns the total number of collections.
    function numberOfCollections() external view returns (uint256);

    /// @dev Returns the total amount of tokens stored by the contract for `collectionId`.
    function tokenTotalSupply(uint256 collectionId) external view returns (uint256);

    /// @dev Returns a token ID owned by `owner` at a given `index` of its token list on `collectionId`.
    /// Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
    function tokenOfOwnerByIndex(address owner, uint256 index, uint256 collectionId) external view returns (uint256);

    /// @notice returns maximum size for collections.
    function MAX_COLLECTION_SIZE() external view returns (uint256);
}