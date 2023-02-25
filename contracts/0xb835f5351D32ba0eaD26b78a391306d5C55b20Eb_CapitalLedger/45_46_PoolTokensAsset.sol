// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import {Context} from "../../../../cake/Context.sol";
import "../../../../cake/Routing.sol" as Routing;

import {CapitalAssetType} from "../../../../interfaces/ICapitalLedger.sol";
import {IPoolTokens} from "../../../../interfaces/IPoolTokens.sol";

import {ITranchedPool} from "../../../../interfaces/ITranchedPool.sol";

using Routing.Context for Context;
using SafeERC20 for IERC20Upgradeable;

library PoolTokensAsset {
  /// Thrown when trying to harvest a pool token when not go-listed
  error NotGoListed(address owner);

  CapitalAssetType public constant AssetType = CapitalAssetType.ERC721;

  /**
   * @notice Get the type of asset that this contract adapts.
   * @return the asset type
   */
  function isType(Context context, address assetAddress) internal view returns (bool) {
    return assetAddress == address(context.poolTokens());
  }

  /**
   * @notice Get whether or not the given asset is valid
   * @return true if the represented tranche is or may be drawn down (so true if assets are doing work)
   */
  function isValid(Context context, uint256 assetTokenId) internal view returns (bool) {
    IPoolTokens.TokenInfo memory tokenInfo = context.poolTokens().getTokenInfo(assetTokenId);
    ITranchedPool tranchedPool = ITranchedPool(tokenInfo.pool);

    return tranchedPool.getTranche(tokenInfo.tranche).lockedUntil != 0;
  }

  /**
   * @notice Get the point-in-time USDC equivalent value of the Pool Token asset. This
   *  specifically attempts to return the "principle" or "at-risk" USDC value of
   *  the asset and does not include rewards, interest, or other benefits.
   * @param context goldfinch context for routing
   * @param assetTokenId tokenId of the Pool Token to evaluate
   * @return USDC equivalent value
   */
  function getUsdcEquivalent(
    Context context,
    uint256 assetTokenId
  ) internal view returns (uint256) {
    IPoolTokens.TokenInfo memory tokenInfo = context.poolTokens().getTokenInfo(assetTokenId);
    return tokenInfo.principalAmount - tokenInfo.principalRedeemed;
  }

  /**
   * @notice Harvest GFI rewards and redeemable interest and principal on PoolToken with id
   *  `assetTokenId` and send the harvested assets to `owner`.
   * @param context goldfinch context for routing
   * @param owner address to send the harvested assets to
   * @param assetTokenId id of the position to harvest
   */
  function harvest(Context context, address owner, uint256 assetTokenId) internal {
    IPoolTokens.TokenInfo memory tokenInfo = context.poolTokens().getTokenInfo(assetTokenId);
    ITranchedPool tranchedPool = ITranchedPool(tokenInfo.pool);

    if (!context.go().goOnlyIdTypes(owner, getAllowedUIDs(tokenInfo.pool))) {
      revert NotGoListed(owner);
    }

    (uint256 interestWithdrawn, uint256 principalWithdrawn) = tranchedPool.withdrawMax(
      assetTokenId
    );
    context.usdc().safeTransfer(owner, interestWithdrawn + principalWithdrawn);

    try context.backerRewards().withdraw(assetTokenId) returns (uint256 rewards) {
      // Withdraw can throw if the pool is late or if it's an early pool and doesn't
      // have associated backer rewards. Try/catch so the interest and principal can
      // still be harvested.

      context.gfi().safeTransfer(owner, rewards);
    } catch {}
  }

  function getAllowedUIDs(address poolAddress) private view returns (uint256[] memory allowedUIDs) {
    // TranchedPools are non-upgradeable and have different capabilites. One of the differences
    // is the `getAllowedUIDTypes` function, which is only available in contracts deployed from
    // Nov 2022 onward. To get around this limitation, we hardcode the expected UID requirements
    // based on the pool address for previous contracts. Otherwise, we use the available method.
    // Pools below are listed in chronological order for convenience.

    if (
      poolAddress == 0xefeB69eDf6B6999B0e3f2Fa856a2aCf3bdEA4ab5 || // almavest 3
      poolAddress == 0xaA2ccC5547f64C5dFfd0a624eb4aF2543A67bA65 || // tugende
      poolAddress == 0xc9BDd0D3B80CC6EfE79a82d850f44EC9B55387Ae || // cauris
      poolAddress == 0xe6C30756136e07eB5268c3232efBFBe645c1BA5A || // almavest 4
      poolAddress == 0x1d596D28A7923a22aA013b0e7082bbA23DAA656b // almavest 5
    ) {
      // Legacy pools that had custom checks upon signup

      allowedUIDs = new uint256[](1);
      allowedUIDs[0] = 0;
      return allowedUIDs;
    }

    if (poolAddress == 0x418749e294cAbce5A714EfcCC22a8AAde6F9dB57 /* almavest 6 */) {
      // Old pool that has internal UID check but does not provide a gas-efficient UID interface
      // Copied the pool's UID requirements below

      allowedUIDs = new uint256[](1);
      allowedUIDs[0] = 0;
      return allowedUIDs;
    }

    if (
      poolAddress == 0x00c27FC71b159a346e179b4A1608a0865e8A7470 || // stratos
      poolAddress == 0xd09a57127BC40D680Be7cb061C2a6629Fe71AbEf // cauris 2
    ) {
      // Old pools that have internal UID check but do not provide a gas-efficient UID interface
      // Copied the pools' UID requirements below

      allowedUIDs = new uint256[](2);
      allowedUIDs[0] = 0;
      allowedUIDs[1] = 1;
      return allowedUIDs;
    }

    if (
      poolAddress == 0xb26B42Dd5771689D0a7faEea32825ff9710b9c11 || // lend east 1
      poolAddress == 0x759f097f3153f5d62FF1C2D82bA78B6350F223e3 || // almavest 7
      poolAddress == 0x89d7C618a4EeF3065DA8ad684859a547548E6169 // addem capital
    ) {
      // Old pools that have internal UID check but do not provide a gas-efficient UID interface
      // Copied the pools' UID requirements below

      allowedUIDs = new uint256[](4);
      allowedUIDs[0] = 0;
      allowedUIDs[1] = 1;
      allowedUIDs[2] = 3;
      allowedUIDs[3] = 4;
      return allowedUIDs;
    }

    // All other and future pools implement getAllowedUIDTypes
    return ITranchedPool(poolAddress).getAllowedUIDTypes();
  }
}