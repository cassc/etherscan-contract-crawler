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

import "../implementations/TokenContract.sol";
import "./IGrtWines.sol";

/// @title GrtWines Redemption Manager Contract
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor Sean L (slongdotexe)
/// @custom:contributor mfbevan (mfbevan.eth)
/// @custom:contributor Seb N
/// @notice Used to manage the process of converting a Liquid Token (sitll in the Warehouse) to a Redeemed Token (Sent to the owner). User's may submit their token for redemption and the warehouse then either aborts or finalizes the redemption
/// @dev  This contract needs BURNER_ROLE on the Liquid Token contract and MINTER_ROLE on the Redeemed Token Contract
///       PLATFORM_ADMIN_ROLE and WAREHOUSE_MANAGER_ROLE are used to protect functions
///       DEFAULT_ADMIN_ROLE is not utilised for any purpose other than being the admin for all other roles
interface IRedemptionManager is IGrtWines {
  //################
  //#### STRUCTS ####

  //################
  //#### EVENTS ####
  /// @dev Emitted on successful redemption creation
  event RedemptionCreated(address indexed sender, uint256 indexed tokenId);

  /// @dev Emitted on successful redemption finalisation
  event RedemptionFinalised(address indexed sender, uint256 indexed tokenId);

  /// @dev Emitted on successful redemption finalisation
  event RedemptionAborted(address indexed sender, uint256 indexed tokenId);

  //################
  //#### ERRORS ####

  /// @dev Thrown if the sender attempts to deploy with {platformAdmin} and {superUser} set to the same address
  error AdminSuperUserMatch();

  /// @dev Thrown if the user does not posses the correct redeemable status.
  /// @param releaseId the release for which a redemption is being created.
  error RedeemableStatusIncorrect(uint256 releaseId);

  /// @dev Thrown if the user tries to set the timelock release date to before the current block time.
  /// @param releaseDate the release date which the token is redeemable from
  error ReleaseDateInvalid(uint256 releaseDate);

  //###################
  //#### FUNCTIONS ####
  /// @notice Utilised to create a redemption. Transfers the token to this contract as escrow and sets {originalOwners}
  /// @dev Account must {approveForAll} or {approve} for the specific token to redeeem
  /// @param tokenId - The token to be redeemed
  /// @param releaseId the release for which a redemption is being redeemed.
  function createRedemption(uint256 tokenId, uint256 releaseId) external;

  /// @notice Utilised to bulk finalise tokens
  /// @dev Account must have WAREHOUSE_MANAGER_ROLE to use
  /// @dev {createRedemption} must be called first. ERC721 0 address checks will fail if calling with tokens that haven't yet had a redemption created
  /// @param tokens - Array of tokens to finalise
  function finaliseRedemption(uint256[] calldata tokens) external;

  /// @notice Utilised to abort the redemption of a token
  /// @dev Account must have PLATFORM_ADMIN_ROLE to use
  /// @dev Returns the token to the original owner and deletes the value at {originalOwners}
  /// @param tokenId - Array of {FinaliseArgs} - see for more docs
  function abortRedemption(uint256 tokenId) external;

  /// @notice Utilised to set a time lock on the redemption of a token
  /// @dev Account must have PLATFORM_ADMIN_ROLE or DROP_MANAGER_ROLE to use
  /// @dev Sets the time value for a release in the timelock mapping in the Timelock contract
  /// @param releaseId - the release to update the timelock for.
  /// @param releaseDate - the date to set the timelock to.
  function setTimeLock(uint256 releaseId, uint256 releaseDate) external;

  //#################
  //#### GETTERS ####
  function PLATFORM_ADMIN_ROLE() external returns (bytes32 role);

  function WAREHOUSE_MANAGER_ROLE() external returns (bytes32 role);

  function DROP_MANAGER_ROLE() external returns (bytes32 role);

  function originalOwners(uint256 tokenId) external returns (address owner);

  function liquidToken() external returns (TokenContract implementation);

  function redeemedToken() external returns (TokenContract implementation);
}