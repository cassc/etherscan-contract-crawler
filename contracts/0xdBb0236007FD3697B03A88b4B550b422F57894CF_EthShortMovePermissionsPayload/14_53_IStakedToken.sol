// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IStakedToken {
  function setPendingAdmin(uint256 role, address newPendingAdmin) external;

  function SLASH_ADMIN_ROLE() external returns (uint256);

  function COOLDOWN_ADMIN_ROLE() external returns (uint256);

  function CLAIM_HELPER_ROLE() external returns (uint256);
}