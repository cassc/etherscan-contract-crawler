// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/SafeCast.sol";
import {SignedSafeMath} from "@openzeppelin/contracts/math/SignedSafeMath.sol";
import {Math} from "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/drafts/IERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

import {ISeniorPool} from "../../interfaces/ISeniorPool.sol";
import {IFidu} from "../../interfaces/IFidu.sol";
import {ISeniorPoolEpochWithdrawals} from "../../interfaces/ISeniorPoolEpochWithdrawals.sol";
import {IWithdrawalRequestToken} from "../../interfaces/IWithdrawalRequestToken.sol";
import {ISeniorPoolStrategy} from "../../interfaces/ISeniorPoolStrategy.sol";
import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";
import {ICUSDCContract} from "../../interfaces/ICUSDCContract.sol";
import {IERC20withDec} from "../../interfaces/IERC20withDec.sol";
import {IPoolTokens} from "../../interfaces/IPoolTokens.sol";
import {Accountant} from "./Accountant.sol";
import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";

/**
 * @title Goldfinch's SeniorPool contract
 * @notice Main entry point for senior LPs (a.k.a. capital providers)
 *  Automatically invests across borrower pools using an adjustable strategy.
 * @author Goldfinch
 */
contract SeniorPool is BaseUpgradeablePausable, ISeniorPool {
  using SignedSafeMath for int256;
  using Math for uint256;
  using SafeCast for uint256;
  using SafeCast for int256;
  using ConfigHelper for GoldfinchConfig;
  using SafeERC20 for IFidu;
  using SafeERC20 for IERC20withDec;

  uint256 internal constant USDC_MANTISSA = 1e6;
  uint256 internal constant FIDU_MANTISSA = 1e18;
  bytes32 public constant ZAPPER_ROLE = keccak256("ZAPPER_ROLE");

  /*================================================================================
    Storage
    ================================================================================*/

  GoldfinchConfig public config;

  /// @dev DEPRECATED!
  uint256 internal compoundBalance;

  /// @dev DEPRECATED, DO NOT USE.
  mapping(ITranchedPool => uint256) internal writedowns;

  /// @dev Writedowns by PoolToken id. This is used to ensure writedowns are incremental.
  ///   Example: At t1, a pool is late and should be written down by 10%. At t2, the pool
  ///   is even later, and should be written down by 25%. This variable helps ensure that
  ///   if writedowns occur at both t1 and t2, t2's writedown is only by the delta of 15%,
  ///   rather than double-counting the writedown percent from t1.
  mapping(uint256 => uint256) public writedownsByPoolToken;

  uint256 internal _checkpointedEpochId;
  mapping(uint256 => Epoch) internal _epochs;
  mapping(uint256 => WithdrawalRequest) internal _withdrawalRequests;
  /// @dev Tracks usdc available for investments, zaps, withdrawal allocations etc. Due to the time
  /// based nature of epochs, if the last epoch has ended but isn't checkpointed yet then this var
  /// doesn't reflect the true usdc available at the current timestamp. To query for the up to date
  /// usdc available without having to execute a tx, use the usdcAvailable() view fn
  uint256 internal _usdcAvailable;
  uint256 internal _epochDuration;

  /*================================================================================
    Initialization Functions
    ================================================================================*/

  function initialize(address owner, GoldfinchConfig _config) public initializer {
    require(owner != address(0) && address(_config) != address(0), "Owner and config addresses cannot be empty");

    __BaseUpgradeablePausable__init(owner);
    _setRoleAdmin(ZAPPER_ROLE, OWNER_ROLE);

    config = _config;
    sharePrice = FIDU_MANTISSA;
    totalLoansOutstanding = 0;
    totalWritedowns = 0;
  }

  /*================================================================================
  Admin Functions
  ================================================================================*/

  /**
   * @inheritdoc ISeniorPoolEpochWithdrawals
   * @dev Triggers a checkpoint
   */
  function setEpochDuration(uint256 newEpochDuration) external override onlyAdmin {
    require(newEpochDuration > 0, "Zero duration");
    Epoch storage headEpoch = _applyEpochCheckpoints();
    // When we're updating the epoch duration we need to update the head epoch endsAt
    // time to be the new epoch duration
    if (headEpoch.endsAt > block.timestamp) {
      /*
      This codepath happens when we successfully finalize the previous epoch. This results
      in a timestamp in the future. In this case we need to account for no-op epochs that
      would be created by setting the duration to a value less than the previous epoch.
      */

      uint256 previousEpochEndsAt = headEpoch.endsAt.sub(_epochDuration);
      _epochDuration = newEpochDuration;
      headEpoch.endsAt = _mostRecentEndsAtAfter(previousEpochEndsAt).add(newEpochDuration);
      assert(headEpoch.endsAt > block.timestamp);
    } else {
      headEpoch.endsAt = _mostRecentEndsAtAfter(headEpoch.endsAt).add(newEpochDuration);
    }
    _epochDuration = newEpochDuration;
    emit EpochDurationChanged(newEpochDuration);
  }

  /**
   * @notice Initialize the epoch withdrawal system. This includes writing the
   *          initial epoch and snapshotting usdcAvailable at the current usdc balance of
   *          the senior pool.
   */
  function initializeEpochs() external onlyAdmin {
    require(_epochs[0].endsAt == 0);
    _epochDuration = 2 weeks;
    _usdcAvailable = config.getUSDC().balanceOf(address(this));
    _epochs[0].endsAt = block.timestamp;
    _applyInitializeNextEpochFrom(_epochs[0]);
  }

  /*================================================================================
    LP functions
    ================================================================================*/

  // External Functions
  //--------------------------------------------------------------------------------

  /**
   * @notice Deposits `amount` USDC from msg.sender into the SeniorPool, and grants you the
   *  equivalent value of FIDU tokens
   * @param amount The amount of USDC to deposit
   */
  function deposit(uint256 amount) public override whenNotPaused nonReentrant returns (uint256 depositShares) {
    require(config.getGo().goSeniorPool(msg.sender), "NA");
    require(amount > 0, "Must deposit more than zero");
    _applyEpochCheckpoints();
    _usdcAvailable = _usdcAvailable.add(amount);
    // Check if the amount of new shares to be added is within limits
    depositShares = getNumShares(amount);
    emit DepositMade(msg.sender, amount, depositShares);
    require(config.getUSDC().transferFrom(msg.sender, address(this), amount), "Failed to transfer for deposit");

    config.getFidu().mintTo(msg.sender, depositShares);
    return depositShares;
  }

  /**
   * @notice Identical to deposit, except it allows for a passed up signature to permit
   *  the Senior Pool to move funds on behalf of the user, all within one transaction.
   * @param amount The amount of USDC to deposit
   * @param v secp256k1 signature component
   * @param r secp256k1 signature component
   * @param s secp256k1 signature component
   */
  function depositWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override returns (uint256 depositShares) {
    IERC20Permit(config.usdcAddress()).permit(msg.sender, address(this), amount, deadline, v, r, s);
    return deposit(amount);
  }

  /**
   * @inheritdoc ISeniorPoolEpochWithdrawals
   * @dev Reverts if a withdrawal with the given tokenId does not exist
   * @dev Reverts if the caller is not the owner of the given token
   * @dev Triggers a checkpoint
   */
  function addToWithdrawalRequest(uint256 fiduAmount, uint256 tokenId) external override whenNotPaused nonReentrant {
    require(config.getGo().goSeniorPool(msg.sender), "NA");
    IWithdrawalRequestToken requestTokens = config.getWithdrawalRequestToken();
    require(msg.sender == requestTokens.ownerOf(tokenId), "NA");

    (Epoch storage thisEpoch, WithdrawalRequest storage request) = _applyEpochAndRequestCheckpoints(tokenId);

    request.fiduRequested = request.fiduRequested.add(fiduAmount);
    thisEpoch.fiduRequested = thisEpoch.fiduRequested.add(fiduAmount);

    emit WithdrawalAddedTo({
      epochId: _checkpointedEpochId,
      tokenId: tokenId,
      operator: msg.sender,
      fiduRequested: fiduAmount
    });

    config.getFidu().safeTransferFrom(msg.sender, address(this), fiduAmount);
  }

  /**
   * @inheritdoc ISeniorPoolEpochWithdrawals
   * @dev triggers a checkpoint
   */
  function requestWithdrawal(uint256 fiduAmount) external override whenNotPaused nonReentrant returns (uint256) {
    IWithdrawalRequestToken requestTokens = config.getWithdrawalRequestToken();
    require(config.getGo().goSeniorPool(msg.sender), "NA");
    require(requestTokens.balanceOf(msg.sender) == 0, "Existing request");
    Epoch storage thisEpoch = _applyEpochCheckpoints();

    uint256 tokenId = requestTokens.mint(msg.sender);

    WithdrawalRequest storage request = _withdrawalRequests[tokenId];

    request.epochCursor = _checkpointedEpochId;
    request.fiduRequested = fiduAmount;

    thisEpoch.fiduRequested = thisEpoch.fiduRequested.add(fiduAmount);
    config.getFidu().safeTransferFrom(msg.sender, address(this), fiduAmount);

    emit WithdrawalRequested(_checkpointedEpochId, tokenId, msg.sender, fiduAmount);
    return tokenId;
  }

  /**
   * @inheritdoc ISeniorPoolEpochWithdrawals
   * @dev triggers a checkpoint
   */
  function cancelWithdrawalRequest(uint256 tokenId) external override whenNotPaused nonReentrant returns (uint256) {
    require(config.getGo().goSeniorPool(msg.sender), "NA");
    require(msg.sender == config.getWithdrawalRequestToken().ownerOf(tokenId), "NA");

    (Epoch storage thisEpoch, WithdrawalRequest storage request) = _applyEpochAndRequestCheckpoints(tokenId);
    require(request.fiduRequested != 0, "Cant cancel");

    uint256 reserveBps = config.getSeniorPoolWithdrawalCancelationFeeInBps();
    require(reserveBps <= 10_000, "Invalid Bps");
    uint256 reserveFidu = request.fiduRequested.mul(reserveBps).div(10_000);
    uint256 userFidu = request.fiduRequested.sub(reserveFidu);

    thisEpoch.fiduRequested = thisEpoch.fiduRequested.sub(request.fiduRequested);
    request.fiduRequested = 0;

    // only delete the withdraw request if there is no more possible value to be added
    if (request.usdcWithdrawable == 0) {
      _burnWithdrawRequest(tokenId);
    }
    config.getFidu().safeTransfer(msg.sender, userFidu);

    address reserve = config.protocolAdminAddress();
    config.getFidu().safeTransfer(reserve, reserveFidu);

    emit ReserveSharesCollected(msg.sender, reserve, reserveFidu);
    emit WithdrawalCanceled(_checkpointedEpochId, tokenId, msg.sender, userFidu, reserveFidu);
    return userFidu;
  }

  /**
   * @inheritdoc ISeniorPoolEpochWithdrawals
   * @dev triggers a checkpoint
   */
  function claimWithdrawalRequest(uint256 tokenId) external override whenNotPaused nonReentrant returns (uint256) {
    require(config.getGo().goSeniorPool(msg.sender), "NA");
    require(msg.sender == config.getWithdrawalRequestToken().ownerOf(tokenId), "NA");
    (, WithdrawalRequest storage request) = _applyEpochAndRequestCheckpoints(tokenId);

    uint256 totalUsdcAmount = request.usdcWithdrawable;
    request.usdcWithdrawable = 0;
    uint256 reserveAmount = totalUsdcAmount.div(config.getWithdrawFeeDenominator());
    uint256 userAmount = totalUsdcAmount.sub(reserveAmount);

    // if there is no outstanding FIDU, burn the token
    if (request.fiduRequested == 0) {
      _burnWithdrawRequest(tokenId);
    }

    _sendToReserve(reserveAmount, msg.sender);
    config.getUSDC().safeTransfer(msg.sender, userAmount);

    emit WithdrawalMade(msg.sender, userAmount, reserveAmount);

    return userAmount;
  }

  // view functions
  //--------------------------------------------------------------------------------

  /// @inheritdoc ISeniorPoolEpochWithdrawals
  function epochDuration() external view override returns (uint256) {
    return _epochDuration;
  }

  /// @inheritdoc ISeniorPoolEpochWithdrawals
  function withdrawalRequest(uint256 tokenId) external view override returns (WithdrawalRequest memory) {
    // This call will revert if the tokenId does not exist
    config.getWithdrawalRequestToken().ownerOf(tokenId);
    WithdrawalRequest storage wr = _withdrawalRequests[tokenId];
    return _previewWithdrawRequestCheckpoint(wr);
  }

  // internal view functions
  //--------------------------------------------------------------------------------

  /**
   * @notice Preview the effects of attempting to checkpoint a given epoch. If
   *         the epoch doesn't need to be checkpointed then the same epoch will be return
   *          along with a bool indicated it didn't need to be checkpointed.
   * @param epoch epoch to checkpoint
   * @return maybeCheckpointedEpoch the checkpointed epoch if the epoch was
   *                                  able to be checkpointed, otherwise the same epoch
   * @return epochStatus If the epoch can't be finalized, returns `Unapplied`.
   *                      If the Epoch is after the end time of the epoch the epoch will be extended.
   *                      An extended epoch will have its endTime set to the next endtime but won't
   *                      have any usdc allocated to it. If the epoch can be finalized and its after
   *                      the end time, it will have usdc allocated to it.
   */
  function _previewEpochCheckpoint(Epoch memory epoch) internal view returns (Epoch memory, EpochCheckpointStatus) {
    if (block.timestamp < epoch.endsAt) {
      return (epoch, EpochCheckpointStatus.Unapplied);
    }

    // After this point block.timestamp >= epoch.endsAt

    uint256 usdcNeededToFullyLiquidate = _getUSDCAmountFromShares(epoch.fiduRequested);
    epoch.endsAt = _mostRecentEndsAtAfter(epoch.endsAt);
    /*
    If usdc available is zero for an epoch, or the epoch's usdc equivalent
    of its fidu requested is zero, then the epoch is extended instead of finalized.
    Why? Because if usdc available is zero then we can't liquidate any fidu,
    and if the fidu requested is zero (in usdc terms) then there's no need to
    allocate usdc. 
    */
    if (_usdcAvailable == 0 || usdcNeededToFullyLiquidate == 0) {
      // When we extend the epoch, we need to add an additional epoch to the end so that
      // the next time a checkpoint happens it won't immediately finalize the epoch
      epoch.endsAt = epoch.endsAt.add(_epochDuration);
      return (epoch, EpochCheckpointStatus.Extended);
    }

    // finalize epoch
    uint256 usdcAllocated = _usdcAvailable.min(usdcNeededToFullyLiquidate);
    uint256 fiduLiquidated = getNumShares(usdcAllocated);
    epoch.fiduLiquidated = fiduLiquidated;
    epoch.usdcAllocated = usdcAllocated;
    return (epoch, EpochCheckpointStatus.Finalized);
  }

  /// @notice Returns the most recent, uncheckpointed epoch
  function _headEpoch() internal view returns (Epoch storage) {
    return _epochs[_checkpointedEpochId];
  }

  /// @notice Returns the state of a withdraw request after checkpointing
  function _previewWithdrawRequestCheckpoint(WithdrawalRequest memory wr)
    internal
    view
    returns (WithdrawalRequest memory)
  {
    Epoch memory epoch;
    // Iterate through each epoch, calculating the amount of USDC that would be
    // allocated to the withdraw request by using the proportion of FIDU the
    // withdraw request had in that epoch and subtracting the allocation from
    // the withdraw request.
    for (uint256 i = wr.epochCursor; i <= _checkpointedEpochId && wr.fiduRequested > 0; ++i) {
      epoch = _epochs[i];

      // The withdraw request could have FIDU in the most recent, non-finalized-
      // epoch, and so we need to apply the checkpoint to get an accurate count
      if (i == _checkpointedEpochId) {
        (epoch, ) = _previewEpochCheckpoint(epoch);
      }
      uint256 proRataUsdc = epoch.usdcAllocated.mul(wr.fiduRequested).div(epoch.fiduRequested);
      uint256 fiduLiquidated = epoch.fiduLiquidated.mul(wr.fiduRequested).div(epoch.fiduRequested);
      wr.fiduRequested = wr.fiduRequested.sub(fiduLiquidated);
      wr.usdcWithdrawable = wr.usdcWithdrawable.add(proRataUsdc);

      if (epoch.fiduLiquidated != 0) {
        /*
        If the user's outstanding fiduAmount, when claimed, would result in them
        receiving no usdc amount because of loss of precision in conversion we
        just zero out the request so when they claim they don't need to
        unnecessarily iterate through many epochs where they receive nothing.

        The sum of the withdraw request that are "dust" (would result in 0 usdc)
        may result in a non zero usdc allocation at the epoch level. USDC will
        be allocated to these "dusty" requests, but the very small amount of
        usdc will not be claimable by anyone.
        */
        uint256 epochSharePrice = epoch.usdcAllocated.mul(FIDU_MANTISSA).mul(1e12).div(epoch.fiduLiquidated);
        bool noUsdcValueRemainingInRequest = _getUSDCAmountFromShares(wr.fiduRequested, epochSharePrice) == 0;
        if (noUsdcValueRemainingInRequest) {
          wr.fiduRequested = 0;
        }
      }
    }
    wr.epochCursor = _checkpointedEpochId;

    return wr;
  }

  /**
   * @notice Returns the most recent time an epoch would end assuming the current epoch duration
   *          and the starting point of `endsAt`.
   * @param endsAt basis for calculating the most recent endsAt time
   * @return mostRecentEndsAt The most recent endsAt
   */
  function _mostRecentEndsAtAfter(uint256 endsAt) internal view returns (uint256) {
    // if multiple epochs have passed since checkpointing, update the endtime
    // and emit many events so that we don't need to write a bunch of useless epochs
    uint256 nopEpochsElapsed = block.timestamp.sub(endsAt).div(_epochDuration);
    // update the last epoch timestamp to the timestamp of the most recently ended epoch
    return endsAt.add(nopEpochsElapsed.mul(_epochDuration));
  }

  // internal functions
  //--------------------------------------------------------------------------------

  function _sendToReserve(uint256 amount, address userForEvent) internal {
    emit ReserveFundsCollected(userForEvent, amount);
    config.getUSDC().safeTransfer(config.reserveAddress(), amount);
  }

  /**
   * @notice Initialize the next epoch using a given epoch by carrying forward its oustanding fidu
   */
  function _applyInitializeNextEpochFrom(Epoch storage previousEpoch) internal returns (Epoch storage) {
    _epochs[++_checkpointedEpochId] = _initializeNextEpochFrom(previousEpoch);
    return _epochs[_checkpointedEpochId];
  }

  function _initializeNextEpochFrom(Epoch memory previousEpoch) internal view returns (Epoch memory) {
    Epoch memory nextEpoch;
    nextEpoch.endsAt = previousEpoch.endsAt.add(_epochDuration);
    uint256 fiduToCarryOverFromLastEpoch = previousEpoch.fiduRequested.sub(previousEpoch.fiduLiquidated);
    nextEpoch.fiduRequested = fiduToCarryOverFromLastEpoch;
    return nextEpoch;
  }

  /// @notice Increment _checkpointedEpochId cursor up to the current epoch
  function _applyEpochCheckpoints() private returns (Epoch storage) {
    return _applyEpochCheckpoint(_headEpoch());
  }

  function _applyWithdrawalRequestCheckpoint(uint256 tokenId) internal returns (WithdrawalRequest storage) {
    WithdrawalRequest storage wr = _withdrawalRequests[tokenId];
    Epoch storage epoch;

    for (uint256 i = wr.epochCursor; i < _checkpointedEpochId && wr.fiduRequested > 0; i++) {
      epoch = _epochs[i];
      uint256 proRataUsdc = epoch.usdcAllocated.mul(wr.fiduRequested).div(epoch.fiduRequested);
      uint256 fiduLiquidated = epoch.fiduLiquidated.mul(wr.fiduRequested).div(epoch.fiduRequested);
      wr.fiduRequested = wr.fiduRequested.sub(fiduLiquidated);
      wr.usdcWithdrawable = wr.usdcWithdrawable.add(proRataUsdc);

      /*
      If the user's outstanding fiduAmount, when claimed, would result in them
      receiving no usdc amount because of loss of precision in conversion we
      just zero out the request so when they claim they don't need to
      unnecessarily iterate through many epochs where they receive nothing.

      At the epoch level, the sum of the withdraw request that are "dust" (would
      result in 0 usdc) may result in a non zero usdc allocation at the epoch
      level. USDC will be allocated to these "dusty" requests, but the very
      small amount of usdc will not be claimable by anyone.
      */
      uint256 epochSharePrice = epoch.usdcAllocated.mul(FIDU_MANTISSA).mul(1e12).div(epoch.fiduLiquidated);
      bool noUsdcValueRemainingInRequest = _getUSDCAmountFromShares(wr.fiduRequested, epochSharePrice) == 0;
      if (noUsdcValueRemainingInRequest) {
        wr.fiduRequested = 0;
      }
    }

    // Update a fully liquidated request's cursor. Otherwise new fiduRequested would be applied to liquidated
    // epochs that the request was not part of.
    wr.epochCursor = _checkpointedEpochId;
    return wr;
  }

  function _applyEpochAndRequestCheckpoints(uint256 tokenId)
    internal
    returns (Epoch storage, WithdrawalRequest storage)
  {
    Epoch storage headEpoch = _applyEpochCheckpoints();
    WithdrawalRequest storage wr = _applyWithdrawalRequestCheckpoint(tokenId);
    return (headEpoch, wr);
  }

  /**
   * @notice Checkpoint an epoch, returning the same epoch if it doesn't need
   * to be checkpointed or a newly initialized epoch if the given epoch was
   * successfully checkpointed. In other words, return the most current epoch
   * @dev To decrease storage writes we have introduced optimizations based on two observations
   *      1. If block.timestamp < endsAt, then the epoch is unchanged and we can return
   *       the unmodified epoch (checkpointStatus == Unappled).
   *      2. If the epoch has ended but its fiduRequested is 0 OR the senior pool's usdcAvailable
   *       is 0, then the next epoch will have the SAME fiduRequested, and the only variable we have to update
   *       is endsAt (chekpointStatus == Extended).
   * @param epoch epoch to checkpoint
   * @return currentEpoch current epoch
   */
  function _applyEpochCheckpoint(Epoch storage epoch) internal returns (Epoch storage) {
    (Epoch memory checkpointedEpoch, EpochCheckpointStatus checkpointStatus) = _previewEpochCheckpoint(epoch);
    if (checkpointStatus == EpochCheckpointStatus.Unapplied) {
      return epoch;
    } else if (checkpointStatus == EpochCheckpointStatus.Extended) {
      uint256 oldEndsAt = epoch.endsAt;
      epoch.endsAt = checkpointedEpoch.endsAt;
      emit EpochExtended(_checkpointedEpochId, epoch.endsAt, oldEndsAt);
      return epoch;
    } else {
      // copy checkpointed data
      epoch.fiduLiquidated = checkpointedEpoch.fiduLiquidated;
      epoch.usdcAllocated = checkpointedEpoch.usdcAllocated;
      epoch.endsAt = checkpointedEpoch.endsAt;

      _usdcAvailable = _usdcAvailable.sub(epoch.usdcAllocated);
      uint256 endingEpochId = _checkpointedEpochId;
      Epoch storage newEpoch = _applyInitializeNextEpochFrom(epoch);
      config.getFidu().burnFrom(address(this), epoch.fiduLiquidated);

      emit EpochEnded(endingEpochId, epoch.endsAt, epoch.fiduRequested, epoch.usdcAllocated, epoch.fiduLiquidated);
      return newEpoch;
    }
  }

  function _burnWithdrawRequest(uint256 tokenId) internal {
    delete _withdrawalRequests[tokenId];
    config.getWithdrawalRequestToken().burn(tokenId);
  }

  /*================================================================================
    Zapper Withdraw
    ================================================================================*/
  /**
   * @notice Withdraws USDC from the SeniorPool to msg.sender, and burns the equivalent value of FIDU tokens
   * @param usdcAmount The amount of USDC to withdraw
   */
  function withdraw(uint256 usdcAmount)
    external
    override
    whenNotPaused
    nonReentrant
    onlyZapper
    returns (uint256 amount)
  {
    require(usdcAmount > 0, "Must withdraw more than zero");
    uint256 withdrawShares = getNumShares(usdcAmount);
    return _withdraw(usdcAmount, withdrawShares);
  }

  /**
   * @notice Withdraws USDC (denominated in FIDU terms) from the SeniorPool to msg.sender
   * @param fiduAmount The amount of USDC to withdraw in terms of FIDU shares
   */
  function withdrawInFidu(uint256 fiduAmount)
    external
    override
    whenNotPaused
    nonReentrant
    onlyZapper
    returns (uint256 amount)
  {
    require(fiduAmount > 0, "Must withdraw more than zero");
    uint256 usdcAmount = _getUSDCAmountFromShares(fiduAmount);
    uint256 withdrawShares = fiduAmount;
    return _withdraw(usdcAmount, withdrawShares);
  }

  // Zapper Withdraw: Internal functions
  //--------------------------------------------------------------------------------
  function _withdraw(uint256 usdcAmount, uint256 withdrawShares) internal returns (uint256 userAmount) {
    _applyEpochCheckpoints();
    IFidu fidu = config.getFidu();
    // Determine current shares the address has and the shares requested to withdraw
    uint256 currentShares = fidu.balanceOf(msg.sender);
    // Ensure the address has enough value in the pool
    require(withdrawShares <= currentShares, "Amount requested is greater than what this address owns");

    _usdcAvailable = _usdcAvailable.sub(usdcAmount, "IB");
    // Send to reserves
    userAmount = usdcAmount;

    // Send to user
    config.getUSDC().safeTransfer(msg.sender, usdcAmount);

    // Burn the shares
    fidu.burnFrom(msg.sender, withdrawShares);

    emit WithdrawalMade(msg.sender, userAmount, 0);

    return userAmount;
  }

  /*================================================================================
    Asset Management
    ----------------
    functions related to investing, writing off, and redeeming assets
    ================================================================================*/

  // External functions
  //--------------------------------------------------------------------------------

  /**
   * @notice Invest in an ITranchedPool's senior tranche using the senior pool's strategy
   * @param pool An ITranchedPool whose senior tranche should be considered for investment
   */
  function invest(ITranchedPool pool) external override whenNotPaused nonReentrant returns (uint256) {
    require(_isValidPool(pool), "Pool must be valid");
    _applyEpochCheckpoints();

    ISeniorPoolStrategy strategy = config.getSeniorPoolStrategy();
    uint256 amount = strategy.invest(this, pool);

    require(amount > 0, "Investment amount must be positive");
    require(amount <= _usdcAvailable, "not enough usdc");

    _usdcAvailable = _usdcAvailable.sub(amount);

    _approvePool(pool, amount);
    uint256 nSlices = pool.numSlices();
    require(nSlices >= 1, "Pool has no slices");
    uint256 sliceIndex = nSlices.sub(1);
    uint256 seniorTrancheId = _sliceIndexToSeniorTrancheId(sliceIndex);
    totalLoansOutstanding = totalLoansOutstanding.add(amount);
    uint256 poolToken = pool.deposit(seniorTrancheId, amount);

    emit InvestmentMadeInSenior(address(pool), amount);

    return poolToken;
  }

  /**
   * @notice Redeem interest and/or principal from an ITranchedPool investment
   * @param tokenId the ID of an IPoolTokens token to be redeemed
   * @dev triggers a checkpoint
   */
  function redeem(uint256 tokenId) external override whenNotPaused nonReentrant {
    _applyEpochCheckpoints();
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);

    ITranchedPool pool = ITranchedPool(tokenInfo.pool);
    (uint256 interestRedeemed, uint256 principalRedeemed) = pool.withdrawMax(tokenId);

    _collectInterestAndPrincipal(address(pool), interestRedeemed, principalRedeemed);
  }

  /**
   * @notice Write down an ITranchedPool investment. This will adjust the senior pool's share price
   *  down if we're considering the investment a loss, or up if the borrower has subsequently
   *  made repayments that restore confidence that the full loan will be repaid.
   * @param tokenId the ID of an IPoolTokens token to be considered for writedown
   * @dev triggers a checkpoint
   */
  function writedown(uint256 tokenId) external override whenNotPaused nonReentrant {
    IPoolTokens poolTokens = config.getPoolTokens();
    require(address(this) == poolTokens.ownerOf(tokenId), "Only tokens owned by the senior pool can be written down");

    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(tokenId);
    ITranchedPool pool = ITranchedPool(tokenInfo.pool);
    require(_isValidPool(pool), "Pool must be valid");
    _applyEpochCheckpoints();

    // Assess the pool first in case it has unapplied USDC in its credit line
    pool.assess();

    uint256 principalRemaining = tokenInfo.principalAmount.sub(tokenInfo.principalRedeemed);

    (uint256 writedownPercent, uint256 writedownAmount) = _calculateWritedown(pool, principalRemaining);

    uint256 prevWritedownAmount = writedownsByPoolToken[tokenId];

    if (writedownPercent == 0 && prevWritedownAmount == 0) {
      return;
    }

    int256 writedownDelta = prevWritedownAmount.toInt256().sub(writedownAmount.toInt256());
    writedownsByPoolToken[tokenId] = writedownAmount;
    _distributeLosses(writedownDelta);
    if (writedownDelta > 0) {
      // If writedownDelta is positive, that means we got money back. So subtract from totalWritedowns.
      totalWritedowns = totalWritedowns.sub(writedownDelta.toUint256());
    } else {
      totalWritedowns = totalWritedowns.add((writedownDelta * -1).toUint256());
    }
    emit PrincipalWrittenDown(address(pool), writedownDelta);
  }

  // View Functions
  //--------------------------------------------------------------------------------

  /// @inheritdoc ISeniorPoolEpochWithdrawals
  function usdcAvailable() public view override returns (uint256) {
    (Epoch memory e, ) = _previewEpochCheckpoint(_headEpoch());
    uint256 usdcThatWillBeAllocatedToLatestEpoch = e.usdcAllocated;
    return _usdcAvailable.sub(usdcThatWillBeAllocatedToLatestEpoch);
  }

  /// @inheritdoc ISeniorPoolEpochWithdrawals
  function currentEpoch() external view override returns (Epoch memory) {
    (Epoch memory e, EpochCheckpointStatus checkpointStatus) = _previewEpochCheckpoint(_headEpoch());
    if (checkpointStatus == EpochCheckpointStatus.Finalized) e = _initializeNextEpochFrom(e);
    return e;
  }

  /**
   * @notice Returns the net assests controlled by and owed to the pool
   */
  function assets() external view override returns (uint256) {
    return usdcAvailable().add(totalLoansOutstanding).sub(totalWritedowns);
  }

  /**
   * @notice Returns the number of shares outstanding, accounting for shares that will be burned
   *          when an epoch checkpoint happens
   */
  function sharesOutstanding() external view override returns (uint256) {
    (Epoch memory e, ) = _previewEpochCheckpoint(_headEpoch());
    uint256 fiduThatWillBeBurnedOnCheckpoint = e.fiduLiquidated;
    return config.getFidu().totalSupply().sub(fiduThatWillBeBurnedOnCheckpoint);
  }

  function getNumShares(uint256 usdcAmount) public view override returns (uint256) {
    return _getNumShares(usdcAmount, sharePrice);
  }

  function estimateInvestment(ITranchedPool pool) external view override returns (uint256) {
    require(_isValidPool(pool), "Pool must be valid");
    ISeniorPoolStrategy strategy = config.getSeniorPoolStrategy();
    return strategy.estimateInvestment(this, pool);
  }

  /**
   * @notice Calculates the writedown amount for a particular pool position
   * @param tokenId The token reprsenting the position
   * @return The amount in dollars the principal should be written down by
   */
  function calculateWritedown(uint256 tokenId) external view override returns (uint256) {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    ITranchedPool pool = ITranchedPool(tokenInfo.pool);

    uint256 principalRemaining = tokenInfo.principalAmount.sub(tokenInfo.principalRedeemed);

    (, uint256 writedownAmount) = _calculateWritedown(pool, principalRemaining);
    return writedownAmount;
  }

  // Internal functions
  //--------------------------------------------------------------------------------

  function _getNumShares(uint256 _usdcAmount, uint256 _sharePrice) internal pure returns (uint256) {
    return _usdcToFidu(_usdcAmount).mul(FIDU_MANTISSA).div(_sharePrice);
  }

  function _calculateWritedown(ITranchedPool pool, uint256 principal)
    internal
    view
    returns (uint256 writedownPercent, uint256 writedownAmount)
  {
    return
      Accountant.calculateWritedownForPrincipal(
        pool.creditLine(),
        principal,
        block.timestamp,
        config.getLatenessGracePeriodInDays(),
        config.getLatenessMaxDays()
      );
  }

  function _distributeLosses(int256 writedownDelta) internal {
    _applyEpochCheckpoints();
    if (writedownDelta > 0) {
      uint256 delta = _usdcToSharePrice(writedownDelta.toUint256());
      sharePrice = sharePrice.add(delta);
    } else {
      // If delta is negative, convert to positive uint, and sub from sharePrice
      uint256 delta = _usdcToSharePrice((writedownDelta * -1).toUint256());
      sharePrice = sharePrice.sub(delta);
    }
  }

  function _collectInterestAndPrincipal(
    address from,
    uint256 interest,
    uint256 principal
  ) internal {
    uint256 increment = _usdcToSharePrice(interest);
    sharePrice = sharePrice.add(increment);

    if (interest > 0) {
      emit InterestCollected(from, interest);
    }
    if (principal > 0) {
      emit PrincipalCollected(from, principal);
      totalLoansOutstanding = totalLoansOutstanding.sub(principal);
    }
    _usdcAvailable = _usdcAvailable.add(interest).add(principal);
  }

  function _isValidPool(ITranchedPool pool) internal view returns (bool) {
    return config.getPoolTokens().validPool(address(pool));
  }

  function _approvePool(ITranchedPool pool, uint256 allowance) internal {
    IERC20withDec usdc = config.getUSDC();
    require(usdc.approve(address(pool), allowance));
  }

  /*================================================================================
    General Internal Functions
    ================================================================================*/

  function _usdcToFidu(uint256 amount) internal pure returns (uint256) {
    return amount.mul(FIDU_MANTISSA).div(USDC_MANTISSA);
  }

  function _fiduToUsdc(uint256 amount) internal pure returns (uint256) {
    return amount.div(FIDU_MANTISSA.div(USDC_MANTISSA));
  }

  function _getUSDCAmountFromShares(uint256 fiduAmount) internal view returns (uint256) {
    return _getUSDCAmountFromShares(fiduAmount, sharePrice);
  }

  function _getUSDCAmountFromShares(uint256 _fiduAmount, uint256 _sharePrice) internal pure returns (uint256) {
    return _fiduToUsdc(_fiduAmount.mul(_sharePrice)).div(FIDU_MANTISSA);
  }

  function _usdcToSharePrice(uint256 usdcAmount) internal view returns (uint256) {
    return _usdcToFidu(usdcAmount).mul(FIDU_MANTISSA).div(_totalShares());
  }

  function _totalShares() internal view returns (uint256) {
    return config.getFidu().totalSupply();
  }

  /// @notice Returns the senion tranche id for the given slice index
  /// @param index slice index
  /// @return senior tranche id of given slice index
  function _sliceIndexToSeniorTrancheId(uint256 index) internal pure returns (uint256) {
    return index.mul(2).add(1);
  }

  modifier onlyZapper() {
    require(hasRole(ZAPPER_ROLE, msg.sender), "Not Zapper");
    _;
  }

  enum EpochCheckpointStatus {
    Unapplied,
    Extended,
    Finalized
  }
}