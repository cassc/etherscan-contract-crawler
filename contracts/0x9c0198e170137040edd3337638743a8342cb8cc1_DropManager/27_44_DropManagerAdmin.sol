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
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "../interfaces/IDropManagerAdmin.sol";
import "../interfaces/IGrtWines.sol";
import "../interfaces/IListing.sol";
import "../libraries/GrtLibrary.sol";

/// @title Drop Manager Admin
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor Sean L (slongdotexe)
/// @custom:contributor mfbevan (mfbevan.eth)
/// @notice Provides admin functionality to the Drop Manager for the GRT Wines platform
contract DropManagerAdmin is IDropManagerAdmin, IGrtWines, AccessControl {
  using BitMaps for BitMaps.BitMap;
  bytes32 public constant override PLATFORM_ADMIN_ROLE =
    keccak256("PLATFORM_ADMIN_ROLE");

  bool public override allListingsPaused = false;

  // Bitmap of listings that are current paused
  BitMaps.BitMap internal pausedListings;

  // Listing type ID  => listing contract instance
  mapping(uint8 => IListing) public override listingRegistry;
  // Listing contract address => Listing type ID
  mapping(address => uint8) public override addressListingLookup;

  constructor(address superUser) {
    GrtLibrary.checkZeroAddress(superUser, "super user");
    _grantRole(DEFAULT_ADMIN_ROLE, superUser);
  }

  /// @dev Set the status of all listings to {status}
  /// @param status The new status to set
  function _changeAllPause(bool status) internal {
    if (allListingsPaused == status) {
      revert ListingStatusAlreadySet();
    }
    allListingsPaused = status;
    emit AllListingStatusChanged(msg.sender, status);
  }

  function registerListingType(uint8 listingType, address listingContract)
    external
    onlyRole(PLATFORM_ADMIN_ROLE)
  {
    GrtLibrary.checkZeroAddress(listingContract, "listing contract");
    if (address(listingRegistry[listingType]) != address(0)) {
      revert ListingIdTaken();
    }
    listingRegistry[listingType] = IListing(listingContract);
    addressListingLookup[listingContract] = listingType;
    emit ListingTypeCreated(listingContract, listingType);
  }

  function pauseListing(uint128 listingId)
    external
    onlyRole(PLATFORM_ADMIN_ROLE)
  {
    if (pausedListings.get(listingId) == true) {
      revert ListingStatusAlreadySet();
    }
    pausedListings.setTo(listingId, true);
    emit ListingStatusChanged(listingId, true);
  }

  function unpauseListing(uint128 listingId)
    external
    onlyRole(PLATFORM_ADMIN_ROLE)
  {
    if (pausedListings.get(listingId) == false) {
      revert ListingStatusAlreadySet();
    }
    pausedListings.setTo(listingId, false);
    emit ListingStatusChanged(listingId, false);
  }

  function listingPauseStatus(uint128 listingId)
    external
    view
    returns (bool status)
  {
    status = pausedListings.get(listingId);
  }

  function pauseAllListings() external onlyRole(PLATFORM_ADMIN_ROLE) {
    _changeAllPause(true);
  }

  function unpauseAllListings() external onlyRole(PLATFORM_ADMIN_ROLE) {
    _changeAllPause(false);
  }
}