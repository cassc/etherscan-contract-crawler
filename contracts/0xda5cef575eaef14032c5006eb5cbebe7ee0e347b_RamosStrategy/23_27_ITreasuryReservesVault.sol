pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (interfaces/v2/ITreasuryReservesVault.sol)

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ITempleDebtToken } from "contracts/interfaces/v2/ITempleDebtToken.sol";
import { ITempleStrategy } from "contracts/interfaces/v2/strategies/ITempleStrategy.sol";
import { ITempleBaseStrategy } from "contracts/interfaces/v2/strategies/ITempleBaseStrategy.sol";
import { ITempleElevatedAccess } from "contracts/interfaces/v2/access/ITempleElevatedAccess.sol";
import { ITreasuryPriceIndexOracle } from "contracts/interfaces/v2/ITreasuryPriceIndexOracle.sol";

/**
 * @title Treasury Reserves Vault (TRV)
 *
 * @notice Temple has various strategies which utilise the treasury funds to generate 
 * gains for token holders.
 * 
 * The maximum amount of funds allocated to each strategy is determined by governance, 
 * and then each strategy can borrow/repay as required (up to the cap).
 * 
 * When strategies borrow funds, they are issued `dToken`, an accruing debt token representing
 * the debt to the temple treasury. This is used to compare strategies performance, where
 * we can determine an equity value (assets - debt).
 *
 *    Strategies can borrow different types of tokens from the TRV, and are minted equivalent internal debt tokens eg:
 *      DAI => minted dUSD
 *      TEMPLE => minted dTEMPLE
 *      ETH => minted dETH
 *   
 *   Each of the dTokens are compounding at different risk free rates, eg:
 *      dUSD: At DAIs Savings Rate (DSR)
 *      dTEMPLE: 0% interest (no opportunity cost)
 *      dETH: ~avg LST rate
 *   
 *   And so each token which can be borrowed has separate config on how to pull/deposit idle funds.
 *   For example, this may be:
 *      DAI => DSR base strategy
 *      TEMPLE => direct Temple mint/burn 
 *      ETH => just hold in a vault
 */
interface ITreasuryReservesVault is ITempleElevatedAccess {
    event GlobalPausedSet(bool borrow, bool repay);
    event StrategyPausedSet(address indexed strategy, bool borrow, bool repay);

    event StrategyAdded(address indexed strategy, int256 underperformingEquityThreshold);
    event StrategyRemoved(address indexed strategy);
    event DebtCeilingUpdated(address indexed strategy, address indexed token, uint256 oldDebtCeiling, uint256 newDebtCeiling);
    event UnderperformingEquityThresholdUpdated(address indexed strategy, int256 oldThreshold, int256 newThreshold);
    event StrategyIsShuttingDownSet(address indexed strategy, bool isShuttingDown);
    event StrategyShutdownCreditAndDebt(address indexed strategy, address indexed token, uint256 outstandingCredit, uint256 outstandingDebt);
    event StrategyCreditAndDebtBalance(address indexed strategy, address indexed token, uint256 credit, uint256 debt);

    event BorrowTokenSet(address indexed token, address baseStrategy, uint256 baseStrategyWithdrawalBuffer, uint256 baseStrategyDepositThreshold, address dToken);
    event BorrowTokenRemoved(address indexed token);

    event Borrow(address indexed strategy, address indexed token, address indexed recipient, uint256 amount);
    event Repay(address indexed strategy, address indexed token, address indexed from, uint256 amount);

    event TpiOracleSet(address indexed tpiOracle);

    error BorrowTokenNotEnabled();
    error StrategyNotEnabled();

    error AlreadyEnabled();
    error BorrowPaused();
    error RepaysPaused();
    error StrategyIsShutdown();
    error DebtCeilingBreached(uint256 available, uint256 borrowAmount);
    error NotShuttingDown();

    struct BorrowTokenConfig {
        /**
         * @notice The base strategy used to hold idle treasury funds
         */
        ITempleBaseStrategy baseStrategy;

        /**
         * @notice A buffer of tokens are maintained in the TRV such that it doesn't have to churn through small base strategy
         * deposits/withdrawals. 
         * On a borrow if tokens need to be pulled from the base strategy, more than the requested amount is withdrawn such that
         * this extra buffer of tokens ends up in the TRV
         */
        uint256 baseStrategyWithdrawalBuffer;

