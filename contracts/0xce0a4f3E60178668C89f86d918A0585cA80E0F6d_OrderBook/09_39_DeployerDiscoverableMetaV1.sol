// SPDX-License-Identifier: CAL
pragma solidity =0.8.18;

import "sol.metadata/IMetaV1.sol";
import "sol.metadata/LibMeta.sol";
import "./LibDeployerDiscoverable.sol";

struct DeployerDiscoverableMetaV1ConstructionConfig {
    address deployer;
    bytes meta;
}

/// @title DeployerDiscoverableMetaV1
/// @notice Checks metadata against a known hash, emits it then touches the
/// deployer (deploy an empty expression). This allows indexers to discover the
/// metadata of the `DeployerDiscoverableMetaV1` contract by indexing the
/// deployer. In this way the deployer acts as a pseudo-registry by virtue of it
/// being a natural hub for interactions.
abstract contract DeployerDiscoverableMetaV1 is IMetaV1 {
    constructor(
        bytes32 metaHash_,
        DeployerDiscoverableMetaV1ConstructionConfig memory config_
    ) {
        LibMeta.checkMetaHashed(metaHash_, config_.meta);
        emit MetaV1(msg.sender, uint256(uint160(address(this))), config_.meta);
        LibDeployerDiscoverable.touchDeployer(config_.deployer);
    }
}