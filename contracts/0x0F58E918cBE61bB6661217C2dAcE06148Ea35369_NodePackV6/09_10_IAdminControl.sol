// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IAdminControl {
  function hasRole(uint8 _role, address _account) external view returns (bool);

  function SUPER_ADMIN() external view returns (uint8);

  function ADMIN() external view returns (uint8);

  function SERVICE_ADMIN() external view returns (uint8);
}