        /**
         * @notice When repayments are made to the TRV, tokens are only deposited into the base strategy once this threshold is met.
         * The amount deposited will ensure that the `baseStrategyWithdrawalBuffer` amount remains in the TRV
         */
        uint256 baseStrategyDepositThreshold;

        /**
         * @notice The address of the internal debt token for this borrow token
         * @dev eg Temple => dTEMPLE, DAI => dUSD
         */
        ITempleDebtToken dToken;
    }
    
    struct StrategyConfig {
        /**
         * @notice Pause borrows
         */
        bool borrowPaused;

        /**
         * @notice Pause repayments
         */
        bool repaysPaused;

        /**
         * @notice Governance nominates this strategy to be shutdown.
         * The strategy executor then needs to unwind (may be manual) 
         * and the strategy needs to then call shutdown() when ready.
         */
        bool isShuttingDown;

        /**
         * @notice Each strategy will have a different threshold of expected performance.
         * This underperforming threshold is used for reporting to determine if the strategy is underperforming.
         */
        int256 underperformingEquityThreshold;

        /**
         * @notice The strategy can borrow up to this limit of accrued debt for each token.
         * The `dToken` is minted on any borrows 1:1 (which then accrues interest)
         * When a strategy repays, the `dToken` is burned 1:1
         */
        mapping(IERC20 => uint256) debtCeiling;

        /**
         * @notice The tokens that this strategy is allowed to borrow from TRV
         * @dev This must be one of the configured Borrow Tokens
         */
        mapping(IERC20 => bool) enabledBorrowTokens;
    }

    /**
     * @notice True if all borrows are paused for all strategies.
     */
    function globalBorrowPaused() external view returns (bool);

    /**
     * @notice True if all repayments are paused for all strategies.
     */
    function globalRepaysPaused() external view returns (bool);

    /**
     * @notice The configuration for a given strategy
     */
    function strategies(address strategy) external view returns (
        bool borrowPaused,
        bool repaysPaused,
        bool isShuttingDown,
        int256 underperformingEquityThreshold
    );

    /**
     * @notice The list of all strategies currently added to the TRV
     */
    function strategiesList() external view returns (address[] memory);

    /**
     * @notice The configuration for a given token which can be borrowed by strategies
     */
    function borrowTokens(IERC20 token) external view returns (
        ITempleBaseStrategy baseStrategy,
        uint256 baseStrategyWithdrawalBuffer,
        uint256 baseStrategyDepositThreshold,
        ITempleDebtToken dToken
    );

    /**
     * @notice The list of all tokens which can be borrowed by the TRV
     */
    function borrowTokensList() external view returns (address[] memory);

    /**
     * @notice When strategies repay a token which covers more than their dToken debt for the token
     * They receive credits. When they next need to borrow tokens this credit is used prior to
     * issuing more dTokens
     */
    function strategyTokenCredits(address strategy, IERC20 token) external view returns (uint256);

    /**
     * @notice The Treasury Price Index Oracle
     */
    function tpiOracle() external view returns (ITreasuryPriceIndexOracle);

    /**
     * @notice Set the Treasury Price Index (TPI) Oracle
     */
    function setTpiOracle(address tpiOracleAddress) external;

    /**
     * @notice The Treasury Price Index - the target price of the Treasury, in `stableToken` terms.
     */
    function treasuryPriceIndex() external view returns (uint96);

    /**
     * @notice API version to help with future integrations/migrations
     */
    function apiVersion() external pure returns (string memory);

    /**
     * @notice Set the borrow token configuration. 
     * @dev This can either add a new token or update an existing token.
     */
    function setBorrowToken(
        IERC20 token, 
        address baseStrategy,
        uint256 baseStrategyWithdrawalBuffer,
        uint256 baseStrategyDepositThreshold,
        address dToken
    ) external;

    /**
     * @notice Enable and/or disable tokens which a strategy can borrow from the (configured) TRV borrow tokens
     */
    function updateStrategyEnabledBorrowTokens(
        address strategy, 
        IERC20[] calldata enableBorrowTokens, 
        IERC20[] calldata disableBorrowTokens
    ) external;

    /**
     * @notice Remove the borrow token configuration. 
     */
    function removeBorrowToken(
        IERC20 token
    ) external;

    /**
     * @notice A helper to collate information about a given strategy for reporting purposes.
     * @dev Note the current assets may not be 100% up to date, as some strategies may need to checkpoint based
     * on the underlying strategy protocols (eg DSR for DAI would need to checkpoint to get the latest valuation).
     */
    function strategyDetails(address strategy) external view returns (
        string memory name,
        string memory version,
        bool borrowPaused,
        bool repaysPaused,
        bool isShuttingDown,
        int256 underperformingEquityThreshold,
        ITempleStrategy.AssetBalance[] memory debtCeiling
    );

