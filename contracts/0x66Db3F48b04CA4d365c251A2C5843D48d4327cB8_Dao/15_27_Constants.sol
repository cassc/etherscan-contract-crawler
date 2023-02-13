// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./external/Decimal.sol";

library Constants {
    /* Chain */
    uint256 private constant CHAIN_ID = 1; // Mainnet

    /* Bootstrapping */
    uint256 private constant BOOTSTRAPPING_SUPPLY = 1e24; // 1M pina supply
    uint256 private constant BOOTSTRAPPING_PRICE = 150e16; // 1.5 USDC (targeting 1% inflation)

    /* Oracle */
    address private constant USDC =
        address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    // address private constant USDC =
    //     address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);  //test network
    uint256 private constant ORACLE_RESERVE_MINIMUM = 1e10; // 10,000 USDC

    /* Bonding */
    uint256 private constant INITIAL_STAKE_MULTIPLE = 1e6; // 1 -> 1M

    /* Epoch */
    struct EpochStrategy {
        uint256 offset;
        uint256 start;
        uint256 period;
    }

    uint256 private constant EPOCH_OFFSET = 170;
    uint256 private constant EPOCH_START = 1673928000;  //
    uint256 private constant EPOCH_PERIOD = 21600;  // 6 hours per epoch

    /* DAO */
    uint256 private constant DAO_EXIT_LOCKUP_EPOCHS = 20; // 5 days fluid
    uint256 private constant COUPON_BONDING_TASK = 1; // TASK ID = 1

    /* Pool */
    uint256 private constant POOL_EXIT_LOCKUP_EPOCHS = 12; // 3 day fluid

    /* Regulator */
    uint256 private constant SUPPLY_CHANGE_LIMIT = 3e16; // 3%, 12.55% per day
    uint256 private constant SUPPLY_CHANGE_MIN = 1e15; // 0.1%, 0.4% per day
    uint256 private constant SUPPLY_CHANGE_DIVISOR = 10e18; // 50 > Max expansion at 1.5, Min 1.003
    uint256 private constant ORACLE_POOL_RATIO = 40; // 40%
    uint256 private constant DONTDIEMEME_POOL_RATIO = 20; // 20% to the dontdiememe artist pool / genesis pool / airdrop pool / P2E games rewards etc.

    /**
     * Getters
     */
    function getUsdcAddress() internal pure returns (address) {
        return USDC;
    }

    function getOracleReserveMinimum() internal pure returns (uint256) {
        return ORACLE_RESERVE_MINIMUM;
    }

    function getEpochStrategy() internal pure returns (EpochStrategy memory) {
        return
            EpochStrategy({
                offset: EPOCH_OFFSET,
                start: EPOCH_START,
                period: EPOCH_PERIOD
            });
    }

    function getInitialStakeMultiple() internal pure returns (uint256) {
        return INITIAL_STAKE_MULTIPLE;
    }

    function getBootstrappingSupply() internal pure returns (uint256) {
        return BOOTSTRAPPING_SUPPLY;
    }

    function getBootstrappingPrice()
        internal
        pure
        returns (Decimal.D256 memory)
    {
        return Decimal.D256({value: BOOTSTRAPPING_PRICE});
    }

    function getDAOExitLockupEpochs() internal pure returns (uint256) {
        return DAO_EXIT_LOCKUP_EPOCHS;
    }

    function getPoolExitLockupEpochs() internal pure returns (uint256) {
        return POOL_EXIT_LOCKUP_EPOCHS;
    }

    function getSupplyChangeLimit()
        internal
        pure
        returns (Decimal.D256 memory)
    {
        return Decimal.D256({value: SUPPLY_CHANGE_LIMIT});
    }

    function getSupplyChangeMin() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: SUPPLY_CHANGE_MIN});
    }

    function getSupplyChangeDivisor()
        internal
        pure
        returns (Decimal.D256 memory)
    {
        return Decimal.D256({value: SUPPLY_CHANGE_DIVISOR});
    }

    function getOraclePoolRatio() internal pure returns (uint256) {
        return ORACLE_POOL_RATIO;
    }

    function getDontDieMemePoolRatio() internal pure returns (uint256) {
        return DONTDIEMEME_POOL_RATIO;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getCouponTask() internal pure returns (uint256) {
        return COUPON_BONDING_TASK;
    }
}