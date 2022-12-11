// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract TSLUpgradeableProxy is TransparentUpgradeableProxy {
  constructor(
    address _logic,
    address admin_,
    bytes memory _data
  ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}

  modifier OnlyAdmin() {
    require(msg.sender == _getAdmin(), "caller not admin");
    _;
  }

  function getImplementation() external view OnlyAdmin returns (address) {
    return _getImplementation();
  }
}