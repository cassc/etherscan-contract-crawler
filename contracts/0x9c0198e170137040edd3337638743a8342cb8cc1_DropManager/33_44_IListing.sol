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

import "./IGrtWines.sol";

interface IListing is IGrtWines {
  //################
  //#### STRUCTS ####

  /// @dev Parameters for creating a Listing. Releases and Listings are matched with {listingId}
  /// @param releaseId The release identifier - Counter from DropManager contract
  /// @param listingId The release identifier - Counter from DropManager contract
  /// @param startDate Start date of the drop listing
  /// @param endDate End date of the drop listing
  /// @param minimumBid Minumum price to allow the listing to sell for
  /// @param startingPrice Starting price for the listing
  struct Listing {
    uint128 releaseId;
    uint40 startDate;
    uint40 endDate;
    uint256 minimumBid;
    uint256 startingPrice;
  }

  /// @param bidder The release identifier - Counter from DropManager contract
  /// @param amount  The amount of the bid
  struct Bid {
    address bidder;
    uint256 amount;
  }

  //################
  //#### EVENTS ####

  /// @dev Emitted when a Listing is created
  event ListingCreated(uint128 listingId, uint128 releaseId);

  /// @dev Emitted when a Listing is updated
  event ListingUpdated(uint128 listingId);

  /// @dev Emitted when a listing is deleted
  event ListingDeleted(uint128 listingId);

  /// @dev Emitted when a bid is successfully registered
  event BidRegistered(
    address indexed bidder,
    uint256 amount,
    uint256 tokenId,
    uint256 listingId
  );

  /// @dev Emitted when bidding is extended due to a bid being received < 10 minutes before cut-off
  event BiddingExtended(uint128 listingId);

  //################
  //#### ERRORS ####
  /// @dev Throw if listing is being deleted while it is active or completed. (TODO NEED TO UPDATE LOGIC IN ENGLISH DROP CONTRACT)
  error ListingStarted();

  /// @dev Thrown if certain operations try to be performed on already active listings
  error ListingActive();

  /// @dev Thrown if sender requests the status of a listing that was not listed at this contract.
  error NotListedHere();

  /// @dev Thrown if a bid is invalid, e.g bid < minimum bid, bid < current bid
  error InvalidBid();

  /// @dev Thrown if a bid is placed on a listing that has not started or has expired
  error ListingNotActive();

  /// @dev Thrown if validateTokenClaim or validateEthWithdrawal calls are invalid, e.g bidding still active or claimant not the bidding winner
  error InvalidClaim();

  /// @dev Thrown if attempting to distribute funds on a listings that has already had its funds distributed
  /// @param listingId The id of the listing for which the error was thrown
  error AlreadyDistributed(uint128 listingId);

  /// @dev Thrown if a distribution is attempted on a listing type that does not support it
  error DistributionNotSupported();

  //###################
  //#### FUNCTIONS ####

  /// @notice Used to create a purchase listing
  /// @dev Only callable by the dropManager (has DROP_MANAGER_ROLE)
  /// @param listingId - ID of the listing
  /// @param listing - Listing struct
  function createListing(
    uint128 listingId,
    Listing calldata listing,
    bytes calldata data
  ) external;

  /// @notice Used to update a purchase listing
  /// @dev Only callable by the dropManager (has DROP_MANAGER_ROLE)
  /// @dev Only if listing has not started yet
  /// @param listingId - ID of the listing
  /// @param listing - Listing struct
  function updateListing(
    uint128 listingId,
    Listing calldata listing,
    bytes calldata data
  ) external;

  /// @notice Used to delete a purchase listing
  /// @dev Only callable by the dropManager (has DROP_MANAGER_ROLE)
  /// @dev Only if listing has not started yet
  /// @param listingId - ID of the listing
  function deleteListing(uint128 listingId) external;

  /// @notice Utilised to register a bid for a specific token
  /// @dev Only callable by the dropManager (has DROP_MANAGER_ROLE)
  /// @dev Only if listing has not started yet
  /// @param listingId - The listing ID that this bid relates to
  /// @param tokenId - The tokenId this bid relates to
  /// @param bid - The bid itself
  function registerBid(
    uint128 listingId,
    uint256 tokenId,
    Bid calldata bid,
    bytes calldata data
  ) external;

  /// @notice Utilised to validate that a valid claim of a token is being submitted
  /// @dev Only callable by the dropManager (has DROP_MANAGER_ROLE)
  /// @dev Either returns true on success or reverts
  /// @dev  Only returns true if the claimant is the highest bidder and listing has expired
  /// @param listingId - The listing ID that this bid relates to
  /// @param tokenId - The tokenId this bid relates to
  /// @return saleAmount - The amount for which the token was sold
  function validateTokenClaim(
    uint128 listingId,
    uint128 releaseId,
    uint128 tokenId,
    address claimant
  ) external returns (uint256 saleAmount);

  /// @notice Validate whether a manual distribution is allowed for this listing. If it is valid, set the listing as distributed and return true. If not, revert
  /// @dev Only callable by the droper (has DROP_MANAGER_ROLE)
  /// @param listingId The id of the listing to validate
  /// @return valid Boolean as to whether the manual distribution is allowed
  function validateManualDistribution(uint128 listingId)
    external
    returns (bool valid);

  /// @notice Check if a listing has passed its end date
  /// @dev Should be checked before placing a bid
  /// @param listingId - The id of the listing to check
  function listingEnded(uint128 listingId) external view returns (bool status);

  //#################
  //#### GETTERS ####
  function DROP_MANAGER_ROLE() external returns (bytes32 role);
}