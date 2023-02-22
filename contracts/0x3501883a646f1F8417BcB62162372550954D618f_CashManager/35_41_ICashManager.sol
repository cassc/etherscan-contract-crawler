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

interface ICashManager {
  /// @notice Function called by user to request mint
  function requestMint(uint256 collateralIn) external;

  /// @notice Function called by the user to instantly mint
  function instantMint(uint256 collateralIn) external;

  /// @notice Function called by user when claiming minted CASH
  function claimMint(address user, uint256 epochToClaim) external;

  /// @notice Sets the ExchangeRate independent of checks
  function overrideExchangeRate(
    uint256 correctExchangeRate,
    uint256 epochToSet,
    uint256 _lastSetMintExchangeRate
  ) external;

  /// @notice Sets fee recipient
  function setFeeRecipient(address _feeRecipient) external;

  /// @notice Sets asset sender
  function setAssetSender(address newAssetSender) external;

  /// @notice Sets minimum deposit amount
  function setMinimumDepositAmount(uint256 _minimumDepositAmount) external;

  /// @notice Sets mint fee
  function setMintFee(uint256 _mintFee) external;

  /// @notice Sets mint exchange rate
  function setMintExchangeRate(
    uint256 _mintExchangeRate,
    uint256 epochToSet
  ) external;

  /// @notice Sets exchange rate delta limit
  function setMintExchangeRateDeltaLimit(
    uint256 _exchangeRateDeltaLimit
  ) external;

  /// @notice User signals redemption request
  function requestRedemption(uint256 amountSharesTokenToRedeem) external;

  /// @notice Asset senders fulfills redemption requests with `collateral` or
  ///         refund of CASH+
  function completeRedemptions(
    address[] calldata redeemers,
    address[] calldata refundees,
    uint256 collateralAmountToDist,
    uint256 epochToService,
    uint256 fees
  ) external;

  /// @notice Admin function used to set the instant mint percent
  function setInstantMintPercentBPS(uint256 newInstantMintBPS) external;

  /// @notice Admin function used to set the instant mint fee percent
  function setInstantMintFee(uint256 _instantMintFee) external;

  /// @notice Adming function used to claim excess `CASH` on behalf of a user
  function claimExcess(address addressToClaim, uint256 epochToClaim) external;

  /**
   * @notice Event emitted when fee recipient is set
   *
   * @param oldFeeRecipient Old fee recipient
   * @param newFeeRecipient New fee recipient
   */
  event FeeRecipientSet(address oldFeeRecipient, address newFeeRecipient);

  /**
   * @notice Event emitted when asset recipient is set
   *
   * @param oldAssetRecipient Old asset recipient
   * @param newAssetRecipient New asset recipient
   */
  event AssetRecipientSet(address oldAssetRecipient, address newAssetRecipient);

  /**
   * @notice Event emitted when the assetSender is changed
   *
   * @param oldAssetSender The address of the old assetSender
   * @param newAssetSender The address of the new assetSender
   */
  event AssetSenderSet(address oldAssetSender, address newAssetSender);

  /**
   * @notice Event emitted when minimum deposit amount is set
   *
   * @param oldMinimum Old minimum
   * @param newMinimum New minimum
   *
   * @dev See inheriting contract for decimals representation
   */
  event MinimumDepositAmountSet(uint256 oldMinimum, uint256 newMinimum);

  /**
   * @notice Event emitted when a new redeem minimum is set.
   *         All units are in 1e18
   *
   * @param oldRedeemMin The old redeem minimum value
   * @param newRedeemMin The new redeem minimum value
   */
  event MinimumRedeemAmountSet(uint256 oldRedeemMin, uint256 newRedeemMin);

  /**
   * @notice Event emitted when mint fee
   *
   * @param oldFee Old fee
   * @param newFee New fee
   *
   * @dev See inheriting contract for decimals representation
   */
  event MintFeeSet(uint256 oldFee, uint256 newFee);

  /**
   * @notice Event emitted when instant mint fee set
   *
   * @param oldFee The old instant minting fee
   * @param newFee The new instant minting fee
   */
  event InstantMintFeeSet(uint256 oldFee, uint256 newFee);

  /**
   * @notice Event emitted when exchange rate is set for
   *         `collateral()`:`cash()`
   *
   * @param epoch   Epoch in which the mint exchange rate was set
   * @param oldRate Previous exchange rate
   * @param newRate New exchange rate
   *
   * @dev `rate` is represented in 6 decimals.
   */
  event MintExchangeRateSet(
    uint256 indexed epoch,
    uint256 oldRate,
    uint256 newRate
  );

  /**
   * @notice Event emitted when exchange rate is overridden for a given epoch
   *         `collateral()`:`cash()`
   *
   * @param epoch                   Epoch in which the mint exchange rate was
   *                                set
   * @param oldRate                 Previous exchange rate
   * @param newRate                 New exchange rate
   * @param lastSetMintExchangeRate Value of lastSetMintExchangeRate
   *
   * @dev All rates are represented in 6 decimals.
   */
  event MintExchangeRateOverridden(
    uint256 indexed epoch,
    uint256 oldRate,
    uint256 newRate,
    uint256 lastSetMintExchangeRate
  );

