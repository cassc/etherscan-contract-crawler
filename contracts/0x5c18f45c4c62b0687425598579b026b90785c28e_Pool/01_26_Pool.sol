// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "./storage/PoolStorage.sol";
import "./lib/WadRayMath.sol";
import "./utils/Pauseable.sol";

error CollateralDoesNotExist();
error SyntheticDoesNotExist();
error SenderIsNotDebtToken();
error SenderIsNotDepositToken();
error UserReachedMaxTokens();
error PoolRegistryIsNull();
error DebtTokenAlreadyExists();
error DepositTokenAlreadyExists();
error FlashRepaySlippageTooHigh();
error LeverageTooLow();
error LeverageTooHigh();
error LeverageSlippageTooHigh();
error PositionIsNotHealthy();
error AmountIsZero();
error CanNotLiquidateOwnPosition();
error PositionIsHealthy();
error AmountGreaterThanMaxLiquidable();
error RemainingDebtIsLowerThanTheFloor();
error AmountIsTooHigh();
error DebtTokenDoesNotExist();
error DepositTokenDoesNotExist();
error SwapFeatureIsInactive();
error AmountInIsInvalid();
error AddressIsNull();
error SyntheticIsNull();
error SyntheticIsInUse();
error UnderlyingAssetInUse();
error ReachedMaxDepositTokens();
error RewardDistributorAlreadyExists();
error RewardDistributorDoesNotExist();
error TotalSupplyIsNotZero();
error NewValueIsSameAsCurrent();
error FeeIsGreaterThanTheMax();
error MaxLiquidableTooHigh();

/**
 * @title Pool contract
 */
