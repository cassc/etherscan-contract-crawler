// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/// @title    GSWFactoryProxy
/// @notice   Default ERC1967Proxy for GSWFactory
contract GSWFactoryProxy is TransparentUpgradeableProxy {
    constructor(
        address logic_,
        address admin_,
        bytes memory data_
    ) payable TransparentUpgradeableProxy(logic_, admin_, data_) {}
}