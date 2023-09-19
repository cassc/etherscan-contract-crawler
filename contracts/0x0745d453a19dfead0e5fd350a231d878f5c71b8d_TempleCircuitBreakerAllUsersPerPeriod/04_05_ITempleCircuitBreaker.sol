pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (interfaces/v2/circuitBreaker/ITempleCircuitBreaker.sol)

import { ITempleElevatedAccess } from "contracts/interfaces/v2/access/ITempleElevatedAccess.sol";

/**
 * @title Temple Circuit Breaker
 * 
 * @notice A circuit breaker can perform checks and record state for transactions which have
 * already happened cumulative totals, totals within a rolling period window,
 * sender specific totals, etc.
 */
interface ITempleCircuitBreaker is ITempleElevatedAccess {

    /**
     * @notice Verify the new amount requested for the sender does not breach the
     * cap in this rolling period.
     */
    function preCheck(address onBehalfOf, uint256 amount) external;
}