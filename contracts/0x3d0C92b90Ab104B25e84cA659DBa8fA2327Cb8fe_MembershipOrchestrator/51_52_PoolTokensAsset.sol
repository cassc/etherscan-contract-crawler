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
   * @dev this may revert if the credit line is late on payments, which results in the backerRewards
   *  withdraw call to revert. We purposefully do not attempt to handle this case, instead expecting
   *  the caller to decide what the best course of action is (eg: wait for the payment to be updated
   *  or handle it manually).
   */
  function harvest(Context context, address owner, uint256 assetTokenId) internal {
    IPoolTokens.TokenInfo memory tokenInfo = context.poolTokens().getTokenInfo(assetTokenId);
    ITranchedPool tranchedPool = ITranchedPool(tokenInfo.pool);

    if (!context.go().goOnlyIdTypes(owner, tranchedPool.getAllowedUIDTypes())) {
      revert NotGoListed(owner);
    }

    (uint256 interestWithdrawn, uint256 principalWithdrawn) = tranchedPool.withdrawMax(
      assetTokenId
    );
    uint256 totalWithdrawn = interestWithdrawn + principalWithdrawn;
    if (totalWithdrawn > 0) {
      context.usdc().safeTransfer(owner, totalWithdrawn);
    }

    // Sends reward to owner (this contract)
    uint256 rewards = context.backerRewards().withdraw(assetTokenId);
    if (rewards > 0) {
      context.gfi().safeTransfer(owner, rewards);
    }
  }
}