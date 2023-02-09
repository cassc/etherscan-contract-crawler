// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { ISignatureTransfer } from "permit2/src/interfaces/ISignatureTransfer.sol";
import { IArbitrable } from "src/interfaces/IArbitrable.sol";
import { CriteriaResolver } from "src/interfaces/CriteriaTypes.sol";
import {
    AgreementData,
    AgreementStatus,
    PositionData,
    PositionParams,
    PositionStatus
} from "src/interfaces/AgreementTypes.sol";

interface IAgreementFramework is IArbitrable {
    /// @dev Raised when a new agreement is created.
    /// @param id Id of the new created agreement.
    /// @param termsHash Hash of the detailed terms of the agreement.
    /// @param criteria Criteria requirements to join the agreement.
    /// @param metadataURI URI of the metadata of the agreement.
    /// @param token ERC20 token address to use in the agreement.
    event AgreementCreated(
        bytes32 indexed id,
        bytes32 termsHash,
        uint256 criteria,
        string metadataURI,
        address token
    );

    /// @dev Raised when a new party joins an agreement.
    /// @param id Id of the agreement joined.
    /// @param party Address of party joined.
    /// @param balance Balance of the party joined.
    event AgreementJoined(bytes32 indexed id, address indexed party, uint256 balance);

    /// @dev Raised when an existing party of an agreement updates its position.
    /// @param id Id of the agreement updated.
    /// @param party Address of the party updated.
    /// @param balance New balance of the party.
    /// @param status New status of the position.
    event AgreementPositionUpdated(
        bytes32 indexed id,
        address indexed party,
        uint256 balance,
        PositionStatus status
    );

    /// @dev Raised when an agreement is finalized.
    /// @param id Id of the agreement finalized.
    event AgreementFinalized(bytes32 indexed id);

    /// @dev Raised when an agreement is in dispute.
    /// @param id Id of the agreement in dispute.
    /// @param party Address of the party that raises the dispute.
    event AgreementDisputed(bytes32 indexed id, address indexed party);

    /// @notice Join an existing agreement with a signed permit.
    /// @param id Id of the agreement to join.
    /// @param resolver Criteria data to prove sender can join agreement.
    /// @param permit Permit2 batched permit to allow the required token transfers.
    /// @param signature Signature of the permit.
    function joinAgreement(
        bytes32 id,
        CriteriaResolver calldata resolver,
        ISignatureTransfer.PermitBatchTransferFrom memory permit,
        bytes calldata signature
    ) external;

    /// @notice Join an existing agreement with transfers previously approved.
    /// @param id Id of the agreement to join.
    /// @param resolver Criteria data to prove sender can join agreement.
    function joinAgreementApproved(bytes32 id, CriteriaResolver calldata resolver) external;

    /// @notice Adjust a position part of an agreement.
    /// @param id Id of the agreement to adjust the position from.
    /// @param newPosition Position params to adjust.
    /// @param permit Permit2 permit to allow the required token transfers.
    /// @param signature Signature of the permit.
    function adjustPosition(
        bytes32 id,
        PositionParams calldata newPosition,
        ISignatureTransfer.PermitTransferFrom memory permit,
        bytes calldata signature
    ) external;

    /// @notice Signal the will of the caller to finalize an agreement.
    /// @param id Id of the agreement to settle.
    function finalizeAgreement(bytes32 id) external;

    /// @notice Raise a dispute over an agreement.
    /// @param id Id of the agreement to dispute.
    function disputeAgreement(bytes32 id) external;

    /// @notice Withdraw your position from the agreement.
    /// @param id Id of the agreement to withdraw from.
    function withdrawFromAgreement(bytes32 id) external;
}