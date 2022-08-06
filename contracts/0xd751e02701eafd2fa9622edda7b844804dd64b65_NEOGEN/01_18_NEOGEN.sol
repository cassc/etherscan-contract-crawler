// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./NEOGENContract.sol";

contract NEOGEN is NEOGENContract {
    constructor(
        DeploymentConfig memory deploymentConfig,
        RuntimeConfig memory runtimeConfig
    ) {
        _preventInitialization = false;
        initialize(deploymentConfig, runtimeConfig);
    }
}