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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/IInsuranceRegistry.sol";
import "../interfaces/ITokenRegistry.sol";
import "./IGrtWines.sol";

/// @title TokenContract
/// @author Developed by Labrys on behalf of GRT Wines
/// @custom:contributor Sean L (slongdotexe)
/// @custom:contributor mfbevan (mfbevan.eth)
/// @custom:contributor Brodie S
/// @notice Implementation to be used for the Liquid and Redeemed editions of each token
/// @dev  The GRT Wines architecture uses a dual ERC721 token system. When releases are created the `LiquidToken`
///       is minted and can be purchased through various listing mechanisms via the Drop Manager. When a user
///       wishes to redeem their token for a physical asset, the `LiquidToken` is burned, and a `RedeemedToken` is
///       minted. The same `TokenContract` implementation is deployed twice, once for each edition. The metadata
///       for both the Liquid and Redeemed editions of each token is set when a release is created, and manage by
///       the `TokenRegistry`. Almost entirely stock ERC721 with the exception of externalised mint, burn and update
///       token URI functions which will be guarded by Open Zeppelin RBAC.
///       DEFAULT_ADMIN_ROLE is not utilised for any purpose other than being the admin for all other roles
interface ITokenContract is IGrtWines, IERC721 {
  //################
  //#### STRUCTS ####

  /// @dev Holds the arguments for a mint transaction
  /// @param to The account the token should be minted to
  struct MintArgs {
    address to;
  }

  /// @dev Holds the arguments necessary for minting tokens with a specific ID
  /// @param to The token ID to be locked
  /// @param tokenId The token ID to be minted
  struct MintWithIdArgs {
    address to;
    uint256 tokenId;
  }

  //################
  //#### ERRORS ####

  /// @dev Thrown if a transaction attempts to update the metadata for a token that has already had an update (locked)
  /// @param sender The sender of the transaction
  /// @param tokenId The tokenId that resulted in the error
  error TokenLocked(address sender, uint256 tokenId);

  /// @dev Thrown if an account attempts to transfer a token that has an insurance event AND msg.sender != redemptionManager
  /// @param tokenId The token ID the attempted to be transferred
  error InsuranceEventRegistered(uint256 tokenId);

  //###################
  //#### FUNCTIONS ####

  /// @notice External mint funciton for Tokens
  /// @dev Bulk mint one or more tokens via MintArgs array for gas efficency.
  /// @dev Only accessible to PLATFORM_ADMIN_ROLE or MINTER_ROLE
  /// @param receiver The address to receive the minted NFTs. This should be the DropManager
  /// @param qty The number of tokens to mint
  /// @param liquidUri The liquid token URI to set for the batch
  /// @param redeemedUri The redeemed token URI to set for the batch
  function mint(
    address receiver,
    uint128 qty,
    string memory liquidUri,
    string memory redeemedUri
  ) external returns (uint256 mintCount);

  /// @notice External mint function to allow minting token with an explicit ID
  /// @dev Bulk mint one or more tokens with an explicit ID - intended to be used by the RedemptionManager to maintain
  /// @dev Only accessible to MINTER_ROLE which should only be assigned to the RedemptionManager when this contract is deployed as the RedeemedToken
  /// @dev This does not set the metadata as it is assumed that the metadata will already have been set in the TokenRegistry on mint of the Liquid Token
  /// @param mintWithIdArgs - Array of MintWithIdArgs struct. See {MintWithIdArgs} for param docs
  function mintWithId(MintWithIdArgs[] calldata mintWithIdArgs) external;

  /// @notice External burn funciton
  /// @dev Only accessible to PLATFORM_ADMIN_ROLE or BURNER_ROLE
  /// @param tokens - Array of token IDs to burn
  function burn(uint256[] calldata tokens) external;

  /// @notice Change the metadata URI for a given token batch
  /// @dev Tokens may only be updated once
  /// @dev Only accessible to PLATFORM_ADMIN_ROLE
  /// @param batchIndex The index of the batch to update in the tokenKeys array
  /// @param liquidUri The new liquid token URI to set
  /// @param redeemedUri The new redeemed token URI to set
  function changeTokenMetadata(
    uint256 batchIndex,
    string memory liquidUri,
    string memory redeemedUri
  ) external;

  /// @notice Lock the capability for a token to be updated
  /// @dev This behaves like a fuse and cannot be undone
  /// @dev Only accessible to PLATFORM_ADMIN_ROLE
  /// @param batchIndex The index of the batch to lock
  function lockTokenMetadata(uint256 batchIndex) external;

  /// @notice Set the insurance registry address
  /// @param _registryAddress The Address of the insurance registry
  function setInsuranceRegistry(address _registryAddress) external;

  /// @notice Set the redemption manager address
  /// @param _managerAddress The address of the redemption manager
  function setRedemptionManager(address _managerAddress) external;

  /// @notice Set the address and percentage of secondary market fees
  /// @param receiver The receiver wallet for the secondary market fees. This should be the address of the Royalty Distributor
  /// @param feeNumerator The fee percentage to send to the distributor, expressed in basis points
  function setSecondaryRoyalties(address receiver, uint96 feeNumerator)
    external;

  //#################
  //#### GETTERS ####

  function PLATFORM_ADMIN_ROLE() external returns (bytes32 role);

  function MINTER_ROLE() external returns (bytes32 role);

  function BURNER_ROLE() external returns (bytes32 role);

  /// @dev returns the locked status from the TokenRegistry
  function tokenLocked(uint256 tokenId) external view returns (bool hasUpdated);

  function insuranceRegistry()
    external
    returns (IInsuranceRegistry registryAddress);

  function tokenRegistry()
    external
    returns (ITokenRegistry tokenRegistryAddress);

  function redemptionManager() external returns (address managerAddress);
}