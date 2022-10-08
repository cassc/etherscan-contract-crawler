// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PRECISION, PRECISION_DOUBLE} from "../BaseConstants.sol";
import {LogExpMath} from "../lib/balancer/LogExpMath.sol";
import {AuraConstants} from "./AuraConstants.sol";

import {IAuraToken} from "../interfaces/aura/IAuraToken.sol";
import {IAsset} from "../interfaces/balancer/IAsset.sol";
import {IBalancerVault} from "../interfaces/balancer/IBalancerVault.sol";
import {IWeightedPool} from "../interfaces/balancer/IWeightedPool.sol";
import {IPriceOracle} from "../interfaces/balancer/IPriceOracle.sol";
import {IAggregatorV3} from "../interfaces/chainlink/IAggregatorV3.sol";

contract AuraAvatarUtils is AuraConstants {
    ////////////////////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////////////////////

    error StalePriceFeed(uint256 currentTime, uint256 updateTime, uint256 maxPeriod);

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL VIEW
    ////////////////////////////////////////////////////////////////////////////

    function getAuraPriceInUsdSpot(uint256 _auraAmount) internal returns (uint256 usdPrice_) {
        usdPrice_ = querySwapAuraForUsdc(_auraAmount) * AURA_USD_SPOT_FACTOR / _auraAmount;
    }

    function getBalAmountInUsdc(uint256 _balAmount) internal view returns (uint256 usdcAmount_) {
        uint256 balInUsd = fetchPriceFromClFeed(BAL_USD_FEED, CL_FEED_HEARTBEAT_BAL);
        // Divisor is 10^20 and uint256 max ~ 10^77 so this shouldn't overflow for normal amounts
        usdcAmount_ = (_balAmount * balInUsd) / BAL_USD_FEED_DIVISOR;
    }

    function getAuraAmountInUsdc(uint256 _auraAmount, uint256 _twapPeriod)
        internal
        view
        returns (uint256 usdcAmount_)
    {
        uint256 auraInEth = fetchPriceFromBalancerTwap(BPT_80AURA_20WETH, _twapPeriod);
        uint256 ethInUsd = fetchPriceFromClFeed(ETH_USD_FEED, CL_FEED_HEARTBEAT_ETH_USD);
        // Divisor is 10^38 and uint256 max ~ 10^77 so this shouldn't overflow for normal amounts
        usdcAmount_ = (_auraAmount * auraInEth * ethInUsd) / AURA_USD_TWAP_DIVISOR;
    }

    function getBalAmountInBpt(uint256 _balAmount) internal view returns (uint256 bptAmount_) {
        uint256 bptPriceInBal = getBptPriceInBal();
        bptAmount_ = (_balAmount * PRECISION) / bptPriceInBal;
    }

    function querySwapAuraForUsdc(uint256 _auraAmount) internal returns (uint256 usdcEarned_) {
        IAsset[] memory assetArray = new IAsset[](3);
        assetArray[0] = IAsset(address(AURA));
        assetArray[1] = IAsset(address(WETH));
        assetArray[2] = IAsset(address(USDC));

        IBalancerVault.BatchSwapStep[] memory swaps = new IBalancerVault.BatchSwapStep[](2);
        // AURA --> WETH
        swaps[0] = IBalancerVault.BatchSwapStep({
            poolId: AURA_WETH_POOL_ID,
            assetInIndex: 0,
            assetOutIndex: 1,
            amount: _auraAmount,
            userData: new bytes(0)
        });
        // WETH --> USDC
        swaps[1] = IBalancerVault.BatchSwapStep({
            poolId: USDC_WETH_POOL_ID,
            assetInIndex: 1,
            assetOutIndex: 2,
            amount: 0, // 0 means all from last step
            userData: new bytes(0)
        });

        IBalancerVault.FundManagement memory fundManagement = IBalancerVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        int256[] memory assetDeltas =
            BALANCER_VAULT.queryBatchSwap(IBalancerVault.SwapKind.GIVEN_IN, swaps, assetArray, fundManagement);

        usdcEarned_ = uint256(-assetDeltas[assetDeltas.length - 1]);
    }

    /// @notice Calculates the price of 80BAL-20WETH BPT in BAL using the BAL-ETH CL feed.
    /// @return bptPriceInBal_ The price of 80BAL-20WETH BPT in BAL.
    function getBptPriceInBal() internal view returns (uint256 bptPriceInBal_) {
        uint256 ethPriceInBal = PRECISION_DOUBLE / fetchPriceFromClFeed(BAL_ETH_FEED, CL_FEED_HEARTBEAT_BAL);

        uint256 invariant = IWeightedPool(address(BPT_80BAL_20WETH)).getInvariant();
        uint256 totalSupply = BPT_80BAL_20WETH.totalSupply();

        // p1: Price of BAL
        // p2: Price of ETH
        //        w1         w2
        //  / p1 \     / p2 \
        // |  --  | . |  --  |
        //  \ w1 /     \ w2 /
        // -------------------
        //          p1
        uint256 priceMultiplier = LogExpMath.pow(
            ethPriceInBal * W1_BPT_80BAL_20WETH / W2_BPT_80BAL_20WETH, W2_BPT_80BAL_20WETH
        ) * PRECISION / W1_BPT_80BAL_20WETH;

        bptPriceInBal_ = invariant * priceMultiplier / totalSupply;
    }

    /// @notice Calculates the expected amount of AURA minted given some BAL rewards.
    /// @dev ref: https://etherscan.io/address/0xc0c293ce456ff0ed870add98a0828dd4d2903dbf#code#F1#L86
    /// @param _balAmount The input BAL reward amount.
    /// @return auraAmount_ The expected amount of AURA minted.
    function getMintableAuraForBalAmount(uint256 _balAmount) internal view returns (uint256 auraAmount_) {
        // NOTE: Only correct if AURA.minterMinted() == 0
        // minterMinted is a private var in the contract, so no way to access it on-chain
        uint256 emissionsMinted = AURA.totalSupply() - IAuraToken(address(AURA)).INIT_MINT_AMOUNT();

        uint256 cliff = emissionsMinted / IAuraToken(address(AURA)).reductionPerCliff();
        uint256 totalCliffs = IAuraToken(address(AURA)).totalCliffs();

        if (cliff < totalCliffs) {
            uint256 reduction = (((totalCliffs - cliff) * 5) / 2) + 700;
            auraAmount_ = (_balAmount * reduction) / totalCliffs;

            uint256 amtTillMax = IAuraToken(address(AURA)).EMISSIONS_MAX_SUPPLY() - emissionsMinted;
            if (auraAmount_ > amtTillMax) {
                auraAmount_ = amtTillMax;
            }
        }
    }

    function fetchPriceFromClFeed(IAggregatorV3 _feed, uint256 _maxStalePeriod)
        internal
        view
        returns (uint256 answerUint256_)
    {
        (, int256 answer,, uint256 updateTime,) = _feed.latestRoundData();

        if (block.timestamp - updateTime > _maxStalePeriod) {
            revert StalePriceFeed(block.timestamp, updateTime, _maxStalePeriod);
        }

        answerUint256_ = uint256(answer);
    }

    function fetchPriceFromBalancerTwap(IPriceOracle _pool, uint256 _twapPeriod)
        internal
        view
        returns (uint256 price_)
    {
        IPriceOracle.OracleAverageQuery[] memory queries = new IPriceOracle.OracleAverageQuery[](1);

        queries[0].variable = IPriceOracle.Variable.PAIR_PRICE;
        queries[0].secs = _twapPeriod;
        queries[0].ago = 0; // now

        // Gets the balancer time weighted average price denominated in BAL
        price_ = _pool.getTimeWeightedAverage(queries)[0];
    }
}