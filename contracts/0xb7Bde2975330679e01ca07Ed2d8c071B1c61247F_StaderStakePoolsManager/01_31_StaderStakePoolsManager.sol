// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import './library/UtilLib.sol';

import './ETHx.sol';
import './interfaces/IPoolUtils.sol';
import './interfaces/IPoolSelector.sol';
import './interfaces/IStaderConfig.sol';
import './interfaces/IStaderOracle.sol';
import './interfaces/IStaderPoolBase.sol';
import './interfaces/IUserWithdrawalManager.sol';
import './interfaces/IStaderStakePoolManager.sol';

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

/**
 *  @title Liquid Staking Pool Implementation
 *  Stader is a non-custodial smart contract-based staking platform
 *  that helps you conveniently discover and access staking solutions.
 *  We are building key staking middleware infra for multiple PoS networks
 * for retail crypto users, exchanges and custodians.
 */
contract StaderStakePoolsManager is
    IStaderStakePoolManager,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Math for uint256;
    using SafeMath for uint256;
    IStaderConfig public staderConfig;
    uint256 public lastExcessETHDepositBlock;
    uint256 public excessETHDepositCoolDown;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Stader initialized with following variables
     * @param _staderConfig config contract
     */
    function initialize(address _admin, address _staderConfig) external initializer {
        UtilLib.checkNonZeroAddress(_admin);
        UtilLib.checkNonZeroAddress(_staderConfig);
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        lastExcessETHDepositBlock = block.number;
        excessETHDepositCoolDown = 3 * 7200;
        staderConfig = IStaderConfig(_staderConfig);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    // protection against accidental submissions by calling non-existent function
    fallback() external payable {
        revert UnsupportedOperation();
    }

    // protection against accidental submissions by calling non-existent function
    receive() external payable {
        revert UnsupportedOperation();
    }

    // payable function for receiving execution layer rewards.
    function receiveExecutionLayerRewards() external payable override {
        emit ExecutionLayerRewardsReceived(msg.value);
    }

    // payable function for receiving user share from validator withdraw vault
    function receiveWithdrawVaultUserShare() external payable override {
        emit WithdrawVaultUserShareReceived(msg.value);
    }

    function receiveEthFromAuction() external payable override {
        emit AuctionedEthReceived(msg.value);
    }

    /**
     * @notice receive the excess ETH from Pools
     * @param _poolId ID of the pool
     */
    function receiveExcessEthFromPool(uint8 _poolId) external payable override {
        emit ReceivedExcessEthFromPool(_poolId);
    }

    /**
     * @notice transfer the ETH to user withdraw manager to finalize requests
     * @dev only user withdraw manager allowed to call
     * @param _amount amount of ETH to transfer
     */
    function transferETHToUserWithdrawManager(uint256 _amount) external override nonReentrant whenNotPaused {
        UtilLib.onlyStaderContract(msg.sender, staderConfig, staderConfig.USER_WITHDRAW_MANAGER());
        //slither-disable-next-line arbitrary-send-eth
        (bool success, ) = payable(staderConfig.getUserWithdrawManager()).call{value: _amount}('');
        if (!success) {
            revert TransferFailed();
        }
        emit TransferredETHToUserWithdrawManager(_amount);
    }

    function updateExcessETHDepositCoolDown(uint256 _excessETHDepositCoolDown) external {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        excessETHDepositCoolDown = _excessETHDepositCoolDown;
        emit UpdatedExcessETHDepositCoolDown(_excessETHDepositCoolDown);
    }

    //update the address of staderConfig
    function updateStaderConfig(address _staderConfig) external onlyRole(DEFAULT_ADMIN_ROLE) {
        UtilLib.checkNonZeroAddress(_staderConfig);
        staderConfig = IStaderConfig(_staderConfig);
        emit UpdatedStaderConfig(_staderConfig);
    }

    /**
     * @notice returns the amount of ETH equivalent 1 ETHX (with 18 decimals)
     */
    function getExchangeRate() external view override returns (uint256) {
        return
            UtilLib.computeExchangeRate(
                totalAssets(),
                IStaderOracle(staderConfig.getStaderOracle()).getExchangeRate().totalETHXSupply,
                staderConfig
            );
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view override returns (uint256) {
        return IStaderOracle(staderConfig.getStaderOracle()).getExchangeRate().totalETHBalance;
    }

    /** @dev See {IERC4626-convertToShares}. */
    function convertToShares(uint256 _assets) external view override returns (uint256) {
        return _convertToShares(_assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-convertToAssets}. */
    function convertToAssets(uint256 _shares) external view override returns (uint256) {
        return _convertToAssets(_shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-maxDeposit}. */
    function maxDeposit() public view override returns (uint256) {
        return isVaultHealthy() ? staderConfig.getMaxDepositAmount() : 0;
    }

    function minDeposit() public view override returns (uint256) {
        return isVaultHealthy() ? staderConfig.getMinDepositAmount() : 0;
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 _assets) public view override returns (uint256) {
        return _convertToShares(_assets, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(uint256 _shares) external view override returns (uint256) {
        return _convertToAssets(_shares, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-deposit}. */
    function deposit(address _receiver) external payable override whenNotPaused returns (uint256) {
        uint256 assets = msg.value;
        if (assets > maxDeposit() || assets < minDeposit()) {
            revert InvalidDepositAmount();
        }
        uint256 shares = previewDeposit(assets);
        _deposit(msg.sender, _receiver, assets, shares);
        return shares;
    }

    /**
     * @notice spinning off validators in pool `_poolId`
     * @dev gets the count of validator to deposit for pool from pool selector logic
     */
    function validatorBatchDeposit(uint8 _poolId) external override nonReentrant whenNotPaused {
        IPoolUtils poolUtils = IPoolUtils(staderConfig.getPoolUtils());
        if (!poolUtils.isExistingPoolId(_poolId)) {
            revert PoolIdDoesNotExit();
        }
        (, uint256 availableETHForNewDeposit) = SafeMath.trySub(
            address(this).balance,
            IUserWithdrawalManager(staderConfig.getUserWithdrawManager()).ethRequestedForWithdraw()
        );
        uint256 poolDepositSize = staderConfig.getStakedEthPerNode() - poolUtils.getCollateralETH(_poolId);

        if (availableETHForNewDeposit < poolDepositSize) {
            revert InsufficientBalance();
        }
        uint256 selectedPoolCapacity = IPoolSelector(staderConfig.getPoolSelector()).computePoolAllocationForDeposit(
            _poolId,
            (availableETHForNewDeposit / poolDepositSize)
        );

        if (selectedPoolCapacity == 0) {
            return;
        }
        address poolAddress = poolUtils.poolAddressById(_poolId);
        //slither-disable-next-line arbitrary-send-eth
        IStaderPoolBase(poolAddress).stakeUserETHToBeaconChain{value: selectedPoolCapacity * poolDepositSize}();
        emit ETHTransferredToPool(_poolId, poolAddress, selectedPoolCapacity * poolDepositSize);
    }

    /**
     * @notice pool selection for excess ETH supply after running `validatorBatchDeposit` for each pool
     * @dev permissionless call with cooldown period
     */
    function depositETHOverTargetWeight() external override nonReentrant {
        if (block.number < lastExcessETHDepositBlock + excessETHDepositCoolDown) {
            revert CooldownNotComplete();
        }
        IPoolUtils poolUtils = IPoolUtils(staderConfig.getPoolUtils());
        (, uint256 availableETHForNewDeposit) = SafeMath.trySub(
            address(this).balance,
            IUserWithdrawalManager(staderConfig.getUserWithdrawManager()).ethRequestedForWithdraw()
        );
        if (availableETHForNewDeposit == 0) {
            revert InsufficientBalance();
        }
        (uint256[] memory selectedPoolCapacity, uint8[] memory poolIdArray) = IPoolSelector(
            staderConfig.getPoolSelector()
        ).poolAllocationForExcessETHDeposit(availableETHForNewDeposit);

        uint256 poolCount = poolIdArray.length;
        for (uint256 i; i < poolCount; i++) {
            uint256 validatorToDeposit = selectedPoolCapacity[i];
            if (validatorToDeposit == 0) {
                continue;
            }
            address poolAddress = IPoolUtils(poolUtils).poolAddressById(poolIdArray[i]);
            uint256 poolDepositSize = staderConfig.getStakedEthPerNode() -
                IPoolUtils(poolUtils).getCollateralETH(poolIdArray[i]);

            lastExcessETHDepositBlock = block.number;
            //slither-disable-next-line arbitrary-send-eth
            IStaderPoolBase(poolAddress).stakeUserETHToBeaconChain{value: validatorToDeposit * poolDepositSize}();
            emit ETHTransferredToPool(i, poolAddress, validatorToDeposit * poolDepositSize);
        }
    }

    /**
     * @dev Triggers stopped state.
     * Contract must not be paused
     */
    function pause() external {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        _pause();
    }

    /**
     * @dev Returns to normal state.
     * Contract must be paused
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amount of shares.
     */
    function _convertToShares(uint256 _assets, Math.Rounding rounding) internal view returns (uint256) {
        uint256 supply = IStaderOracle(staderConfig.getStaderOracle()).getExchangeRate().totalETHXSupply;
        return
            (_assets == 0 || supply == 0)
                ? initialConvertToShares(_assets, rounding)
                : _assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @dev Internal conversion function (from assets to shares) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {_initialConvertToAssets} when overriding it.
     */
    function initialConvertToShares(
        uint256 _assets,
        Math.Rounding /*rounding*/
    ) internal pure returns (uint256 shares) {
        return _assets;
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 _shares, Math.Rounding rounding) internal view returns (uint256) {
        uint256 supply = IStaderOracle(staderConfig.getStaderOracle()).getExchangeRate().totalETHXSupply;
        return
            (supply == 0) ? initialConvertToAssets(_shares, rounding) : _shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) to apply when the vault is empty.
     *
     * NOTE: Make sure to keep this function consistent with {initialConvertToShares} when overriding it.
     */
    function initialConvertToAssets(
        uint256 _shares,
        Math.Rounding /*rounding*/
    ) internal pure returns (uint256) {
        return _shares;
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(
        address _caller,
        address _receiver,
        uint256 _assets,
        uint256 _shares
    ) internal {
        ETHx(staderConfig.getETHxToken()).mint(_receiver, _shares);
        emit Deposited(_caller, _receiver, _assets, _shares);
    }

    /**
     * @dev Checks if vault is "healthy" in the sense of having assets backing the circulating shares.
     */
    function isVaultHealthy() public view override returns (bool) {
        return
            (totalAssets() > 0 ||
                IStaderOracle(staderConfig.getStaderOracle()).getExchangeRate().totalETHXSupply == 0) && (!paused());
    }
}