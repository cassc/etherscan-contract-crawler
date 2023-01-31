// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IERC2981} from "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";

/**
 * Built with <3 by 0xfoobar
 */

contract LiquidDelegateMarket {

    address public immutable LIQUID_DELEGATE;

    struct Bid {
        address bidder;
        uint96 rightsId;
        uint256 weiAmount;
    }

    struct Listing {
        address seller;
        uint96 rightsId;
        uint256 weiAmount;
    }

    /// @notice A mapping pointing bid ids to bid structs
    mapping(uint256 => Bid) public bids;

    /// @notice A mapping pointing listing ids to listing structs
    mapping(uint256 => Listing) public listings;

    /// @notice The next bid id to be created
    uint256 public nextBidId = 1;

    /// @notice The next listing id to be created
    uint256 public nextListingId = 1;

    /// @notice Emitted when a bid is created
    event BidCreated(uint256 indexed bidId, address indexed bidder, uint256 indexed rightsId, uint256 weiAmount);

    /// @notice Emitted when a bid is canceled or fulfilled
    event BidCanceled(uint256 indexed bidId, address indexed bidder, uint256 indexed rightsId, uint256 weiAmount);

    /// @notice Emitted when a listing is created
    event ListingCreated(uint256 indexed listingId, address indexed seller, uint256 indexed rightsId, uint256 weiAmount);

    /// @notice Emitted when a listing is canceled or fulfilled
    event ListingCanceled(uint256 indexed listingId, address indexed seller, uint256 indexed rightsId, uint256 weiAmount);

    /// @notice Emitted when a liquid delegate is sold
    event Sale(uint256 indexed rightsId, address indexed buyer, address indexed seller, uint256 weiAmount);

    constructor(address _liquidDelegate) {
        LIQUID_DELEGATE = _liquidDelegate;
    }

    /// @notice Create a bid to buy a liquid delegate
    /// @param rightsId The id of the liquid delegate
    function bid(uint256 rightsId) external payable {
        bids[nextBidId] = Bid({
            bidder: msg.sender,
            rightsId: uint96(rightsId),
            weiAmount: msg.value
        });
        emit BidCreated(nextBidId++, msg.sender, rightsId, msg.value);
    }

    /// @notice Cancel your bid
    /// @param bidId The id of the bid to cancel
    function cancelBid(uint256 bidId) external {
       // Move data into memory to delete the bid data first, preventing reentrancy
        Bid memory bid = bids[bidId];
        uint256 rightsId = bid.rightsId;
        uint256 bidAmount = bid.weiAmount;
        address bidder = bid.bidder;
        delete bids[bidId];

        require(msg.sender == bidder, "NOT_YOUR_BID");
        _pay(payable(bidder), bidAmount, true);
        emit BidCanceled(bidId, bidder, rightsId, bidAmount);
    }

    /// @notice Create a new listing to sell your liquid delegate
    /// @param rightsId The id of the liquid delegate
    /// @param weiAmount The amount to sell for
    function list(uint256 rightsId, uint256 weiAmount) external {
        listings[nextListingId] = Listing({
            seller: msg.sender,
            rightsId: uint96(rightsId),
            weiAmount: weiAmount
        });
        emit ListingCreated(nextListingId++, msg.sender, rightsId, weiAmount);
    }

    /// @notice Cancel your own listing
    /// @param listingId The id of the listing
    function cancelListing(uint256 listingId) external {
        // No re-entrancy possible here, no external calls
        Listing memory listing = listings[listingId];
        require(msg.sender == listing.seller, "NOT_YOUR_LISTING");
        emit ListingCanceled(listingId, msg.sender, listing.rightsId, listing.weiAmount);
        delete listings[listingId];
    }

    /// @notice Fulfill a listing and buy a liquid delegate
    /// @param listingId The id of the listing, not the liquid delegate
    function buy(uint256 listingId) external payable {
        Listing memory listing = listings[listingId];
        address seller = listing.seller;
        uint256 listPrice = listing.weiAmount;
        uint256 rightsId = listing.rightsId;
        delete listings[listingId];

        address currentOwner = IERC721(LIQUID_DELEGATE).ownerOf(rightsId);
        require(msg.value == listPrice, "WRONG_PRICE");
        require(currentOwner == seller, "NOT_OWNER");
        IERC721(LIQUID_DELEGATE).transferFrom(currentOwner, msg.sender, rightsId);
        (address receiver, uint256 royaltyAmount) = IERC2981(LIQUID_DELEGATE).royaltyInfo(rightsId, listPrice);
        _pay(payable(receiver), royaltyAmount, true);
        _pay(payable(currentOwner), listPrice - royaltyAmount, true);
        emit ListingCanceled(listingId, seller, rightsId, listPrice);
        emit Sale(rightsId, msg.sender, currentOwner, listPrice);
    }

    /// @notice Accept a bid and sell your liquid delegate
    /// @param bidId The id of the bid, not the liquid delegate
    function sell(uint256 bidId) external {
        // Move data into memory to delete the bid data first, preventing reentrancy
        Bid memory bid = bids[bidId];
        uint256 rightsId = bid.rightsId;
        uint256 bidAmount = bid.weiAmount;
        address bidder = bid.bidder;
        delete bids[bidId];

        address currentOwner = IERC721(LIQUID_DELEGATE).ownerOf(rightsId);
        require(currentOwner == msg.sender, "NOT_OWNER");
        IERC721(LIQUID_DELEGATE).transferFrom(currentOwner, bidder, rightsId);
        (address receiver, uint256 royaltyAmount) = IERC2981(LIQUID_DELEGATE).royaltyInfo(rightsId, bidAmount);
        _pay(payable(receiver), royaltyAmount, true);
        _pay(payable(currentOwner), bidAmount - royaltyAmount, true);
        emit BidCanceled(bidId, bidder, rightsId, bidAmount);
        emit Sale(rightsId, bidder, currentOwner, bidAmount);
    }

    /// @dev Send ether
    function _pay(address payable recipient, uint256 amount, bool errorOnFail) internal {
        (bool sent,) = recipient.call{value: amount}("");
        require(sent || errorOnFail, "SEND_ETHER_FAILED");
    }
}