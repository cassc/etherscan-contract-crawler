pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (interfaces/amo/IRamos.sol)

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IBalancerVault } from "contracts/interfaces/external/balancer/IBalancerVault.sol";
import { IBalancerBptToken } from "contracts/interfaces/external/balancer/IBalancerBptToken.sol";
import { IBalancerPoolHelper } from "contracts/interfaces/amo/helpers/IBalancerPoolHelper.sol";
import { IAuraStaking } from "contracts/interfaces/amo/IAuraStaking.sol";
import { ITreasuryPriceIndexOracle } from "contracts/interfaces/v2/ITreasuryPriceIndexOracle.sol";
import { IRamosTokenVault } from "contracts/interfaces/amo/helpers/IRamosTokenVault.sol";

/**
 * @title AMO built for a 50/50 balancer pool
 *
 * @notice RAMOS rebalances the pool to trend towards the Treasury Price Index (TPI).
 * In order to accomplish this:
 *   1. When the price is BELOW the TPI it will either:
 *      - Single side withdraw `protocolToken`
 *      - Single side add `quoteToken`
 *   2. When the price is ABOVE the TPI it will either:
 *      - Single side add `protocolToken`
 *      - Single side withdraw `quoteToken`
 * Any idle BPTs (Balancer LP tokens) are deposited into Aura to earn yield.
 * `protocolToken` can be sourced/disposed of by either having direct mint & burn rights or by
 * pulling and sending tokens to an address.
 */
interface IRamos {
    struct MaxRebalanceAmounts {
        uint256 bpt;
        uint256 quoteToken;
        uint256 protocolToken;
    }

    struct RebalanceFees {
        uint128 rebalanceJoinFeeBps;
        uint128 rebalanceExitFeeBps;
    }

    // Admin events
    event RecoveredToken(address token, address to, uint256 amount);
    event SetPostRebalanceDelta(uint64 deltaBps);
    event SetCooldown(uint64 cooldownSecs);
    event SetRebalancePercentageBounds(uint64 belowTpi, uint64 aboveTpi);
    event TpiOracleSet(address indexed tpiOracle);
    event TokenVaultSet(address indexed vault);
    event SetPoolHelper(address poolHelper);
    event SetMaxRebalanceAmounts(uint256 bptMaxAmount, uint256 quoteTokenMaxAmount, uint256 protocolTokenMaxAmount);
    event RebalanceFeesSet(uint256 rebalanceJoinFeeBps, uint256 rebalanceExitFeeBps);
    event FeeCollectorSet(address indexed feeCollector);

    // Rebalance events
    event RebalanceUpExit(uint256 bptAmountIn, uint256 protocolTokenRepaid, uint256 protocolTokenFee);
    event RebalanceDownExit(uint256 bptAmountIn, uint256 quoteTokenRepaid, uint256 quoteTokenFee);
    event RebalanceUpJoin(uint256 quoteTokenAmountIn, uint256 bptTokensStaked, uint256 quoteTokenFee);
    event RebalanceDownJoin(uint256 protocolTokenAmountIn, uint256 bptTokensStaked, uint256 protocolTokenFee);

    // Add/remove liquidity events
    event LiquidityAdded(uint256 quoteTokenAdded, uint256 protocolTokenAdded, uint256 bptReceived);
    event LiquidityRemoved(uint256 quoteTokenReceived, uint256 protocolTokenReceived, uint256 bptRemoved);
    event DepositAndStakeBptTokens(uint256 bptAmount);
    
    /// @notice The Balancer vault singleton
    function balancerVault() external view returns (IBalancerVault);

    /// @notice BPT token address for this LP
    function bptToken() external view returns (IBalancerBptToken);

    /// @notice Balancer pool helper contract
    function poolHelper() external view returns (IBalancerPoolHelper);

    /// @notice AMO contract for staking into aura 
    function amoStaking() external view returns (IAuraStaking);
  
    /// @notice The Protocol token  
    function protocolToken() external view returns (IERC20);

