// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

import './interfaces/ISponsorship.sol';
import './Authorizable.sol';

contract Sponsorship is ISponsorship, Authorizable {
  /// Mapping from token ID to number of sponsorships given
  mapping(uint256 => uint256) public scores;

  /// Mapping from beneficiary to sponsor token ID
  mapping(uint256 => uint256) public sponsors;

  /// Amount of souls sponsored by this address
  function scoreOf(uint256 tokenId) public view returns (uint256) {
    return scores[tokenId];
  }

  /// Retrieve the sponsor for a given token ID
  function sponsorOf(uint256 tokenId) public view returns (uint256) {
    return sponsors[tokenId];
  }

  /// Adds a new sponsorship
  function create(uint256 sponsor, uint256 recipient) public onlyAuthorized {
    if (sponsor > 0) {
      scores[sponsor] += 1;
      sponsors[recipient] = sponsor;
    }
  }
}