  /**
   * @notice Event emitted when exchange rate delta limit has been set
   *
   * @param oldLimit Previous limit
   * @param newLimit New limit
   */
  event ExchangeRateDeltaLimitSet(uint256 oldLimit, uint256 newLimit);

  /**
   * @notice Event emitted when exchange rate has strayed too far from value
   *         at start of epoch
   *
   * @param lastEpochRate Previous exchange rate being compared against
   * @param newRate       New exchange rate
   *
   * @dev Both rates are represented in 6 decimals.
   */
  event MintExchangeRateCheckFailed(
    uint256 indexed epoch,
    uint256 lastEpochRate,
    uint256 newRate
  );

  /**
   * @notice Event emitted when mint limit is set
   *
   * @param oldLimit Old mint limit
   * @param newLimit New mint limit
   *
   * @dev See inheriting contract for representation
   */
  event MintLimitSet(uint256 oldLimit, uint256 newLimit);

  /**
   * @notice Event emitted when redeem limit is set
   *
   * @param oldLimit Old mint limit
   * @param newLimit New mint limit
   *
   * @dev See inheriting contract for representation
   */
  event RedeemLimitSet(uint256 oldLimit, uint256 newLimit);

  /**
   * @notice Event emitted when epochDurationSet
   *
   * @param oldDuration Old epoch duration
   * @param newDuration New epoch duration
   *
   * @dev See inheriting contract for representation
   */
  event EpochDurationSet(uint256 oldDuration, uint256 newDuration);

  /**
   * @notice Event emitted when setEpochStartTimestampOffset
   *
   * @param oldOffset Old epoch start timestamp offset
   * @param newOffset New epoch start timestamp offset
   */
  event EpochStartTimestampOffsetSet(uint256 oldOffset, uint256 newOffset);

  /**
   * @notice Event emitted when redemption request is submitted
   *
   * @param user         The user submitting the redemption request
   * @param cashAmountIn The amount of cash being burned
   * @param epoch        The epoch in which the redemption was submitted
   */
  event RedemptionRequested(
    address indexed user,
    uint256 cashAmountIn,
    uint256 indexed epoch
  );

  /**
   * @notice Event emitted when a mint request is submitted
   *
   * @param user                      The user requesting to mint
   * @param collateralAmountDeposited The total amount deposited
   * @param depositAmountAfterFee     The value deposited - fee
   * @param feeAmount                 The fee amount taken
   *                                  (units of collateral)
   */
  event MintRequested(
    address indexed user,
    uint256 indexed epoch,
    uint256 collateralAmountDeposited,
    uint256 depositAmountAfterFee,
    uint256 feeAmount
  );

  /**
   * @notice Event emitted when a redemption request is completed
   *
   * @param user                     The address of the user getting the funds
   * @param cashAmountRequested      Amount of cash originally requested by the user
   * @param collateralAmountReturned Amount of collateral received by the user
   * @param epoch                    The epoch in which this redemption was
   *                                 requested
   */
  event RedemptionCompleted(
    address indexed user,
    uint256 cashAmountRequested,
    uint256 collateralAmountReturned,
    uint256 indexed epoch
  );

  /**
   * @notice Event emitted when a Mint request is completed
   *
   * @param user                      The address of the user getting the funds
   * @param cashAmountOut             The amount of CASH token minted to the
   *                                  user
   * @param collateralAmountDeposited The amount of collateral deposited
   * @param exchangeRate              The exchange rate set for the given epoch
   * @param epochClaimedFrom          The epoch in which the user requested
   *                                  to mint
   */
  event MintCompleted(
    address indexed user,
    uint256 cashAmountOut,
    uint256 collateralAmountDeposited,
    uint256 exchangeRate,
    uint256 indexed epochClaimedFrom
  );

  /**
   * @notice Event emitted when an instant Mint occurs
   *
   * @param user                      The user requesting to mint
   * @param epoch                     The total amount deposited
   * @param collateralAmountDeposited The total amount deposited
   * @param depositAmountAfterFee     The value deposited - fee
   * @param feeAmount                 The fee amount taken (unit collateral)
   * @param instantMintAmount         The amount of CASH tokens minted
   *
   */
  event InstantMint(
    address indexed user,
    uint256 indexed epoch,
    uint256 collateralAmountDeposited,
    uint256 depositAmountAfterFee,
    uint256 feeAmount,
    uint256 instantMintAmount
  );

