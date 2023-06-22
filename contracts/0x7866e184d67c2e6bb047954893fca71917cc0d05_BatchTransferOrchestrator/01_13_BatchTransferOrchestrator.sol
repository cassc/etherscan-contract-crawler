//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.8.13;

import {Entity} from "./Entity.sol";

/**
 * @notice Thrown when the caller is not the manager of an entity.
 * @param entity Entity that caller is not the manager of.
 * @param caller Address of the caller.
 * @param manager Address of the actual entity manager.
 */
error CallerNotManager(address entity, address caller, address manager);

/**
 * @notice Contract used to enable entity managers issuing a batch of Entity-to-Entity transfers in a single transaction.
 */
contract BatchTransferOrchestrator {
    struct Transfer {
        /// @notice Entity to transfer from. Caller must manage this entity.
        Entity sourceEntity;
        /// @notice Entity to transfer to.
        Entity targetEntity;
        /// @notice Amount to transfer.
        uint256 amount;
    }

    struct DestinationTransfer {
        /// @notice Entity to transfer to.
        Entity targetEntity;
        /// @notice Amount to transfer.
        uint256 amount;
    }

    /**
     * @notice Issues a batch of transfers from entities managed by the caller.
     * @dev Use this method only if the transfers are coming from different source entities, since it
     * is more expensive to call than "transferFromSingleEntity".
     * @param _transfers Transfers to be issued by this contract.
     */
    function transferFromMultipleEntities(Transfer[] calldata _transfers) external {
        for (uint256 i = 0; i < _transfers.length; i++) {
            // Check that the caller is the manager of the source entity
            _checkCallerIsManager(_transfers[i].sourceEntity);

            // Issue the transfer once the check passes
            _transfers[i].sourceEntity.transferToEntity(_transfers[i].targetEntity, _transfers[i].amount);
        }
    }

    /**
     * @notice Issues a batch of transfers from an entity managed by the caller.
     * @dev This method is cheaper in terms of gas because it only checks the caller is the manager of the
     * source entity once. Prefer using this method if all transfers are coming from the same contract.
     * @param _sourceEntity Entity to transfer from. Caller must manage this entity.
     * @param _transfers Transfers to be issued by this contract.
     */
    function transferFromSingleEntity(Entity _sourceEntity, DestinationTransfer[] calldata _transfers) external {
        // Check that the caller is the manager of the source entity
        _checkCallerIsManager(_sourceEntity);

        // Issue the transfers once the check passes
        for (uint256 i = 0; i < _transfers.length; i++) {
            _sourceEntity.transferToEntity(_transfers[i].targetEntity, _transfers[i].amount);
        }
    }

    /**
     * Check that the caller is the manager of the source entity.
     * @param _sourceEntity Entity to check the caller is the manager of.
     */
    function _checkCallerIsManager(Entity _sourceEntity) internal view {
        address manager = _sourceEntity.manager();
        if (manager != msg.sender) {
            revert CallerNotManager(address(_sourceEntity), msg.sender, manager);
        }
    }
}