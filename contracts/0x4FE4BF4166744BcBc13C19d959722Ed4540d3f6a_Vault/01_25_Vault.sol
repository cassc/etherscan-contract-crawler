// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IVault} from "./vault/IVault.sol";
import {IVaultSponsoring} from "./vault/IVaultSponsoring.sol";
import {IVaultSettings} from "./vault/IVaultSettings.sol";
import {CurveSwapper} from "./vault/CurveSwapper.sol";
import {PercentMath} from "./lib/PercentMath.sol";
import {ExitPausable} from "./lib/ExitPausable.sol";
import {IStrategy} from "./strategy/IStrategy.sol";
import {CustomErrors} from "./interfaces/CustomErrors.sol";

/**
 * A vault where other accounts can deposit an underlying token
 * currency and set distribution params for their principal and yield
 *
 * @notice The underlying token can be automatically swapped from any configured ERC20 token via {CurveSwapper}
 */
contract Vault is
    IVault,
    IVaultSponsoring,
    IVaultSettings,
    CurveSwapper,
    Context,
    ERC165,
    AccessControl,
    ReentrancyGuard,
    Pausable,
    ExitPausable,
    Ownable,
    CustomErrors
{
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;
    using PercentMath for uint256;
    using PercentMath for uint16;
    using Counters for Counters.Counter;

    //
    // Constants
    //

    /// Role allowed to invest/desinvest from strategy
    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");

    /// Role allowed to change settings such as performance fee and investment fee
    bytes32 public constant SETTINGS_ROLE = keccak256("SETTINGS_ROLE");

    /// Role for sponsors allowed to call sponsor/unsponsor
    bytes32 public constant SPONSOR_ROLE = keccak256("SPONSOR_ROLE");

    /// Minimum lock for each sponsor
    uint64 public constant MIN_SPONSOR_LOCK_DURATION = 2 weeks;

    /// Maximum lock for each sponsor
    uint64 public constant MAX_SPONSOR_LOCK_DURATION = 24 weeks;

    /// Maximum lock for each deposit
    uint64 public constant MAX_DEPOSIT_LOCK_DURATION = 24 weeks;

    /// Helper constant for computing shares without losing precision
    uint256 public constant SHARES_MULTIPLIER = 1e18;

    //
    // State
    //

    /// @inheritdoc IVault
    IERC20Metadata public override(IVault) underlying;

    /// @inheritdoc IVault
    uint16 public override(IVault) investPct;

    /// @inheritdoc IVault
    uint64 public immutable override(IVault) minLockPeriod;

    /// @inheritdoc IVaultSponsoring
    uint256 public override(IVaultSponsoring) totalSponsored;

    /// @inheritdoc IVault
    uint256 public override(IVault) totalShares;

    /// The investment strategy
    IStrategy public strategy;

    /// Unique IDs to correlate donations that belong to the same foundation
    uint256 private _depositGroupIds;
    mapping(uint256 => address) public depositGroupIdOwner;

    /// deposit ID => deposit data
    mapping(uint256 => Deposit) public deposits;

    /// Counter for deposit ids
    Counters.Counter private _depositTokenIds;

    /// claimer address => claimer data
    mapping(address => Claimer) public claimer;

    /// The total of principal deposited
    uint256 public totalPrincipal;

    /// Treasury address to collect performance fee
    address public treasury;

    /// Performance fee percentage
    uint16 public perfFeePct;

    /// Current accumulated performance fee;
    uint256 public accumulatedPerfFee;

    /// Loss tolerance pct
    uint16 public lossTolerancePct;

    /// Rebalance minimum
    uint256 private immutable rebalanceMinimum;

    /**
     * @param _underlying Underlying ERC20 token to use.
     * @param _minLockPeriod Minimum lock period to deposit
     * @param _investPct Percentage of the total underlying to invest in the strategy
     * @param _treasury Treasury address to collect performance fee
     * @param _owner Vault admin address
     * @param _perfFeePct Performance fee percentage
     * @param _lossTolerancePct Loss tolerance when investing through the strategy
     * @param _swapPools Swap pools used to automatically convert tokens to underlying
     */
    constructor(
        IERC20Metadata _underlying,
        uint64 _minLockPeriod,
        uint16 _investPct,
        address _treasury,
        address _owner,
        uint16 _perfFeePct,
        uint16 _lossTolerancePct,
        SwapPoolParam[] memory _swapPools
    ) {
        if (!_investPct.validPct()) revert VaultInvalidInvestpct();
        if (!_perfFeePct.validPct()) revert VaultInvalidPerformanceFee();
        if (!_lossTolerancePct.validPct()) revert VaultInvalidLossTolerance();
        if (address(_underlying) == address(0x0))
            revert VaultUnderlyingCannotBe0Address();
        if (_treasury == address(0x0)) revert VaultTreasuryCannotBe0Address();
        if (_owner == address(0x0)) revert VaultOwnerCannotBe0Address();
        if (_minLockPeriod == 0 || _minLockPeriod > MAX_DEPOSIT_LOCK_DURATION)
            revert VaultInvalidMinLockPeriod();

        _transferOwnership(_owner);

        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(INVESTOR_ROLE, _owner);
        _setupRole(SETTINGS_ROLE, _owner);
        _setupRole(SPONSOR_ROLE, _owner);

        investPct = _investPct;
        underlying = _underlying;
        treasury = _treasury;
        minLockPeriod = _minLockPeriod;
        perfFeePct = _perfFeePct;
        lossTolerancePct = _lossTolerancePct;

        rebalanceMinimum = 10 * 10**underlying.decimals();

        _addPools(_swapPools);

        emit TreasuryUpdated(_treasury);
    }

    //
    // Ownable
    //

    /**
     * Transfers ownership of the Vault to another account,
     * revoking all of previous owner's roles and setting them up for the new owner.
     *
     * @notice Can only be called by the current owner.
     *
     * @param _newOwner The new owner of the contract.
     */
    function transferOwnership(address _newOwner)
        public
        override(Ownable)
        onlyOwner
    {
        if (_newOwner == address(0x0)) revert VaultOwnerCannotBe0Address();
        if (_newOwner == msg.sender)
            revert VaultCannotTransferOwnershipToSelf();

        _transferOwnership(_newOwner);

        _setupRole(DEFAULT_ADMIN_ROLE, _newOwner);
        _setupRole(INVESTOR_ROLE, _newOwner);
        _setupRole(SETTINGS_ROLE, _newOwner);
        _setupRole(SPONSOR_ROLE, _newOwner);

        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _revokeRole(INVESTOR_ROLE, msg.sender);
        _revokeRole(SETTINGS_ROLE, msg.sender);
        _revokeRole(SPONSOR_ROLE, msg.sender);
    }

    //
    // IVault
    //

    /// @inheritdoc IVault
    function totalUnderlying() public view override(IVault) returns (uint256) {
        if (address(strategy) != address(0)) {
            return
                underlying.balanceOf(address(this)) + strategy.investedAssets();
        }

        return underlying.balanceOf(address(this));
    }

    /// @inheritdoc IVault
    function yieldFor(address _to)
        public
        view
        override(IVault)
        returns (
            uint256 claimableYield,
            uint256 shares,
            uint256 perfFee
        )
    {
        uint256 claimerPrincipal = claimer[_to].totalPrincipal;
        uint256 claimerShares = claimer[_to].totalShares;

        uint256 currentClaimerPrincipal = _computeAmount(
            claimerShares,
            totalShares,
            totalUnderlyingMinusSponsored()
        );

        if (currentClaimerPrincipal <= claimerPrincipal) {
            return (0, 0, 0);
        }

        uint256 yieldWithPerfFee = currentClaimerPrincipal - claimerPrincipal;

        shares = _computeShares(
            yieldWithPerfFee,
            totalShares,
            totalUnderlyingMinusSponsored()
        );
        uint256 sharesAmount = _computeAmount(
            shares,
            totalShares,
            totalUnderlyingMinusSponsored()
        );

        perfFee = sharesAmount.pctOf(perfFeePct);
        claimableYield = sharesAmount - perfFee;
    }

    /// @inheritdoc IVault
    function depositForGroupId(uint256 _groupId, DepositParams calldata _params)
        external
        nonReentrant
        whenNotPaused
        returns (uint256[] memory depositIds)
    {
        if (depositGroupIdOwner[_groupId] != msg.sender)
            revert VaultSenderNotOwnerOfGroupId();

        depositIds = _doDeposit(_groupId, _params);
    }

    /// @inheritdoc IVault
    function deposit(DepositParams calldata _params)
        external
        nonReentrant
        whenNotPaused
        returns (uint256[] memory depositIds)
    {
        uint256 depositGroupId = _depositGroupIds;
        _depositGroupIds = depositGroupId + 1;

        depositGroupIdOwner[depositGroupId] = msg.sender;
        depositIds = _doDeposit(depositGroupId, _params);
    }

    function _doDeposit(uint256 _groupId, DepositParams calldata _params)
        internal
        returns (uint256[] memory depositIds)
    {
        if (_params.amount == 0) revert VaultCannotDeposit0();
        if (
            _params.lockDuration < minLockPeriod ||
            _params.lockDuration > MAX_DEPOSIT_LOCK_DURATION
        ) revert VaultInvalidLockPeriod();
        if (bytes(_params.name).length < 3) revert VaultDepositNameTooShort();

        uint256 principalMinusStrategyFee = _applyLossTolerance(totalPrincipal);
        uint256 previousTotalUnderlying = totalUnderlyingMinusSponsored();
        if (principalMinusStrategyFee > previousTotalUnderlying)
            revert VaultCannotDepositWhenYieldNegative();

        _transferAndCheckInputToken(
            msg.sender,
            _params.inputToken,
            _params.amount
        );
        uint256 newUnderlyingAmount = _swapIntoUnderlying(
            _params.inputToken,
            _params.amount,
            _params.slippage
        );

        uint64 lockedUntil = _params.lockDuration + _blockTimestamp();

        depositIds = _createDeposit(
            previousTotalUnderlying,
            newUnderlyingAmount,
            lockedUntil,
            _params.claims,
            _params.name,
            _groupId
        );
    }

    /// @inheritdoc IVault
    function claimYield(address _to)
        external
        override(IVault)
        nonReentrant
        whenNotExitPaused
    {
        if (_to == address(0)) revert VaultDestinationCannotBe0Address();

        (uint256 yield, uint256 shares, uint256 fee) = yieldFor(msg.sender);

        if (yield == 0) revert VaultNoYieldToClaim();

        uint256 _totalUnderlyingMinusSponsored = totalUnderlyingMinusSponsored();
        uint256 _totalShares = totalShares;

        accumulatedPerfFee += fee;

        _rebalanceBeforeWithdrawing(yield);

        underlying.safeTransfer(_to, yield);

        claimer[msg.sender].totalShares -= shares;
        totalShares -= shares;

        emit YieldClaimed(
            msg.sender,
            _to,
            yield,
            shares,
            fee,
            _totalUnderlyingMinusSponsored,
            _totalShares
        );
    }

    /// @inheritdoc IVault
    function withdraw(address _to, uint256[] calldata _ids)
        external
        override(IVault)
        nonReentrant
        whenNotExitPaused
    {
        if (_to == address(0)) revert VaultDestinationCannotBe0Address();

        if (totalPrincipal > totalUnderlyingMinusSponsored())
            revert VaultCannotWithdrawWhenYieldNegative();

        _withdrawAll(_to, _ids, false);
    }

    /// @inheritdoc IVault
    function forceWithdraw(address _to, uint256[] calldata _ids)
        external
        nonReentrant
        whenNotExitPaused
    {
        if (_to == address(0)) revert VaultDestinationCannotBe0Address();

        _withdrawAll(_to, _ids, true);
    }

    function partialWithdraw(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external nonReentrant whenNotExitPaused {
        if (_to == address(0)) revert VaultDestinationCannotBe0Address();

        _withdrawPartial(_to, _ids, _amounts);
    }

    /// @inheritdoc IVault
    function investState()
        public
        view
        override(IVault)
        returns (uint256 maxInvestableAmount, uint256 alreadyInvested)
    {
        if (address(strategy) == address(0)) {
            return (0, 0);
        }

        maxInvestableAmount = totalUnderlying().pctOf(investPct);
        alreadyInvested = strategy.investedAssets();
    }

    /// @inheritdoc IVault
    function updateInvested()
        external
        override(IVault)
        onlyRole(INVESTOR_ROLE)
    {
        if (address(strategy) == address(0)) revert VaultStrategyNotSet();

        (uint256 maxInvestableAmount, uint256 alreadyInvested) = investState();

        if (maxInvestableAmount == alreadyInvested) revert VaultNothingToDo();

        // disinvest
        if (alreadyInvested > maxInvestableAmount) {
            uint256 disinvestAmount = alreadyInvested - maxInvestableAmount;

            if (disinvestAmount < rebalanceMinimum)
                revert VaultNotEnoughToRebalance();

            strategy.withdrawToVault(disinvestAmount);

            emit Disinvested(disinvestAmount);

            return;
        }

        // invest
        uint256 investAmount = maxInvestableAmount - alreadyInvested;

        if (investAmount < rebalanceMinimum) revert VaultNotEnoughToRebalance();

        underlying.safeTransfer(address(strategy), investAmount);

        strategy.invest();

        emit Invested(investAmount);
    }

    /// @inheritdoc IVault
    function withdrawPerformanceFee()
        external
        override(IVault)
        onlyRole(INVESTOR_ROLE)
    {
        uint256 _perfFee = accumulatedPerfFee;
        if (_perfFee == 0) revert VaultNoPerformanceFee();

        accumulatedPerfFee = 0;
        _rebalanceBeforeWithdrawing(_perfFee);

        emit FeeWithdrawn(_perfFee);
        underlying.safeTransfer(treasury, _perfFee);
    }

    //
    // IVaultSponsoring
    //

    /// @inheritdoc IVaultSponsoring
    function sponsor(
        address _inputToken,
        uint256 _amount,
        uint256 _lockDuration,
        uint256 _slippage
    )
        external
        override(IVaultSponsoring)
        nonReentrant
        onlyRole(SPONSOR_ROLE)
        whenNotPaused
    {
        if (_amount == 0) revert VaultCannotSponsor0();

        if (
            _lockDuration < MIN_SPONSOR_LOCK_DURATION ||
            _lockDuration > MAX_SPONSOR_LOCK_DURATION
        ) revert VaultInvalidLockPeriod();

        uint256 lockedUntil = _lockDuration + block.timestamp;
        _depositTokenIds.increment();
        uint256 tokenId = _depositTokenIds.current();

        _transferAndCheckInputToken(msg.sender, _inputToken, _amount);
        uint256 underlyingAmount = _swapIntoUnderlying(
            _inputToken,
            _amount,
            _slippage
        );

        deposits[tokenId] = Deposit(
            underlyingAmount,
            msg.sender,
            address(0),
            lockedUntil
        );
        totalSponsored += underlyingAmount;

        emit Sponsored(tokenId, underlyingAmount, msg.sender, lockedUntil);
    }

    /// @inheritdoc IVaultSponsoring
    function unsponsor(address _to, uint256[] calldata _ids)
        external
        nonReentrant
        whenNotExitPaused
    {
        if (_to == address(0)) revert VaultDestinationCannotBe0Address();

        _unsponsor(_to, _ids);
    }

    //
    // CurveSwapper
    //

    /// @inheritdoc CurveSwapper
    function getUnderlying()
        public
        view
        override(CurveSwapper)
        returns (address)
    {
        return address(underlying);
    }

    /// Adds a new curve swap pool from an input token to {underlying}
    ///
    /// @param _param Swap pool params
    function addPool(SwapPoolParam memory _param)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _addPool(_param);
    }

    /// Removes an existing swap pool, and the ability to deposit the given token as underlying
    ///
    /// @param _inputToken the token to remove
    function removePool(address _inputToken)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _removePool(_inputToken);
    }

    //
    // Admin functions
    //

    /// @inheritdoc IVaultSettings
    function setInvestPct(uint16 _investPct)
        external
        override(IVaultSettings)
        onlyRole(SETTINGS_ROLE)
    {
        if (!PercentMath.validPct(_investPct)) revert VaultInvalidInvestpct();

        emit InvestPctUpdated(_investPct);

        investPct = _investPct;
    }

    /// @inheritdoc IVaultSettings
    function setTreasury(address _treasury)
        external
        override(IVaultSettings)
        onlyRole(SETTINGS_ROLE)
    {
        if (address(_treasury) == address(0x0))
            revert VaultTreasuryCannotBe0Address();
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    /// @inheritdoc IVaultSettings
    function setPerfFeePct(uint16 _perfFeePct)
        external
        override(IVaultSettings)
        onlyRole(SETTINGS_ROLE)
    {
        if (!PercentMath.validPct(_perfFeePct))
            revert VaultInvalidPerformanceFee();
        perfFeePct = _perfFeePct;
        emit PerfFeePctUpdated(_perfFeePct);
    }

    /// @inheritdoc IVaultSettings
    function setStrategy(address _strategy)
        external
        override(IVaultSettings)
        onlyRole(SETTINGS_ROLE)
    {
        if (_strategy == address(0)) revert VaultStrategyNotSet();
        if (IStrategy(_strategy).vault() != address(this))
            revert VaultInvalidVault();
        if (address(strategy) != address(0) && strategy.hasAssets())
            revert VaultStrategyHasInvestedFunds();

        strategy = IStrategy(_strategy);

        emit StrategyUpdated(_strategy);
    }

    /// @inheritdoc IVaultSettings
    function setLossTolerancePct(uint16 pct)
        external
        override(IVaultSettings)
        onlyRole(SETTINGS_ROLE)
    {
        if (!pct.validPct()) revert VaultInvalidLossTolerance();

        lossTolerancePct = pct;
        emit LossTolerancePctUpdated(pct);
    }

    //
    // Public API
    //

    /**
     * Computes the total amount of principal + yield currently controlled by the
     * vault and the strategy. The principal + yield is the total amount
     * of underlying that can be claimed or withdrawn, excluding the sponsored amount and performance fee.
     *
     * @return Total amount of principal and yield help by the vault (not including sponsored amount and performance fee).
     */
    function totalUnderlyingMinusSponsored() public view returns (uint256) {
        uint256 _totalUnderlying = totalUnderlying();
        uint256 deductAmount = totalSponsored + accumulatedPerfFee;
        if (deductAmount > _totalUnderlying) {
            return 0;
        }

        return _totalUnderlying - deductAmount;
    }

    //
    // ERC165
    //

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IVault).interfaceId ||
            interfaceId == type(IVaultSponsoring).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    //
    // Internal API
    //

    /**
     * Withdraws the principal from the deposits with the ids provided in @param _ids and sends it to @param _to.
     *
     * @notice the NFTs of the deposits will be burned.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     * @param _force Boolean to specify if the action should be perfomed when there's loss.
     */
    function _withdrawAll(
        address _to,
        uint256[] calldata _ids,
        bool _force
    ) internal {
        uint256 localTotalShares = totalShares;
        uint256 localTotalPrincipal = totalUnderlyingMinusSponsored();
        uint256 amount;
        uint256 idsLen = _ids.length;

        for (uint256 i = 0; i < idsLen; ++i) {
            uint256 depositAmount = deposits[_ids[i]].amount;

            amount += _withdrawSingle(
                _ids[i],
                localTotalShares,
                localTotalPrincipal,
                _to,
                _force,
                depositAmount
            );
        }

        _rebalanceBeforeWithdrawing(amount);

        underlying.safeTransfer(_to, amount);
    }

    function _withdrawPartial(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) internal {
        uint256 localTotalShares = totalShares;
        uint256 localTotalPrincipal = totalUnderlyingMinusSponsored();
        uint256 amount;
        uint256 idsLen = _ids.length;

        for (uint256 i = 0; i < idsLen; ++i) {
            amount += _withdrawSingle(
                _ids[i],
                localTotalShares,
                localTotalPrincipal,
                _to,
                false,
                _amounts[i]
            );
        }

        _rebalanceBeforeWithdrawing(amount);

        underlying.safeTransfer(_to, amount);
    }

    /**
     * Rebalances the vault's funds to cover the transfer of funds from the vault
     * by disinvesting from the strategy. After the rebalance the vault is left
     * with a set percentage (100% - invest%) of the total underlying as reserves.
     *
     * @notice this will have effect only for sync strategies.
     *
     * @param _amount Funds to be transferred from the vault.
     */
    function _rebalanceBeforeWithdrawing(uint256 _amount) internal {
        uint256 vaultBalance = underlying.balanceOf(address(this));

        if (_amount <= vaultBalance) return;
        if (!strategy.isSync()) revert VaultNotEnoughFunds();

        uint256 expectedReserves = (totalUnderlying() - _amount).pctOf(
            10000 - investPct
        );

        // we want to withdraw the from the strategy only what is needed
        // to cover the transfer and leave the vault with the expected reserves
        uint256 needed = _amount + expectedReserves - vaultBalance;

        strategy.withdrawToVault(needed);

        emit Disinvested(needed);
    }

    /**
     * Withdraws the sponsored amount for the deposits with the ids provided
     * in @param _ids and sends it to @param _to.
     *
     * @notice the NFTs of the deposits will be burned.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     */
    function _unsponsor(address _to, uint256[] calldata _ids) internal {
        uint256 sponsorAmount;
        uint256 idsLen = _ids.length;

        for (uint8 i; i < idsLen; ++i) {
            uint256 tokenId = _ids[i];

            Deposit memory _deposit = deposits[tokenId];
            uint256 lockedUntil = _deposit.lockedUntil;
            address claimerId = _deposit.claimerId;

            address owner = _deposit.owner;
            uint256 amount = _deposit.amount;

            if (owner != msg.sender) revert VaultNotAllowed();
            if (lockedUntil > block.timestamp) revert VaultAmountLocked();
            if (claimerId != address(0)) revert VaultNotSponsor();

            sponsorAmount += amount;

            delete deposits[tokenId];

            emit Unsponsored(tokenId);
        }

        if (sponsorAmount > totalUnderlying()) revert VaultNotEnoughFunds();

        totalSponsored -= sponsorAmount;

        _rebalanceBeforeWithdrawing(sponsorAmount);

        underlying.safeTransfer(_to, sponsorAmount);
    }

    /**
     * @dev `_createDeposit` declares too many locals
     * We move some of them to this struct to fix the problem
     */
    struct CreateDepositLocals {
        uint256 totalShares;
        uint256 totalUnderlying;
        uint16 accumulatedPct;
        uint256 accumulatedAmount;
        uint256 claimsLen;
    }

    /**
     * Creates a deposit with the given amount of underlying and claim
     * structure. The deposit is locked until the timestamp specified in @param _lockedUntil.
     * @notice This function assumes underlying will be transfered elsewhere in
     * the transaction.
     *
     * @notice Underlying must be transfered *after* this function, in order to
     * correctly calculate shares.
     *
     * @notice claims must add up to 100%.
     *
     * @param _amount Amount of underlying to consider @param claims claim
     * @param _lockedUntil Timestamp at which the deposit unlocks
     * @param claims Claim params
     * params.
     */
    function _createDeposit(
        uint256 _previousTotalUnderlying,
        uint256 _amount,
        uint64 _lockedUntil,
        ClaimParams[] calldata claims,
        string calldata _name,
        uint256 _groupId
    ) internal returns (uint256[] memory) {
        CreateDepositLocals memory locals = CreateDepositLocals({
            totalShares: totalShares,
            totalUnderlying: _previousTotalUnderlying,
            accumulatedPct: 0,
            accumulatedAmount: 0,
            claimsLen: claims.length
        });

        uint256[] memory result = new uint256[](locals.claimsLen);

        for (uint256 i = 0; i < locals.claimsLen; ++i) {
            ClaimParams memory data = claims[i];
            if (data.pct == 0) revert VaultClaimPercentageCannotBe0();
            if (data.beneficiary == address(0)) revert VaultClaimerCannotBe0();
            // if it's the last claim, just grab all remaining amount, instead
            // of relying on percentages
            uint256 localAmount = i == locals.claimsLen - 1
                ? _amount - locals.accumulatedAmount
                : _amount.pctOf(data.pct);

            result[i] = _createClaim(
                _groupId,
                localAmount,
                _lockedUntil,
                data,
                locals.totalShares,
                locals.totalUnderlying,
                _name
            );
            locals.accumulatedPct += data.pct;
            locals.accumulatedAmount += localAmount;
        }

        if (!locals.accumulatedPct.is100Pct()) revert VaultClaimsDontAddUp();

        return result;
    }

    /**
     * @dev `_createClaim` declares too many locals
     * We move some of them to this struct to fix the problem
     */
    struct CreateClaimLocals {
        uint256 newShares;
        address claimerId;
        uint256 tokenId;
    }

    function _createClaim(
        uint256 _depositGroupId,
        uint256 _amount,
        uint64 _lockedUntil,
        ClaimParams memory _claim,
        uint256 _localTotalShares,
        uint256 _localTotalPrincipal,
        string calldata _name
    ) internal returns (uint256) {
        _depositTokenIds.increment();
        CreateClaimLocals memory locals = CreateClaimLocals({
            newShares: _computeShares(
                _amount,
                _localTotalShares,
                _localTotalPrincipal
            ),
            claimerId: _claim.beneficiary,
            tokenId: _depositTokenIds.current()
        });

        // Checks if the user is not already in debt
        if (
            _computeShares(
                _applyLossTolerance(claimer[locals.claimerId].totalPrincipal),
                _localTotalShares,
                _localTotalPrincipal
            ) > claimer[locals.claimerId].totalShares
        ) revert VaultCannotDepositWhenClaimerInDebt();

        claimer[locals.claimerId].totalShares += locals.newShares;
        claimer[locals.claimerId].totalPrincipal += _amount;

        totalShares += locals.newShares;
        totalPrincipal += _amount;

        deposits[locals.tokenId] = Deposit(
            _amount,
            msg.sender,
            locals.claimerId,
            _lockedUntil
        );

        emit DepositMinted(
            locals.tokenId,
            _depositGroupId,
            _amount,
            locals.newShares,
            msg.sender,
            _claim.beneficiary,
            locals.claimerId,
            _lockedUntil,
            _claim.data,
            _name
        );

        return locals.tokenId;
    }

    /**
     * Burns a deposit NFT and reduces the principal and shares of the claimer.
     * If there were any yield to be claimed, the claimer will also keep shares to withdraw later on.
     *
     * @notice This function doesn't transfer any funds, it only updates the state.
     *
     * @notice Only the owner of the deposit may call this function.
     *
     * @param _tokenId The deposit ID to withdraw from.
     * @param _totalShares The total shares to consider for the withdraw.
     * @param _totalUnderlyingMinusSponsored The total underlying to consider for the withdraw.
     * @param _to Where the funds will be sent
     * @param _force If the withdraw should still withdraw if there are not enough funds in the vault.
     *
     * @return the amount to withdraw.
     */
    function _withdrawSingle(
        uint256 _tokenId,
        uint256 _totalShares,
        uint256 _totalUnderlyingMinusSponsored,
        address _to,
        bool _force,
        uint256 _amount
    ) internal returns (uint256) {
        if (deposits[_tokenId].owner != msg.sender)
            revert VaultNotOwnerOfDeposit();

        // memoizing saves warm sloads
        Deposit memory _deposit = deposits[_tokenId];
        Claimer memory _claim = claimer[_deposit.claimerId];

        if (_deposit.lockedUntil > block.timestamp) revert VaultDepositLocked();
        if (_deposit.claimerId == address(0)) revert VaultNotDeposit();
        if (_deposit.amount < _amount)
            revert VaultCannotWithdrawMoreThanAvailable();

        // Amount of shares the _amount is worth
        uint256 amountShares = _computeShares(
            _amount,
            _totalShares,
            _totalUnderlyingMinusSponsored
        );

        // Amount of shares the _amount is worth taking in the claimer's
        // totalShares and totalPrincipal
        uint256 claimerShares = (_amount * _claim.totalShares) /
            _claim.totalPrincipal;

        if (!_force && amountShares > claimerShares)
            revert VaultCannotWithdrawMoreThanAvailable();

        uint256 sharesToBurn = amountShares;

        if (_force && amountShares > claimerShares)
            sharesToBurn = claimerShares;

        claimer[_deposit.claimerId].totalShares -= sharesToBurn;
        claimer[_deposit.claimerId].totalPrincipal -= _amount;

        totalShares -= sharesToBurn;
        totalPrincipal -= _amount;

        bool isFull = _deposit.amount == _amount;

        if (isFull) {
            delete deposits[_tokenId];
        } else {
            deposits[_tokenId].amount -= _amount;
        }

        uint256 amount = _computeAmount(
            sharesToBurn,
            _totalShares,
            _totalUnderlyingMinusSponsored
        );

        emit DepositWithdrawn(_tokenId, sharesToBurn, amount, _to, isFull);

        return amount;
    }

    function _transferAndCheckInputToken(
        address _from,
        address _token,
        uint256 _amount
    ) internal {
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));

        if (balanceAfter != balanceBefore + _amount)
            revert VaultAmountDoesNotMatchParams();
    }

    function _blockTimestamp() internal view returns (uint64) {
        return uint64(block.timestamp);
    }

    /**
     * Computes amount of shares that will be received for a given deposit amount
     *
     * @param _amount Amount of deposit to consider.
     * @param _totalShares Amount of existing shares to consider.
     * @param _totalUnderlyingMinusSponsored Amount of existing underlying to consider.
     * @return Amount of shares the deposit will receive.
     */
    function _computeShares(
        uint256 _amount,
        uint256 _totalShares,
        uint256 _totalUnderlyingMinusSponsored
    ) internal pure returns (uint256) {
        if (_amount == 0) return 0;
        if (_totalShares == 0) return _amount * SHARES_MULTIPLIER;
        if (_totalUnderlyingMinusSponsored == 0)
            revert VaultCannotComputeSharesWithoutPrincipal();

        return (_amount * _totalShares) / _totalUnderlyingMinusSponsored;
    }

    /**
     * Computes the amount of underlying from a given number of shares
     *
     * @param _shares Number of shares.
     * @param _totalShares Amount of existing shares to consider.
     * @param _totalUnderlyingMinusSponsored Amounf of existing underlying to consider.
     * @return Amount that corresponds to the number of shares.
     */
    function _computeAmount(
        uint256 _shares,
        uint256 _totalShares,
        uint256 _totalUnderlyingMinusSponsored
    ) internal pure returns (uint256) {
        if (
            _shares == 0 ||
            _totalShares == 0 ||
            _totalUnderlyingMinusSponsored == 0
        ) {
            return 0;
        }

        return ((_totalUnderlyingMinusSponsored * _shares) / _totalShares);
    }

    /**
     * Applies a loss tolerance to the given @param _amount.
     *
     * This function is used to prevent the vault from entering loss mode when funds are lost due to fees in the strategy.
     * For instance, the fees taken by Anchor.
     *
     * @param _amount Amount to apply the fees to.
     *
     * @return Amount with the fees applied.
     */
    function _applyLossTolerance(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        return _amount - _amount.pctOf(lossTolerancePct);
    }

    function sharesOf(address claimerId) external view returns (uint256) {
        return claimer[claimerId].totalShares;
    }

    function principalOf(address claimerId) external view returns (uint256) {
        return claimer[claimerId].totalPrincipal;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function exitPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _exitPause();
    }

    function exitUnpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _exitUnpause();
    }
}