// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IGovernable {
    // Events

    event PendingGovernorSet(address _governor, address _pendingGovernor);
    event PendingGovernorAccepted(address _newGovernor);

    // Errors

    error OnlyGovernor();
    error OnlyPendingGovernor();
    error ZeroAddress();

    // Variables

    function governor() external view returns (address _governor);

    function pendingGovernor() external view returns (address _pendingGovernor);

    // Methods

    function setPendingGovernor(address _pendingGovernor) external;

    function acceptPendingGovernor() external;
}