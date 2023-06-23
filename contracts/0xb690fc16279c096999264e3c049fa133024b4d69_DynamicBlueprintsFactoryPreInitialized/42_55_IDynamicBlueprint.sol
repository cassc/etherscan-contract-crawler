//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../storefront/interfaces/IStorefront.sol";
import "../../common/IRoyalty.sol";

/**
 * @notice Async Art Dynamic Blueprint NFT contract interface
 * @author Ohimire Labs
 */
interface IDynamicBlueprint {
    /**
     * @notice Blueprint
     * @param capacity Number of NFTs in Blueprint
     * @param mintedCount Number of Blueprint NFTs minted so far
     * @param erc721TokenIndex First token ID of the next Blueprint to be prepared
     * @param tokenUriLocked If the token metadata isn't updatable
     * @param baseTokenUri Base URI for token, resultant uri for each token is base uri concatenated with token id
     * @param metadataUriLocked If the metadata uri is frozen (cannot be modified)
     * @param blueprintMetadata A URI to web2 metadata for this entire blueprint
     * @param prepared If the blueprint is prepared
     * @param isSouldbound If the blueprint editions are soulbound tokens
     */
    struct Blueprint {
        uint64 capacity;
        uint64 mintedCount;
        uint64 erc721TokenIndex;
        bool tokenUriLocked;
        string baseTokenUri;
        bool metadataUriLocked;
        string blueprintMetadata;
        bool prepared;
        bool isSoulbound;
    }

    /**
     * @notice Data passed in when preparing blueprint
     * @param _capacity Number of NFTs in Blueprint
     * @param _blueprintMetaData Blueprint metadata uri
     * @param _baseTokenUri Base URI for token, resultant uri for each token is base uri concatenated with token id
     * @param _isSoulbound If the Blueprint is soulbound
     */
    struct BlueprintPreparationConfig {
        uint64 _capacity;
        string _blueprintMetaData;
        string _baseTokenUri;
        bool _isSoulbound;
    }

    /**
     * @notice Creator config of contract
     * @param name Contract name
     * @param symbol Contract symbol
     * @param contractURI Contract-level metadata
     * @param artist Blueprint artist
     */
    struct DynamicBlueprintsInput {
        string name;
        string symbol;
        string contractURI;
        address artist;
    }

    /**
     * @notice Per-token optional struct tracking token-specific URIs which override baseTokenURI
     * @param tokenURI URI of token metadata
     * @param isFrozen whether or not the URI is frozen
     */
    struct DynamicBlueprintTokenURI {
        string tokenURI;
        bool isFrozen;
    }

    /**
     * @notice Prepare the blueprint and create a sale for it on a storefront 
               (this is the core operation to set up a blueprint)
     * @param config Object containing values required to prepare blueprint
     * @param sale Blueprint sale
     * @param storefront Storefront to create sale on
     */
    function prepareBlueprintAndCreateSale(
        BlueprintPreparationConfig calldata config,
        IStorefront.Sale memory sale,
        address storefront
    ) external;

    /**
     * @notice Mint a number of editions of this blueprint
     * @param purchaseQuantity How many blueprint editions to mint
     * @param nftRecipient Recipient of minted blueprints
     */
    function mintBlueprints(uint32 purchaseQuantity, address nftRecipient) external;

    /**
     * @notice Update the blueprint's artist
     * @param _newArtist New artist
     */
    function updateBlueprintArtist(address _newArtist) external;

    /**
     * @notice Update a blueprint's capacity
     * @param _newCapacity New capacity
     * @param _newLatestErc721TokenIndex Newly adjusted last ERC721 token id
     */
    function updateBlueprintCapacity(uint64 _newCapacity, uint64 _newLatestErc721TokenIndex) external;

    /**
     * @notice Update a specific token's URI
     * @param _tokenId The ID of the token
     * @param _newURI The new overriding token URI for the token
     */
    function updatePerTokenURI(uint256 _tokenId, string calldata _newURI) external;

    /**
     * @notice Lock the metadata URI of a specific token
     * @param _tokenId The ID of the token
     */
    function lockPerTokenURI(uint256 _tokenId) external;

    /**
     * @notice Update blueprint's token uri
     * @param newBaseTokenUri New base token uri to update to
     */
    function updateBlueprintTokenUri(string calldata newBaseTokenUri) external;

    /**
     * @notice Lock blueprint's token uri (from changing)
     */
    function lockBlueprintTokenUri() external;

    /**
     * @notice Update blueprint's metadata URI
     * @param newMetadataUri New metadata URI
     */
    function updateBlueprintMetadataUri(string calldata newMetadataUri) external;

    /**
     * @notice Lock blueprint's metadata uri (from changing)
     */
    function lockBlueprintMetadataUri() external;

    /**
     * @notice Update royalty config
     * @param newRoyalty New royalty parameters
     */
    function updateRoyalty(IRoyalty.Royalty calldata newRoyalty) external;

    /**
     * @notice Update contract-wide minter address, and MINTER_ROLE role ownership
     * @param newMinterAddress New minter address
     */
    function updateMinterAddress(address newMinterAddress) external;

    /**
     * @notice Update contract-wide platform address, and DEFAULT_ADMIN_ROLE role ownership
     * @param _platform New platform
     */
    function updatePlatformAddress(address _platform) external;

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. 
               Also register this contract with that registry.
     * @param newRegistry New Operator filter registry to check against
     * @param coriCuratedSubscriptionAddress CORI Curated subscription address 
     *        -> updates Async's operator filter list in coordination with OS
     */
    function updateOperatorFilterAndRegister(address newRegistry, address coriCuratedSubscriptionAddress) external;

    /**
     * @notice Return the blueprint's metadata URI
     */
    function metadataURI() external view returns (string memory);

    /**
     * @notice Get secondary fee recipients of a token
     * @param // tokenId Token ID
     */
    function getFeeRecipients(uint256 /* tokenId */) external view returns (address[] memory);

    /**
     * @notice Get secondary fee bps (allocations) of a token
     * @param // tokenId Token ID
     */
    function getFeeBps(uint256 /* tokenId */) external view returns (uint32[] memory);
}