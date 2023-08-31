//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import {OrgFundFactory} from "./OrgFundFactory.sol";
import {Entity} from "./Entity.sol";
import {Org} from "./Org.sol";
import {Fund} from "./Fund.sol";

// --- Errors ---
error Unauthorized();

/**
 * @notice This contract serves to automatically deploy entities on entity transfers
 */
contract TransferDeployer {
    /// @notice The canonical OrgFundFactory address
    OrgFundFactory public immutable orgFundFactory;

    /// @notice Emitted when an Org is deployed and assets are transferred to it
    event OrgDeployedAndTransferred(Org org, Entity source, uint256 amount);
    /// @notice Emitted when a Fund is deployed and assets are transferred to it
    event FundDeployedAndTransferred(Fund fund, Entity source, uint256 amount);

    modifier requiresManager(Entity _entity) {
        if (msg.sender != _entity.manager()) revert Unauthorized();
        _;
    }

    /**
     * @param _orgFundFactory The canonical OrgFundFactory address
     */
    constructor(OrgFundFactory _orgFundFactory) {
        orgFundFactory = _orgFundFactory;
    }

    /**
     * @notice Deploys an Org and transfers assets from the source entity
     * @param _source The source entity that wants to transfer
     * @param _orgId The Org's ID for tax purposes
     * @param _amount The amount of base tokens to transfer to the deployed Org
     * @dev Can only be called by the source entity's manager or will revert
     * @return _org The deployed Org
     */
    function deployOrgAndTransfer(Entity _source, bytes32 _orgId, uint256 _amount)
        external
        requiresManager(_source)
        returns (Org _org)
    {
        // Deploy the Org
        _org = orgFundFactory.deployOrg(_orgId);

        // Transfer assets from the source entity to the Org
        _source.transferToEntity(_org, _amount);

        // Emit event
        emit OrgDeployedAndTransferred(_org, _source, _amount);
    }

    /**
     * @notice Deploys a Fund and transfers assets from the source entity
     * @param _source The source entity that wants to transfer
     * @param _manager The Fund's manager
     * @param _salt A 32-byte value used to create the contract at a deterministic address
     * @param _amount The amount of base tokens to transfer to the deployed Fund
     * @dev Can only be called by the source entity's manager or will revert
     * @return _fund The deployed Fund
     */
    function deployFundAndTransfer(Entity _source, address _manager, bytes32 _salt, uint256 _amount)
        external
        requiresManager(_source)
        returns (Fund _fund)
    {
        // Deploy the Fund
        _fund = orgFundFactory.deployFund(_manager, _salt);

        // Transfer assets from the source entity to the Fund
        _source.transferToEntity(_fund, _amount);

        // Emit event
        emit FundDeployedAndTransferred(_fund, _source, _amount);
    }
}