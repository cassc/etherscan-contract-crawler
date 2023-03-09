// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IGuardable is IERC165 {
  // Interface ID 0x126f5523

  error TokenIsLocked();
  error CallerGuardianMismatch(address caller, address guardian);
  error InvalidGuardian();

  event GuardianAdded(address indexed addressGuarded, address indexed guardian);
  event GuardianRemoved(address indexed addressGuarded);

  function setGuardian(address guardian) external;

  function removeGuardianOf(address tokenOwner) external;

  function guardianOf(address tokenOwner) external view returns (address);
}