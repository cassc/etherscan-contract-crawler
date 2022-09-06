//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IAccumulator
 * @notice An interface that defines an accumulator - that is, a contract that updates cumulative value(s) when the
 *   underlying value(s) change by more than the update threshold.
 */
abstract contract IAccumulator {
    /// @notice Gets the scalar (as a power of 10) to be used for calculating changes in value.
    /// @return The scalar to be used for calculating changes in value.
    function changePrecision() external view virtual returns (uint256);

    /// @notice Gets the threshold at which an update to the cumulative value(s) should be performed.
    /// @return A percentage scaled by the change precision.
    function updateThreshold() external view virtual returns (uint256);

    /// @notice Determines whether the specified change threshold has been surpassed for the specified token.
    /// @dev Calculates the change from the stored observation to the current observation.
    /// @param token The token to check.
    /// @param changeThreshold The change threshold as a percentage multiplied by the change precision
    ///   (`changePrecision`). Ex: a 1% change is respresented as 0.01 * `changePrecision`.
    /// @return surpassed True if the update threshold has been surpassed; false otherwise.
    function changeThresholdSurpassed(address token, uint256 changeThreshold) public view virtual returns (bool);

    /// @notice Determines whether the update threshold has been surpassed for the specified token.
    /// @dev Calculates the change from the stored observation to the current observation.
    /// @param token The token to check.
    /// @return surpassed True if the update threshold has been surpassed; false otherwise.
    function updateThresholdSurpassed(address token) public view virtual returns (bool);
}