// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";

import {PositionParams} from "src/interfaces/AgreementTypes.sol";
import {IArbitrable} from "src/interfaces/IArbitrable.sol";

interface IArbitrator {
    /// @dev Raised when a new resolution is submitted.
    /// @param framework Address of the framework that manages the dispute.
    /// @param dispute Id of the dispute to resolve.
    /// @param resolution Id of the resolution.
    /// @param settlement Encoding of the settlement.
    event ResolutionSubmitted(address indexed framework, bytes32 indexed dispute, bytes32 indexed resolution, bytes32 settlement);

    /// @dev Raised when a resolution is appealed.
    /// @param resolution Id of the resolution appealed.
    /// @param settlement Encoding of the settlement.
    /// @param account Address of the account that appealed.
    event ResolutionAppealed(bytes32 indexed resolution, bytes32 settlement, address account);

    /// @dev Raised when an appealed resolution is endorsed.
    /// @param resolution Id of the resolution endorsed.
    /// @param settlement Encoding of the settlement.
    event ResolutionEndorsed(bytes32 indexed resolution, bytes32 settlement);

    /// @dev Raised when a resolution is executed.
    /// @param resolution Id of the resolution executed.
    /// @param settlement Encoding of the settlement.
    event ResolutionExecuted(bytes32 indexed resolution, bytes32 settlement);

    /// @notice Submit a resolution for a dispute.
    /// @dev Any new resolution for the same dispute overrides the last one.
    /// @param framework address of the framework of the agreement in dispute.
    /// @param dispute Identifier of the agreement in dispute.
    /// @param settlement Array of final positions in the resolution.
    /// @return Identifier of the resolution submitted.
    function submitResolution(
        IArbitrable framework,
        bytes32 dispute,
        string calldata metadataURI,
        PositionParams[] calldata settlement
    ) external returns (bytes32);

    /// @notice Execute a submitted resolution.
    /// @param framework address of the framework of the agreement in dispute.
    /// @param dispute Identifier of the agreement in dispute.
    /// @param settlement Array of final positions in the resolution.
    function executeResolution(IArbitrable framework, bytes32 dispute, PositionParams[] calldata settlement) external;

    /// @notice Appeal a submitted resolution.
    /// @param id Identifier of the resolution to appeal.
    /// @param settlement Array of final positions in the resolution.
    /// @param permit Permit2 permit to allow the required token transfer.
    /// @param signature Signature of the permit.
    function appealResolution(
        bytes32 id,
        PositionParams[] calldata settlement,
        ISignatureTransfer.PermitTransferFrom memory permit,
        bytes calldata signature
    ) external;

    /// @notice Endorse a submitted resolution, it overrides any appeal.
    /// @param id Identifier of the resolution to endorse.
    /// @param settlement Encoding of the settlement to endorse.
    function endorseResolution(bytes32 id, bytes32 settlement) external;
}