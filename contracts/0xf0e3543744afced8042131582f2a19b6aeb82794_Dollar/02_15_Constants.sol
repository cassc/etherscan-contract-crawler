/*
    Copyright 2020 VTD team, based on the works of Dynamic Dollar Devs and Empty Set Squad

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./external/Decimal.sol";

library Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet

    /* Bootstrapping */
    uint256 private constant BOOTSTRAPPING_PERIOD = 36; // 36 epochs IMPORTANT
    uint256 private constant BOOTSTRAPPING_PERIOD_PHASE1 = 11; // 12 epochs to speed up deployment IMPORTANT
    uint256 private constant BOOTSTRAPPING_PRICE = 196e16; // 1.96 pegged token (targeting 8% inflation)

    /* Oracle */
    //pegs to DSD during bootstrap. variable name not renamed on purpose until DAO votes on the peg.
    //IMPORTANT 0xBD2F0Cd039E0BFcf88901C98c0bFAc5ab27566e3
    address private constant USDC = address(0xBD2F0Cd039E0BFcf88901C98c0bFAc5ab27566e3); 
    uint256 private constant ORACLE_RESERVE_MINIMUM = 1e9; // 1,000 pegged token, 1e9 IMPORTANT

    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1e6; // 100 VTD -> 100M VTDD

    /* Epoch */
    uint256 private constant EPOCH_START = 1609405200;
    uint256 private constant EPOCH_BASE = 7200; //two hours IMPORTANT
    uint256 private constant EPOCH_GROWTH_CONSTANT = 12000; //3.3 hrs
    uint256 private constant P1_EPOCH_BASE = 300; // IMPORTANT
    uint256 private constant P1_EPOCH_GROWTH_CONSTANT = 2000; // IMPORTANT
    uint256 private constant ADVANCE_LOTTERY_TIME = 91; // 7 average block lengths

    /* Governance */
    uint256 private constant GOVERNANCE_PERIOD = 8; // 1 dayish governance period IMPORTANT
    uint256 private constant GOVERNANCE_QUORUM = 20e16; // 20%
    uint256 private constant GOVERNANCE_SUPER_MAJORITY = 51e16; // 51%
    uint256 private constant GOVERNANCE_EMERGENCY_DELAY = 21600; // 6 hours

    /* DAO */
    uint256 private constant ADVANCE_INCENTIVE = 50e18; // 50 VTD
    uint256 private constant ADVANCE_INCENTIVE_BOOTSTRAP = 50e18; // 100 VTD during phase 1 bootstrap
    uint256 private constant DAO_EXIT_LOCKUP_EPOCHS = 18; // 18 epoch fluid IMPORTANT

    /* Pool */
    uint256 private constant POOL_EXIT_LOCKUP_EPOCHS = 9; // 9 epoch fluid IMPORTANT

    /* Market */
    uint256 private constant COUPON_EXPIRATION = 180; //30 days
    uint256 private constant DEBT_RATIO_CAP = 35e16; // 35%
    uint256 private constant INITIAL_COUPON_REDEMPTION_PENALTY = 50e16; // 50%
    uint256 private constant COUPON_REDEMPTION_PENALTY_DECAY = 3600; // 1 hour

    /* Regulator */
    uint256 private constant SUPPLY_CHANGE_DIVISOR = 12e18; // 12
    uint256 private constant SUPPLY_CHANGE_LIMIT = 10e16; // 10%
    uint256 private constant ORACLE_POOL_RATIO = 30; // 30%

    /**
     * Getters
     */
    function getEpochStart() internal pure returns (uint256) {
        return EPOCH_START;
    }

    function getP1EpochBase() internal pure returns (uint256) {
        return P1_EPOCH_BASE;
    }

    function getP1EpochGrowthConstant() internal pure returns (uint256) {
        return P1_EPOCH_GROWTH_CONSTANT;
    }

    function getEpochBase() internal pure returns (uint256) {
        return EPOCH_BASE;
    }

    function getEpochGrowthConstant() internal pure returns (uint256) {
        return EPOCH_GROWTH_CONSTANT;
    }

    function getUsdcAddress() internal pure returns (address) {
        return USDC;
    }

    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
    }

    function getAdvanceLotteryTime() internal pure returns (uint256){
        return ADVANCE_LOTTERY_TIME;
    }

    function getBootstrappingPeriod() internal pure returns (uint256) {
        return BOOTSTRAPPING_PERIOD;
    }

    function getPhaseOnePeriod() internal pure returns (uint256) {
        return BOOTSTRAPPING_PERIOD_PHASE1;
    }

    function getBootstrappingPrice() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: BOOTSTRAPPING_PRICE});
    }

    function getGovernancePeriod() internal pure returns (uint256) {
        return GOVERNANCE_PERIOD;
    }

    function getGovernanceQuorum() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_QUORUM});
    }

    function getGovernanceSuperMajority() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_SUPER_MAJORITY});
    }

    function getGovernanceEmergencyDelay() internal pure returns (uint256) {
        return GOVERNANCE_EMERGENCY_DELAY;
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return ADVANCE_INCENTIVE;
    }

    function getAdvanceIncentiveBootstrap() internal pure returns (uint256) {
        return ADVANCE_INCENTIVE_BOOTSTRAP;
    }

    function getDAOExitLockupEpochs() internal pure returns (uint256) {
        return DAO_EXIT_LOCKUP_EPOCHS;
    }

    function getPoolExitLockupEpochs() internal pure returns (uint256) {
        return POOL_EXIT_LOCKUP_EPOCHS;
    }

    function getCouponExpiration() internal pure returns (uint256) {
        return COUPON_EXPIRATION;
    }

    function getDebtRatioCap() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: DEBT_RATIO_CAP});
    }
    
    function getInitialCouponRedemptionPenalty() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: INITIAL_COUPON_REDEMPTION_PENALTY});
    }

    function getCouponRedemptionPenaltyDecay() internal pure returns (uint256) {
        return COUPON_REDEMPTION_PENALTY_DECAY;
    }

    function getSupplyChangeLimit() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_LIMIT});
    }

    function getSupplyChangeDivisor() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_DIVISOR});
    }

    function getOraclePoolRatio() internal pure returns (uint256) {
        return ORACLE_POOL_RATIO;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }
}