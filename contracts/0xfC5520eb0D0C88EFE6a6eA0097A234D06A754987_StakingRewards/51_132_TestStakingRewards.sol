// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../rewards/StakingRewards.sol";

contract TestStakingRewards is StakingRewards {
  uint256 private constant MULTIPLIER_DECIMALS = 1e18;

  mapping(StakedPositionType => uint256) private exchangeRates;

  /// @dev Used in unit tests to mock the `unsafeEffectiveMultiplier` for a given position
  function _setPositionUnsafeEffectiveMultiplier(uint256 tokenId, uint256 newMultiplier) external {
    StakedPosition storage position = positions[tokenId];

    position.unsafeEffectiveMultiplier = newMultiplier;
  }

  /// @dev Copy of _stake, but with a valid vesting endtime
  function stakeWithVesting(
    address staker,
    address nftRecipient,
    uint256 amount,
    StakedPositionType positionType
  ) external nonReentrant whenNotPaused updateReward(0) returns (uint256 tokenId) {
    /// @dev ZERO: Cannot stake 0
    require(amount > 0, "ZERO");

    _tokenIdTracker.increment();
    tokenId = _tokenIdTracker.current();

    // Ensure we snapshot accumulatedRewardsPerToken for tokenId after it is available
    // We do this before setting the position, because we don't want `earned` to (incorrectly) account for
    // position.amount yet. This is equivalent to using the updateReward(msg.sender) modifier in the original
    // synthetix contract, where the modifier is called before any staking balance for that address is recorded
    _updateReward(tokenId);

    uint256 baseTokenExchangeRate = getBaseTokenExchangeRate(positionType);
    uint256 effectiveMultiplier = getEffectiveMultiplierForPositionType(positionType);

    positions[tokenId] = StakedPosition({
      positionType: positionType,
      amount: amount,
      rewards: Rewards({
        totalUnvested: 0,
        totalVested: 0,
        totalPreviouslyVested: 0,
        totalClaimed: 0,
        startTime: block.timestamp,
        endTime: block.timestamp.add(100)
      }),
      unsafeBaseTokenExchangeRate: baseTokenExchangeRate,
      unsafeEffectiveMultiplier: effectiveMultiplier,
      leverageMultiplier: 0,
      lockedUntil: 0
    });
    _mint(nftRecipient, tokenId);

    uint256 effectiveAmount = _positionToEffectiveAmount(positions[tokenId]);
    totalStakedSupply = totalStakedSupply.add(effectiveAmount);

    // Staker is address(this) when using depositAndStake or other convenience functions
    if (staker != address(this)) {
      stakingToken(positionType).safeTransferFrom(staker, address(this), amount);
    }

    emit Staked(nftRecipient, tokenId, amount, positionType, baseTokenExchangeRate);

    return tokenId;
  }

  function _getStakingAndRewardsTokenMantissa() public pure returns (uint256) {
    return stakingAndRewardsTokenMantissa();
  }

  function _getFiduStakingTokenMantissa() public view returns (uint256) {
    return uint256(10)**IERC20withDec(address(stakingToken(StakedPositionType.Fidu))).decimals();
  }

  function _getCurveLPStakingTokenMantissa() public view returns (uint256) {
    return uint256(10)**IERC20withDec(address(stakingToken(StakedPositionType.CurveLP))).decimals();
  }

  function _getRewardsTokenMantissa() public view returns (uint256) {
    return uint256(10)**rewardsToken().decimals();
  }
}