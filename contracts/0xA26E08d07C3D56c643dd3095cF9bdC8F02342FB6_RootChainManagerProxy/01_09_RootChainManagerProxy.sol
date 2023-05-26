// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

// RootChainManagerProxy
contract RootChainManagerProxy is TransparentUpgradeableProxy {
    constructor(
        address implementation,
        address admin,
        bytes memory data
    )
        TransparentUpgradeableProxy(implementation, admin, data)
    // solhint-disable-next-line no-empty-blocks
    {

    }
}