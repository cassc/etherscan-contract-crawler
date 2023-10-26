// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../interfaces/IBuyItNow.sol";
import "../interfaces/IDropManager.sol";
import "../interfaces/ITokenContract.sol";
import "../libraries/GrtLibrary.sol";

/// @title Buy It Now
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor mfbevan (mfbevan.eth)
/// @custom:contributor Seb N
/// @notice A listing type involving a single token that can be bought instantly. If a users placed a bid with a high enough amount, they
///         will be the winner. The listing will continue until the timer runs out or there are not tokens left to buy.
contract BuyItNow is IBuyItNow, AccessControl {
  bytes32 public constant override DROP_MANAGER_ROLE =
    keccak256("DROP_MANAGER_ROLE");

  /// Listing ID => BIN Listing
  mapping(uint128 => BINListing) public override listings;

  IDropManager public immutable dropManager;

  constructor(address _dropManager, address _superUser) {
    GrtLibrary.checkZeroAddress(_dropManager, "dropManager");
    GrtLibrary.checkZeroAddress(_superUser, "super user");

    dropManager = IDropManager(_dropManager);

    _grantRole(DROP_MANAGER_ROLE, _dropManager);
    _grantRole(DEFAULT_ADMIN_ROLE, _superUser);
  }

  function _listingEnded(uint128 listingId)
    internal
    view
    returns (bool hasEnded)
  {
    hasEnded = block.timestamp > listings[listingId].endDate;
  }

  /// @dev Set listing details. To be used on creation and updating of listings
  /// @param listingId The id of the listing to update as per the global counter in the Drop Manager
  /// @param listing The new listing details
  function _setListing(
    uint128 listingId,
    Listing calldata listing,
    bytes calldata
  ) internal {
    if (
      block.timestamp > listing.endDate || listing.endDate <= listing.startDate
    ) {
      revert IncorrectParams(msg.sender);
    } else if (block.timestamp > listing.startDate) {
      revert ListingActive();
    }

    listings[listingId] = BINListing({
      releaseId: listing.releaseId,
      startDate: listing.startDate,
      endDate: listing.endDate,
      salePrice: listing.startingPrice
    });
  }

  function createListing(
    uint128 listingId,
    Listing calldata listing,
    bytes calldata data
  ) external override onlyRole(DROP_MANAGER_ROLE) {
    _setListing(listingId, listing, data);
    emit ListingCreated(listingId, listing.releaseId);
  }

  function deleteListing(uint128 listingId)
    external
    override
    onlyRole(DROP_MANAGER_ROLE)
    notStarted(listingId)
  {
    delete listings[listingId];
    emit ListingDeleted(listingId);
  }

  function updateListing(
    uint128 listingId,
    Listing calldata listing,
    bytes calldata data
  ) external override onlyRole(DROP_MANAGER_ROLE) notStarted(listingId) {
    _setListing(listingId, listing, data);
    emit ListingUpdated(listingId);
  }

  function registerBid(
    uint128 listingId,
    uint256 tokenId,
    Bid calldata bid,
    bytes calldata
  ) external override onlyRole(DROP_MANAGER_ROLE) {
    BINListing memory listing = listings[listingId];
    if (
      (block.timestamp < listing.startDate) ||
      (block.timestamp > listing.endDate)
    ) {
      revert ListingNotActive();
    }

    if (bid.amount < listing.salePrice) {
      revert InvalidBid();
    }

    emit BidRegistered(bid.bidder, bid.amount, tokenId, listingId);

    uint8 listingType = dropManager.addressListingLookup(address(this));
    if (bid.amount > 0) {
      dropManager.distributeSaleFunds(
        listingType,
        listingId,
        listing.releaseId,
        bid.amount
      );
    }
    dropManager.transferToken(listingType, SafeCast.toUint128(tokenId), bid.bidder);
  }

  /// @dev Due to this being the BuyItNow contract, there is no reason for a claim
  ///      to be made. Therefore if a claim is made, an error is feedback to the
  ///     caller that this function is not available.
  function validateTokenClaim(
    uint128,
    uint128,
    uint128,
    address
  ) external view override onlyRole(DROP_MANAGER_ROLE) returns (uint256) {
    revert InvalidClaim();
  }

  function validateEthWithdrawal(uint128 listingId)
    external
    view
    onlyRole(DROP_MANAGER_ROLE)
    returns (bool valid)
  {
    if (!_listingEnded(listingId)) {
      revert InvalidClaim();
    }
    return true;
  }

  /// @dev Manual distribution is not necesarry on Buy It Now listings as funds are automatically distributed on sale
  function validateManualDistribution(uint128) external pure returns (bool) {
    revert DistributionNotSupported();
  }

  function listingEnded(uint128 listingId)
    external
    view
    override
    returns (bool status)
  {
    BINListing memory currentListing = listings[listingId];
    if (currentListing.releaseId == 0) {
      revert NotListedHere();
    }
    status = block.timestamp > currentListing.endDate;
  }

  modifier notStarted(uint128 listingId) {
    if (block.timestamp > listings[listingId].startDate) {
      revert ListingActive();
    }
    _;
  }
}