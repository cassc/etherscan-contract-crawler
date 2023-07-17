// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

/**
 * @title Interface of the Prime membership contract
 */
interface IPrime {
  /// @notice Member status enum
  enum MemberStatus {
    PENDING,
    WHITELISTED,
    BLACKLISTED
  }

  /// @notice A record of member info
  struct Member {
    uint256 riskScore;
    MemberStatus status;
    bool created;
  }

  /**
   * @notice Check membership status for a given `_member`
   * @param _member The address of member
   * @return Boolean flag containing membership status
   */
  function isMember(address _member) external view returns (bool);

  /**
   * @notice Check Stablecoin existence for a given `asset` address
   * @param asset The address of asset
   * @return Boolean flag containing asset availability
   */
  function isAssetAvailable(address asset) external view returns (bool);

  /**
   * @notice Get membership info for a given `_member`
   * @param _member The address of member
   * @return The member info struct
   */
  function membershipOf(address _member) external view returns (Member memory);

  /**
   * @notice Returns current protocol rate value
   * @return The protocol rate as a mantissa between [0, 1e18]
   */
  function spreadRate() external view returns (uint256);

  /**
   * @notice Returns current originated fee value
   * @return originated fee rate as a mantissa between [0, 1e18]
   */
  function originationRate() external view returns (uint256);

  /**
   * @notice Returns current rolling increment fee
   * @return rolling fee rate as a mantissa between [0, 1e18]
   */
  function incrementPerRoll() external view returns (uint256);

  /**
   * @notice Returns current protocol fee collector address
   * @return address of protocol fee collector
   */
  function treasury() external view returns (address);

  /**
   * @notice Returns current penalty rate for 1 year
   * @return penalty fee rate as a mantissa between [0, 1e18]
   */
  function penaltyRatePerYear() external view returns (uint256);
}