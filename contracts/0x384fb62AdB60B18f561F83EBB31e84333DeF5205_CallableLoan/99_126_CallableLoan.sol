// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

// solhint-disable-next-line max-line-length
import {IERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
// solhint-disable-next-line max-line-length
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {ICallableLoan, LoanPhase} from "../../../interfaces/ICallableLoan.sol";
import {ICallableLoanErrors} from "../../../interfaces/ICallableLoanErrors.sol";
import {ILoan, LoanType} from "../../../interfaces/ILoan.sol";
import {IRequiresUID} from "../../../interfaces/IRequiresUID.sol";
import {IERC20UpgradeableWithDec} from "../../../interfaces/IERC20UpgradeableWithDec.sol";
import {ICreditLine} from "../../../interfaces/ICreditLine.sol";
import {IPoolTokens} from "../../../interfaces/IPoolTokens.sol";
import {IVersioned} from "../../../interfaces/IVersioned.sol";
import {ISchedule} from "../../../interfaces/ISchedule.sol";
import {IGoldfinchConfig} from "../../../interfaces/IGoldfinchConfig.sol";

import {BaseUpgradeablePausable} from "../BaseUpgradeablePausable08x.sol";

import {CallableLoanConfigHelper} from "./CallableLoanConfigHelper.sol";
import {Waterfall} from "./structs/Waterfall.sol";
// solhint-disable-next-line max-line-length
import {CallableCreditLine, CallableCreditLineLogic, CheckpointedCallableCreditLineLogic, SettledTrancheInfo} from "./structs/CallableCreditLine.sol";
import {StaleCallableCreditLine, StaleCallableCreditLineLogic} from "./structs/StaleCallableCreditLine.sol";
import {SaturatingSub} from "../../../library/SaturatingSub.sol";
import {PaymentSchedule, PaymentScheduleLogic} from "../schedule/PaymentSchedule.sol";
import {CallableLoanAccountant} from "./CallableLoanAccountant.sol";

// import {console2 as console} from "forge-std/console2.sol";

/// @title CallableLoan
/// @notice A loan that allows the lenders to call back capital from the borrower.
/// @author Warbler Labs
contract CallableLoan is
  BaseUpgradeablePausable,
  ICallableLoan,
  ICallableLoanErrors,
  ICreditLine,
  IRequiresUID,
  IVersioned
{
  using CheckpointedCallableCreditLineLogic for CallableCreditLine;
  using CallableLoanConfigHelper for IGoldfinchConfig;
  using SafeERC20 for IERC20UpgradeableWithDec;
  using SaturatingSub for uint256;

  /*================================================================================
  Constants
  ================================================================================*/
  bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");
  // When splitting a pool token as part of submitting a call, the remainder on a
  // pool token should be voided if it does not meet this threshold.
  // Why 5e3 (half a cent)? Large enough to rule out rounding errors, but small
  // enough to not materially effect USD accounting.
  uint256 public constant SPLIT_TOKEN_DUST_THRESHOLD = 5e3;

  uint8 internal constant MAJOR_VERSION = 1;
  uint8 internal constant MINOR_VERSION = 1;
  uint8 internal constant PATCH_VERSION = 0;

  /*================================================================================
  Storage State
  ================================================================================*/
  StaleCallableCreditLine private _staleCreditLine;
  bool public drawdownsPaused;
  uint256[] public allowedUIDTypes;

  /*================================================================================
  Storage Static Configuration
  ================================================================================*/
  IGoldfinchConfig public config;
  uint256 public override createdAt;
  address public override borrower;

  /*================================================================================
  Initialization
  ================================================================================*/

  function initialize(
    IGoldfinchConfig _config,
    address _borrower,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _numLockupPeriods,
    ISchedule _schedule,
    uint256 _lateFeeApr,
    uint256 _fundableAt,
    uint256[] calldata _allowedUIDTypes
  ) external override initializer {
    // NOTE: This check can be replaced with an after deploy verification rather than
    //       a require statement which increases bytecode size.
    // require(address(_config) != address(0) && address(_borrower) != address(0), "00");
    if (_numLockupPeriods >= _schedule.periodsPerPrincipalPeriod()) {
      revert InvalidNumLockupPeriods(_numLockupPeriods, _schedule.periodsPerPrincipalPeriod());
    }

    config = _config;
    borrower = _borrower;
    createdAt = block.timestamp;
    allowedUIDTypes = _allowedUIDTypes;

    {
      address owner = config.protocolAdminAddress();
      __BaseUpgradeablePausable__init(owner);

      _setupRole(LOCKER_ROLE, _borrower);
      _setupRole(LOCKER_ROLE, owner);
      _setRoleAdmin(LOCKER_ROLE, OWNER_ROLE);
    }

    _staleCreditLine.initialize({
      _config: _config,
      _fundableAt: _fundableAt,
      _numLockupPeriods: _numLockupPeriods,
      _schedule: _schedule,
      _interestApr: _interestApr,
      _lateAdditionalApr: _lateFeeApr,
      _limit: _limit
    });
    emit DrawdownsPaused(address(this));
  }

  /*================================================================================
  Main Public/External Write functions
  ================================================================================*/
  /// @inheritdoc ICallableLoan
  /// @notice Submit a call request for the given amount of capital.
  ///         The borrower is obligated to pay the call request back at the end of the
  ///         corresponding call request period.
  /// @param callAmount Amount of capital to call back
  /// @param poolTokenId Pool token id to be called back.
  function submitCall(
    uint256 callAmount,
    uint256 poolTokenId
  )
    external
    override
    nonReentrant
    whenNotPaused
    returns (uint256 callRequestedTokenId, uint256 remainingTokenId)
  {
    // 1. Checkpoint the credit line and perform basic validation on the call request.
    CallableCreditLine storage cl = _staleCreditLine.checkpoint();
    IPoolTokens poolTokens = config.getPoolTokens();
    IPoolTokens.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(poolTokenId);
    if (!poolTokens.isApprovedOrOwner(msg.sender, poolTokenId) || !hasAllowedUID(msg.sender)) {
      revert NotAuthorizedToSubmitCall(msg.sender, poolTokenId);
    }
    if (tokenInfo.tranche != cl.uncalledCapitalTrancheIndex()) {
      revert InvalidCallSubmissionPoolToken(poolTokenId);
    }

    if (callAmount == 0) {
      revert ZeroCallSubmissionAmount();
    }

    if (
      callAmount >
      cl.proportionalCallablePrincipal({
        trancheId: tokenInfo.tranche,
        principalDeposited: tokenInfo.principalAmount
      })
    ) {
      revert ExcessiveCallSubmissionAmount(
        poolTokenId,
        callAmount,
        cl.proportionalCallablePrincipal({
          trancheId: tokenInfo.tranche,
          principalDeposited: tokenInfo.principalAmount
        })
      );
    }

    // 2. Determine the total amount of principal and interest that can be withdrawn
    //    on the given pool token. Withdraw all of this amount.
    (uint256 totalInterestWithdrawable, uint256 totalPrincipalWithdrawable) = cl
      .proportionalInterestAndPrincipalAvailable({
        trancheId: tokenInfo.tranche,
        principal: tokenInfo.principalAmount,
        feePercent: _reserveFundsFeePercent()
      });

    {
      uint256 netWithdrawableAmount = totalPrincipalWithdrawable -
        tokenInfo.principalRedeemed +
        totalInterestWithdrawable -
        tokenInfo.interestRedeemed;
      if (netWithdrawableAmount > 0) {
        _withdraw(tokenInfo, poolTokenId, netWithdrawableAmount, cl);
      }
    }

    // 3. Account for the call request in the credit line - this will return the corresponding
    //    amounts of principal deposited, principal paid, and interest redeemable which have
    //    been moved from the pool token to the call request token.
    (
      uint256 principalDepositedMoved,
      uint256 principalPaidRedeemable,
      ,
      uint256 interestRedeemable
    ) = cl.submitCall(callAmount);
    interestRedeemable = (interestRedeemable * (100 - _reserveFundsFeePercent())) / 100;

    {
      // 4. Mint a new token representing the call requested pool token.
      //    Redeem the principal paid and interest redeemed to make sure a user cannot
      //    double withdraw their redeemable balances on the call requested token.
      address owner = poolTokens.ownerOf(poolTokenId);
      callRequestedTokenId = poolTokens.mint(
        IPoolTokens.MintParams({
          principalAmount: principalDepositedMoved,
          tranche: cl.activeCallSubmissionTrancheIndex()
        }),
        owner
      );

      poolTokens.redeem(callRequestedTokenId, principalPaidRedeemable, interestRedeemable);

      // 5. If an above SPLIT_TOKEN_DUST_THRESHOLD amount of principal remains on the pool token,
      //    mint a new token representing the remainder.
      //    Redeem the principal paid and interest redeemed to make sure a user cannot
      //    double withdraw their redeemable balances on the call requested token.
      if (tokenInfo.principalAmount - principalDepositedMoved > SPLIT_TOKEN_DUST_THRESHOLD) {
        remainingTokenId = poolTokens.mint(
          IPoolTokens.MintParams({
            principalAmount: tokenInfo.principalAmount - principalDepositedMoved,
            tranche: cl.uncalledCapitalTrancheIndex()
          }),
          owner
        );

        assert(principalPaidRedeemable <= totalPrincipalWithdrawable);
        assert(interestRedeemable <= totalInterestWithdrawable);

        poolTokens.redeem(
          remainingTokenId,
          totalPrincipalWithdrawable - principalPaidRedeemable,
          totalInterestWithdrawable - interestRedeemable
        );
      }
    }

    // 6. Redeem the original pool token's balance so we can burn it. Then burn it.
    poolTokens.redeem(poolTokenId, tokenInfo.principalAmount - totalPrincipalWithdrawable, 0);
    poolTokens.burn(poolTokenId);

    emit CallRequestSubmitted(poolTokenId, callRequestedTokenId, remainingTokenId, callAmount);
  }

  /// @inheritdoc ILoan
  /// @notice Supply capital to the loan.
  /// @param tranche Should always be uncalled capital tranche index.
  /// @param amount amount of capital to supply
  /// @return tokenId NFT representing your position in this pool
  function deposit(
    uint256 tranche,
    uint256 amount
  ) external override nonReentrant whenNotPaused returns (uint256) {
    return _deposit(tranche, amount);
  }

  /// @inheritdoc ILoan
  /// @notice Supply capital to the loan.
  /// @param tranche Should always be uncalled capital tranche index.
  /// @param amount amount of capital to supply
  /// @param deadline deadline of permit operation
  /// @param v v portion of signature
  /// @param r r portion of signature
  /// @param s s portion of signature
  /// @return tokenId NFT representing your position in this pool
  function depositWithPermit(
    uint256 tranche,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external override nonReentrant whenNotPaused returns (uint256 tokenId) {
    IERC20PermitUpgradeable(config.usdcAddress()).permit(
      msg.sender,
      address(this),
      amount,
      deadline,
      v,
      r,
      s
    );
    return _deposit(tranche, amount);
  }

  /// @inheritdoc ILoan
  function withdraw(
    uint256 tokenId,
    uint256 amount
  ) external override nonReentrant whenNotPaused returns (uint256, uint256) {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    return _withdraw(tokenInfo, tokenId, amount);
  }

  /// @inheritdoc ILoan
  function withdrawMultiple(
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external override nonReentrant whenNotPaused {
    CallableCreditLine storage cl = _staleCreditLine.checkpoint();
    if (tokenIds.length != amounts.length) {
      revert ArrayLengthMismatch(tokenIds.length, amounts.length);
    }

    for (uint256 i = 0; i < amounts.length; i++) {
      IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenIds[i]);
      _withdraw(tokenInfo, tokenIds[i], amounts[i], cl);
    }
  }

  /// @inheritdoc ILoan
  function withdrawMax(
    uint256 tokenId
  )
    external
    override
    nonReentrant
    whenNotPaused
    returns (uint256 interestWithdrawn, uint256 principalWithdrawn)
  {
    return _withdrawMax(tokenId);
  }

  /// @inheritdoc ILoan
  function drawdown(
    uint256 amount
  ) external override(ICreditLine, ILoan) nonReentrant onlyLocker whenNotPaused {
    if (drawdownsPaused) {
      revert CannotDrawdownWhenDrawdownsPaused();
    }
    if (amount == 0) {
      revert ZeroDrawdownAmount();
    }
    CallableCreditLine storage cl = _staleCreditLine.checkpoint();

    cl.drawdown(amount);

    config.getUSDC().safeTransfer(borrower, amount);
    emit DrawdownMade(borrower, amount);
  }

  /// @inheritdoc ILoan
  function pay(
    uint256 amount
  )
    external
    override(ICreditLine, ILoan)
    nonReentrant
    whenNotPaused
    returns (PaymentAllocation memory)
  {
    return _pay(amount);
  }

  /// @notice Pauses all drawdowns (but not deposits/withdraws)
  function pauseDrawdowns() external onlyAdmin {
    drawdownsPaused = true;
    emit DrawdownsPaused(address(this));
  }

  /// @notice Unpause drawdowns
  function unpauseDrawdowns() external onlyAdmin {
    drawdownsPaused = false;
    emit DrawdownsUnpaused(address(this));
  }

  /// Set accepted UID types for the loan.
  /// Requires that users have not already begun to deposit.
  function setAllowedUIDTypes(uint256[] calldata ids) external onlyLocker {
    if (_staleCreditLine.totalPrincipalDeposited() != 0) {
      revert CannotSetAllowedUIDTypesAfterDeposit();
    }
    allowedUIDTypes = ids;
  }

  /// @inheritdoc ILoan
  function setFundableAt(uint256 newFundableAt) external override onlyLocker {
    _staleCreditLine.checkpoint().setFundableAt(newFundableAt);
  }

  /*================================================================================
  Main Public/External View functions
  ================================================================================*/

  /// @inheritdoc ILoan
  function getLoanType() external pure override returns (LoanType) {
    return LoanType.CallableLoan;
  }

  function getFundableAt() external view returns (uint256) {
    return _staleCreditLine.fundableAt();
  }

  function getAllowedUIDTypes() external view override returns (uint256[] memory) {
    return allowedUIDTypes;
  }

  function inLockupPeriod() public view override returns (bool) {
    return _staleCreditLine.inLockupPeriod();
  }

  function numLockupPeriods() public view override returns (uint256) {
    return _staleCreditLine.numLockupPeriods();
  }

  /// @inheritdoc ICallableLoan
  function estimateOwedInterestAt(
    uint256 assumedBalance,
    uint256 timestamp
  ) public view override returns (uint256) {
    return
      (_staleCreditLine.totalInterestAccrued() +
        CallableLoanAccountant.calculateInterest(
          timestamp - block.timestamp,
          assumedBalance,
          _staleCreditLine.interestApr()
        )).saturatingSub(_staleCreditLine.totalInterestPaid());
  }

  /// @inheritdoc ICallableLoan
  function estimateOwedInterestAt(uint256 timestamp) external view override returns (uint256) {
    return estimateOwedInterestAt(interestBearingBalance(), timestamp);
  }

  /// @inheritdoc ICallableLoan
  function loanPhase() public view override returns (LoanPhase) {
    return _staleCreditLine.loanPhase();
  }

  /// TODO: Low priority tests - currently only used for tests and frontend
  /// @inheritdoc ICallableLoan
  function interestBearingBalance() public view override returns (uint256) {
    return
      _staleCreditLine.totalPrincipalDeposited() -
      _staleCreditLine.totalPrincipalPaidAt(block.timestamp);
  }

  /// @inheritdoc ILoan
  function getAmountsOwed(
    uint256 timestamp
  )
    external
    view
    override
    returns (
      uint256 returnedInterestOwed,
      uint256 returnedInterestAccrued,
      uint256 returnedPrincipalOwed
    )
  {
    if (timestamp < block.timestamp) {
      revert InputTimestampInThePast(timestamp);
    }

    return (interestOwedAt(timestamp), interestAccruedAt(timestamp), principalOwedAt(timestamp));
  }

  function uncalledCapitalTrancheIndex() public view override returns (uint256) {
    return _staleCreditLine.uncalledCapitalTrancheIndex();
  }

  function getUncalledCapitalInfo() external view returns (UncalledCapitalInfo memory) {
    SettledTrancheInfo memory info = _staleCreditLine.getSettledTrancheInfo(
      uncalledCapitalTrancheIndex()
    );
    return
      UncalledCapitalInfo({
        interestPaid: info.interestPaid,
        principalDeposited: info.principalDeposited,
        principalPaid: info.principalPaid,
        principalReserved: info.principalReserved
      });
  }

  function getCallRequestPeriod(
    uint256 callRequestPeriodIndex
  ) external view returns (CallRequestPeriod memory) {
    if (callRequestPeriodIndex >= uncalledCapitalTrancheIndex()) {
      revert OutOfCallRequestPeriodBounds(uncalledCapitalTrancheIndex() - 1);
    }
    SettledTrancheInfo memory info = _staleCreditLine.getSettledTrancheInfo(callRequestPeriodIndex);
    return
      CallRequestPeriod({
        interestPaid: info.interestPaid,
        principalDeposited: info.principalDeposited,
        principalPaid: info.principalPaid,
        principalReserved: info.principalReserved
      });
  }

  function availableToCall(uint256 tokenId) public view override returns (uint256) {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    if (tokenInfo.tranche != uncalledCapitalTrancheIndex()) {
      revert MustSubmitCallToUncalledTranche(tokenInfo.tranche, uncalledCapitalTrancheIndex());
    }
    return
      _staleCreditLine.proportionalCallablePrincipal({
        trancheId: tokenInfo.tranche,
        principalDeposited: tokenInfo.principalAmount
      });
  }

  /// @inheritdoc ILoan
  function availableToWithdraw(uint256 tokenId) public view override returns (uint256, uint256) {
    return _availableToWithdraw(config.getPoolTokens().getTokenInfo(tokenId));
  }

  function hasAllowedUID(address sender) public view override returns (bool) {
    return config.getGo().goOnlyIdTypes(sender, allowedUIDTypes);
  }

  /*================================================================================
  Internal Write functions
  ================================================================================*/
  function _pay(uint256 amount) internal returns (ILoan.PaymentAllocation memory) {
    CallableCreditLine storage cl = _staleCreditLine.checkpoint();
    if (amount == 0) {
      revert ZeroPaymentAmount();
    }

    ILoan.PaymentAllocation memory pa = CallableLoanAccountant.allocatePayment({
      paymentAmount: amount,
      interestOwed: cl.interestOwed(),
      interestAccrued: cl.interestAccrued(),
      principalOwed: cl.principalOwed(),
      interestRate: cl.interestApr(),
      balance: cl.totalPrincipalOutstanding(),
      timeUntilNextPrincipalSettlement: cl.nextPrincipalDueTimeAt(block.timestamp).saturatingSub(
        block.timestamp
      ),
      guaranteedFutureInterestPaid: cl.totalInterestPaid().saturatingSub(cl.totalInterestAccrued())
    });

    uint256 totalInterestPayment = pa.owedInterestPayment + pa.accruedInterestPayment;
    uint256 totalPrincipalPayment = pa.principalPayment + pa.additionalBalancePayment;

    uint256 reserveFundsFee = (_reserveFundsFeePercent() * totalInterestPayment) / 100;

    cl.pay(totalPrincipalPayment, totalInterestPayment);
    emit PaymentApplied({
      payer: msg.sender,
      pool: address(this),
      interest: totalInterestPayment,
      principal: totalPrincipalPayment,
      remaining: pa.paymentRemaining,
      reserve: reserveFundsFee
    });

    config.getUSDC().safeTransferFrom(
      msg.sender,
      address(this),
      totalInterestPayment + totalPrincipalPayment
    );
    config.getUSDC().safeTransfer(config.reserveAddress(), reserveFundsFee);
    emit ReserveFundsCollected(address(this), reserveFundsFee);
    return pa;
  }

  /// @notice Supply capital to the loan.
  /// @param tranche Should always be uncalled capital tranche index.
  /// @param amount amount of capital to supply
  /// @return tokenId NFT representing your position in this pool
  function _deposit(uint256 tranche, uint256 amount) internal returns (uint256) {
    CallableCreditLine storage cl = _staleCreditLine.checkpoint();
    if (amount == 0) {
      revert ZeroDepositAmount();
    }
    if (tranche != cl.uncalledCapitalTrancheIndex()) {
      revert MustDepositToUncalledTranche(tranche, cl.uncalledCapitalTrancheIndex());
    }
    if (!hasAllowedUID(msg.sender)) {
      revert InvalidUIDForDepositor(msg.sender);
    }

    cl.deposit(amount);
    uint256 tokenId = config.getPoolTokens().mint(
      IPoolTokens.MintParams({tranche: tranche, principalAmount: amount}),
      msg.sender
    );
    config.getUSDC().safeTransferFrom(msg.sender, address(this), amount);

    emit DepositMade(msg.sender, tranche, tokenId, amount);
    return tokenId;
  }

  function _withdraw(
    IPoolTokens.TokenInfo memory tokenInfo,
    uint256 tokenId,
    uint256 amount
  ) internal returns (uint256, uint256) {
    CallableCreditLine storage cl = _staleCreditLine.checkpoint();
    return _withdraw(tokenInfo, tokenId, amount, cl);
  }

  function _withdraw(
    IPoolTokens.TokenInfo memory tokenInfo,
    uint256 tokenId,
    uint256 amount,
    CallableCreditLine storage cl
  ) internal returns (uint256, uint256) {
    if (amount == 0) {
      revert ZeroWithdrawAmount();
    }
    IPoolTokens poolTokens = config.getPoolTokens();
    if (!poolTokens.isApprovedOrOwner(msg.sender, tokenId) || !hasAllowedUID(msg.sender)) {
      revert NotAuthorizedToWithdraw(msg.sender, tokenId);
    }

    // calculate the amount that will ever be redeemable
    (uint256 interestWithdrawable, uint256 principalWithdrawable) = _availableToWithdraw(
      tokenInfo,
      cl
    );

    if (amount > interestWithdrawable + principalWithdrawable) {
      revert WithdrawAmountExceedsWithdrawable(
        amount,
        interestWithdrawable + principalWithdrawable
      );
    }

    // prefer to withdraw interest first, then principal
    uint256 interestToRedeem = Math.min(interestWithdrawable, amount);
    uint256 amountAfterInterest = amount - interestToRedeem;
    uint256 principalToRedeem = Math.min(amountAfterInterest, principalWithdrawable);

    {
      LoanPhase _loanPhase = cl.loanPhase();
      if (_loanPhase == LoanPhase.InProgress) {
        poolTokens.redeem({
          tokenId: tokenId,
          principalRedeemed: principalToRedeem,
          interestRedeemed: interestToRedeem
        });
      } else if (_loanPhase == LoanPhase.Funding) {
        // if the pool is still funding, we need to decrease the deposit rather than the amount redeemed
        assert(interestToRedeem == 0);
        cl.withdraw(principalToRedeem);
        poolTokens.withdrawPrincipal({tokenId: tokenId, principalAmount: principalToRedeem});
      } else {
        revert CannotWithdrawInDrawdownPeriod();
      }
    }

    config.getUSDC().safeTransfer(msg.sender, interestToRedeem + principalToRedeem);

    // While owner is the label of the first argument, it is actually the sender of the transaction.
    emit WithdrawalMade({
      owner: msg.sender,
      tranche: tokenInfo.tranche,
      tokenId: tokenId,
      interestWithdrawn: interestToRedeem,
      principalWithdrawn: principalToRedeem
    });

    return (interestToRedeem, principalToRedeem);
  }

  function _withdrawMax(uint256 tokenId) internal returns (uint256, uint256) {
    CallableCreditLine storage cl = _staleCreditLine.checkpoint();
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    (uint256 interestWithdrawable, uint256 principalWithdrawable) = _availableToWithdraw(tokenInfo);
    uint256 totalWithdrawable = interestWithdrawable + principalWithdrawable;
    return _withdraw(tokenInfo, tokenId, totalWithdrawable, cl);
  }

  /*================================================================================
  PaymentSchedule proxy functions
  ================================================================================*/
  function nextPrincipalDueTime() public view override returns (uint256) {
    return _staleCreditLine.nextPrincipalDueTime();
  }

  function nextDueTimeAt(uint256 timestamp) public view override returns (uint256) {
    return _staleCreditLine.nextDueTimeAt(timestamp);
  }

  function nextInterestDueTimeAt(uint256 timestamp) public view returns (uint256) {
    return _staleCreditLine.nextInterestDueTimeAt(timestamp);
  }

  function schedule() public view override returns (ISchedule) {
    return _staleCreditLine.schedule();
  }

  /*================================================================================
  Internal View functions
  ================================================================================*/
  function _reserveFundsFeePercent() public view returns (uint256) {
    return uint256(100) / (config.getReserveDenominator());
  }

  function _availableToWithdraw(
    IPoolTokens.TokenInfo memory tokenInfo
  ) internal view returns (uint256 interestAvailable, uint256 principalAvailable) {
    // Bail out early to account for proportion of zero or invalid phase for withdrawal
    if (tokenInfo.principalAmount == 0 || loanPhase() == LoanPhase.DrawdownPeriod) {
      return (0, 0);
    }

    (uint256 totalInterestWithdrawable, uint256 totalPrincipalWithdrawable) = _staleCreditLine
      .proportionalInterestAndPrincipalAvailable({
        trancheId: tokenInfo.tranche,
        principal: tokenInfo.principalAmount,
        feePercent: _reserveFundsFeePercent()
      });

    return
      _availableToWithdrawGivenProportions(
        tokenInfo,
        totalInterestWithdrawable,
        totalPrincipalWithdrawable
      );
  }

  function _availableToWithdraw(
    IPoolTokens.TokenInfo memory tokenInfo,
    CallableCreditLine storage cl
  ) internal view returns (uint256 interestAvailable, uint256 principalAvailable) {
    if (tokenInfo.principalAmount == 0) {
      // Bail out early to account for proportion of zero.
      return (0, 0);
    }

    (uint256 totalInterestWithdrawable, uint256 totalPrincipalWithdrawable) = cl
      .proportionalInterestAndPrincipalAvailable({
        trancheId: tokenInfo.tranche,
        principal: tokenInfo.principalAmount,
        feePercent: _reserveFundsFeePercent()
      });

    return
      _availableToWithdrawGivenProportions(
        tokenInfo,
        totalInterestWithdrawable,
        totalPrincipalWithdrawable
      );
  }

  function _availableToWithdrawGivenProportions(
    IPoolTokens.TokenInfo memory tokenInfo,
    uint256 totalInterestWithdrawable,
    uint256 totalPrincipalWithdrawable
  ) internal view returns (uint256 interestAvailable, uint256 principalAvailable) {
    // Due to integer math, redeemeded amounts can be more than redeemable amounts after splitting.
    assert(tokenInfo.principalRedeemed <= totalPrincipalWithdrawable + 1);
    assert(tokenInfo.interestRedeemed <= totalInterestWithdrawable + 1);

    return (
      totalInterestWithdrawable.saturatingSub(tokenInfo.interestRedeemed),
      totalPrincipalWithdrawable.saturatingSub(tokenInfo.principalRedeemed)
    );
  }

  /*================================================================================
  Legacy ICreditLine Conformance
  ================================================================================*/
  /// @inheritdoc ILoan
  function creditLine() external view override returns (ICreditLine) {
    return this;
  }

  /// @inheritdoc ICreditLine
  function balance() public view returns (uint256) {
    return _staleCreditLine.totalPrincipalOutstanding();
  }

  /// @inheritdoc ICreditLine
  function interestOwed() public view override returns (uint256) {
    return _staleCreditLine.interestOwed();
  }

  /// @inheritdoc ICreditLine
  function principalOwed() public view override returns (uint256) {
    return _staleCreditLine.principalOwed();
  }

  /// @inheritdoc ICreditLine
  function termEndTime() public view override returns (uint256) {
    return _staleCreditLine.termEndTime();
  }

  /// @inheritdoc ICreditLine
  function nextDueTime() public view override returns (uint256) {
    return _staleCreditLine.nextDueTime();
  }

  /// @notice We keep this to conform to the ICreditLine interface, but it's redundant information
  ///   now that we have `checkpointedAsOf`
  function interestAccruedAsOf() public view override returns (uint256) {
    return _staleCreditLine.checkpointedAsOf();
  }

  /// @inheritdoc ICreditLine
  function currentLimit() public view override returns (uint256) {
    return _staleCreditLine.limit();
  }

  /// @inheritdoc ICreditLine
  function limit() public view override returns (uint256) {
    return _staleCreditLine.limit();
  }

  /// @inheritdoc ICreditLine
  function interestApr() public view override returns (uint256) {
    return _staleCreditLine.interestApr();
  }

  /// @inheritdoc ICreditLine
  function lateFeeApr() public view override returns (uint256) {
    return _staleCreditLine.lateAdditionalApr();
  }

  /// @inheritdoc ICreditLine
  function isLate() public view override returns (bool) {
    return _staleCreditLine.isLate();
  }

  /// @notice If a checkpoint has not occurred, late fees may be overestimated beyond the next due time.
  /// @inheritdoc ICreditLine
  function totalInterestAccrued() public view override returns (uint256) {
    return _staleCreditLine.totalInterestAccrued();
  }

  /// @notice If a checkpoint has not occurred, late fees may be overestimated beyond the next due time.
  /// @inheritdoc ICreditLine
  function totalInterestAccruedAt(uint256 timestamp) public view override returns (uint256) {
    return _staleCreditLine.totalInterestAccruedAt(timestamp);
  }

  /// @inheritdoc ICreditLine
  function totalInterestPaid() public view override returns (uint256) {
    return _staleCreditLine.totalInterestPaid();
  }

  /// @notice If a checkpoint has not occurred, late fees may be overestimated beyond the next due time.
  /// @inheritdoc ICreditLine
  function totalInterestOwed() public view override returns (uint256) {
    return _staleCreditLine.totalInterestOwed();
  }

  /// @notice If a checkpoint has not occurred, late fees may be overestimated beyond the next due time.
  /// @inheritdoc ICreditLine
  function totalInterestOwedAt(uint256 timestamp) public view override returns (uint256) {
    return _staleCreditLine.totalInterestOwedAt(timestamp);
  }

  /// @notice If a checkpoint has not occurred, late fees may be overestimated beyond the next due time.
  /// @inheritdoc ICreditLine
  function interestOwedAt(uint256 timestamp) public view override returns (uint256) {
    return _staleCreditLine.interestOwedAt(timestamp);
  }

  /// @notice If a checkpoint has not occurred, late fees may be overestimated beyond the next due time.
  /// @inheritdoc ICreditLine
  function interestAccrued() public view override returns (uint256) {
    return _staleCreditLine.interestAccrued();
  }

  /// @notice If a checkpoint has not occurred, late fees may be overestimated beyond the next due time.
  /// @inheritdoc ICreditLine
  function interestAccruedAt(uint256 timestamp) public view override returns (uint256) {
    return _staleCreditLine.interestAccruedAt(timestamp);
  }

  /// @inheritdoc ICreditLine
  function principalOwedAt(uint256 timestamp) public view override returns (uint256) {
    return _staleCreditLine.principalOwedAt(timestamp);
  }

  /// @inheritdoc ICreditLine
  function totalPrincipalPaid() public view override returns (uint256) {
    return _staleCreditLine.totalPrincipalPaid();
  }

  /// @inheritdoc ICreditLine
  function totalPrincipalOwedAt(uint256 timestamp) public view override returns (uint256) {
    return _staleCreditLine.totalPrincipalOwedAt(timestamp);
  }

  /// @inheritdoc ICreditLine
  function totalPrincipalOwed() public view override returns (uint256) {
    return _staleCreditLine.totalPrincipalOwed();
  }

  /// @inheritdoc ICreditLine
  function termStartTime() public view override returns (uint256) {
    return _staleCreditLine.termStartTime();
  }

  /// @inheritdoc ICreditLine
  function withinPrincipalGracePeriod() public view override returns (bool) {
    return _staleCreditLine.withinPrincipalGracePeriod();
  }

  /// @inheritdoc ICreditLine
  function lastFullPaymentTime() public view override returns (uint256) {
    return _staleCreditLine.lastFullPaymentTime();
  }

  /// Unsupported in callable loans.
  function pay(
    uint256,
    uint256
  ) external pure override(ICreditLine) returns (PaymentAllocation memory) {
    revert UnsupportedOperation();
  }

  /// Unsupported in callable loans.
  function maxLimit() external pure override returns (uint256) {
    revert UnsupportedOperation();
  }

  /// Unsupported in callable loans.

  function setMaxLimit(uint256) external pure override {
    revert UnsupportedOperation();
  }

  /// Unsupported ICreditLine method kept for ICreditLine conformance

  function setLimit(uint256) external pure override {
    revert UnsupportedOperation();
  }

  /*================================================================================
  Modifiers
  ================================================================================*/
  /// @inheritdoc IVersioned
  function getVersion() external pure override returns (uint8[3] memory version) {
    (version[0], version[1], version[2]) = (MAJOR_VERSION, MINOR_VERSION, PATCH_VERSION);
  }

  modifier onlyLocker() {
    if (!hasRole(LOCKER_ROLE, msg.sender)) {
      revert RequiresLockerRole(msg.sender);
    }
    _;
  }
}