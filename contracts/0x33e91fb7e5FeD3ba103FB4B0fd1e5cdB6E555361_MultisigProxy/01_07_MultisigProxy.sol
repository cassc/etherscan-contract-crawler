// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../proxy/TransparentUpgradeableProxy.sol";

contract MultisigProxy is TransparentUpgradeableProxy {
    constructor(address _proxyTo, address admin_, bytes memory _data) TransparentUpgradeableProxy(_proxyTo, admin_, _data) {}
}