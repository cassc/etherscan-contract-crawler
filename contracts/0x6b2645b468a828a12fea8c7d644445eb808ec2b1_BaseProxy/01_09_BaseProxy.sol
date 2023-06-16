// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import { TransparentUpgradeableProxy } from
  "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";

/// BaseProxy is a upgradeable proxy for base wallet instances
contract BaseProxy is TransparentUpgradeableProxy {
  constructor(address logic, address admin, bytes memory data)
    TransparentUpgradeableProxy(logic, admin, data)
  { }
}