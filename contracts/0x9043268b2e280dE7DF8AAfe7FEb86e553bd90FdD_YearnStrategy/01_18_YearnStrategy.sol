// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {PercentMath} from "../../lib/PercentMath.sol";
import {ERC165Query} from "../../lib/ERC165Query.sol";
import {IStrategy} from "../IStrategy.sol";
import {CustomErrors} from "../../interfaces/CustomErrors.sol";
import {IYearnVault} from "../../interfaces/yearn/IYearnVault.sol";
import {IVault} from "../../vault/IVault.sol";

/**
 * YearnStrategy generates yield by investing into a Yearn vault.
 *
 * @notice This strategy is syncrhonous (supports immediate withdrawals).
 */
contract YearnStrategy is IStrategy, AccessControl, CustomErrors {
    using SafeERC20 for IERC20;
    using PercentMath for uint256;
    using ERC165Query for address;

    /**
     * Emmited when the maxLossOnWithdraw (from Yearn vault) is changed.
     *
     * @param maxLoss new value for max loss withdraw param
     */
    event StrategyMaxLossOnWithdrawChanged(uint256 maxLoss);

    // yearn vault is 0x
    error StrategyYearnVaultCannotBe0Address();
    // max loss on withdraw from yearn > 100%
    error StrategyMaxLossOnWithdrawTooLarge();

    /// role allowed to invest/withdraw from yearn vault
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    /// role allowed to change settings such as max loss on withdraw from yearn vault
    bytes32 public constant SETTINGS_ROLE = keccak256("SETTINGS_ROLE");
    // underlying ERC20 token
    IERC20 public immutable underlying;
    /// @inheritdoc IStrategy
    address public immutable override(IStrategy) vault;
    // yearn vault that this strategy is interacting with
    IYearnVault public immutable yVault;
    // multiplier for underlying convertion to shares
    uint128 public immutable conversionMultiplier;
    // used when withdrawing from yearn vault, 1 = 0.01%
    uint128 public maxLossOnWithdraw = 1;

    /**
     * @param _vault address of the vault that will use this strategy
     * @param _admin address of the administrator account for this strategy
     * @param _yVault address of the yearn vault that this strategy is using
     * @param _underlying address of the underlying token
     */
    constructor(
        address _vault,
        address _admin,
        address _yVault,
        address _underlying
    ) {
        if (_admin == address(0)) revert StrategyAdminCannotBe0Address();
        if (_yVault == address(0)) revert StrategyYearnVaultCannotBe0Address();
        if (_underlying == address(0))
            revert StrategyUnderlyingCannotBe0Address();

        if (!_vault.doesContractImplementInterface(type(IVault).interfaceId))
            revert StrategyNotIVault();

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(SETTINGS_ROLE, _admin);
        _setupRole(MANAGER_ROLE, _vault);

        vault = _vault;
        yVault = IYearnVault(_yVault);
        conversionMultiplier = uint128(10**yVault.decimals());

        underlying = IERC20(_underlying);

        underlying.approve(_yVault, type(uint256).max);
    }

    //
    // Modifiers
    //

    modifier onlyManager() {
        if (!hasRole(MANAGER_ROLE, msg.sender))
            revert StrategyCallerNotManager();
        _;
    }

    modifier onlySettings() {
        if (!hasRole(SETTINGS_ROLE, msg.sender))
            revert StrategyCallerNotSettings();
        _;
    }

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
            revert StrategyCallerNotAdmin();
        _;
    }

    /**
     * Transfers administrator rights for the Strategy to another account,
     * revoking current admin roles and setting up the roles for the new admin.
     *
     * @notice Can only be called by the account with the ADMIN role.
     *
     * @param _newAdmin The new Strategy admin account.
     */
    function transferAdminRights(address _newAdmin) external onlyAdmin {
        if (_newAdmin == address(0x0)) revert StrategyAdminCannotBe0Address();
        if (_newAdmin == msg.sender)
            revert StrategyCannotTransferAdminRightsToSelf();

        _setupRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        _setupRole(SETTINGS_ROLE, _newAdmin);

        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _revokeRole(SETTINGS_ROLE, msg.sender);
    }

    /**
     * Yearn strategy is synchronous meaning it supports immediate withdrawals.
     *
     * @return true always
     */
    function isSync() external pure override(IStrategy) returns (bool) {
        return true;
    }

    /// @inheritdoc IStrategy
    function hasAssets()
        external
        view
        virtual
        override(IStrategy)
        returns (bool)
    {
        return _getShares() != 0;
    }

    /// @inheritdoc IStrategy
    function investedAssets()
        external
        view
        virtual
        override(IStrategy)
        returns (uint256)
    {
        return _sharesToUnderlying(_getShares()) + _getUnderlyingBalance();
    }

    /// @inheritdoc IStrategy
    function invest() external virtual override(IStrategy) onlyManager {
        uint256 beforeBalance = _getUnderlyingBalance();
        if (beforeBalance == 0) revert StrategyNoUnderlying();

        yVault.deposit(type(uint256).max, address(this));

        uint256 afterBalance = _getUnderlyingBalance();

        emit StrategyInvested(beforeBalance - afterBalance);
    }

    /// @inheritdoc IStrategy
    function withdrawToVault(uint256 _amount)
        external
        virtual
        override(IStrategy)
        onlyManager
    {
        if (_amount == 0) revert StrategyAmountZero();
        uint256 uninvestedUnderlying = _getUnderlyingBalance();

        if (_amount > uninvestedUnderlying) {
            uint256 sharesToWithdraw = _underlyingToShares(
                _amount - uninvestedUnderlying
            );

            if (sharesToWithdraw > _getShares())
                revert StrategyNotEnoughShares();

            // burn shares and withdraw required underlying to strategy
            uint256 withdrawnFromYearn = yVault.withdraw(
                sharesToWithdraw,
                address(this),
                maxLossOnWithdraw
            );

            _amount = uninvestedUnderlying + withdrawnFromYearn;
        }

        // transfer underlying to vault
        underlying.safeTransfer(vault, _amount);

        emit StrategyWithdrawn(_amount);
    }

    /**
     * Sets the max loss percentage used when withdrawing from the Yearn vault.
     *
     * @notice Can only be called by the account with settings role.
     *
     * @param _maxLoss The max loss percentage to use when withdrawing from the Yearn vault. Value of 1 equals 0.01% loss.
     */
    function setMaxLossOnWithdraw(uint128 _maxLoss) external onlySettings {
        if (_maxLoss > 10000) revert StrategyMaxLossOnWithdrawTooLarge();

        maxLossOnWithdraw = _maxLoss;

        emit StrategyMaxLossOnWithdrawChanged(_maxLoss);
    }

    /**
     * Get the underlying balance of the strategy.
     *
     * @return underlying balance of the strategy
     */
    function _getUnderlyingBalance() internal view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    /**
     * Get the number of yearn vault shares owned by the strategy.
     *
     * @return shares owned by the strategy
     */
    function _getShares() internal view returns (uint256) {
        return yVault.balanceOf(address(this));
    }

    /**
     * Calculates the value of yearn vault shares in underlying.
     *
     * @param _shares number of yearn vault shares
     *
     * @return underlying value of yearn vault shares
     */
    function _sharesToUnderlying(uint256 _shares)
        internal
        view
        returns (uint256)
    {
        return (_shares * yVault.pricePerShare()) / conversionMultiplier;
    }

    /**
     * Calculates the amount of underlying in number of yearn vault shares.
     *
     * @param _underlying amount of underlying
     *
     * @return number of yearn vault shares
     */
    function _underlyingToShares(uint256 _underlying)
        internal
        view
        returns (uint256)
    {
        return (_underlying * conversionMultiplier) / yVault.pricePerShare();
    }
}