    /// @notice The quoteToken this is paired with in the LP. It may be a stable, 
    /// or another Balancer linear token like BB-A-USD
    function quoteToken() external view returns (IERC20);

    /// @notice The time when the last rebalance occured
    function lastRebalanceTimeSecs() external view returns (uint64);

    /// @notice The minimum amount of time which must pass since `lastRebalanceTimeSecs` before another rebalance
    /// can occur
    function cooldownSecs() external view returns (uint64);

    /// @notice The balancer 50/50 pool ID.
    function balancerPoolId() external view returns (bytes32);

    /// @notice Precision for BPS calculations. 1% == 100
    // solhint-disable-next-line func-name-mixedcase
    function BPS_PRECISION() external view returns (uint256);

    /// @notice The percentage bounds (in bps) beyond which to rebalance up or down
    function rebalancePercentageBoundLow() external view returns (uint64);
    function rebalancePercentageBoundUp() external view returns (uint64);

    /// @notice Maximum amount of tokens that can be rebalanced on each run
    function maxRebalanceAmounts() external view returns (
        uint256 bpt,
        uint256 quoteToken,
        uint256 protocolToken
    );

    /// @notice A limit on how much the price can be impacted by a rebalance. 
    /// A price change over this limit will revert. Specified in bps
    function postRebalanceDelta() external view returns (uint64);

    /// @notice protocolToken index in balancer pool. to avoid recalculation or external calls
    function protocolTokenBalancerPoolIndex() external view returns (uint64);

    /**
     * @notice The address to send proportion of rebalance as fees to
     */
    function feeCollector() external view returns (address);

    /**
     * @notice The maximum rebalance fee which can be set
     */
    function maxRebalanceFee() external view returns (uint256);

    /**
     * @notice The fees (in basis points) taken on a rebalance
     */
    function rebalanceFees() external view returns (
        uint128 rebalanceJoinFeeBps, 
        uint128 rebalanceExitFeeBps
    );

    /**
     * @notice Set the rebalance fees, in basis points
     * @param rebalanceJoinFeeBps The fee for when a `rebalanceUpJoin` or `rebalanceDownJoin` is performed
     * @param rebalanceExitFeeBps The fee for when a `rebalanceUpExit` or `rebalanceDownExit` is performed
     */
    function setRebalanceFees(uint256 rebalanceJoinFeeBps, uint256 rebalanceExitFeeBps) external;

    /**
     * @notice The Treasury Price Index (TPI) Oracle
     */
    function tpiOracle() external view returns (ITreasuryPriceIndexOracle);

    /**
     * @notice Set the Treasury Price Index (TPI) Oracle
     */
    function setTpiOracle(address tpiOracleAddress) external;

    /**
     * @notice The vault from where to borrow and repay the Protocol Token
     */
    function tokenVault() external view returns (IRamosTokenVault);

    /**
     * @notice Set the Treasury Price Index (TPI) Oracle
     */
    function setTokenVault(address vault) external;

    /**
     * @notice The Treasury Price Index - the target price of the Treasury, in `quoteTokenToken` terms.
     */
    function treasuryPriceIndex() external view returns (uint96);

    /**
     * @notice Rebalance up when `protocolToken` spot price is below TPI.
     * Single-side WITHDRAW `protocolToken` from balancer liquidity pool to raise price.
     * BPT tokens are withdrawn from Aura rewards staking contract and used for balancer
     * pool exit. 
     * Ramos rebalance fees are deducted from the amount of `protocolToken` returned from the exit
     * The remainder `protocolToken` are repaid to the `TokenVault`
     * @param bptAmountIn amount of BPT tokens going in balancer pool for exit
     * @param minProtocolTokenOut amount of `protocolToken` expected out of balancer pool
     */
    function rebalanceUpExit(
        uint256 bptAmountIn,
        uint256 minProtocolTokenOut
    ) external;

