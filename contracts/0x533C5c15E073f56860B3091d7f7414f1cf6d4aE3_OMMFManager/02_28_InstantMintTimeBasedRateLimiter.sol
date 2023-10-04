/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

/**
 * @title InstantMintTimeBasedRateLimiter
 *
 * @notice This abstract contract implements two rate limiters: one for minting
 *         and one for redeeming. Each limit is completely independent: mints
 *         and redemption don't offset each other. Each limit is associated
 *         with a duration, after which the tracked amount is reset. The
 *         amounts tracked are agnostic to a specific token; the usage is
 *         determined by the inheriting contracts.
 *
 * @dev Although this contract has all of its functions implemented, this
 *      contract is marked abstract to prevent an accidental deployment and to
 *      signify that we would never deploy this contract standalone.
 *
 */
abstract contract InstantMintTimeBasedRateLimiter {
  // `currentInstantMintAmount` resets after this interval (in seconds)
  uint256 public resetInstantMintDuration;
  // timestamp when `currentInstantMintAmount` was last reset
  uint256 public lastResetInstantMintTime;

  // maximum amount that can be minted during a `resetInstantMintDuration` window
  uint256 public instantMintLimit;
  // amount already minted during the current `resetInstantMintDuration` window
  uint256 public currentInstantMintAmount;

  // `currentInstantRedemptionAmount` resets after this interval (in seconds)
  uint256 public resetInstantRedemptionDuration;
  // timestamp when the `currentInstantRedemptionAmount` was last reset
  uint256 public lastResetInstantRedemptionTime;

  // maximum amount that can be redeemed during a `resetInstantRedemptionDuration` window
  uint256 public instantRedemptionLimit;
  // amount already redeemed during the current `resetInstantRedemptionDuration` window
  uint256 public currentInstantRedemptionAmount;

  /**
   * @notice In the constructor, we initialize the variables for the mint and
   *         redemption rate limiters.
   *
   * @param _instantMintResetDuration   `currentInstantMintAmount` resets after this interval
   *                                    (in seconds)
   * @param _instantRedemptionResetDuration `currentInstantRedemptionAmount` resets after this
   *                                    interval (in seconds)
   * @param _instantMintLimit           maximum amount that can be minted during a
   *                                    `resetInstantMintDuration` window
   * @param _instantRedemptionLimit     maximum amount that can be redeemed during a
   *                                    `resetInstantRedemptionDuration` window
   *
   * @dev If a duration is zero, the limit resets before each mint/redemption.
   * @dev If a limit is zero, the relevant check always fails.
   */
  constructor(
    uint256 _instantMintResetDuration,
    uint256 _instantRedemptionResetDuration,
    uint256 _instantMintLimit,
    uint256 _instantRedemptionLimit
  ) {
    resetInstantMintDuration = _instantMintResetDuration; // can be zero for per-block limit
    resetInstantRedemptionDuration = _instantRedemptionResetDuration; // can be zero for per-block limit
    instantMintLimit = _instantMintLimit; // can be zero to disable minting
    instantRedemptionLimit = _instantRedemptionLimit; // can be zero to disable redemptions

    lastResetInstantMintTime = block.timestamp;
    lastResetInstantRedemptionTime = block.timestamp;
  }

  /**
   * @notice Checks the requested mint amount against the rate limiter (and
   *         updates the remaining amount)
   *
   * @param amount The requested mint amount
   *
   * @dev Reverts if the requested mint amount exceeds the current limit
   */
  function _checkAndUpdateInstantMintLimit(uint256 amount) internal {
    require(amount > 0, "RateLimit: mint amount can't be zero");

    if (
      block.timestamp >= lastResetInstantMintTime + resetInstantMintDuration
    ) {
      // time has passed, reset
      currentInstantMintAmount = 0;
      lastResetInstantMintTime = block.timestamp;
    }
    require(
      amount <= instantMintLimit - currentInstantMintAmount,
      "RateLimit: Mint exceeds rate limit"
    );

    currentInstantMintAmount += amount;
  }

  /**
   * @notice Checks the requested redemption amount against the rate limiter
   *         (and updates the remaining amount)
   *
   * @param amount The requested redemption amount
   *
   * @dev Reverts if the requested redemption amount exceeds the current
   *      limit
   */
  function _checkAndUpdateInstantRedemptionLimit(uint256 amount) internal {
    require(amount > 0, "RateLimit: redemption amount can't be zero");

    if (
      block.timestamp >=
      lastResetInstantRedemptionTime + resetInstantRedemptionDuration
    ) {
      // time has passed, reset
      currentInstantRedemptionAmount = 0;
      lastResetInstantRedemptionTime = block.timestamp;
    }
    require(
      amount <= instantRedemptionLimit - currentInstantRedemptionAmount,
      "RateLimit: Redemption exceeds rate limit"
    );
    currentInstantRedemptionAmount += amount;
  }

  /**
   * @notice Update the amount of token that can be minted during one duration
   *
   * @param _instantMintLimit The token amount
   *
   * @dev If a limit is zero, the relevant check always fails.
   */
  function _setInstantMintLimit(uint256 _instantMintLimit) internal {
    instantMintLimit = _instantMintLimit;
    emit InstantMintLimitSet(_instantMintLimit);
  }

  /**
   * @notice Update the amount of token that can be redeemed during one duration
   *
   * @param _redemptionLimit The token amount
   *
   * @dev If a limit is zero, the relevant check always fails.
   */
  function _setInstantRedemptionLimit(uint256 _redemptionLimit) internal {
    instantRedemptionLimit = _redemptionLimit;
    emit InstantRedemptionLimitSet(_redemptionLimit);
  }

  /**
   * @notice Update the duration for the mint rate limiter
   *
   * @param _instantMintResetDuration The duration in seconds
   *
   * @dev If a duration is zero, the limit resets before each mint/redemption
   */
  function _setInstantMintLimitDuration(
    uint256 _instantMintResetDuration
  ) internal {
    resetInstantMintDuration = _instantMintResetDuration;
    emit InstantMintLimitDurationSet(_instantMintResetDuration);
  }

  /**
   * @notice Update the duration for the redemption rate limiter
   *
   * @param _instantRedemptionResetDuration The duration in seconds
   *
   * @dev If a duration is zero, the limit resets before each mint/redemption
   */
  function _setInstantRedemptionLimitDuration(
    uint256 _instantRedemptionResetDuration
  ) internal {
    resetInstantRedemptionDuration = _instantRedemptionResetDuration;
    emit InstantRedemptionLimitDurationSet(_instantRedemptionResetDuration);
  }

  /**
   * @notice Event emitted when instant mint limit is set
   *
   * @param instantMintLimit How much of some token can be minted within
   *                  an interval of length `resetInstantMintDuration`
   *
   * @dev See inheriting contract for representation
   */
  event InstantMintLimitSet(uint256 instantMintLimit);

  /**
   * @notice Event emitted when instant redemption limit is set
   *
   * @param instantRedemptionLimit How much of some token can be redeemed within
   *                    an interval of length `resetInstantRedemptionDuration`
   *
   * @dev See inheriting contract for representation
   */
  event InstantRedemptionLimitSet(uint256 instantRedemptionLimit);

  /**
   * @notice Event emitted when mint limit duration is set
   *
   * @param instantMintLimitDuration The time window in which `instantMintLimit`
   *                          of some token can be minted
   *
   * @dev instantMintLimitDuration is specified in seconds
   */
  event InstantMintLimitDurationSet(uint256 instantMintLimitDuration);

  /**
   * @notice Event emitted when redemption limit duration is set
   *
   * @param redemptionLimitDuration The time window in which `instantRedemptionLimit`
   *                            of some token can be redeemed
   *
   * @dev redemptionLimitDuration is specified in seconds.
   */
  event InstantRedemptionLimitDurationSet(uint256 redemptionLimitDuration);
}