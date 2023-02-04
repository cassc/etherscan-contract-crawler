//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

library SlippageLib {
    error CostAboveTolerance(uint256 limitCost, uint256 actualCost);
    error CostBelowTolerance(uint256 limitCost, uint256 actualCost);

    function requireCostAboveTolerance(uint256 cost, uint256 limitCost) internal pure {
        if (cost < limitCost) revert CostBelowTolerance(limitCost, cost);
    }

    function requireCostBelowTolerance(uint256 cost, uint256 limitCost) internal pure {
        if (cost > limitCost) revert CostAboveTolerance(limitCost, cost);
    }
}