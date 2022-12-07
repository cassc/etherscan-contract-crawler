// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./interfaces/ILiquidityProvider.sol";
import "./interfaces/IPool.sol";

import "./BasePoolStorage.sol";
import "./Errors.sol";
import "./EvaluationAgentNFT.sol";
import "./HDT/HDT.sol";
import "./HumaConfig.sol";

import "hardhat/console.sol";

abstract contract BasePool is Initializable, BasePoolStorage, ILiquidityProvider, IPool {
    using SafeERC20 for IERC20;

    event LiquidityDeposited(address indexed account, uint256 assetAmount, uint256 shareAmount);
    event LiquidityWithdrawn(address indexed account, uint256 assetAmount, uint256 shareAmount);

    event PoolConfigChanged(address indexed sender, address newPoolConfig);
    event PoolCoreDataChanged(
        address indexed sender,
        address underlyingToken,
        address poolToken,
        address humaConfig,
        address feeManager
    );

    event PoolDisabled(address indexed by);
    event PoolEnabled(address indexed by);

    event AddApprovedLender(address indexed lender, address by);
    event RemoveApprovedLender(address indexed lender, address by);

    /**
     * @dev This event emits when new losses are distributed
     * @param lossesDistributed the amount of losses by the pool
     */
    event LossesDistributed(uint256 lossesDistributed, uint256 updatedPoolValue);

    constructor() {
        _disableInitializers();
    }

    function initialize(address poolConfigAddr) external initializer {
        _poolConfig = BasePoolConfig(poolConfigAddr);
        _updateCoreData();

        // note approve max amount to pool config for admins to withdraw their rewards
        _safeApproveForPoolConfig(type(uint256).max);

        // All pools are off when initiated, will turn on after admins' initial deposits
        _status = PoolStatus.Off;
    }

    //********************************************/
    //               LP Functions                //
    //********************************************/
    /**
     * @notice LP deposits to the pool to earn interest, and share losses
     *
     * @notice All deposits should be made by calling this function and
     * makeInitialDeposit() (for pool owner and EA's initial deposit) only.
     * Please do NOT directly transfer any digital assets to the contracts,
     * which will cause a permanent loss and we cannot help reverse transactions
     * or retrieve assets from the contracts.
     *
     * @param amount the number of underlyingToken to be deposited
     */
    function deposit(uint256 amount) external virtual override {
        _protocolAndPoolOn();
        return _deposit(msg.sender, amount);
    }

    /**
     * @notice Allows the pool owner and EA to make initial deposit before the pool goes live
     * @param amount the number of `poolToken` to be deposited
     */
    function makeInitialDeposit(uint256 amount) external virtual override {
        _poolConfig.onlyPoolOwnerTreasuryOrEA(msg.sender);
        return _deposit(msg.sender, amount);
    }

    /**
     * @notice Withdraw capital from the pool in the unit of underlyingToken
     * @dev Withdrawals are not allowed when 1) the pool withdraw is paused or
     *      2) the LP has not reached lockout period since their last depsit
     *      3) the requested amount is higher than the LP's remaining principal
     * @dev the `amount` is total amount to withdraw, not the number of HDT shares,
     * which will be computed based on the current price per share
     */
    function withdraw(uint256 amount) public virtual override {
        _protocolAndPoolOn();
        if (amount == 0) revert Errors.zeroAmountProvided();
        if (
            block.timestamp <
            _lastDepositTime[msg.sender] + _poolConfig.withdrawalLockoutPeriodInSeconds()
        ) revert Errors.withdrawTooSoon();

        uint256 withdrawableAmount = _poolToken.withdrawableFundsOf(msg.sender);
        if (amount > withdrawableAmount) revert Errors.withdrawnAmountHigherThanBalance();

        _poolConfig.checkWithdrawLiquidityRequirement(msg.sender, withdrawableAmount - amount);

        uint256 shares = _poolToken.burnAmount(msg.sender, amount);
        _totalPoolValue -= amount;
        _underlyingToken.safeTransfer(msg.sender, amount);

        emit LiquidityWithdrawn(msg.sender, amount, shares);
    }

    /**
     * @notice Withdraw all balance from the pool.
     */
    function withdrawAll() external virtual override {
        withdraw(_poolToken.withdrawableFundsOf(msg.sender));
    }

    function _deposit(address lender, uint256 amount) internal {
        if (amount == 0) revert Errors.zeroAmountProvided();
        _onlyApprovedLender(lender);

        if (_totalPoolValue + amount > _poolConfig.poolLiquidityCap())
            revert Errors.exceededPoolLiquidityCap();

        uint256 shares = _poolToken.mintAmount(lender, amount);
        _lastDepositTime[lender] = block.timestamp;
        _totalPoolValue += amount;
        _underlyingToken.safeTransferFrom(lender, address(this), amount);

        emit LiquidityDeposited(lender, amount, shares);
    }

    /**
     * @notice Distributes income to token holders.
     */
    function distributeIncome(uint256 value) internal virtual {
        uint256 poolIncome = _poolConfig.distributeIncome(value);
        _totalPoolValue += poolIncome;
    }

    /**
     * @notice Distributes losses associated with the token.
     * Note: The pool (i.e. LPs) is responsible for the losses in a default. The protocol does not
     * participate in loss distribution. PoolOwner and EA only participate in their LP capacity.
     * @param value the amount of losses to be distributed
     * @dev We chose not to change distributeIncome to accepted int256 to cover losses for
     * readability consideration.
     * @dev It does not make sense to combine reserveIncome() and distributeLosses() since protocol,
     * poolOwner and EA do not participate in losses, but they participate in income reverse.
     */
    function distributeLosses(uint256 value) internal virtual {
        if (_totalPoolValue > value) _totalPoolValue -= value;
        else _totalPoolValue = 0;
        emit LossesDistributed(value, _totalPoolValue);
    }

    /**
     * @notice Reverse income to token holders.
     * @param value the amount of income to be reverted
     * @dev this is needed when the user pays off early. We collect and distribute interest
     * at the beginning of the pay period. When the user pays off early, the interest
     * for the remainder of the period will be automatically subtraced from the payoff amount.
     * The portion of the income will be reversed. We can also change the parameter of
     * distributeIncome to int256. Choose to use a separate function for better readability.
     */
    function reverseIncome(uint256 value) internal virtual {
        uint256 poolIncome = _poolConfig.reverseIncome(value);
        if (_totalPoolValue > poolIncome) _totalPoolValue -= poolIncome;
        else _totalPoolValue = 0;
    }

    //********************************************/
    //            Admin Functions                //
    //********************************************/

    /**
     * @notice Lenders need to pass compliance requirements. Pool operator will administer off-chain
     * to make sure potential lenders meet the requirements. Afterwords, the pool operator will
     * call this function to mark a lender as approved.
     */
    function addApprovedLender(address lender) external virtual override {
        _onlyPoolOperator();
        _approvedLenders[lender] = true;
        emit AddApprovedLender(lender, msg.sender);
    }

    /**
     * @notice turns off the pool. Any pool operator can do so when they see abnormalities.
     */
    function disablePool() external virtual override {
        _onlyPoolOperator();
        _status = PoolStatus.Off;
        emit PoolDisabled(msg.sender);
    }

    /**
     * @notice turns on the pool. Only the pool owner or protocol owner can enable a pool.
     */
    function enablePool() external virtual override {
        _onlyOwnerOrHumaMasterAdmin();

        _poolConfig.checkLiquidityRequirement();

        _status = PoolStatus.On;
        emit PoolEnabled(msg.sender);
    }

    /**
     * @notice Disables a lender. This prevents the lender from making more deposits.
     * The capital that the lender has contributed can continue to work as normal.
     */
    function removeApprovedLender(address lender) external virtual override {
        _onlyPoolOperator();
        _approvedLenders[lender] = false;
        emit RemoveApprovedLender(lender, msg.sender);
    }

    /**
     * @notice Points the pool configuration to PoolConfig contract
     */
    function setPoolConfig(address poolConfigAddr) external override {
        _onlyOwnerOrHumaMasterAdmin();
        address oldConfig = address(_poolConfig);
        if (poolConfigAddr == oldConfig) revert Errors.sameValue();

        // note set old pool config allowance to 0
        _safeApproveForPoolConfig(0);

        BasePoolConfig newPoolConfig = BasePoolConfig(poolConfigAddr);
        newPoolConfig.onlyOwnerOrHumaMasterAdmin(msg.sender);

        _poolConfig = newPoolConfig;

        // note approve max amount to pool config for admin withdraw functions
        _safeApproveForPoolConfig(type(uint256).max);

        emit PoolConfigChanged(msg.sender, poolConfigAddr);
    }

    /**
     * @notice Updates references to core supporting contracts: underlying token, pool token,
     * Huma Config, and Fee Manager.
     */
    function updateCoreData() external {
        _onlyOwnerOrHumaMasterAdmin();
        _updateCoreData();
    }

    /**
     * @notice Gets the address of core supporting contracts: underlying token, pool token,
     * Huma Config, and Fee Manager.
     */
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
        underlyingToken_ = address(_underlyingToken);
        poolToken_ = address(_poolToken);
        humaConfig_ = address(_humaConfig);
        feeManager_ = address(_feeManager);
    }

    /// Reports if the given account has been approved as a lender for this pool
    function isApprovedLender(address account) external view virtual override returns (bool) {
        return _approvedLenders[account];
    }

    /// Gets the on/off status of the pool
    function isPoolOn() external view virtual override returns (bool status) {
        if (_status == PoolStatus.On) return true;
        else return false;
    }

    /// Gets the last deposit time of the given lender
    function lastDepositTime(address account) external view virtual override returns (uint256) {
        return _lastDepositTime[account];
    }

    /// Gets the address of poolConfig
    function poolConfig() external view virtual override returns (address) {
        return address(_poolConfig);
    }

    /// Gets the total value of the pool, measured by the units of underlying token
    function totalPoolValue() external view override returns (uint256) {
        return _totalPoolValue;
    }

    /**
     * @notice In PoolConfig, the admins (protocol, pool owner, EA) can withdraw the rewards
     * that they have earned so far. This gives allowance for PoolConfig to enable such withdraw.
     */
    function _safeApproveForPoolConfig(uint256 amount) internal {
        address config = address(_poolConfig);
        uint256 allowance = _underlyingToken.allowance(address(this), config);

        // Call safeApprove when the allowance is changed from >0 to 0, or from 0 to >0.
        if ((amount == 0 && allowance > 0) || (amount > 0 && allowance == 0)) {
            _underlyingToken.safeApprove(config, amount);
        }
    }

    /// Refreshes the cache of addresses for key contracts using the current data in PoolConfig
    function _updateCoreData() private {
        (
            address underlyingTokenAddr,
            address poolTokenAddr,
            address humaConfigAddr,
            address feeManagerAddr
        ) = _poolConfig.getCoreData();
        _underlyingToken = IERC20(underlyingTokenAddr);
        _poolToken = IHDT(poolTokenAddr);
        _humaConfig = HumaConfig(humaConfigAddr);
        _feeManager = BaseFeeManager(feeManagerAddr);

        emit PoolCoreDataChanged(
            msg.sender,
            underlyingTokenAddr,
            poolTokenAddr,
            humaConfigAddr,
            feeManagerAddr
        );
    }

    /// "Modifier" function that limits access only when both protocol and pool are on.
    /// Did not use modifier for contract size consideration.
    function _protocolAndPoolOn() internal view {
        if (_humaConfig.paused()) revert Errors.protocolIsPaused();
        if (_status != PoolStatus.On) revert Errors.poolIsNotOn();
    }

    /// "Modifier" function that limits access to approved lenders only.
    function _onlyApprovedLender(address lender) internal view {
        if (!_approvedLenders[lender]) revert Errors.permissionDeniedNotLender();
    }

    /// "Modifier" function that limits access to pool owner or protocol owner
    function _onlyOwnerOrHumaMasterAdmin() internal view {
        _poolConfig.onlyOwnerOrHumaMasterAdmin(msg.sender);
    }

    /// "Modifier" function that limits access to pool operators only
    function _onlyPoolOperator() internal view {
        if (!_poolConfig.isOperator(msg.sender)) revert Errors.poolOperatorRequired();
    }
}