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

interface IRWAHub {
  // Struct to contain the deposit information for a given depositId
  struct Depositor {
    address user;
    uint256 amountDepositedMinusFees;
    uint256 priceId;
  }

  // Struc to contain withdrawal infromation for a given redemptionId
  struct Redeemer {
    address user;
    uint256 amountRwaTokenBurned;
    uint256 priceId;
  }

  function requestSubscription(uint256 amount) external;

  function claimMint(bytes32[] calldata depositIds) external;

  function requestRedemption(uint256 amount) external;

  function claimRedemption(bytes32[] calldata redemptionIds) external;

  function addProof(
    bytes32 txHash,
    address user,
    uint256 depositAmountAfterFee,
    uint256 feeAmount,
    uint256 timestamp
  ) external;

  function setPriceIdForDeposits(
    bytes32[] calldata depositIds,
    uint256[] calldata priceIds
  ) external;

  function setPriceIdForRedemptions(
    bytes32[] calldata redemptionIds,
    uint256[] calldata priceIds
  ) external;

  function setPricer(address newPricer) external;

  function overwriteDepositor(
    bytes32 depositIdToOverride,
    address user,
    uint256 depositAmountAfterFee,
    uint256 priceId
  ) external;

  function overwriteRedeemer(
    bytes32 redemptionIdToOverride,
    address user,
    uint256 rwaTokenAmountBurned,
    uint256 priceId
  ) external;

  /**
   * @notice Event emitted when fee recipient is set
   *
   * @param oldFeeRecipient Old fee recipient
   * @param newFeeRecipient New fee recipient
   */
  event FeeRecipientSet(address oldFeeRecipient, address newFeeRecipient);

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
   * @param oldRedemptionMin The old redeem minimum value
   * @param newRedemptionMin The new redeem minimum value
   */
  event MinimumRedemptionAmountSet(
    uint256 oldRedemptionMin,
    uint256 newRedemptionMin
  );

  /**
   * @notice Event emitted when mint fee is set
   *
   * @param oldFee Old fee
   * @param newFee New fee
   *
   * @dev See inheriting contract for decimals representation
   */
  event MintFeeSet(uint256 oldFee, uint256 newFee);

  /**
   * @notice Event emitted when redeem fee is set
   *
   * @param oldFee Old fee
   * @param newFee New fee
   *
   * @dev see inheriting contract for decimal representation
   */
  event RedemptionFeeSet(uint256 oldFee, uint256 newFee);

  /**
   * @notice Event emitted when redemption request is submitted
   *
   * @param user         The user submitting the redemption request
   * @param redemptionId The id corresponding to a given redemption
   * @param rwaAmountIn The amount of cash being burned
   */
  event RedemptionRequested(
    address indexed user,
    bytes32 indexed redemptionId,
    uint256 rwaAmountIn
  );

  /**
   * @notice Event emitted when a mint request is submitted
   *
   * @param user                      The user requesting to mint
   * @param depositId                 The depositId of the request
   * @param collateralAmountDeposited The total amount deposited
   * @param depositAmountAfterFee     The value deposited - fee
   * @param feeAmount                 The fee amount taken
   *                                  (units of collateral)
   */
  event MintRequested(
    address indexed user,
    bytes32 indexed depositId,
    uint256 collateralAmountDeposited,
    uint256 depositAmountAfterFee,
    uint256 feeAmount
  );

  /**
   * @notice Event emitted when a redemption request is completed
   *
   * @param user                     The address of the user getting the funds
   * @param redemptionId             The id corresponding to a given redemption
   *                                 requested
   * @param rwaAmountRequested       Amount of RWA originally requested by the user
   * @param collateralAmountReturned Amount of collateral received by the user
   * @param price                    The price at which the redemption was
   *                                 serviced at
   */
  event RedemptionCompleted(
    address indexed user,
    bytes32 indexed redemptionId,
    uint256 rwaAmountRequested,
    uint256 collateralAmountReturned,
    uint256 price
  );

