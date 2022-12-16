// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "./storage/PoolStorage.sol";
import "./lib/WadRayMath.sol";
import "./utils/Pauseable.sol";

error CollateralDoesNotExist();
error SyntheticDoesNotExist();
error SenderIsNotDebtToken();
error PoolRegistryIsNull();
error DebtTokenAlreadyExists();
error SenderIsNotDepositToken();
error DepositTokenAlreadyExists();
error AmountIsZero();
error CanNotLiquidateOwnPosition();
error PositionIsHealthy();
error AmountGreaterThanMaxLiquidable();
error RemainingDebtIsLowerThanTheFloor();
error AmountIsTooHight();
error DebtTokenDoesNotExist();
error DepositTokenDoesNotExist();
error SwapFeatureIsInactive();
error AmountInIsInvalid();
error AddressIsNull();
error SyntheticIsNull();
error SyntheticIsInUse();
error UnderlyingAssetInUse();
error RewardDistributorAlreadyExists();
error RewardDistributorDoesNotExist();
error TotalSupplyIsNotZero();
error NewValueIsSameAsCurrent();
error FeeIsGreaterThanTheMax();
error MaxLiquidableTooHigh();

/**
 * @title Pool contract
 */
contract Pool is ReentrancyGuard, Pauseable, PoolStorageV1 {
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using MappedEnumerableSet for MappedEnumerableSet.AddressSet;

    string public constant VERSION = "1.0.0";
    uint256 internal constant MAX_FEE_VALUE = 0.25e18; // 25%

    /// @notice Emitted when protocol liquidation fee is updated
    event DebtFloorUpdated(uint256 oldDebtFloorInUsd, uint256 newDebtFloorInUsd);

    /// @notice Emitted when debt token is enabled
    event DebtTokenAdded(IDebtToken indexed debtToken);

    /// @notice Emitted when debt token is disabled
    event DebtTokenRemoved(IDebtToken indexed debtToken);

    /// @notice Emitted when deposit fee is updated
    event DepositFeeUpdated(uint256 oldDepositFee, uint256 newDepositFee);

    /// @notice Emitted when deposit token is enabled
    event DepositTokenAdded(address indexed depositToken);

    /// @notice Emitted when deposit token is disabled
    event DepositTokenRemoved(IDepositToken indexed depositToken);

    /// @notice Emitted when issue fee is updated
    event IssueFeeUpdated(uint256 oldIssueFee, uint256 newIssueFee);

    /// @notice Emitted when liquidator incentive is updated
    event LiquidatorIncentiveUpdated(uint256 oldLiquidatorIncentive, uint256 newLiquidatorIncentive);

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

    /// @notice Emitted when protocol liquidation fee is updated
    event ProtocolLiquidationFeeUpdated(uint256 oldProtocolLiquidationFee, uint256 newProtocolLiquidationFee);

    /// @notice Emitted when repay fee is updated
    event RepayFeeUpdated(uint256 oldRepayFee, uint256 newRepayFee);

    /// @notice Emitted when rewards distributor contract is added
    event RewardsDistributorAdded(IRewardsDistributor indexed _distributor);

    /// @notice Emitted when rewards distributor contract is removed
    event RewardsDistributorRemoved(IRewardsDistributor _distributor);

    /// @notice Emitted when swap fee is updated
    event SwapFeeUpdated(uint256 oldSwapFee, uint256 newSwapFee);

    /// @notice Emitted when the swap active flag is updated
    event SwapActiveUpdated(bool newActive);

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

    /// @notice Emitted when withdraw fee is updated
    event WithdrawFeeUpdated(uint256 oldWithdrawFee, uint256 newWithdrawFee);

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

    function initialize(IPoolRegistry poolRegistry_) public initializer {
        if (address(poolRegistry_) == address(0)) revert PoolRegistryIsNull();
        __ReentrancyGuard_init();
        __Pauseable_init();

        poolRegistry = poolRegistry_;
        isSwapActive = true;

        repayFee = 3e15; // 0.3%
        liquidationFees = LiquidationFees({
            liquidatorIncentive: 1e17, // 10%
            protocolFee: 8e16 // 8%
        });
        maxLiquidable = 0.5e18; // 50%
        swapFee = 6e15; // 0.6%
    }

    /**
     * @notice Add a debt token to the per-account list
     * @dev This function is called from `DebtToken` when user's balance changes from `0`
     * @dev The caller should ensure to not pass `address(0)` as `_account`
     * @param account_ The account address
     */
    function addToDebtTokensOfAccount(address account_) external onlyIfMsgSenderIsDebtToken {
        if (!debtTokensOfAccount.add(account_, msg.sender)) revert DebtTokenAlreadyExists();
    }

    /**
     * @notice Add a deposit token to the per-account list
     * @dev This function is called from `DepositToken` when user's balance changes from `0`
     * @dev The caller should ensure to not pass `address(0)` as `_account`
     * @param account_ The account address
     */
    function addToDepositTokensOfAccount(address account_) external {
        if (!depositTokens.contains(msg.sender)) revert SenderIsNotDepositToken();
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
     * @notice Returns whether the debt position from an account is healthy
     * @param account_ The account to check
     * @return _isHealthy Whether the account's position is healthy
     * @return _depositInUsd The total collateral deposited in USD
     * @return _debtInUsd The total debt in USD
     * @return _issuableLimitInUsd The max amount of debt (is USD) that can be created (considering collateral factors)
     * @return _issuableInUsd The amount of debt (is USD) that is free (i.e. can be used to issue synthetic tokens)
     */
    function debtPositionOf(address account_)
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
    function depositOf(address account_)
        public
        view
        override
        returns (uint256 _depositInUsd, uint256 _issuableLimitInUsd)
    {
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
    function getRewardsDistributors() external view override returns (IRewardsDistributor[] memory) {
        return rewardsDistributors;
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
    )
        public
        view
        override
        returns (
            uint256 _amountToRepay,
            uint256 _toLiquidator,
            uint256 _fee
        )
    {
        LiquidationFees memory _fees = liquidationFees;
        uint256 _totalFees = _fees.protocolFee + _fees.liquidatorIncentive;
        uint256 _repayAmountInCollateral = totalToSeize_;

        if (_totalFees > 0) {
            _repayAmountInCollateral = _repayAmountInCollateral.wadDiv(1e18 + _totalFees);
        }

        _amountToRepay = masterOracle().quote(
            address(depositToken_.underlying()),
            address(syntheticToken_),
            _repayAmountInCollateral
        );

        if (_fees.protocolFee > 0) {
            _fee = _repayAmountInCollateral.wadMul(_fees.protocolFee);
        }

        if (_fees.liquidatorIncentive > 0) {
            _toLiquidator = _repayAmountInCollateral.wadMul(1e18 + _fees.liquidatorIncentive);
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
    )
        public
        view
        override
        returns (
            uint256 _totalToSeize,
            uint256 _toLiquidator,
            uint256 _fee
        )
    {
        _toLiquidator = masterOracle().quote(
            address(syntheticToken_),
            address(depositToken_.underlying()),
            amountToRepay_
        );

        LiquidationFees memory _fees = liquidationFees;

        if (_fees.protocolFee > 0) {
            _fee = _toLiquidator.wadMul(_fees.protocolFee);
        }
        if (_fees.liquidatorIncentive > 0) {
            _toLiquidator += _toLiquidator.wadMul(_fees.liquidatorIncentive);
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
        uint256 _swapFee = swapFee;
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

        uint256 _swapFee = swapFee;
        if (_swapFee > 0) {
            _fee = _amountOut.wadMul(_swapFee);
            _amountOut -= _fee;
        }
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
        onlyIfDepositTokenExists(depositToken_)
        returns (
            uint256 _totalSeized,
            uint256 _toLiquidator,
            uint256 _fee
        )
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
            revert AmountIsTooHight();
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
    function removeFromDepositTokensOfAccount(address account_) external {
        if (!depositTokens.contains(msg.sender)) revert SenderIsNotDepositToken();
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
     * @notice Add debt token to offerings
     * @dev Must keep `debtTokenOf` mapping updated
     */
    function addDebtToken(IDebtToken debtToken_) external override onlyGovernor {
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
    function addDepositToken(address depositToken_) external override onlyGovernor {
        if (depositToken_ == address(0)) revert AddressIsNull();
        IERC20 _underlying = IDepositToken(depositToken_).underlying();
        if (address(depositTokenOf[_underlying]) != address(0)) revert UnderlyingAssetInUse();

        if (!depositTokens.add(depositToken_)) revert DepositTokenAlreadyExists();

        depositTokenOf[_underlying] = IDepositToken(depositToken_);

        emit DepositTokenAdded(depositToken_);
    }

    /**
     * @notice Add a RewardsDistributor contract
     */
    function addRewardsDistributor(IRewardsDistributor distributor_) external override onlyGovernor {
        if (address(distributor_) == address(0)) revert AddressIsNull();

        uint256 _length = rewardsDistributors.length;
        for (uint256 i; i < _length; ++i) {
            if (distributor_ == rewardsDistributors[i]) {
                revert RewardDistributorAlreadyExists();
            }
        }

        rewardsDistributors.push(distributor_);
        emit RewardsDistributorAdded(distributor_);
    }

    /**
     * @notice Remove debt token from offerings
     * @dev Must keep `debtTokenOf` mapping updated
     */
    function removeDebtToken(IDebtToken debtToken_) external override onlyGovernor {
        if (debtToken_.totalSupply() > 0) revert TotalSupplyIsNotZero();
        if (!debtTokens.remove(address(debtToken_))) revert DebtTokenDoesNotExist();

        delete debtTokenOf[debtToken_.syntheticToken()];

        emit DebtTokenRemoved(debtToken_);
    }

    /**
     * @notice Remove deposit token (i.e. collateral) from Synth
     */
    function removeDepositToken(IDepositToken depositToken_) external override onlyGovernor {
        if (depositToken_.totalSupply() > 0) revert TotalSupplyIsNotZero();

        if (!depositTokens.remove(address(depositToken_))) revert DepositTokenDoesNotExist();
        delete depositTokenOf[depositToken_.underlying()];

        emit DepositTokenRemoved(depositToken_);
    }

    /**
     * @notice Remove a RewardsDistributor contract
     */
    function removeRewardsDistributor(IRewardsDistributor distributor_) external override onlyGovernor {
        if (address(distributor_) == address(0)) revert AddressIsNull();

        uint256 _length = rewardsDistributors.length;
        uint256 _index = _length;
        for (uint256 i; i < _length; ++i) {
            if (rewardsDistributors[i] == distributor_) {
                _index = i;
                break;
            }
        }
        if (_index == _length) revert RewardDistributorDoesNotExist();
        if (_index != _length - 1) {
            rewardsDistributors[_index] = rewardsDistributors[_length - 1];
        }
        rewardsDistributors.pop();

        emit RewardsDistributorRemoved(distributor_);
    }

    /**
     * @notice Turn swap on/off
     */
    function toggleIsSwapActive() external override onlyGovernor {
        bool _newIsSwapActive = !isSwapActive;
        emit SwapActiveUpdated(_newIsSwapActive);
        isSwapActive = _newIsSwapActive;
    }

    /**
     * @notice Update debt floor
     */
    function updateDebtFloor(uint256 newDebtFloorInUsd_) external override onlyGovernor {
        uint256 _currentDebtFloorInUsd = debtFloorInUsd;
        if (newDebtFloorInUsd_ == _currentDebtFloorInUsd) revert NewValueIsSameAsCurrent();
        emit DebtFloorUpdated(_currentDebtFloorInUsd, newDebtFloorInUsd_);
        debtFloorInUsd = newDebtFloorInUsd_;
    }

    /**
     * @notice Update deposit fee
     */
    function updateDepositFee(uint256 newDepositFee_) external override onlyGovernor {
        if (newDepositFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentDepositFee = depositFee;
        if (newDepositFee_ == _currentDepositFee) revert NewValueIsSameAsCurrent();
        emit DepositFeeUpdated(_currentDepositFee, newDepositFee_);
        depositFee = newDepositFee_;
    }

    /**
     * @notice Update issue fee
     */
    function updateIssueFee(uint256 newIssueFee_) external override onlyGovernor {
        if (newIssueFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentIssueFee = issueFee;
        if (newIssueFee_ == _currentIssueFee) revert NewValueIsSameAsCurrent();
        emit IssueFeeUpdated(_currentIssueFee, newIssueFee_);
        issueFee = newIssueFee_;
    }

    /**
     * @notice Update liquidator incentive
     */
    function updateLiquidatorIncentive(uint128 newLiquidatorIncentive_) external override onlyGovernor {
        if (newLiquidatorIncentive_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentLiquidatorIncentive = liquidationFees.liquidatorIncentive;
        if (newLiquidatorIncentive_ == _currentLiquidatorIncentive) revert NewValueIsSameAsCurrent();
        emit LiquidatorIncentiveUpdated(_currentLiquidatorIncentive, newLiquidatorIncentive_);
        liquidationFees.liquidatorIncentive = newLiquidatorIncentive_;
    }

    /**
     * @notice Update maxLiquidable (liquidation cap)
     */
    function updateMaxLiquidable(uint256 newMaxLiquidable_) external override onlyGovernor {
        if (newMaxLiquidable_ > 1e18) revert MaxLiquidableTooHigh();
        uint256 _currentMaxLiquidable = maxLiquidable;
        if (newMaxLiquidable_ == _currentMaxLiquidable) revert NewValueIsSameAsCurrent();
        emit MaxLiquidableUpdated(_currentMaxLiquidable, newMaxLiquidable_);
        maxLiquidable = newMaxLiquidable_;
    }

    /**
     * @notice Update protocol liquidation fee
     */
    function updateProtocolLiquidationFee(uint128 newProtocolLiquidationFee_) external override onlyGovernor {
        if (newProtocolLiquidationFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentProtocolLiquidationFee = liquidationFees.protocolFee;
        if (newProtocolLiquidationFee_ == _currentProtocolLiquidationFee) revert NewValueIsSameAsCurrent();
        emit ProtocolLiquidationFeeUpdated(_currentProtocolLiquidationFee, newProtocolLiquidationFee_);
        liquidationFees.protocolFee = newProtocolLiquidationFee_;
    }

    /**
     * @notice Update repay fee
     */
    function updateRepayFee(uint256 newRepayFee_) external override onlyGovernor {
        if (newRepayFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentRepayFee = repayFee;
        if (newRepayFee_ == _currentRepayFee) revert NewValueIsSameAsCurrent();
        emit RepayFeeUpdated(_currentRepayFee, newRepayFee_);
        repayFee = newRepayFee_;
    }

    /**
     * @notice Update treasury contract - will migrate funds to the new contract
     */
    function updateTreasury(ITreasury newTreasury_) external override onlyGovernor {
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
     * @notice Update swap fee
     */
    function updateSwapFee(uint256 newSwapFee_) external override onlyGovernor {
        if (newSwapFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentSwapFee = swapFee;
        if (newSwapFee_ == _currentSwapFee) revert NewValueIsSameAsCurrent();
        emit SwapFeeUpdated(_currentSwapFee, newSwapFee_);
        swapFee = newSwapFee_;
    }

    /**
     * @notice Update withdraw fee
     */
    function updateWithdrawFee(uint256 newWithdrawFee_) external override onlyGovernor {
        if (newWithdrawFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentWithdrawFee = withdrawFee;
        if (newWithdrawFee_ == _currentWithdrawFee) revert NewValueIsSameAsCurrent();
        emit WithdrawFeeUpdated(_currentWithdrawFee, newWithdrawFee_);
        withdrawFee = newWithdrawFee_;
    }
}