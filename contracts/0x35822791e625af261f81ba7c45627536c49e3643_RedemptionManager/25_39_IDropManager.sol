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

import "./IDropManagerAdmin.sol";
import "./IListing.sol";
import "./ITokenContract.sol";
import "./IRedemptionManager.sol";
import "./IRoyaltyDistributor.sol";
import "./ISwap.sol";

/// @title Drop Manager
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor Sean L (slongdotexe)
/// @custom:contributor mfbevan (mfbevan.eth)
/// @custom:contributor Seb N
/// @notice The nerve centre of the Droping system for GRT. Responsible for routing calls to relevant implementation
///         contracts for purchase and token logic
interface IDropManager is IDropManagerAdmin {
  //################
  //#### STRUCTS ####

  /// @dev Parameters for creating a Release which could include one or more tokens. E.g a box of six wines
  /// @param listingType The identifier of the drop contract which manages sale logic. Up to 255
  /// @param listingId The listing identifier - Counter from DropManager contract
  /// @param startTokenId Start point of included tokens
  /// @param endTokenId The end of the token range to drop
  /// @param producerPercentage The percentage of sales to send to producers. The remaining funds will be claimed by GRT
  /// @param producer The address of the producer who will receive funds for release sales
  struct Release {
    uint128 listingId;
    uint128 startTokenId;
    uint128 endTokenId;
    uint8 listingType;
    uint16 producerPercentage;
    address producer;
  }

  //################
  //#### EVENTS ####

  /// @dev Emitted when a Release is created
  event ReleaseCreated(uint128 releaseId);

  /// @dev Emitted on successful token claim
  event TokenClaimed(address claimant, uint128 tokenId);

  /// @dev Emitted when unsold tokens are withdrawn
  event TokensWithdrawn(
    address indexed receiver,
    uint128 listingId,
    uint128[] tokens
  );

  /// @dev Emitted when proceeds from listings are withdrawn successfully
  event ProceedsWithdrawn(address indexed receiver, uint128[] listingIds);

  /// @dev Emitted on successful setting of a Time Lock
  event TimeLockSet(uint256 indexed releaseId, uint256 indexed releaseDate);

  /// @dev Emitted when funds are distributed to producers
  event FundsDistributed(address receiver, uint256 amount, uint128 releaseId);

  //################
  //#### ERRORS ####

  /// @dev Thrown if an account attempts to create a listing for a release that already has a listing
  error ReleaseAlreadyListed(address sender, uint128 releaseId);

  /// @dev Thrown if the provided releaseId does not exist
  error InvalidRelease(address sender, uint128 releaseId);

  /// @dev Thrown if an account attempts to withdraw an un-sold token that is not included in the release ID provided
  error TokenNotInRelease(uint128 tokenId);

  /// @dev Thrown if usdc balance of contract does not match expected after swap
  error IncorrectSwapParams();

  /// @dev Thrown if an account attempts to withdraw a token that already has a bid
  error TokenHasBid(uint128 tokenId);

  /// @dev Thrown everytime unless msg.sender is the address of the listingRegistry itself
  error InvalidTransferOperator();

  /// @dev Thrown if an ETH transfer fails
  error EthTransferFailed();

  /// @dev Thrown if attempting to transfer a zero eth amount
  error InvalidTokenAmount();

  /// @dev Thrown if operations attempt to be performed on a release with a listing that is still active
  /// @param listingId The listing ID that is still considered active
  error ListingActive(uint128 listingId);

  /// @dev Thrown if the token has already sold or been otherwise withdrawn
  error TokenAlreadySold();

  /// @dev Thrown if an invalid producer percentage is provided (greater than 100%)
  error InvalidProducerPercentage(uint16 producerPercentage);

  /// @dev Throw if attempting to distribute funds on a release that does not have any remaining funds to distribute
  /// @param listingId The id of the listing for which the error was thrown
  error NoFundsRemaining(uint128 listingId);

  //###################
  //#### FUNCTIONS ####

  /// @notice Create a release for tokens
  /// @dev Calls the liquid token contract to mint a sequential range of tokens and add tokens URIs to the registry
  /// @param qty The number of tokens to mint for the release
  /// @param liquidUri The liquid token URI to set for the batch
  /// @param redeemedUri The redeemed token URI to set for the batch
  /// @param producer The address of the producer who will receive funds for release sales
  /// @param producerPercentage The percentage of sales to send to producers. The remaining funds will be claimed by GRT
  function createRelease(
    uint128 qty,
    string memory liquidUri,
    string memory redeemedUri,
    address producer,
    uint16 producerPercentage
  ) external;

  /// @notice Create a listing for a release
  /// @dev Creates a Listing at the target contract based on the provided listingType
  /// @param listing The listing data
  /// @param listingType The type of listing this should be e.g EnglishDrop, Buy It Now
  /// @param releaseDate The date at which the listing is published.
  /// @param data Arbitrary additional data to be passed to the Listing contract, should additional data be required by new listing types in future
  function createListing(
    IListing.Listing calldata listing,
    uint8 listingType,
    uint256 releaseDate,
    bytes calldata data
  ) external;

