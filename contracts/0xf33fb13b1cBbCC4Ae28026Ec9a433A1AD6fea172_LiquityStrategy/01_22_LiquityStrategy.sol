// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {PercentMath} from "../../lib/PercentMath.sol";
import {IStrategy} from "../IStrategy.sol";
import {CustomErrors} from "../../interfaces/CustomErrors.sol";
import {IVault} from "../../vault/IVault.sol";
import {IStabilityPool} from "../../interfaces/liquity/IStabilityPool.sol";
import {ERC165Query} from "../../lib/ERC165Query.sol";

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

    error StrategyStabilityPoolCannotBeAddressZero();
    error StrategyYieldTokenCannotBe0Address();
    error StrategyTokenApprovalFailed(address token);
    error StrategyTokenTransferFailed(address token);
    error StrategyNothingToReinvest();
    error StrategySwapTargetCannotBe0Address();
    error StrategyLQTYSwapDataEmpty();
    error StrategyETHSwapDataEmpty();
    error StrategyLQTYSwapFailed();
    error StrategyETHSwapFailed();

    event StrategyRewardsClaimed(uint256 amountInLQTY, uint256 amountInETH);
    event StrategyRewardsReinvested(uint256 amountInLUSD);

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IERC20 public underlying; // LUSD token
    /// @inheritdoc IStrategy
    address public override(IStrategy) vault;
    IStabilityPool public stabilityPool;
    IERC20 public lqty; // reward token

    //
    // Modifiers
    //

    modifier onlyManager() {
        if (!hasRole(MANAGER_ROLE, msg.sender))
            revert StrategyCallerNotManager();
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
        address _underlying
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        if (_admin == address(0)) revert StrategyAdminCannotBe0Address();
        if (_lqty == address(0)) revert StrategyYieldTokenCannotBe0Address();
        if (_stabilityPool == address(0))
            revert StrategyStabilityPoolCannotBeAddressZero();
        if (_underlying == address(0))
            revert StrategyUnderlyingCannotBe0Address();
        if (!_vault.doesContractImplementInterface(type(IVault).interfaceId))
            revert StrategyNotIVault();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MANAGER_ROLE, _vault);

        vault = _vault;
        underlying = IERC20(_underlying);
        stabilityPool = IStabilityPool(_stabilityPool);
        lqty = IERC20(_lqty);

        if (!underlying.approve(_stabilityPool, type(uint256).max)) {
            revert StrategyTokenApprovalFailed(_underlying);
        }
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

        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    //
    // IStrategy
    //

    /**
     * Returns true since strategy is synchronous.
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
        return investedAssets() != 0;
    }

    /// @inheritdoc IStrategy
    /// @notice ETH & LQTY rewards of the strategy waiting to be claimed in the liquity stability pool are not included
    function investedAssets()
        public
        view
        virtual
        override(IStrategy)
        returns (uint256)
    {
        return stabilityPool.getCompoundedLUSDDeposit(address(this));
    }

    /// @inheritdoc IStrategy
    function invest() external virtual override(IStrategy) onlyManager {
        uint256 balance = underlying.balanceOf(address(this));
        if (balance == 0) revert StrategyNoUnderlying();

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
    {
        if (amount == 0) revert StrategyAmountZero();
        if (amount > investedAssets()) revert StrategyNotEnoughShares();

        // withdraws underlying amount and claims LQTY & ETH rewards
        stabilityPool.withdrawFromSP(amount);

        uint256 lqtyRewards = lqty.balanceOf(address(this));
        uint256 ethRewards = address(this).balance;
        emit StrategyRewardsClaimed(lqtyRewards, ethRewards);

        // use balance instead of amount since amount could be greater than what was actually withdrawn
        uint256 balance = underlying.balanceOf(address(this));
        if (!underlying.transfer(vault, balance)) {
            revert StrategyTokenTransferFailed(address(underlying));
        }

        emit StrategyWithdrawn(balance);
    }

    /**
     * Collects the LQTY & ETH rewards from the stability pool, swaps the rewards to LUSD,
     * and reinvests swapped LUSD amount into the stability pool to create compound interest on future gains.
     *
     * @notice Can only be called by the account with the ADMIN role.
     * @notice Implicitly calls the reinvestRewards function.
     * @notice Arguments provided to harvest function are real-time data obtained from '0x' api.
     *
     * @param _swapTarget the address of the '0x' contract performing the tokens swap.
     * @param _lqtySwapData data used to perform LQTY -> LUSD swap.
     * @param _ethSwapData data used to perform ETH -> LUSD swap.
     */
    function harvest(
        address _swapTarget,
        bytes calldata _lqtySwapData,
        bytes calldata _ethSwapData
    ) external virtual {
        // call withdrawFromSP with 0 amount only to claim rewards
        stabilityPool.withdrawFromSP(0);

        reinvestRewards(_swapTarget, _lqtySwapData, _ethSwapData);
    }

    /**
     * Swaps LQTY tokens and ETH already held by the strategy to LUSD,
     * and reinvests swapped LUSD amount into the stability pool.
     *
     * @notice Can only be called by the account with the ADMIN role.
     * @notice Arguments provided are real-time data obtained from '0x' api.
     *
     * @param _swapTarget the address of the '0x' contract performing the tokens swap.
     * @param _lqtySwapData data used to perform LQTY -> LUSD swap.
     * @param _ethSwapData data used to perform ETH -> LUSD swap.
     */
    function reinvestRewards(
        address _swapTarget,
        bytes calldata _lqtySwapData,
        bytes calldata _ethSwapData
    ) public virtual onlyAdmin {
        if (_swapTarget == address(0))
            revert StrategySwapTargetCannotBe0Address();

        uint256 lqtyBalance = lqty.balanceOf(address(this));
        uint256 ethBalance = address(this).balance;

        if (lqtyBalance == 0 && ethBalance == 0)
            revert StrategyNothingToReinvest();

        if (lqtyBalance != 0) {
            swapLQTYtoLUSD(lqtyBalance, _swapTarget, _lqtySwapData);
        }

        if (ethBalance != 0) {
            swapETHtoLUSD(ethBalance, _swapTarget, _ethSwapData);
        }

        // reinvest LUSD gains into the stability pool
        uint256 balance = underlying.balanceOf(address(this));
        if (balance != 0) {
            emit StrategyRewardsReinvested(balance);

            stabilityPool.provideToSP(balance, address(0));
        }
    }

    /**
     * Swaps LQTY tokens held by the strategy to LUSD.
     *
     * @notice Arguments provided are real-time data obtained from '0x' api.
     *
     * @param amount the amount of LQTY tokens to swap.
     * @param _swapTarget the address of the '0x' contract performing the tokens swap.
     * @param _lqtySwapData data used to perform LQTY -> LUSD swap.
     */
    function swapLQTYtoLUSD(
        uint256 amount,
        address _swapTarget,
        bytes calldata _lqtySwapData
    ) internal {
        // give approval to the swapTarget
        if (!lqty.approve(_swapTarget, amount)) {
            revert StrategyTokenApprovalFailed(address(lqty));
        }

        // perform the swap
        (bool success, ) = _swapTarget.call{value: 0}(_lqtySwapData);
        if (!success) revert StrategyLQTYSwapFailed();
    }

    /**
     * Swaps ETH held by the strategy to LUSD.
     *
     * @notice Arguments provided are real-time data obtained from '0x' api.
     *
     * @param amount the amount of ETH to swap.
     * @param _swapTarget the address of the '0x' contract performing the tokens swap.
     * @param _ethSwapData data used to perform ETH -> LUSD swap.
     */
    function swapETHtoLUSD(
        uint256 amount,
        address _swapTarget,
        bytes calldata _ethSwapData
    ) internal {
        (bool success, ) = _swapTarget.call{value: amount}(_ethSwapData);
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