    /**
     * @notice Rebalance down when `protocolToken` spot price is above TPI.
     * Single-side WITHDRAW `quoteToken` from balancer liquidity pool to lower price.
     * BPT tokens are withdrawn from Aura rewards staking contract and used for balancer
     * pool exit. 
     * Ramos rebalance fees are deducted from the amount of `quoteToken` returned from the exit
     * The remainder `quoteToken` are repaid via the token vault
     * @param bptAmountIn Amount of BPT tokens to deposit into balancer pool
     * @param minQuoteTokenAmountOut Minimum amount of `quoteToken` expected to receive
     */
    function rebalanceDownExit(
        uint256 bptAmountIn,
        uint256 minQuoteTokenAmountOut
    ) external;

    /**
     * @notice Rebalance up when `protocolToken` spot price is below TPI.
     * Single-side ADD `quoteToken` into the balancer liquidity pool to raise price.
     * Returned BPT tokens are deposited and staked into Aura for rewards using the staking contract.
     * Ramos rebalance fees are deducted from the amount of `quoteToken` input
     * The remainder `quoteToken` are added into the balancer pool
     * @dev The `quoteToken` amount must be deposited into this contract first
     * @param quoteTokenAmountIn Amount of `quoteToken` to deposit into balancer pool
     * @param minBptOut Minimum amount of BPT tokens expected to receive
     */
    function rebalanceUpJoin(
        uint256 quoteTokenAmountIn,
        uint256 minBptOut
    ) external;

    /**
     * @notice Rebalance down when `protocolToken` spot price is above TPI.
     * Single-side ADD `protocolToken` into the balancer liquidity pool to lower price.
     * Returned BPT tokens are deposited and staked into Aura for rewards using the staking contract.
     * Ramos rebalance fees are deducted from the amount of `protocolToken` input
     * The remainder `protocolToken` are added into the balancer pool
     * @dev The `protocolToken` are borrowed from the `TokenVault`
     * @param protocolTokenAmountIn Amount of `protocolToken` tokens to deposit into balancer pool
     * @param minBptOut Minimum amount of BPT tokens expected to receive
     */
    function rebalanceDownJoin(
        uint256 protocolTokenAmountIn,
        uint256 minBptOut
    ) external;

    /**
     * @notice Add liquidity with both `protocolToken` and `quoteToken` into balancer pool. 
     * TPI is expected to be within bounds of multisig set range.
     * BPT tokens are then deposited and staked in Aura.
     * @param request Request data for joining balancer pool. Assumes userdata of request is
     * encoded with EXACT_TOKENS_IN_FOR_BPT_OUT type
     */
    function addLiquidity(
        IBalancerVault.JoinPoolRequest memory request
    ) external returns (
        uint256 quoteTokenAmount,
        uint256 protocolTokenAmount,
        uint256 bptTokensStaked
    );
    
    /**
     * @notice Remove liquidity from balancer pool receiving both `protocolToken` and `quoteToken` from balancer pool. 
     * TPI is expected to be within bounds of multisig set range.
     * Withdraw and unwrap BPT tokens from Aura staking and send to balancer pool to receive both tokens.
     * @param request Request for use in balancer pool exit
     * @param bptIn Amount of BPT tokens to send into balancer pool
     */
    function removeLiquidity(
        IBalancerVault.ExitPoolRequest memory request, 
        uint256 bptIn
    ) external returns (
        uint256 quoteTokenAmount,
        uint256 protocolTokenAmount
    );

    /**
     * @notice Allow owner to deposit and stake bpt tokens directly
     * @param amount Amount of Bpt tokens to depositt
     * @param useContractBalance If to use bpt tokens in contract
     */
    function depositAndStakeBptTokens(
        uint256 amount,
        bool useContractBalance
    ) external;

    /**
     * @notice The total amount of `protocolToken` and `quoteToken` that Ramos holds via it's 
     * staked and unstaked BPT.
     * @dev Calculated by pulling the total balances of each token in the pool
     * and getting RAMOS proportion of the owned BPT's
     */
    function positions() external view returns (
        uint256 bptBalance, 
        uint256 protoclTokenBalance, 
        uint256 quoteTokenBalance
    );
}