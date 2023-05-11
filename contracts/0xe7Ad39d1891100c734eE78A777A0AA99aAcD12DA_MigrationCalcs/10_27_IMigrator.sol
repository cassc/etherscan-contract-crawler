// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.19;

import { IBasePool } from "src/interfaces/balancer/IBasePool.sol";
import { IRewardPool4626 } from "src/interfaces/aura/IRewardPool4626.sol";

interface IMigrator {
    /**
     * @notice Represents the addresses, migration details, and calculations required for migration
     */
    struct MigrationParams {
        // 80/20 TOKEN/WETH Balancer Pool Token
        IBasePool balancerPoolToken;
        // ERC4626 Aura pool address
        IRewardPool4626 auraPool;
        // Amount of LP tokens to be migrated
        uint256 poolTokensIn;
        // Minimum amount of Tokens to be received from the LP
        uint256 amountCompanionMinimumOut;
        // Minimum amount of WETH to be received from the LP
        uint256 amountWETHMinimumOut;
        // Amount of WETH required to create an 80/20 TOKEN/WETH balance
        uint256 wethRequired;
        // Minimum amount of Tokens from swapping excess WETH due to the 80/20 TOKEN/WETH rebalance (amountWethMin is always > wethRequired)
        uint256 minAmountTokenOut;
        // Amount of BPT to be received given the rebalanced Token and WETH amounts
        uint256 amountBalancerLiquidityOut;
        // Amount of auraBPT to be received given the amount of BPT deposited
        uint256 amountAuraSharesMinimum;
        // Indicates whether to stake the migrated BPT in the Aura pool
        bool stake;
    }

    /**
     * @notice Emitted when an account migrates from UniV2 LP to BPT or auraBPT
     * @param account The account migrating
     * @param poolToken The UniV2 LP token address
     * @param balancerPoolToken The balancer pool address
     * @param poolTokenAmount Amount of UniV2 LP tokens migrated
     * @param balancerPoolTokenAmount The amount of BPT or auraBPT received
     * @param staked Indicates if the account staked BPT in the Aura pool
     */
    event Migrated(
        address indexed account,
        address indexed poolToken,
        address indexed balancerPoolToken,
        uint256 poolTokenAmount,
        uint256 balancerPoolTokenAmount,
        bool staked
    );

    /**
     * @notice Migrate UniV2 LP position into BPT position
     * @param params Migration addresses, details, and calculations
     */
    function migrate(MigrationParams calldata params) external;
}