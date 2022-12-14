// SPDX-License-Identifier: MIT

/// @author notu @notuart

pragma solidity ^0.8.9;

interface ITrustee {
  function trust(uint256 me, uint256 you) external view returns (bool);
}