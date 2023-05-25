// SPDX-License-Identifier:  AGPL-3.0-or-later
pragma solidity 0.8.18;

import {Utils} from "Utils.sol";
import {IListings, Listing} from "IListings.sol";
import {ExtendedAccessControl} from "ExtendedAccessControl.sol";
import {Counters} from "Counters.sol";
import {ERC721} from "ERC721.sol";


/**
 * @title Listings
 * @author aarora
 * @custom:coauthor hgaron
 * @notice Listings holds information related to all potential sales of BlockBar BTL tokens as listing.
 *         Each listing contains information about the seller, token IDs being sold, amount, currency,
 *         expiration date, and whether it is a public listing or for a specific buyer.
 *         Listings allows users to create, read, update and disable their own listings.
 */
contract Listings is IListings, Utils, ExtendedAccessControl {
    // Use Counters to track Listing IDs
	using Counters for Counters.Counter;
    Counters.Counter private _listingIds;

    // BlockBarBTL contract instantiated in the constructor
    ERC721 internal _blockBarBtlContract;

    // Store all listings
    mapping(uint256 => Listing) private _listings;

    /**
    * @notice Instantiation BlockBarBTL contract via generic ERC721 and forward the price feed address to parent
    *         parent contract. Additionally, set the owner of the contract as the caller.
    *
    * @param  blockBarBtl Address of the BlockBarBTL ERC721 contract
    * @param  priceFeed   Chainlink Price Feed for ETH/USD pair
    */
    constructor(address blockBarBtl, address priceFeed) Utils(priceFeed){
        require(blockBarBtl != address(0), "BlockBarBTL address cannot be 0");
        _blockBarBtlContract = ERC721(blockBarBtl);
    }

    /**
     * @notice Get information about a specific listing
     *
     * @param  listingId ID of the listing to retrieve information
     *
     * @return listing A struct of Listing containing information of the listing
     */
    function getListing(uint256 listingId) external view returns (Listing memory listing) {
        return _getListing(listingId);
    }

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
     * @param currency      Currency of the listing. Supported options include USD and ETH.
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
    ) external nonReentrant whenNotPaused returns(uint256 listingId) {
        // Call internal _createListing function. Inject false for isSpecificBuyer and 0 address for payoutAddress
        return _createListing(tokenIds, amount, currency, payoutAddress, validUntil, false, address (0));
    }

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
    ) external nonReentrant whenNotPaused returns(uint256 listingId) {
        // Call internal _createListing function. Inject true for isSpecificBuyer
        return _createListing(tokenIds, amount, currency, payoutAddress, validUntil, true, buyerAddress);
    }

    /**
     * @notice Return the count of total listings ever created. Returns 0 if there are no listings.
     *         Does not exclude inactive/sold listings
     *
     * @return count    Count of listings
     */
    function listingsCount() external view returns(uint256 count) {
        // Returns 0 if there are no listings
        return _listingIds.current();
    }

    /**
     * @notice Disable a listing that is currently active. Only the owner of the listing can trigger it.
     *         Once disabled, no one will be able to purchase this listing.
     *x
     * @param listingId ID of the listing to be disabled.
     *
     */
    function disableListing(uint256 listingId) external nonReentrant whenNotPaused {
        // Retrieve the listing and validate owner before calling internal disable listing function
        require(_listings[listingId].owner == msg.sender, "Only owner can disable listing");
        _disableListing(listingId);
    }


    /**
    * @notice Update listing expiration date. Only owner of the listing can extend the listing.
    *         Listing must be valid - cannot be un-listed. The new expiration date must be in the future.
    *
    * @param listingId ID of the listing to update
    * @param validUntil New expiration date in UNIX timestamp (seconds)
    *
    * @return listing Update Listing struct
    */
    function updateListingExpiration(
        uint256 listingId,
        uint256 validUntil
    ) external nonReentrant returns(Listing memory listing) {
        return _updateListingExpiration(listingId, validUntil);
    }

    /**
     * @notice Internal function to create a listing.
     *         Listing may be created for a specific buyer by settings isSpecificBuyer to true and a non 0 address
     *         for buyerAddress.
     *         Listing will expire after `validUntil`.
     *         Support currencies for listing: USD, ETH.
     *         If the listing is in USD, it must be greater that 0.01 USD or 1 cent.
     *         Caller can pass a different wallet to payoutAddress to receive funds from the sale.
     *         The caller/owner of the token IDs must provide this contract access to manage the token IDs on
     *         BlockBar BTL contract by calling setApprovalForAll with operator as the address of this contract.
     *
     * @param tokenIds         A list of BlockBar BTL token IDs to be included in the listing.
     &                         Must be owned by the caller.
     * @param amount           Amount in USD or ETH for the sale of all BTL tokens passed into tokenIds.
     *                         USD amount must be padded with 1e18
     * @param currency         Currency of the listing. Supported options include USD and ETH.
     * @param payoutAddress    An Ethereum wallet address where funds will be sent from this listings' sale.
     * @param validUntil       An expiration date in UNIX Timestamp (seconds).
     * @param forSpecificBuyer Set to true if it is a private listing. BuyerAddress is required.
     * @param buyerAddress     Optional Ethereum wallet address for whom this listing is valid.
     *                         No other address will be able to purchase this listing.
     *                         Will be ignored if forSpecificBuyer is false.
     *
     * @return listingId    ID of the newly created listing
     */
    function _createListing(
        uint256[] calldata tokenIds,
        uint256 amount,
        bytes32 currency,
        address payoutAddress,
        uint256 validUntil,
        bool forSpecificBuyer,
        address buyerAddress
    ) internal returns(uint256) {
        // Initial checks for quick revert
        require(validUntil > block.timestamp + 1 days, "Listing cannot expire before tomorrow");
        require(amount > 0, "Amount must be greater than 0");
        require(currency == USD_CURRENCY || currency == ETH_CURRENCY, "invalid currency");
        require(payoutAddress != address(0), "Invalid payout address");
        require(tokenIds.length > 0, "Cannot create a listing without tokenIds");
        require(tokenIds.length <= 100, "Cannot create a listing more than 100 NFTs");

        // Listings in USD must be greater than 1 cent. USD amount must be padded with 1e18
        if(currency == USD_CURRENCY) {
            require(amount >= 1 * 1e16, "USD listing cannot be less than 1 cent or 1*1e16 Wei");
        }

        // Initial checks for private listings. Cannot be 0 address or self.
        if (forSpecificBuyer) {
            require(buyerAddress != address(0), "Invalid buyer address");
            require(buyerAddress != msg.sender, "Invalid buyer address");
        }

        // Validate the caller is owner of the BlockBarBTL tokens,
        // and has provided approval to manage tokens to this contract
        unchecked {
            for (uint256 i = 0; i< tokenIds.length; i++) {
                address _tokenOwner = _blockBarBtlContract.ownerOf(tokenIds[i]);
                require(_tokenOwner == msg.sender, "Only owner can list for sale");
                require(_blockBarBtlContract.isApprovedForAll(msg.sender, address(this)), "Seller revoked permissions");
            }
        }

        // Increment counter
        _listingIds.increment();

        // Counters are 0 indexed. Use current value to create a new listing
        uint256 listingId = _listingIds.current();

        // Add listing to storage for retrieval later
        _listings[listingId] = Listing({
            listingId: listingId,
            tokenIds:tokenIds,
            owner: msg.sender,
            payoutAddress: payoutAddress,
            validUntil: validUntil,
            forSpecificBuyer: forSpecificBuyer,
            buyerAddress: buyerAddress,
            isListed: true,
            amount: amount,
            currency: currency
        });

        emit ListingCreated(listingId, msg.sender);
        return listingId;
    }

    /**
     * @notice Internal function to disable a listing that is currently active.
     *         Only the owner of the listing can trigger deletion.
     *         Once disabled, no one will be able to purchase this listing.
     *         Will revert if the listing is already disabled.
     *
     * @param listingId ID of the listing to be disabled.
     */

    function _disableListing(uint256 listingId) internal {
        // Check if listing has already been disabled to save gas fees for the caller
        require(_listings[listingId].isListed, "Cannot disable unlisted listing");
        _listings[listingId].isListed = false;
        emit ListingDisabled(listingId);
    }

    /**
     * @notice Internal function to retrieve a listing
     *
     * @param listingId ID of the listing.
     *
     * @return listing a Listing struct containing information of the listing
     */
    function _getListing(uint256 listingId) view internal returns (Listing memory listing) {
        return _listings[listingId];
    }

    /**
    * @notice Internal function to update listing expiration date. Only owner of the listing can extend the listing.
    *         Listing must be valid - cannot be un-listed. The new expiration date must be in the future.
    *
    * @param listingId ID of the listing to update
    * @param validUntil New expiration date in UNIX timestamp (seconds)
    *
    * @return updatedListing Update Listing struct
    */
    function _updateListingExpiration(
        uint256 listingId,
        uint256 validUntil
    ) internal returns (Listing memory updatedListing) {
        require(_listings[listingId].isListed, "Cannot update unlisted listing");
        require(_listings[listingId].owner == msg.sender, "Only owner can change listing");
        require(validUntil > block.timestamp + 1 days, "Listing cannot expire before tomorrow");

        _listings[listingId].validUntil = validUntil;

        emit ListingUpdated(listingId, msg.sender, validUntil);

        return _listings[listingId];
    }
}