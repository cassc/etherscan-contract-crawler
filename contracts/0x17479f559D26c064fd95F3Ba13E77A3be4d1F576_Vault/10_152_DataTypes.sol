// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library DataTypes {
    /**
     * @notice Container for User Deposit/withdraw operations
     * @param account User's address
     * @param isDeposit True if it is deposit and false if it withdraw
     * @param value Amount to deposit/withdraw
     */
    struct UserDepositOperation {
        address account;
        uint256 value;
    }

    /**
     * @notice Container for token balance in vault contract in a specific block
     * @param actualVaultValue current balance of the vault contract
     * @param blockMinVaultValue minimum balance recorded for vault contract in the same block
     * @param blockMaxVaultValue maximum balance recorded for vault contract in the same block
     */
    struct BlockVaultValue {
        uint256 actualVaultValue;
        uint256 blockMinVaultValue;
        uint256 blockMaxVaultValue;
    }

    /**
     * @notice Container for Strategy Steps used by Strategy
     * @param pool Liquidity Pool address
     * @param outputToken Output token of the liquidity pool
     * @param isSwap true if the underlying token is to be swapped to output token
     */
    struct StrategyStep {
        address pool;
        address outputToken;
        bool isSwap;
    }

    /**
     * @notice Container for pool's configuration
     * @param rating Rating of the liquidity pool
     * @param isLiquidityPool If pool is enabled as liquidity pool
     */
    struct LiquidityPool {
        uint8 rating;
        bool isLiquidityPool;
    }

    /**
     * @notice Container for Strategy used by Vault contract
     * @param index Index at which strategy is stored
     * @param strategySteps StrategySteps consisting pool, outputToken and isSwap
     */
    struct Strategy {
        uint256 index;
        StrategyStep[] strategySteps;
    }

    /**
     * @notice Container for all Tokens
     * @param index Index at which token is stored
     * @param tokens List of token addresses
     */
    struct Token {
        uint256 index;
        address[] tokens;
    }

    /**
     * @notice Container for pool and its rating
     * @param pool Address of liqudity pool
     * @param rate Value to be set as rate for the liquidity pool
     */
    struct PoolRate {
        address pool;
        uint8 rate;
    }

    /**
     * @notice Container for mapping the liquidity pool and adapter
     * @param pool liquidity pool address
     * @param adapter adapter contract address corresponding to pool
     */
    struct PoolAdapter {
        address pool;
        address adapter;
    }

    /**
     * @notice Container for having limit range for the pools
     * @param lowerLimit liquidity pool rate's lower limit
     * @param upperLimit liquidity pool rate's upper limit
     */
    struct PoolRatingsRange {
        uint8 lowerLimit;
        uint8 upperLimit;
    }

    /**
     * @notice Container for having limit range for withdrawal fee
     * @param lowerLimit withdrawal fee's lower limit
     * @param upperLimit withdrawal fee's upper limit
     */
    struct WithdrawalFeeRange {
        uint256 lowerLimit;
        uint256 upperLimit;
    }

    /**
     * @notice Container for containing risk Profile's configuration
     * @param index Index at which risk profile is stored
     * @param var0 boolean placeholder
     * @param poolRatingsRange Container for having limit range for the pools
     * @param exists if risk profile exists or not
     */
    struct RiskProfile {
        uint256 index;
        bool var0;
        PoolRatingsRange poolRatingsRange;
        bool exists;
        string name;
        string symbol;
    }

    /**
     * @notice Container for holding percentage of reward token to hold and convert
     * @param hold reward token hold percentage in basis point
     * @param convert reward token convert percentage in basis point
     */
    struct VaultRewardStrategy {
        uint256 hold; //  should be in basis eg: 50% means 5000
        uint256 convert; //  should be in basis eg: 50% means 5000
    }

    /**
     * @notice Container for token hash details
     * @param tokensHash the hash of tokens
     * @param tokens the array of tokens' addresses
     */
    struct TokensHashDetail {
        bytes32 tokensHash;
        address[] tokens;
    }

    /** @notice Named Constants for defining max exposure state */
    enum MaxExposure { Number, Pct }

    /** @notice Named Constants for defining default strategy state */
    enum DefaultStrategyState { Zero, CompoundOrAave }

    /**
     * @notice Container for persisting ODEFI contract's state
     * @param index The market's last index
     * @param timestamp The block number the index was last updated at
     */
    struct RewardsState {
        uint224 index;
        uint32 timestamp;
    }

    /**
     * @notice Container for Treasury accounts along with their shares
     * @param treasury treasury account address
     * @param share treasury's share in percentage from the withdrawal fee
     */
    struct TreasuryShare {
        address treasury;
        uint256 share; //  should be in basis eg: 5% means 500
    }

    /**
     * @notice Container for combining Vault contract's configuration
     * @param discontinued If the vault contract is discontinued or not
     * @param unpaused If the vault contract is paused or unpaused
     * @param withdrawalFee withdrawal fee for a particular vault contract
     * @param treasuryShares Treasury accounts along with their shares
     * @param isLimitedState If the vault contract has a limit for total user deposits
     * @param allowWhitelistedState If the vault contract require whitelisted users or not
     * @param userDepositCap Maximum total amount that can be deposited by an address
     * @param minimumDepositAmount Minimum deposit without rebalance allowed
     * @param totalValueLockedLimitInUnderlying Maximum TVL in underlying allowed for the vault
     * @param queueCap Maximum length of the deposits without rebalance queue
     */
    struct VaultConfiguration {
        bool discontinued;
        bool unpaused;
        bool isLimitedState;
        bool allowWhitelistedState;
        TreasuryShare[] treasuryShares;
        uint256 withdrawalFee; //  should be in basis eg: 15% means 1500
        uint256 userDepositCap;
        uint256 minimumDepositAmount;
        uint256 totalValueLockedLimitInUnderlying;
        uint256 queueCap;
    }

    /**
     * @notice Container for combining Vault contract's configuration
     * @param emergencyShutdown If the vault contract is in emergencyShutdown
     *        state or not
     * @param unpaused If the vault contract is paused or unpaused
     *        Following operations cannot happen if vault is paused:
     *        - deposit of underlying tokens
     *        - withdraw and transfer of vault tokens
     * @param allowWhitelistedState vault's whitelisted state flag
     * @param vaultFeeCollector address that collects vault deposit and withdraw fee
     * @param depositFeeFlatUT flat deposit fee in underlying token
     * @param depositFeePct deposit fee in percentage basis points
     * @param withdrawalFeeFlatUT flat withdrawal fee in underlying token
     * @param withdrawalFeePct withdrawal fee in percentage basis points
     */
    struct VaultConfigurationV2 {
        bool emergencyShutdown;
        bool unpaused;
        bool allowWhitelistedState;
        address vaultFeeCollector;
        uint256 depositFeeFlatUT;
        uint256 depositFeePct;
        uint256 withdrawalFeeFlatUT;
        uint256 withdrawalFeePct;
    }

    /**
     * @notice Container for persisting all strategy related contract's configuration
     * @param investStrategyRegistry investStrategyRegistry contract address
     * @param strategyProvider strategyProvider contract address
     * @param aprOracle aprOracle contract address
     */
    struct StrategyConfiguration {
        address investStrategyRegistry;
        address strategyProvider;
        address aprOracle;
    }

    /**
     * @notice Container for persisting contract addresses required by vault contract
     * @param strategyManager strategyManager contract address
     * @param riskManager riskManager contract address
     * @param optyDistributor optyDistributor contract address
     * @param operator operator contract address
     */
    struct VaultStrategyConfiguration {
        address strategyManager;
        address riskManager;
        address optyDistributor;
        address odefiVaultBooster;
        address operator;
    }

    /**
     * @notice Container for strategy configuration parameters
     * @param registryContract address of Registry contract
     * @param vault address of vault contract
     * @param underlyingToken address of the underlying token
     * @param initialStepInputAmount value in lp token or underlying token at initial strategy step
     * @param internalTransactionIndex index of the internal transaction for a strategy to execute
     * @param internalTransactionCount count of internal transaction for a strategy to execute
     */
    struct StrategyConfigurationParams {
        address registryContract;
        address payable vault;
        address underlyingToken;
        uint256 initialStepInputAmount;
        uint256 internalTransactionIndex;
        uint256 internalTransactionCount;
    }
}