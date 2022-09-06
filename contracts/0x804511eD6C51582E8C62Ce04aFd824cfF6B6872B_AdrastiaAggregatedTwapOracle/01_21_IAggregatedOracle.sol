//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./IOracle.sol";

/**
 * @title IAggregatedOracle
 * @notice An interface that defines a price and liquidity oracle that aggregates consulations from many underlying
 *  oracles.
 */
abstract contract IAggregatedOracle is IOracle {
    /// @notice Emitted when an underlying oracle (or this oracle) throws an update error with a reason.
    /// @param oracle The address or the oracle throwing the error.
    /// @param token The token for which the oracle is throwing the error.
    /// @param reason The reason for or description of the error.
    event UpdateErrorWithReason(address indexed oracle, address indexed token, string reason);

    /// @notice Emitted when an underlying oracle (or this oracle) throws an update error without a reason.
    /// @param oracle The address or the oracle throwing the error.
    /// @param token The token for which the oracle is throwing the error.
    /// @param err Data corresponding with a low level error being thrown.
    event UpdateError(address indexed oracle, address indexed token, bytes err);

    /// @notice Gets the addresses of all underlying oracles that are used for all consultations.
    /// @dev Oracles only used for specific tokens are not included.
    /// @return An array of the addresses of all underlying oracles that are used for all consultations.
    function getOracles() external view virtual returns (address[] memory);

    /**
     * @notice Gets the addresses of all underlying oracles that are consulted with in regards to the specified token.
     * @param token The address of the token for which to get all of the consulted oracles.
     * @return An array of the addresses of all underlying oracles that are consulted with in regards to the specified
     *  token.
     */
    function getOraclesFor(address token) external view virtual returns (address[] memory);
}