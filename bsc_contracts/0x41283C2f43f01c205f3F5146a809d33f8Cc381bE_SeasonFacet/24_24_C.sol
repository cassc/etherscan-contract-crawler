/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "./interfaces/pancake/IPancakePair.sol";
import "./interfaces/ITopcorn.sol";
import "./libraries/Decimal.sol";

/**
 * @title C holds the contracts for Farmer.
 **/
library C {
    using Decimal for Decimal.D256;

    // Constants
    uint256 private constant PERCENT_BASE = 1e18; // BSC

    // Chain
    uint256 private constant CHAIN_ID = 56; // BSC

    // Season
    uint256 private constant CURRENT_SEASON_PERIOD = 3600; // 1 hour
    uint256 private constant REWARD_MULTIPLIER = 1;
    uint256 private constant MAX_TIME_MULTIPLIER = 100; // seconds

    // Sun
    uint256 private constant HARVESET_PERCENTAGE = 0.5e18; // 50%

    // Weather
    uint256 private constant POD_RATE_LOWER_BOUND = 0.05e18; // 5%
    uint256 private constant OPTIMAL_POD_RATE = 0.15e18; // 15%
    uint256 private constant POD_RATE_UPPER_BOUND = 0.25e18; // 25%

    uint256 private constant DELTA_POD_DEMAND_LOWER_BOUND = 0.95e18; // 95%
    uint256 private constant DELTA_POD_DEMAND_UPPER_BOUND = 1.05e18; // 105%

    uint32 private constant STEADY_SOW_TIME = 60; // 1 minute
    uint256 private constant RAIN_TIME = 24; // 24 seasons = 1 day

    // Silo
    uint256 private constant BASE_ADVANCE_INCENTIVE = 100e18; // 100 topcorn
    uint32 private constant WITHDRAW_TIME = 25; // 24 + 1 seasons
    uint256 private constant SEEDS_PER_TOPCORN = 2;
    uint256 private constant SEEDS_PER_LP_TOPCORN = 4;
    uint256 private constant STALK_PER_TOPCORN = 10000;
    uint256 private constant ROOTS_BASE = 1e12;

    // Bsc contracts
    address private constant FACTORY = address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    address private constant ROUTER = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address private constant PEG_PAIR = address(0x58F876857a02D6762E0101bb5C46A8c1ED44Dc16);
    address private constant BUSD_TOKEN = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    /**
     * Getters
     **/

    function getSeasonPeriod() internal pure returns (uint256) {
        return CURRENT_SEASON_PERIOD;
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return BASE_ADVANCE_INCENTIVE;
    }

    function getSiloWithdrawSeasons() internal pure returns (uint32) {
        return WITHDRAW_TIME;
    }

    function getHarvestPercentage() internal pure returns (uint256) {
        return HARVESET_PERCENTAGE;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getOptimalPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(OPTIMAL_POD_RATE, PERCENT_BASE);
    }

    function getUpperBoundPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(POD_RATE_UPPER_BOUND, PERCENT_BASE);
    }

    function getLowerBoundPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(POD_RATE_LOWER_BOUND, PERCENT_BASE);
    }

    function getUpperBoundDPD() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(DELTA_POD_DEMAND_UPPER_BOUND, PERCENT_BASE);
    }

    function getLowerBoundDPD() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(DELTA_POD_DEMAND_LOWER_BOUND, PERCENT_BASE);
    }

    function getSteadySowTime() internal pure returns (uint32) {
        return STEADY_SOW_TIME;
    }

    function getRainTime() internal pure returns (uint256) {
        return RAIN_TIME;
    }

    function getSeedsPerTopcorn() internal pure returns (uint256) {
        return SEEDS_PER_TOPCORN;
    }

    function getSeedsPerLP() internal pure returns (uint256) {
        return SEEDS_PER_LP_TOPCORN;
    }

    function getStalkPerTopcorn() internal pure returns (uint256) {
        return STALK_PER_TOPCORN;
    }

    function getStalkPerLPSeed() internal pure returns (uint256) {
        return STALK_PER_TOPCORN / SEEDS_PER_LP_TOPCORN;
    }

    function getRootsBase() internal pure returns (uint256) {
        return ROOTS_BASE;
    }

    function getFactory() internal pure returns (address) {
        return FACTORY;
    }

    function getRouter() internal pure returns (address) {
        return ROUTER;
    }

    function getPegPair() internal pure returns (address) {
        return PEG_PAIR;
    }

    function getRewardMultiplier() internal pure returns (uint256) {
        return REWARD_MULTIPLIER;
    }

    function getMaxTimeMultiplier() internal pure returns (uint256) {
        return MAX_TIME_MULTIPLIER;
    }

    function getBUSD() internal pure returns (address) {
        return BUSD_TOKEN;
    }
}