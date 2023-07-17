// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./MultiSigCheckable.sol";

/**
 * @dev This removes adminOnly and other relevant methods from a multiSigCheckable.
 */
abstract contract PublicMultiSigCheckable is MultiSigCheckable {
    /**
    @notice Initialize a quorum
        Override this to allow public creatig new quorums.
        If you allow public creating quorums, you MUST NOT have
        customized groupIds. Make sure groupId is created from
        hash of a quorum and is not duplicate.
    @param quorumId The unique quorumID
    @param groupId The groupID, which can be shared by quorums (if managed)
    @param minSignatures The minimum number of signatures for the quorum
    @param ownerGroupId The owner group ID. Can modify this quorum (if managed)
    @param addresses List of addresses in the quorum
    */
    function initialize(
        address quorumId,
        uint64 groupId,
        uint16 minSignatures,
        uint8 ownerGroupId,
        address[] calldata addresses
    ) public override virtual {
			_initialize(quorumId, groupId, minSignatures, ownerGroupId, addresses);
    }

    /**
    @notice Disable force removal
     */
    function forceRemoveFromQuorum(address
    ) external override virtual {
			revert("PMSC: Not supported");
    }

    /**
    @notice Disable cancellation
     */
    function cancelSaltedSignature(
        bytes32,
        uint64,
        bytes memory
    ) external override virtual {
			revert("PMSC: Not supported");
    }
}