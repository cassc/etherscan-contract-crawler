// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./IAntfarmBase.sol";

interface IAntfarmPair is IAntfarmBase {
    /// @notice Initialize the pair
    /// @dev Can only be called by the factory
    function initialize(
        address,
        address,
        uint16,
        address
    ) external;

    /// @notice The Antfarm token address
    /// @return address Address
    function antfarmToken() external view returns (address);

    /// @notice The Oracle instance used to compute swap's fees
    /// @return AntfarmOracle Oracle instance
    function antfarmOracle() external view returns (address);

    /// @notice Calcul fee to pay
    /// @param amount0Out The token0 amount going out of the pool
    /// @param amount0In The token0 amount going in the pool
    /// @param amount1Out The token1 amount going out of the pool
    /// @param amount1In The token1 amount going in the pool
    /// @return feeToPay Calculated fee to be paid
    function getFees(
        uint256 amount0Out,
        uint256 amount0In,
        uint256 amount1Out,
        uint256 amount1In
    ) external view returns (uint256 feeToPay);

    /// @notice Check for the best Oracle to use to perform fee calculation for a swap
    /// @dev Returns address(0) if no better oracle is found.
    /// @param maxReserve Actual oracle reserve0
    /// @return bestOracle Address from the best oracle found
    function scanOracles(uint112 maxReserve)
        external
        view
        returns (address bestOracle);

    /// @notice Update oracle for token
    /// @custom:usability Update the current Oracle with a more suitable one. Revert if the current Oracle is already the more suitable
    function updateOracle() external;
}