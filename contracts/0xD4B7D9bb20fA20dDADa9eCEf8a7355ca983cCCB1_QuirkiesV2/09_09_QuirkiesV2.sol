// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {TransparentUpgradeableProxy} from "openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";

contract QuirkiesV2 is TransparentUpgradeableProxy {
    constructor(
        address logic_,
        address admin_,
        bytes memory data_
    ) TransparentUpgradeableProxy(logic_, admin_, data_) {}
}