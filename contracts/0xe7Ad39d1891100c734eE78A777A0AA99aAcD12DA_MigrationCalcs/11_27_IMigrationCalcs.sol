// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.19;


import { IUniswapV2Pair } from "src/interfaces/univ2/IUniswapV2Pair.sol";
import { IBasePool } from "src/interfaces/balancer/IBasePool.sol";
import { IRewardPool4626 } from "src/interfaces/aura/IRewardPool4626.sol";
import { AggregatorV3Interface } from "src/interfaces/chainlink/AggregatorV3Interface.sol";

import { IMigrator } from "src/interfaces/IMigrator.sol";

interface IMigrationCalcs {
    /**
     * @notice Parameters required to make migration calculations
     */
    struct MigrationCalcParams {
        // Whether to stake the BPT in the Aura pool
        bool stakeBpt;
        // Amount of UniV2 LP tokens to migrate
        uint256 amount;
        // Slippage tolerance (10 = 0.1%)
        uint256 slippage;
        // UniV2 LP token address
        IUniswapV2Pair poolToken;
        // 80/20 TOKEN/WETH Balancer Pool Token
        IBasePool balancerPoolToken;
        // ERC4626 Aura pool address
        IRewardPool4626 auraPool;
        // Chainlink WETH/USD price feed
        AggregatorV3Interface wethPriceFeed;
        // Chainlink TOKEN/WETH price feed
        AggregatorV3Interface tokenPriceFeed;
    }

    /**
     * @notice Get the parameters required for calling the migration function
     * @param params MigrationCalcParams required to make migration calculations
     * @return MigrationParams struct for calling the migration function
     */
    function getMigrationParams(
        MigrationCalcParams calldata params
    ) external view returns (IMigrator.MigrationParams memory);
}