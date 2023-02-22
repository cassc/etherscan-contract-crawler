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

import "contracts/cash/interfaces/ICashManager.sol";
import "contracts/cash/interfaces/IMulticall.sol";
import "contracts/cash/token/Cash.sol";
import "contracts/cash/kyc/KYCRegistryClientConstructable.sol";
import "contracts/cash/external/openzeppelin/contracts/security/Pausable.sol";
import "contracts/cash/external/openzeppelin/contracts/token/IERC20.sol";
import "contracts/cash/external/openzeppelin/contracts/token/IERC20Metadata.sol";
import "contracts/cash/external/openzeppelin/contracts/token/SafeERC20.sol";
import "contracts/cash/external/openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "contracts/cash/external/openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CashManager is
  ICashManager,
  IMulticall,
  AccessControlEnumerable,
  KYCRegistryClientConstructable,
  Pausable,
  ReentrancyGuard
{
  using SafeERC20 for IERC20;

  /// @dev Tokens
  // ERC20 token used to Mint CASH with
  IERC20 public immutable collateral;

  // CASH contract
  Cash public immutable cash;

  /// @dev Collateral Recipients
  // The address to which the `collateral` is sent
  address public constant assetRecipient =
    0xF67416a2C49f6A46FEe1c47681C5a3832cf8856c;

  // The address to which fees are sent
  address public feeRecipient;

  // The address from which redemptions are processed
  address public assetSender;

  /// @dev Mint/Redeem Parameters
  // Minimum amount that must be deposited to mint CASH
  // Denoted in decimals of `collateral`
  uint256 public minimumDepositAmount = 10_000;

  // Maximum amount that an admin can manually mint
  // Denoted in decimals of `CASH`
  uint256 public maxAdminMintAmount = 10_000e18;

  // Minimum amount that must be redeemed for a withdraw request
  uint256 public minimumRedeemAmount;

  // Minting fee specified in basis points
  uint256 public mintFee = 0;

  // Instant Minting fee specified in basis points
  uint256 public instantMintFee = 0;

  // Limit for how far `exchangeRate` can stray from
  // `lastSetMintExchangeRate` within an epoch (in basis points)
  uint256 public exchangeRateDeltaLimit = 100;

  // Struct representing all redemption requests in an epoch
  struct RedemptionRequests {
    // Total CASH burned in the epoch
    uint256 totalBurned;
    // Mapping from address to amount of CASH address burned
    mapping(address => uint256) addressToBurnAmt;
  }

  // Mapping from epoch to redemption info struct for that epoch
  mapping(uint256 => RedemptionRequests) public redemptionInfoPerEpoch;

  // Mapping used for getting the exchange rate during a given epoch
  mapping(uint256 => uint256) public epochToExchangeRate;

  // Nested mapping containing mint requests for an epoch
  // { <epoch> : {<user> : <collateralAmount> }
  mapping(uint256 => mapping(address => uint256)) public mintRequestsPerEpoch;

  // Struct representing all redemption requests in an epoch
  struct InstantMintAmounts {
    // Collateral deposited in an epoch
    uint256 collateralDeposited;
    // Amount of CASH instantly minted
    uint256 instantMintAmount;
  }

  // Mapping corresponding to a given users instantMint info per epoch
  mapping(uint256 => mapping(address => InstantMintAmounts))
    public instantMintAmtsPerEpoch;

  // Helper constant that allows us to specify basis points in calculations
  uint256 public constant BPS_DENOMINATOR = 10_000;

  // Decimal multiplier representing the difference between `CASH` decimals
  // In `collateral` token decimals
  uint256 public immutable decimalsMultiplier;

  /// @dev Epoch Parameters
  // Epoch that contract is currently in
  uint256 public currentEpoch;

  // Duration of an epoch in seconds
  uint256 public epochDuration;

  // Timestamp of the start of `currentEpoch`
  uint256 public currentEpochStartTimestamp;

  // Offset by which `currentEpochStartTimestamp` is shifted by in seconds
  uint256 public epochStartTimestampOffset;

  // `exchangeRate` at start of `currentEpoch`
  uint256 public lastSetMintExchangeRate = 100e18;

  /// @dev Mint/Redeem Limit Parameters
  // Maximum amount that can be minted during an epoch
  uint256 public mintLimit;

  // Amount already minted during the `currentEpoch`
  uint256 public currentMintAmount;

  // Maximum amount that can be redeemed during an epoch
  uint256 public redeemLimit;

  // Amount already redeemed during the `currentEpoch`
  uint256 public currentRedeemAmount;

  // Amount credited to a user on Mint in BPS
  uint256 public instantMintBPS = 9_000;

  // Feature flag used to enable and disable instant minting
  bool public instantMintingEnabled;

  /// @dev Role based access control roles
  bytes32 public constant MANAGER_ADMIN = keccak256("MANAGER_ADMIN");
  bytes32 public constant MINTER_ADMIN = keccak256("MINTER_ADMIN");
  bytes32 public constant PAUSER_ADMIN = keccak256("PAUSER_ADMIN");
  bytes32 public constant SETTER_ADMIN = keccak256("SETTER_ADMIN");

  /// @notice constructor
  constructor(
    address _collateral,
    address _cash,
    address managerAdmin,
    address pauser,
    address _assetSender,
    address _feeRecipient,
    uint256 _mintLimit,
    uint256 _redeemLimit,
    uint256 _epochDuration,
    address _kycRegistry,
    uint256 _kycRequirementGroup
  ) KYCRegistryClientConstructable(_kycRegistry, _kycRequirementGroup) {
    if (_collateral == address(0)) {
      revert CollateralZeroAddress();
    }
    if (_cash == address(0)) {
      revert CashZeroAddress();
    }
    if (_assetSender == address(0)) {
      revert AssetSenderZeroAddress();
    }
    if (_feeRecipient == address(0)) {
      revert FeeRecipientZeroAddress();
    }

    _grantRole(DEFAULT_ADMIN_ROLE, managerAdmin);
    _grantRole(MANAGER_ADMIN, managerAdmin);
    _setRoleAdmin(PAUSER_ADMIN, MANAGER_ADMIN);
    _setRoleAdmin(SETTER_ADMIN, MANAGER_ADMIN);
    _grantRole(PAUSER_ADMIN, pauser);

    collateral = IERC20(_collateral);
    cash = Cash(_cash);
    feeRecipient = _feeRecipient;
    assetSender = _assetSender;

    mintLimit = _mintLimit;
    redeemLimit = _redeemLimit;
    epochDuration = _epochDuration;

    currentEpochStartTimestamp =
      block.timestamp -
      (block.timestamp % epochDuration);

    // Implicit constraint: cash decimals >= collateral decimals.
    decimalsMultiplier =
      10 **
        (IERC20Metadata(_cash).decimals() -
          IERC20Metadata(_collateral).decimals());
  }

  /*//////////////////////////////////////////////////////////////
                            Mint Logic
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Admin function used to toggle instantMinting
   *
   * @param val Boolean representing if instantMinting is enabled
   */
  function setInstantMint(bool val) external onlyRole(MANAGER_ADMIN) {
    instantMintingEnabled = val;
    emit InstantMintingEnabled(instantMintingEnabled);
  }

  /**
   * @notice Function modifier used to gate functions
   *         dependent on if instantMinting enabled
   */
  modifier instantMintingAllowed() {
    if (instantMintingEnabled == false) {
      revert FeatureNotEnabled();
    }
    _;
  }

  /**
   * @notice Function used by users to submit a request to mint
   *
   * @param collateralAmountIn The amount of collateral one wishes to deposit
   *                           to mint CASH tokens
   */
  function requestMint(
    uint256 collateralAmountIn
  )
    external
    override
    updateEpoch
    nonReentrant
    whenNotPaused
    checkKYC(msg.sender)
  {
    if (collateralAmountIn < minimumDepositAmount) {
      revert MintRequestAmountTooSmall();
    }

    uint256 feesInCollateral = _getMintFees(collateralAmountIn);
    uint256 depositValueAfterFees = collateralAmountIn - feesInCollateral;

    _checkAndUpdateMintLimit(depositValueAfterFees);

    if (feesInCollateral > 0) {
      collateral.safeTransferFrom(msg.sender, feeRecipient, feesInCollateral);
    }

    collateral.safeTransferFrom(
      msg.sender,
      assetRecipient,
      depositValueAfterFees
    );

    mintRequestsPerEpoch[currentEpoch][msg.sender] += depositValueAfterFees;

    emit MintRequested(
      msg.sender,
      currentEpoch,
      collateralAmountIn,
      depositValueAfterFees,
      feesInCollateral
    );
  }

  /**
   * @notice Function used by users to claim an airdrop for a given epoch
   *
   * @param user         The user who requested to mint
   * @param epochToClaim The epoch in which the mint was requested
   *
   * @dev We perform KYC check on the user destined to receive `cash`, not the
   *      msg.sender
   */
  function claimMint(
    address user,
    uint256 epochToClaim
  ) external override updateEpoch nonReentrant whenNotPaused checkKYC(user) {
    uint256 collateralDeposited = mintRequestsPerEpoch[epochToClaim][user];
    if (collateralDeposited == 0) {
      revert NoCashToClaim();
    }
    if (epochToExchangeRate[epochToClaim] == 0) {
      revert ExchangeRateNotSet();
    }

    // Get the amount of CASH due at a given rate per epoch
    uint256 cashOwed = _getMintAmountForEpoch(
      collateralDeposited,
      epochToClaim
    );

    mintRequestsPerEpoch[epochToClaim][user] = 0;
    cash.mint(user, cashOwed);

    emit MintCompleted(
      user,
      cashOwed,
      collateralDeposited,
      epochToExchangeRate[epochToClaim],
      epochToClaim
    );
  }

  /**
   * @notice Function used by user to subscribe to the fund and
   *         instantly mint a portion of the subscription amt
   *
   * @param collateralAmountIn The amount of collateral one wished to deposit
   *                           to mint CASH tokens
   */
  function instantMint(
    uint256 collateralAmountIn
  )
    external
    override
    updateEpoch
    nonReentrant
    whenNotPaused
    checkKYC(msg.sender)
    instantMintingAllowed
  {
    if (collateralAmountIn < minimumDepositAmount) {
      revert MintRequestAmountTooSmall();
    }
    uint256 feesInCollateral = _getInstantMintFees(collateralAmountIn);
    uint256 depositValueAfterFees = collateralAmountIn - feesInCollateral;

    _checkAndUpdateMintLimit(depositValueAfterFees);

    if (feesInCollateral > 0) {
      collateral.safeTransferFrom(msg.sender, feeRecipient, feesInCollateral);
    }

    collateral.safeTransferFrom(
      msg.sender,
      assetRecipient,
      depositValueAfterFees
    );

    uint256 instantCash = _getInstantMintAmount(depositValueAfterFees);
    cash.mint(msg.sender, instantCash);

    instantMintAmtsPerEpoch[currentEpoch][msg.sender]
      .instantMintAmount += instantCash;

    instantMintAmtsPerEpoch[currentEpoch][msg.sender]
      .collateralDeposited += depositValueAfterFees;

    emit InstantMint(
      msg.sender,
      currentEpoch,
      collateralAmountIn,
      depositValueAfterFees,
      feesInCollateral,
      instantCash
    );
  }

  /**
   * @notice Claim excess `CASH` on behalf of a user after the mint exchange
   *         rate has been posted on chain. This scenario can happen if the
   *         mint exchange rate is larger than the instant mint rate.
   *
   * @param user         The address you would like to claim on behalf of
   * @param epochToClaim The epoch in which the user minted
   *
   * @dev This function can be called by admin or the user who is owed `CASH`
   * @dev We perform KYC check on the user destined to receive `CASH` not the
   *      msg.sender
   */
  function claimExcess(
    address user,
    uint256 epochToClaim
  )
    external
    override
    updateEpoch
    nonReentrant
    whenNotPaused
    checkKYC(user)
    instantMintingAllowed
  {
    if (!(msg.sender == user || hasRole(MANAGER_ADMIN, msg.sender))) {
      revert CannotClaimExcess();
    }
    if (epochToExchangeRate[epochToClaim] == 0) {
      revert ExchangeRateNotSet();
    }
    uint256 collateralDeposited = instantMintAmtsPerEpoch[epochToClaim][user]
      .collateralDeposited;
    if (collateralDeposited == 0) {
      revert NoCashToClaim();
    }
    uint256 cashGiven = instantMintAmtsPerEpoch[epochToClaim][user]
      .instantMintAmount;

    // Get amount of CASH due at a given rate per epoch
    uint256 cashOwed = _getMintAmountForEpoch(
      collateralDeposited,
      epochToClaim
    );
    uint256 cashDue = cashOwed - cashGiven;
    instantMintAmtsPerEpoch[epochToClaim][user].collateralDeposited = 0;
    cash.mint(user, cashDue);

    emit ExcessMintClaimed(
      user,
      cashOwed,
      cashDue,
      collateralDeposited,
      epochToExchangeRate[epochToClaim],
      epochToClaim
    );
  }

  /**
   * @notice Given amount of `collateral` returns fees owed
   *
   * @param collateralAmount Amount `collateral` to exchange
   *                         (in decimals of `collateral`)
   */
  function _getInstantMintFees(
    uint256 collateralAmount
  ) internal view returns (uint256) {
    return (collateralAmount * instantMintFee) / BPS_DENOMINATOR;
  }

  /**
   * @notice Sets instant mint fee
   *
   * @param _instantMintFee new mint fee specified in basis points
   *
   * @dev The maximum fee that can be set is 10_000 BPS or 100%
   */
  function setInstantMintFee(
    uint256 _instantMintFee
  ) external override instantMintingAllowed onlyRole(MANAGER_ADMIN) {
    if (_instantMintFee > BPS_DENOMINATOR) {
      revert MintFeeTooLarge();
    }
    uint256 oldInstantMintFee = instantMintFee;
    instantMintFee = _instantMintFee;
    emit InstantMintFeeSet(oldInstantMintFee, instantMintFee);
  }

  /**
   * @notice Sets the % (in bps) for instant minting based off the
   *         `lastSetMintExchangeRate`
   *
   * @param newInstantMintBPS The new percent for instant minting
   */
  function setInstantMintPercentBPS(
    uint256 newInstantMintBPS
  )
    external
    override
    updateEpoch
    instantMintingAllowed
    onlyRole(MANAGER_ADMIN)
  {
    if (newInstantMintBPS > BPS_DENOMINATOR) {
      revert InstantMintTooLarge();
    }
    uint256 oldInstantMintBPS = instantMintBPS;
    instantMintBPS = newInstantMintBPS;
    emit InstantMintPercentSet(oldInstantMintBPS, instantMintBPS);
  }

  /**
   * @notice Given amount of `collateral`, returns how much CASH ought
   *         to be instantly minted, based off a percentage of the last
   *         set exchangeRate
   *
   * @param collateralAmountIn Amount of `collateral` given
   *
   * @return cashInstantMint Amount of CASH to instantly mint
   *
   * @dev If `lastSetMintExchangeRate` needs to be changed this can be done
   *      through a call to `overrideExchangeRate`
   */
  function _getInstantMintAmount(
    uint256 collateralAmountIn
  ) internal view returns (uint256 cashInstantMint) {
    uint256 amountE24 = _scaleUp(collateralAmountIn) * 1e18;
    uint256 cashOwedLastRate = amountE24 / lastSetMintExchangeRate;
    cashInstantMint = (cashOwedLastRate * instantMintBPS) / BPS_DENOMINATOR;
  }

  /**
   * @notice Sets mint exchange rate
   *
   * @param exchangeRate New mint exchange rate (in 18 decimals)
   * @param epochToSet   The epoch we want to set the exchange rate for
   *
   * @dev If the exchange rate differs more than `exchangeRateDeltaLimit`
   *      from the last exchange rate set, the entire contract will be paused.
   *      See `overrideExchangeRate` should this check need to be bypassed
   */
  function setMintExchangeRate(
    uint256 exchangeRate,
    uint256 epochToSet
  ) external override updateEpoch onlyRole(SETTER_ADMIN) {
    if (exchangeRate == 0) {
      revert ZeroExchangeRate();
    }
    if (epochToSet >= currentEpoch) {
      revert EpochNotElapsed();
    }
    if (epochToExchangeRate[epochToSet] != 0) {
      revert EpochExchangeRateAlreadySet();
    }

    uint256 rateDifference;
    if (exchangeRate > lastSetMintExchangeRate) {
      rateDifference = exchangeRate - lastSetMintExchangeRate;
    } else if (exchangeRate < lastSetMintExchangeRate) {
      rateDifference = lastSetMintExchangeRate - exchangeRate;
    }

    uint256 maxDifferenceThisEpoch = (lastSetMintExchangeRate *
      exchangeRateDeltaLimit) / BPS_DENOMINATOR;

    if (rateDifference > maxDifferenceThisEpoch) {
      epochToExchangeRate[epochToSet] = exchangeRate;
      _pause();
      emit MintExchangeRateCheckFailed(
        epochToSet,
        lastSetMintExchangeRate,
        exchangeRate
      );
    } else {
      uint256 oldExchangeRate = lastSetMintExchangeRate;
      epochToExchangeRate[epochToSet] = exchangeRate;
      lastSetMintExchangeRate = exchangeRate;
      emit MintExchangeRateSet(epochToSet, oldExchangeRate, exchangeRate);
    }
  }

  /**
   * @notice Admin function to manually mint CASH tokens to a user
   *
   * @param user   User to mint CASH tokens to
   * @param amount Quantity of CASH tokens to mint
   */
  function adminMintCash(
    address user,
    uint256 amount
  ) external onlyRole(MINTER_ADMIN) {
    if (amount > maxAdminMintAmount) {
      revert AdminMintAmountTooLarge();
    }
    if (user == address(0)) {
      revert ZeroAddressInput();
    }
    cash.mint(user, amount);
    emit AdminMintedCash(user, amount);
  }

  /**
   * @notice Admin function to set the maximum amount of CASH tokens that can
   *         be minted via `adminMintCash`
   *
   * @param _maxAdminMintAmount The maximum amount of CASH tokens that can be minted
   */
  function setMaxAdminMintAmount(
    uint256 _maxAdminMintAmount
  ) external onlyRole(MANAGER_ADMIN) {
    uint256 oldMaxAdminMintAmount = maxAdminMintAmount;
    maxAdminMintAmount = _maxAdminMintAmount;
    emit MaxAdminMintAmountSet(oldMaxAdminMintAmount, _maxAdminMintAmount);
  }

  /**
   * @notice Override admin function for changing the representation of the
   *         amount of collateral a user has deposited to kick off minting
   *         process
   *
   * @param user       The user whose balance is being set
   * @param epoch      The epoch in which to set user balance for
   * @param oldBalance The user's previous balance
   * @param newBalance The user's new balance to set
   *
   * @dev `oldBalance` is provided to prevent front running attacks where a
   *      user could attempt to claim before and after this is set.
   */
  function setPendingMintBalance(
    address user,
    uint256 epoch,
    uint256 oldBalance,
    uint256 newBalance
  ) external updateEpoch onlyRole(MANAGER_ADMIN) {
    if (oldBalance != mintRequestsPerEpoch[epoch][user]) {
      revert UnexpectedMintBalance();
    }
    if (epoch > currentEpoch) {
      revert CannotServiceFutureEpoch();
    }
    mintRequestsPerEpoch[epoch][user] = newBalance;
    emit PendingMintBalanceSet(user, epoch, oldBalance, newBalance);
  }

  /**
   * @notice Override admin function for changing the representation of the
   *         amount of collateral a user has deposited for instant minting
   *
   * @param user       The user whose balance is being set
   * @param epoch      The epoch in which to set user balance for
   * @param oldBalance The user's previous balance
   * @param newBalance The user's new balance to set
   *
   * @dev The total burned amount for the epoch must be set appropriately
   *      in order to correctly calculate redemptions.
   * @dev `oldBalance` is provided to prevent front running attacks where a
   *      user could attempt to claim before and after this is set.
   */
  function setPendingInstantMintBalance(
    address user,
    uint256 epoch,
    uint256 oldBalance,
    uint256 newBalance
  ) external updateEpoch onlyRole(MANAGER_ADMIN) {
    if (
      oldBalance != instantMintAmtsPerEpoch[epoch][user].collateralDeposited
    ) {
      revert UnexpectedMintBalance();
    }
    if (epoch > currentEpoch) {
      revert CannotServiceFutureEpoch();
    }
    instantMintAmtsPerEpoch[epoch][user].collateralDeposited = newBalance;
    emit PendingInstantMintBalanceSet(user, epoch, oldBalance, newBalance);
  }

  /**
   * @notice Allows for the `MANAGER_ADMIN` to arbitrarily set an exchange
   *         rate for a given epoch
   *
   * @param correctExchangeRate      The exchange rate we wish to update to
   * @param epochToSet               The epoch for which we want to set the rate
   * @param _lastSetMintExchangeRate Value to set `lastSetMintExchangeRate` to
   *                                 if not equal to 0
   *
   * @dev This function allows the caller to also update the
   *      `lastSetMintExchangeRate`, which is compared against
   *      when calling `setMintExchangeRate` to prevent large
   *      swings in prices.
   */
  function overrideExchangeRate(
    uint256 correctExchangeRate,
    uint256 epochToSet,
    uint256 _lastSetMintExchangeRate
  ) external override updateEpoch onlyRole(MANAGER_ADMIN) {
    if (epochToSet >= currentEpoch) {
      revert MustServicePastEpoch();
    }
    uint256 incorrectRate = epochToExchangeRate[epochToSet];
    epochToExchangeRate[epochToSet] = correctExchangeRate;
    if (_lastSetMintExchangeRate != 0) {
      lastSetMintExchangeRate = _lastSetMintExchangeRate;
    }
    emit MintExchangeRateOverridden(
      epochToSet,
      incorrectRate,
      correctExchangeRate,
      lastSetMintExchangeRate
    );
  }

  /**
   * @notice Sets mint exchange rate delta limit
   *
   * @param _exchangeRateDeltaLimit New mint exchange rate delta limit (in bps)
   */
  function setMintExchangeRateDeltaLimit(
    uint256 _exchangeRateDeltaLimit
  ) external override onlyRole(MANAGER_ADMIN) {
    uint256 oldExchangeRateDeltaLimit = exchangeRateDeltaLimit;
    exchangeRateDeltaLimit = _exchangeRateDeltaLimit;
    emit ExchangeRateDeltaLimitSet(
      oldExchangeRateDeltaLimit,
      _exchangeRateDeltaLimit
    );
  }

  /**
   * @notice Sets mint fee
   *
   * @param _mintFee new mint fee specified in basis points
   *
   * @dev The maximum fee that can be set is 10_000 bps, or 100%
   */
  function setMintFee(
    uint256 _mintFee
  ) external override onlyRole(MANAGER_ADMIN) {
    if (_mintFee > BPS_DENOMINATOR) {
      revert MintFeeTooLarge();
    }
    uint256 oldMintFee = mintFee;
    mintFee = _mintFee;
    emit MintFeeSet(oldMintFee, _mintFee);
  }

  /**
   * @notice Sets minimum deposit amount
   *
   * @param _minimumDepositAmount New minimum deposit amount
   *                              (in decimals specified by `collateral`)
   *
   * @dev Must be larger than BPS_DENOMINATOR due to keep our `_getMintFees`
   *      calculation correct. For example, if a deposit amount is less than
   *      BPS_DENOMINAOR (say 9999) and `mintFee` = 1,
   *      (collateralAmount * mintFee) / BPS_DENOMINATOR will incorrectly
   *      return 0.
   */
  function setMinimumDepositAmount(
    uint256 _minimumDepositAmount
  ) external override onlyRole(MANAGER_ADMIN) {
    if (_minimumDepositAmount < BPS_DENOMINATOR) {
      revert MinimumDepositAmountTooSmall();
    }
    uint256 oldMinimumDepositAmount = minimumDepositAmount;
    minimumDepositAmount = _minimumDepositAmount;
    emit MinimumDepositAmountSet(
      oldMinimumDepositAmount,
      _minimumDepositAmount
    );
  }

  /**
   * @notice Sets fee recipient
   *
   * @param _feeRecipient New fee recipient address
   */
  function setFeeRecipient(
    address _feeRecipient
  ) external override onlyRole(MANAGER_ADMIN) {
    address oldFeeRecipient = feeRecipient;
    feeRecipient = _feeRecipient;
    emit FeeRecipientSet(oldFeeRecipient, _feeRecipient);
  }

  /**
   * @notice Given amount of `collateral`, returns how much CASH should be
   *         minted
   *
   * @param collateralAmountIn Amount of `collateral` to exchange
   *                           (in 18 decimals)
   * @param epoch              The epoch we want to set the rate
   *                           for
   *
   * @return cashAmountOut The amount of cash to be returned
   *
   * @dev Scales to 24 decimals to divide by exchange rate in 6 decimals,
   *      bringing us down to 18 decimals of precision
   */
  function _getMintAmountForEpoch(
    uint256 collateralAmountIn,
    uint256 epoch
  ) private view returns (uint256 cashAmountOut) {
    uint256 amountE36 = _scaleUp(collateralAmountIn) * 1e18;
    cashAmountOut = amountE36 / epochToExchangeRate[epoch];
  }

  /**
   * @notice Given amount of `collateral`, returns how
   *
   *
   * @param collateralAmount Amount `collateral` to exchange
   *                         (in decimals of `collateral`)
   */
  function _getMintFees(
    uint256 collateralAmount
  ) private view returns (uint256) {
    return (collateralAmount * mintFee) / BPS_DENOMINATOR;
  }

  /**
   * @notice Scale provided amount up by `decimalsMultiplier`
   *
   * @dev This helper is used for converting the collateral's decimals
   *      representation to the CASH amount decimals representation.
   */
  function _scaleUp(uint256 amount) private view returns (uint256) {
    return amount * decimalsMultiplier;
  }

  /*//////////////////////////////////////////////////////////////
                            Pause Utils
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Will pause minting functionality of this contract
   *
   */
  function pause() external onlyRole(PAUSER_ADMIN) {
    _pause();
  }

  /**
   * @notice Will unpause minting functionality of this contract
   */
  function unpause() external onlyRole(MANAGER_ADMIN) {
    _unpause();
  }

  /*//////////////////////////////////////////////////////////////
                    Epoch and Rate Limiting Logic
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Update the duration of one epoch
   *
   * @param _epochDuration The epoch duration in seconds
   *
   * @dev The epoch duration must be smaller than `epochStartTimestampOffset`
   */
  function setEpochDuration(
    uint256 _epochDuration
  ) external updateEpoch onlyRole(MANAGER_ADMIN) {
    if (_epochDuration <= epochStartTimestampOffset) {
      revert EpochDurationTooSmall();
    }
    uint256 oldEpochDuration = epochDuration;
    epochDuration = _epochDuration;
    transitionEpoch();
    emit EpochDurationSet(oldEpochDuration, _epochDuration);
  }

  /**
   * @notice Update the epoch start timestamp offset
   *
   * @param _epochStartTimestampOffset The epoch start timestamp offset in seconds
   */
  function setEpochTimestampOffset(
    uint256 _epochStartTimestampOffset
  ) external updateEpoch onlyRole(MANAGER_ADMIN) {
    if (_epochStartTimestampOffset >= epochDuration) {
      revert EpochStartTimestampOffsetTooLarge();
    }

    // Cache epochStartTimestampOffset
    uint256 oldEpochStartTimestampOffset = epochStartTimestampOffset;

    // Variable for holding difference in epoch offsets
    uint256 epochOffsetDiff;

    // `currentEpochStartTimestamp` will be moved forward, making the current
    // epoch longer and positively translating the epoch
    if (_epochStartTimestampOffset > oldEpochStartTimestampOffset) {
      // Need to ensure that forwarding `currentEpochStartTimestamp` will not
      // cause an underflow in `transitionEpoch`
      epochOffsetDiff =
        _epochStartTimestampOffset -
        oldEpochStartTimestampOffset;
      if (block.timestamp < currentEpochStartTimestamp + epochOffsetDiff) {
        revert InvalidOffsetAtCurrentTime();
      }
      currentEpochStartTimestamp += epochOffsetDiff;
    }
    // `currentEpochStartTimestamp` will be moved backwards, making the current
    // epoch shorter and negatively translating the epoch
    else {
      // We are already at a timestamp that is > currentEpochStartTimestamp, so
      // there is no need to worry about potential underflow
      epochOffsetDiff =
        oldEpochStartTimestampOffset -
        _epochStartTimestampOffset;
      currentEpochStartTimestamp -= epochOffsetDiff;
    }

    epochStartTimestampOffset = _epochStartTimestampOffset;

    transitionEpoch();

    emit EpochStartTimestampOffsetSet(
      oldEpochStartTimestampOffset,
      _epochStartTimestampOffset
    );
  }

  /**
   * @notice Modifier to transition epoch
   */
  modifier updateEpoch() {
    transitionEpoch();
    _;
  }

  /**
   * @notice Transition to another epoch
   *
   * @dev Should be called prior to `_checkAndUpdateRedeemLimit`
   *      and `_checkAndUpdateMintLimit`
   * @dev `currentEpoch` can only be incremented
   *
   * @notice If this function increments the epoch
   *         1) `currentRedeemAmount` & `currentMintAmount` are set to 0
   *         2) `currentEpoch` is incremented by number of epochs that
   *            have elapsed
   *         3) `currentEpochStartTimestamp` is set.
   */
  function transitionEpoch() public {
    uint256 epochDifference = (block.timestamp - currentEpochStartTimestamp) /
      epochDuration;
    if (epochDifference > 0) {
      currentRedeemAmount = 0;
      currentMintAmount = 0;
      currentEpoch += epochDifference;
      currentEpochStartTimestamp =
        block.timestamp -
        (block.timestamp % epochDuration) +
        epochStartTimestampOffset;

      if (currentEpochStartTimestamp > block.timestamp) {
        currentEpochStartTimestamp -= epochDuration;
      }
    }
  }

  /**
   * @notice Update the amount of token that can be minted during one epoch
   *
   * @param _mintLimit The token amount
   *
   * @dev If a limit is zero, the relevant check always fails.
   */
  function setMintLimit(uint256 _mintLimit) external onlyRole(MANAGER_ADMIN) {
    uint256 oldMintLimit = mintLimit;
    mintLimit = _mintLimit;
    emit MintLimitSet(oldMintLimit, _mintLimit);
  }

  /**
   * @notice Update the amount of token that can be redeemed during one epoch
   *
   * @param _redeemLimit The token amount
   *
   * @dev If a limit is zero, the relevant check always fails.
   */
  function setRedeemLimit(
    uint256 _redeemLimit
  ) external onlyRole(MANAGER_ADMIN) {
    uint256 oldRedeemLimit = redeemLimit;
    redeemLimit = _redeemLimit;
    emit RedeemLimitSet(oldRedeemLimit, _redeemLimit);
  }

  /**
   * @notice Checks the requested mint amount against the rate limiter
   *
   * @param collateralAmountIn The requested mint amount
   *
   * @dev Reverts if the requested mint amount exceeds the current limit
   * @dev Should only be called w/n functions w/ `updateEpoch` modifier
   */
  function _checkAndUpdateMintLimit(uint256 collateralAmountIn) private {
    if (collateralAmountIn > mintLimit - currentMintAmount) {
      revert MintExceedsRateLimit();
    }

    currentMintAmount += collateralAmountIn;
  }

  /**
   * @notice Checks the requested redeem amount against the rate limiter
   *
   * @param amount The requested redeem amount
   *
   * @dev Reverts if the requested redeem amount exceeds the current limit
   * @dev Should only be called w/n function w/ `updateEpoch` modifier
   */
  function _checkAndUpdateRedeemLimit(uint256 amount) private {
    if (amount == 0) {
      revert RedeemAmountCannotBeZero();
    }
    if (amount > redeemLimit - currentRedeemAmount) {
      revert RedeemExceedsRateLimit();
    }

    currentRedeemAmount += amount;
  }

  /*//////////////////////////////////////////////////////////////
                          Redeem Logic
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Adds a RedemptionRequests member to the current epoch array &
   *         burns tokens
   *
   * @param amountCashToRedeem The requested redeem amount
   */
  function requestRedemption(
    uint256 amountCashToRedeem
  )
    external
    override
    updateEpoch
    nonReentrant
    whenNotPaused
    checkKYC(msg.sender)
  {
    if (amountCashToRedeem < minimumRedeemAmount) {
      revert WithdrawRequestAmountTooSmall();
    }

    _checkAndUpdateRedeemLimit(amountCashToRedeem);

    redemptionInfoPerEpoch[currentEpoch].addressToBurnAmt[
        msg.sender
      ] += amountCashToRedeem;
    redemptionInfoPerEpoch[currentEpoch].totalBurned += amountCashToRedeem;

    cash.burnFrom(msg.sender, amountCashToRedeem);

    emit RedemptionRequested(msg.sender, amountCashToRedeem, currentEpoch);
  }

  /**
   * @notice Allows for an admin account to distribute collateral to users
   *         based off of the total amount of cash tokens burned w/n a given
   *         epoch. This function also allows for an admin to refund redemption
   *         requests w/n an epoch provided that the redemption cannot be
   *         serviced
   *
   * @param redeemers              List of addresses to which we want to
   *                               issue redemptions to
   * @param refundees              List of addresses to which we want to issue
   *                               refunds to in the form of cash tokens
   * @param collateralAmountToDist The total amount to distribute for redemptions
   *                               including fees to accrue to Ondo
   *                               (In units of collateral)
   * @param epochToService         The epoch number we wish to issue redemptions/
   *                               refunds for
   * @param fees                   The amount of fees to send to Ondo
   *                               (In units of collateral)
   */
  function completeRedemptions(
    address[] calldata redeemers,
    address[] calldata refundees,
    uint256 collateralAmountToDist,
    uint256 epochToService,
    uint256 fees
  ) external override updateEpoch onlyRole(MANAGER_ADMIN) {
    _checkAddressesKYC(redeemers);
    _checkAddressesKYC(refundees);
    if (epochToService >= currentEpoch) {
      revert MustServicePastEpoch();
    }
    // Calculate the total quantity of shares tokens burned w/n an epoch
    uint256 refundedAmt = _processRefund(refundees, epochToService);
    uint256 totalBurnedAfterRefunds = redemptionInfoPerEpoch[epochToService]
      .totalBurned - refundedAmt;
    redemptionInfoPerEpoch[epochToService]
      .totalBurned = totalBurnedAfterRefunds;
    uint256 amountToDist = collateralAmountToDist - fees;
    _processRedemption(
      redeemers,
      amountToDist,
      totalBurnedAfterRefunds,
      epochToService
    );
    if (fees > 0) {
      collateral.safeTransferFrom(assetSender, feeRecipient, fees);
    }
    emit RedemptionFeesCollected(feeRecipient, fees, epochToService);
  }

  /**
   * @notice Will iterate over the array of `addressToWithdraw` calculate
   *         the proportion of burned tokens w/n a given epoch and will
   *         then distribute collateral based off this % of burned tokens
   *
   * @param redeemers               List of addresses to issue redemptions too
   * @param amountToDist            The amount to distribute to clients minus
   *                                the fee amount taken by Ondo
   * @param totalBurnedAfterRefunds The total amount of tokens burned in an
   *                                epoch minus those burned by users who
   *                                are issued a refund
   * @param epochToService          The epoch we wish to service redemptions
   *                                and redemptions for
   */
  function _processRedemption(
    address[] calldata redeemers,
    uint256 amountToDist,
    uint256 totalBurnedAfterRefunds,
    uint256 epochToService
  ) private {
    uint256 size = redeemers.length;
    for (uint256 i = 0; i < size; ++i) {
      address redeemer = redeemers[i];
      uint256 cashAmountReturned = redemptionInfoPerEpoch[epochToService]
        .addressToBurnAmt[redeemer];
      redemptionInfoPerEpoch[epochToService].addressToBurnAmt[redeemer] = 0;
      uint256 collateralAmountDue = (amountToDist * cashAmountReturned) /
        totalBurnedAfterRefunds;

      if (collateralAmountDue == 0) {
        revert CollateralRedemptionTooSmall();
      }

      collateral.safeTransferFrom(assetSender, redeemer, collateralAmountDue);
      emit RedemptionCompleted(
        redeemer,
        cashAmountReturned,
        collateralAmountDue,
        epochToService
      );
    }
  }

  /**
   * @notice Iterates over the array of `addressToRefund` and mint them
   *         back the same quantity of cash tokens burned.
   *
   * @param refundees      List of addresses we are issuing refunds for
   * @param epochToService The epoch we wish to service redemptions for
   *
   * @return totalCashAmountRefunded The total amount of cash refunded for `epochToService`.
   */
  function _processRefund(
    address[] calldata refundees,
    uint256 epochToService
  ) private returns (uint256 totalCashAmountRefunded) {
    uint256 size = refundees.length;
    for (uint256 i = 0; i < size; ++i) {
      address refundee = refundees[i];
      uint256 cashAmountBurned = redemptionInfoPerEpoch[epochToService]
        .addressToBurnAmt[refundee];
      redemptionInfoPerEpoch[epochToService].addressToBurnAmt[refundee] = 0;
      cash.mint(refundee, cashAmountBurned);
      totalCashAmountRefunded += cashAmountBurned;
      emit RefundIssued(refundee, cashAmountBurned, epochToService);
    }
    return totalCashAmountRefunded;
  }

  /**
   * @notice will change the `assetSender` variable
   *
   * @param newAssetSender The address we wish to change `assetSender` too
   */
  function setAssetSender(
    address newAssetSender
  ) external onlyRole(MANAGER_ADMIN) {
    address oldAssetSender = assetSender;
    assetSender = newAssetSender;
    emit AssetSenderSet(oldAssetSender, newAssetSender);
  }

  /**
   * @notice Allows for `MANAGER_ADMIN` to set a new `minimumRedeemAmount`
   *
   * @param newRedeemMinimum The new minimum redemption amount
   *                         in units of 1e18
   */
  function setRedeemMinimum(
    uint256 newRedeemMinimum
  ) external onlyRole(MANAGER_ADMIN) {
    uint256 oldRedeemMin = minimumRedeemAmount;
    minimumRedeemAmount = newRedeemMinimum;
    emit MinimumRedeemAmountSet(oldRedeemMin, minimumRedeemAmount);
  }

  /**
   * @notice Custom view function to return the quantity burned by
   *         an address w/n a given epoch.
   *
   * @param epoch The epoch we want to query
   * @param user  The user we want to know the burned quantity
   *              of cash tokens for in a given epoch
   */
  function getBurnedQuantity(
    uint256 epoch,
    address user
  ) external view returns (uint256) {
    return redemptionInfoPerEpoch[epoch].addressToBurnAmt[user];
  }

  /**
   * @notice Override admin function for changing the representation of the
   *         amount of CASH a user has burned to kick off redemption process
   *
   * @param user       The user whose balance is being set
   * @param epoch      The epoch in which to set user balance for
   * @param oldBalance The user's old redemption balance
   * @param balance    The user's new balance
   *
   * @dev The total burned amount for the epoch must be set appropriately
   *      in order to correctly calculate redemptions.
   */
  function setPendingRedemptionBalance(
    address user,
    uint256 epoch,
    uint256 oldBalance,
    uint256 balance
  ) external updateEpoch onlyRole(MANAGER_ADMIN) {
    if (epoch > currentEpoch) {
      revert CannotServiceFutureEpoch();
    }
    uint256 previousBalance = redemptionInfoPerEpoch[epoch].addressToBurnAmt[
      user
    ];
    if (oldBalance != previousBalance) {
      revert RedemptionBalanceMismatch();
    }
    // Increment or decrement total burned for the epoch based on whether we
    // are increasing or decreasing the balance.
    if (balance < previousBalance) {
      redemptionInfoPerEpoch[epoch].totalBurned -= previousBalance - balance;
    } else if (balance > previousBalance) {
      redemptionInfoPerEpoch[epoch].totalBurned += balance - previousBalance;
    }
    redemptionInfoPerEpoch[epoch].addressToBurnAmt[user] = balance;
    emit PendingRedemptionBalanceSet(
      user,
      epoch,
      balance,
      redemptionInfoPerEpoch[epoch].totalBurned
    );
  }

  /*//////////////////////////////////////////////////////////////
                           KYC FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Modifier to check KYC status of an account
   */
  modifier checkKYC(address account) {
    _checkKYC(account);
    _;
  }

  /**
   * @notice Update KYC group of the contract for which
   *         accounts are checked against
   *
   * @param _kycRequirementGroup The new KYC requirement group
   */
  function setKYCRequirementGroup(
    uint256 _kycRequirementGroup
  ) external override onlyRole(MANAGER_ADMIN) {
    _setKYCRequirementGroup(_kycRequirementGroup);
  }

  /**
   * @notice Update KYC registry address
   *
   * @param _kycRegistry The new KYC registry address
   */
  function setKYCRegistry(
    address _kycRegistry
  ) external override onlyRole(MANAGER_ADMIN) {
    _setKYCRegistry(_kycRegistry);
  }

  /**
   * @notice Private function to check KYC status
   *         of an address
   *
   * @param account The account to check KYC status for
   */
  function _checkKYC(address account) private view {
    if (!_getKYCStatus(account)) {
      revert KYCCheckFailed();
    }
  }

  /**
   * @notice Private function to check KYC status
   *         of an array of addresses
   *
   * @param accounts The accounts to check KYC status for
   */
  function _checkAddressesKYC(address[] calldata accounts) private view {
    uint256 size = accounts.length;
    for (uint256 i = 0; i < size; ++i) {
      _checkKYC(accounts[i]);
    }
  }

  /**
   * @notice Allows for arbitrary batched calls
   *
   * @dev All external calls made through this function will
   *      msg.sender == contract address
   *
   * @param exCallData Struct consisting of
   *       1) target - contract to call
   *       2) data - data to call target with
   *       3) value - eth value to call target with
   */
  function multiexcall(
    ExCallData[] calldata exCallData
  )
    external
    payable
    override
    nonReentrant
    onlyRole(MANAGER_ADMIN)
    whenPaused
    returns (bytes[] memory results)
  {
    results = new bytes[](exCallData.length);
    for (uint256 i = 0; i < exCallData.length; ++i) {
      (bool success, bytes memory ret) = address(exCallData[i].target).call{
        value: exCallData[i].value
      }(exCallData[i].data);
      require(success, "Call Failed");
      results[i] = ret;
    }
  }
}