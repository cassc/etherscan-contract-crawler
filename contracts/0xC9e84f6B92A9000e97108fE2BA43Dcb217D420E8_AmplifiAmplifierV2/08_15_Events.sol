// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Types.sol";

library Events {
    event AmplifierCreated(uint256 indexed id, address indexed owner, uint256 months);

    event AmplifierRenewed(uint256 indexed id, address indexed owner, uint256 months);

    event AmplifierFused(uint256 indexed id, address indexed owner, Types.FuseProduct indexed fuseProduct);

    event AmplifierMigrated(uint256 indexed v1AmplifierId, uint256 indexed v2AmplifierId, address indexed owner);

    event AMPLIFIClaimed(address indexed owner, uint256 amount);

    event ETHClaimed(uint256 indexed id, address indexed owner, address indexed claimer, uint256 amount);
}