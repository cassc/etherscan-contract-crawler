// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/// @title    GSWVersionsRegistryProxy
/// @notice   Default ERC1967Proxy for GSWVersionsRegistryProxy
contract GSWVersionsRegistryProxy is TransparentUpgradeableProxy {
    constructor(
        address logic_,
        address admin_,
        bytes memory data_
    ) payable TransparentUpgradeableProxy(logic_, admin_, data_) {}
}