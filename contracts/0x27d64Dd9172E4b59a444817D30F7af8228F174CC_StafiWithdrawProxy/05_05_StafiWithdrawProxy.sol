pragma solidity 0.7.6;
// SPDX-License-Identifier: GPL-3.0-only

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract StafiWithdrawProxy is TransparentUpgradeableProxy {
    constructor(
        address _proxyTo,
        address admin_,
        bytes memory _data
    ) TransparentUpgradeableProxy(_proxyTo, admin_, _data) {}
}