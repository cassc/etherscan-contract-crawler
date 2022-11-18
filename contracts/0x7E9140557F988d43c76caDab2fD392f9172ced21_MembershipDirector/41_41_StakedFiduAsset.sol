// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "../../../../library/FiduConversions.sol";
import {Context} from "../../../../cake/Context.sol";
import "../../../../cake/Routing.sol" as Routing;

import {CapitalAssetType} from "../../../../interfaces/ICapitalLedger.sol";
import {IStakingRewards, StakedPositionType} from "../../../../interfaces/IStakingRewards.sol";
import {ISeniorPool} from "../../../../interfaces/ISeniorPool.sol";

using Routing.Context for Context;

library StakedFiduAsset {
  CapitalAssetType public constant AssetType = CapitalAssetType.ERC721;

  /**
   * @notice Get the type of asset that this contract adapts.
   * @return the asset type
   */
  function isType(Context context, address assetAddress) internal view returns (bool) {
    return assetAddress == address(context.stakingRewards());
  }

  /**
   * @notice Get whether or not the given asset is valid
   * @return true if the asset is Fidu type (not CurveLP)
   */
  function isValid(Context context, uint256 assetTokenId) internal view returns (bool) {
    return context.stakingRewards().getPosition(assetTokenId).positionType == StakedPositionType.Fidu;
  }

  /**
   * @notice Get the point-in-time USDC equivalent value of the ERC721 asset. This
   *  specifically attempts to return the "principle" or "at-risk" USDC value of
   *  the asset and does not include rewards, interest, or other benefits.
   * @param context goldfinch context for routing
   * @param assetTokenId id of the position to evaluate
   * @return USDC equivalent value
   */
  function getUsdcEquivalent(Context context, uint256 assetTokenId) internal view returns (uint256) {
    uint256 stakedFiduBalance = context.stakingRewards().stakedBalanceOf(assetTokenId);
    return FiduConversions.fiduToUsdc(stakedFiduBalance, context.seniorPool().sharePrice());
  }
}