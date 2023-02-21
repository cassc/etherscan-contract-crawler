// SPDX-License-Identifier: MIT

pragma solidity >=0.6.11;

/// @notice Event sent to Governance layer when a cycle rollover is complete
struct CycleRolloverEvent {
	bytes32 eventSig;
	uint256 cycleIndex;
	uint256 timestamp;
}