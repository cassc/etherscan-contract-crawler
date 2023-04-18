// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "TransparentUpgradeableProxy.sol";
import "ProxyAdmin.sol";

contract Port3AgencyFundsUpgradeableProxy is TransparentUpgradeableProxy {

    constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) public {

    }

}