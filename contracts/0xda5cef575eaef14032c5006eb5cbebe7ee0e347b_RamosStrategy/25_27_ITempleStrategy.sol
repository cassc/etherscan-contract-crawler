pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (interfaces/v2/strategies/ITempleStrategy.sol)

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ITreasuryReservesVault } from "contracts/interfaces/v2/ITreasuryReservesVault.sol";
import { ITempleElevatedAccess } from "contracts/interfaces/v2/access/ITempleElevatedAccess.sol";

/**
 * @title Temple Strategy
 * @notice The Temple Strategy is responsible for borrowing funds from the Treasury Reserve Vault
 * and generating positive equity from that capital.
 * 
 * When it borrows funds it is issued systematic debt (`dToken`) which accrues interest at a common base rate
 * plus a risk premium rate specific to this strategy, agreed and set by governance.
 *
 * The strategy reports it's assets (total available funds in investments)
 * in order to report the equity of the strategy -- ie a comparable performance metric across all strategy's.
 *
 * The Strategy Executor role is responsible for applying the capital within the strategy, and can borrow funds from
 * the TRV up to a cap (set by governance). Similarly the Executor is responsible for operations - borrow/repay/liquidate/etc.
 *
 * The strategy can be shutdown - first by Executors giving the go-ahead by setting it to `isShuttingDown` in the TRV
 * and then the Executor can either:
 *   a/ Graceful shutdown, where any liquidation can happen automatically
 *   b/ Force shutdown, where the Executor needs to handle any liquidations manually and send funds back to Treasury first.
 */
interface ITempleStrategy is ITempleElevatedAccess {
    struct AssetBalance {
        address asset;
        uint256 balance;
    }

    struct AssetBalanceDelta {
        address asset;
        int256 delta;
    }

    event TreasuryReservesVaultSet(address indexed trv);
    event Shutdown();
    event AssetBalancesCheckpoint(AssetBalance[] assetBalances);
    event ManualAdjustmentsSet(AssetBalanceDelta[] adjustments);
    event TokenAllowanceSet(address token, address spender, uint256 amount);
    
    error InvalidVersion(string expected, string actual);
    error OnlyTreasuryReserveVault(address caller);

    /**
     * @notice API version to help with future integrations/migrations
     */
    function apiVersion() external view returns (string memory);

    /**
     * @notice A human readable name of the strategy
     */
    function strategyName() external view returns (string memory);

    /**
     * @notice The version of this particular strategy
     */
    function strategyVersion() external view returns (string memory);

    /**
     * @notice The address of the treasury reserves vault.
     */
    function treasuryReservesVault() external view returns (ITreasuryReservesVault);

    /**
     * @notice Executors can set the address of the treasury reserves vault.
     */
    function setTreasuryReservesVault(address _trv) external;

    /**
     * @notice The Strategy Executor may set manual adjustments to asset balances
     * if they cannot be reported automatically - eg a staked position with no receipt token.
     */
    function setManualAdjustments(AssetBalanceDelta[] calldata adjustments) external;

    /**
     * @notice Get the set of manual asset balance deltas, set by the Strategy Executor.
     */
    function manualAdjustments() external view returns (AssetBalanceDelta[] memory adjustments);

    /**
     * @notice The latest checkpoint of each asset balance this strategy holds.
     *
     * @dev The asset value may be stale at any point in time, depending on the strategy. 
     * It may optionally implement `checkpointAssetBalances()` in order to update those balances.
     */
    function latestAssetBalances() external view returns (AssetBalance[] memory assetBalances);

    /**
     * @notice By default, we assume there is no checkpoint required for a strategy
     * In which case it would be identical to just calling `latestAssetBalances()`
     *
     * A strategy can override this if on-chain functions are required to run to force balance
     * updates first - eg checkpoint DSR
     */
    function checkpointAssetBalances() external returns (AssetBalance[] memory assetBalances);

    /**
     * @notice populate data required for shutdown - for example quote data.
     * This may/may not be required in order to do a shutdown. For example to avoid frontrunning/MEV
     * quotes to exit an LP position may need to be obtained off-chain prior to the actual shutdown.
     * Each strategy can abi encode params that it requires.
     * @dev Intentionally not a view - as some quotes require a non-view (eg Balancer)
     * The intention is for clients to call as 'static', like a view
     */
    function populateShutdownData(bytes calldata populateParamsData) external returns (bytes memory shutdownParamsData);

    /**
     * @notice The strategy executor can shutdown this strategy, only after Executors have
     * marked the strategy as `isShuttingDown` in the TRV.
     * This should handle all liquidations and send all funds back to the TRV, and will then call `TRV.shutdown()`
     * to apply the shutdown.
     * @dev Each strategy may require a different set of params to do the shutdown. It can abi encode/decode
     * that data off chain, or by first calling populateShutdownData()
     */
    function automatedShutdown(bytes calldata shutdownParamsData) external;

    /**
     * @notice Executors can recover any token from the strategy.
     */
    function recoverToken(address token, address to, uint256 amount) external;

    /**
     * @notice Executors can set the allowance of any token spend from the strategy
     */
    function setTokenAllowance(IERC20 token, address spender, uint256 amount) external;

    /**
     * @notice A hook which is called by the Treasury Reserves Vault when the debt ceiling
     * for this strategy is updated
     * @dev by default it's a no-op unless the strategy implements `_debtCeilingUpdated()`
     */
    function debtCeilingUpdated(IERC20 token, uint256 newDebtCeiling) external;
}