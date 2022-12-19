//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IMultisigOwnerCut} from "../interfaces/IMultisigOwnerCut.sol";

import {ImmutableQuorumGovernanceGroup} from "./ImmutableQuorumGovernanceGroup.sol";
import {LibEIP712MultisigOwnerCut} from "../libraries/LibEIP712MultisigOwnerCut.sol";
import {LibEIP712} from "../../libraries/LibEIP712.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Multi-sig quorum governance based group
/// @author Amit Molek
/// @dev Please see `IMultisigOwnerCut` and `ImmutableQuorumGovernanceGroup`.
/// Gives the ability to Add/Replace/Remove owners from the group.
contract MutableQuorumGovernanceGroup is
    IMultisigOwnerCut,
    ImmutableQuorumGovernanceGroup
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /* FIELDS */

    /// @dev Maps between owner cut hash and if it was already executed
    mapping(bytes32 => bool) public enactedOwnerCuts;

    /* ERRORS */

    /// @dev Already executed this owner cut
    /// @param cutHash The hash of the owner cut that was already executed
    error OwnerCutEnacted(bytes32 cutHash);

    /// @dev The owner cut ended/deadline passed
    /// @param cutHash The hash of the owner cut
    /// @param endedAt The owner cut deadline
    error OwnerCutEnded(bytes32 cutHash, uint256 endedAt);

    constructor(address[] memory owners)
        ImmutableQuorumGovernanceGroup(owners)
    {}

    function ownerCut(OwnerCut memory cut, bytes[] memory signatures)
        external
        override
    {
        bytes32 cutHash = toTypedDataHash(cut);

        // Verify that this cut is not already executed
        if (enactedOwnerCuts[cutHash]) {
            revert OwnerCutEnacted(cutHash);
        }

        // Make sure that the cut is still alive
        uint256 endsAt = cut.endsAt;
        // solhint-disable-next-line not-rely-on-time
        if (endsAt < block.timestamp) {
            revert OwnerCutEnded(cutHash, endsAt);
        }

        // Verify signatures
        _verifyHashGuard(cutHash, signatures);

        // Tag the cut as executed
        enactedOwnerCuts[cutHash] = true;

        emit IMultisigOwnerCut.OwnerCutExecuted(cut);

        IMultisigOwnerCut.OwnerCutAction action = cut.action;
        if (action == IMultisigOwnerCut.OwnerCutAction.ADD) {
            _safeAddOwnerCut(cut.account);
        } else if (action == IMultisigOwnerCut.OwnerCutAction.REPLACE) {
            _safeReplaceOwnerCut(cut.account, cut.prevAccount);
        } else if (action == IMultisigOwnerCut.OwnerCutAction.REMOVE) {
            _safeRemoveOwnerCut(cut.account);
        } else {
            revert IMultisigOwnerCut.InvalidOwnerCutAction(uint256(action));
        }
    }

    /// @dev Adds `account` as an owner and recalculated the quorum threshold
    function _safeAddOwnerCut(address account) internal {
        if (account == address(0)) {
            revert InvalidOwner(account);
        }

        bool success = _owners.add(account);
        if (success == false) {
            revert DuplicateOwner(account);
        }

        // Recalculate the quorum threshold
        quorumGovernanceThreshold = _calculateQuorumGovernanceThreshold(
            _owners.length()
        );
    }

    /// @dev Replaces `prevAccount` and `account` as owner
    function _safeReplaceOwnerCut(address account, address prevAccount)
        internal
    {
        if (account == address(0)) {
            revert InvalidOwner(account);
        }
        if (account == prevAccount) {
            revert DuplicateOwner(account);
        }

        // Remove previous owner
        bool success = _owners.remove(prevAccount);
        if (success == false) {
            revert InvalidOwner(prevAccount);
        }

        // Add new owner
        success = _owners.add(account);
        if (success == false) {
            revert DuplicateOwner(account);
        }
    }

    /// @dev Removes `account` as an owner and recalculates the quorum threshold
    function _safeRemoveOwnerCut(address account) internal {
        if (_owners.length() - 1 < MIN_OWNERS_LENGTH) {
            revert MinimumOwners();
        }

        bool success = _owners.remove(account);
        if (success == false) {
            revert InvalidOwner(account);
        }

        // Recalculate the quorum threshold
        quorumGovernanceThreshold = _calculateQuorumGovernanceThreshold(
            _owners.length()
        );
    }

    function toTypedDataHash(IMultisigOwnerCut.OwnerCut memory cut)
        public
        view
        returns (bytes32)
    {
        return
            LibEIP712._toTypedDataHash(
                LibEIP712MultisigOwnerCut._hashOwnerCut(cut)
            );
    }

    /* ERC165 */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IMultisigOwnerCut).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}