  /// @notice Create a release and list in at a listing contract with one call
  /// @param listingType The listing type identifer
  /// @param qty The number of tokens to mint
  /// @param liquidUri The liquid token URI to set for the batch
  /// @param redeemedUri The redeemed token URI to set for the batch
  /// @param producer The address of the producer who will receive funds for release sales
  /// @param producerPercentage The percentage of sales to send to producers. The remaining funds will be claimed by GRT
  /// @param listing The listing data to pass to the listing contract
  /// @param releaseDate The date at which the release is published.
  /// @param data Arbitrary additional data should requirements change in future
  function createReleaseAndList(
    uint8 listingType,
    uint128 qty,
    string memory liquidUri,
    string memory redeemedUri,
    address producer,
    uint16 producerPercentage,
    IListing.Listing memory listing,
    uint256 releaseDate,
    bytes calldata data
  ) external;

  /// @notice Update a listing
  /// @dev Cannot update an active listing
  /// @param listingType The listing type identifer
  /// @param listingId The identifier of the listing to be updated
  /// @param listing The listing data to update the existing listing with
  /// @param data Arbitrary additional data should requirements change in future
  function updateListing(
    uint8 listingType,
    uint128 listingId,
    IListing.Listing calldata listing,
    bytes calldata data
  ) external;

  /// @notice Delete a listing
  /// @dev Cannot delete a listing once it has started
  /// @param listingType The listing type ID of the target listing contract
  /// @param listingId The listing ID of the listing itself
  function deleteListing(uint8 listingType, uint128 listingId) external;

  /// @notice Relist a release, maintaining funds stored in the DropManager
  /// @dev Assigns a new listing ID and sets new listing information on the target contract
  /// @dev Calls create listing on the target contract, even if the target is the same as the old one
  /// @param releaseId The release ID this relisting targets
  /// @param listing The listing information to relist with
  /// @param data Arbitrary additional data
  function relistRelease(
    uint128 releaseId,
    uint8 newListingType,
    IListing.Listing calldata listing,
    bytes calldata data
  ) external;

  /// @notice Place a bid directly with USDC
  /// @param releaseId The release ID this relisting targets
  /// @param tokenId The targeted token ID
  /// @param amount The amount of USDC for the token
  /// @param data Arbitrary additional data
  function placeBidWithUSDC(
    uint128 releaseId,
    uint128 tokenId,
    uint256 amount,
    bytes calldata data
  ) external;

  /// @notice Places a bid with ETH
  /// @dev Calls Swap contract to exchange ETH for USDC
  /// @param releaseId The release ID this relisting targets
  /// @param tokenId The targeted token ID
  /// @param spender an address provided by the 0x Quote API
  /// @param swapTarget an address provided by the 0x Quote API
  /// @param data Data from 0x Swap API
  function placeBidWithETH(
    uint128 releaseId,
    uint128 tokenId,
    uint256 amount,
    address spender,
    address payable swapTarget,
    bytes calldata data
  ) external payable;

  /// @notice Places a bid with FIAT through integration iwth Paper
  /// @dev Calls Swap contract to exchange ETH for USDC
  /// @param releaseId The release ID this relisting targets
  /// @param tokenId The targeted token ID
  /// @param receiver The person to receive the token through purchase with Paper
  /// @param spender an address provided by the 0x Quote API
  /// @param swapTarget an address provided by the 0x Quote API
  /// @param data Data from 0x Swap API
  function placeETHBidWithReceiver(
    uint128 releaseId,
    uint128 tokenId,
    address receiver,
    uint256 amount,
    address spender,
    address payable swapTarget,
    bytes calldata data
  ) external payable;

  /// @notice Callback function for listing contracts to return USDC of the previous highest bidder once they are out-bid
  /// @dev Can ONLY be used as a callback from a listing contract - if msg.sender != listingRegistry[listingId] it reverts
  /// @param listingType The listing ID of the contract doing the callback
  /// @param listingId The ID of the listing
  /// @param destination The destination for the USDC transfer (previous higest bidder)
  /// @param amount The value of ETH to send
  function transferBaseToken(
    uint8 listingType,
    uint128 listingId,
    address destination,
    uint256 amount
  ) external;

  /// @notice Callback function for listing contracts to send tokens to a user for immediate settlement listings - e.g buy it now
  /// @dev Can ONLY be used as a callback from a listing contract - if msg.sender != listingRegistry[listingId] it reverts
  /// @param listingType The listing ID of the contract doing the callback
  /// @param tokenId The ID of the token to be transferred
  /// @param destination The destination for the ETH transfer (previous higest bidder)
  function transferToken(
    uint8 listingType,
    uint128 tokenId,
    address destination
  ) external;

