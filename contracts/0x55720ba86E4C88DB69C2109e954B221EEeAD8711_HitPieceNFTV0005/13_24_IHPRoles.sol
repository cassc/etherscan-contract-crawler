// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract IHPRoles {
  function isAdmin(
    address wallet
  ) public virtual view returns(bool);

  function isApprovedMarketplace(
    address _marketplaceAddress
  ) public virtual view returns(bool);
}