// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// use the Royalty Registry's IManifold interface for token royalties
import "./IManifold.sol";
import "./IERC721MultiCollection.sol";

/// @title Interface for Core ERC721 contract for multiple collections
/// @author Particle Collection - valdi.eth
/// @notice Manages all collections tokens
/// @dev Exposes all public functions and events needed by the Particle Collection's smart contracts
/// @dev Adheres to the ERC721 standard, ERC721MultiCollection extension and Manifold for secondary royalties
interface IPRTCLCollections721V1 is IERC721, IERC721MultiCollection, IManifold {
    /// @notice Collection ID `_collectionId` updated
    event CollectionDataUpdated(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` size updated
    event CollectionSizeUpdated(uint256 indexed _collectionId, uint256 _size);

    /// @notice Collection ID `_collectionId` sold through governance
    event CollectionSold(uint256 indexed _collectionId, address _buyer);

    /// @notice Collection ID `_collectionId` active
    event CollectionActive(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` not active
    event CollectionInactive(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` royalties updated
    event CollectionRoyaltiesUpdated(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` primary split updated
    event CollectionPrimarySplitUpdated(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` fully minted
    event CollectionFullyMinted(uint256 indexed _collectionId);

    /// @notice Updated base uri
    event BaseURIUpdated(string _baseURI);

    /// @notice Royalties addresses updated
    event RoyaltiesAddressesUpdated(address _FJMAddress, address _DAOAddress);

    /// @notice Randomizer contract updated
    event RandomizerUpdated(address _randomizer);

    /// @notice Collection seeds set
    event CollectionSeedsSet(uint256 _collectionId, uint24 _seed1, uint24 _seed2);

    ///
    /// Collection data
    ///

    /// @notice Artist address for collection ID `_collectionId`
    function collectionIdToArtistAddress(uint256 _collectionId) external view returns (address payable);

    /// @notice Get the primary revenue splits for a given collection ID and sale price
    /// @dev Used by minter contract
    function getPrimaryRevenueSplits(uint256 _collectionId, uint256 _price) external view
        returns (
            uint256 FJMRevenue_,
            address payable FJMAddress_,
            uint256 DAORevenue_,
            address payable DAOAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_
        );

    /// @notice Main collection data
    function collectionData(uint256 _collectionId) external view returns (
        uint256 nParticles,
        uint256 maxParticles,
        bool active,
        string memory collectionName,
        bool sold,
        uint24[] memory seeds,
        uint256 setSeedsAfterBlock
    );

    /// @notice Check if the collection can be sold
    /// @dev Used by governance contract
    function collectionCanBeSold(uint256 _collectionId) external view returns (bool);

    /// @notice Get the proceeds for a given collection ID, sale price, sale comission and number of tokens
    /// @dev Used by governance contract
    function proceeds(uint256 _collectionId, uint256 _salePrice, uint256 _commission, uint256 _tokens) external view returns (uint256);

    /// @notice Get coordinates within an artwork for a given token ID
    function getCoordinate(uint256 _tokenId) external view returns (uint256);

    ///
    /// Collection interactions
    ///

    /// @notice Mark a collection as sold
    /// @dev Only callable by the governance role
    function markCollectionSold(uint256 _collectionId, address _buyer) external;
    
    /// @notice Mint a new token.
    /// Used by minter contract and BE infrastructure when handling fiat payments
    /// @dev Only callable by the minter role
    function mint(address _to, uint256 _collectionId, uint24 _amount) external returns (uint256 tokenId);

    /// @notice Burn tokensToRedeem tokens owned by `owner` in collection `_collectionId`
    /// Used when redeeming tokens for sale proceeds
    /// @dev Only callable by the governance role
    function burn(address owner, uint256 collectionId, uint256 tokensToRedeem) external returns (uint256 tokensBurnt);

    /// @notice Set the random prime seeds for a given collection ID, used to calculate token coordinates
    /// @dev Only callable by the Randomizer contract
    function setCollectionSeeds(uint256 _collectionId, uint24[2] calldata _seeds) external;
}