// SPDX-License-Identifier: GPL-3
pragma solidity 0.8.19;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";

import { IVault } from "src/interfaces/balancer/IVault.sol";
import { IManagedPool } from "src/interfaces/balancer/IManagedPool.sol";
import { WeightedMath } from "src/interfaces/balancer/WeightedMath.sol";
import { IBasePool } from "src/interfaces/balancer/IBasePool.sol";
import { IRewardPool4626 } from "src/interfaces/aura/IRewardPool4626.sol";
import { IUniswapV2Pair } from "src/interfaces/univ2/IUniswapV2Pair.sol";
import { AggregatorV3Interface } from "src/interfaces/chainlink/AggregatorV3Interface.sol";

import { IMigrator } from "src/interfaces/IMigrator.sol";
import { IMigrationCalcs } from "src/interfaces/IMigrationCalcs.sol";

/**
 * @title Migration Calculations
 * @notice Tool to query the migration parameters for a given migration
 * @dev The output of this contract are the parameters for the migration function in Migrator.sol
 */
contract MigrationCalcs is IMigrationCalcs {
    uint256 internal immutable BPS = 10000;

    /**
     * @inheritdoc IMigrationCalcs
     */
    function getMigrationParams(
        MigrationCalcParams calldata params
    ) external view returns (IMigrator.MigrationParams memory) {
        // Calculate min amount of TOKEN and WETH from unwrapping UniV2 LP
        (uint256 amountTokenMin, uint256 amountWethMin) = calculateLpAmounts(
            params.slippage,
            params.amount,
            params.poolToken,
            params.wethPriceFeed,
            params.tokenPriceFeed
        );

        // Given an amount of TOKEN, calculate amount of WETH needed to create 80/20 TOKEN/WETH balance
        uint256 wethRequired = calculateWethRequired(amountTokenMin, params.balancerPoolToken, params.tokenPriceFeed);

        // Calculate amount of TOKEN out given the excess amount of WETH due to 80/20 TOKEN/WETH rebalance (amountWethMin is always > wethRequired)
        uint256 minAmountTokenOut = calculateTokenAmountOut(
            // Excess amount of WETH we are swapping for TOKEN
            amountWethMin - wethRequired,
            params.slippage,
            params.tokenPriceFeed
        );

        // Calculate expected amount of BPT out given TOKEN and WETH
        uint256 amountBptOut = calculateBptAmountOut(
            // Original and predicted swapped amounts of companion token
            amountTokenMin + minAmountTokenOut,
            wethRequired,
            params.balancerPoolToken,
            params.balancerPoolToken.getVault()
        );

        // Calculate expected amount of auraBPT out given BPT amount in
        uint256 amountAuraBptOut = calculateAuraBptAmountOut(amountBptOut, params.auraPool);

        // Create migration params struct from calculated values
        IMigrator.MigrationParams memory migrationParams = IMigrator.MigrationParams({
            balancerPoolToken:          params.balancerPoolToken,
            auraPool:                   params.auraPool,
            poolTokensIn:               params.amount,
            amountCompanionMinimumOut:  amountTokenMin,
            amountWETHMinimumOut:       amountWethMin,
            wethRequired:               wethRequired,
            minAmountTokenOut:          minAmountTokenOut,
            amountBalancerLiquidityOut: amountBptOut,
            amountAuraSharesMinimum:    amountAuraBptOut,
            stake:                      params.stakeBpt
        });

        return migrationParams;
    }

    /*
        Internal functions
    */

    /**
     * @notice Calculate the min amount of TOKEN and WETH for a given UniV2 LP amount
     * @param slippage Slippage tolerance
     * @param lpAmount The amount of UniV2 LP
     * @param poolToken UniV2 LP token address
     * @param tokenPriceFeed Chainlink TOKEN/WETH price feed
     * @param wethPriceFeed Chainlink WETH/USD price feed
     * @return Return values for min amount out of TOKEN and WETH with unwrap slippage
     */
    function calculateLpAmounts(
        uint256 slippage,
        uint256 lpAmount,
        IUniswapV2Pair poolToken,
        AggregatorV3Interface tokenPriceFeed,
        AggregatorV3Interface wethPriceFeed
    ) internal view returns (uint256, uint256) {
        (uint256 wethReserves, uint256 tokenReserves, ) = poolToken.getReserves();

        // Convert reserves into current USD price
        uint256 tokenReservesUsd = ((tokenReserves * tokenPrice(tokenPriceFeed)) * wethPrice(wethPriceFeed)) / 1 ether;
        uint256 wethReservesUsd = wethReserves * wethPrice(wethPriceFeed);

        // Get amounts in USD given the amount of UniV2 LP with slippage
        uint256 amountTokenUsd = (((lpAmount * tokenReservesUsd) / poolToken.totalSupply()) * (BPS - slippage)) / BPS;
        uint256 amountWethUsd = (((lpAmount * wethReservesUsd) / poolToken.totalSupply()) * (BPS - slippage)) / BPS;

        // Return tokens denominated in ETH
        uint256 amountTokenMin = (amountTokenUsd * 1 ether) / (tokenPrice(tokenPriceFeed) * wethPrice(wethPriceFeed));
        uint256 amountWethMin = (amountWethUsd) / wethPrice(wethPriceFeed);

        return (amountTokenMin, amountWethMin);
    }

    /**
     * @notice Given an amount of a companion token, calculate the amount of WETH to create an 80/20 TOKEN/WETH ratio
     * @param tokenAmount Amount of companion token
     * @param balancerPoolToken 80/20 TOKEN/WETH Balancer Pool Token
     * @param tokenPriceFeed Chainlink TOKEN/WETH price feed
     */
    function calculateWethRequired(
        uint256 tokenAmount,
        IBasePool balancerPoolToken,
        AggregatorV3Interface tokenPriceFeed
    ) internal view returns (uint256) {
        uint256[] memory normalizedWeights = IManagedPool(address(balancerPoolToken)).getNormalizedWeights();

        return (((tokenAmount * tokenPrice(tokenPriceFeed)) / 1 ether) * normalizedWeights[0]) / normalizedWeights[1];
    }

    /**
     * @notice Min amount of TOKEN swapped for WETH
     * @param wethAmount Amount of WETH to swap
     * @param slippage Slippage tolerance
     * @param tokenPriceFeed Chainlink TOKEN/WETH price feed
     * @dev This is the excess WETH swapped once we know expected rebalanced 80/20 amounts
     */
    function calculateTokenAmountOut(
        uint256 wethAmount,
        uint256 slippage,
        AggregatorV3Interface tokenPriceFeed
    ) internal view returns (uint256) {
        uint256 minAmountTokenOut = ((((wethAmount * tokenPrice(tokenPriceFeed)) / (1 ether)) * (BPS - slippage)) / BPS);

        return minAmountTokenOut;
    }

    /**
     * @notice Given an amount of tokens in, calculate the expected BPT out
     * @param wethAmountIn Amount of WETH
     * @param tokenAmountIn Amount of TOKEN
     * @param balancerPoolToken Balancer pool token
     * @param balancerVault Balancer vault
     */
    function calculateBptAmountOut(
        uint256 tokenAmountIn,
        uint256 wethAmountIn,
        IBasePool balancerPoolToken,
        IVault balancerVault
    ) internal view returns (uint256) {
        bytes32 balancerPoolId = IBasePool(balancerPoolToken).getPoolId();

        (, uint256[] memory balances, ) = IVault(balancerVault).getPoolTokens(balancerPoolId);
        uint256[] memory normalizedWeights = IManagedPool(address(balancerPoolToken)).getNormalizedWeights();

        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = wethAmountIn;
        amountsIn[1] = tokenAmountIn;

        uint256 amountOut = (
            WeightedMath._calcBptOutGivenExactTokensIn(
                balances,
                normalizedWeights,
                amountsIn,
                ERC20(address(balancerPoolToken)).totalSupply(),
                IBasePool(balancerPoolToken).getSwapFeePercentage()
            )
        );

        return amountOut;
    }

    /**
     * @notice Given an amount of BPT in, calculate the expected auraBPT out
     * @param bptAmountIn Amount of BPT
     * @param auraPool Address of the Aura pool
     */
    function calculateAuraBptAmountOut(uint256 bptAmountIn, IRewardPool4626 auraPool) internal view returns (uint256) {
        uint256 amountOut = IRewardPool4626(auraPool).previewDeposit(bptAmountIn);

        return amountOut;
    }

    /**
     * @notice Get the price of WETH in USD
     * @param wethPriceFeed Chainlink price feed for WETH
     * @dev Make sure price is not stale or incorrect
     * @return Return the correct price
     */
    function wethPrice(AggregatorV3Interface wethPriceFeed) internal view returns (uint256) {
        (uint80 roundId, int256 price, , uint256 timestamp, uint80 answeredInRound) = AggregatorV3Interface(wethPriceFeed).latestRoundData();

        require(answeredInRound >= roundId, "Stale price");
        require(timestamp != 0, "Round not complete");
        require(price > 0, "Chainlink answer reporting 0");

        return uint256(price);
    }

    /**
     * @notice Get the price of a companion token in WETH
     * @param tokenPriceFeed Chainlink price feed for the token
     * @dev Make sure price is not stale or incorrect
     * @return Return the correct price
     */
    function tokenPrice(AggregatorV3Interface tokenPriceFeed) internal view returns (uint256) {
        (uint80 roundId, int256 price, , uint256 timestamp, uint80 answeredInRound) = AggregatorV3Interface(tokenPriceFeed).latestRoundData();

        require(answeredInRound >= roundId, "Stale price");
        require(timestamp != 0, "Round not complete");
        require(price > 0, "Chainlink answer reporting 0");

        return uint256(price);
    }
}