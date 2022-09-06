// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20Permit} from "@openzeppelin/contracts/drafts/IERC20Permit.sol";
import {Math} from "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import {SafeMath} from "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

import {ITranchedPool} from "../../interfaces/ITranchedPool.sol";
import {IRequiresUID} from "../../interfaces/IRequiresUID.sol";
import {IERC20withDec} from "../../interfaces/IERC20withDec.sol";
import {IV2CreditLine} from "../../interfaces/IV2CreditLine.sol";
import {IBackerRewards} from "../../interfaces/IBackerRewards.sol";
import {IPoolTokens} from "../../interfaces/IPoolTokens.sol";
import {IVersioned} from "../../interfaces/IVersioned.sol";
import {GoldfinchConfig} from "./GoldfinchConfig.sol";
import {BaseUpgradeablePausable} from "./BaseUpgradeablePausable.sol";
import {ConfigHelper} from "./ConfigHelper.sol";
import {SafeERC20Transfer} from "../../library/SafeERC20Transfer.sol";
import {TranchingLogic} from "./TranchingLogic.sol";

contract TranchedPool is BaseUpgradeablePausable, ITranchedPool, IRequiresUID, IVersioned {
  GoldfinchConfig public config;
  using ConfigHelper for GoldfinchConfig;
  using TranchingLogic for PoolSlice;
  using TranchingLogic for TrancheInfo;
  using SafeERC20Transfer for IERC20withDec;

  bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");
  bytes32 public constant SENIOR_ROLE = keccak256("SENIOR_ROLE");
  uint8 internal constant MAJOR_VERSION = 0;
  uint8 internal constant MINOR_VERSION = 1;
  uint8 internal constant PATCH_VERSION = 0;
  uint256 public juniorFeePercent;
  bool public drawdownsPaused;
  uint256[] public allowedUIDTypes;
  uint256 public totalDeployed;
  uint256 public fundableAt;

  mapping(uint256 => PoolSlice) internal _poolSlices;
  uint256 public override numSlices;

  function initialize(
    address _config,
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays,
    uint256 _fundableAt,
    uint256[] calldata _allowedUIDTypes
  ) public override initializer {
    require(address(_config) != address(0) && address(_borrower) != address(0), "ZERO");

    config = GoldfinchConfig(_config);
    address owner = config.protocolAdminAddress();
    __BaseUpgradeablePausable__init(owner);
    _initializeNextSlice(_fundableAt);
    _createAndSetCreditLine(
      _borrower,
      _limit,
      _interestApr,
      _paymentPeriodInDays,
      _termInDays,
      _lateFeeApr,
      _principalGracePeriodInDays
    );

    createdAt = block.timestamp;
    juniorFeePercent = _juniorFeePercent;
    if (_allowedUIDTypes.length == 0) {
      uint256[1] memory defaultAllowedUIDTypes = [config.getGo().ID_TYPE_0()];
      allowedUIDTypes = defaultAllowedUIDTypes;
    } else {
      allowedUIDTypes = _allowedUIDTypes;
    }

    _setupRole(LOCKER_ROLE, _borrower);
    _setupRole(LOCKER_ROLE, owner);
    _setRoleAdmin(LOCKER_ROLE, OWNER_ROLE);
    _setRoleAdmin(SENIOR_ROLE, OWNER_ROLE);

    // Give the senior pool the ability to deposit into the senior pool
    _setupRole(SENIOR_ROLE, address(config.getSeniorPool()));

    // Unlock self for infinite amount
    require(config.getUSDC().approve(address(this), uint256(-1)));
  }

  function setAllowedUIDTypes(uint256[] calldata ids) external onlyLocker {
    require(
      _poolSlices[0].juniorTranche.principalDeposited == 0 && _poolSlices[0].seniorTranche.principalDeposited == 0,
      "has balance"
    );
    allowedUIDTypes = ids;
  }

  function getAllowedUIDTypes() external view returns (uint256[] memory) {
    return allowedUIDTypes;
  }

  /**
   * @notice Deposit a USDC amount into the pool for a tranche. Mints an NFT to the caller representing the position
   * @param tranche The number representing the tranche to deposit into
   * @param amount The USDC amount to tranfer from the caller to the pool
   * @return tokenId The tokenId of the NFT
   */
  function deposit(uint256 tranche, uint256 amount) public override nonReentrant whenNotPaused returns (uint256) {
    TrancheInfo storage trancheInfo = _getTrancheInfo(tranche);
    /// @dev TL: tranche locked
    require(trancheInfo.lockedUntil == 0, "TL");
    /// @dev IA: invalid amount
    require(amount > 0, "IA");
    /// @dev NA: not authorized. Must have correct UID or be go listed
    require(hasAllowedUID(msg.sender), "NA");
    require(block.timestamp > fundableAt, "Not open");
    // senior tranche ids are always odd numbered
    if (TranchingLogic.isSeniorTrancheId(trancheInfo.id)) {
      require(hasRole(SENIOR_ROLE, _msgSender()), "NA");
    }

    trancheInfo.principalDeposited = trancheInfo.principalDeposited.add(amount);
    uint256 tokenId = config.getPoolTokens().mint(
      IPoolTokens.MintParams({tranche: tranche, principalAmount: amount}),
      msg.sender
    );

    config.getUSDC().safeERC20TransferFrom(msg.sender, address(this), amount);
    emit DepositMade(msg.sender, tranche, tokenId, amount);
    return tokenId;
  }

  function depositWithPermit(
    uint256 tranche,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public override returns (uint256 tokenId) {
    IERC20Permit(config.usdcAddress()).permit(msg.sender, address(this), amount, deadline, v, r, s);
    return deposit(tranche, amount);
  }

  /**
   * @notice Withdraw an already deposited amount if the funds are available
   * @param tokenId The NFT representing the position
   * @param amount The amount to withdraw (must be <= interest+principal currently available to withdraw)
   * @return interestWithdrawn The interest amount that was withdrawn
   * @return principalWithdrawn The principal amount that was withdrawn
   */
  function withdraw(uint256 tokenId, uint256 amount)
    public
    override
    nonReentrant
    whenNotPaused
    returns (uint256, uint256)
  {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    TrancheInfo storage trancheInfo = _getTrancheInfo(tokenInfo.tranche);

    return _withdraw(trancheInfo, tokenInfo, tokenId, amount);
  }

  /**
   * @notice Withdraw from many tokens (that the sender owns) in a single transaction
   * @param tokenIds An array of tokens ids representing the position
   * @param amounts An array of amounts to withdraw from the corresponding tokenIds
   */
  function withdrawMultiple(uint256[] calldata tokenIds, uint256[] calldata amounts) public override {
    require(tokenIds.length == amounts.length, "LEN");

    for (uint256 i = 0; i < amounts.length; i++) {
      withdraw(tokenIds[i], amounts[i]);
    }
  }

  /**
   * @notice Similar to withdraw but will withdraw all available funds
   * @param tokenId The NFT representing the position
   * @return interestWithdrawn The interest amount that was withdrawn
   * @return principalWithdrawn The principal amount that was withdrawn
   */
  function withdrawMax(uint256 tokenId)
    external
    override
    nonReentrant
    whenNotPaused
    returns (uint256 interestWithdrawn, uint256 principalWithdrawn)
  {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    TrancheInfo storage trancheInfo = _getTrancheInfo(tokenInfo.tranche);

    (uint256 interestRedeemable, uint256 principalRedeemable) = TranchingLogic.redeemableInterestAndPrincipal(
      trancheInfo,
      tokenInfo
    );

    uint256 amount = interestRedeemable.add(principalRedeemable);

    return _withdraw(trancheInfo, tokenInfo, tokenId, amount);
  }

  /**
   * @notice Draws down the funds (and locks the pool) to the borrower address. Can only be called by the borrower
   * @param amount The amount to drawdown from the creditline (must be < limit)
   */
  function drawdown(uint256 amount) external override onlyLocker whenNotPaused {
    /// @dev DP: drawdowns paused
    require(!drawdownsPaused, "DP");
    if (!_locked()) {
      // Assumes the senior pool has invested already (saves the borrower a separate transaction to lock the pool)
      _lockPool();
    }
    // Drawdown only draws down from the current slice for simplicity. It's harder to account for how much
    // money is available from previous slices since depositors can redeem after unlock.
    PoolSlice storage currentSlice = _poolSlices[numSlices - 1];
    uint256 amountAvailable = TranchingLogic.sharePriceToUsdc(
      currentSlice.juniorTranche.principalSharePrice,
      currentSlice.juniorTranche.principalDeposited
    );
    amountAvailable = amountAvailable.add(
      TranchingLogic.sharePriceToUsdc(
        currentSlice.seniorTranche.principalSharePrice,
        currentSlice.seniorTranche.principalDeposited
      )
    );

    /// @dev IF: insufficient funds
    require(amount <= amountAvailable, "IF");

    creditLine.drawdown(amount);

    // Update the share price to reflect the amount remaining in the pool
    uint256 amountRemaining = amountAvailable.sub(amount);
    uint256 oldJuniorPrincipalSharePrice = currentSlice.juniorTranche.principalSharePrice;
    uint256 oldSeniorPrincipalSharePrice = currentSlice.seniorTranche.principalSharePrice;
    currentSlice.juniorTranche.principalSharePrice = currentSlice.juniorTranche.calculateExpectedSharePrice(
      amountRemaining,
      currentSlice
    );
    currentSlice.seniorTranche.principalSharePrice = currentSlice.seniorTranche.calculateExpectedSharePrice(
      amountRemaining,
      currentSlice
    );
    currentSlice.principalDeployed = currentSlice.principalDeployed.add(amount);
    totalDeployed = totalDeployed.add(amount);

    address borrower = creditLine.borrower();
    IBackerRewards backerRewards = IBackerRewards(config.backerRewardsAddress());
    backerRewards.onTranchedPoolDrawdown(numSlices - 1);
    config.getUSDC().safeERC20TransferFrom(address(this), borrower, amount);
    emit DrawdownMade(borrower, amount);
    emit SharePriceUpdated(
      address(this),
      currentSlice.juniorTranche.id,
      currentSlice.juniorTranche.principalSharePrice,
      int256(oldJuniorPrincipalSharePrice.sub(currentSlice.juniorTranche.principalSharePrice)) * -1,
      currentSlice.juniorTranche.interestSharePrice,
      0
    );
    emit SharePriceUpdated(
      address(this),
      currentSlice.seniorTranche.id,
      currentSlice.seniorTranche.principalSharePrice,
      int256(oldSeniorPrincipalSharePrice.sub(currentSlice.seniorTranche.principalSharePrice)) * -1,
      currentSlice.seniorTranche.interestSharePrice,
      0
    );
  }

  function NUM_TRANCHES_PER_SLICE() external pure returns (uint256) {
    return TranchingLogic.NUM_TRANCHES_PER_SLICE;
  }

  /**
   * @notice Locks the junior tranche, preventing more junior deposits. Gives time for the senior to determine how
   * much to invest (ensure leverage ratio cannot change for the period)
   */
  function lockJuniorCapital() external override onlyLocker whenNotPaused {
    _lockJuniorCapital(numSlices.sub(1));
  }

  /**
   * @notice Locks the pool (locks both senior and junior tranches and starts the drawdown period). Beyond the drawdown
   * period, any unused capital is available to withdraw by all depositors
   */
  function lockPool() external override onlyLocker whenNotPaused {
    _lockPool();
  }

  function setFundableAt(uint256 newFundableAt) external override onlyLocker {
    fundableAt = newFundableAt;
  }

  function initializeNextSlice(uint256 _fundableAt) external override onlyLocker whenNotPaused {
    /// @dev NL: not locked
    require(_locked(), "NL");
    /// @dev LP: late payment
    require(!creditLine.isLate(), "LP");
    /// @dev GP: beyond principal grace period
    require(creditLine.withinPrincipalGracePeriod(), "GP");
    _initializeNextSlice(_fundableAt);
    emit SliceCreated(address(this), numSlices.sub(1));
  }

  /**
   * @notice Triggers an assessment of the creditline and the applies the payments according the tranche waterfall
   */
  function assess() external override whenNotPaused {
    _assess();
  }

  /**
   * @notice Allows repaying the creditline. Collects the USDC amount from the sender and triggers an assess
   * @param amount The amount to repay
   */
  function pay(uint256 amount) external override whenNotPaused {
    /// @dev  IA: cannot pay 0
    require(amount > 0, "IA");
    config.getUSDC().safeERC20TransferFrom(msg.sender, address(creditLine), amount);
    _assess();
  }

  /**
   * @notice Pauses the pool and sweeps any remaining funds to the treasury reserve.
   */
  function emergencyShutdown() public onlyAdmin {
    if (!paused()) {
      pause();
    }

    IERC20withDec usdc = config.getUSDC();
    address reserveAddress = config.reserveAddress();
    // Sweep any funds to community reserve
    uint256 poolBalance = usdc.balanceOf(address(this));
    if (poolBalance > 0) {
      config.getUSDC().safeERC20Transfer(reserveAddress, poolBalance);
    }

    uint256 clBalance = usdc.balanceOf(address(creditLine));
    if (clBalance > 0) {
      usdc.safeERC20TransferFrom(address(creditLine), reserveAddress, clBalance);
    }
    emit EmergencyShutdown(address(this));
  }

  /**
   * @notice Pauses all drawdowns (but not deposits/withdraws)
   */
  function pauseDrawdowns() public onlyAdmin {
    drawdownsPaused = true;
    emit DrawdownsPaused(address(this));
  }

  /**
   * @notice Unpause drawdowns
   */
  function unpauseDrawdowns() public onlyAdmin {
    drawdownsPaused = false;
    emit DrawdownsUnpaused(address(this));
  }

  /**
   * @notice Migrates the accounting variables from the current creditline to a brand new one
   * @param _borrower The borrower address
   * @param _maxLimit The new max limit
   * @param _interestApr The new interest APR
   * @param _paymentPeriodInDays The new payment period in days
   * @param _termInDays The new term in days
   * @param _lateFeeApr The new late fee APR
   */
  function migrateCreditLine(
    address _borrower,
    uint256 _maxLimit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) public onlyAdmin {
    require(_borrower != address(0) && _paymentPeriodInDays != 0 && _termInDays != 0, "ZERO");

    IV2CreditLine originalCl = creditLine;

    _createAndSetCreditLine(
      _borrower,
      _maxLimit,
      _interestApr,
      _paymentPeriodInDays,
      _termInDays,
      _lateFeeApr,
      _principalGracePeriodInDays
    );

    TranchingLogic.migrateAccountingVariables(originalCl, creditLine);
    TranchingLogic.closeCreditLine(originalCl);
    address originalBorrower = originalCl.borrower();
    address newBorrower = creditLine.borrower();

    // Ensure Roles
    if (originalBorrower != newBorrower) {
      revokeRole(LOCKER_ROLE, originalBorrower);
      grantRole(LOCKER_ROLE, newBorrower);
    }
    // Transfer any funds to new CL
    uint256 clBalance = config.getUSDC().balanceOf(address(originalCl));
    if (clBalance > 0) {
      config.getUSDC().safeERC20TransferFrom(address(originalCl), address(creditLine), clBalance);
    }
    emit CreditLineMigrated(originalCl, creditLine);
  }

  // CreditLine proxy method
  function setLimit(uint256 newAmount) external onlyAdmin {
    return creditLine.setLimit(newAmount);
  }

  function setMaxLimit(uint256 newAmount) external onlyAdmin {
    return creditLine.setMaxLimit(newAmount);
  }

  function getTranche(uint256 tranche) public view override returns (TrancheInfo memory) {
    return _getTrancheInfo(tranche);
  }

  function poolSlices(uint256 index) external view override returns (PoolSlice memory) {
    return _poolSlices[index];
  }

  /**
   * @notice Returns the total junior capital deposited
   * @return The total USDC amount deposited into all junior tranches
   */
  function totalJuniorDeposits() external view override returns (uint256) {
    uint256 total;
    for (uint256 i = 0; i < numSlices; i++) {
      total = total.add(_poolSlices[i].juniorTranche.principalDeposited);
    }
    return total;
  }

  /**
   * @notice Determines the amount of interest and principal redeemable by a particular tokenId
   * @param tokenId The token representing the position
   * @return interestRedeemable The interest available to redeem
   * @return principalRedeemable The principal available to redeem
   */
  function availableToWithdraw(uint256 tokenId) public view override returns (uint256, uint256) {
    IPoolTokens.TokenInfo memory tokenInfo = config.getPoolTokens().getTokenInfo(tokenId);
    TrancheInfo storage trancheInfo = _getTrancheInfo(tokenInfo.tranche);

    if (block.timestamp > trancheInfo.lockedUntil) {
      return TranchingLogic.redeemableInterestAndPrincipal(trancheInfo, tokenInfo);
    } else {
      return (0, 0);
    }
  }

  function hasAllowedUID(address sender) public view override returns (bool) {
    return config.getGo().goOnlyIdTypes(sender, allowedUIDTypes);
  }

  /* Internal functions  */

  function _collectInterestAndPrincipal(
    address from,
    uint256 interest,
    uint256 principal
  ) internal returns (uint256) {
    uint256 totalReserveAmount = TranchingLogic.applyToAllSlices(
      _poolSlices,
      numSlices,
      interest,
      principal,
      uint256(100).div(config.getReserveDenominator()), // Convert the denonminator to percent
      totalDeployed,
      creditLine,
      juniorFeePercent
    );

    config.getUSDC().safeERC20TransferFrom(from, address(this), principal.add(interest));
    config.getUSDC().safeERC20TransferFrom(address(this), config.reserveAddress(), totalReserveAmount);

    emit ReserveFundsCollected(address(this), totalReserveAmount);

    return totalReserveAmount;
  }

  function _createAndSetCreditLine(
    address _borrower,
    uint256 _maxLimit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) internal {
    creditLine = IV2CreditLine(config.getGoldfinchFactory().createCreditLine());
    creditLine.initialize(
      address(config),
      address(this), // Set self as the owner
      _borrower,
      _maxLimit,
      _interestApr,
      _paymentPeriodInDays,
      _termInDays,
      _lateFeeApr,
      _principalGracePeriodInDays
    );
  }

  // // Internal //////////////////////////////////////////////////////////////////

  function _withdraw(
    TrancheInfo storage trancheInfo,
    IPoolTokens.TokenInfo memory tokenInfo,
    uint256 tokenId,
    uint256 amount
  ) internal returns (uint256, uint256) {
    /// @dev NA: not authorized
    require(config.getPoolTokens().isApprovedOrOwner(msg.sender, tokenId) && hasAllowedUID(msg.sender), "NA");
    /// @dev IA: invalid amount. Cannot withdraw 0
    require(amount > 0, "IA");
    (uint256 interestRedeemable, uint256 principalRedeemable) = TranchingLogic.redeemableInterestAndPrincipal(
      trancheInfo,
      tokenInfo
    );
    uint256 netRedeemable = interestRedeemable.add(principalRedeemable);

    /// @dev IA: invalid amount. User does not have enough available to redeem
    require(amount <= netRedeemable, "IA");
    /// @dev TL: Tranched Locked
    require(block.timestamp > trancheInfo.lockedUntil, "TL");

    uint256 interestToRedeem = 0;
    uint256 principalToRedeem = 0;

    // If the tranche has not been locked, ensure the deposited amount is correct
    if (trancheInfo.lockedUntil == 0) {
      trancheInfo.principalDeposited = trancheInfo.principalDeposited.sub(amount);

      principalToRedeem = amount;

      config.getPoolTokens().withdrawPrincipal(tokenId, principalToRedeem);
    } else {
      interestToRedeem = Math.min(interestRedeemable, amount);
      principalToRedeem = Math.min(principalRedeemable, amount.sub(interestToRedeem));

      config.getPoolTokens().redeem(tokenId, principalToRedeem, interestToRedeem);
    }

    config.getUSDC().safeERC20TransferFrom(address(this), msg.sender, principalToRedeem.add(interestToRedeem));

    emit WithdrawalMade(msg.sender, tokenInfo.tranche, tokenId, interestToRedeem, principalToRedeem);

    return (interestToRedeem, principalToRedeem);
  }

  function _lockJuniorCapital(uint256 sliceId) internal {
    /// @dev TL: tranch locked
    require(!_locked() && _poolSlices[sliceId].juniorTranche.lockedUntil == 0, "TL");

    TranchingLogic.lockTranche(_poolSlices[sliceId].juniorTranche, config);
  }

  function _lockPool() internal {
    PoolSlice storage slice = _poolSlices[numSlices.sub(1)];
    /// @dev NL: Not locked
    require(slice.juniorTranche.lockedUntil > 0, "NL");
    // Allow locking the pool only once; do not allow extending the lock of an
    // already-locked pool. Otherwise the locker could keep the pool locked
    // indefinitely, preventing withdrawals.
    /// @dev TL: tranche locked. The senior pool has already been locked.
    require(slice.seniorTranche.lockedUntil == 0, "TL");

    uint256 currentTotal = slice.juniorTranche.principalDeposited.add(slice.seniorTranche.principalDeposited);
    creditLine.setLimit(Math.min(creditLine.limit().add(currentTotal), creditLine.maxLimit()));

    // We start the drawdown period, so backers can withdraw unused capital after borrower draws down
    TranchingLogic.lockTranche(slice.juniorTranche, config);
    TranchingLogic.lockTranche(slice.seniorTranche, config);
  }

  function _initializeNextSlice(uint256 newFundableAt) internal {
    /// @dev SL: slice limit
    require(numSlices < 5, "SL");
    TranchingLogic.initializeNextSlice(_poolSlices, numSlices);
    numSlices = numSlices.add(1);
    fundableAt = newFundableAt;
  }

  // If the senior tranche of the current slice is locked, then the pool is not open to any more deposits
  // (could throw off leverage ratio)
  function _locked() internal view returns (bool) {
    return numSlices == 0 || _poolSlices[numSlices - 1].seniorTranche.lockedUntil > 0;
  }

  function _getTrancheInfo(uint256 trancheId) internal view returns (TrancheInfo storage) {
    require(trancheId > 0 && trancheId <= numSlices.mul(TranchingLogic.NUM_TRANCHES_PER_SLICE), "invalid tranche");
    uint256 sliceId = TranchingLogic.trancheIdToSliceIndex(trancheId);
    PoolSlice storage slice = _poolSlices[sliceId];
    TrancheInfo storage trancheInfo = TranchingLogic.isSeniorTrancheId(trancheId)
      ? slice.seniorTranche
      : slice.juniorTranche;
    return trancheInfo;
  }

  function _assess() internal {
    // We need to make sure the pool is locked before we allocate rewards to ensure it's not
    // possible to game rewards by sandwiching an interest payment to an unlocked pool
    // It also causes issues trying to allocate payments to an empty slice (divide by zero)
    /// @dev NL: not locked
    require(_locked(), "NL");

    uint256 interestAccrued = creditLine.totalInterestAccrued();
    (uint256 paymentRemaining, uint256 interestPayment, uint256 principalPayment) = creditLine.assess();
    interestAccrued = creditLine.totalInterestAccrued().sub(interestAccrued);

    // Split the interest accrued proportionally across slices so we know how much interest goes to each slice
    // We need this because the slice start at different times, so we cannot retroactively allocate the interest
    // linearly
    uint256[] memory principalPaymentsPerSlice = new uint256[](numSlices);
    for (uint256 i = 0; i < numSlices; i++) {
      uint256 interestForSlice = TranchingLogic.scaleByFraction(
        interestAccrued,
        _poolSlices[i].principalDeployed,
        totalDeployed
      );
      principalPaymentsPerSlice[i] = TranchingLogic.scaleByFraction(
        principalPayment,
        _poolSlices[i].principalDeployed,
        totalDeployed
      );
      _poolSlices[i].totalInterestAccrued = _poolSlices[i].totalInterestAccrued.add(interestForSlice);
    }

    if (interestPayment > 0 || principalPayment > 0) {
      uint256 reserveAmount = _collectInterestAndPrincipal(
        address(creditLine),
        interestPayment,
        principalPayment.add(paymentRemaining)
      );

      for (uint256 i = 0; i < numSlices; i++) {
        _poolSlices[i].principalDeployed = _poolSlices[i].principalDeployed.sub(principalPaymentsPerSlice[i]);
        totalDeployed = totalDeployed.sub(principalPaymentsPerSlice[i]);
      }

      config.getBackerRewards().allocateRewards(interestPayment);

      emit PaymentApplied(
        creditLine.borrower(),
        address(this),
        interestPayment,
        principalPayment,
        paymentRemaining,
        reserveAmount
      );
    }
    emit TranchedPoolAssessed(address(this));
  }

  // // Events ////////////////////////////////////////////////////////////////////

  event DepositMade(address indexed owner, uint256 indexed tranche, uint256 indexed tokenId, uint256 amount);
  event WithdrawalMade(
    address indexed owner,
    uint256 indexed tranche,
    uint256 indexed tokenId,
    uint256 interestWithdrawn,
    uint256 principalWithdrawn
  );

  event TranchedPoolAssessed(address indexed pool);
  event PaymentApplied(
    address indexed payer,
    address indexed pool,
    uint256 interestAmount,
    uint256 principalAmount,
    uint256 remainingAmount,
    uint256 reserveAmount
  );
  // Note: This has to exactly match the even in the TranchingLogic library for events to be emitted
  // correctly
  event SharePriceUpdated(
    address indexed pool,
    uint256 indexed tranche,
    uint256 principalSharePrice,
    int256 principalDelta,
    uint256 interestSharePrice,
    int256 interestDelta
  );
  event ReserveFundsCollected(address indexed from, uint256 amount);
  event CreditLineMigrated(IV2CreditLine indexed oldCreditLine, IV2CreditLine indexed newCreditLine);
  event DrawdownMade(address indexed borrower, uint256 amount);
  event DrawdownsPaused(address indexed pool);
  event DrawdownsUnpaused(address indexed pool);
  event EmergencyShutdown(address indexed pool);
  event TrancheLocked(address indexed pool, uint256 trancheId, uint256 lockedUntil);
  event SliceCreated(address indexed pool, uint256 sliceId);

  // // Modifiers /////////////////////////////////////////////////////////////////

  /// @inheritdoc IVersioned
  function getVersion() external pure override returns (uint8[3] memory version) {
    (version[0], version[1], version[2]) = (MAJOR_VERSION, MINOR_VERSION, PATCH_VERSION);
  }

  modifier onlyLocker() {
    /// @dev NA: not authorized. not locker
    require(hasRole(LOCKER_ROLE, msg.sender), "NA");
    _;
  }
}