// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./IdolMain.sol";
import "./VirtueStaking.sol";

/**
  @notice IdolMarketplace is a contract containing functions for listing, bidding on, and exchanging
    God NFTs.
*/
contract IdolMarketplace is VirtueStaking {
  // Listing is a struct which holds metadata for when a user lists a God they own for sale.
  struct Listing {
    // seller indicates the address of who posted the God Listing.
    address seller;

    // minValue specifies the minimum value that the owner will accept when buying through the
    // buyGod function.
    uint minValue;

    // onlySellTo is an optional field that specifies that the God can only be sold to a specific
    // address. Uses the 0x0 address if no specific address is specified.
    address onlySellTo;
  }

  // Bid is a struct holding metadata for when a user bids on a God they are interested in buying.
  struct Bid {
    // bidder indicates the address of who posted the God Bid.
    address bidder;

    // value is the amount (in wei) that the Bid is offering for the God.
    uint value;
  }

  // Royalties that are allocated to the VIRTUE rewards protocol in basis points (100ths of a %).
  uint public constant ROYALTY_BPS = 750;

  // Mapping containing active listings for each god.
  mapping (uint => Listing) public godListings;

  // Mapping containing the active bids for each god.
  mapping (uint => Bid) public godBids;

  // Mapping containing pending balances that users can withdraw.
  mapping (address => uint) public pendingWithdrawals;

  IdolMain public immutable idolMain;

  event GodListed(uint indexed _godId, uint _minValue, address indexed _toAddress);
  event GodBidEntered(uint indexed _godId, uint _value, address indexed _fromAddress);
  event GodBidWithdrawn(uint indexed _godId, uint _value, address indexed _fromAddress);
  event GodBought(uint indexed _godId, uint _value, address indexed _fromAddress, address indexed _toAddress, uint cumulativeETH);
  event GodUnlisted(uint indexed _godId);

  constructor(address _idolMintAddress, address _idolMainAddress, address _virtueTokenAddress)
    VirtueStaking(_idolMintAddress, _virtueTokenAddress)
  {
    idolMain = IdolMain(_idolMainAddress);
  }

  /**
    @notice postGodListing creates a sales listing for a God.
    @param _godId The ID of the God being listed.
    @param _salePriceInWei Specifies the minimum price the God can be bought for using the buyGod function.
  */
  function postGodListing(uint _godId, uint _salePriceInWei) external onlyGodOwner(_godId) nonReentrant {
    godListings[_godId] = Listing(msg.sender, _salePriceInWei, address(0x0));
    emit GodListed(_godId, _salePriceInWei, address(0x0));
  }

  /**
    @notice postGodListingForAddress creates a sales listing for a God exclusively for a single address.
    @param _godId The ID of the God being listed.
    @param _salePriceInWei Specifies the minimum price the God can be bought for using the buyGod function.
    @param _toAddress The address that the Listing is exclusively meant for.
  */
  function postGodListingForAddress(uint _godId, uint _salePriceInWei, address _toAddress) external onlyGodOwner(_godId) nonReentrant {
    godListings[_godId] = Listing(msg.sender, _salePriceInWei, _toAddress);
    emit GodListed(_godId, _salePriceInWei, _toAddress);
  }

  /**
    @notice removeGodListing removes an existing sales listing for a God.
    @param _godId The ID of the God whose listing is being removed.
  */
  function removeGodListing(uint _godId) external nonReentrant {
    require(msg.sender == godListings[_godId].seller, "Can only remove a listing where msg.sender is the seller");
    _removeGodListing(_godId);
  }

  function _removeGodListing(uint _godId) private {
    delete godListings[_godId];
    emit GodUnlisted(_godId);
  }

  /**
    @notice buyGod is used to buy a listed God for the sales price on its Listing. 7.5% of the
      price is also distributed to the VIRTUE rewards controller.
    @param _godId The ID of the God being bought.
  */
  function buyGod(uint _godId) external payable nonReentrant {
    Listing memory listing = godListings[_godId];
    require(listing.minValue > 0, "Can only buy a god that is listed for sale.");
    require(listing.onlySellTo == address(0x0) || listing.onlySellTo == msg.sender, "Owner has reserved god listing for a different address.");
    require(msg.value >= listing.minValue, "Must pay at least the minPrice that the listing specifies.");
    require(listing.seller == idolMain.ownerOf(_godId), "Listing is outdated and was not posted by the god's current owner.");

    address seller = listing.seller;

    _removeGodListing(_godId);
    idolMain.safeTransferFrom(seller, msg.sender, _godId);

    // Reserve royalty for VIRTUE protocol
    uint saleAmount = msg.value;
    uint royalty = saleAmount * ROYALTY_BPS / 10000;
    uint proceeds = saleAmount - royalty;
    pendingWithdrawals[seller] += proceeds;
    _distributeRewards(royalty);
    emit GodBought(_godId, msg.value, seller, msg.sender, cumulativeETH);

    // Check for the case where there is a bid from the new owner and refund it.
    // Any other bid can stay in place.
    if (godBids[_godId].bidder == msg.sender) {
      // Kill bid and refund value
      uint bidValue = godBids[_godId].value;
      delete godBids[_godId];
      pendingWithdrawals[msg.sender] += bidValue;
    }
  }

  /**
    @notice withdrawPendingFunds withdraws any pending funds that the marketplace is holding for
      the user (e.g. through sales or overriden bids).
  */
  function withdrawPendingFunds() external nonReentrant {
    Address.sendValue(payable(msg.sender), pendingWithdrawals[msg.sender]);
    delete pendingWithdrawals[msg.sender];
  }

  /**
    @notice enterBidForGod creates a Bid on the specified God for the amount of ETH passed to the
      function.
    @param _godId The ID of the God to create a Bid for.
  */
  function enterBidForGod(uint _godId) external payable nonReentrant {
    require(idolMain.ownerOf(_godId) != address(0x0), "Cannot bid on god assigned to the 0x0 address.");
    require(idolMain.ownerOf(_godId) != msg.sender, "Cannot bid on a god owned by the bidder.");
    require(msg.value > 0, "Must offer a nonzero amount for bidding.");

    Bid memory existingBid = godBids[_godId];
    require(msg.value > existingBid.value, "A higher bid has already been made for this god.");

    // Refund the existing bid to the original bidder and overwrite with the higher bid.
    if (existingBid.value > 0) {
      pendingWithdrawals[existingBid.bidder] += existingBid.value;
    }
    godBids[_godId] = Bid(msg.sender, msg.value);
    emit GodBidEntered(_godId, msg.value, msg.sender);
  }

  /**
    @notice acceptBidForGod allows a God owner to accept an existing Bid for a God and transfer the
      Bid amount to themselves, in exchange for transferring the God to the bidder. 7.5% of the
      price is also distributed to the VIRTUE rewards controller.
    @param _godId The ID of the God to accept the Bid for.
    @param _minPrice The minimum amount (in wei) that the Bid will be accepted for. Reverts if the
      current Bid is below _minPrice.
  */
  function acceptBidForGod(uint _godId, uint _minPrice) external onlyGodOwner(_godId) nonReentrant {
    Bid memory existingBid = godBids[_godId];
    require(existingBid.value > 0, "Cannot accept a 0 bid.");
    require(existingBid.value >= _minPrice, "Existing bid is lower than the specified _minPrice.");

    delete godListings[_godId];
    idolMain.safeTransferFrom(msg.sender, existingBid.bidder, _godId);

    // Reserve royalty for VIRTUE protocol
    uint saleAmount = existingBid.value;
    delete godBids[_godId];
    uint royalty = saleAmount * ROYALTY_BPS / 10000;
    uint proceeds = saleAmount - royalty;
    pendingWithdrawals[msg.sender] += proceeds;
    _distributeRewards(royalty);
    emit GodBought(_godId, saleAmount, msg.sender, existingBid.bidder,  cumulativeETH);
  }

  /**
    @notice withdrawBidForGod takes down the message sender's previous Bid for a God. It also sends
      them back the funds they had initially sent when creating the Bid.
    @param _godId The ID of the God to withdraw the Bid from.
  */
  function withdrawBidForGod(uint _godId) external nonReentrant {
    require(godBids[_godId].bidder == msg.sender, "Cannot withdraw a bid not made by the sender.");

    uint amount = godBids[_godId].value;
    emit GodBidWithdrawn(_godId, amount, msg.sender);
    delete godBids[_godId];
    Address.sendValue(payable(msg.sender), amount);
  }

  modifier onlyGodOwner(uint _godId) {
    require(msg.sender == idolMain.ownerOf(_godId), "Must own the specified God to call this function.");
    _;
  }
}