    /**
     * @notice A strategy's current asset balances, any manual adjustments and the current debt
     * of the strategy.
     * 
     * This will be used to report equity performance: `sum($assetValue +- $manualAdj) - debt`
     * The conversion of each asset price into the stable token (eg DAI) will be done off-chain
     * along with formulating the union of asset balances and manual adjustments
     */
    function strategyBalanceSheet(address strategyAddr) external view returns (
        ITempleStrategy.AssetBalance[] memory assetBalances,
        ITempleStrategy.AssetBalanceDelta[] memory manualAdjustments, 
        ITempleStrategy.AssetBalance[] memory dTokenBalances,
        ITempleStrategy.AssetBalance[] memory dTokenCreditBalances
    );

    /**
     * @notice The current max debt ceiling that a strategy is allowed to borrow up to.
     */
    function strategyDebtCeiling(address strategy, IERC20 token) external view returns (uint256);
    
    /**
     * @notice Whether a token is enabled to be borrowed for a given strategy
     */
    function strategyEnabledBorrowTokens(address strategy, IERC20 token) external view returns (bool);

    /**
     * @notice The total available stables, both as a balance in this contract and
     * any available to withdraw from the baseStrategy
     */
    function totalAvailable(IERC20 token) external view returns (uint256);

    /**
     * @notice The amount remaining that a strategy can borrow for a given token
     * taking into account: the approved debt ceiling, current dToken debt, and any credits
     * @dev available == min(ceiling - debt + credit, 0)
     */
    function availableForStrategyToBorrow(
        address strategy, 
        IERC20 token
    ) external view returns (uint256);

    /**
     * @notice Pause all strategy borrow and repays
     */
    function setGlobalPaused(bool borrow, bool repays) external;

    /**
     * @notice Set whether borrows and repayments are paused for a given strategy.
     */
    function setStrategyPaused(address strategy, bool borrow, bool repays) external;

    /**
     * @notice Register a new strategy which can borrow tokens from Treasury Reserves
     */
    function addStrategy(
        address strategy, 
        int256 underperformingEquityThreshold,
        ITempleStrategy.AssetBalance[] calldata debtCeiling
    ) external;

    /**
     * @notice Update the debt ceiling for a given strategy
     */
    function setStrategyDebtCeiling(address strategy, IERC20 token, uint256 newDebtCeiling) external;

    /**
     * @notice Update the underperforming equity threshold.
     */
    function setStrategyUnderperformingThreshold(address strategy, int256 underperformingEquityThreshold) external;

    /**
     * @notice The first step in a two-phase shutdown. Executor first sets whether a strategy is slated for shutdown.
     * The strategy then needs to call shutdown as a separate call once ready.
     */
    function setStrategyIsShuttingDown(address strategy, bool isShuttingDown) external;

    /**
     * @notice The second step in a two-phase shutdown. A strategy (automated) or executor (manual) calls
     * to effect the shutdown. isShuttingDown must be true for the strategy first.
     * The strategy executor is responsible for unwinding all it's positions first and repaying the debt to the TRV.
     * All outstanding dToken debt is burned, leaving a net gain/loss of equity for the shutdown strategy.
     */
    function shutdown(address strategy) external;   

    /**
     * @notice A strategy calls to request more funding.
     * @dev This will revert if the strategy requests more stables than it's able to borrow.
     * `dToken` will be minted 1:1 for the amount of stables borrowed
     */
    function borrow(IERC20 token, uint256 borrowAmount, address recipient) external;

    /**
     * @notice A strategy calls to request the most funding it can.
     * @dev This will revert if the strategy requests more stables than it's able to borrow.
     * `dToken` will be minted 1:1 for the amount of stables borrowed
     */
    function borrowMax(IERC20 token, address recipient) external returns (uint256);

    /**
     * @notice A strategy calls to paydown it's debt
     * This will pull the stables, and will burn the equivalent amount of dToken from the strategy.
     */
    function repay(IERC20 token, uint256 repayAmount, address strategy) external;

    /**
     * @notice A strategy calls to paydown all of it's debt
     * This will pull the stables for the entire dToken balance of the strategy, and burn the dToken.
     */
    function repayAll(IERC20 token, address strategy) external returns (uint256 amountRepaid);
}