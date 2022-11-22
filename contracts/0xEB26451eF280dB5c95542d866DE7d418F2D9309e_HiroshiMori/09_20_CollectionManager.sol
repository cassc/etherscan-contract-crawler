// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13;

abstract contract CollectionManager {

    // TYPES -------------------------------------------------------------------

    /// @notice Represents a collection of pieces
    struct Collection {
        /// @notice Artist address
        address artist;

        /// @notice Payment receiver address
        address paymentReceiver;

        /// @notice Resolver contract address
        address uriResolver;

        /// @notice Base token URI
        string baseURI;

        /// @notice Price in ETH (wei)
        uint256 price;

        /// @notice Supply (0 for unlimited, >= 1 for fixed)
        uint128 supply;

        /// @notice Time after which the collection is open for public sale
        uint256 startTime;

        /// @notice Max quantity purchasable per transaction (0 for unlimited)
        uint256 perMintQuantity;

        /// @notice Royalty percentage (0 to 1), 18 decimals
        uint256 royaltyPercentage;

        /// @notice Inactive collections cannot be minted/bought by anyone
        bool active;

        /// @notice If false, then tokens are first minted to the artist's
        /// wallet then transferred to the recipient
        bool directMint;
    }

    /// @notice Contains internal state regarding a collection
    struct CollectionState {
        /// @notice The local ID of the next token in the collection.
        uint256 nextId; 
    }

    // STATE -------------------------------------------------------------------

    /// @notice All collections associated with this contract
    Collection[] public collections;

    /// @notice CollectionState for each Collection in collections
    CollectionState[] public collectionStates;

    // MODIFIERS ---------------------------------------------------------------

    /// @dev precondition that the collection must exist
    modifier collectionExists(uint256 collectionId) {
        require(collectionId < collections.length, "invalid collection");
        _;
    }

    /// @dev note: collectionId may be invalid in the case of a new collection
    modifier onlyCollectionAdmin(uint256 collectionId) virtual {
        // Note: These lines do not need to be covered by tests - solidity
        // coverage just fails to compile when a virtual modifier does not have
        // a body.
        require(false, "this is a virtual modifier");
        _;
    }

    // VIEWS -------------------------------------------------------------------

    /// @notice Get the global token id for a given collection and local id
    /// @param collectionId The id of the collection
    /// @param localId The local token id in the collection
    /// @return The global token id for the token in the collection
    function _getGlobalTokenId(
        uint256 collectionId,
        uint256 localId
    ) private pure returns (uint256) {
        return (collectionId << 128) + localId;
    }

    /// @notice Get the id of a collection for a given token id
    /// @param tokenId The id of the token
    /// @return The id of the collection
    function _getCollectionId(uint256 tokenId) internal pure returns (uint256) {
        return tokenId >> 128;
    }

    /// @notice Get the number of collections
    /// @return The number of collections
    function getCollectionCount() external view returns (uint256) {
        return collections.length;
    }

    /// @notice Get the min, next and max token ids for a given collection
    /// @param collectionId The id of the collection
    /// @return min The first token id for the collection
    /// @return next The next token id for the collection
    /// @return max The maximum token id for the collection
    function getCollectionTokenIdRange(
        uint256 collectionId
    ) public view collectionExists(collectionId) returns (
        uint256 min,
        uint256 next,
        uint256 max
    ) {
        if (collections[collectionId].supply == 0) {
            return (
                _getGlobalTokenId(collectionId, 0),
                _getGlobalTokenId(collectionId, collectionStates[collectionId].nextId),
                _getGlobalTokenId(collectionId, type(uint128).max)
            );
        }

        return (
            _getGlobalTokenId(collectionId, 0),
            _getGlobalTokenId(collectionId, collectionStates[collectionId].nextId),
            _getGlobalTokenId(collectionId, collections[collectionId].supply - 1)
        );
    }

    // EVENTS ------------------------------------------------------------------

    /// @notice Emitted when when a collection is created or updated
    /// @param who The account that updated the collection
    /// @param collectionId The id of the collection that was updated
    event CollectionUpdate(address who, uint256 collectionId);

    /// MUTATIONS (INTERNAL) ---------------------------------------------------

    /// @notice "Use" up the next token ids for a given collection
    /// @dev Precondition: The collection for `collectionId` must exist
    /// @param collectionId The id of the collection
    /// @param count The number of token ids to consume
    function _consumeTokenIds(
        uint256 collectionId,
        uint256 count
    ) internal returns (uint256) {
        require(
            collectionStates[collectionId].nextId + count <= (
                (collections[collectionId].supply > 0) ?
                (collections[collectionId].supply) :
                type(uint128).max
            ),
            "not enough supply"
        );
        uint256 firstTokenId = _getGlobalTokenId(
            collectionId,
            collectionStates[collectionId].nextId
        );
        collectionStates[collectionId].nextId += count;
        return firstTokenId;
    }

    /// MUTATIONS (PUBLIC) -----------------------------------------------------

    /// @notice Create a new collection
    /// @param collection The collection data
    function createCollection(
        Collection calldata collection
    ) public onlyCollectionAdmin(collections.length) {
        emit CollectionUpdate(msg.sender, collections.length);
        collections.push(collection);
        collectionStates.push(CollectionState(0));
    }

    /// @notice Update an existing collection
    /// @param collectionId The id of the collection to update
    /// @param collection The new collection data
    function updateCollection(
        uint256 collectionId,
        Collection calldata collection
    ) public collectionExists(collectionId) onlyCollectionAdmin(collectionId) {
        emit CollectionUpdate(msg.sender, collectionId);
        collections[collectionId] = collection;
    }

    /// @notice Update the paymentReceiver for an existing collection
    /// @param collectionId The id of the collection to update
    /// @param paymentReceiver The new value for paymentReceiver
    function updateCollectionPaymentReceiver(
        uint256 collectionId,
        address paymentReceiver
    ) public collectionExists(collectionId) onlyCollectionAdmin(collectionId) {
        emit CollectionUpdate(msg.sender, collectionId);
        collections[collectionId].paymentReceiver = paymentReceiver;
    }

    /// @notice Update the artist for an existing collection
    /// @param collectionId The id of the collection to update
    /// @param artist The new value for artist
    function updateCollectionArtist(
        uint256 collectionId,
        address artist
    ) public collectionExists(collectionId) onlyCollectionAdmin(collectionId) {
        emit CollectionUpdate(msg.sender, collectionId);
        collections[collectionId].artist = artist;
    }

    /// @notice Update the uriResolver for an existing collection
    /// @param collectionId The id of the collection to update
    /// @param uriResolver The new value for uriResolver
    function updateCollectionUriResolver(
        uint256 collectionId,
        address uriResolver
    ) public collectionExists(collectionId) onlyCollectionAdmin(collectionId) {
        emit CollectionUpdate(msg.sender, collectionId);
        collections[collectionId].uriResolver = uriResolver;
    }

    /// @notice Update the baseURI for an existing collection
    /// @param collectionId The id of the collection to update
    /// @param baseURI The new value for baseURI
    function updateCollectionBaseURI(
        uint256 collectionId,
        string calldata baseURI
    ) public collectionExists(collectionId) onlyCollectionAdmin(collectionId) {
        emit CollectionUpdate(msg.sender, collectionId);
        collections[collectionId].baseURI = baseURI;
    }

    /// @notice Update the price for an existing collection
    /// @param collectionId The id of the collection to update
    /// @param price The new value for price
    function updateCollectionPrice(
        uint256 collectionId,
        uint256 price
    ) public collectionExists(collectionId) onlyCollectionAdmin(collectionId) {
        emit CollectionUpdate(msg.sender, collectionId);
        collections[collectionId].price = price;
    }

    /// @notice Update the supply for an existing collection
    /// @param collectionId The id of the collection to update
    /// @param supply The new value for supply
    function updateCollectionSupply(
        uint256 collectionId,
        uint128 supply
    ) public collectionExists(collectionId) onlyCollectionAdmin(collectionId) {
        emit CollectionUpdate(msg.sender, collectionId);
        collections[collectionId].supply = supply;
    }

    /// @notice Update the startTime for an existing collection
    /// @param collectionId The id of the collection to update
    /// @param startTime The new value for startTime
    function updateCollectionStartTime(
        uint256 collectionId,
        uint256 startTime
    ) public collectionExists(collectionId) onlyCollectionAdmin(collectionId) {
        emit CollectionUpdate(msg.sender, collectionId);
        collections[collectionId].startTime = startTime;
    }

    /// @notice Update the perMintQuantity for an existing collection
    /// @param collectionId The id of the collection to update
    /// @param perMintQuantity The new value for perMintQuantity
    function updateCollectionPerMintQuantity(
        uint256 collectionId,
        uint256 perMintQuantity
    ) public collectionExists(collectionId) onlyCollectionAdmin(collectionId) {
        emit CollectionUpdate(msg.sender, collectionId);
        collections[collectionId].perMintQuantity = perMintQuantity;
    }

    /// @notice Update the royaltyPercentage for an existing collection
    /// @param collectionId The id of the collection to update
    /// @param royaltyPercentage The new value for royaltyPercentage
    function updateCollectionRoyaltyPercentage(
        uint256 collectionId,
        uint256 royaltyPercentage
    ) public collectionExists(collectionId) onlyCollectionAdmin(collectionId) {
        emit CollectionUpdate(msg.sender, collectionId);
        collections[collectionId].royaltyPercentage = royaltyPercentage;
    }

    /// @notice Update the active value for an existing collection
    /// @param collectionId The id of the collection to update
    /// @param active The new value for active
    function updateCollectionActive(
        uint256 collectionId,
        bool active
    ) public collectionExists(collectionId) onlyCollectionAdmin(collectionId) {
        emit CollectionUpdate(msg.sender, collectionId);
        collections[collectionId].active = active;
    }

    /// @notice Update the directMint value for an existing collection
    /// @param collectionId The id of the collection to update
    /// @param directMint The new value for directMint
    function updateCollectionDirectMint(
        uint256 collectionId,
        bool directMint
    ) public collectionExists(collectionId) onlyCollectionAdmin(collectionId) {
        emit CollectionUpdate(msg.sender, collectionId);
        collections[collectionId].directMint = directMint;
    }
}