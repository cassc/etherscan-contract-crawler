// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IQuorum {
  /// @dev Emitted when the threshold is updated
  event ThresholdUpdated(
    uint256 indexed nonce,
    uint256 indexed numerator,
    uint256 indexed denominator,
    uint256 previousNumerator,
    uint256 previousDenominator
  );

  /**
   * @dev Returns the threshold.
   */
  function getThreshold() external view returns (uint256 _num, uint256 _denom);

  /**
   * @dev Checks whether the `_voteWeight` passes the threshold.
   */
  function checkThreshold(uint256 _voteWeight) external view returns (bool);

  /**
   * @dev Returns the minimum vote weight to pass the threshold.
   */
  function minimumVoteWeight() external view returns (uint256);

  /**
   * @dev Sets the threshold.
   *
   * Requirements:
   * - The method caller is admin.
   *
   * Emits the `ThresholdUpdated` event.
   *
   */
  function setThreshold(uint256 _numerator, uint256 _denominator)
    external
    returns (uint256 _previousNum, uint256 _previousDenom);
}