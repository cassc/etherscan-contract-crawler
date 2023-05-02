// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

import {Multicallable} from "solady/src/utils/Multicallable.sol";

import {AffineGovernable} from "src/utils/AffineGovernable.sol";
import {BaseStrategy as Strategy} from "src/strategies/BaseStrategy.sol";
import {WithdrawalEscrow} from "./WithdrawalEscrow.sol";
import {uncheckedInc} from "src/libs/Unchecked.sol";

/**
 * @notice A single-strategy vault.
 */
contract BaseStrategyVault is AffineGovernable, AccessControlUpgradeable, Multicallable {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                             INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    ERC20 _asset;

    /// @notice The token that the vault takes in and tries to get more of, e.g. USDC
    function asset() public view virtual returns (address) {
        return address(_asset);
    }

    /**
     * @dev Initialize the vault.
     * @param _governance The governance address.
     * @param vaultAsset The vault's input asset.
     */
    function baseInitialize(address _governance, ERC20 vaultAsset) internal virtual {
        governance = _governance;
        _asset = vaultAsset;

        // All roles use the default admin role
        // Governance has the admin role and all roles
        _grantRole(DEFAULT_ADMIN_ROLE, governance);
        _grantRole(HARVESTER, governance);

        lastHarvest = uint128(block.timestamp);
        epochEnded = true;
    }

    /*//////////////////////////////////////////////////////////////
                             AUTHENTICATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Role with authority to call "harvest", i.e. update this vault's tvl
    bytes32 public constant HARVESTER = keccak256("HARVESTER");

    /*//////////////////////////////////////////////////////////////
                               STRATEGY
    //////////////////////////////////////////////////////////////*/

    /// @notice The strategy that the vault uses to invest its assets.
    Strategy public strategy;
    /// @notice The total amount of underlying assets held in strategies at the time of the last harvest.
    uint256 public strategyTVL;

    function setStrategy(Strategy newStrategy) external virtual onlyGovernance {
        strategy = newStrategy;
    }

    uint248 public epoch;
    bool public epochEnded;
    uint256 public epochStartTime;
    WithdrawalEscrow public debtEscrow;

    function setDebtEscrow(WithdrawalEscrow escrow) external onlyGovernance {
        debtEscrow = escrow;
    }

    event BeginEpoch(uint256 epoch);

    function beginEpoch() external virtual {
        require(msg.sender == address(strategy), "BSV: only strategy");
        epoch += 1;
        epochEnded = false;
        epochStartTime = block.timestamp;
        emit BeginEpoch(epoch);
    }

    event EndEpoch(uint256 epoch);

    function endEpoch() external virtual {
        require(msg.sender == address(strategy), "BSV: only strategy");
        epochEnded = true;
        _updateTVL();
        emit EndEpoch(epoch);
    }

    /*//////////////////////////////////////////////////////////////
                      STRATEGY DEPOSIT/WITHDRAWAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted after the Vault deposits into a strategy contract.
     * @param assets The amount of assets deposited.
     */
    event StrategyDeposit(uint256 assets);

    /**
     * @notice Emitted after the Vault withdraws funds from a strategy contract.
     * @param assetsRequested The amount of assets we tried to divest from the strategy.
     * @param assetsReceived The amount of assets actually withdrawn.
     */
    event StrategyWithdrawal(uint256 assetsRequested, uint256 assetsReceived);

    function _depositIntoStrategy(uint256 assets) internal {
        // Don't allow empty investments
        if (assets == 0) return;

        // Increase strategyTVL to account for the deposit.
        // Without this the next harvest would count the deposit as profit.
        strategyTVL += assets;

        // Approve assets to the strategy so we can deposit.
        _asset.safeApprove(address(strategy), assets);

        // Deposit into the strategy, will revert upon failure
        strategy.invest(assets);
        emit StrategyDeposit(assets);
    }

    /**
     * @notice Withdraw a specific amount of underlying tokens from a strategy.
     * @dev This is a "best effort" withdrawal. It could potentially withdraw nothing.
     * @param assets  The amount of underlying tokens to withdraw.
     * @return The amount of assets actually received.
     */
    function _withdrawFromStrategy(uint256 assets) internal returns (uint256) {
        // Withdraw from the strategy
        uint256 amountWithdrawn = _divest(assets);

        // Without this the next harvest would count the withdrawal as a loss.
        // We update the balance to the current tvl because a withdrawal can reduce the tvl by more than the amount
        // withdrawn (e.g. fees during a swap)
        uint256 oldStratTVL = strategyTVL;
        uint256 newStratTVL = strategy.totalLockedValue();

        // Decrease strategyTVL to account for the withdrawal.
        // If we haven't harvested in a long time, newStratTVL could be bigger than oldStratTvl
        strategyTVL -= oldStratTVL > newStratTVL ? oldStratTVL - newStratTVL : 0;
        emit StrategyWithdrawal({assetsRequested: assets, assetsReceived: amountWithdrawn});
        return amountWithdrawn;
    }

    /// @dev A small wrapper around divest(). We try-catch to make sure that a bad strategy does not pause withdrawals.
    function _divest(uint256 assets) internal returns (uint256) {
        try strategy.divest(assets) returns (uint256 amountDivested) {
            return amountDivested;
        } catch {
            return 0;
        }
    }

    /*//////////////////////////////////////////////////////////////
                               HARVESTING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice A timestamp representing when the most recent harvest occurred.
     * @dev Since the time since the last harvest is used to calculate management fees, this is set
     * to `block.timestamp` (instead of 0) during initialization.
     */
    uint128 public lastHarvest;
    /// @notice The amount of profit *originally* locked after harvesting from a strategy
    uint128 public maxLockedProfit;
    /// @notice Amount of time in seconds that profit takes to fully unlock. See lockedProfit().
    uint256 public constant LOCK_INTERVAL = 24 hours;

    /**
     * @notice Emitted after a successful harvest.
     * @param user The user who triggered the harvest.
     */
    event Harvest(address indexed user);

    function _updateTVL() internal {
        // Get the strategy's previous and current balance.
        uint256 prevBalance = strategyTVL;
        uint256 currentBalance = strategy.totalLockedValue();

        // Calculate profit made
        uint256 totalProfitAccrued;
        unchecked {
            // Update the total profit accrued while counting losses as zero profit.
            // Cannot overflow as we already increased total holdings without reverting.
            totalProfitAccrued += currentBalance > prevBalance
                ? currentBalance - prevBalance // Profits since last harvest.
                : 0; // If the strategy registered a net loss we don't have any new profit.
        }

        // Update max unlocked profit based on any remaining locked profit plus new profit.
        maxLockedProfit = uint128(lockedProfit() + totalProfitAccrued);

        // Set strategy holdings to our new total.
        strategyTVL = currentBalance;

        // Assess fees (using old `lastHarvest`) and update the last harvest timestamp.
        _assessFees();
        lastHarvest = uint128(block.timestamp);
        emit Harvest(msg.sender);
    }

    /**
     * @notice Current locked profit amount.
     * @dev Profit unlocks uniformly over `LOCK_INTERVAL` seconds after the last harvest
     */
    function lockedProfit() public view virtual returns (uint256) {
        if (block.timestamp >= lastHarvest + LOCK_INTERVAL) {
            return 0;
        }

        uint256 unlockedProfit = (maxLockedProfit * (block.timestamp - lastHarvest)) / LOCK_INTERVAL;
        return maxLockedProfit - unlockedProfit;
    }

    /*//////////////////////////////////////////////////////////////
                        LIQUIDATION/REBALANCING
    //////////////////////////////////////////////////////////////*/

    /// @notice The total amount of the underlying asset the vault has.
    function vaultTVL() public view returns (uint256) {
        return _asset.balanceOf(address(this)) + strategyTVL;
    }

    /**
     * @notice Assess fees.
     * @dev This is called during harvest() to assess management fees.
     */
    function _assessFees() internal virtual {}
}