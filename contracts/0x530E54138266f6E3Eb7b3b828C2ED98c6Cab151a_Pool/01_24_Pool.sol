// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "./storage/PoolStorage.sol";
import "./lib/WadRayMath.sol";
import "./utils/Pauseable.sol";

/**
 * @title Pool contract
 */
contract Pool is ReentrancyGuard, Pauseable, PoolStorageV1 {
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using MappedEnumerableSet for MappedEnumerableSet.AddressSet;

    string public constant VERSION = "1.0.0";

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

    /// @notice Emitted when liquidator liquidation fee is updated
    event LiquidatorLiquidationFeeUpdated(uint256 oldLiquidatorLiquidationFee, uint256 newLiquidatorLiquidationFee);

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
    event RewardsDistributorAdded(IRewardsDistributor _distributor);

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
        require(isDepositTokenExists(depositToken_), "collateral-inexistent");
        _;
    }

    /**
     * @dev Throws if synthetic token doesn't exist
     */
    modifier onlyIfSyntheticTokenExists(ISyntheticToken syntheticToken_) {
        require(isSyntheticTokenExists(syntheticToken_), "synthetic-inexistent");
        _;
    }

    /**
     * @dev Throws if `msg.sender` isn't a debt token
     */
    modifier onlyIfMsgSenderIsDebtToken() {
        require(isDebtTokenExists(IDebtToken(msg.sender)), "caller-is-not-debt-token");
        _;
    }

    function initialize(IPoolRegistry poolRegistry_) public initializer {
        require(address(poolRegistry_) != address(0), "pool-registry-is-null");
        __ReentrancyGuard_init();
        __Pauseable_init();

        poolRegistry = poolRegistry_;
        isSwapActive = true;

        repayFee = 3e15; // 0.3%
        liquidationFees = LiquidationFees({
            liquidatorFee: 1e17, // 10%
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
        require(debtTokensOfAccount.add(account_, msg.sender), "debt-token-exists");
    }

    /**
     * @notice Add a deposit token to the per-account list
     * @dev This function is called from `DepositToken` when user's balance changes from `0`
     * @dev The caller should ensure to not pass `address(0)` as `_account`
     * @param account_ The account address
     */
    function addToDepositTokensOfAccount(address account_) external {
        require(depositTokens.contains(msg.sender), "caller-is-not-deposit-token");
        require(depositTokensOfAccount.add(account_, msg.sender), "deposit-token-exists");
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
     * @notice Get if the debt position from an account is healthy
     * @param account_ The account to check
     * @return _isHealthy Whether the account's position is healthy
     * @return _depositInUsd The total collateral deposited in USD
     * @return _debtInUsd The total debt in USD
     * @return _issuableLimitInUsd The max amount of debt (is USD) that can be created (considering collateralization ratios)
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
            _issuableLimitInUsd += _amountInUsd.wadMul(_depositToken.collateralizationRatio());
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
    function feeCollector() external view returns (address) {
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
    function isDebtTokenExists(IDebtToken debtToken_) public view override returns (bool) {
        return debtTokens.contains(address(debtToken_));
    }

    /**
     * @notice Check if collateral is supported
     * @param depositToken_ Asset to check
     * @return true if exist
     */
    function isDepositTokenExists(IDepositToken depositToken_) public view override returns (bool) {
        return depositTokens.contains(address(depositToken_));
    }

    /**
     * @notice Check if token is part of the synthetic offerings
     * @param syntheticToken_ Asset to check
     * @return true if exist
     */
    function isSyntheticTokenExists(ISyntheticToken syntheticToken_) public view override returns (bool) {
        return address(debtTokenOf[syntheticToken_]) != address(0);
    }

    /**
     * @notice Burn synthetic token, unlock deposit token and send liquidator liquidation fee
     * @param syntheticToken_ The msAsset to use for repayment
     * @param account_ The account with an unhealthy position
     * @param amountToRepay_ The amount to repay in synthetic token
     * @param depositToken_ The collateral to seize from
     */
    function liquidate(
        ISyntheticToken syntheticToken_,
        address account_,
        uint256 amountToRepay_,
        IDepositToken depositToken_
    ) external override whenNotShutdown nonReentrant onlyIfDepositTokenExists(depositToken_) {
        require(amountToRepay_ > 0, "amount-is-zero");
        require(msg.sender != account_, "can-not-liquidate-own-position");

        IDebtToken _debtToken = debtTokenOf[syntheticToken_];
        _debtToken.accrueInterest();

        (bool _isHealthy, , , , ) = debtPositionOf(account_);

        require(!_isHealthy, "position-is-healthy");

        uint256 _debtTokenBalance = _debtToken.balanceOf(account_);

        require(amountToRepay_.wadDiv(_debtTokenBalance) <= maxLiquidable, "amount-gt-max-liquidable");

        IMasterOracle _masterOracle = masterOracle();

        if (debtFloorInUsd > 0) {
            uint256 _newDebtInUsd = _masterOracle.quoteTokenToUsd(
                address(syntheticToken_),
                _debtTokenBalance - amountToRepay_
            );
            require(_newDebtInUsd == 0 || _newDebtInUsd >= debtFloorInUsd, "remaining-debt-lt-floor");
        }

        uint256 _amountToRepayInCollateral = _masterOracle.quote(
            address(syntheticToken_),
            address(depositToken_.underlying()),
            amountToRepay_
        );

        LiquidationFees memory _fees = liquidationFees;

        uint256 _toProtocol = _fees.protocolFee > 0 ? _amountToRepayInCollateral.wadMul(_fees.protocolFee) : 0;
        uint256 _toLiquidator = _amountToRepayInCollateral.wadMul(1e18 + _fees.liquidatorFee);
        uint256 _depositToSeize = _toProtocol + _toLiquidator;

        require(_depositToSeize <= depositToken_.balanceOf(account_), "amount-too-high");

        syntheticToken_.burn(msg.sender, amountToRepay_);
        _debtToken.burn(account_, amountToRepay_);
        depositToken_.seize(account_, msg.sender, _toLiquidator);

        if (_toProtocol > 0) {
            depositToken_.seize(account_, poolRegistry.feeCollector(), _toProtocol);
        }

        emit PositionLiquidated(msg.sender, account_, syntheticToken_, amountToRepay_, _depositToSeize, _toProtocol);
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
        require(debtTokensOfAccount.remove(account_, msg.sender), "debt-token-doesnt-exist");
    }

    /**
     * @notice Remove a deposit token from the per-account list
     * @dev This function is called from `DepositToken` when user's balance changes to `0`
     * @dev The caller should ensure to not pass `address(0)` as `_account`
     * @param account_ The account address
     */
    function removeFromDepositTokensOfAccount(address account_) external {
        require(depositTokens.contains(msg.sender), "caller-is-not-deposit-token");
        require(depositTokensOfAccount.remove(account_, msg.sender), "deposit-token-doesnt-exist");
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
        returns (uint256 _amountOut)
    {
        require(isSwapActive, "swap-is-off");
        require(amountIn_ > 0 && amountIn_ <= syntheticTokenIn_.balanceOf(msg.sender), "amount-in-is-invalid");
        syntheticTokenIn_.burn(msg.sender, amountIn_);

        _amountOut = poolRegistry.masterOracle().quote(
            address(syntheticTokenIn_),
            address(syntheticTokenOut_),
            amountIn_
        );

        uint256 _feeAmount;
        if (swapFee > 0) {
            _feeAmount = _amountOut.wadMul(swapFee);
            syntheticTokenOut_.mint(poolRegistry.feeCollector(), _feeAmount);
            _amountOut -= _feeAmount;
        }

        syntheticTokenOut_.mint(msg.sender, _amountOut);

        emit SyntheticTokenSwapped(
            msg.sender,
            syntheticTokenIn_,
            syntheticTokenOut_,
            amountIn_,
            _amountOut,
            _feeAmount
        );
    }

    /**
     * @notice Add debt token to offerings
     * @dev Must keep `debtTokenOf` mapping updated
     */
    function addDebtToken(IDebtToken debtToken_) external override onlyGovernor {
        require(address(debtToken_) != address(0), "address-is-null");
        ISyntheticToken _syntheticToken = debtToken_.syntheticToken();
        require(address(_syntheticToken) != address(0), "synthetic-is-null");
        require(address(debtTokenOf[_syntheticToken]) == address(0), "synth-in-use");

        require(debtTokens.add(address(debtToken_)), "debt-exists");

        debtTokenOf[_syntheticToken] = debtToken_;

        emit DebtTokenAdded(debtToken_);
    }

    /**
     * @notice Add deposit token (i.e. collateral) to Synth
     */
    function addDepositToken(address depositToken_) external override onlyGovernor {
        require(depositToken_ != address(0), "address-is-null");
        IERC20 _underlying = IDepositToken(depositToken_).underlying();
        require(address(depositTokenOf[_underlying]) == address(0), "underlying-in-use");

        require(depositTokens.add(depositToken_), "deposit-token-exists");

        depositTokenOf[_underlying] = IDepositToken(depositToken_);

        emit DepositTokenAdded(depositToken_);
    }

    /**
     * @notice Add a RewardsDistributor contract
     */
    function addRewardsDistributor(IRewardsDistributor distributor_) external override onlyGovernor {
        require(address(distributor_) != address(0), "address-is-null");

        uint256 _length = rewardsDistributors.length;
        for (uint256 i; i < _length; ++i) {
            require(distributor_ != rewardsDistributors[i], "contract-already-added");
        }

        rewardsDistributors.push(distributor_);
        emit RewardsDistributorAdded(distributor_);
    }

    /**
     * @notice Remove debt token from offerings
     * @dev Must keep `debtTokenOf` mapping updated
     */
    function removeDebtToken(IDebtToken debtToken_) external override onlyGovernor {
        require(debtToken_.totalSupply() == 0, "supply-gt-0");
        require(debtTokens.remove(address(debtToken_)), "debt-doesnt-exist");

        delete debtTokenOf[debtToken_.syntheticToken()];

        emit DebtTokenRemoved(debtToken_);
    }

    /**
     * @notice Remove deposit token (i.e. collateral) from Synth
     */
    function removeDepositToken(IDepositToken depositToken_) external override onlyGovernor {
        require(depositToken_.totalSupply() == 0, "supply-gt-0");

        require(depositTokens.remove(address(depositToken_)), "deposit-token-doesnt-exist");
        delete depositTokenOf[depositToken_.underlying()];

        emit DepositTokenRemoved(depositToken_);
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
        require(newDebtFloorInUsd_ != _currentDebtFloorInUsd, "new-same-as-current");
        emit DebtFloorUpdated(_currentDebtFloorInUsd, newDebtFloorInUsd_);
        debtFloorInUsd = newDebtFloorInUsd_;
    }

    /**
     * @notice Update deposit fee
     */
    function updateDepositFee(uint256 newDepositFee_) external override onlyGovernor {
        require(newDepositFee_ <= 1e18, "max-is-100%");
        uint256 _currentDepositFee = depositFee;
        require(newDepositFee_ != _currentDepositFee, "new-same-as-current");
        emit DepositFeeUpdated(_currentDepositFee, newDepositFee_);
        depositFee = newDepositFee_;
    }

    /**
     * @notice Update issue fee
     */
    function updateIssueFee(uint256 newIssueFee_) external override onlyGovernor {
        require(newIssueFee_ <= 1e18, "max-is-100%");
        uint256 _currentIssueFee = issueFee;
        require(newIssueFee_ != _currentIssueFee, "new-same-as-current");
        emit IssueFeeUpdated(_currentIssueFee, newIssueFee_);
        issueFee = newIssueFee_;
    }

    /**
     * @notice Update liquidator liquidation fee
     */
    function updateLiquidatorLiquidationFee(uint128 newLiquidatorLiquidationFee_) external override onlyGovernor {
        require(newLiquidatorLiquidationFee_ <= 1e18, "max-is-100%");
        uint256 _currentLiquidatorLiquidationFee = liquidationFees.liquidatorFee;
        require(newLiquidatorLiquidationFee_ != _currentLiquidatorLiquidationFee, "new-same-as-current");
        emit LiquidatorLiquidationFeeUpdated(_currentLiquidatorLiquidationFee, newLiquidatorLiquidationFee_);
        liquidationFees.liquidatorFee = newLiquidatorLiquidationFee_;
    }

    /**
     * @notice Update maxLiquidable (liquidation cap)
     */
    function updateMaxLiquidable(uint256 newMaxLiquidable_) external override onlyGovernor {
        require(newMaxLiquidable_ <= 1e18, "max-is-100%");
        uint256 _currentMaxLiquidable = maxLiquidable;
        require(newMaxLiquidable_ != _currentMaxLiquidable, "new-same-as-current");
        emit MaxLiquidableUpdated(_currentMaxLiquidable, newMaxLiquidable_);
        maxLiquidable = newMaxLiquidable_;
    }

    /**
     * @notice Update protocol liquidation fee
     */
    function updateProtocolLiquidationFee(uint128 newProtocolLiquidationFee_) external override onlyGovernor {
        require(newProtocolLiquidationFee_ <= 1e18, "max-is-100%");
        uint256 _currentProtocolLiquidationFee = liquidationFees.protocolFee;
        require(newProtocolLiquidationFee_ != _currentProtocolLiquidationFee, "new-same-as-current");
        emit ProtocolLiquidationFeeUpdated(_currentProtocolLiquidationFee, newProtocolLiquidationFee_);
        liquidationFees.protocolFee = newProtocolLiquidationFee_;
    }

    /**
     * @notice Update repay fee
     */
    function updateRepayFee(uint256 newRepayFee_) external override onlyGovernor {
        require(newRepayFee_ <= 1e18, "max-is-100%");
        uint256 _currentRepayFee = repayFee;
        require(newRepayFee_ != _currentRepayFee, "new-same-as-current");
        emit RepayFeeUpdated(_currentRepayFee, newRepayFee_);
        repayFee = newRepayFee_;
    }

    /**
     * @notice Update treasury contract - will migrate funds to the new contract
     */
    function updateTreasury(ITreasury newTreasury_) external override onlyGovernor {
        require(address(newTreasury_) != address(0), "address-is-null");
        ITreasury _currentTreasury = treasury;
        require(newTreasury_ != _currentTreasury, "new-same-as-current");

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
        require(newSwapFee_ <= 1e18, "max-is-100%");
        uint256 _currentSwapFee = swapFee;
        require(newSwapFee_ != _currentSwapFee, "new-same-as-current");
        emit SwapFeeUpdated(_currentSwapFee, newSwapFee_);
        swapFee = newSwapFee_;
    }

    /**
     * @notice Update withdraw fee
     */
    function updateWithdrawFee(uint256 newWithdrawFee_) external override onlyGovernor {
        require(newWithdrawFee_ <= 1e18, "max-is-100%");
        uint256 _currentWithdrawFee = withdrawFee;
        require(newWithdrawFee_ != _currentWithdrawFee, "new-same-as-current");
        emit WithdrawFeeUpdated(_currentWithdrawFee, newWithdrawFee_);
        withdrawFee = newWithdrawFee_;
    }
}