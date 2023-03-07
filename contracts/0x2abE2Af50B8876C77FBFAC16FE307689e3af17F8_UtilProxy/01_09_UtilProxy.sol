// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

import {TransparentUpgradeableProxy} from "TransparentUpgradeableProxy.sol";

contract UtilProxy is TransparentUpgradeableProxy {

  constructor(address _logic, address admin_) TransparentUpgradeableProxy(_logic, admin_, "") {

  }
}