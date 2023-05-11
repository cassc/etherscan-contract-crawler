//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract GoochCrowdsaleProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _proxyAdmin
    ) TransparentUpgradeableProxy(_logic, _proxyAdmin, "") {}
}