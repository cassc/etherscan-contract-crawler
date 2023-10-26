pragma solidity 0.8.19;
// SPDX-License-Identifier: AGPL-3.0-or-later
// Temple (interfaces/v2/circuitBreaker/ITempleCircuitBreakerProxy.sol)

import { ITempleElevatedAccess } from "contracts/interfaces/v2/access/ITempleElevatedAccess.sol";
import { ITempleCircuitBreaker } from "contracts/interfaces/v2/circuitBreaker/ITempleCircuitBreaker.sol";

/**
 * @title Temple Circuit Breaker Proxy
 * 
 * @notice Direct circuit breaker requests to the correct underlying implementation,
 * based on a pre-defined bytes32 identifier, and a token.
 */
interface ITempleCircuitBreakerProxy is ITempleElevatedAccess {
    event CircuitBreakerSet(bytes32 indexed identifier, address indexed token, address circuitBreaker);
    event IdentifierForCallerSet(address indexed caller, string identifierString, bytes32 identifier);

    /**
     * @notice A calling contract of the circuit breaker (eg TLC) is mapped to an identifier
     * which means circuit breaker caps can be shared across multiple callers.
     */
    function callerToIdentifier(address) external view returns (bytes32);

    /**
     * @notice The mapping of a (identifier, tokenAddress) tuple to the underlying circuit breaker contract
     */
    function circuitBreakers(
        bytes32 identifier, 
        address token
    ) external view returns (ITempleCircuitBreaker);

    /**
     * @notice Set the identifier for a given caller of the circuit breaker. These identifiers
     * can be shared, such that multiple contracts share the same cap limits for a given token.
     */
    function setIdentifierForCaller(
        address caller, 
        string memory identifierString
    ) external;

    /**
     * @notice Set the address of the circuit breaker for a particular identifier and token
     */
    function setCircuitBreaker(
        bytes32 identifier,
        address token,
        address circuitBreaker
    ) external;

    /**
     * @notice For a given identifier & token, verify the new amount requested for the sender does not breach the
     * cap in this rolling period.
     */
    function preCheck(
        address token,
        address onBehalfOf,
        uint256 amount
    ) external;

    /**
     * @notice The set of all identifiers registered
     */
    function identifiers() external view returns (bytes32[] memory);
}