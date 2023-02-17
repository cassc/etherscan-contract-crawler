// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;

import "../EnsoWalletFactory.sol";
import "../proxy/UpgradeableProxy.sol";

contract FactoryDeployer {
    address public immutable factory;

    constructor(address owner, address factoryImplementation) {
        factory = address(new UpgradeableProxy(factoryImplementation));
        EnsoWalletFactory(factory).initialize(owner);
    }
}