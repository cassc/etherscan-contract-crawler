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

import "contracts/interfaces/IPricerReader.sol";
import "contracts/interfaces/IRWALike.sol";
import "contracts/external/openzeppelin/contracts/token/IERC20.sol";
import "contracts/external/openzeppelin/contracts/token/SafeERC20.sol";
import "contracts/interfaces/IRWAHub.sol";

// Additional Dependencies
import "contracts/external/openzeppelin/contracts/token/IERC20Metadata.sol";
import "contracts/external/openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "contracts/external/openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract RWAHub is IRWAHub, ReentrancyGuard, AccessControlEnumerable {
  using SafeERC20 for IERC20;
  // RWA Token contract
  IRWALike public immutable rwa;
  // Pointer to Pricer
  IPricerReader public pricer;
  // Address to receive deposits
  address public constant assetRecipient =
    0x786A5b6B303453D4079C957895130302bAefcecC; // USDY - CB Deposit Address
  // Address to send redemptions
  address public assetSender;
  // Address fee recipient
  address public feeRecipient;
  // Mapping from deposit Id -> Depositor
  mapping(bytes32 => Depositor) public depositIdToDepositor;
  // Mapping from redemptionId -> Redeemer
  mapping(bytes32 => Redeemer) public redemptionIdToRedeemer;

  /// @dev Mint/Redeem Parameters
  // Minimum amount that must be deposited to mint the RWA token
  // Denoted in decimals of `collateral`
  uint256 public minimumDepositAmount;

  // Minimum amount that must be redeemed for a withdraw request
  uint256 public minimumRedemptionAmount;

  // Minting fee specified in basis points
  uint256 public mintFee = 0;

  // Redemption fee specified in basis points
  uint256 public redemptionFee = 0;

  // The asset accepted by the RWAHub
  IERC20 public immutable collateral;

  // Decimal multiplier representing the difference between `rwa` decimals
  // In `collateral` token decimals
  uint256 public immutable decimalsMultiplier;

  // Deposit counter to map subscription requests to
  uint256 public subscriptionRequestCounter = 1;

  // Redemption Id to map from
  uint256 public redemptionRequestCounter = 1;

  // Helper constant that allows us to specify basis points in calculations
  uint256 public constant BPS_DENOMINATOR = 10_000;

  // Pause variables
  bool public redemptionPaused;
  bool public subscriptionPaused;

  /// @dev Role based access control roles
  bytes32 public constant MANAGER_ADMIN = keccak256("MANAGER_ADMIN");
  bytes32 public constant PAUSER_ADMIN = keccak256("PAUSER_ADMIN");
  bytes32 public constant PRICE_ID_SETTER_ROLE =
    keccak256("PRICE_ID_SETTER_ROLE");
  bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

  /// @notice constructor
  constructor(
    address _collateral,
    address _rwa,
    address managerAdmin,
    address pauser,
    address _assetSender,
    address _feeRecipient,
    uint256 _minimumDepositAmount,
    uint256 _minimumRedemptionAmount
  ) {
    if (_collateral == address(0)) {
      revert CollateralCannotBeZero();
    }
    if (_rwa == address(0)) {
      revert RWACannotBeZero();
    }
    if (_assetSender == address(0)) {
      revert AssetSenderCannotBeZero();
    }
    if (_feeRecipient == address(0)) {
      revert FeeRecipientCannotBeZero();
    }

    _grantRole(DEFAULT_ADMIN_ROLE, managerAdmin);
    _grantRole(MANAGER_ADMIN, managerAdmin);
    _grantRole(PAUSER_ADMIN, pauser);
    _setRoleAdmin(PAUSER_ADMIN, MANAGER_ADMIN);
    _setRoleAdmin(PRICE_ID_SETTER_ROLE, MANAGER_ADMIN);
    _setRoleAdmin(RELAYER_ROLE, MANAGER_ADMIN);

    collateral = IERC20(_collateral);
    rwa = IRWALike(_rwa);
    feeRecipient = _feeRecipient;
    assetSender = _assetSender;
    minimumDepositAmount = _minimumDepositAmount;
    minimumRedemptionAmount = _minimumRedemptionAmount;

    decimalsMultiplier =
      10 **
        (IERC20Metadata(_rwa).decimals() -
          IERC20Metadata(_collateral).decimals());
  }

  /*//////////////////////////////////////////////////////////////
                  Subscription/Redemption Functions
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Function used by users to request subscription to the fund
   *
   * @param amount The amount of collateral one wished to deposit
   */
  function requestSubscription(
    uint256 amount
  )
    external
    virtual
    nonReentrant
    ifNotPaused(subscriptionPaused)
    checkRestrictions(msg.sender)
  {
    if (amount < minimumDepositAmount) {
      revert DepositTooSmall();
    }

    uint256 feesInCollateral = _getMintFees(amount);
    uint256 depositAmountAfterFee = amount - feesInCollateral;

    // Link the depositor to their deposit ID
    bytes32 depositId = bytes32(subscriptionRequestCounter++);
    depositIdToDepositor[depositId] = Depositor(
      msg.sender,
      depositAmountAfterFee,
      0
    );

    if (feesInCollateral > 0) {
      collateral.safeTransferFrom(msg.sender, feeRecipient, feesInCollateral);
    }

    collateral.safeTransferFrom(
      msg.sender,
      assetRecipient,
      depositAmountAfterFee
    );

    emit MintRequested(
      msg.sender,
      depositId,
      amount,
      depositAmountAfterFee,
      feesInCollateral
    );
  }

  /**
   * @notice Function used to claim tokens corresponding to a deposit request
   *
   * @param depositIds An array containing the deposit Ids one wishes to claim
   *
   * @dev Implicitly does all transfer checks present in underlying `rwa`
   * @dev The priceId corresponding to a given depositId must be set prior to
   *      claiming a mint
   */
  function claimMint(
    bytes32[] calldata depositIds
  ) external virtual nonReentrant ifNotPaused(subscriptionPaused) {
    uint256 depositsSize = depositIds.length;
    for (uint256 i = 0; i < depositsSize; ++i) {
      _claimMint(depositIds[i]);
    }
  }

  /**
   * @notice Internal claim mint helper
   *
   * @dev This function can be overriden to implement custom claiming logic
   */
  function _claimMint(bytes32 depositId) internal virtual {
    Depositor memory depositor = depositIdToDepositor[depositId];
    // Revert if priceId is not set
    if (depositor.priceId == 0) {
      revert PriceIdNotSet();
    }

    uint256 price = pricer.getPrice(depositor.priceId);
    uint256 rwaOwed = _getMintAmountForPrice(
      depositor.amountDepositedMinusFees,
      price
    );

    delete depositIdToDepositor[depositId];
    rwa.mint(depositor.user, rwaOwed);

    emit MintCompleted(
      depositor.user,
      depositId,
      rwaOwed,
      depositor.amountDepositedMinusFees,
      price,
      depositor.priceId
    );
  }

  /**
   * @notice Function used by users to request a redemption from the fund
   *
   * @param amount The amount (in units of `rwa`) that a user wishes to redeem
   *               from the fund
   */
  function requestRedemption(
    uint256 amount
  ) external virtual nonReentrant ifNotPaused(redemptionPaused) {
    if (amount < minimumRedemptionAmount) {
      revert RedemptionTooSmall();
    }
    bytes32 redemptionId = bytes32(redemptionRequestCounter++);
    redemptionIdToRedeemer[redemptionId] = Redeemer(msg.sender, amount, 0);

    rwa.burnFrom(msg.sender, amount);

    emit RedemptionRequested(msg.sender, redemptionId, amount);
  }

  /**
   * @notice Function to claim collateral corresponding to a redemption request
   *
   * @param redemptionIds an Array of redemption Id's which ought to fulfilled
   *
   * @dev Implicitly does all checks present in underlying `rwa`
   * @dev The price Id corresponding to a redemptionId must be set prior to
   *      claiming a redemption
   */
  function claimRedemption(
    bytes32[] calldata redemptionIds
  ) external virtual nonReentrant ifNotPaused(redemptionPaused) {
    uint256 fees;
    uint256 redemptionsSize = redemptionIds.length;
    for (uint256 i = 0; i < redemptionsSize; ++i) {
      Redeemer memory member = redemptionIdToRedeemer[redemptionIds[i]];
      _checkRestrictions(member.user);
      if (member.priceId == 0) {
        // Then the price for this redemption has not been set
        revert PriceIdNotSet();
      }

      // Calculate collateral due and fees
      uint256 price = pricer.getPrice(member.priceId);
      uint256 collateralDue = _getRedemptionAmountForRwa(
        member.amountRwaTokenBurned,
        price
      );
      uint256 fee = _getRedemptionFees(collateralDue);
      uint256 collateralDuePostFees = collateralDue - fee;
      fees += fee;

      delete redemptionIdToRedeemer[redemptionIds[i]];

      collateral.safeTransferFrom(
        assetSender,
        member.user,
        collateralDuePostFees
      );

      emit RedemptionCompleted(
        member.user,
        redemptionIds[i],
        member.amountRwaTokenBurned,
        collateralDuePostFees,
        fee,
        price,
        member.priceId
      );
    }
    if (fees > 0) {
      collateral.safeTransferFrom(assetSender, feeRecipient, fees);
    }
  }

  /*//////////////////////////////////////////////////////////////
                         Relayer Functions
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Adds a deposit proof to the contract
   *
   * @param txHash                The transaction hash of the deposit
   * @param user                  The address of the user who made the deposit
   * @param depositAmountAfterFee The amount of the deposit after fees
   * @param feeAmount             The amount of the fees taken
   * @param timestamp             The timestamp of the deposit
   *
   * @dev txHash is used as the depositId in storage
   * @dev All amounts are in decimals of `collateral`
   */
  function addProof(
    bytes32 txHash,
    address user,
    uint256 depositAmountAfterFee,
    uint256 feeAmount,
    uint256 timestamp
  ) external override onlyRole(RELAYER_ROLE) checkRestrictions(user) {
    if (depositIdToDepositor[txHash].user != address(0)) {
      revert DepositProofAlreadyExists();
    }
    depositIdToDepositor[txHash] = Depositor(user, depositAmountAfterFee, 0);
    emit DepositProofAdded(
      txHash,
      user,
      depositAmountAfterFee,
      feeAmount,
      timestamp
    );
  }

  /*//////////////////////////////////////////////////////////////
                           PriceId Setters
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Admin function to associate a depositId with a given Price Id
   *
   * @param depositIds an Array of deposit Ids to be associated
   * @param priceIds   an Array of price Ids to be associated
   *
   * @dev Array size must match
   */
  function setPriceIdForDeposits(
    bytes32[] calldata depositIds,
    uint256[] calldata priceIds
  ) external virtual onlyRole(PRICE_ID_SETTER_ROLE) {
    uint256 depositsSize = depositIds.length;
    if (depositsSize != priceIds.length) {
      revert ArraySizeMismatch();
    }
    for (uint256 i = 0; i < depositsSize; ++i) {
      if (depositIdToDepositor[depositIds[i]].user == address(0)) {
        revert DepositorNull();
      }
      if (depositIdToDepositor[depositIds[i]].priceId != 0) {
        revert PriceIdAlreadySet();
      }
      depositIdToDepositor[depositIds[i]].priceId = priceIds[i];
      emit PriceIdSetForDeposit(depositIds[i], priceIds[i]);
    }
  }

  /**
   * @notice Admin function to associate redemptionId with a given priceId
   *
   * @param redemptionIds an Array of redemptionIds to associate
   * @param priceIds  an Array of priceIds to associate
   */
  function setPriceIdForRedemptions(
    bytes32[] calldata redemptionIds,
    uint256[] calldata priceIds
  ) external virtual onlyRole(PRICE_ID_SETTER_ROLE) {
    uint256 redemptionsSize = redemptionIds.length;
    if (redemptionsSize != priceIds.length) {
      revert ArraySizeMismatch();
    }
    for (uint256 i = 0; i < redemptionsSize; ++i) {
      if (redemptionIdToRedeemer[redemptionIds[i]].priceId != 0) {
        revert PriceIdAlreadySet();
      }
      redemptionIdToRedeemer[redemptionIds[i]].priceId = priceIds[i];
      emit PriceIdSetForRedemption(redemptionIds[i], priceIds[i]);
    }
  }

  /*//////////////////////////////////////////////////////////////
                           Admin Setters
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Admin function to overwrite entries in the depoitIdToDepositor
   *         mapping
   *
   * @param depositIdToOverwrite  The depositId of the entry we wish to
   *                              overwrite
   * @param user                  The user for the new entry
   * @param depositAmountAfterFee The deposit value for the new entry
   * @param priceId               The priceId to be associated with the new
   *                              entry
   */
  function overwriteDepositor(
    bytes32 depositIdToOverwrite,
    address user,
    uint256 depositAmountAfterFee,
    uint256 priceId
  ) external onlyRole(MANAGER_ADMIN) checkRestrictions(user) {
    Depositor memory oldDepositor = depositIdToDepositor[depositIdToOverwrite];

    depositIdToDepositor[depositIdToOverwrite] = Depositor(
      user,
      depositAmountAfterFee,
      priceId
    );

    emit DepositorOverwritten(
      depositIdToOverwrite,
      oldDepositor.user,
      user,
      oldDepositor.priceId,
      priceId,
      oldDepositor.amountDepositedMinusFees,
      depositAmountAfterFee
    );
  }

  /**
   * @notice Admin function to overwrite entries in the redemptionIdToRedeemer
   *         mapping
   *
   * @param redemptionIdToOverwrite The redemptionId of the entry we wish to
   *                                overwrite
   * @param user                    The user for the new entry
   * @param rwaTokenAmountBurned    The burn amount for the new entry
   * @param priceId                 The priceID to be associated with the new
   *                                entry
   */
  function overwriteRedeemer(
    bytes32 redemptionIdToOverwrite,
    address user,
    uint256 rwaTokenAmountBurned,
    uint256 priceId
  ) external onlyRole(MANAGER_ADMIN) checkRestrictions(user) {
    Redeemer memory oldRedeemer = redemptionIdToRedeemer[
      redemptionIdToOverwrite
    ];
    redemptionIdToRedeemer[redemptionIdToOverwrite] = Redeemer(
      user,
      rwaTokenAmountBurned,
      priceId
    );
    emit RedeemerOverwritten(
      redemptionIdToOverwrite,
      oldRedeemer.user,
      user,
      oldRedeemer.priceId,
      priceId,
      oldRedeemer.amountRwaTokenBurned,
      rwaTokenAmountBurned
    );
  }

  /**
   * @notice Admin function to set the minimum amount to redeem
   *
   * @param _minimumRedemptionAmount The minimum amount required to submit a
   *                                 redemption request
   */
  function setMinimumRedemptionAmount(
    uint256 _minimumRedemptionAmount
  ) external onlyRole(MANAGER_ADMIN) {
    if (_minimumRedemptionAmount < BPS_DENOMINATOR) {
      revert AmountTooSmall();
    }
    uint256 oldRedeemMinimum = minimumRedemptionAmount;
    minimumRedemptionAmount = _minimumRedemptionAmount;
    emit MinimumRedemptionAmountSet(oldRedeemMinimum, _minimumRedemptionAmount);
  }

  /**
   * @notice Admin function to set the minimum amount required for a deposit
   *
   * @param minDepositAmount The minimum amount required to submit a deposit
   *                         request
   */
  function setMinimumDepositAmount(
    uint256 minDepositAmount
  ) external onlyRole(MANAGER_ADMIN) {
    if (minDepositAmount < BPS_DENOMINATOR) {
      revert AmountTooSmall();
    }
    uint256 oldMinimumDepositAmount = minimumDepositAmount;
    minimumDepositAmount = minDepositAmount;
    emit MinimumDepositAmountSet(oldMinimumDepositAmount, minDepositAmount);
  }

  /**
   * @notice Admin function to set the mint fee
   *
   * @param _mintFee The new mint fee specified in basis points
   *
   * @dev The maximum fee that can be set is 10_000 bps, or 100%
   */
  function setMintFee(uint256 _mintFee) external onlyRole(MANAGER_ADMIN) {
    if (_mintFee > BPS_DENOMINATOR) {
      revert FeeTooLarge();
    }
    uint256 oldMintFee = mintFee;
    mintFee = _mintFee;
    emit MintFeeSet(oldMintFee, _mintFee);
  }

  /**
   * @notice Admin function to set the redeem fee
   *
   * @param _redemptionFee The new redeem fee specified in basis points
   *
   * @dev The maximum fee that can be set is 10_000 bps, or 100%
   */
  function setRedemptionFee(
    uint256 _redemptionFee
  ) external onlyRole(MANAGER_ADMIN) {
    if (_redemptionFee > BPS_DENOMINATOR) {
      revert FeeTooLarge();
    }
    uint256 oldRedeemFee = redemptionFee;
    redemptionFee = _redemptionFee;
    emit RedemptionFeeSet(oldRedeemFee, _redemptionFee);
  }

  /**
   * @notice Admin function to set the address of the Pricer contract
   *
   * @param newPricer The address of the new pricer contract
   */
  function setPricer(address newPricer) external onlyRole(MANAGER_ADMIN) {
    address oldPricer = address(pricer);
    pricer = IPricerReader(newPricer);
    emit NewPricerSet(oldPricer, newPricer);
  }

  /**
   * @notice Admin function to set the address of `feeRecipient`
   *
   * @param newFeeRecipient The address of the new `feeRecipient`
   */
  function setFeeRecipient(
    address newFeeRecipient
  ) external onlyRole(MANAGER_ADMIN) {
    address oldFeeRecipient = feeRecipient;
    feeRecipient = newFeeRecipient;
    emit FeeRecipientSet(oldFeeRecipient, feeRecipient);
  }

  /**
   * @notice Admin function to set the address of `assetSender`
   *
   * @param newAssetSender The address of the new `assetSender`
   */
  function setAssetSender(
    address newAssetSender
  ) external onlyRole(MANAGER_ADMIN) {
    address oldAssetSender = assetSender;
    assetSender = newAssetSender;
    emit AssetSenderSet(oldAssetSender, newAssetSender);
  }

  /*//////////////////////////////////////////////////////////////
                            Pause Utils
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Modifier to check if a feature is paused
   *
   * @param feature The feature to check if paused
   */
  modifier ifNotPaused(bool feature) {
    if (feature) {
      revert FeaturePaused();
    }
    _;
  }

  /**
   * @notice Function to pause subscription to RWAHub
   */
  function pauseSubscription() external onlyRole(PAUSER_ADMIN) {
    subscriptionPaused = true;
    emit SubscriptionPaused(msg.sender);
  }

  /**
   * @notice Function to pause redemptions to RWAHub
   */
  function pauseRedemption() external onlyRole(PAUSER_ADMIN) {
    redemptionPaused = true;
    emit RedemptionPaused(msg.sender);
  }

  /**
   * @notice Function to unpause subscriptions to RWAHub
   */
  function unpauseSubscription() external onlyRole(MANAGER_ADMIN) {
    subscriptionPaused = false;
    emit SubscriptionUnpaused(msg.sender);
  }

  /**
   * @notice Function to unpause redemptions to RWAHub
   */
  function unpauseRedemption() external onlyRole(MANAGER_ADMIN) {
    redemptionPaused = false;
    emit RedemptionUnpaused(msg.sender);
  }

  /*//////////////////////////////////////////////////////////////
                      Check Restriction Utils
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Modifier to check restrictions status of an account
   *
   * @param account The account to check
   */
  modifier checkRestrictions(address account) {
    _checkRestrictions(account);
    _;
  }

  /**
   * @notice internal function to check restriction status
   *         of an address
   *
   * @param account The account to check restriction status for
   *
   * @dev This function is virtual to be overridden by child contract
   *      to check restrictions on a more granular level
   */
  function _checkRestrictions(address account) internal view virtual;

  /*//////////////////////////////////////////////////////////////
                           Math Utils
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Given amount of `collateral`, returns how much in fees
   *         are owed
   *
   *
   * @param collateralAmount Amount `collateral` to calculate fees
   *                         (in decimals of `collateral`)
   */
  function _getMintFees(
    uint256 collateralAmount
  ) internal view returns (uint256) {
    return (collateralAmount * mintFee) / BPS_DENOMINATOR;
  }

  /**
   * @notice Given amount of `collateral`, returns how much in fees
   *         are owed
   *
   * @param collateralAmount Amount of `collateral` to calculate fees
   *                         (in decimals of `collateral`)
   */
  function _getRedemptionFees(
    uint256 collateralAmount
  ) internal view returns (uint256) {
    return (collateralAmount * redemptionFee) / BPS_DENOMINATOR;
  }

  /**
   * @notice Given a deposit amount and priceId, returns the amount
   *         of `rwa` due
   *
   * @param depositAmt The amount deposited in units of `collateral`
   * @param price      The price associated with this deposit
   */
  function _getMintAmountForPrice(
    uint256 depositAmt,
    uint256 price
  ) internal view returns (uint256 rwaAmountOut) {
    uint256 amountE36 = _scaleUp(depositAmt) * 1e18;
    // Will revert with div by 0 if price not defined for a priceId
    rwaAmountOut = amountE36 / price;
  }

  /**
   * @notice Given a redemption amount and a priceId, returns the amount
   *         of `collateral` due
   *
   * @param rwaTokenAmountBurned The amount of `rwa` burned for a redemption
   * @param price                The price associated with this redemption
   */
  function _getRedemptionAmountForRwa(
    uint256 rwaTokenAmountBurned,
    uint256 price
  ) internal view returns (uint256 collateralOwed) {
    uint256 amountE36 = rwaTokenAmountBurned * price;
    collateralOwed = _scaleDown(amountE36 / 1e18);
  }

  /**
   * @notice Scale provided amount up by `decimalsMultiplier`
   *
   * @dev This helper is used for converting the collateral's decimals
   *      representation to the RWA amount decimals representation.
   */
  function _scaleUp(uint256 amount) internal view returns (uint256) {
    return amount * decimalsMultiplier;
  }

  /**
   * @notice Scale provided amount down by `decimalsMultiplier`
   *
   * @dev This helper is used for converting `rwa`'s decimal
   *      representation to the `collateral`'s decimal representation
   */
  function _scaleDown(uint256 amount) internal view returns (uint256) {
    return amount / decimalsMultiplier;
  }
}