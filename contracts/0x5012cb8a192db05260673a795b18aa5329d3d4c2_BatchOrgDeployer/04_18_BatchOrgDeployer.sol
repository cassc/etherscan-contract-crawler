//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import {OrgFundFactory} from "./OrgFundFactory.sol";
import {Entity} from "./Entity.sol";
import {Org} from "./Org.sol";

/**
 * @notice Contract used to deploy a batch of Orgs at once, in case anyone wants to do
 * this in bulk instead of performing multiple single deploy transactions
 */
contract BatchOrgDeployer {
    /// @notice The OrgFundFactory contract we'll use to batch deploy
    OrgFundFactory public immutable orgFundFactory;

    /// @notice Emitted when a batch is deployed
    event EntityBatchDeployed(address indexed caller, uint8 indexed entityType, uint256 batchSize);

    constructor(OrgFundFactory _orgFundFactory) {
        orgFundFactory = _orgFundFactory;
    }

    /// @notice Deploys a batch of Orgs, given an array of orgIds
    /// @param _orgIds The array of orgIds to deploy
    /// @dev Function will throw in case an org with a same `orgId` already exists since factory uses determinist `create2`, so only pass org ids that have not yet been deployed
    function batchDeploy(bytes32[] calldata _orgIds) external {
        for (uint256 i = 0; i < _orgIds.length; i++) {
            orgFundFactory.deployOrg(_orgIds[i]);
        }
        emit EntityBatchDeployed(msg.sender, 1, _orgIds.length);
    }
}