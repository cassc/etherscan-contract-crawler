// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./TransparentUpgradeableProxy.sol";

contract OriginationCoreProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _proxyAdmin)
        TransparentUpgradeableProxy(_logic, _proxyAdmin, "")
    {}
}