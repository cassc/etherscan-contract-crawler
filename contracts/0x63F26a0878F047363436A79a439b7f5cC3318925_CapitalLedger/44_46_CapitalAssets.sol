// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";

import {Context} from "../../../../cake/Context.sol";
import {CapitalAssetType} from "../../../../interfaces/ICapitalLedger.sol";
import "../../../../cake/Routing.sol" as Routing;

/// @dev Adding a New Asset Type
/// 1. Create a new library in this directory of the name <AssetType>Asset.sol
/// 2. The library must implement the same functions as the other assets:
///   2.1 AssetType
///   2.2 isType
///   2.3 isValid - if the asset is an ERC721
///   2.4 getUsdcEquivalent
/// 3. Import the library below in "Supported assets"
/// 4. Add the new library to the corresponding `getSupportedType` function in this file
/// 5. Add the new library to the corresponding `getUsdcEquivalent` function in this file
/// 6. If the new library is an ERC721, add it to the `isValid` function in this file

// Supported assets
import {PoolTokensAsset} from "./PoolTokensAsset.sol";
import {StakedFiduAsset} from "./StakedFiduAsset.sol";

using Routing.Context for Context;

library CapitalAssets {
  /// Thrown when an asset has been requested that does not exist
  error InvalidAsset(address assetAddress);
  /// Thrown when an asset has been requested that does not exist
  error InvalidAssetWithId(address assetAddress, uint256 assetTokenId);

  /**
   * @notice Check if a specific `assetAddress` has a corresponding capital asset
   *  implementation and returns the asset type. Returns INVALID if no
   *  such asset exists.
   * @param context goldfinch context for routing
   * @param assetAddress the address of the asset's contract
   * @return type of the asset
   */
  function getSupportedType(
    Context context,
    address assetAddress
  ) internal view returns (CapitalAssetType) {
    if (StakedFiduAsset.isType(context, assetAddress)) return StakedFiduAsset.AssetType;
    if (PoolTokensAsset.isType(context, assetAddress)) return PoolTokensAsset.AssetType;

    return CapitalAssetType.INVALID;
  }

  //////////////////////////////////////////////////////////////////
  // ERC721

  /**
   * @notice Check if a specific token for a supported asset is valid or not. Returns false
   *  if the asset is not supported or the token is invalid
   * @param context goldfinch context for routing
   * @param assetAddress the address of the asset's contract
   * @param assetTokenId the token id
   * @return whether or not a specific token id of asset address is supported
   */
  function isValid(
    Context context,
    address assetAddress,
    uint256 assetTokenId
  ) internal view returns (bool) {
    if (StakedFiduAsset.isType(context, assetAddress))
      return StakedFiduAsset.isValid(context, assetTokenId);
    if (PoolTokensAsset.isType(context, assetAddress))
      return PoolTokensAsset.isValid(context, assetTokenId);

    return false;
  }

  /**
   * @notice Get the point-in-time USDC equivalent value of the ERC721 asset. This
   *  specifically attempts to return the "principle" or "at-risk" USDC value of
   *  the asset and does not include rewards, interest, or other benefits.
   * @param context goldfinch context for routing
   * @param asset ERC721 to evaluate
   * @param assetTokenId id of the token to evaluate
   * @return USDC equivalent value
   */
  function getUsdcEquivalent(
    Context context,
    IERC721Upgradeable asset,
    uint256 assetTokenId
  ) internal view returns (uint256) {
    if (PoolTokensAsset.isType(context, address(asset))) {
      return PoolTokensAsset.getUsdcEquivalent(context, assetTokenId);
    }

    if (StakedFiduAsset.isType(context, address(asset))) {
      return StakedFiduAsset.getUsdcEquivalent(context, assetTokenId);
    }

    revert InvalidAsset(address(asset));
  }

  /**
   * @notice Harvests the associated rewards, interest, and other accrued assets
   *  associated with the asset token. For example, if given a PoolToken asset,
   *  this will collect the GFI rewards (if available), redeemable interest, and
   *  redeemable principal, and send that to the `owner`.
   * @param context goldfinch context for routing
   * @param owner address to send the harvested assets to
   * @param asset ERC721 to harvest
   * @param assetTokenId id of the token to harvest
   */
  function harvest(
    Context context,
    address owner,
    IERC721Upgradeable asset,
    uint256 assetTokenId
  ) internal {
    if (PoolTokensAsset.isType(context, address(asset))) {
      return PoolTokensAsset.harvest(context, owner, assetTokenId);
    }

    if (StakedFiduAsset.isType(context, address(asset))) {
      return StakedFiduAsset.harvest(context, owner, assetTokenId);
    }

    revert InvalidAsset(address(asset));
  }
}