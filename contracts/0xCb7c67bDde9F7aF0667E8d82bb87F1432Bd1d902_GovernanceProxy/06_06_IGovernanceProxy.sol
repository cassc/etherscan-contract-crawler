// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "ISimpleAccessControl.sol";

interface IGovernanceProxy is ISimpleAccessControl {
    /// @notice emitted when a change is requested by governance
    event ChangeRequested(Call[] calls, uint64 delay, uint64 changeId);

    /// @notice emitted when a change is executed
    /// this can be in the same block as `ChangeRequested` if there is no
    /// delay for the given function
    event ChangeExecuted(uint64 indexed changeId);

    /// @notice emitted when a change is canceled
    event ChangeCanceled(uint64 indexed changeId);

    /// @notice emitted when a function's delay is updated
    event DelayUpdated(bytes4 indexed selector, uint64 delay);

    /// @notice status of a change
    enum Status {
        Pending,
        Canceled,
        Executed
    }

    /// @notice this represents a function call as part of a Change
    /// The target is the contract to execute the function on
    /// The data is the function signature and the abi-encoded arguments
    struct Call {
        address target;
        bytes data;
    }

    /// @notice this represents a change to execute a set of function calls
    /// The ID is an unique auto-incrementing id that will be generated for each change
    /// The status is one of pending, canceled or executed and is pending when the change is created
    /// The requestedAt is the timestamp when the change was requested
    /// The delay is the delay in seconds before the change can be executed
    /// The endedAt is the timestamp when the change was executed or canceled
    /// The calls are the function calls to execute as part of the change
    struct Change {
        Status status;
        uint64 id;
        uint64 requestedAt;
        uint64 delay;
        uint64 endedAt;
        Call[] calls;
    }

    function delays(bytes4 selector) external view returns (uint64);

    function getPendingChange(uint64 changeId) external view returns (Change memory change);

    function getPendingChanges() external view returns (Change[] memory);

    function getEndedChangesCount() external view returns (uint256);

    function getEndedChanges() external view returns (Change[] memory);

    function getEndedChanges(uint256 offset, uint256 n) external view returns (Change[] memory);

    function requestChange(Call[] calldata calls) external;

    function executeChange(uint64 id) external;

    function cancelChange(uint64 id) external;

    function updateDelay(bytes4 selector, uint64 delay) external;

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;
}