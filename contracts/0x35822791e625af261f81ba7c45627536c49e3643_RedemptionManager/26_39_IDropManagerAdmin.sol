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

import "./IListing.sol";

/// @title Drop Manager Admin
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor Sean L (slongdotexe)
/// @custom:contributor mfbevan (mfbevan.eth)
/// @notice Provides admin functionality to the Drop Manager for the GRT Wines platform
interface IDropManagerAdmin {
  //################
  //#### EVENTS ####

  /// @dev Emitted when a listing type is created
  /// @param listingAddress The address of the listing contract
  /// @param listingType The ID to assign to the listing
  event ListingTypeCreated(
    address indexed listingAddress,
    uint8 indexed listingType
  );

  /// @dev Emitted when the status of a listing is paused / unpaused
  /// @param listingType The ID of the listing that had it's status changed
  /// @param status The status the listing was changed to
  event ListingStatusChanged(uint128 indexed listingType, bool status);

  /// @dev Emitted when all listings are globally paused / unpaused
  /// @param sender The sender of the transaction
  /// @param status The status that the global pause / unpause was changed to
  event AllListingStatusChanged(address indexed sender, bool status);

  //################
  //#### ERRORS ####

  /// @dev Thrown if the specific listing being accessed, or all listings are paused
  error ListingPaused();
  /// @dev Thrown if the listing ID has been taken by an existing implementaiton
  error ListingIdTaken();
  /// @dev Thrown if changing the pause status is a redundant call
  error ListingStatusAlreadySet();

  //###################
  //#### FUNCTIONS ####

  /// @notice Use to register a listing type logic contract
  /// @dev IDs are not sequential and it is assumed that the sender of this transaction has some intelligence around how they use this
  /// @param listingType The ID of the listing type to be created
  /// @param listingContract The address of the listing contract
  function registerListingType(uint8 listingType, address listingContract)
    external;

  /// @notice Pause a specific listing
  /// @dev Specific pause function so that this operation is idempotent
  /// @param listingId The ID of the listing to pause
  function pauseListing(uint128 listingId) external;

  /// @notice Unpause a specific listing
  /// @dev Specific unpause function so that this operation is idempotent
  /// @param listingId The ID of the listing to unpause
  function unpauseListing(uint128 listingId) external;

  /// @notice Pause all listings
  /// @dev Specific pause function so that this operation is idempotent
  function pauseAllListings() external;

  /// @notice Unpause all listings
  /// @dev Specific unpause function so that this operation is idempotent
  function unpauseAllListings() external;

  //################################
  //#### AUTO-GENERATED GETTERS ####

  function allListingsPaused() external returns (bool);

  function listingRegistry(uint8) external returns (IListing);

  function addressListingLookup(address) external returns (uint8);

  function PLATFORM_ADMIN_ROLE() external returns (bytes32);
}