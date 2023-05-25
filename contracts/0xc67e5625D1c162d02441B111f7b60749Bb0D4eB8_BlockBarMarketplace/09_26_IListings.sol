// SPDX-License-Identifier:  AGPL-3.0-or-later
pragma solidity 0.8.18;

struct Listing {
    uint256 listingId;
    uint256[] tokenIds;
    uint256 amount;
    bytes32 currency;
    uint256 validUntil;
    address owner;
    address payoutAddress;
    address buyerAddress;
    bool forSpecificBuyer;
    bool isListed;
}

/**
 * @title IListings
 * @author aarora
 * @notice IListings contains all external function interfaces and events
 */
interface IListings {
    /**
    * @dev Emit an event whenever a listing is created
    *
    * @param listingId The ID of the listing
    * @param owner     The owner of the listing
    **/
    event ListingCreated(uint256 indexed listingId, address indexed owner);

    /**
    * @dev Emit an event whenever a listing is updated
    *
    * @param listingId The ID of the listing
    * @param owner     The owner of the listing
    **/
    event ListingUpdated(uint256 indexed listingId, address indexed owner, uint256 indexed validUntil);

    /**
    * @dev Emit an event whenever a listing is disabled
    *
    * @param listingId The ID of the listing
    **/
    event ListingDisabled(uint256 indexed listingId);

    /**
     * @notice Get information about a specific listing
     *
     * @param  listingId ID of the listing to retrieve information
     *
     * @return listing A struct of Listing containing information of the listing
     */
    function getListing(uint256 listingId) external view returns (Listing memory listing);

    /**
     * @notice Create a listing for anyone to purchase. Listing will expire after `validUntil`.
     *         Support currencies for listing: USD, ETH.
     *         If the listing is in USD, it must be greater that 0.01 USD or 1 cent.
     *         Caller can pass a different wallet to payoutAddress to receive funds from the sale.
     *         The caller/owner of the token IDs must provide this contract access to manage the token IDs on
     *         BlockBar BTL contract by calling setApprovalForAll with operator as the address of this contract.
     *
     * @param tokenIds      A list of BlockBar BTL token IDs to be included in the listing. Must be owned by the caller.
     * @param amount        Amount in USD or ETH for the sale of all BTL tokens passed into tokenIds.
     * @param currency      Currency in bytes32 of the listing. Supported options include USD and ETH.
     * @param payoutAddress An Ethereum wallet address where funds will be sent from this listings' sale.
     * @param validUntil    An expiration date in UNIX Timestamp (seconds).
     *
     * @return listingId    ID of the newly created listing
     */
    function createPublicListing(
        uint256[] calldata tokenIds,
        uint256 amount,
        bytes32 currency,
        address payoutAddress,
        uint256 validUntil
    ) external returns(uint256 listingId);

    /**
     * @notice Create a listing for a specific buyer. Listing will expire after `validUntil`.
     *         Support currencies for listing: USD, ETH.
     *         If the listing is in USD, it must be greater that 0.01 USD or 1 cent.
     *         Caller can pass a different wallet to payoutAddress to receive funds from the sale.
     *         The caller/owner of the token IDs must provide this contract access to manage the token IDs on
     *         BlockBar BTL contract by calling setApprovalForAll with operator as the address of this contract.
     *
     * @param tokenIds      A list of BlockBar BTL token IDs to be included in the listing. Must be owned by the caller.
     * @param amount        Amount in USD or ETH for the sale of all BTL tokens passed into tokenIds.
     * @param currency      Currency of the listing. Supported options include USD and ETH.
     * @param payoutAddress An Ethereum wallet address where funds will be sent from this listings' sale.
     * @param validUntil    An expiration date in UNIX Timestamp (seconds).
     * @param buyerAddress  An Ethereum wallet address for whom this listing is valid. No other address will be able
     *                      to purchase this listing.
     *
     * @return listingId    ID of the newly created listing
     */
    function createPrivateListing(
        uint256[] calldata tokenIds,
        uint256 amount,
        bytes32 currency,
        address payoutAddress,
        uint256 validUntil,
        address buyerAddress
    ) external returns(uint256 listingId);

    /**
     * @notice Return the count of total listings ever created. Returns 0 if there are no listings.
     *         Does not exclude inactive/sold listings
     *
     * @return count    Count of listings
     */
    function listingsCount() external view returns(uint256 count);

    /**
     * @notice Disable a listing that is currently active. Only the owner of the listing can trigger it.
     *         Once disable, no one will be able to purchase this listing.
     *
     * @param listingId ID of the listing to be disabled.
     */
    function disableListing(uint256 listingId) external;

    /**
    * @notice Update listing expiration date. Only owner of the listing can extend the listing.
    *         Listing must be valid - cannot be un-listed. The new expiration date must be in the future.
    *
    * @param listingId ID of the listing to update
    * @param validUntil New expiration date in UNIX timestamp (seconds)
    *
    * @return updatedListing Update Listing struct
    */
    function updateListingExpiration(
        uint256 listingId,
        uint256 validUntil
    ) external returns(Listing memory updatedListing);
}