contract Pool is ReentrancyGuard, Pauseable, PoolStorageV2 {
    using SafeERC20 for IERC20;
    using SafeERC20 for ISyntheticToken;
    using WadRayMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using MappedEnumerableSet for MappedEnumerableSet.AddressSet;

    string public constant VERSION = "1.2.0";

    /**
     * @notice Maximum tokens per pool a user may have
     */
    uint256 public constant MAX_TOKENS_PER_USER = 30;

    /// @notice Emitted when protocol liquidation fee is updated
    event DebtFloorUpdated(uint256 oldDebtFloorInUsd, uint256 newDebtFloorInUsd);

    /// @notice Emitted when debt token is enabled
    event DebtTokenAdded(IDebtToken indexed debtToken);

    /// @notice Emitted when debt token is disabled
    event DebtTokenRemoved(IDebtToken indexed debtToken);

    /// @notice Emitted when deposit token is enabled
    event DepositTokenAdded(address indexed depositToken);

    /// @notice Emitted when deposit token is disabled
    event DepositTokenRemoved(IDepositToken indexed depositToken);

    /// @notice Emitted when fee provider contract is updated
    event FeeProviderUpdated(IFeeProvider indexed oldFeeProvider, IFeeProvider indexed newFeeProvider);

    /// @notice Emitted when maxLiquidable (liquidation cap) is updated
    event MaxLiquidableUpdated(uint256 oldMaxLiquidable, uint256 newMaxLiquidable);

    /// @notice Emitted when a position is liquidated
    event PositionLiquidated(
        address indexed liquidator,
        address indexed account,
        ISyntheticToken indexed syntheticToken,
        uint256 amountRepaid,
        uint256 depositSeized,
        uint256 fee
    );

    /// @notice Emitted when rewards distributor contract is added
    event RewardsDistributorAdded(IRewardsDistributor indexed _distributor);

    /// @notice Emitted when rewards distributor contract is removed
    event RewardsDistributorRemoved(IRewardsDistributor _distributor);

    /// @notice Emitted when the swap active flag is updated
    event SwapActiveUpdated(bool newActive);

    /// @notice Emitted when swapper contract is updated
    event SwapperUpdated(ISwapper oldSwapFee, ISwapper newSwapFee);

    /// @notice Emitted when synthetic token is swapped
    event SyntheticTokenSwapped(
        address indexed account,
        ISyntheticToken indexed syntheticTokenIn,
        ISyntheticToken indexed syntheticTokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee
    );

    /// @notice Emitted when treasury contract is updated
    event TreasuryUpdated(ITreasury indexed oldTreasury, ITreasury indexed newTreasury);

    /**
     * @dev Throws if token addition will reach the `account_`'s max
     */
    modifier onlyIfAdditionWillNotReachMaxTokens(address account_) {
        if (debtTokensOfAccount.length(account_) + depositTokensOfAccount.length(account_) >= MAX_TOKENS_PER_USER) {
            revert UserReachedMaxTokens();
        }
        _;
    }

    /**
     * @dev Throws if deposit token doesn't exist
     */
    modifier onlyIfDepositTokenExists(IDepositToken depositToken_) {
        if (!doesDepositTokenExist(depositToken_)) revert CollateralDoesNotExist();
        _;
    }

    /**
     * @dev Throws if synthetic token doesn't exist
     */
    modifier onlyIfSyntheticTokenExists(ISyntheticToken syntheticToken_) {
        if (!doesSyntheticTokenExist(syntheticToken_)) revert SyntheticDoesNotExist();
        _;
    }

    /**
     * @dev Throws if `msg.sender` isn't a debt token
     */
    modifier onlyIfMsgSenderIsDebtToken() {
        if (!doesDebtTokenExist(IDebtToken(msg.sender))) revert SenderIsNotDebtToken();
        _;
    }

    /**
     * @dev Throws if `msg.sender` isn't a deposit token
     */
    modifier onlyIfMsgSenderIsDepositToken() {
        if (!doesDepositTokenExist(IDepositToken(msg.sender))) revert SenderIsNotDepositToken();
        _;
    }

    function initialize(IPoolRegistry poolRegistry_) public initializer {
        if (address(poolRegistry_) == address(0)) revert PoolRegistryIsNull();
        __ReentrancyGuard_init();
        __Pauseable_init();

        poolRegistry = poolRegistry_;
        isSwapActive = true;
        maxLiquidable = 0.5e18; // 50%
    }

    /**
     * @notice Add a debt token to the per-account list
     * @dev This function is called from `DebtToken` when user's balance changes from `0`
     * @dev The caller should ensure to not pass `address(0)` as `_account`
     * @param account_ The account address
     */
    function addToDebtTokensOfAccount(
        address account_
    ) external onlyIfMsgSenderIsDebtToken onlyIfAdditionWillNotReachMaxTokens(account_) {
        if (!debtTokensOfAccount.add(account_, msg.sender)) revert DebtTokenAlreadyExists();
    }

    /**
     * @notice Add a deposit token to the per-account list
     * @dev This function is called from `DepositToken` when user's balance changes from `0`
     * @dev The caller should ensure to not pass `address(0)` as `_account`
     * @param account_ The account address
     */
    function addToDepositTokensOfAccount(
        address account_
    ) external onlyIfMsgSenderIsDepositToken onlyIfAdditionWillNotReachMaxTokens(account_) {
        if (!depositTokensOfAccount.add(account_, msg.sender)) revert DepositTokenAlreadyExists();
    }

    /**
     * @notice Get account's debt by querying latest prices from oracles
     * @param account_ The account to check
     * @return _debtInUsd The debt value in USD
     */
    function debtOf(address account_) public view override returns (uint256 _debtInUsd) {
        IMasterOracle _masterOracle = masterOracle();
        uint256 _length = debtTokensOfAccount.length(account_);
        for (uint256 i; i < _length; ++i) {
            IDebtToken _debtToken = IDebtToken(debtTokensOfAccount.at(account_, i));
            _debtInUsd += _masterOracle.quoteTokenToUsd(
                address(_debtToken.syntheticToken()),
                _debtToken.balanceOf(account_)
            );
        }
    }

    /**
     * @notice Flash debt repayment
     * @param syntheticToken_ The debt token to repay
     * @param depositToken_ The collateral to withdraw
     * @param withdrawAmount_ The amount to withdraw
     * @param repayAmountMin_ The minimum amount to repay (slippage check)
     */
    function flashRepay(
        ISyntheticToken syntheticToken_,
        IDepositToken depositToken_,
        uint256 withdrawAmount_,
        uint256 repayAmountMin_
    )
        external
        override
        whenNotShutdown
        nonReentrant
        onlyIfDepositTokenExists(depositToken_)
        onlyIfSyntheticTokenExists(syntheticToken_)
        returns (uint256 _withdrawn, uint256 _repaid)
    {
        if (withdrawAmount_ > depositToken_.balanceOf(msg.sender)) revert AmountIsTooHigh();
        IDebtToken _debtToken = debtTokenOf[syntheticToken_];
        if (repayAmountMin_ > _debtToken.balanceOf(msg.sender)) revert AmountIsTooHigh();

        // 1. withdraw collateral
        (_withdrawn, ) = depositToken_.flashWithdraw(msg.sender, withdrawAmount_);

        // 2. swap for synth
        uint256 _amountToRepay = _swap(swapper, depositToken_.underlying(), syntheticToken_, _withdrawn, 0);

        // 3. repay debt
        (_repaid, ) = _debtToken.repay(msg.sender, _amountToRepay);
        if (_repaid < repayAmountMin_) revert FlashRepaySlippageTooHigh();

        // 4. check the health of the outcome position
        (bool _isHealthy, , , , ) = debtPositionOf(msg.sender);
        if (!_isHealthy) revert PositionIsNotHealthy();
    }

    /**
     * @notice Returns whether the debt position from an account is healthy
     * @param account_ The account to check
     * @return _isHealthy Whether the account's position is healthy
     * @return _depositInUsd The total collateral deposited in USD
     * @return _debtInUsd The total debt in USD
     * @return _issuableLimitInUsd The max amount of debt (is USD) that can be created (considering collateral factors)
     * @return _issuableInUsd The amount of debt (is USD) that is free (i.e. can be used to issue synthetic tokens)
     */
    function debtPositionOf(
        address account_
    )
        public
        view
        override
        returns (
            bool _isHealthy,
            uint256 _depositInUsd,
            uint256 _debtInUsd,
            uint256 _issuableLimitInUsd,
            uint256 _issuableInUsd
        )
    {
        _debtInUsd = debtOf(account_);
        (_depositInUsd, _issuableLimitInUsd) = depositOf(account_);
        _isHealthy = _debtInUsd <= _issuableLimitInUsd;
        _issuableInUsd = _debtInUsd < _issuableLimitInUsd ? _issuableLimitInUsd - _debtInUsd : 0;
    }

    /**
     * @notice Get account's total collateral deposited by querying latest prices from oracles
     * @param account_ The account to check
     * @return _depositInUsd The total deposit value in USD among all collaterals
     * @return _issuableLimitInUsd The max value in USD that can be used to issue synthetic tokens
     */
    function depositOf(
        address account_
    ) public view override returns (uint256 _depositInUsd, uint256 _issuableLimitInUsd) {
        IMasterOracle _masterOracle = masterOracle();
        uint256 _length = depositTokensOfAccount.length(account_);
        for (uint256 i; i < _length; ++i) {
            IDepositToken _depositToken = IDepositToken(depositTokensOfAccount.at(account_, i));
            uint256 _amountInUsd = _masterOracle.quoteTokenToUsd(
                address(_depositToken.underlying()),
                _depositToken.balanceOf(account_)
            );
            _depositInUsd += _amountInUsd;
            _issuableLimitInUsd += _amountInUsd.wadMul(_depositToken.collateralFactor());
        }
    }

    /**
     * @inheritdoc Pauseable
     */
    function everythingStopped() public view override(IPauseable, Pauseable) returns (bool) {
        return super.everythingStopped() || poolRegistry.everythingStopped();
    }

    /**
     * @notice Returns fee collector address
     */
    function feeCollector() external view override returns (address) {
        return poolRegistry.feeCollector();
    }

    /**
     * @notice Get all debt tokens
     * @dev WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees.
     */
    function getDebtTokens() external view override returns (address[] memory) {
        return debtTokens.values();
    }

    /**
     * @notice Get all debt tokens
     * @dev WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees.
     */
    function getDebtTokensOfAccount(address account_) external view override returns (address[] memory) {
        return debtTokensOfAccount.values(account_);
    }

    /**
     * @notice Get all deposit tokens
     * @dev WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees.
     */
    function getDepositTokens() external view override returns (address[] memory) {
        return depositTokens.values();
    }

    /**
     * @notice Get deposit tokens of an account
     * @dev WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees.
     */
    function getDepositTokensOfAccount(address account_) external view override returns (address[] memory) {
        return depositTokensOfAccount.values(account_);
    }

    /**
     * @notice Get all rewards distributors
     */
    function getRewardsDistributors() external view override returns (address[] memory) {
        return rewardsDistributors.values();
    }

    /**
     * @notice Check if token is part of the debt offerings
     * @param debtToken_ Asset to check
     * @return true if exist
     */
    function doesDebtTokenExist(IDebtToken debtToken_) public view override returns (bool) {
        return debtTokens.contains(address(debtToken_));
    }

    /**
     * @notice Check if collateral is supported
     * @param depositToken_ Asset to check
     * @return true if exist
     */
    function doesDepositTokenExist(IDepositToken depositToken_) public view override returns (bool) {
        return depositTokens.contains(address(depositToken_));
    }

    /**
     * @notice Check if token is part of the synthetic offerings
     * @param syntheticToken_ Asset to check
     * @return true if exist
     */
    function doesSyntheticTokenExist(ISyntheticToken syntheticToken_) public view override returns (bool) {
        return address(debtTokenOf[syntheticToken_]) != address(0);
    }

    /**
     * @notice Quote synth  `_amountToRepay` in order to seize `totalToSeized_`
     * @param syntheticToken_ Synth for repayment
     * @param totalToSeize_ Collateral total amount to size
     * @param depositToken_ Collateral's deposit token
     * @return _amountToRepay Synth amount to burn
     * @return _toLiquidator Seized amount to the liquidator
     * @return _fee The fee amount to collect
     */
    function quoteLiquidateIn(
        ISyntheticToken syntheticToken_,
        uint256 totalToSeize_,
        IDepositToken depositToken_
    ) public view override returns (uint256 _amountToRepay, uint256 _toLiquidator, uint256 _fee) {
        (uint128 _liquidatorIncentive, uint128 _protocolFee) = feeProvider.liquidationFees();
        uint256 _totalFees = _protocolFee + _liquidatorIncentive;
        uint256 _repayAmountInCollateral = totalToSeize_;

        if (_totalFees > 0) {
            _repayAmountInCollateral = _repayAmountInCollateral.wadDiv(1e18 + _totalFees);
        }

        _amountToRepay = masterOracle().quote(
            address(depositToken_.underlying()),
            address(syntheticToken_),
            _repayAmountInCollateral
        );

        if (_protocolFee > 0) {
            _fee = _repayAmountInCollateral.wadMul(_protocolFee);
        }

        if (_liquidatorIncentive > 0) {
            _toLiquidator = _repayAmountInCollateral.wadMul(1e18 + _liquidatorIncentive);
        }
    }

    /**
     * @notice Quote max allowed synth to repay
     * @dev I.e. Considers the min amount between collateral's balance and `maxLiquidable` param
     * @param syntheticToken_ Synth for repayment
     * @param account_ The account to liquidate
     * @param depositToken_ Collateral's deposit token
     * @return _maxAmountToRepay Synth amount to burn
     */
    function quoteLiquidateMax(
        ISyntheticToken syntheticToken_,
        address account_,
        IDepositToken depositToken_
    ) external view override returns (uint256 _maxAmountToRepay) {
        (bool _isHealthy, , , , ) = debtPositionOf(account_);
        if (_isHealthy) {
            return 0;
        }

        (uint256 _amountToRepay, , ) = quoteLiquidateIn(
            syntheticToken_,
            depositToken_.balanceOf(account_),
            depositToken_
        );

        _maxAmountToRepay = debtTokenOf[syntheticToken_].balanceOf(account_).wadMul(maxLiquidable);

        if (_amountToRepay < _maxAmountToRepay) {
            _maxAmountToRepay = _amountToRepay;
        }
    }

    /**
     * @notice Quote collateral  `totalToSeized_` by repaying `amountToRepay_`
     * @param syntheticToken_ Synth for repayment
     * @param amountToRepay_ Synth amount to burn
     * @param depositToken_ Collateral's deposit token
     * @return _totalToSeize Collateral total amount to size
     * @return _toLiquidator Seized amount to the liquidator
     * @return _fee The fee amount to collect
     */
    function quoteLiquidateOut(
        ISyntheticToken syntheticToken_,
        uint256 amountToRepay_,
        IDepositToken depositToken_
    ) public view override returns (uint256 _totalToSeize, uint256 _toLiquidator, uint256 _fee) {
        _toLiquidator = masterOracle().quote(
            address(syntheticToken_),
            address(depositToken_.underlying()),
            amountToRepay_
        );

        (uint128 _liquidatorIncentive, uint128 _protocolFee) = feeProvider.liquidationFees();

        if (_protocolFee > 0) {
            _fee = _toLiquidator.wadMul(_protocolFee);
        }
        if (_liquidatorIncentive > 0) {
            _toLiquidator += _toLiquidator.wadMul(_liquidatorIncentive);
        }

        _totalToSeize = _fee + _toLiquidator;
    }

    /**
     * @notice Quote `_amountIn` to get `amountOut_`
     * @param syntheticTokenIn_ Synth in
     * @param syntheticTokenOut_ Synth out
     * @param amountOut_ Amount out
     * @return _amountIn Amount in
     * @return _fee Fee to charge in `syntheticTokenOut_`
     */
    function quoteSwapIn(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountOut_
    ) external view override returns (uint256 _amountIn, uint256 _fee) {
        uint256 _swapFee = feeProvider.swapFeeFor(msg.sender);
        if (_swapFee > 0) {
            amountOut_ = amountOut_.wadDiv(1e18 - _swapFee);
            _fee = amountOut_.wadMul(_swapFee);
        }

        _amountIn = poolRegistry.masterOracle().quote(
            address(syntheticTokenOut_),
            address(syntheticTokenIn_),
            amountOut_
        );
    }

    /**
     * @notice Quote `amountOut_` get from `amountIn_`
     * @param syntheticTokenIn_ Synth in
     * @param syntheticTokenOut_ Synth out
     * @param amountIn_ Amount in
     * @return _amountOut Amount out
     * @return _fee Fee to charge in `syntheticTokenOut_`
     */
    function quoteSwapOut(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountIn_
    ) public view override returns (uint256 _amountOut, uint256 _fee) {
        _amountOut = poolRegistry.masterOracle().quote(
            address(syntheticTokenIn_),
            address(syntheticTokenOut_),
            amountIn_
        );

        uint256 _swapFee = feeProvider.swapFeeFor(msg.sender);
        if (_swapFee > 0) {
            _fee = _amountOut.wadMul(_swapFee);
            _amountOut -= _fee;
        }
    }

    /**
     * @notice Leverage yield position
     * @param tokenIn_ The token to transfer
     * @param depositToken_ The collateral to deposit
     * @param syntheticToken_ The msAsset to mint
     * @param amountIn_ The amount to deposit
     * @param leverage_ The leverage X param (e.g. 1.5e18 for 1.5X)
     * @param depositAmountMin_ The min final deposit amount (slippage)
     */
    function leverage(
        IERC20 tokenIn_,
        IDepositToken depositToken_,
        ISyntheticToken syntheticToken_,
        uint256 amountIn_,
        uint256 leverage_,
        uint256 depositAmountMin_
    )
        external
        override
        whenNotShutdown
        nonReentrant
        onlyIfDepositTokenExists(depositToken_)
        onlyIfSyntheticTokenExists(syntheticToken_)
        returns (uint256 _deposited, uint256 _issued)
    {
        if (leverage_ <= 1e18) revert LeverageTooLow();
        if (leverage_ > uint256(1e18).wadDiv(1e18 - depositToken_.collateralFactor())) revert LeverageTooHigh();
        ISwapper _swapper = swapper;

        // 1. transfer collateral
        IERC20 _collateral = depositToken_.underlying();
        if (address(tokenIn_) == address(0)) tokenIn_ = _collateral;
        tokenIn_.safeTransferFrom(msg.sender, address(this), amountIn_);
        if (tokenIn_ != _collateral) {
            amountIn_ = _swap(_swapper, tokenIn_, _collateral, amountIn_, 0);
        }

        // 2. mint synth
        uint256 _debtAmount = masterOracle().quote(
            address(_collateral),
            address(syntheticToken_),
            (leverage_ - 1e18).wadMul(amountIn_)
        );
        (_issued, ) = debtTokenOf[syntheticToken_].flashIssue(msg.sender, _debtAmount);

        // 3. swap synth for collateral
        uint256 _depositAmount = amountIn_ + _swap(_swapper, syntheticToken_, _collateral, _issued, 0);
        if (_depositAmount < depositAmountMin_) revert LeverageSlippageTooHigh();

        // 4. deposit collateral
        _collateral.safeApprove(address(depositToken_), 0);
        _collateral.safeApprove(address(depositToken_), _depositAmount);
        (_deposited, ) = depositToken_.deposit(_depositAmount, msg.sender);

        // 5. check the health of the outcome position
        (bool _isHealthy, , , , ) = debtPositionOf(msg.sender);
        if (!_isHealthy) revert PositionIsNotHealthy();
    }

    /**
     * @notice Burn synthetic token, unlock deposit token and send liquidator incentive
     * @param syntheticToken_ The msAsset to use for repayment
     * @param account_ The account with an unhealthy position
     * @param amountToRepay_ The amount to repay in synthetic token
     * @param depositToken_ The collateral to seize from
     * @return _totalSeized Total deposit amount seized from the liquidated account
     * @return _toLiquidator Share of `_totalSeized` sent to the liquidator
     * @return _fee Share of `_totalSeized` collected as fee
     */
    function liquidate(
        ISyntheticToken syntheticToken_,
        address account_,
        uint256 amountToRepay_,
        IDepositToken depositToken_
    )
        external
        override
        whenNotShutdown
        nonReentrant
        onlyIfSyntheticTokenExists(syntheticToken_)
        onlyIfDepositTokenExists(depositToken_)
        returns (uint256 _totalSeized, uint256 _toLiquidator, uint256 _fee)
    {
        if (amountToRepay_ == 0) revert AmountIsZero();
        if (msg.sender == account_) revert CanNotLiquidateOwnPosition();

        IDebtToken _debtToken = debtTokenOf[syntheticToken_];
        _debtToken.accrueInterest();

        (bool _isHealthy, , , , ) = debtPositionOf(account_);

        if (_isHealthy) {
            revert PositionIsHealthy();
        }

        uint256 _debtTokenBalance = _debtToken.balanceOf(account_);

        if (amountToRepay_.wadDiv(_debtTokenBalance) > maxLiquidable) {
            revert AmountGreaterThanMaxLiquidable();
        }

        IMasterOracle _masterOracle = masterOracle();

        if (debtFloorInUsd > 0) {
            uint256 _newDebtInUsd = _masterOracle.quoteTokenToUsd(
                address(syntheticToken_),
                _debtTokenBalance - amountToRepay_
            );
            if (_newDebtInUsd > 0 && _newDebtInUsd < debtFloorInUsd) {
                revert RemainingDebtIsLowerThanTheFloor();
            }
        }

        (_totalSeized, _toLiquidator, _fee) = quoteLiquidateOut(syntheticToken_, amountToRepay_, depositToken_);

        if (_totalSeized > depositToken_.balanceOf(account_)) {
            revert AmountIsTooHigh();
        }

        syntheticToken_.burn(msg.sender, amountToRepay_);
        _debtToken.burn(account_, amountToRepay_);
        depositToken_.seize(account_, msg.sender, _toLiquidator);

        if (_fee > 0) {
            depositToken_.seize(account_, poolRegistry.feeCollector(), _fee);
        }

        emit PositionLiquidated(msg.sender, account_, syntheticToken_, amountToRepay_, _totalSeized, _fee);
    }

    /**
     * @notice Get MasterOracle contract
     */
    function masterOracle() public view override returns (IMasterOracle) {
        return poolRegistry.masterOracle();
    }

    /**
     * @inheritdoc Pauseable
     */
    function paused() public view override(IPauseable, Pauseable) returns (bool) {
        return super.paused() || poolRegistry.paused();
    }

    /**
     * @notice Remove a debt token from the per-account list
     * @dev This function is called from `DebtToken` when user's balance changes to `0`
     * @dev The caller should ensure to not pass `address(0)` as `_account`
     * @param account_ The account address
     */
    function removeFromDebtTokensOfAccount(address account_) external onlyIfMsgSenderIsDebtToken {
        if (!debtTokensOfAccount.remove(account_, msg.sender)) revert DebtTokenDoesNotExist();
    }

    /**
     * @notice Remove a deposit token from the per-account list
     * @dev This function is called from `DepositToken` when user's balance changes to `0`
     * @dev The caller should ensure to not pass `address(0)` as `_account`
     * @param account_ The account address
     */
    function removeFromDepositTokensOfAccount(address account_) external onlyIfMsgSenderIsDepositToken {
        if (!depositTokensOfAccount.remove(account_, msg.sender)) revert DepositTokenDoesNotExist();
    }

    /**
     * @notice Swap synthetic tokens
     * @param syntheticTokenIn_ Synthetic token to sell
     * @param syntheticTokenOut_ Synthetic token to buy
     * @param amountIn_ Amount to swap
     */
    function swap(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountIn_
    )
        external
        override
        whenNotShutdown
        nonReentrant
        onlyIfSyntheticTokenExists(syntheticTokenIn_)
        onlyIfSyntheticTokenExists(syntheticTokenOut_)
        returns (uint256 _amountOut, uint256 _fee)
    {
        if (!isSwapActive) revert SwapFeatureIsInactive();
        if (amountIn_ == 0 || amountIn_ > syntheticTokenIn_.balanceOf(msg.sender)) revert AmountInIsInvalid();

        syntheticTokenIn_.burn(msg.sender, amountIn_);

        (_amountOut, _fee) = quoteSwapOut(syntheticTokenIn_, syntheticTokenOut_, amountIn_);

        if (_fee > 0) {
            syntheticTokenOut_.mint(poolRegistry.feeCollector(), _fee);
        }

        syntheticTokenOut_.mint(msg.sender, _amountOut);

        emit SyntheticTokenSwapped(msg.sender, syntheticTokenIn_, syntheticTokenOut_, amountIn_, _amountOut, _fee);
    }

    /**
     * @notice Swap assets using Swapper contract
     * @param swapper_ The Swapper contract
     * @param tokenIn_ The token to swap from
     * @param tokenOut_ The token to swap to
     * @param amountIn_ The amount in
     * @param amountOutMin_ The minimum amount out (slippage check)
     * @return _amountOut The actual amount out
     */
    function _swap(
        ISwapper swapper_,
        IERC20 tokenIn_,
        IERC20 tokenOut_,
        uint256 amountIn_,
        uint256 amountOutMin_
    ) private returns (uint256 _amountOut) {
        tokenIn_.safeApprove(address(swapper_), 0);
        tokenIn_.safeApprove(address(swapper_), amountIn_);
        uint256 _tokenOutBefore = tokenOut_.balanceOf(address(this));
        swapper_.swapExactInput(address(tokenIn_), address(tokenOut_), amountIn_, amountOutMin_, address(this));
        return tokenOut_.balanceOf(address(this)) - _tokenOutBefore;
    }

    /**
     * @notice Add debt token to offerings
     * @dev Must keep `debtTokenOf` mapping updated
     */
    function addDebtToken(IDebtToken debtToken_) external onlyGovernor {
        if (address(debtToken_) == address(0)) revert AddressIsNull();
        ISyntheticToken _syntheticToken = debtToken_.syntheticToken();
        if (address(_syntheticToken) == address(0)) revert SyntheticIsNull();
        if (address(debtTokenOf[_syntheticToken]) != address(0)) revert SyntheticIsInUse();

        if (!debtTokens.add(address(debtToken_))) revert DebtTokenAlreadyExists();

        debtTokenOf[_syntheticToken] = debtToken_;

        emit DebtTokenAdded(debtToken_);
    }

    /**
     * @notice Add deposit token (i.e. collateral) to Synth
     */
    function addDepositToken(address depositToken_) external onlyGovernor {
        if (depositToken_ == address(0)) revert AddressIsNull();
        IERC20 _underlying = IDepositToken(depositToken_).underlying();
        if (address(depositTokenOf[_underlying]) != address(0)) revert UnderlyingAssetInUse();
        // Note: Fee collector collects deposit tokens as fee
        if (depositTokens.length() >= MAX_TOKENS_PER_USER) revert ReachedMaxDepositTokens();

        if (!depositTokens.add(depositToken_)) revert DepositTokenAlreadyExists();

        depositTokenOf[_underlying] = IDepositToken(depositToken_);

        emit DepositTokenAdded(depositToken_);
    }

    /**
     * @notice Add a RewardsDistributor contract
     */
    function addRewardsDistributor(IRewardsDistributor distributor_) external onlyGovernor {
        if (address(distributor_) == address(0)) revert AddressIsNull();
        if (!rewardsDistributors.add(address(distributor_))) revert RewardDistributorAlreadyExists();
        emit RewardsDistributorAdded(distributor_);
    }

    /**
     * @notice Remove debt token from offerings
     * @dev Must keep `debtTokenOf` mapping updated
     */
    function removeDebtToken(IDebtToken debtToken_) external onlyGovernor {
        if (debtToken_.totalSupply() > 0) revert TotalSupplyIsNotZero();
        if (!debtTokens.remove(address(debtToken_))) revert DebtTokenDoesNotExist();

        delete debtTokenOf[debtToken_.syntheticToken()];

        emit DebtTokenRemoved(debtToken_);
    }

    /**
     * @notice Remove deposit token (i.e. collateral) from Synth
     */
    function removeDepositToken(IDepositToken depositToken_) external onlyGovernor {
        if (depositToken_.totalSupply() > 0) revert TotalSupplyIsNotZero();

        if (!depositTokens.remove(address(depositToken_))) revert DepositTokenDoesNotExist();
        delete depositTokenOf[depositToken_.underlying()];

        emit DepositTokenRemoved(depositToken_);
    }

    /**
     * @notice Remove a RewardsDistributor contract
     */
    function removeRewardsDistributor(IRewardsDistributor distributor_) external onlyGovernor {
        if (address(distributor_) == address(0)) revert AddressIsNull();
        if (!rewardsDistributors.remove(address(distributor_))) revert RewardDistributorDoesNotExist();

        emit RewardsDistributorRemoved(distributor_);
    }

    /**
     * @notice Turn swap on/off
     */
    function toggleIsSwapActive() external onlyGovernor {
        bool _newIsSwapActive = !isSwapActive;
        emit SwapActiveUpdated(_newIsSwapActive);
        isSwapActive = _newIsSwapActive;
    }

    /**
     * @notice Update debt floor
     */
    function updateDebtFloor(uint256 newDebtFloorInUsd_) external onlyGovernor {
        uint256 _currentDebtFloorInUsd = debtFloorInUsd;
        if (newDebtFloorInUsd_ == _currentDebtFloorInUsd) revert NewValueIsSameAsCurrent();
        emit DebtFloorUpdated(_currentDebtFloorInUsd, newDebtFloorInUsd_);
        debtFloorInUsd = newDebtFloorInUsd_;
    }

    /**
     * @notice Update maxLiquidable (liquidation cap)
     */
    function updateMaxLiquidable(uint256 newMaxLiquidable_) external onlyGovernor {
        if (newMaxLiquidable_ > 1e18) revert MaxLiquidableTooHigh();
        uint256 _currentMaxLiquidable = maxLiquidable;
        if (newMaxLiquidable_ == _currentMaxLiquidable) revert NewValueIsSameAsCurrent();
        emit MaxLiquidableUpdated(_currentMaxLiquidable, newMaxLiquidable_);
        maxLiquidable = newMaxLiquidable_;
    }

    /**
     * @notice Update treasury contract - will migrate funds to the new contract
     */
    function updateTreasury(ITreasury newTreasury_) external onlyGovernor {
        if (address(newTreasury_) == address(0)) revert AddressIsNull();
        ITreasury _currentTreasury = treasury;
        if (newTreasury_ == _currentTreasury) revert NewValueIsSameAsCurrent();

        if (address(_currentTreasury) != address(0)) {
            _currentTreasury.migrateTo(address(newTreasury_));
        }

        emit TreasuryUpdated(_currentTreasury, newTreasury_);
        treasury = newTreasury_;
    }

    /**
     * @notice Update FeeProvider contract
     */
    function updateFeeProvider(IFeeProvider feeProvider_) external onlyGovernor {
        if (address(feeProvider_) == address(0)) revert AddressIsNull();
        IFeeProvider _current = feeProvider;
        if (feeProvider_ == _current) revert NewValueIsSameAsCurrent();
        emit FeeProviderUpdated(_current, feeProvider_);
        feeProvider = feeProvider_;
    }

    /**
     * @notice Update swapper contract
     */
    function updateSwapper(ISwapper newSwapper_) external onlyGovernor {
        if (address(newSwapper_) == address(0)) revert AddressIsNull();
        ISwapper _currentSwapper = swapper;
        if (newSwapper_ == _currentSwapper) revert NewValueIsSameAsCurrent();

        emit SwapperUpdated(_currentSwapper, newSwapper_);
        swapper = newSwapper_;
    }
}