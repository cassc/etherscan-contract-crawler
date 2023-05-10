// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library BridgePoolFactoryErrors {
    error FailedToDeployLogic();
    error PoolVersionNotSupported(uint16 version);
    error StaticPoolDeploymentFailed(bytes32 salt_);
    error UnexistentBridgePoolImplementationVersion(uint16 version);
    error UnableToDeployBridgePool(bytes32 salt_);
    error InsufficientFunds();
    error PublicPoolDeploymentTemporallyDisabled();
}