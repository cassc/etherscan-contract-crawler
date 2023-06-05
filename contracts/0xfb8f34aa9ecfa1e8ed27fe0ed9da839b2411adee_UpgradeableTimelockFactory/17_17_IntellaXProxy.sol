// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libs/@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract IntellaXProxy is TransparentUpgradeableProxy {
    constructor(
        address implementation,
        address admin,
        bytes memory data
    ) TransparentUpgradeableProxy(implementation, admin, data) {}
    // solhint-disable-previous-line no-empty-blocks
}