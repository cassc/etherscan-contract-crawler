//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../storefront/interfaces/IStorefront.sol";
import "../../common/IRoyalty.sol";

/**
 * @notice Interface for Dynamic Blueprint Expansion contract
 * @author Ohimire Labs
 */
interface IExpansion is IRoyalty {
    /**
     * @notice Atomic purchaseable unit
     * @param itemSizes The number of tokens in each item in pack
     * @param startTokenId Start token id of the pack
     * @param capacity The number of packs that can be purchased
     * @param mintedCount The number of packs that have been purchased
     * @param baseUri The base uri containing metadata for tokens in the pack
     * @param tokenUriLocked Denotes if changes to the baseUri is locked
     */
    struct Pack {
        uint256[] itemSizes;
        uint256 startTokenId;
        uint256 capacity;
        uint256 mintedCount;
        string baseUri;
        bool tokenUriLocked;
    }

    /**
     * @notice Mint the same combination of token ids in a pack. Each token is a token in one item in the pack
     * @param packId ID of pack
     * @param tokenIds Combination of tokens being minted
     * @param numTimes How many of each token in the combination are minted
     * @param nftRecipient Recipient of minted tokens
     */
    function mintSameCombination(
        uint256 packId,
        uint256[] calldata tokenIds,
        uint32 numTimes,
        address nftRecipient
    ) external;

    /**
     * @notice Mint different combinations of token ids in a pack.
     * @dev Could flatten 2d array to fully optimize for gas
     *      but logic would be too misaligned from natural function / readability
     * @param tokenIdCombinations The unique, different token id combinations being minted in pack
     * @param numCombinationPurchases How many times each unique combination is minted
     * @param nftRecipient Recipient of minted NFTs
     */
    function mintDifferentCombination(
        uint256 packId,
        uint256[][] calldata tokenIdCombinations,
        uint32[] calldata numCombinationPurchases,
        address nftRecipient
    ) external;

    /**
     * @notice Create a pack
     * @param pack Pack being created
     */
    function preparePack(Pack calldata pack) external payable;

    /**
     * @notice Create a pack and sale for the pack on a storefront
     * @param pack Pack being created
     * @param sale Sale being created
     * @param storefront Storefront that sale resides on
     */
    function preparePackAndSale(Pack calldata pack, IStorefront.Sale calldata sale, address storefront) external;

    /**
     * @notice Set a pack's base uri
     * @param packId ID of pack who's base uri is being set
     * @param newBaseUri New base uri for pack
     */
    function setBaseUri(uint256 packId, string calldata newBaseUri) external;

    /**
     * @notice Lock a pack's base uri
     * @param packId ID of pack who's base uri is being locked
     */
    function lockBaseUri(uint256 packId) external;

    /**
     * @notice Update expansion contract's artist
     * @param newArtist New artist to update to
     */
    function updateArtist(address newArtist) external;

    /**
     * @notice Update expansion contract's platform address and manage ownership of DEFAULT_ADMIN_ROLE accordingly
     * @param _platform New platform
     */
    function updatePlatformAddress(address _platform) external;

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against.
               Also register this contract with that registry.
     * @param newRegistry New Operator filter registry to check against
     * @param newSubscription Filter-list to subscribe to 
     */
    function updateOperatorFilterAndRegister(address newRegistry, address newSubscription) external;

    /**
     * @notice Enable artist (although not restricted) to top-up funds which are used to cover AsyncArt gas fees for preparePack calls
     */
    function topUpGasFunds() external payable;

    /**
     * @notice Get a pack by its ID
     * @param packId ID of pack to get
     */
    function getPack(uint256 packId) external view returns (Pack memory);

    /**
     * @notice Get packs by their IDs
     * @param packIds IDs of packs to get
     */
    function getPacks(uint256[] calldata packIds) external view returns (Pack[] memory);

    /**
     * @notice Get the pack a token belongs to
     * @param tokenId ID of token who's pack is retrieved
     */
    function getTokenPack(uint256 tokenId) external view returns (Pack memory);

    /**
     * @notice Return true if account is the platform account
     * @param account Account being checked
     */
    function isPlatform(address account) external view returns (bool);

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