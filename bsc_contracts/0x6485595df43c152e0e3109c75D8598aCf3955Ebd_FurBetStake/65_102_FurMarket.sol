// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
// Interfaces.
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

/**
 * @title FurMarket
 * @notice This is the NFT marketplace contract.
 */

/// @custom:security-contact [email protected]
contract FurMarket is BaseContract, ERC721Holder
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
    }

    /**
     * External contracts.
     */
    IERC20 private _paymentToken;

    /**
     * Listings.
     */
    uint256 private _listingIdTracker;
    struct Listing {
        uint256 start;
        address token;
        uint256 id;
        uint256 price;
        uint256 offer;
        address offerAddress;
        address owner;
    }
    mapping(uint256 => Listing) _listings;

    /**
     * Events.
     */
    event ListingCreated(Listing);
    event ListingCancelled(Listing);
    event NftPurchased(Listing);
    event OfferPlaced(Listing);
    event OfferRescinded(Listing);
    event OfferAccepted(Listing);
    event OfferRejected(Listing);

    /**
     * Setup.
     */
    function setup() external
    {
        _paymentToken = IERC20(addressBook.get("payment"));
    }

    /**
     * List NFT.
     * @param tokenAddress_ The address of the NFT contract.
     * @param tokenId_ The ID of the NFT.
     * @param price_ The price of the NFT.
     */
    function listNft(address tokenAddress_, uint256 tokenId_, uint256 price_) external whenNotPaused
    {
        IERC721 _token_ = IERC721(tokenAddress_);
        require(_token_.supportsInterface(type(IERC721).interfaceId), "Token must be ERC721");
        _transferERC721(tokenAddress_, tokenId_, msg.sender, address(this));
        _listingIdTracker++;
        _listings[_listingIdTracker].start = block.timestamp;
        _listings[_listingIdTracker].token = tokenAddress_;
        _listings[_listingIdTracker].id = tokenId_;
        _listings[_listingIdTracker].price = price_;
        _listings[_listingIdTracker].owner = msg.sender;
        emit ListingCreated(_listings[_listingIdTracker]);
    }

    /**
     * Cancel listing.
     * @param listingId_ The ID of the listing.
     */
    function cancelListing(uint256 listingId_) external whenNotPaused
    {
        require(_listings[listingId_].start > 0, "Listing does not exist");
        require(_listings[listingId_].owner == msg.sender, "Only the listing owner can cancel the listing");
        _transferERC721(_listings[listingId_].token, _listings[listingId_].id, address(this), msg.sender);
        emit ListingCancelled(_listings[listingId_]);
        delete _listings[listingId_];
    }

    /**
     * Buy NFT.
     * @param listingId_ The ID of the listing.
     */
    function buyNft(uint256 listingId_) external whenNotPaused
    {
        require(_listings[listingId_].start > 0, "Listing does not exist");
        address _owner_ = _listings[listingId_].owner;
        uint256 _price_ = _listings[listingId_].price;
        address _token_ = _listings[listingId_].token;
        uint256 _tokenId_ = _listings[listingId_].id;
        emit NftPurchased(_listings[listingId_]);
        delete _listings[listingId_];
        require(_paymentToken.transferFrom(msg.sender, _owner_, _price_), "Payment failed");
        _transferERC721(_token_, _tokenId_, address(this), msg.sender);
    }

    /**
     * Make offer.
     * @param listingId_ The ID of the listing.
     * @param offer_ The offer amount.
     */
    function makeOffer(uint256 listingId_, uint256 offer_) external whenNotPaused
    {
        require(_listings[listingId_].start > 0, "Listing does not exist");
        require(offer_ > _listings[listingId_].offer, "Offer must be higher than the highest offer");
        require(_paymentToken.transferFrom(msg.sender, address(this), offer_), "Payment failed");
        _listings[listingId_].offer = offer_;
        _listings[listingId_].offerAddress = msg.sender;
        emit OfferPlaced(_listings[listingId_]);
    }

    /**
     * Rescind offer.
     * @param listingId_ The ID of the listing.
     */
    function rescindOffer(uint256 listingId_) external whenNotPaused
    {
        require(_listings[listingId_].start > 0, "Listing does not exist");
        require(_listings[listingId_].offerAddress == msg.sender, "Only the offer owner can rescind the offer");
        emit OfferRescinded(_listings[listingId_]);
        _deleteOffer(listingId_);
    }

    /**
     * Accept offer.
     * @param listingId_ The ID of the listing.
     */
    function acceptOffer(uint256 listingId_) external whenNotPaused
    {
        require(_listings[listingId_].start > 0, "Listing does not exist");
        require(_listings[listingId_].owner == msg.sender, "Only the listing owner can accept the offer");
        require(_paymentToken.transfer(_listings[listingId_].owner, _listings[listingId_].offer), "Payment failed");
        _transferERC721(_listings[listingId_].token, _listings[listingId_].id, address(this), _listings[listingId_].offerAddress);
        emit OfferAccepted(_listings[listingId_]);
        emit NftPurchased(_listings[listingId_]);
        delete _listings[listingId_];
    }

    /**
     * Reject offer.
     * @param listingId_ The ID of the listing.
     */
    function rejectOffer(uint256 listingId_) external whenNotPaused
    {
        require(_listings[listingId_].start > 0, "Listing does not exist");
        require(_listings[listingId_].owner == msg.sender, "Only the listing owner can reject the offer");
        require(_listings[listingId_].offerAddress != address(0), "No offer to reject");
        require(_listings[listingId_].offer > 0, "No offer to reject");
        emit OfferRejected(_listings[listingId_]);
        _deleteOffer(listingId_);
    }

    /**
     * Get listings.
     * @param cursor_ The cursor.
     * @param limit_ The limit.
     */
    function getListings(uint256 cursor_, uint256 limit_) external view returns (uint256 cursor, Listing[] memory listings)
    {
        Listing[] memory _listings_ = new Listing[](limit_);
        uint256 j;
        for(uint256 i = _listingIdTracker; i >= 0; i--) {
            if(_listings[i].start > 0) {
                _listings_[j] = _listings[i];
                j++;
                if(j == cursor_ + limit_) {
                    break;
                }
            }
        }
        return (j, _listings_);
    }

    /**
     * Transfer ERC721.
     * @param tokenAddress_ The address of the token.
     * @param tokenId_ The ID of the token.
     * @param from_ The address of the sender.
     * @param to_ The address of the receiver.
     */
    function _transferERC721(address tokenAddress_, uint256 tokenId_, address from_, address to_) internal
    {
        IERC721 _token_ = IERC721(tokenAddress_);
        _token_.safeTransferFrom(from_, to_, tokenId_);
        require(_token_.ownerOf(tokenId_) == to_, "Token transfer failed");
    }

    /**
     * Delete offer.
     * @param listingId_ The ID of the listing.
     */
    function _deleteOffer(uint256 listingId_) internal
    {
        address _offerAddress_ = _listings[listingId_].offerAddress;
        uint256 _offer_ = _listings[listingId_].offer;
        _listings[listingId_].offerAddress = address(0);
        _listings[listingId_].offer = 0;
        require(_paymentToken.transfer(_offerAddress_, _offer_), "Payment failed");
    }
}