// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC4973} from './ERC4973.sol';

struct Stats {
  uint216 bidAmount;
  uint16 bidCount;
  uint16 tokenIndex;
  bool refundClaimed;
}

interface IOldeusAuction is IERC4973 {
  function stats(address holder) external view returns (Stats memory);

  function refund(address payable to, uint256 refundAmount) external;

  function exists(address holder) external view returns (bool);

  function tokenId(address holder) external view returns (uint256);
}