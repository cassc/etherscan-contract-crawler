// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

interface ISponsorship {
  /// Amount of souls sponsored by this address
  function scoreOf(uint256 tokenId) external view returns (uint256);

  /// Retrieve the sponsor for a given token ID
  function sponsorOf(uint256 tokenId) external view returns (uint256);

  /// Adds a new sponsorship
  function create(uint256 sponsor, uint256 recipient) external;
}