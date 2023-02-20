// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {PercentMath} from "../../lib/PercentMath.sol";
import {IStrategy} from "../IStrategy.sol";
import {CustomErrors} from "../../interfaces/CustomErrors.sol";
import {IVault} from "../../vault/IVault.sol";
import {IVaultSponsoring} from "../../vault/IVaultSponsoring.sol";
import {IStabilityPool} from "../../interfaces/liquity/IStabilityPool.sol";
import {ERC165Query} from "../../lib/ERC165Query.sol";
import {ICurveExchange} from "../../interfaces/curve/ICurveExchange.sol";

/***
 * Liquity Strategy generates yield by investing LUSD assets into Liquity Stability Pool contract.
 * Stability pool gives out LQTY & ETH as rewards for liquidity providers.
 * The LQTY rewards are normal yield rewards
 * But the Stability Pool achievs ETH rewards by Liquidating Troves using the LUSD we deposited.
 * So our balance of LUSD goes down and we get an 1.1x (or higher) value of ETH. In short, we make a 10% profit in ETH everytime our LUSD is used for liquidation by the stability pool
 * the harvest method here withdraws those LQTY & ETH rewards, swaps them into LUSD and then deposits them back to the stability pool.
 * we should make sure to harvest at regular intervals because if the value of ETH rewards goes below 1x of the LUSD used for liquidation then we will make a net loss on our LUSD.
 * the contract uses 0xapi for swapping the tokens.
 */
