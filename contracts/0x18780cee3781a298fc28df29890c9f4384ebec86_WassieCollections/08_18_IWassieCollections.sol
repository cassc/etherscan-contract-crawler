// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

struct CreateCollectionParams {
    address minter;
    uint32 mintableSupply;
    uint32 ownerSupply;
    string name;
    string revealedURI;
    string unrevealedURI;
}

interface IWassieCollections {
    event Created(uint16 id);
    event Revealed(uint16 id);

    /// Details of each individual collection
    struct CollectionDetails {
        /// ID of the collection
        uint16 id;
        /// Address authorized to mint this collection
        address minter;
        /// Max supply available to mint
        uint32 totalSupply;
        /// Supply available to be minted
        uint32 mintableSupply;
        /// Supply available for the owner to min
        uint32 ownerSupply;
        /// Whether metadata is already revealed
        bool revealed;
        /// Collection name
        string name;
        /// Base URI for revealed metadata
        string revealedURI;
        /// URI for unrevealed metadata
        string unrevealedURI;
    }

    /// Returns details of a collection
    /// @param _id ID of the collection
    /// @return details of the collection
    function collectionDetails(uint16 _id) external view returns (CollectionDetails memory);

    /// Mints a new item
    /// @notice Must be called by the minter of the given collection
    /// @param _id ID of the collection
    /// @param _to Beneficiary
    /// @param _amount number of items to mint
    function mint(uint16 _id, address _to, uint256 _amount) external;

    /// Reveals a collection
    /// @notice Only the minter can reveal a collection
    ///
    /// @param _id collection ID
    function reveal(uint16 _id) external;
}