  /**
   * @notice Event emitted when a Mint request is completed
   *
   * @param user                      The address of the user getting the funds
   * @param depositId                 The depositId of the mint request
   * @param rwaAmountOut              The amount of RWA token minted to the
   *                                  user
   * @param collateralAmountDeposited The amount of collateral deposited
   * @param price                     The price set for the given
   *                                  deposit id
   * @param priceId                   The priceId used to determine price
   */
  event MintCompleted(
    address indexed user,
    bytes32 indexed depositId,
    uint256 rwaAmountOut,
    uint256 collateralAmountDeposited,
    uint256 price,
    uint256 priceId
  );

  /**
   * @notice Event emitted when a deposit has its corresponding priceId set
   *
   * @param depositIdSet The Deposit Id for which the price Id is being set
   * @param priceIdSet   The price Id being associate with a deposit Id
   */
  event PriceIdSetForDeposit(
    bytes32 indexed depositIdSet,
    uint256 indexed priceIdSet
  );

  /**
   * @notice Event Emitted when a redemption has its corresponding priceId set
   *
   * @param redemptionIdSet The Redemption Id for which the price Id is being
   *                        set
   * @param priceIdSet      The Price Id being associated with a redemption Id
   */
  event PriceIdSetForRedemption(
    bytes32 indexed redemptionIdSet,
    uint256 indexed priceIdSet
  );

  /**
   * @notice Event emitted when a new Pricer contract is set
   *
   * @param oldPricer The address of the old pricer contract
   * @param newPricer The address of the new pricer contract
   */
  event NewPricerSet(address oldPricer, address newPricer);

  /**
   * @notice Event emitted when a new Pricer contract is set
   *
   * @param oldRWA The address of the old pricer contract
   * @param newRWA The address of the new pricer contract
   */
  event NewRWASet(address oldRWA, address newRWA);

  /**
   * @notice Event emitted when deposit proof has been added
   *
   * @param txHash                Tx hash of the deposit
   * @param user                  Address of the user who made the deposit
   * @param depositAmountAfterFee Amount of the deposit after fees
   * @param feeAmount             Amount of fees taken
   * @param timestamp             Timestamp of the deposit
   */
  event DepositProofAdded(
    bytes32 indexed txHash,
    address indexed user,
    uint256 depositAmountAfterFee,
    uint256 feeAmount,
    uint256 timestamp
  );

  /**
   * @notice Event emitted when subscriptions are paused
   *
   * @param caller Address which initiated the pause
   */
  event SubscriptionPaused(address caller);

  /**
   * @notice Event emitted when redemptions are paused
   *
   * @param caller Address which initiated the pause
   */
  event RedemptionPaused(address caller);

  /**
   * @notice Event emitted when subscriptions are unpaused
   *
   * @param caller Address which initiated the unpause
   */
  event SubscriptionUnpaused(address caller);

  /**
   * @notice Event emitted when redemptions are unpaused
   *
   * @param caller Address which initiated the unpause
   */
  event RedemptionUnpaused(address caller);

  event DepositorOverwritten(
    bytes32 indexed depositId,
    address oldDepositor,
    address newDepositor,
    uint256 oldPriceId,
    uint256 newPriceId,
    uint256 oldDepositAmount,
    uint256 newDepositAmount
  );

  event RedeemerOverwritten(
    bytes32 indexed redemptionId,
    address oldRedeemer,
    address newRedeemer,
    uint256 oldPriceId,
    uint256 newPriceId,
    uint256 oldRWATokenAmountBurned,
    uint256 newRWATokenAmountBurned
  );

  /// ERRORS ///
  error PriceIdNotSet();
  error ArraySizeMismatch();
  error DepositTooSmall();
  error RedemptionTooSmall();
  error TxnAlreadyValidated();
  error CollateralCannotBeZero();
  error RWACannotBeZero();
  error AssetSenderCannotBeZero();
  error FeeRecipientCannotBeZero();
  error FeeTooLarge();
  error AmountTooSmall();
  error DepositorNull();
  error RedeemerNull();
  error DepositProofAlreadyExists();
  error FeaturePaused();
  error PriceIdAlreadySet();
  error RWAIncorrectDecimals();
}