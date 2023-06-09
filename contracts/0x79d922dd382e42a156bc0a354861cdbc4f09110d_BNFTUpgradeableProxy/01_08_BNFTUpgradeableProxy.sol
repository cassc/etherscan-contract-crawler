// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract BNFTUpgradeableProxy is TransparentUpgradeableProxy {
  constructor(
    address _logic,
    address admin_,
    bytes memory _data
  ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}
}