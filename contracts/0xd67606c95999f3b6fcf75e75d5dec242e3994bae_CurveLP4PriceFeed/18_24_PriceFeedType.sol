// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.10;

// NOTE: new values must always be added at the end of the enum

enum PriceFeedType {
    CHAINLINK_ORACLE,
    YEARN_ORACLE,
    CURVE_2LP_ORACLE,
    CURVE_3LP_ORACLE,
    CURVE_4LP_ORACLE,
    ZERO_ORACLE,
    WSTETH_ORACLE,
    BOUNDED_ORACLE,
    COMPOSITE_ORACLE,
    AAVE_ORACLE,
    COMPOUND_ORACLE,
    BALANCER_STABLE_LP_ORACLE,
    BALANCER_WEIGHTED_LP_ORACLE,
    CURVE_CRYPTO_ORACLE,
    REDSTONE_ORACLE
}