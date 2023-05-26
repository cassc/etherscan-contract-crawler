// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IGovernable {
    event PendingGovernorSet(address pendingGovernor);
    event GovernorAccepted();

    function setPendingGovernor(address _pendingGovernor) external;

    function acceptGovernor() external;
}