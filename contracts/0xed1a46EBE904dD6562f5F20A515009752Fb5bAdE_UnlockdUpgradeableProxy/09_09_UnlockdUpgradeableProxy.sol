// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../helpers/Errors.sol";

contract UnlockdUpgradeableProxy is TransparentUpgradeableProxy {
  constructor(
    address _logic,
    address admin_,
    bytes memory _data
  ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}

  modifier OnlyAdmin() {
    require(msg.sender == _getAdmin(), Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  /**
  @dev Returns the implementation contract for the proxy
   */
  function getImplementation() external view OnlyAdmin returns (address) {
    return _getImplementation();
  }
}