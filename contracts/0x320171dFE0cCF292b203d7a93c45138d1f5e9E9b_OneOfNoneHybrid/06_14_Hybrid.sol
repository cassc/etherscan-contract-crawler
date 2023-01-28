pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


abstract contract Hybrid {
  string constant INVALID_STATUS = "004002";

  enum  TokenStatus { Vaulted, Redeemed, Lost }
  mapping(uint256 => TokenStatus) private _tokenStatus;

  function _setStatus(uint256 tokenId, TokenStatus status) internal {
    _tokenStatus[tokenId] = status;
  }

  /// Check if token is not in status
  modifier notStatus(uint256 tokenId, TokenStatus status) {
    require(_tokenStatus[tokenId] != status, INVALID_STATUS);
    _;
  }
}