  /**
   * @notice Event emitted when excess CASH from a mint is claimed
   *
   * @param user                      The address of the user getting the funds
   * @param cashAmountOwed            The total amount of CASH owed to `user`
   * @param cashAmountGiven           The excess CASH amount claimed
   * @param collateralAmountDeposited The amount of collateral Deposited
   * @param exchangeRate              The exchange rate set for the given epoch
   * @param epochClaimedFrom          The epoch in which the user requested
   *                                  to mint
   */
  event ExcessMintClaimed(
    address indexed user,
    uint256 cashAmountOwed,
    uint256 cashAmountGiven,
    uint256 collateralAmountDeposited,
    uint256 exchangeRate,
    uint256 indexed epochClaimedFrom
  );

  /**
   * @notice Event emitted when the redemption fees are collected
   *
   * @param beneficiary         The address of who is receiving the fees
   * @param collateralAmountOut The amount of collateral that the `beneficiary`
   *                            is receiving
   * @param epoch               The epoch in which this fee dispersal happened
   */
  event RedemptionFeesCollected(
    address indexed beneficiary,
    uint256 collateralAmountOut,
    uint256 indexed epoch
  );

  /**
   * @notice Event emitted when a user is issued a redemption refund
   *
   * @param user          The address of the user being refunded
   * @param cashAmountOut The amount of cash being refunded to the user
   * @param epoch         The epoch in which this redemption was requested
   */
  event RefundIssued(
    address indexed user,
    uint256 cashAmountOut,
    uint256 indexed epoch
  );

  /**
   * @notice Event emitted when a user mint balance is set manually
   *
   * @param user       The address of the user having their mint balance set
   * @param epoch      The epoch in which the balance was set
   * @param oldBalance The user's previous balance
   * @param newBalance The user's new mint balance
   */
  event PendingMintBalanceSet(
    address indexed user,
    uint256 indexed epoch,
    uint256 oldBalance,
    uint256 newBalance
  );

  /**
   * @notice Event emitted when a user mint balance is set manually
   *
   * @param user       The address of the user having their mint balance set
   * @param epoch      The epoch in which the balance was set
   * @param oldBalance The user's previous balance
   * @param newBalance The user's new mint balance
   */
  event PendingInstantMintBalanceSet(
    address indexed user,
    uint256 indexed epoch,
    uint256 oldBalance,
    uint256 newBalance
  );

  /**
   * @notice Event emitted when a user redemption balance is set manually
   *
   * @param user        The address of the user having their redemption balance
   *                    set
   * @param epoch       The epoch in which the balance was set
   * @param balance     The new redemption balance
   * @param totalBurned The total amount of cash burned in epoch
   */
  event PendingRedemptionBalanceSet(
    address indexed user,
    uint256 indexed epoch,
    uint256 balance,
    uint256 totalBurned
  );

  /**
   * @notice Event emitted when instant mint percent is changed
   *
   * @param oldInstantMintBPS The old instant mint percent
   * @param newInstantMintBPS The new instant mint percent
   */
  event InstantMintPercentSet(
    uint256 oldInstantMintBPS,
    uint256 newInstantMintBPS
  );

  /** @notice Event emitted when a user is manually minted `CASH`
   *
   * @param user   The address of the user being minted `CASH`
   * @param amount The amount of `CASH` being minted to the user
   */
  event AdminMintedCash(address indexed user, uint256 amount);

  /**
   * @notice Event emitted when the max admin mint amount is set
   *
   * @param oldMaxAdminMintAmount The previous max admin mint amount
   * @param newMaxAdminMintAmount The new max admin mint amount
   */
  event MaxAdminMintAmountSet(
    uint256 oldMaxAdminMintAmount,
    uint256 newMaxAdminMintAmount
  );

  /**
   * @notice Event emitted when the instant mint feature is
   *         toggled
   *
   * @param status true == enabled | false == disabled
   */
  event InstantMintingEnabled(bool status);

  /// ERRORS ///
  error CollateralZeroAddress();
  error CashZeroAddress();
  error AssetRecipientZeroAddress();
  error AssetSenderZeroAddress();
  error FeeRecipientZeroAddress();
  error MinimumDepositAmountTooSmall();
  error ZeroExchangeRate();

  error KYCCheckFailed();
  error MintRequestAmountTooSmall();
  error NoCashToClaim();
  error ExchangeRateNotSet();

  error EpochNotElapsed();
  error EpochDurationTooSmall();
  error EpochExchangeRateAlreadySet();
  error InvalidOffsetAtCurrentTime();
  error EpochStartTimestampOffsetTooLarge();
  error UnexpectedMintBalance();

  error MintFeeTooLarge();
  error MintExceedsRateLimit();
  error RedeemAmountCannotBeZero();
  error RedeemExceedsRateLimit();
  error WithdrawRequestAmountTooSmall();
  error CollateralRedemptionTooSmall();
  error MustServicePastEpoch();
  error CannotServiceFutureEpoch();
  error RedemptionBalanceMismatch();

  error FeatureNotEnabled();
  error InstantMintTooLarge();
  error CannotClaimMint();
  error CannotClaimExcess();
  error AdminMintAmountTooLarge();
  error ZeroAddressInput();
}