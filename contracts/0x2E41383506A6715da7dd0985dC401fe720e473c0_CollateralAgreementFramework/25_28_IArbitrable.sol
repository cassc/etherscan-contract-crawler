// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import { PositionParams } from "src/interfaces/AgreementTypes.sol";

/// @dev Thrown when trying to perform an operation restricted to the arbitrator without being the arbitrator.
error OnlyArbitrator();

/// @notice Minimal interface for arbitrable contracts.
/// @dev Implementers must write the logic to raise and settle disputes.
interface IArbitrable {
    /// @notice Address capable of settling disputes.
    function arbitrator() external view returns (address);

    /// @notice Settles the dispute `id` with the provided settlement.
    /// @param id Id of the dispute to settle.
    /// @param settlement Array of PositionParams to set as final positions.
    function settleDispute(bytes32 id, PositionParams[] calldata settlement) external;
}