// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { IJBDelegatesRegistry } from "@jbx-protocol/juice-delegates-registry/src/interfaces/IJBDelegatesRegistry.sol";
import { IJBDirectory } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import { JBOwnable } from "@jbx-protocol/juice-ownable/src/JBOwnable.sol";

import { JB721GovernanceType } from "./enums/JB721GovernanceType.sol";
import { IJBTiered721DelegateDeployer } from "./interfaces/IJBTiered721DelegateDeployer.sol";
import { IJBTiered721Delegate } from "./interfaces/IJBTiered721Delegate.sol";
import { JBDeployTiered721DelegateData } from "./structs/JBDeployTiered721DelegateData.sol";
import { JBTiered721Delegate } from "./JBTiered721Delegate.sol";
import { JBTiered721GovernanceDelegate } from "./JBTiered721GovernanceDelegate.sol";

/// @title JBTiered721DelegateDeployer
/// @notice Deploys a JBTiered721Delegate.
/// @custom:version 3.3
contract JBTiered721DelegateDeployer is IJBTiered721DelegateDeployer {
    //*********************************************************************//
    // --------------------------- custom errors ------------------------- //
    //*********************************************************************//

    error INVALID_GOVERNANCE_TYPE();

    //*********************************************************************//
    // ----------------------- internal properties ----------------------- //
    //*********************************************************************//

    /**
     * @notice 
     * This contract's current nonce, used for the Juicebox delegates registry.
     */
    uint256 internal _nonce;

    //*********************************************************************//
    // --------------- public immutable stored properties ---------------- //
    //*********************************************************************//

    /// @notice A contract that supports on-chain governance across all tiers.
    JBTiered721GovernanceDelegate public immutable onchainGovernance;

    /// @notice A contract with no on-chain governance mechanism.
    JBTiered721Delegate public immutable noGovernance;

    /// @notice A contract that stores references to deployer contracts of delegates.
    IJBDelegatesRegistry public immutable delegatesRegistry;

    //*********************************************************************//
    // -------------------------- constructor ---------------------------- //
    //*********************************************************************//

    /// @param _onchainGovernance Reference copy of the delegate that works with onchain governance.
    /// @param _noGovernance Reference copy of a simpler delegate without on-chain governance.
    /// @param _delegatesRegistry A contract that stores references to delegate deployer contracts.
    constructor(
        JBTiered721GovernanceDelegate _onchainGovernance,
        JBTiered721Delegate _noGovernance,
        IJBDelegatesRegistry _delegatesRegistry
    ) {
        onchainGovernance = _onchainGovernance;
        noGovernance = _noGovernance;
        delegatesRegistry = _delegatesRegistry;
    }

    //*********************************************************************//
    // ---------------------- external transactions ---------------------- //
    //*********************************************************************//

    /// @notice Deploys a delegate for the provided project.
    /// @param _projectId The ID of the project for which the delegate will be deployed.
    /// @param _deployTiered721DelegateData Structure containing data necessary for delegate deployment.
    /// @param _directory The directory of terminals and controllers for projects.
    /// @return newDelegate The address of the newly deployed delegate.
    function deployDelegateFor(
        uint256 _projectId,
        JBDeployTiered721DelegateData memory _deployTiered721DelegateData,
        IJBDirectory _directory
    ) external override returns (IJBTiered721Delegate newDelegate) {
        // Deploy the governance variant that was requested
        if (_deployTiered721DelegateData.governanceType == JB721GovernanceType.NONE) {
            newDelegate = IJBTiered721Delegate(Clones.clone(address(noGovernance)));
        } else if (_deployTiered721DelegateData.governanceType == JB721GovernanceType.ONCHAIN) {
            newDelegate = IJBTiered721Delegate(Clones.clone(address(onchainGovernance)));
        } else {
            revert INVALID_GOVERNANCE_TYPE();
        }

        newDelegate.initialize(
            _projectId,
            _directory,
            _deployTiered721DelegateData.name,
            _deployTiered721DelegateData.symbol,
            _deployTiered721DelegateData.fundingCycleStore,
            _deployTiered721DelegateData.baseUri,
            _deployTiered721DelegateData.tokenUriResolver,
            _deployTiered721DelegateData.contractUri,
            _deployTiered721DelegateData.pricing,
            _deployTiered721DelegateData.store,
            _deployTiered721DelegateData.flags
        );

        // Transfer the delegate ownership to the address that made this deployment.
        JBOwnable(address(newDelegate)).transferOwnership(msg.sender);

        // Add the delegate to the registry. Contract nonce starts at 1.
        delegatesRegistry.addDelegate(address(this), ++_nonce);

        emit DelegateDeployed(_projectId, newDelegate, _deployTiered721DelegateData.governanceType, _directory);

        return newDelegate;
    }
}