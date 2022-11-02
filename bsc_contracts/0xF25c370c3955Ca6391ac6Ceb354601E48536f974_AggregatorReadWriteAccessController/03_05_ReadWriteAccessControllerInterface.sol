// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface ReadWriteAccessControllerInterface {
  function hasReadAccess(address user) external view returns (bool);

  function hasWriteAccess(address user) external view returns (bool);
}