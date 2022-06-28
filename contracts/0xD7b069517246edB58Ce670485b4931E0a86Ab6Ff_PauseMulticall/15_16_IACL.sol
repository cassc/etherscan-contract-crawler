// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import {IVersion} from "./IVersion.sol";

interface IACLEvents {
  // emits each time when new pausable admin added
  event PausableAdminAdded(address indexed newAdmin);

  // emits each time when pausable admin removed
  event PausableAdminRemoved(address indexed admin);

  // emits each time when new unpausable admin added
  event UnpausableAdminAdded(address indexed newAdmin);

  // emits each times when unpausable admin removed
  event UnpausableAdminRemoved(address indexed admin);
}

/// @title ACL interface
interface IACL is IACLEvents, IVersion {

  function isPausableAdmin(address addr) external view returns (bool);

  function isUnpausableAdmin(address addr) external view returns (bool);

  function isConfigurator(address account) external view returns (bool);
}