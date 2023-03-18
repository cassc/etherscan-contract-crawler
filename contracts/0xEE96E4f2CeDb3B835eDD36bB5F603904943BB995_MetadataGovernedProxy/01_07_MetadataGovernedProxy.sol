// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

// Energi Governance system is a fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
// match requirement.

pragma solidity 0.5.16;

import { NonReentrant } from './NonReentrant.sol';

import { IGovernedProxy_New } from './interfaces/IGovernedProxy_New.sol';
import { ISporkRegistry } from './interfaces/ISporkRegistry.sol';
import { IUpgradeProposal } from './interfaces/IUpgradeProposal.sol';
import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract MetadataGovernedProxy is NonReentrant, IGovernedContract, IGovernedProxy_New {
    bool public initialized = false;
    IGovernedContract public implementation;
    IGovernedProxy_New public spork_proxy;
    mapping(address => IGovernedContract) public upgrade_proposals;
    IUpgradeProposal[] public upgrade_proposal_list;

    event MetadataHashesUploaded(bytes4 indexed batchId, uint256 indexed numItems);

    event StartingIndexSet(bytes4 indexed batchId, uint256 indexed startingIndex);

    modifier senderOrigin() {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        require(tx.origin == msg.sender, 'MetadataGovernedProxy: Only direct calls are allowed!');
        _;
    }

    modifier onlyImplementation() {
        require(
            msg.sender == address(implementation),
            'MetadataGovernedProxy: Only calls from implementation are allowed!'
        );
        _;
    }

    function initialize(address _implementation) external {
        if (!initialized) {
            initialized = true;
            implementation = IGovernedContract(_implementation);
        }
    }

    function setSporkProxy(address payable _sporkProxy) external onlyImplementation {
        spork_proxy = IGovernedProxy_New(_sporkProxy);
    }

    function emitMetadataHashesUploaded(bytes4 batchId, uint256 numItems)
        external
        onlyImplementation
    {
        emit MetadataHashesUploaded(batchId, numItems);
    }

    function emitStartingIndexSet(bytes4 batchId, uint256 startingIndex)
        external
        onlyImplementation
    {
        emit StartingIndexSet(batchId, startingIndex);
    }

    // Due to backward compatibility of old Energi proxies
    function impl() external view returns (IGovernedContract) {
        return implementation;
    }

    /**
     * Pre-create a new contract first.
     * Then propose upgrade based on that.
     */
    function proposeUpgrade(IGovernedContract _newImplementation, uint256 _period)
        external
        payable
        senderOrigin
        noReentry
        returns (IUpgradeProposal)
    {
        require(_newImplementation != implementation, 'MetadataGovernedProxy: Already active!');
        require(_newImplementation.proxy() == address(this), 'MetadataGovernedProxy: Wrong proxy!');

        ISporkRegistry spork_reg = ISporkRegistry(address(spork_proxy.impl()));
        IUpgradeProposal proposal = spork_reg.createUpgradeProposal.value(msg.value)(
            _newImplementation,
            _period,
            msg.sender
        );

        upgrade_proposals[address(proposal)] = _newImplementation;
        upgrade_proposal_list.push(proposal);

        emit UpgradeProposal(_newImplementation, proposal);

        return proposal;
    }

    /**
     * Once proposal is accepted, anyone can activate that.
     */
    function upgrade(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract newImplementation = upgrade_proposals[address(_proposal)];
        require(newImplementation != implementation, 'MetadataGovernedProxy: Already active!');
        // in case it changes in the flight
        require(address(newImplementation) != address(0), 'MetadataGovernedProxy: Not registered!');
        require(_proposal.isAccepted(), 'MetadataGovernedProxy: Not accepted!');

        IGovernedContract oldImplementation = implementation;

        newImplementation.migrate(oldImplementation);
        implementation = newImplementation;
        oldImplementation.destroy(newImplementation);

        // SECURITY: prevent downgrade attack
        _cleanupProposal(_proposal);

        // Return fee ASAP
        _proposal.destroy();

        emit Upgraded(newImplementation, _proposal);
    }

    /**
     * Map proposal to implementation
     */
    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract newImplementation)
    {
        newImplementation = upgrade_proposals[address(_proposal)];
    }

    /**
     * Lists all available upgrades
     */
    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals) {
        uint256 len = upgrade_proposal_list.length;
        proposals = new IUpgradeProposal[](len);

        for (uint256 i = 0; i < len; ++i) {
            proposals[i] = upgrade_proposal_list[i];
        }

        return proposals;
    }

    /**
     * Once proposal is reject, anyone can start collect procedure.
     */
    function collectUpgradeProposal(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract newImplementation = upgrade_proposals[address(_proposal)];
        require(address(newImplementation) != address(0), 'MetadataGovernedProxy: Not registered!');
        _proposal.collect();
        delete upgrade_proposals[address(_proposal)];

        _cleanupProposal(_proposal);
    }

    function _cleanupProposal(IUpgradeProposal _proposal) internal {
        delete upgrade_proposals[address(_proposal)];

        uint256 len = upgrade_proposal_list.length;
        for (uint256 i = 0; i < len; ++i) {
            if (upgrade_proposal_list[i] == _proposal) {
                upgrade_proposal_list[i] = upgrade_proposal_list[len - 1];
                upgrade_proposal_list.pop();
                break;
            }
        }
    }

    /**
     * Related to above
     */
    function proxy() external view returns (address) {
        return address(this);
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function migrate(IGovernedContract) external {
        revert('MetadataGovernedProxy: Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function destroy(IGovernedContract) external {
        revert('MetadataGovernedProxy: Good try');
    }

    /**
     * Proxy all other calls to implementation.
     */
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory
        IGovernedContract implementation_m = implementation;

        // A dummy delegatecall opcode in the fallback function is necessary for
        // block explorers to pick up the Energi proxy-implementation pattern
        if (false) {
            (bool success, bytes memory data) = address(0).delegatecall(
                abi.encodeWithSignature('')
            );
            require(
                success && !success && data.length == 0 && data.length != 0,
                'MetadataGovernedProxy: delegatecall cannot be used'
            );
        }

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)

            let res := call(sub(gas, 10000), implementation_m, callvalue, ptr, calldatasize, 0, 0)
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize)

            switch res
            case 0 {
                revert(ptr, returndatasize)
            }
            default {
                return(ptr, returndatasize)
            }
        }
    }
}