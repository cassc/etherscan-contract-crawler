// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTCollection.sol";

contract NFTCollectionContract is NFTCollection {
    constructor(
        DeploymentConfig memory deploymentConfig,
        RuntimeConfig memory runtimeConfig
    ) {
        _preventInitialization = false;
        initialize(deploymentConfig, runtimeConfig);
    }
}