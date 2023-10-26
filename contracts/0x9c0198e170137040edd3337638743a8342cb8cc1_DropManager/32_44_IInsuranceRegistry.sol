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

/// @title GRT Wines Insurance Registry
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor Sean L (slongdotexe)
/// @notice External registry contract for tracking if a Token (bottle of wine) has been damaged and thus should
///         not be able to be transferred to another user
/// @dev    Extended Bitmaps library is utilised to provide a gas efficent mechanism for rapidly manipulating large
//          quantities of boolean statuses. It is assumed that the structure of the Bitmap will be reliably calculated off-chain
interface IInsuranceRegistry is IGrtWines {
  //################
  //#### STRUCTS ####

  /// @notice Data structure for registering an insurance event
  /// @param firstAffectedToken The first affected token, this allows us to easily set each bucket'
  /// @param affectedTokens Bitmap of tokens that are void
  struct InsuranceEvent {
    uint256 firstAffectedToken;
    uint256[] affectedTokens;
  }

  //################
  //#### EVENTS ####
  event InsuranceEventRegistered(
    uint256 firstAffectedToken,
    uint256[] affectedTokens
  );

  //###################
  //#### FUNCTIONS ####

  /// @notice Create an insurance event
  /// @dev It is assumed that the bitmap has been adequately generated off-chain
  /// @dev Emits InsuranceEventRegistered
  /// @param insuranceEvent Insurance event data
  function createInsuranceEvent(InsuranceEvent calldata insuranceEvent)
    external;

  /// @notice Check if a token has an insurance event registered
  /// @param _tokenId The token ID to check
  /// @return isTokenAffected If TRUE token has an insurance claim - transfers except to a RedemptionManager should revert.
  function checkTokenStatus(uint256 _tokenId)
    external
    view
    returns (bool isTokenAffected);

  //################################
  //#### AUTO-GENERATED GETTERS ####
  function PLATFORM_ADMIN_ROLE() external returns (bytes32 role);
}