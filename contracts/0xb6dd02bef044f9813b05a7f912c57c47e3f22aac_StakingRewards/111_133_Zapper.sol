// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC721} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";

import {ISeniorPool} from "../../interfaces/ISeniorPool.sol";
import {IPoolTokens} from "../../interfaces/IPoolTokens.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";
import {IRequiresUID} from "../../interfaces/IRequiresUID.sol";
import {IStakingRewards, StakedPositionType} from "../../interfaces/IStakingRewards.sol";
import {Accountant} from "./Accountant.sol";
import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";

/// @title Zapper
/// @author Emily Hsia, Mark Hudnall, Will Johnston, Dalton Sweeney
/// @notice Moves capital from the SeniorPool to TranchedPools without taking fees
contract Zapper is BaseUpgradeablePausable {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;

  struct Zap {
    address owner;
    uint256 stakingPositionId;
  }

  /// @dev PoolToken.id => Zap
  mapping(uint256 => Zap) public tranchedPoolZaps;

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    require(
      owner != address(0) && address(_config) != address(0),
      "Owner and config addresses cannot be empty"
    );
    __BaseUpgradeablePausable__init(owner);
    config = _config;
  }

  /// @notice Zap multiple StakingRewards tokens to a tranched pool.
  /// @param stakingRewardsTokenIds ids of the StakingRewards ERC721 positions to zap. Token ids MUST be
  ///   sorted ascending.
  /// @param fiduAmounts FIDU amount to zap for each position such that `fiduAmounts[i]` FIDU
  ///   is zapped from position `tokenIds[i]`.
  /// @param tranchedPool address of the tranched pool to zap into.
  /// @param tranche id of the tranch to zap into.
  /// @return poolTokenIds PoolTokens ERC721 ids created by each zap action.
  function zapMultipleToTranchedPool(
    uint256[] calldata stakingRewardsTokenIds,
    uint256[] calldata fiduAmounts,
    ITranchedPool tranchedPool,
    uint256 tranche
  ) public whenNotPaused nonReentrant returns (uint256[] memory poolTokenIds) {
    require(stakingRewardsTokenIds.length == fiduAmounts.length, "Array size mismatch");

    poolTokenIds = new uint256[](stakingRewardsTokenIds.length);
    for (uint256 i = 0; i < stakingRewardsTokenIds.length; ++i) {
      if (i > 0 && stakingRewardsTokenIds[i] <= stakingRewardsTokenIds[i - 1]) {
        revert("Token ids not sorted");
      }
      poolTokenIds[i] = _zapFiduAmountToTranchedPool(
        stakingRewardsTokenIds[i],
        tranchedPool,
        tranche,
        fiduAmounts[i]
      );
    }

    return poolTokenIds;
  }

  /// @notice Unzap multiple pool tokens (not necessarily from the same tranched pools).
  ///   You may perform this action anytime before the respective tranche locks.
  /// @param poolTokenIds PoolTokens ERC721 ids to unzap. Token ids MUST be sorted ascending.
  ///   The caller MUST be the address that performed the initial zaps.
  function unzapMultipleFromTranchedPools(
    uint256[] calldata poolTokenIds
  ) public whenNotPaused nonReentrant {
    for (uint256 i = 0; i < poolTokenIds.length; ++i) {
      if (i > 0 && poolTokenIds[i] <= poolTokenIds[i - 1]) {
        revert("Token ids not sorted");
      }
      _unzapToStakingRewards(poolTokenIds[i]);
    }
  }

  /// @notice Claim multiple pool tokens (not necessarily from the same tranched pools). A claim
  ///   only succeeds if the tranched pool has locked.
  /// @param poolTokenIds PoolTokens ERC721 ids to claim. Token ids MUST be sorted ascending.
  ///   The caller MUST be the address that performed the initial zaps.
  function claimMultipleTranchedPoolZaps(
    uint256[] calldata poolTokenIds
  ) public whenNotPaused nonReentrant {
    for (uint256 i = 0; i < poolTokenIds.length; ++i) {
      if (i > 0 && poolTokenIds[i] <= poolTokenIds[i - 1]) {
        revert("Token ids not sorted");
      }
      _claimTranchedPoolZap(poolTokenIds[i]);
    }
  }

  /// @notice Zap staked FIDU into the junior tranche of a TranchedPool without losing
  ///   unvested rewards or paying a withdrawal fee. This function is preferred over
  ///   `zapStakeToTranchedPool` for zapping an entire position because the latter
  ///   accepts a USDC amount, which cannot precisely represent FIDU due to lack of decimals.
  /// @dev The minted pool token is held by this contract until either `claimZap` or
  ///   `unzap` is called.
  /// @param tokenId StakingRewards ERC721 token id to zap.
  /// @param tranchedPool TranchedPool to deposit into.
  /// @param tranche id of the tranche to deposit into.
  /// @param fiduAmount amount to deposit in FIDU.
  /// @return poolTokenId PoolTokens ERC721 id of the TranchedPool deposit.
  function zapFiduStakeToTranchedPool(
    uint256 tokenId,
    ITranchedPool tranchedPool,
    uint256 tranche,
    uint256 fiduAmount
  ) public whenNotPaused nonReentrant returns (uint256 poolTokenId) {
    return _zapFiduAmountToTranchedPool(tokenId, tranchedPool, tranche, fiduAmount);
  }

  /// @notice Zap staked FIDU into the junior tranche of a TranchedPool without losing
  ///   unvested rewards or paying a withdrawal fee
  /// @dev The minted pool token is held by this contract until either `claimZap` or
  ///   `unzap` is called
  /// @param tokenId A staking position token ID. The owner MUST perform an ERC721 approval
  /// @param tranchedPool TranchedPool to deposit into.
  /// @param tranche id of the tranche to deposit into.
  /// @param usdcAmount The USDC amount to deposit.
  /// @return poolTokenId PoolTokens ERC721 id of the TranchedPool deposit.
  ///   for the Zapper address before calling this function.
  function zapStakeToTranchedPool(
    uint256 tokenId,
    ITranchedPool tranchedPool,
    uint256 tranche,
    uint256 usdcAmount
  ) public whenNotPaused nonReentrant returns (uint256 poolTokenId) {
    return _zapUsdcAmountToTranchedPool(tokenId, tranchedPool, tranche, usdcAmount);
  }

  /// @notice Claim the underlying PoolToken for a zap initiated with `zapStakeToTranchePool`.
  ///  The pool token will be transferred to msg.sender if msg.sender initiated the zap and
  ///  we are past the tranche's lockedUntil time.
  /// @param poolTokenId The underyling PoolToken id created in a previously initiated zap
  function claimTranchedPoolZap(uint256 poolTokenId) public whenNotPaused nonReentrant {
    _claimTranchedPoolZap(poolTokenId);
  }

  /// @notice Unwind a zap initiated with `zapStakeToTranchePool`.
  ///  The funds will be withdrawn from the TranchedPool and added back to the original
  ///  staked position in StakingRewards. This method can only be called when the PoolToken's
  ///  tranche has never been locked.
  /// @param poolTokenId The underyling PoolToken id created in a previously initiated zap
  function unzapToStakingRewards(uint256 poolTokenId) public whenNotPaused nonReentrant {
    _unzapToStakingRewards(poolTokenId);
  }

  /// @notice Zap staked FIDU into staked Curve LP tokens without losing unvested rewards
  ///  or paying a withdrawal fee.
  /// @param tokenId A staking position token ID
  /// @param fiduAmount The amount in FIDU from the staked position to zap
  /// @param usdcAmount The amount of USDC to deposit into Curve
  function zapStakeToCurve(
    uint256 tokenId,
    uint256 fiduAmount,
    uint256 usdcAmount
  ) public whenNotPaused nonReentrant {
    IStakingRewards stakingRewards = config.getStakingRewards();
    require(IERC721(address(stakingRewards)).ownerOf(tokenId) == msg.sender, "Not token owner");

    uint256 stakedBalance = stakingRewards.stakedBalanceOf(tokenId);
    require(fiduAmount > 0, "Cannot zap 0 FIDU");
    require(fiduAmount <= stakedBalance, "cannot unstake more than staked balance");

    stakingRewards.unstake(tokenId, fiduAmount);

    SafeERC20.safeApprove(config.getFidu(), address(stakingRewards), fiduAmount);

    if (usdcAmount > 0) {
      SafeERC20.safeTransferFrom(config.getUSDC(), msg.sender, address(this), usdcAmount);
      SafeERC20.safeApprove(config.getUSDC(), address(stakingRewards), usdcAmount);
    }

    stakingRewards.depositToCurveAndStakeFrom(msg.sender, fiduAmount, usdcAmount);

    // Require that the allowances for both FIDU and USDC are reset to zero after
    // at the end of the transaction. `safeApprove` will fail on subsequent invocations
    // if any "dust" is left behind.
    require(
      config.getFidu().allowance(address(this), address(stakingRewards)) == 0,
      "Entire allowance of FIDU has not been used."
    );
    require(
      config.getUSDC().allowance(address(this), address(stakingRewards)) == 0,
      "Entire allowance of USDC has not been used."
    );
  }

  /// @notice See `unzapToStakingRewards`
  function _unzapToStakingRewards(uint256 poolTokenId) internal {
    Zap storage zap = tranchedPoolZaps[poolTokenId];

    require(zap.owner == msg.sender, "Not zap owner");

    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(poolTokenId);
    ITranchedPool tranchedPool = ITranchedPool(tokenInfo.pool);
    ITranchedPool.TrancheInfo memory trancheInfo = tranchedPool.getTranche(tokenInfo.tranche);

    require(trancheInfo.lockedUntil == 0, "Tranche locked");

    (uint256 interestWithdrawn, uint256 principalWithdrawn) = tranchedPool.withdrawMax(poolTokenId);
    require(interestWithdrawn == 0, "Invalid state");
    require(principalWithdrawn > 0, "Invalid state");

    ISeniorPool seniorPool = config.getSeniorPool();
    SafeERC20.safeApprove(config.getUSDC(), address(seniorPool), principalWithdrawn);
    uint256 fiduAmount = seniorPool.deposit(principalWithdrawn);

    IStakingRewards stakingRewards = config.getStakingRewards();
    SafeERC20.safeApprove(config.getFidu(), address(stakingRewards), fiduAmount);
    stakingRewards.addToStake(zap.stakingPositionId, fiduAmount);

    // Require that the allowances for both FIDU and USDC are reset to zero
    // at the end of the transaction. `safeApprove` will fail on subsequent invocations
    // if any "dust" is left behind.
    require(
      config.getUSDC().allowance(address(this), address(seniorPool)) == 0,
      "Entire allowance of USDC has not been used."
    );
    require(
      config.getFidu().allowance(address(this), address(stakingRewards)) == 0,
      "Entire allowance of FIDU has not been used."
    );
  }

  /// @notice See `claimTranchedPoolZap`
  function _claimTranchedPoolZap(uint256 poolTokenId) internal {
    Zap storage zap = tranchedPoolZaps[poolTokenId];

    require(zap.owner == msg.sender, "Not zap owner");

    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(poolTokenId);
    ITranchedPool.TrancheInfo memory trancheInfo = ITranchedPool(tokenInfo.pool).getTranche(
      tokenInfo.tranche
    );

    require(
      trancheInfo.lockedUntil != 0 && block.timestamp > trancheInfo.lockedUntil,
      "Zap locked"
    );

    IERC721(address(poolTokens)).safeTransferFrom(address(this), msg.sender, poolTokenId);
  }

  /// @notice See zapStakeToTranchedPool
  function _zapUsdcAmountToTranchedPool(
    uint256 tokenId,
    ITranchedPool tranchedPool,
    uint256 tranche,
    uint256 usdcAmount
  ) internal returns (uint256 poolTokenId) {
    IStakingRewards stakingRewards = config.getStakingRewards();
    ISeniorPool seniorPool = config.getSeniorPool();

    require(_validPool(tranchedPool), "Invalid pool");
    require(IERC721(address(stakingRewards)).ownerOf(tokenId) == msg.sender, "Not token owner");
    require(_hasAllowedUID(tranchedPool), "Address not go-listed");
    require(
      stakingRewards.getPosition(tokenId).positionType == StakedPositionType.Fidu,
      "Bad positionType"
    );

    uint256 shares = seniorPool.getNumShares(usdcAmount);
    stakingRewards.unstake(tokenId, shares);

    uint256 withdrawnAmount = seniorPool.withdraw(usdcAmount);
    require(withdrawnAmount == usdcAmount, "Withdrawn amount != requested amount");

    SafeERC20.safeApprove(config.getUSDC(), address(tranchedPool), usdcAmount);
    poolTokenId = tranchedPool.deposit(tranche, usdcAmount);

    tranchedPoolZaps[poolTokenId] = Zap(msg.sender, tokenId);

    // Require that the tranched pool's allowance for USDC is reset to zero
    // at the end of the transaction. `safeApprove` will fail on subsequent invocations
    // if any "dust" is left behind.
    require(
      config.getUSDC().allowance(address(this), address(tranchedPool)) == 0,
      "Entire allowance of USDC has not been used."
    );
  }

  /// @notice See zapFiduStakeToTranchedPool
  function _zapFiduAmountToTranchedPool(
    uint256 tokenId,
    ITranchedPool tranchedPool,
    uint256 tranche,
    uint256 fiduAmount
  ) internal returns (uint256 poolTokenId) {
    IStakingRewards stakingRewards = config.getStakingRewards();
    ISeniorPool seniorPool = config.getSeniorPool();

    require(_validPool(tranchedPool), "Invalid pool");
    require(IERC721(address(stakingRewards)).ownerOf(tokenId) == msg.sender, "Not token owner");
    require(_hasAllowedUID(tranchedPool), "Address not go-listed");
    require(
      stakingRewards.getPosition(tokenId).positionType == StakedPositionType.Fidu,
      "Bad positionType"
    );

    stakingRewards.unstake(tokenId, fiduAmount);
    uint256 withdrawnAmount = seniorPool.withdrawInFidu(fiduAmount);

    SafeERC20.safeApprove(config.getUSDC(), address(tranchedPool), withdrawnAmount);
    poolTokenId = tranchedPool.deposit(tranche, withdrawnAmount);

    tranchedPoolZaps[poolTokenId] = Zap(msg.sender, tokenId);

    // Require that the allowance for USDC is reset to zero after at the end of the transaction.
    // `safeApprove` will fail on subsequent invocations if any "dust" is left behind.
    require(
      config.getUSDC().allowance(address(this), address(tranchedPool)) == 0,
      "Entire allowance of USDC has not been used."
    );
  }

  function _hasAllowedUID(ITranchedPool pool) internal view returns (bool) {
    return IRequiresUID(address(pool)).hasAllowedUID(msg.sender);
  }

  function _validPool(ITranchedPool pool) internal view returns (bool) {
    return config.getPoolTokens().validPool(address(pool));
  }
}