  /// @notice Claim a token that has been won via a non-immediate settlement sale, i.e Drop
  /// @dev Performs check at the target contract to verify the highest bidder, listing has ended etc
  /// @param tokenId The ID of the token to be checked
  /// @param listingId The ID of the listing this token was won in
  /// @param listingType The listing type this was one from
  function claimToken(
    uint128 releaseId,
    uint128 tokenId,
    uint128 listingId,
    uint8 listingType
  ) external;

  /// @notice Withdraw un-sold tokens.
  /// @dev If tokens are withdrawn from the dropManager they cannot be relisted for sale via the current droping system
  /// @param releaseId The release ID these tokens belong to
  /// @param tokens Array of token IDs
  /// @param destination The destination for the tokens to be withdrawn to
  function withdrawTokens(
    uint128 releaseId,
    uint128[] calldata tokens,
    address destination
  ) external;

  /// @notice Distribute remaining funds for a release that usually distributes funds on claim (e.g Drops)
  /// @dev Distributes to the assigned producer wallet, with remaining funds going to the grt royalty wallet
  /// @dev Should only be called for releases that store pending eth balances until claim (e.g Drops)
  /// @dev Emits a {FundsDistributed} event for the receiver
  /// @dev Emits a {FundsDistributed} event for the royalties
  /// @dev Can only be called by PLATFORM_ADMIN role
  /// @param listingType The id of the listing contract in which the listing exists
  /// @param listingId The id of the listing to release funds for
  /// @param releaseId The id of the release for which the listing was made
  function distributeListingFunds(
    uint8 listingType,
    uint128 listingId,
    uint128 releaseId
  ) external;

  /// @notice Distribute funds for a single sale to producer account, with remaining funds sent as a royalty to the grt royalty account
  /// @dev Can only be called by Listing contracts
  /// @dev Should be called when the token is claimed for drops, and on sale for instant transactions like Buy It Now
  /// @dev Emits a {FundsDistributed} event for the receiver
  /// @dev Emits a {FundsDistributed} event for the royalties
  /// @param listingType The type that this call was made from
  /// @param listingId The ID of the listing the token was won in
  /// @param releaseId The ID of the release the token was won in
  /// @param saleAmount The total value of the sale, with producer proceed being a percentage of this amount
  function distributeSaleFunds(
    uint8 listingType,
    uint128 listingId,
    uint128 releaseId,
    uint256 saleAmount
  ) external;

  /// @notice Distribute secondary market sales for a release
  /// @dev Distributes to the assigned producer wallet, with remaining funds going to the grt royalty wallet
  /// @dev Emits a {FundsDistributed} event for the receiver
  /// @dev Emits a {FundsDistributed} event for the royalties
  /// @dev Can only be called by PLATFORM_ADMIN role
  /// @param releaseId The id of the release for which the listing was made
  /// @param amount The amount of funds to distribute
  function distributeSecondaryFunds(uint128 releaseId, uint256 amount) external;

  /// @notice Getter for specific bit in hasBid bitmap
  /// @param tokenId The token ID
  /// @return status Whether or not the token has a bid
  function hasBid(uint128 tokenId) external view returns (bool status);

  /// @notice Getter for specific bit in hasSold bitmap
  /// @param tokenId The token ID
  /// @return  status Whether or not the token has sold
  function hasSold(uint128 tokenId) external view returns (bool status);

  //################################
  //#### AUTO-GENERATED GETTERS ####
  function releaseCounter() external returns (uint128 currentValue);

  function listingCounter() external returns (uint128 currentValue);

  /// @notice Setter for setting the redemption manager.
  /// @dev sets the address for the redemption manager so that calls to the Redemption Manager can be made.
  /// @param _redemptionManager the address of the redemption manager.
  function setRedemptionManager(address _redemptionManager) external;

  /// @notice Setter for setting the royalty distributor.
  /// @dev sets the address for the redemption manager so that calls to the Redemption Manager can be made.
  /// @param _royaltyDistributor the address of the royalty distributor.
  function setRoyaltyDistributor(address _royaltyDistributor) external;

  /// @notice Setter for the GRT Royalty Walet address
  /// @dev Sets the address for the wallet that receives royalties from token sales
  /// @param _royaltyWallet the address of the royalty wallet
  function setRoyaltyWallet(address _royaltyWallet) external;

  function releases(
    uint128 releaseId
  )
    external
    returns (
      uint128 listingId,
      uint128 startTokenId,
      uint128 endTokenId,
      uint8 listingType,
      uint16 producerPercentage,
      address producer
    );

  function pendingEth(uint128 listingId) external returns (uint256 pending);

  function liquidToken() external returns (ITokenContract tokenContract);

  function royaltyDistributor()
    external
    returns (IRoyaltyDistributor _royaltyDistributor);

  function redemptionManager()
    external
    returns (IRedemptionManager _redemptionManager);

  function swapContract() external returns (ISwap _swap);
}