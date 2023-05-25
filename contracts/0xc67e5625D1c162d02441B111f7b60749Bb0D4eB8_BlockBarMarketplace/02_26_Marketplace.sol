// SPDX-License-Identifier:  AGPL-3.0-or-later
pragma solidity 0.8.18;


import {Listings} from "Listings.sol";
import {Listing} from "IListings.sol";
import {IMarketplace} from "IMarketplace.sol";

import {Counters} from "Counters.sol";
import {EnumerableSet} from "EnumerableSet.sol";


/**
 * @title Marketplace
 * @author aarora
 * @notice Marketplace handles sales of listings. Sales include transferring royalties, funds to seller,
 *         and tokens to buyers. Additionally, a sale of a listing will require the listing owner to
 *         provide approval to this contract address on BlockBarBTL ERC721 contract.
 */
contract Marketplace is Listings, IMarketplace {
    // Use counters for tracking sales
	using Counters for Counters.Counter;

    // Use EnumerableSet for royalties mapping.
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _sales;

    // Define Marketplace royalty share
    uint96 private _marketplaceFee = 1000;
    uint96 public constant FEE_DENOMINATOR = 10000;

    // Forward constructor params to Listings contract to initial ERC721 and PriceFeed contracts.
    constructor(
        address blockbarBtlContractAddress,
        address priceFeedAddress
    ) Listings(blockbarBtlContractAddress, priceFeedAddress) {}

    /**
     * @notice Validate a listing by performing the following checks:
     *         - The owner of the tokens in the listing should match the listing owner
     *         - The listing should have isListed set to true
     *         - The listing should have validUntil greater than the block timestamp. Otherwise the listing has expired.
     *         - The owner of listing should have provided approval to contract address on BlockBarBTL contract
     *
     * @param  listingId ID of the listing to validate.
     *
     * @return isValid Returns whether the listing can be purchase or not.
     */
    function validate(uint256 listingId) external view returns (bool isValid) {
        Listing memory listing = _getListing(listingId);
        // Initial checks for a quick revert.
        require(listing.isListed, "Cannot buy unlisted NFT");
        require(listing.validUntil > block.timestamp, "Listing has expired");

        // If the tokens have been sold external to this contract, the listing is no longer valid.
        for(uint256 i; i < listing.tokenIds.length; i++) {
            require(_blockBarBtlContract.ownerOf(listing.tokenIds[i]) == listing.owner, "Owner mismatch");
        }

        // If the token holder has revoked permissions for this contract address, the listing is no longer valid.
        require(_blockBarBtlContract.isApprovedForAll(listing.owner, address(this)), "Seller has revoked permissions");
        return true;
    }

    /**
     * @notice Swap function is used to purchase a valid listing. A valid listing equates to the following being true:
     *                 - The owner of the tokens in the listing should match the listing owner
     *                 - The listing should have isListed set to true
     *                 - The listing should have validUntil greater than the block timestamp.
     *                   Otherwise the listing has expired.
     *                 - The owner of listing should have provided approval to contract address on BlockBarBTL contract
     *                 - The buyer should send exact amount of funds (as the listing amount) if the listing currency
     *                   is in ETH.
     *                 - The buyer should send within the threshold of slippage if the listing is in USD
     *          If all of the above are true, the swap function will send out royalties and
     *          transfer remainder to the previous owner before transferring the tokens from the seller to the buyer.
     *          Once all of the above is done, the function will increment the total sales counter.
     *
     * @param  listingId ID of the listing for sale.
     */
    function swap(uint256 listingId) external payable nonReentrant whenNotPaused {
        require(msg.value != 0, "Amount sent cannot be 0");
        Listing memory listing = _getListing(listingId);
        // Initial checks for quick revert.
        require(listing.isListed, "Cannot buy unlisted NFT");
        require(listing.validUntil > block.timestamp, "Listing has expired");
        require(_blockBarBtlContract.isApprovedForAll(listing.owner, address(this)), "Seller revoked permissions");
        if (listing.forSpecificBuyer) {
            // If the listing is for a specific buyer, only that address can purchase it.
            require(listing.buyerAddress == msg.sender, "Listing is not for public sale");
        }
        uint256 amount = listing.amount;
        uint256 fullAmount = msg.value;
        if (listing.currency == USD_CURRENCY) {
            // If listing is in USD, validate funds received to be within acceptable threshold to allow the sale.
            amount = _convertUSDWeiToETHWei(amount);
            require(_isClose(amount, fullAmount, 5), "Amount does not match payment for USD listing");
        }
        else {
            // If listing is in ETH, the funds send should match exactly to the listing amount.
            require(amount == fullAmount, "Amount does not match payment for ETH listing");
        }

        // increment sales counter.
        _sales.increment();
        // Disable the listing to avoid attempts to purchase it.
        _disableListing(listingId);
        // Evenly split the full amount into amount per token for royalty calculation
        uint256 listPriceOfTokenId = fullAmount / listing.tokenIds.length;

        for(uint256 i; i < listing.tokenIds.length; i++) {
            uint256 tokenId = listing.tokenIds[i];
            // For each token in the listing, validate the owner matches. Otherwise the listing is no longer valid.
            require(_blockBarBtlContract.ownerOf(tokenId) == listing.owner, "Owner mismatch");
            uint256 amountToSendToRoyaltyCollector = (listPriceOfTokenId * _marketplaceFee) / FEE_DENOMINATOR;
            // _send funds will revert the transaction if insufficient balance or if collector cannot receive funds.
            _sendFunds(_owner, amountToSendToRoyaltyCollector);
            // Emit event for royalties sent.
            emit TransferToRoyaltiesCollector(tokenId, _owner, _marketplaceFee, amountToSendToRoyaltyCollector);
            // Subtract royalty amount from full amount to calculate sellers' payout.
            fullAmount -= amountToSendToRoyaltyCollector;
            // for each token in the listing, call ERC721 safeTransferFrom to move tokens to the buyers' wallet.
            _blockBarBtlContract.safeTransferFrom(listing.owner, msg.sender, listing.tokenIds[i]);
        }

        // Send funds to seller with the remainder of the funds from buyer.
        _sendFunds(listing.payoutAddress, fullAmount);
        // Emit event confirming funds have been sent to previous owner.
        emit TransferToPreviousOwner(listingId, listing.payoutAddress, fullAmount);
        // Emit event confirming the listing has been sold
        emit Swap(listingId, msg.sender);
    }

    /**
    * @notice Private helper function used sending funds to EOAs or contracts.
    *         Will revert if the receiver cannot accept funds.
    *
    * @param receiver Address to send the funds to.
    * @param amount   Amount in Wei to send to the receiver.
    */
    function _sendFunds(address receiver, uint256 amount) private {
        // Ensure contract has enough funds to send.
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = receiver.call{value: amount}("");
        // Revert if funds cannot be send to the receiver.
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
    * @notice Drain function used for dust collection. Any remainder funds in the wallet can be drained by the admin.
    */
    function drain() external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        // revert if there's nothing to drain
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to drain");
        _sendFunds(msg.sender, amount);
    }

    /**
    * @notice Get number of sales on this contract
    *
    * @return numberOfSales Number of sales generated
    */
    function getSales() external view returns (uint256 numberOfSales) {
        return _sales.current();
    }

    /**
    * @notice Update marketplace royalties
    *
    * @param newMarketplaceFee New Marketplace Royalty. Most be greater than fee denominator
    */
    function setMarketplaceFee(uint96 newMarketplaceFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // revert if there's nothing to drain
        require(newMarketplaceFee >= 100, "Must be at least 1%");
        require(newMarketplaceFee < FEE_DENOMINATOR, "Cannot be more than FEE_DENOMINATOR");
        _marketplaceFee = newMarketplaceFee;
    }

    /**
    * @notice Get marketplace fees
    */
    function getMarketplaceFee() external view returns (uint96 marketplaceFees){
        return _marketplaceFee;
    }
}