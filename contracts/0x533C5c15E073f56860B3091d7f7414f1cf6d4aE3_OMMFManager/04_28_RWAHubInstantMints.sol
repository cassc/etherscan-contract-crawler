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

import "contracts/interfaces/IRWAHubInstantMints.sol";
import "contracts/RWAHubOffChainRedemptions.sol";
import "contracts/InstantMintTimeBasedRateLimiter.sol";

abstract contract RWAHubInstantMints is
  IRWAHubInstantMints,
  RWAHubOffChainRedemptions,
  InstantMintTimeBasedRateLimiter
{
  using SafeERC20 for IERC20;

  // Fee collected when instant minting OMMF (in basis points)
  uint256 public instantMintFee = 10;

  // Fee collected when instant redeeming OMMF (in basis points)
  uint256 public instantRedemptionFee = 10;

  // priceId associated with instantMints
  uint256 public instantMintPriceId;

  // priceId associated with instantRedemptions
  uint256 public instantRedemptionPriceId;

  // Flag whether instantMint is paused
  bool public instantMintPaused = true;

  // Flag whether instantRedemption is paused
  bool public instantRedemptionPaused = true;

  // Address to manage instant mints/redemptions
  address public instantMintAssetManager;

  constructor(
    address _collateral,
    address _rwa,
    address managerAdmin,
    address pauser,
    address _assetSender,
    address _feeRecipient,
    uint256 _minimumDepositAmount,
    uint256 _minimumRedemptionAmount,
    address _instantMintAssetManager
  )
    RWAHubOffChainRedemptions(
      _collateral,
      _rwa,
      managerAdmin,
      pauser,
      _assetSender,
      _feeRecipient,
      _minimumDepositAmount,
      _minimumRedemptionAmount
    )
    InstantMintTimeBasedRateLimiter(0, 0, 0, 0)
  {
    instantMintAssetManager = _instantMintAssetManager;
  }

  /*//////////////////////////////////////////////////////////////
                  Instant Mint/Redemption Functions
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Instant mints `rwa` token to the caller in exchange for
   *         `collateral`
   *
   * @param amount The amount of `collateral` to deposit
   *
   * @dev All fees are deducted from amount transferred by
   *      `instantMintAssetManager`
   */
  function instantMint(
    uint256 amount
  ) external nonReentrant ifNotPaused(instantMintPaused) {
    if (amount < minimumDepositAmount) {
      revert DepositTooSmall();
    }

    if (instantMintPriceId == 0) {
      revert PriceIdNotSet();
    }

    // Calculate fees
    uint256 feesInCollateral = _getInstantMintFees(amount);
    uint256 depositAmountAfterFee = amount - feesInCollateral;

    // Transfer collateral
    collateral.safeTransferFrom(msg.sender, instantMintAssetManager, amount);

    // Calculate mint amount
    uint256 price = pricer.getPrice(instantMintPriceId);
    uint256 rwaOwed = _getMintAmountForPrice(depositAmountAfterFee, price);

    // Check mint limit
    _checkAndUpdateInstantMintLimit(rwaOwed);

    // Mint RWA
    rwa.mint(msg.sender, rwaOwed);

    emit InstantMintCompleted(
      msg.sender,
      amount,
      depositAmountAfterFee,
      feesInCollateral,
      rwaOwed,
      price
    );
  }

  /**
   * @notice Instant mints `rwa` token to the caller in exchange for
   *         `collateral`
   *
   * @param amount The amount of `collateral` to deposit
   *
   * @dev All fees are deducted from collateral transferred by
   *      `instantMintAssetManager`
   */
  function instantRedemption(
    uint256 amount
  ) external nonReentrant ifNotPaused(instantRedemptionPaused) {
    // Checks
    if (amount < minimumRedemptionAmount) {
      revert RedemptionTooSmall();
    }

    if (instantRedemptionPriceId == 0) {
      revert PriceIdNotSet();
    }

    // Update instant redemption limit
    _checkAndUpdateInstantRedemptionLimit(amount);

    // Calculate collateralDue and fees
    uint256 price = pricer.getPrice(instantRedemptionPriceId);
    uint256 collateralDue = _getRedemptionAmountForRwa(amount, price);
    uint256 feesInCollateral = _getinstantRedemptionFees(collateralDue);
    uint256 collateralDuePostFees = collateralDue - feesInCollateral;

    // Burn rwa and transfer collateral
    rwa.burnFrom(msg.sender, amount);

    collateral.safeTransferFrom(
      instantMintAssetManager,
      msg.sender,
      collateralDuePostFees
    );

    emit InstantRedemptionCompleted(
      msg.sender,
      amount,
      collateralDuePostFees,
      feesInCollateral,
      price,
      instantRedemptionPriceId
    );
  }

  /**
   * @notice Guarded function to set the `instantMintAssetManager`
   *
   * @param _instantMintAssetManager The address to update
   *                                 `instantMintAssetManager` to
   */
  function setInstantMintAssetManager(
    address _instantMintAssetManager
  ) external onlyRole(MANAGER_ADMIN) {
    address oldInstantMintAssetManager = instantMintAssetManager;
    instantMintAssetManager = _instantMintAssetManager;
    emit InstantMintAssetManagerSet(
      oldInstantMintAssetManager,
      _instantMintAssetManager
    );
  }

  /*//////////////////////////////////////////////////////////////
                    Instant Mint/Redeem Fee Utils
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Sets the instant mint fee
   *
   * @param _instantMintFee new mint fee specified in basis points
   *
   * @dev `_instantMintFee` must not exceed 100% (or 10_000 bps)
   */
  function setInstantMintFee(
    uint256 _instantMintFee
  ) external onlyRole(MANAGER_ADMIN) {
    if (_instantMintFee > BPS_DENOMINATOR) {
      revert FeeTooLarge();
    }
    uint256 oldInstantMintFee = instantMintFee;
    instantMintFee = _instantMintFee;
    emit InstantMintFeeSet(oldInstantMintFee, _instantMintFee);
  }

  /**
   * @notice Sets instant redemption fee.
   *
   * @param _instantRedemptionFee new redemption fee specified in basis points
   *
   * @dev `_instantRedemptionFee` must not exceed 100% (or 10_000 bps)
   */
  function setInstantRedemptionFee(
    uint256 _instantRedemptionFee
  ) external onlyRole(MANAGER_ADMIN) {
    if (_instantRedemptionFee > BPS_DENOMINATOR) {
      revert FeeTooLarge();
    }
    uint256 oldinstantRedemptionFee = instantRedemptionFee;
    instantRedemptionFee = _instantRedemptionFee;
    emit InstantRedemptionFeeSet(
      oldinstantRedemptionFee,
      _instantRedemptionFee
    );
  }

  /**
   * @notice Given amount of `collateral`, returns how much in fees
   *         are owed
   *
   * @param collateralAmount Amount of `collateral` to calculate fees
   *                         (in decimals of `collateral`)
   */
  function _getInstantMintFees(
    uint256 collateralAmount
  ) internal view returns (uint256) {
    return (collateralAmount * instantMintFee) / BPS_DENOMINATOR;
  }

  /**
   * @notice Given amount of `collateral`, returns how much in fees
   *         are owed
   *
   * @param collateralAmount Amount `collateral` to calculate fees
   *                         (in decimals of `collateral`)
   */
  function _getinstantRedemptionFees(
    uint256 collateralAmount
  ) internal view returns (uint256) {
    return (collateralAmount * instantRedemptionFee) / BPS_DENOMINATOR;
  }

  /*//////////////////////////////////////////////////////////////
                    Instant Mint/Redeem Setters
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Function to set priceId for instant mints
   */
  function setInstantMintPriceId(
    uint256 _instantMintPriceId
  ) external onlyRole(PRICE_ID_SETTER_ROLE) {
    instantMintPriceId = _instantMintPriceId;
    emit PriceIdSetForInstantMint(_instantMintPriceId);
  }

  /**
   * @notice Function to set priceId for instant redemptions
   */
  function setInstantRedemptionPriceId(
    uint256 _instantRedemptionPriceId
  ) external onlyRole(PRICE_ID_SETTER_ROLE) {
    instantRedemptionPriceId = _instantRedemptionPriceId;
    emit PriceIdSetForInstantRedemption(_instantRedemptionPriceId);
  }

  /**
   * @notice Function to pause instant mints
   */
  function pauseInstantMint() external onlyRole(PAUSER_ADMIN) {
    instantMintPaused = true;
    emit InstantMintPaused(msg.sender);
  }

  /**
   * @notice Function to unpause instant mints
   */
  function unpauseInstantMint() external onlyRole(MANAGER_ADMIN) {
    instantMintPaused = false;
    emit InstantMintUnpaused(msg.sender);
  }

  /**
   * @notice Function to pause instant redemptions
   */
  function pauseInstantRedemption() external onlyRole(PAUSER_ADMIN) {
    instantRedemptionPaused = true;
    emit InstantRedemptionPaused(msg.sender);
  }

  /**
   * @notice Function to unpause instant redemptions
   */
  function unpauseInstantRedemption() external onlyRole(MANAGER_ADMIN) {
    instantRedemptionPaused = false;
    emit InstantRedemptionUnpaused(msg.sender);
  }

  /*//////////////////////////////////////////////////////////////
                     Rate Limiter Configuration
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Set the mintLimit constraint inside the TimeBasedRateLimiter
   *         base contract
   *
   * @param newMintLimit New limit that dictates how much RWA can be minted
   *                     in a specified duration
   *                     (in 18 decimals per the RWA contract)
   */
  function setInstantMintLimit(
    uint256 newMintLimit
  ) external onlyRole(MANAGER_ADMIN) {
    _setInstantMintLimit(newMintLimit);
  }

  /**
   * @notice Set the RedemptionLimit constraint inside the TimeBasedRateLimiter
   *         base contract
   *
   * @param newRedemptionLimit New limit that dicates how much RWA
   *                       can be redeemed in a specified duration
   *                       (in 18 decimals per the RWA contract)
   */
  function setInstantRedemptionLimit(
    uint256 newRedemptionLimit
  ) external onlyRole(MANAGER_ADMIN) {
    _setInstantRedemptionLimit(newRedemptionLimit);
  }

  /**
   * @notice Sets mintLimitDuration constraint inside the TimeBasedRateLimiter
   *         base contract
   *
   * @param newMintLimitDuration New limit that specifies the interval
   *                             (in seconds) in which only mintLimit RWA
   *                             can be minted within
   */
  function setInstantMintLimitDuration(
    uint256 newMintLimitDuration
  ) external onlyRole(MANAGER_ADMIN) {
    _setInstantMintLimitDuration(newMintLimitDuration);
  }

  /**
   * @notice Sets RedemptionLimitDuration inside the TimeBasedRateLimiter
   *         base contract
   *
   * @param newRedemptionLimitDuration New limit that specifies the interval
   *                               (in seconds) in which only RedemptionLimit RWA
   *                               can be redeemed within
   */
  function setInstantRedemptionLimitDuration(
    uint256 newRedemptionLimitDuration
  ) external onlyRole(MANAGER_ADMIN) {
    _setInstantRedemptionLimitDuration(newRedemptionLimitDuration);
  }
}