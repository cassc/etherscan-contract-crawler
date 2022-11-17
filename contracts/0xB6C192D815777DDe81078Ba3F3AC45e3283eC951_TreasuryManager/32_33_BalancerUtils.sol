// SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "IPriceOracle.sol";

library BalancerUtils {
    function getTimeWeightedOraclePrice(
        address pool,
        IPriceOracle.Variable variable,
        uint256 secs
    ) internal view returns (uint256) {
        IPriceOracle.OracleAverageQuery[]
            memory queries = new IPriceOracle.OracleAverageQuery[](1);

        queries[0].variable = variable;
        queries[0].secs = secs;
        queries[0].ago = 0; // now

        // Gets the balancer time weighted average price denominated in ETH
        return IPriceOracle(pool).getTimeWeightedAverage(queries)[0];
    }
}