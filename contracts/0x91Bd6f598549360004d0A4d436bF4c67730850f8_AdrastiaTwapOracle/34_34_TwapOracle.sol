//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@adrastia-oracle/adrastia-periphery/contracts/oracles/ManagedPeriodicAccumulationOracle.sol";

import "../AdrastiaVersioning.sol";

contract AdrastiaTwapOracle is AdrastiaVersioning, ManagedPeriodicAccumulationOracle {
    string public name;

    constructor(
        string memory name_,
        address liquidityAccumulator_,
        address priceAccumulator_,
        address quoteToken_,
        uint256 period_
    ) ManagedPeriodicAccumulationOracle(liquidityAccumulator_, priceAccumulator_, quoteToken_, period_) {
        name = name_;
    }
}