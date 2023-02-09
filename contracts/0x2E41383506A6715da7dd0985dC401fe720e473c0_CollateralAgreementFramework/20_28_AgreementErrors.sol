// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @notice Thrown when trying to access to an agreement that doesn't exist.
error NonExistentAgreement();
/// @notice Thrown when trying to override an already existing agreement.
error AlreadyExistentAgreement();
/// @notice Thrown when trying to perform an invalid operation on a disputed agreement.
error AgreementIsDisputed();
/// @notice Thrown when trying to perform an invalid operation on a finalized agreement.
error AgreementIsFinalized();
/// @notice Thrown when trying to perform an invalid operation on a non-finalized agreement.
error AgreementNotFinalized();
/// @notice Thrown when trying to perform an invalid operation on a non-disputed agreement.
error AgreementNotDisputed();

/// @notice Thrown when a given party is not part of a given agreement.
error NoPartOfAgreement();
/// @notice Thrown when a party is trying to join an agreement after already have joined the agreement.
error PartyAlreadyJoined();
/// @notice Thrown when a party is trying to finalize an agreement after already have finalized the agreement.
error PartyAlreadyFinalized();
/// @notice Thrown when the provided criteria doesn't match the account trying to join.
error InvalidCriteria();
/// @notice Thrown when the provided permit doesn't match the agreement token requirements.
error InvalidPermit();
/// @notice Thrown when trying to use an invalid balance for a position in an agreement.
error InvalidBalance();