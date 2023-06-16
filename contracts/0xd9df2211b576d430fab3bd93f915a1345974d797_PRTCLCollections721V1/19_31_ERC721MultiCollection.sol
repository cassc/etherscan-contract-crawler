// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IERC721MultiCollection.sol";

/// @title ERC721Multi collection extension implementation
/// @author Particle Collection - valdi.eth
/// See {IERC721MultiCollection}.
/// @dev Based on OpenZeppelin's ERC721Enumerable.sol, extending it to allow for multiple collections.
abstract contract ERC721MultiCollection is ERC721, IERC721MultiCollection {
    uint256 public immutable MAX_COLLECTION_SIZE;

    // Mapping owner address to token count per collection
    // owner => collection id => balance
    mapping(address =>  mapping(uint256 => uint256)) private _collectionBalances;
    // Mapping from owner to list of owned token IDs per collection
    // owner => token index => token id
    mapping(address => mapping(uint256 => uint256)) private _collectionOwnedTokens;
    // Mapping from token ID to index of the owner tokens list per collection
    // owner => tokenId => index
    mapping(address => mapping(uint256 => uint256)) private _collectionOwnedTokensIndex;
    // Mapping from collection id to number of tokens on that collection
    mapping(uint256 => uint256) private _tokensPerCollection;

    /// bool indicating if adding new collections is forbidden;
    /// default behavior is to allow new collections
    bool private _newCollectionsForbidden;

    /// next collection ID to be created
    uint256 private _nextCollectionId;

    modifier onlyValidCollectionId(uint256 _collectionId) {
        require(
            _collectionId < _nextCollectionId,
            "Collection ID does not exist"
        );
        _;
    }

    constructor(uint256 maxCollectionSize) {
        MAX_COLLECTION_SIZE = maxCollectionSize;
    }

    /**  
    * @dev External function to determine if a collection exists.
    */
    function collectionExists(uint256 collectionId) external view override returns (bool) {
        return collectionId < _nextCollectionId;
    }

    /**  
    * @dev Determines if new collections can be added to this contract.
    */
    function _newCollectionsAllowed() internal view returns (bool) {
        return !_newCollectionsForbidden;
    }

    /**
     * @dev Determines if a collection size is valid.
     */
    function _validCollectionSize(uint256 collectionSize) internal view returns (bool) {
        return collectionSize > 0 && collectionSize <= MAX_COLLECTION_SIZE;
    }

    /**  
    * @dev Adds a new collection and returns the collection ID.
    */
    function _addCollection(uint256 collectionSize) internal returns (uint256){
        require(!_newCollectionsForbidden, "New collections forbidden");
        require(_validCollectionSize(collectionSize), "Number of particles must be > 0 && <= MAX_COLLECTION_SIZE");

        uint256 collectionId = _nextCollectionId;
        
        _nextCollectionId++;

        emit CollectionAdded(collectionId);
        return collectionId;
    }

    /**
     * @notice returns the total number of collections.
     */
    function numberOfCollections() public view returns (uint256) {
        return _nextCollectionId;
    }

    /**
     * @notice Balance for `owner` in `collectionId`
     */
    function balanceOf(address owner, uint256 collectionId) public view returns (uint256) {
        require(owner != address(0), "ERC721MultiCollection: address zero is not a valid owner");
        return _collectionBalances[owner][collectionId];
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract for `collectionId`.
     */
    function tokenTotalSupply(uint256 collectionId) external view returns (uint256) {
        return _tokensPerCollection[collectionId];
    }

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list on `collectionId`.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index, uint256 collectionId) external view returns (uint256) {
        require(index < balanceOf(owner, collectionId), "ERC721MultiCollection: owner index out of bounds");
        return _collectionOwnedTokens[owner][index];
    }

    /**
     * @notice Forever forbids new collections from being added to this contract.
     */
    function _forbidNewCollections()
        internal
    {
        require(!_newCollectionsForbidden, "Already forbidden");
        _newCollectionsForbidden = true;

        emit NewCollectionsForbidden();
    }

    /**
     * @notice Get the collection ID for a given token ID
     */
    function tokenIdToCollectionId(uint256 _tokenId) public view returns (uint256 collectionId) {
        return _tokenId / MAX_COLLECTION_SIZE;
    }

    /**
     * @notice Burns tokensToBurn tokens in a collection for user `owner`.
     *
     * @dev does not check for approval or ownership.
     * Checking is left to the extended contract if needed according to it's own logic.
     */
    function _burn(address owner, uint256 collectionId, uint256 tokensToBurn) internal returns (uint256 tokensBurnt) {
        uint256 balance = _collectionBalances[owner][collectionId];

        require(balance >= tokensToBurn, "ERC721MultiCollection: burn amount exceeds balance");

        for (uint256 i = 0; i < tokensToBurn;) {
            uint256 tokenId = _collectionOwnedTokens[owner][balance - 1 - i]; // Burn token at index balance - 1 - i, preventing swapping on each burn
            _burn(tokenId);

            unchecked { i++; }
        }

        return tokensToBurn;
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerCollectionEnumeration(address to, uint256 tokenId, uint256 collectionId) private {
        uint256 length = _collectionBalances[to][collectionId];
        _collectionOwnedTokens[to][length] = tokenId;
        _collectionOwnedTokensIndex[to][tokenId] = length;

        _collectionBalances[to][collectionId] += 1;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_collectionOwnedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _collectionOwnedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerCollectionEnumeration(address from, uint256 tokenId, uint256 collectionId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _collectionBalances[from][collectionId] - 1;
        uint256 tokenIndex = _collectionOwnedTokensIndex[from][tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _collectionOwnedTokens[from][lastTokenIndex];

            _collectionOwnedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _collectionOwnedTokensIndex[from][lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _collectionOwnedTokensIndex[from][tokenId];
        delete _collectionOwnedTokens[from][lastTokenIndex];

        _collectionBalances[from][collectionId] -= 1;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        uint256 collectionId = tokenIdToCollectionId(tokenId);

        if (from != address(0)) {
            _removeTokenFromOwnerCollectionEnumeration(from, tokenId, collectionId);
        } else {
            _tokensPerCollection[collectionId] += 1;
        }
        if (to != address(0)) {
            _addTokenToOwnerCollectionEnumeration(to, tokenId, collectionId);
        } else {
            _tokensPerCollection[collectionId] -= 1;
        }
    }
}