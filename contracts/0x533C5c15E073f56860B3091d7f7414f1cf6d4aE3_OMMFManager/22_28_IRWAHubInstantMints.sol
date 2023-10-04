pragma solidity 0.8.16;

interface IRWAHubInstantMints {
  function instantMint(uint256 amount) external;

  function instantRedemption(uint256 amount) external;

  function setInstantMintFee(uint256 _instantMintFee) external;

  function setInstantRedemptionFee(uint256 _instantRedemptionFee) external;

  function setInstantMintPriceId(uint256 _instantMintPriceId) external;

  function setInstantRedemptionPriceId(
    uint256 _instantRedemptionPriceId
  ) external;

  function pauseInstantMint() external;

  function unpauseInstantMint() external;

  function pauseInstantRedemption() external;

  function unpauseInstantRedemption() external;

  function setInstantMintLimit(uint256 newMintLimit) external;

  function setInstantRedemptionLimit(uint256 newRedemptionLimit) external;

  function setInstantMintLimitDuration(uint256 newMintLimitDuration) external;

  function setInstantRedemptionLimitDuration(
    uint256 newRedemptionLimitDuration
  ) external;

  /**
   * @notice Event emitted when instant mint fee is set
   *
   * @param oldFee Old fee
   * @param newFee New fee
   *
   * @dev See inheriting contract for decimals representation
   */
  event InstantMintFeeSet(uint256 oldFee, uint256 newFee);

  /**
   * @notice Event emitted when instant redeem fee is set
   *
   * @param oldFee Old fee
   * @param newFee New fee
   *
   * @dev See inheriting contract for decimals representation
   */
  event InstantRedemptionFeeSet(uint256 oldFee, uint256 newFee);

  /**
   * @notice Event emitted when an instant mint is completed
   *
   * @param user                      The address of the user
   * @param collateralAmountDeposited The amount of collateral deposited
   * @param collateralAmountAfterFees The amount of collateral after fees
   * @param feesInCollateral          The amount of fees in collateral
   * @param rwaOwed                   The amount of rwa minted to the user
   * @param price                     The price at which the rwa was minted at
   */
  event InstantMintCompleted(
    address indexed user,
    uint256 collateralAmountDeposited,
    uint256 collateralAmountAfterFees,
    uint256 feesInCollateral,
    uint256 rwaOwed,
    uint256 price
  );

  /**
   * @notice Event emitted when an instant redeem is completed
   *
   * @param user                      The address of the user
   * @param rwaAmountBurned           The amount of RWA burned by the user
   * @param collateralAmountAfterFees The amount of collateral after fees returned
   * @param feesInCollateral          The amount of fees in collateral
   * @param price                     The price at which the rwa was redeemed at
   * @param priceId                   The priceId of the used redemption price
   */
  event InstantRedemptionCompleted(
    address indexed user,
    uint256 rwaAmountBurned,
    uint256 collateralAmountAfterFees,
    uint256 feesInCollateral,
    uint256 price,
    uint256 priceId
  );

  /**
   * @notice Event emitted when instant mints are paused
   *
   * @param caller Address which initiated the pause
   */
  event InstantMintPaused(address caller);

  /**
   * @notice Event emitted when instant mints are unpaused
   *
   * @param caller Address which initiated the unpause
   */
  event InstantMintUnpaused(address caller);

  /**
   * @notice Event emitted when instant redeems are paused
   *
   * @param caller Address which initiated the pause
   */
  event InstantRedemptionPaused(address caller);

  /**
   * @notice Event emitted when instant redeems are unpaused
   *
   * @param caller Address which initiated the unpause
   */
  event InstantRedemptionUnpaused(address caller);

  /**
   * @notice Event emitted when instant mint priceId is set
   *
   * @param priceId Price Id
   */
  event PriceIdSetForInstantMint(uint256 priceId);

  /**
   * @notice Event emitted when instant redeem priceId is set
   *
   * @param priceId Price Id
   */
  event PriceIdSetForInstantRedemption(uint256 priceId);

  /**
   * @notice Event emitted when instant mint asset manager is set
   *
   * @param oldInstantMintAssetManager Old instant mint asset manager
   * @param newInstantMintAssetManager New instant mint asset manager
   */
  event InstantMintAssetManagerSet(
    address oldInstantMintAssetManager,
    address newInstantMintAssetManager
  );
}