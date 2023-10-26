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

/// @title Buy It Now
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor mfbevan (mfbevan.eth)
/// @custom:contributor Seb N
/// @notice A listing type involving a single token that can be bought instantly. If a users placed a bid with a high enough amount, they
///         will be the winner. The listing will continue until the timer runs out or there are not tokens left to buy.
interface IBuyItNow is IListing {
  //################
  //#### STRUCTS ####

  /// @dev Parameters for storing Buy It Now information for a given release.
  /// @param releaseId The identifier of the DropListing - provided by the DropManager
  /// @param startDate Start date/time (Unix time)
  /// @param endDate End date/time (Unix time)
  /// @param salePrice The price the listing will be sold for (Maps to the startingPrice in the Listing object)
  struct BINListing {
    uint128 releaseId;
    uint40 startDate;
    uint40 endDate;
    uint256 salePrice;
  }

  //################
  //#### ERRORS ####

  //Thrown if {endDate} is in the past or {startDate} is after end date
  error IncorrectParams(address sender);

  /// Listing ID => {BINListing}
  function listings(uint128 listingId)
    external
    returns (
      uint128 releaseId,
      uint40 startDate,
      uint40 endDate,
      uint256 salePrice
    );
}