contract LiquityStrategy is
    IStrategy,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    CustomErrors
{
    using PercentMath for uint256;
    using ERC165Query for address;

    error StrategyETHSwapFailed();
    error StrategyLQTYSwapFailed();
    error StrategyNotEnoughETH();
    error StrategyNotEnoughLQTY();
    error StrategyNothingToReinvest();
    error StrategyStabilityPoolCannotBe0Address();
    error StrategyCurveExchangeCannotBe0Address();
    error StrategySwapTargetCannotBe0Address();
    error StrategySwapTargetNotAllowed();
    error StrategyInsufficientOutputAmount();
    error StrategyYieldTokenCannotBe0Address();
    error StrategyMinimumAssetsProtection();

    event StrategyReinvested(uint256 amountInLUSD);

    address public constant WETH_CURVE_POOL =
        0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    address public constant LUSD_CURVE_POOL =
        0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA;
    address public constant CURVE_ROUTER =
        0x81C46fECa27B31F3ADC2b91eE4be9717d1cd3DD7;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    // role allowed to invest/withdraw assets to/from the strategy (vault)
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    // role allowed to call harvest() and reinvest()
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    // role for managing swap targets whitelist
    bytes32 public constant SETTINGS_ROLE = keccak256("SETTINGS_ROLE");

    IERC20 public underlying; // LUSD token
    /// @inheritdoc IStrategy
    address public override(IStrategy) vault;
    IStabilityPool public stabilityPool;
    IERC20 public lqty; // reward token
    mapping(address => bool) public allowedSwapTargets; // whitelist of swap targets
    ICurveExchange public curveExchange;

    /**
     * A percentage that specifies the minimum amount of assets to protect in the strategy.
     * Protected assets are kept in LUSD and include principal, sponsored and accumulated performance fees.
     * This value acts as a threshold and is applied only when the total underlying assets are grater than the minimum protected assets.
     *
     * For instance, the minimum protected assets percentage is 150%, the total principal is 100 LUSD,
     * sponsored and perf fees are both 0, and the total yield is 100 LUSD. When the backend
     * rebalances the strategy (calls #reinvest), it has to ensure that at least 50 ETH+LQTY is
     * converted to LUSD to maintain a 150% minimum protected assets (150 LUSD).
     */
    uint16 public minProtectedAssetsPct;

    //
    // Modifiers
    //

    modifier onlyManager() {
        if (!hasRole(MANAGER_ROLE, msg.sender))
            revert StrategyCallerNotManager();
        _;
    }

    modifier onlyKeeper() {
        if (!hasRole(KEEPER_ROLE, msg.sender)) revert StrategyCallerNotKeeper();
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

    //
    // Initialize method (constructor alternative for proxy contracts)
    //

    function initialize(
        address _vault,
        address _admin,
        address _stabilityPool,
        address _lqty,
        address _underlying,
        address _keeper,
        uint16 _minProtectedAssetsPct,
        address _curveExchange
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        if (_admin == address(0)) revert StrategyAdminCannotBe0Address();
        if (_lqty == address(0)) revert StrategyYieldTokenCannotBe0Address();
        if (_stabilityPool == address(0))
            revert StrategyStabilityPoolCannotBe0Address();
        if (_underlying == address(0))
            revert StrategyUnderlyingCannotBe0Address();
        if (!_vault.doesContractImplementInterface(type(IVault).interfaceId))
            revert StrategyNotIVault();
        if (_keeper == address(0)) revert StrategyKeeperCannotBe0Address();
        if (_curveExchange == address(0))
            revert StrategyCurveExchangeCannotBe0Address();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(KEEPER_ROLE, _admin);
        _grantRole(SETTINGS_ROLE, _admin);
        _grantRole(MANAGER_ROLE, _vault);
        _grantRole(KEEPER_ROLE, _keeper);

        vault = _vault;
        underlying = IERC20(_underlying);
        stabilityPool = IStabilityPool(_stabilityPool);
        curveExchange = ICurveExchange(_curveExchange);
        lqty = IERC20(_lqty);
        minProtectedAssetsPct = _minProtectedAssetsPct;

        underlying.approve(_stabilityPool, type(uint256).max);
    }

    /**
     * Set the minimum protected assets percentage.
     *
     * @param _pct The new minimum assets protection percentage.
     */
    function setMinProtectedAssetsPct(uint16 _pct) external onlySettings {
        minProtectedAssetsPct = _pct;
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

        _grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        _grantRole(KEEPER_ROLE, _newAdmin);
        _grantRole(SETTINGS_ROLE, _newAdmin);

        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _revokeRole(KEEPER_ROLE, msg.sender);
        _revokeRole(SETTINGS_ROLE, msg.sender);
    }

    //
    // IStrategy
    //

    /// @inheritdoc IStrategy
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
        return investedAssets() != 0;
    }

    /// @inheritdoc IStrategy
    /// @notice LQTY rewards of the strategy waiting to be claimed in the liquity stability pool are not included
    /// @notice but the ETH rewards are included
    function investedAssets()
        public
        view
        virtual
        override(IStrategy)
        returns (uint256)
    {
        uint256 ethBalance = address(this).balance +
            stabilityPool.getDepositorETHGain(address(this));

        // need to do this because the get_exchange_amount method reverts if ethBalance is zero
        if (ethBalance == 0) {
            return stabilityPool.getCompoundedLUSDDeposit(address(this));
        }

        uint256 ethBalanceInUSDT = curveExchange.get_exchange_amount(
            WETH_CURVE_POOL,
            WETH,
            USDT,
            ethBalance
        );

        uint256 ethBalanceInLusd = curveExchange.get_exchange_amount(
            LUSD_CURVE_POOL,
            USDT,
            address(underlying),
            ethBalanceInUSDT
        );

        return
            stabilityPool.getCompoundedLUSDDeposit(address(this)) +
            ethBalanceInLusd;
    }

    /// @inheritdoc IStrategy
    /// @notice this will also claim any unclaimed gains in the stability pool
    function invest() external virtual override(IStrategy) onlyManager {
        uint256 balance = underlying.balanceOf(address(this));
        if (balance == 0) revert StrategyNoUnderlying();

        // claims LQTY & ETH rewards if there are any
        stabilityPool.provideToSP(balance, address(0));

        emit StrategyInvested(balance);
    }

    /// @inheritdoc IStrategy
    /// @notice will also claim unclaimed LQTY & ETH gains
    /// @notice when amount > total deposited, all available funds will be withdrawn
    function withdrawToVault(uint256 amount)
        external
        virtual
        override(IStrategy)
        onlyManager
        returns (uint256)
    {
        if (amount == 0) revert StrategyAmountZero();
        if (amount > investedAssets()) revert StrategyNotEnoughShares();

        // withdraws underlying amount and claims LQTY & ETH rewards
        stabilityPool.withdrawFromSP(amount);

        // use balance instead of amount since amount could be greater than what was actually withdrawn
        uint256 balance = underlying.balanceOf(address(this));
        underlying.transfer(vault, balance);

        emit StrategyWithdrawn(balance);

        return balance;
    }

    /**
     * Allows an address to be used as a swap target by adding it on the whitelist.
     *
     * @notice Can only be called by the account with the SETTINGS role.
     * @notice Swap targets are addresses of 0x contracts used for swapping ETH and LQTY tokens held by the strategy.
     */
    function allowSwapTarget(address _swapTarget) external onlySettings {
        _checkSwapTargetForZeroAddress(_swapTarget);

        allowedSwapTargets[_swapTarget] = true;
    }

    /**
     * Denies an address to be used as a swap target by removing it from the whitelist.
     *
     * @notice Can only be called by the account with the SETTINGS role.
     */
    function denySwapTarget(address _swapTarget) external onlySettings {
        _checkSwapTargetForZeroAddress(_swapTarget);

        allowedSwapTargets[_swapTarget] = false;
    }

    /**
     * Collects the LQTY & ETH rewards from the stability pool.
     */
    function harvest() external virtual {
        // call to withdrawFromSP with 0 amount will only claim rewards
        stabilityPool.withdrawFromSP(0);
    }

    /**
     * Swaps LQTY tokens and ETH held by the strategy to LUSD,
     * and reinvests the swapped LUSD amount into the stability pool.
     *
     * @notice Can only be called by the account with the KEEPER role.
     * @notice Swap data arguments provided are real-time data obtained from '0x' api.
     *
     * @param _swapTarget the address of the '0x' contract performing the tokens swap.
     * @param _lqtySwapData data used to perform LQTY -> LUSD swap. Leave empty to skip this swap.
     * @param _ethAmount amount of ETH to swap to LUSD, has to match with the amount used to obtain @param _ethSwapData.
     * @param _ethSwapData data used to perform ETH -> LUSD swap. Leave empty to skip this swap.
     * @param _amountOutMin the minimum amount of LUSD to be received after the ETH & LQTY -> LUSD swap.
     */
    function reinvest(
        address _swapTarget,
        uint256 _lqtyAmount,
        bytes calldata _lqtySwapData,
        uint256 _ethAmount,
        bytes calldata _ethSwapData,
        uint256 _amountOutMin
    ) external virtual onlyKeeper {
        _checkSwapTarget(_swapTarget);
        _checkMinAssetsProtectionRequirement(_amountOutMin);

        _swapLQTYtoLUSD(_swapTarget, _lqtyAmount, _lqtySwapData);
        _swapETHtoLUSD(_swapTarget, _ethAmount, _ethSwapData);

        // reinvest LUSD gains into the stability pool
        uint256 balance = underlying.balanceOf(address(this));
        if (balance == 0) {
            revert StrategyNothingToReinvest();
        }

        if (balance < _amountOutMin) {
            revert StrategyInsufficientOutputAmount();
        }

        stabilityPool.provideToSP(balance, address(0));

        emit StrategyReinvested(balance);
    }

    /// @inheritdoc IStrategy
    function transferYield(address, uint256)
        external
        virtual
        override(IStrategy)
        onlyManager
        returns (uint256)
    {
        return 0;
    }

    /**
     * Checks if the minimum assets protection requirement is met.
     * The minimum assets protection requirement is the minimum amount of LUSD that needs to be available after reinvesting.
     * Assets that are protected are the principal (user deposits), the sponsored amount and the accumulated performance fee.
     *
     * @param _amountOutMin the minimum amount of LUSD to be received after the ETH & LQTY -> LUSD swap.
     */
    function _checkMinAssetsProtectionRequirement(uint256 _amountOutMin)
        internal
        view
    {
        uint256 minAssetsToProtect = (IVault(vault).totalPrincipal() +
            IVaultSponsoring(vault).totalSponsored() +
            IVault(vault).accumulatedPerfFee()).pctOf(minProtectedAssetsPct);

        // the protection does not make sense if total underlying (assets held in the vault + assets invected in the strategy) is less than what is ment to be protected
        if (IVault(vault).totalUnderlying() < minAssetsToProtect) return;

        // check if the amountOutMin is large enough that total LUSD after reinvesting is greater than the amount that needs to be protected
        if (
            stabilityPool.getCompoundedLUSDDeposit(address(this)) +
                underlying.balanceOf(vault) +
                _amountOutMin >=
            minAssetsToProtect
        ) return;

        revert StrategyMinimumAssetsProtection();
    }

    /**
     * Checks if the provided swap target is 0 address or is not allowed and reverts if any of these conditions is true.
     */
    function _checkSwapTarget(address _swapTarget) internal view {
        _checkSwapTargetForZeroAddress(_swapTarget);

        if (!allowedSwapTargets[_swapTarget])
            revert StrategySwapTargetNotAllowed();
    }

    /**
     * Checks if the provided swap target is 0 address and reverts if true.
     */
    function _checkSwapTargetForZeroAddress(address _swapTarget) internal pure {
        if (_swapTarget == address(0))
            revert StrategySwapTargetCannotBe0Address();
    }

    /**
     * Swaps LQTY tokens held by the strategy to LUSD.
     *
     * @notice Swap data is real-time data obtained from '0x' api.
     *
     * @param _swapTarget the address of the '0x' contract performing the swap.
     * @param _amount the amount of LQTY tokens to swap. Has to match with the amount used to obtain @param _lqtySwapData from '0x' api.
     * @param _lqtySwapData data from '0x' api used to perform LQTY -> LUSD swap.
     */
    function _swapLQTYtoLUSD(
        address _swapTarget,
        uint256 _amount,
        bytes calldata _lqtySwapData
    ) internal {
        // don't do cross-contract call if nothing to swap
        if (_amount == 0 || _lqtySwapData.length == 0) return;

        uint256 lqtyBalance = lqty.balanceOf(address(this));
        if (_amount > lqtyBalance) revert StrategyNotEnoughLQTY();

        lqty.approve(_swapTarget, _amount);

        // perform the swap
        (bool success, ) = _swapTarget.call{value: 0}(_lqtySwapData);
        if (!success) revert StrategyLQTYSwapFailed();
    }

    /**
     * Swaps ETH held by the strategy to LUSD.
     *
     * @notice Swap data is real-time data obtained from '0x' api.
     *
     * @param _swapTarget the address of the '0x' contract performing the swap.
     * @param _amount the amount of ETH to swap. Has to match with the amount used to obtain @param _ethSwapData from '0x' api.
     * @param _ethSwapData data from '0x' api to perform ETH -> LUSD swap.
     */
    function _swapETHtoLUSD(
        address _swapTarget,
        uint256 _amount,
        bytes calldata _ethSwapData
    ) internal {
        // don't do cross-contract call if nothing to swap
        if (_amount == 0 || _ethSwapData.length == 0) return;

        uint256 ethBalance = address(this).balance;
        if (_amount > ethBalance) revert StrategyNotEnoughETH();

        (bool success, ) = _swapTarget.call{value: _amount}(_ethSwapData);

        if (!success) revert StrategyETHSwapFailed();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyAdmin
    {}

    /**
     * Strategy has to be able to receive ETH as stability pool rewards.
     */
    receive() external payable {}
}