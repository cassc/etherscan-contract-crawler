// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

/**
 * Copyright (C) 2023 Flare Finance B.V. - All Rights Reserved.
 *
 * This source code and any functionality deriving from it are owned by Flare
 * Finance BV and the use of it is only permitted within the official platforms
 * and/or original products of Flare Finance B.V. and its licensed parties. Any
 * further enquiries regarding this copyright and possible licenses can be directed
 * to partners[at]flr.finance.
 *
 * The source code and any functionality deriving from it are provided "as is",
 * without warranty of any kind, express or implied, including but not limited to
 * the warranties of merchantability, fitness for a particular purpose and
 * noninfringement. In no event shall the authors or copyright holder be liable
 * for any claim, damages or other liability, whether in an action of contract,
 * tort or otherwise, arising in any way out of the use or other dealings or in
 * connection with the source code and any functionality deriving from it.
 */

/// @title Two committee multisig library.
/// @dev Implements a multisig with two committees.
/// A separate quorum must be reached in both committees
/// to approve a given request. A request is rejected if
/// either of the two committees rejects it. Each committee
/// cannot have more than 128 members.
library Multisig {
    /// @dev Thrown when an already existing signer is added.
    error SignerAlreadyExists(address signer);

    /// @dev Thrown when an account that is performing some
    /// signer-only action is not an active signer.
    error SignerNotActive(address signer);

    /// @dev Thrown when attempting to add a new signer
    /// after the max committee size has been reached.
    error MaxCommitteeSizeReached();

    /// @dev Thrown when the configuration parmeters that are
    /// being set are not valid.
    error InvalidConfiguration();

    /// @dev Thrown when a given ID has already been assigned
    /// to an apprroved request.
    error InvalidId();

    /// @dev Thrown when the current next execution index is
    /// greater equal to the new next execution index.
    error InvalidNextExecutionIndex();

    /// @dev Emitted when a new signer is added.
    /// @param signer Address of signer that was added.
    /// @param isFirstCommittee True if the signer was
    /// added to the first committee and false if they were
    /// added to the second committee.
    event AddSigner(address indexed signer, bool indexed isFirstCommittee);

    /// @dev Emitted when an existing signer is removed.
    /// @param signer Address of signer that was removed.
    event RemoveSigner(address indexed signer);

    /// @dev Maximum number of members in each committee.
    /// @notice This number cannot be increased further
    /// with the current implementation. Our implementation
    /// uses bitmasks and the uint8 data type to optimize gas.
    /// These data structures will overflow if maxCommitteeSize
    /// is greater than 128.
    uint8 constant maxCommitteeSize = 128;

    /// @dev Maximum number of members in both committees
    /// combined.
    /// @notice Similarly to maxCommitteeSize, maxSignersSize
    /// also cannot be further increased to more than 256.
    uint16 constant maxSignersSize = 256; // maxCommitteeSize * 2

    /// @dev Request statuses.
    /// @notice `NULL` should be the first element as the first value is used
    /// as the default value in Solidity. The sequence of the other
    /// elements also shouldn't be changed.
    enum RequestStatus {
        NULL, // request which doesn't exist
        Undecided, // request hasn't reached quorum
        Accepted // request has been approved
    }

    /// @notice `Unchanged` should be the first element as the first value is used
    /// as the default value in Solidity. The sequence of the other
    /// elements also shouldn't be changed.
    enum RequestStatusTransition {
        Unchanged,
        NULLToUndecided,
        UndecidedToAccepted
    }

    /// @dev Signer statuses.
    /// @notice `Uninitialized` should be the first element as the first value is used
    /// as the default value in Solidity. The sequence of the other
    /// elements also shouldn't be changed.
    enum SignerStatus {
        Uninitialized,
        Removed,
        FirstCommittee,
        SecondCommittee
    }

    /// @dev Request info.
    /// @param approvalsFirstCommittee Number of approvals
    /// by the first committee.
    /// @param approvalsSecondCommittee Number of approvals
    /// by the second committee.
    /// @param status Status of the request.
    /// @param approvers Bitmask for signers from the two
    /// committees who have accepted the request.
    /// @notice Approvers is a bitmask. For example, a set bit at
    /// position 2 in the approvers bitmask indicates that the
    /// signer with index 2 has approved the request.
    struct Request {
        uint8 approvalsFirstCommittee; // slot 1 (0 - 7 bits)
        uint8 approvalsSecondCommittee; // slot 1 (8 - 15 bits)
        RequestStatus status; // slot 1 (16 - 23 bits)
        // slot 1 (23 - 255 spare bits)
        uint256 approvers; // slot 2
    }

    /// @dev Signer information.
    /// @param status Status of the signer.
    /// @param index Index of the signer.
    struct SignerInfo {
        SignerStatus status;
        uint8 index;
    }

    /// @dev DualMultisig
    /// @param firstCommitteeAcceptanceQuorum Number of acceptances
    /// required to reach quorum in the first committee.
    /// @param secondCommitteeAcceptanceQuorum Number of acceptances
    /// required to reach quorum in the second committee.
    /// @param firstCommitteeSize Size of the first committee.
    /// @param secondCommitteeSize Size of the second committee.
    /// @param nextExecutionIndex Index of the request that will be executed next.
    /// @param signers Mapping from signer address to signer info.
    /// @param requests Mapping from request hash to request info.
    /// @param approvedRequests Mapping request ID to request hash.
    struct DualMultisig {
        uint8 firstCommitteeAcceptanceQuorum; // slot 1 (0 - 7bits)
        uint8 secondCommitteeAcceptanceQuorum; // slot 1 (8 - 15bits)
        uint8 firstCommitteeSize; // slot 1 (16 - 23bits)
        uint8 secondCommitteeSize; // slot 1 (24 - 31bits)
        // slot1 (32 - 255 spare bits)
        uint256 nextExecutionIndex;
        mapping(address => SignerInfo) signers;
        mapping(bytes32 => Request) requests;
        mapping(uint256 => bytes32) approvedRequests;
    }

    /// @param firstCommitteeAcceptanceQuorum Number of acceptances
    /// required to reach quorum in the first committee.
    /// @param secondCommitteeAcceptanceQuorum Number of acceptances
    /// required to reach quorum in the second committee.
    /// @notice Both acceptance quorums should be greater than zero
    /// and less than or equal to maxCommitteeSize.
    struct Config {
        uint8 firstCommitteeAcceptanceQuorum;
        uint8 secondCommitteeAcceptanceQuorum;
    }

    /// @dev Returns a request status for a given request hash.
    /// @param s The relevant multisig to check.
    /// @param hash The hash of the request being checked.
    /// @return The status of the request with the given hash.
    function status(
        DualMultisig storage s,
        bytes32 hash
    ) internal view returns (RequestStatus) {
        return s.requests[hash].status;
    }

    /// @dev Returns whether or not a given address is a signer
    /// in the multisig.
    /// @param s The relevant multisig to check.
    /// @param signer The address of the potential signer.
    /// @return True if the provided address is a signer.
    function isSigner(
        DualMultisig storage s,
        address signer
    ) internal view returns (bool) {
        return s.signers[signer].status >= SignerStatus.FirstCommittee;
    }

    /// @dev Updates a multisig's configuration.
    function configure(DualMultisig storage s, Config memory c) internal {
        if (
            c.firstCommitteeAcceptanceQuorum == 0 ||
            c.firstCommitteeAcceptanceQuorum > maxCommitteeSize ||
            c.secondCommitteeAcceptanceQuorum == 0 ||
            c.secondCommitteeAcceptanceQuorum > maxCommitteeSize
        ) {
            revert InvalidConfiguration();
        }
        s.firstCommitteeAcceptanceQuorum = c.firstCommitteeAcceptanceQuorum;
        s.secondCommitteeAcceptanceQuorum = c.secondCommitteeAcceptanceQuorum;
    }

    /// @dev Adds a new signer.
    /// @param s The multisig to add the signer to.
    /// @param signer The address of the signer to add.
    /// @param isFirstCommittee True if the signer is to be
    /// added to the first committee and false if they are
    /// to be added to the second committee.
    function addSigner(
        DualMultisig storage s,
        address signer,
        bool isFirstCommittee
    ) internal {
        uint8 committeeSize = (
            isFirstCommittee ? s.firstCommitteeSize : s.secondCommitteeSize
        );
        if (committeeSize == maxCommitteeSize) {
            revert MaxCommitteeSizeReached();
        }

        SignerInfo storage signerInfo = s.signers[signer];
        if (signerInfo.status != SignerStatus.Uninitialized) {
            revert SignerAlreadyExists(signer);
        }

        signerInfo.index = s.firstCommitteeSize + s.secondCommitteeSize;
        if (isFirstCommittee) {
            s.firstCommitteeSize++;
            signerInfo.status = SignerStatus.FirstCommittee;
        } else {
            s.secondCommitteeSize++;
            signerInfo.status = SignerStatus.SecondCommittee;
        }

        emit AddSigner(signer, isFirstCommittee);
    }

    /// @dev Removes a signer.
    /// @param s The multisig to remove the signer from.
    /// @param signer The signer to be removed.
    function removeSigner(DualMultisig storage s, address signer) internal {
        SignerInfo storage signerInfo = s.signers[signer];
        if (signerInfo.status < SignerStatus.FirstCommittee) {
            revert SignerNotActive(signer);
        }
        signerInfo.status = SignerStatus.Removed;
        emit RemoveSigner(signer);
    }

    /// @dev Approve a request if its has not already been approved.
    /// @param s The multisig for which to approve the given request.
    /// @param signer The signer approving the request.
    /// @param hash The hash of the request being approved.
    /// @return The request's status transition.
    /// @dev Notice that this code assumes that the hash is generated from
    /// the ID and other data outside of this function. It is important to include
    /// the ID in the hash.
    function tryApprove(
        DualMultisig storage s,
        address signer,
        bytes32 hash,
        uint256 id
    ) internal returns (RequestStatusTransition) {
        Request storage request = s.requests[hash];
        // If the request has already been accepted
        // then simply return.
        if (request.status == RequestStatus.Accepted) {
            return RequestStatusTransition.Unchanged;
        }

        SignerInfo memory signerInfo = s.signers[signer];
        // Make sure that the signer is valid.
        if (signerInfo.status < SignerStatus.FirstCommittee) {
            revert SignerNotActive(signer);
        }

        // Revert if another request with the same ID has
        // already been approved.
        if (s.approvedRequests[id] != bytes32(0)) {
            revert InvalidId();
        }

        uint256 signerMask = 1 << signerInfo.index;
        // Check if the signer has already signed.
        if ((signerMask & request.approvers) != 0) {
            return RequestStatusTransition.Unchanged;
        }

        // Add the signer to the bitmask of approvers.
        request.approvers |= signerMask;
        if (signerInfo.status == SignerStatus.FirstCommittee) {
            ++request.approvalsFirstCommittee;
        } else {
            ++request.approvalsSecondCommittee;
        }

        if (
            request.approvalsFirstCommittee >=
            s.firstCommitteeAcceptanceQuorum &&
            request.approvalsSecondCommittee >=
            s.secondCommitteeAcceptanceQuorum
        ) {
            request.status = RequestStatus.Accepted;
            s.approvedRequests[id] = hash;
            return RequestStatusTransition.UndecidedToAccepted;
        } else if (request.status == RequestStatus.NULL) {
            // If this is the first approval, change the request status
            // to undecided.
            request.status = RequestStatus.Undecided;
            return RequestStatusTransition.NULLToUndecided;
        }
        return RequestStatusTransition.Unchanged;
    }

    /// @dev Get approvers for a given request.
    /// @param s The multisig to get the approvers for.
    /// @param hash The hash of the request.
    /// @return approvers List of approvers.
    /// @return count Count of approvers.
    function getApprovers(
        DualMultisig storage s,
        bytes32 hash
    ) internal view returns (uint16[] memory approvers, uint16 count) {
        uint256 mask = s.requests[hash].approvers;
        uint16 signersCount = s.firstCommitteeSize + s.secondCommitteeSize;
        approvers = new uint16[](signersCount);
        count = 0;
        for (uint16 i = 0; i < signersCount; i++) {
            if ((mask & (1 << i)) != 0) {
                approvers[count] = i;
                count++;
            }
        }

        return (approvers, count);
    }

    /// @dev Forcefully set next next execution index.
    /// @param s The multisig to set the next execution index for.
    /// @param index The new next execution index.
    function forceSetNextExecutionIndex(
        DualMultisig storage s,
        uint256 index
    ) internal {
        if (s.nextExecutionIndex >= index) {
            revert InvalidNextExecutionIndex();
        }
        s.nextExecutionIndex = index;
    }

    /// @dev Try to execute the next approved request.
    /// @param s The multisig whose next request should
    /// be executed.
    /// @param hash The hash of the request being executed.
    /// @param id The ID of the request being executed.
    /// @return True if the execution was successful.
    function tryExecute(
        DualMultisig storage s,
        bytes32 hash,
        uint256 id
    ) internal returns (bool) {
        if (id == s.nextExecutionIndex && s.approvedRequests[id] == hash) {
            s.nextExecutionIndex++;
            return true;
        }
        return false;
    }
}