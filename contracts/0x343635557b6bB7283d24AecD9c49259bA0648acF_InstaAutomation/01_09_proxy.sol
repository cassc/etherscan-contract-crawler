// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract InstaAutomation is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) public TransparentUpgradeableProxy(_logic, admin_, _data) {}
}