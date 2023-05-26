// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

import "./RocketArbitrumPriceOracle.sol";
import "./interfaces/balancer/IRateProvider.sol";

/// @author Kane Wallmann (Rocket Pool)
/// @notice Implements Balancer's IRateProvider interface
contract RocketBalancerRateProvider is IRateProvider {
    RocketArbitrumPriceOracle immutable oracle;

    constructor(RocketArbitrumPriceOracle _oracle) {
        oracle = _oracle;
    }

    function getRate() external override view returns (uint256) {
        return oracle.rate();
    }
}