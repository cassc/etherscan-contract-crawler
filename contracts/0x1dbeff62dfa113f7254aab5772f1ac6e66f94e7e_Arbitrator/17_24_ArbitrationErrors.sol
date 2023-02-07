// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @dev Thrown when trying to access an agreement that doesn't exist.
error NonExistentResolution();
/// @dev Thrown when trying to execute a resolution that is locked.
error ResolutionIsLocked();
/// @dev Thrown when trying to actuate a resolution that is already executed.
error ResolutionIsExecuted();
/// @dev Thrown when trying to actuate a resolution that is appealed.
error ResolutionIsAppealed();
/// @dev Thrown when trying to appeal a resolution that is endorsed.
error ResolutionIsEndorsed();

/// @dev Thrown when an account that is not part of a settlement tries to access a function restricted to the parties of a settlement.
error NoPartOfSettlement();
/// @dev Thrown when the positions on a settlement don't match the ones in the dispute.
error SettlementPositionsMustMatch();
/// @dev Thrown when the total balance of a settlement don't match the one in the dispute.
error SettlementBalanceMustMatch();

/// @notice Thrown when the provided permit doesn't match the agreement token requirements.
error InvalidPermit();