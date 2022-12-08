// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./HDT/HDT.sol";
import "./HumaConfig.sol";
import "./BasePool.sol";
import "./Errors.sol";

import "hardhat/console.sol";

contract BasePoolConfig is Ownable, Initializable {
    using SafeERC20 for IERC20;

    /**
     * @notice Stores required liquidity rate and rewards rate for Pool Owner and EA
     */
    struct PoolConfig {
        // The max liquidity allowed for the pool.
        uint256 _liquidityCap;
        // How long a lender has to wait after the last deposit before they can withdraw
        uint256 _withdrawalLockoutPeriodInSeconds;
        // Percentage of pool income allocated to EA
        uint256 _rewardRateInBpsForEA;
        // Percentage of pool income allocated to Pool Owner
        uint256 _rewardRateInBpsForPoolOwner;
        // Percentage of the _liquidityCap to be contributed by EA
        uint256 _liquidityRateInBpsByEA;
        // Percentage of the _liquidityCap to be contributed by Pool Owner
        uint256 _liquidityRateInBpsByPoolOwner;
        // the maximum credit line for an address in terms of the amount of poolTokens
        uint88 _maxCreditLine;
        // the grace period at the pool level before a Default can be triggered
        uint256 _poolDefaultGracePeriodInSeconds;
        // pay period for the pool, measured in number of days
        uint256 _payPeriodInDays;
        // Percentage of receivable required for credits in this pool in terms of basis points
        // For over receivableization, use more than 100%, for no receivable, use 0.
        uint256 _receivableRequiredInBps;
        // the default APR for the pool in terms of basis points.
        uint256 _poolAprInBps;
        // the duration of a credit line without an initial drawdown
        uint256 _creditApprovalExpirationInSeconds;
    }

    struct AccruedIncome {
        uint128 _protocolIncome;
        uint128 _poolOwnerIncome;
        uint128 _eaIncome;
    }

    struct AccruedWithdrawn {
        uint128 _eaIncomeWithdrawn;
        uint128 _protocolIncomeWithdrawn;
        uint128 _poolOwnerIncomeWithdrawn;
    }

    uint256 private constant HUNDRED_PERCENT_IN_BPS = 10000;
    uint256 private constant SECONDS_IN_A_DAY = 1 days;
    uint256 private constant SECONDS_IN_180_DAYS = 180 days;
    uint256 private constant WITHDRAWAL_LOCKOUT_PERIOD_IN_SECONDS = SECONDS_IN_180_DAYS;

    string public poolName;

    address public pool;

    HumaConfig public humaConfig;

    address public feeManager;

    // The HDT token for this pool
    HDT public poolToken;

    // The ERC20 token this pool manages
    IERC20 public underlyingToken;

    // Evaluation Agents (EA) are the risk underwriting agents that associated with the pool.
    address public evaluationAgent;

    uint256 public evaluationAgentId;

    PoolConfig internal _poolConfig;

    AccruedIncome internal _accuredIncome;

    AccruedWithdrawn internal _accuredWithdrawn;

    /// Pool operators can add or remove lenders.
    mapping(address => bool) private poolOperators;

    // Address for the account that handles the treasury functions for the pool owner:
    // liquidity deposits, liquidity withdrawls, and reward withdrawals
    address public poolOwnerTreasury;

    event APRChanged(uint256 aprInBps, address by);
    event CreditApprovalExpirationChanged(uint256 durationInSeconds, address by);
    event EARewardsAndLiquidityChanged(
        uint256 rewardsRate,
        uint256 liquidityRate,
        address indexed by
    );
    event EvaluationAgentChanged(address oldEA, address newEA, uint256 newEAId, address by);
    event EvaluationAgentRewardsWithdrawn(address receiver, uint256 amount, address by);
    event FeeManagerChanged(address feeManager, address by);
    event HDTChanged(address hdt, address udnerlyingToken, address by);
    event HumaConfigChanged(address humaConfig, address by);
    event IncomeDistributed(
        uint256 protocolFee,
        uint256 ownerIncome,
        uint256 eaIncome,
        uint256 poolIncome
    );

    event IncomeReversed(
        uint256 protocolFee,
        uint256 ownerIncome,
        uint256 eaIncome,
        uint256 poolIncome
    );
    event MaxCreditLineChanged(uint256 maxCreditLine, address by);
    event PoolChanged(address pool, address by);
    event PoolDefaultGracePeriodChanged(uint256 gracePeriodInDays, address by);
    event PoolLiquidityCapChanged(uint256 liquidityCap, address by);
    event PoolNameChanged(string name, address by);
    event PoolOwnerRewardsAndLiquidityChanged(
        uint256 rewardsRate,
        uint256 liquidityRate,
        address indexed by
    );
    event PoolOwnerTreasuryChanged(address treasury, address indexed by);
    event PoolPayPeriodChanged(uint256 periodInDays, address by);
    event PoolRewardsWithdrawn(address receiver, uint256 amount);
    event ProtocolRewardsWithdrawn(address receiver, uint256 amount, address by);
    event ReceivableRequiredInBpsChanged(uint256 receivableInBps, address by);
    event WithdrawalLockoutPeriodChanged(uint256 lockoutPeriodInDays, address by);

    /// An operator has been added. An operator is someone who can add or remove approved lenders.
    event PoolOperatorAdded(address indexed operator, address by);

    /// A operator has been removed
    event PoolOperatorRemoved(address indexed operator, address by);

    function initialize(
        string memory _poolName,
        address _poolToken,
        address _humaConfig,
        address _feeManager
    ) external onlyOwner initializer {
        poolName = _poolName;
        if (_poolToken == address(0)) revert Errors.zeroAddressProvided();
        if (_humaConfig == address(0)) revert Errors.zeroAddressProvided();
        if (_feeManager == address(0)) revert Errors.zeroAddressProvided();
        poolToken = HDT(_poolToken);

        humaConfig = HumaConfig(_humaConfig);

        address assetTokenAddress = poolToken.assetToken();
        if (!humaConfig.isAssetValid(assetTokenAddress))
            revert Errors.underlyingTokenNotApprovedForHumaProtocol();
        underlyingToken = IERC20(assetTokenAddress);

        feeManager = _feeManager;

        _poolConfig._withdrawalLockoutPeriodInSeconds = WITHDRAWAL_LOCKOUT_PERIOD_IN_SECONDS;
        _poolConfig._poolDefaultGracePeriodInSeconds = HumaConfig(humaConfig)
            .protocolDefaultGracePeriodInSeconds();

        // Default values for the pool configurations. The pool owners are expected to reset
        // these values when setting up the pools. Setting these default values to avoid
        // strange behaviors when the pool owner missed setting up these configurations.
        // _liquidityCap, _maxCreditLine, _creditApprovalExpirationInSeconds are left at 0.
        _poolConfig._rewardRateInBpsForEA = 100;
        _poolConfig._rewardRateInBpsForPoolOwner = 100;
        _poolConfig._liquidityRateInBpsByEA = 200;
        _poolConfig._liquidityRateInBpsByPoolOwner = 200;
        _poolConfig._payPeriodInDays = 30;
        _poolConfig._receivableRequiredInBps = 10000;
        _poolConfig._poolAprInBps = 1500;
    }

    /**
     * @notice Adds a operator, who can add or remove approved lenders.
     * @param _operator Address to be added to the operator list
     * @dev If address(0) is provided, revert with "zeroAddressProvided()"
     * @dev If the address is already an operator, revert w/ "alreadyAnOperator"
     * @dev Emits a PoolOperatorAdded event.
     */
    function addPoolOperator(address _operator) external onlyOwner {
        if (_operator == address(0)) revert Errors.zeroAddressProvided();
        if (poolOperators[_operator]) revert Errors.alreadyAnOperator();

        poolOperators[_operator] = true;

        emit PoolOperatorAdded(_operator, msg.sender);
    }

    function distributeIncome(uint256 value) external returns (uint256 poolIncome) {
        if (msg.sender != pool) {
            revert Errors.notPool();
        }

        AccruedIncome memory tempIncome = _accuredIncome;

        uint256 protocolFee = (uint256(humaConfig.protocolFee()) * value) / HUNDRED_PERCENT_IN_BPS;
        tempIncome._protocolIncome += uint128(protocolFee);

        uint256 valueForPool = value - protocolFee;

        uint256 ownerIncome = (valueForPool * _poolConfig._rewardRateInBpsForPoolOwner) /
            HUNDRED_PERCENT_IN_BPS;
        tempIncome._poolOwnerIncome += uint128(ownerIncome);

        uint256 eaIncome = (valueForPool * _poolConfig._rewardRateInBpsForEA) /
            HUNDRED_PERCENT_IN_BPS;
        tempIncome._eaIncome += uint128(eaIncome);

        _accuredIncome = tempIncome;

        poolIncome = (valueForPool - ownerIncome - eaIncome);

        emit IncomeDistributed(protocolFee, ownerIncome, eaIncome, poolIncome);
    }

    function reverseIncome(uint256 value) external returns (uint256 poolIncome) {
        if (msg.sender != pool) {
            revert Errors.notPool();
        }

        AccruedIncome memory tempIncome = _accuredIncome;

        uint256 protocolFee = (uint256(humaConfig.protocolFee()) * value) / HUNDRED_PERCENT_IN_BPS;
        tempIncome._protocolIncome -= uint128(protocolFee);

        uint256 valueForPool = value - protocolFee;

        uint256 ownerIncome = (valueForPool * _poolConfig._rewardRateInBpsForPoolOwner) /
            HUNDRED_PERCENT_IN_BPS;
        tempIncome._poolOwnerIncome -= uint128(ownerIncome);

        uint256 eaIncome = (valueForPool * _poolConfig._rewardRateInBpsForEA) /
            HUNDRED_PERCENT_IN_BPS;
        tempIncome._eaIncome -= uint128(eaIncome);

        _accuredIncome = tempIncome;

        poolIncome = (valueForPool - ownerIncome - eaIncome);

        emit IncomeReversed(protocolFee, ownerIncome, eaIncome, poolIncome);
    }

    /**
     * @notice change the default APR for the pool
     * @param aprInBps APR in basis points, use 500 for 5%
     */
    function setAPR(uint256 aprInBps) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (aprInBps > HUNDRED_PERCENT_IN_BPS) revert Errors.invalidBasisPointHigherThan10000();
        _poolConfig._poolAprInBps = aprInBps;
        emit APRChanged(aprInBps, msg.sender);
    }

    function setCreditApprovalExpiration(uint256 durationInDays) external {
        _onlyOwnerOrHumaMasterAdmin();
        _poolConfig._creditApprovalExpirationInSeconds = durationInDays * SECONDS_IN_A_DAY;
        emit CreditApprovalExpirationChanged(durationInDays * SECONDS_IN_A_DAY, msg.sender);
    }

    function setEARewardsAndLiquidity(uint256 rewardsRate, uint256 liquidityRate) external {
        _onlyOwnerOrHumaMasterAdmin();

        if (rewardsRate > HUNDRED_PERCENT_IN_BPS || liquidityRate > HUNDRED_PERCENT_IN_BPS)
            revert Errors.invalidBasisPointHigherThan10000();
        _poolConfig._rewardRateInBpsForEA = rewardsRate;
        _poolConfig._liquidityRateInBpsByEA = liquidityRate;
        emit EARewardsAndLiquidityChanged(rewardsRate, liquidityRate, msg.sender);
    }

    /**
     * @notice Adds an evaluation agent to the list who can approve loans.
     * @param agent the evaluation agent to be added
     */
    function setEvaluationAgent(uint256 eaId, address agent) external {
        if (agent == address(0)) revert Errors.zeroAddressProvided();
        _onlyOwnerOrHumaMasterAdmin();

        if (IERC721(HumaConfig(humaConfig).eaNFTContractAddress()).ownerOf(eaId) != agent)
            revert Errors.proposedEADoesNotOwnProvidedEANFT();

        // Make sure the new EA has met the liquidity requirements
        if (BasePool(pool).isPoolOn()) {
            checkLiquidityRequirementForEA(poolToken.withdrawableFundsOf(agent));
        }

        // Transfer the accrued EA income to the old EA's wallet.
        // Decided not to check if there is enough balance in the pool. If there is
        // not enough balance, the transaction will fail. PoolOwner has to find enough
        // liquidity to pay the EA before replacing it.
        address oldEA = evaluationAgent;
        evaluationAgent = agent;
        evaluationAgentId = eaId;

        if (oldEA != address(0)) {
            uint256 rewardsToPayout = _accuredIncome._eaIncome -
                _accuredWithdrawn._eaIncomeWithdrawn;
            if (rewardsToPayout > 0) {
                _withdrawEAFee(msg.sender, oldEA, rewardsToPayout);
            }
        }

        emit EvaluationAgentChanged(oldEA, agent, eaId, msg.sender);
    }

    function setFeeManager(address _feeManager) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (_feeManager == address(0)) revert Errors.zeroAddressProvided();
        feeManager = _feeManager;
        emit FeeManagerChanged(_feeManager, msg.sender);
    }

    function setHumaConfig(address _humaConfig) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (_humaConfig == address(0)) revert Errors.zeroAddressProvided();
        humaConfig = HumaConfig(_humaConfig);
        emit HumaConfigChanged(_humaConfig, msg.sender);
    }

    /**
     * @notice Sets the min and max of each loan/credit allowed by the pool.
     * @param creditLine the max amount of a credit line
     */
    function setMaxCreditLine(uint256 creditLine) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (creditLine == 0) revert Errors.zeroAmountProvided();
        if (creditLine >= 2**88) revert Errors.creditLineTooHigh();
        _poolConfig._maxCreditLine = uint88(creditLine);
        emit MaxCreditLineChanged(creditLine, msg.sender);
    }

    function setPool(address _pool) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (_pool == address(0)) revert Errors.zeroAddressProvided();
        pool = _pool;
        emit PoolChanged(_pool, msg.sender);
    }

    /**
     * Sets the default grace period for this pool.
     * @param gracePeriodInDays the desired grace period in days.
     */
    function setPoolDefaultGracePeriod(uint256 gracePeriodInDays) external {
        _onlyOwnerOrHumaMasterAdmin();
        _poolConfig._poolDefaultGracePeriodInSeconds = gracePeriodInDays * SECONDS_IN_A_DAY;
        emit PoolDefaultGracePeriodChanged(gracePeriodInDays, msg.sender);
    }

    /**
     * @notice Sets the cap of the pool liquidity.
     * @param liquidityCap the upper bound that the pool accepts liquidity from the depositors
     */
    function setPoolLiquidityCap(uint256 liquidityCap) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (liquidityCap == 0) revert Errors.zeroAmountProvided();
        _poolConfig._liquidityCap = liquidityCap;
        emit PoolLiquidityCapChanged(liquidityCap, msg.sender);
    }

    function setPoolOwnerRewardsAndLiquidity(uint256 rewardsRate, uint256 liquidityRate) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (rewardsRate > HUNDRED_PERCENT_IN_BPS || liquidityRate > HUNDRED_PERCENT_IN_BPS)
            revert Errors.invalidBasisPointHigherThan10000();

        _poolConfig._rewardRateInBpsForPoolOwner = rewardsRate;
        _poolConfig._liquidityRateInBpsByPoolOwner = liquidityRate;
        emit PoolOwnerRewardsAndLiquidityChanged(rewardsRate, liquidityRate, msg.sender);
    }

    function setPoolPayPeriod(uint256 periodInDays) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (periodInDays == 0) revert Errors.zeroAmountProvided();
        _poolConfig._payPeriodInDays = periodInDays;
        emit PoolPayPeriodChanged(periodInDays, msg.sender);
    }

    /**
     * @notice Change pool name
     */
    function setPoolName(string memory newName) external {
        _onlyOwnerOrHumaMasterAdmin();
        poolName = newName;
        emit PoolNameChanged(newName, msg.sender);
    }

    function setPoolOwnerTreasury(address _poolOwnerTreasury) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (_poolOwnerTreasury == address(0)) revert Errors.zeroAddressProvided();
        poolOwnerTreasury = _poolOwnerTreasury;
        emit PoolOwnerTreasuryChanged(_poolOwnerTreasury, msg.sender);
    }

    function setPoolToken(address _poolToken) external {
        _onlyOwnerOrHumaMasterAdmin();
        if (_poolToken == address(0)) revert Errors.zeroAddressProvided();
        poolToken = HDT(_poolToken);
        address assetToken = poolToken.assetToken();
        underlyingToken = IERC20(poolToken.assetToken());
        emit HDTChanged(_poolToken, assetToken, msg.sender);
    }

    /**
     * @notice Set the receivable rate in terms of basis points.
     * When the rate is higher than 10000, it means the backing is higher than the borrow amount,
     * similar to an over-collateral situation.
     * @param receivableInBps the percentage. A percentage over 10000 means overreceivableization.
     */
    function setReceivableRequiredInBps(uint256 receivableInBps) external {
        _onlyOwnerOrHumaMasterAdmin();
        // note: this rate can be over 10000 when it requires more backing than the credit limit
        _poolConfig._receivableRequiredInBps = receivableInBps;
        emit ReceivableRequiredInBpsChanged(receivableInBps, msg.sender);
    }

    /**
     * Sets withdrawal lockout period after the lender makes the last deposit
     * @param lockoutPeriodInDays the lockout period in terms of days
     */
    function setWithdrawalLockoutPeriod(uint256 lockoutPeriodInDays) external {
        _onlyOwnerOrHumaMasterAdmin();
        _poolConfig._withdrawalLockoutPeriodInSeconds = lockoutPeriodInDays * SECONDS_IN_A_DAY;
        emit WithdrawalLockoutPeriodChanged(lockoutPeriodInDays, msg.sender);
    }

    function withdrawEAFee(uint256 amount) external {
        // Either Pool owner or EA can trigger reward withdraw for EA.
        // When it is triggered by pool owner, the fund still flows to the EA's account.
        onlyPoolOwnerOrEA(msg.sender);
        if (amount == 0) revert Errors.zeroAmountProvided();
        if (amount + _accuredWithdrawn._eaIncomeWithdrawn > _accuredIncome._eaIncome)
            revert Errors.withdrawnAmountHigherThanBalance();
        // Note: the transfer can only goes to evaluationAgent
        _withdrawEAFee(msg.sender, evaluationAgent, amount);
    }

    function withdrawPoolOwnerFee(uint256 amount) external {
        onlyPoolOwnerTreasury(msg.sender);
        if (amount == 0) revert Errors.zeroAmountProvided();
        if (amount + _accuredWithdrawn._poolOwnerIncomeWithdrawn > _accuredIncome._poolOwnerIncome)
            revert Errors.withdrawnAmountHigherThanBalance();
        _accuredWithdrawn._poolOwnerIncomeWithdrawn += uint128(amount);
        underlyingToken.safeTransferFrom(pool, msg.sender, amount);
        emit PoolRewardsWithdrawn(msg.sender, amount);
    }

    function withdrawProtocolFee(uint256 amount) external {
        if (msg.sender != humaConfig.owner()) revert Errors.notProtocolOwner();
        if (amount + _accuredWithdrawn._protocolIncomeWithdrawn > _accuredIncome._protocolIncome)
            revert Errors.withdrawnAmountHigherThanBalance();
        _accuredWithdrawn._protocolIncomeWithdrawn += uint128(amount);
        address treasuryAddress = humaConfig.humaTreasury();
        // It is possible that Huma protocolTreasury is missed in the setup. If that happens,
        // the transaction is reverted. The protocol owner can still withdraw protocol fee
        // after protocolTreasury is configured in HumaConfig.
        assert(treasuryAddress != address(0));
        underlyingToken.safeTransferFrom(pool, treasuryAddress, amount);
        emit ProtocolRewardsWithdrawn(treasuryAddress, amount, msg.sender);
    }

    function accruedIncome()
        external
        view
        returns (
            uint256 protocolIncome,
            uint256 poolOwnerIncome,
            uint256 eaIncome,
            uint256 protocolIncomeWithdrawn,
            uint256 poolOwnerIncomeWithdrawn,
            uint256 eaIncomeWithdrawn
        )
    {
        return (
            _accuredIncome._protocolIncome,
            _accuredIncome._poolOwnerIncome,
            _accuredIncome._eaIncome,
            _accuredWithdrawn._protocolIncomeWithdrawn,
            _accuredWithdrawn._poolOwnerIncomeWithdrawn,
            _accuredWithdrawn._eaIncomeWithdrawn
        );
    }

    function checkLiquidityRequirementForPoolOwner(uint256 balance) public view {
        if (
            balance <
            (_poolConfig._liquidityCap * _poolConfig._liquidityRateInBpsByPoolOwner) /
                HUNDRED_PERCENT_IN_BPS
        ) revert Errors.poolOwnerNotEnoughLiquidity();
    }

    function checkLiquidityRequirementForEA(uint256 balance) public view {
        if (
            balance <
            (_poolConfig._liquidityCap * _poolConfig._liquidityRateInBpsByEA) /
                HUNDRED_PERCENT_IN_BPS
        ) revert Errors.evaluationAgentNotEnoughLiquidity();
    }

    /// Checks to make sure both EA and pool owner treasury meet the pool's liquidity requirements
    function checkLiquidityRequirement() public view {
        checkLiquidityRequirementForPoolOwner(poolToken.withdrawableFundsOf(poolOwnerTreasury));
        checkLiquidityRequirementForEA(poolToken.withdrawableFundsOf(evaluationAgent));
    }

    /// When the pool owner treasury or EA wants to withdraw liquidity from the pool,
    /// checks to make sure the remaining liquidity meets the pool's requirements
    function checkWithdrawLiquidityRequirement(address lender, uint256 newBalance) public view {
        if (lender == evaluationAgent) {
            checkLiquidityRequirementForEA(newBalance);
        } else if (lender == poolOwnerTreasury) {
            // note poolOwnerTreasury handles all thing financial-related for pool owner
            checkLiquidityRequirementForPoolOwner(newBalance);
        }
    }

    function creditApprovalExpirationInSeconds() external view returns (uint256) {
        return _poolConfig._creditApprovalExpirationInSeconds;
    }

    function getCoreData()
        external
        view
        returns (
            address underlyingToken_,
            address poolToken_,
            address humaConfig_,
            address feeManager_
        )
    {
        underlyingToken_ = address(underlyingToken);
        poolToken_ = address(poolToken);
        humaConfig_ = address(humaConfig);
        feeManager_ = feeManager;
    }

    /**
     * Returns a summary information of the pool.
     * @return token the address of the pool token
     * @return apr the default APR of the pool
     * @return payPeriod the standard pay period for the pool
     * @return maxCreditAmount the max amount for the credit line
     */
    function getPoolSummary()
        external
        view
        returns (
            address token,
            uint256 apr,
            uint256 payPeriod,
            uint256 maxCreditAmount,
            uint256 liquiditycap,
            string memory name,
            string memory symbol,
            uint8 decimals,
            uint256 eaId,
            address eaNFTAddress
        )
    {
        IERC20Metadata erc20Contract = IERC20Metadata(address(underlyingToken));
        return (
            address(underlyingToken),
            _poolConfig._poolAprInBps,
            _poolConfig._payPeriodInDays,
            _poolConfig._maxCreditLine,
            _poolConfig._liquidityCap,
            erc20Contract.name(),
            erc20Contract.symbol(),
            erc20Contract.decimals(),
            evaluationAgentId,
            humaConfig.eaNFTContractAddress()
        );
    }

    function isPoolOwnerTreasuryOrEA(address account) public view returns (bool) {
        return (account == poolOwnerTreasury || account == evaluationAgent);
    }

    /// Reports if a given user account is an approved operator or not
    function isOperator(address account) external view returns (bool) {
        return poolOperators[account];
    }

    function maxCreditLine() external view returns (uint256) {
        return _poolConfig._maxCreditLine;
    }

    function onlyPoolOwner(address account) public view {
        if (account != owner()) revert Errors.notPoolOwner();
    }

    function onlyPoolOwnerTreasury(address account) public view {
        if (account != poolOwnerTreasury) revert Errors.notPoolOwnerTreasury();
    }

    /// "Modifier" function that limits access to pool owner or EA.
    function onlyPoolOwnerOrEA(address account) public view {
        if (account != owner() && account != evaluationAgent) revert Errors.notPoolOwnerOrEA();
    }

    /// "Modifier" function that limits access to pool owner treasury or EA.
    function onlyPoolOwnerTreasuryOrEA(address account) public view {
        if (!isPoolOwnerTreasuryOrEA(account)) revert Errors.notPoolOwnerTreasuryOrEA();
    }

    function payPeriodInDays() external view returns (uint256) {
        return _poolConfig._payPeriodInDays;
    }

    function poolAprInBps() external view returns (uint256) {
        return _poolConfig._poolAprInBps;
    }

    function poolDefaultGracePeriodInSeconds() external view returns (uint256) {
        return _poolConfig._poolDefaultGracePeriodInSeconds;
    }

    function poolLiquidityCap() external view returns (uint256) {
        return _poolConfig._liquidityCap;
    }

    function receivableRequiredInBps() external view returns (uint256) {
        return _poolConfig._receivableRequiredInBps;
    }

    /**
     * @notice Removes a pool operator.
     * @param _operator Address to be removed from the operator list
     * @dev If address(0) is provided, revert with "zeroAddressProvided()"
     * @dev If the address is not currently a operator, revert w/ "notOperator()"
     * @dev Emits a PoolOperatorRemoved event.
     */
    function removePoolOperator(address _operator) external onlyOwner {
        if (_operator == address(0)) revert Errors.zeroAddressProvided();
        if (!poolOperators[_operator]) revert Errors.notOperator();

        poolOperators[_operator] = false;

        emit PoolOperatorRemoved(_operator, msg.sender);
    }

    function rewardsAndLiquidityRateForEA()
        external
        view
        returns (uint256 rewardRateInBpsForEA, uint256 liquidityRateInBpsByEA)
    {
        return (_poolConfig._rewardRateInBpsForEA, _poolConfig._liquidityRateInBpsByEA);
    }

    function rewardsAndLiquidityRateForPoolOwner()
        external
        view
        returns (uint256 rewardRateInBpsForPoolOwner, uint256 liquidityRateInBpsByPoolOwner)
    {
        return (
            _poolConfig._rewardRateInBpsForPoolOwner,
            _poolConfig._liquidityRateInBpsByPoolOwner
        );
    }

    function withdrawalLockoutPeriodInSeconds() external view returns (uint256) {
        return _poolConfig._withdrawalLockoutPeriodInSeconds;
    }

    // Allow for sensitive pool functions only to be called by
    // the pool owner and the huma master admin
    function onlyOwnerOrHumaMasterAdmin(address account) public view {
        if (account != owner() && account != humaConfig.owner()) {
            revert Errors.permissionDeniedNotAdmin();
        }
    }

    function _withdrawEAFee(
        address caller,
        address receiver,
        uint256 amount
    ) internal {
        _accuredWithdrawn._eaIncomeWithdrawn += uint96(amount);
        underlyingToken.safeTransferFrom(pool, receiver, amount);

        emit EvaluationAgentRewardsWithdrawn(receiver, amount, caller);
    }

    /// "Modifier" function that limits access to pool owner or Huma protocol owner
    function _onlyOwnerOrHumaMasterAdmin() internal view {
        onlyOwnerOrHumaMasterAdmin(msg.sender);
    }
}